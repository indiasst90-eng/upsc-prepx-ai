-- Migration 049: Smart Bookmark System Infrastructure
-- Story 9.7: Bookmark notes, videos, questions, and topics

-- ============================================
-- BOOKMARKS TABLE (AC 3)
-- ============================================

CREATE TABLE IF NOT EXISTS public.bookmarks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL ,
  
  -- AC 5: Content types
  content_type TEXT NOT NULL CHECK (content_type IN ('note', 'video', 'question', 'topic', 'mindmap', 'pyq', 'custom')),
  content_id UUID,  -- Reference to specific content
  
  -- AC 3: Title and snippet
  title TEXT NOT NULL,
  snippet TEXT,  -- AC 4: First 100 chars
  url TEXT,  -- For custom bookmarks
  
  -- AC 6: Tags
  tags TEXT[] DEFAULT '{}',
  
  -- AC 7: Context saving
  context JSONB DEFAULT '{}',  -- video_position, scroll_position, highlight, etc.
  
  -- Metadata
  is_favorite BOOLEAN DEFAULT FALSE,
  notes TEXT,  -- User's personal notes
  bookmarked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- AC 10: Duplicate prevention
  UNIQUE(user_id, content_type, content_id)
);

-- AC 9: Database indexes
CREATE INDEX idx_bookmarks_user ON public.bookmarks(user_id);
CREATE INDEX idx_bookmarks_user_type ON public.bookmarks(user_id, content_type);
CREATE INDEX idx_bookmarks_user_date ON public.bookmarks(user_id, bookmarked_at DESC);
CREATE INDEX idx_bookmarks_content ON public.bookmarks(content_type, content_id);
CREATE INDEX idx_bookmarks_tags ON public.bookmarks USING GIN(tags);

-- RLS Policies
ALTER TABLE public.bookmarks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own bookmarks"
  ON public.bookmarks FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own bookmarks"
  ON public.bookmarks FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own bookmarks"
  ON public.bookmarks FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own bookmarks"
  ON public.bookmarks FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- AC 2, 4: Create bookmark with auto-snippet
CREATE OR REPLACE FUNCTION create_bookmark(
  p_user_id UUID,
  p_content_type TEXT,
  p_content_id UUID,
  p_title TEXT,
  p_full_content TEXT DEFAULT NULL,
  p_url TEXT DEFAULT NULL,
  p_tags TEXT[] DEFAULT '{}',
  p_context JSONB DEFAULT '{}'
)
RETURNS UUID AS $$
DECLARE
  v_id UUID;
  v_snippet TEXT;
BEGIN
  -- AC 4: Auto-snippet - first 100 characters
  IF p_full_content IS NOT NULL THEN
    v_snippet := LEFT(p_full_content, 100);
    IF LENGTH(p_full_content) > 100 THEN
      v_snippet := v_snippet || '...';
    END IF;
  END IF;
  
  -- AC 10: Insert with ON CONFLICT to prevent duplicates
  INSERT INTO public.bookmarks (
    user_id, content_type, content_id, title, snippet, url, tags, context
  ) VALUES (
    p_user_id, p_content_type, p_content_id, p_title, v_snippet, p_url, p_tags, p_context
  )
  ON CONFLICT (user_id, content_type, content_id) 
  DO UPDATE SET
    updated_at = NOW(),
    tags = COALESCE(NULLIF(EXCLUDED.tags, '{}'), public.bookmarks.tags),
    context = COALESCE(NULLIF(EXCLUDED.context, '{}'), public.bookmarks.context)
  RETURNING id INTO v_id;
  
  RETURN v_id;
END;
$$ LANGUAGE plpgsql;

-- AC 10: Check if already bookmarked
CREATE OR REPLACE FUNCTION is_bookmarked(
  p_user_id UUID,
  p_content_type TEXT,
  p_content_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.bookmarks
    WHERE user_id = p_user_id
      AND content_type = p_content_type
      AND content_id = p_content_id
  );
END;
$$ LANGUAGE plpgsql;

-- Toggle bookmark (add/remove)
CREATE OR REPLACE FUNCTION toggle_bookmark(
  p_user_id UUID,
  p_content_type TEXT,
  p_content_id UUID,
  p_title TEXT DEFAULT 'Bookmark'
)
RETURNS TABLE (
  action TEXT,
  bookmark_id UUID
) AS $$
DECLARE
  v_existing UUID;
BEGIN
  SELECT id INTO v_existing FROM public.bookmarks
  WHERE user_id = p_user_id
    AND content_type = p_content_type
    AND content_id = p_content_id;
  
  IF v_existing IS NOT NULL THEN
    -- Remove bookmark
    DELETE FROM public.bookmarks WHERE id = v_existing;
    RETURN QUERY SELECT 'removed'::TEXT, v_existing;
  ELSE
    -- Add bookmark
    RETURN QUERY 
    SELECT 'added'::TEXT, create_bookmark(p_user_id, p_content_type, p_content_id, p_title);
  END IF;
END;
$$ LANGUAGE plpgsql;

-- AC 8: Get bookmark count
CREATE OR REPLACE FUNCTION get_bookmark_count(p_user_id UUID)
RETURNS INTEGER AS $$
BEGIN
  RETURN (SELECT COUNT(*)::INTEGER FROM public.bookmarks WHERE user_id = p_user_id);
END;
$$ LANGUAGE plpgsql;

-- Get bookmarks by type
CREATE OR REPLACE FUNCTION get_bookmarks_by_type(
  p_user_id UUID,
  p_content_type TEXT DEFAULT NULL,
  p_limit INTEGER DEFAULT 50
)
RETURNS TABLE (
  id UUID,
  content_type TEXT,
  content_id UUID,
  title TEXT,
  snippet TEXT,
  url TEXT,
  tags TEXT[],
  context JSONB,
  is_favorite BOOLEAN,
  bookmarked_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    b.id,
    b.content_type,
    b.content_id,
    b.title,
    b.snippet,
    b.url,
    b.tags,
    b.context,
    b.is_favorite,
    b.bookmarked_at
  FROM public.bookmarks b
  WHERE b.user_id = p_user_id
    AND (p_content_type IS NULL OR b.content_type = p_content_type)
  ORDER BY b.bookmarked_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- AC 6: Update bookmark tags
CREATE OR REPLACE FUNCTION update_bookmark_tags(
  p_bookmark_id UUID,
  p_user_id UUID,
  p_tags TEXT[]
)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE public.bookmarks
  SET tags = p_tags, updated_at = NOW()
  WHERE id = p_bookmark_id AND user_id = p_user_id;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Search bookmarks by tag
CREATE OR REPLACE FUNCTION search_bookmarks_by_tag(
  p_user_id UUID,
  p_tag TEXT
)
RETURNS TABLE (
  id UUID,
  content_type TEXT,
  title TEXT,
  snippet TEXT,
  tags TEXT[],
  bookmarked_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    b.id,
    b.content_type,
    b.title,
    b.snippet,
    b.tags,
    b.bookmarked_at
  FROM public.bookmarks b
  WHERE b.user_id = p_user_id
    AND p_tag = ANY(b.tags)
  ORDER BY b.bookmarked_at DESC;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE public.bookmarks IS 'Story 9.7: Smart bookmark system for all content types';
COMMENT ON FUNCTION create_bookmark IS 'Story 9.7 AC 2,4: Create bookmark with auto-snippet';
COMMENT ON FUNCTION is_bookmarked IS 'Story 9.7 AC 10: Check duplicate prevention';
COMMENT ON FUNCTION toggle_bookmark IS 'Story 9.7 AC 2: One-click bookmark toggle';
COMMENT ON FUNCTION get_bookmark_count IS 'Story 9.7 AC 8: Badge count for navigation';

