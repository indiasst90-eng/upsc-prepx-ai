-- Migration 052: Bookmark Library Organization
-- Story 9.10: Collections and enhanced organization

-- ============================================
-- AC 5: COLLECTIONS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.bookmark_collections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL ,
  
  name TEXT NOT NULL,
  description TEXT,
  icon TEXT DEFAULT '📁',
  color TEXT DEFAULT '#3B82F6',
  
  -- Ordering
  sort_order INTEGER DEFAULT 0,
  
  -- Metadata
  is_default BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  UNIQUE(user_id, name)
);

CREATE INDEX idx_collections_user ON public.bookmark_collections(user_id);

-- Add collection_id to bookmarks
ALTER TABLE public.bookmarks 
ADD COLUMN IF NOT EXISTS collection_id UUID REFERENCES public.bookmark_collections(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_bookmarks_collection ON public.bookmarks(collection_id);

-- RLS
ALTER TABLE public.bookmark_collections ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own collections"
  ON public.bookmark_collections FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own collections"
  ON public.bookmark_collections FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own collections"
  ON public.bookmark_collections FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own collections"
  ON public.bookmark_collections FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- AC 5: Create collection
CREATE OR REPLACE FUNCTION create_collection(
  p_user_id UUID,
  p_name TEXT,
  p_description TEXT DEFAULT NULL,
  p_icon TEXT DEFAULT '📁',
  p_color TEXT DEFAULT '#3B82F6'
)
RETURNS UUID AS $$
DECLARE
  v_id UUID;
  v_order INTEGER;
BEGIN
  SELECT COALESCE(MAX(sort_order), 0) + 1 INTO v_order
  FROM public.bookmark_collections WHERE user_id = p_user_id;
  
  INSERT INTO public.bookmark_collections (user_id, name, description, icon, color, sort_order)
  VALUES (p_user_id, p_name, p_description, p_icon, p_color, v_order)
  RETURNING id INTO v_id;
  
  RETURN v_id;
END;
$$ LANGUAGE plpgsql;

-- AC 6: Bulk move to collection
CREATE OR REPLACE FUNCTION bulk_move_to_collection(
  p_user_id UUID,
  p_bookmark_ids UUID[],
  p_collection_id UUID
)
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER;
BEGIN
  UPDATE public.bookmarks 
  SET collection_id = p_collection_id, updated_at = NOW()
  WHERE id = ANY(p_bookmark_ids) AND user_id = p_user_id;
  
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- AC 6: Bulk add tags
CREATE OR REPLACE FUNCTION bulk_add_tags(
  p_user_id UUID,
  p_bookmark_ids UUID[],
  p_tags TEXT[]
)
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER := 0;
  v_bookmark_id UUID;
BEGIN
  FOREACH v_bookmark_id IN ARRAY p_bookmark_ids
  LOOP
    UPDATE public.bookmarks
    SET tags = (
      SELECT ARRAY(SELECT DISTINCT unnest(COALESCE(tags, '{}') || p_tags))
    ), updated_at = NOW()
    WHERE id = v_bookmark_id AND user_id = p_user_id;
    
    IF FOUND THEN v_count := v_count + 1; END IF;
  END LOOP;
  
  RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- AC 6: Bulk delete
CREATE OR REPLACE FUNCTION bulk_delete_bookmarks(
  p_user_id UUID,
  p_bookmark_ids UUID[]
)
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER;
BEGIN
  DELETE FROM public.bookmarks
  WHERE id = ANY(p_bookmark_ids) AND user_id = p_user_id;
  
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- AC 7: Rename tag
CREATE OR REPLACE FUNCTION rename_tag(
  p_user_id UUID,
  p_old_tag TEXT,
  p_new_tag TEXT
)
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER := 0;
BEGIN
  UPDATE public.bookmarks
  SET tags = array_replace(tags, p_old_tag, p_new_tag),
      updated_at = NOW()
  WHERE user_id = p_user_id
    AND p_old_tag = ANY(tags);
  
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- AC 7: Merge tags
CREATE OR REPLACE FUNCTION merge_tags(
  p_user_id UUID,
  p_source_tags TEXT[],
  p_target_tag TEXT
)
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER := 0;
  v_source_tag TEXT;
BEGIN
  FOREACH v_source_tag IN ARRAY p_source_tags
  LOOP
    IF v_source_tag != p_target_tag THEN
      v_count := v_count + rename_tag(p_user_id, v_source_tag, p_target_tag);
    END IF;
  END LOOP;
  
  RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- AC 7: Delete tag
CREATE OR REPLACE FUNCTION delete_tag(
  p_user_id UUID,
  p_tag TEXT
)
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER := 0;
BEGIN
  UPDATE public.bookmarks
  SET tags = array_remove(tags, p_tag),
      updated_at = NOW()
  WHERE user_id = p_user_id
    AND p_tag = ANY(tags);
  
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- AC 7: Get all tags with counts
CREATE OR REPLACE FUNCTION get_user_tags(p_user_id UUID)
RETURNS TABLE (
  tag TEXT,
  count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT unnest(b.tags) as tag, COUNT(*) as count
  FROM public.bookmarks b
  WHERE b.user_id = p_user_id
    AND b.tags IS NOT NULL
    AND array_length(b.tags, 1) > 0
  GROUP BY unnest(b.tags)
  ORDER BY count DESC, tag ASC;
END;
$$ LANGUAGE plpgsql;

-- AC 8: Get bookmark statistics
CREATE OR REPLACE FUNCTION get_bookmark_stats(p_user_id UUID)
RETURNS TABLE (
  total_bookmarks BIGINT,
  by_type JSONB,
  top_tags JSONB,
  current_streak INTEGER,
  longest_streak INTEGER,
  total_reviews BIGINT,
  this_week BIGINT,
  collections_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  WITH type_counts AS (
    SELECT b.content_type, COUNT(*) as cnt
    FROM public.bookmarks b
    WHERE b.user_id = p_user_id
    GROUP BY b.content_type
  ),
  tag_counts AS (
    SELECT unnest(b.tags) as tag, COUNT(*) as cnt
    FROM public.bookmarks b
    WHERE b.user_id = p_user_id AND b.tags IS NOT NULL
    GROUP BY unnest(b.tags)
    ORDER BY cnt DESC
    LIMIT 5
  ),
  streak_info AS (
    SELECT COALESCE(current_streak, 0) as cs, COALESCE(longest_streak, 0) as ls, COALESCE(total_reviews, 0) as tr
    FROM public.review_streaks
    WHERE user_id = p_user_id
  ),
  week_reviews AS (
    SELECT COUNT(*) as cnt
    FROM public.bookmark_reviews
    WHERE user_id = p_user_id
      AND reviewed_at >= NOW() - INTERVAL '7 days'
  )
  SELECT 
    (SELECT COUNT(*) FROM public.bookmarks WHERE user_id = p_user_id),
    (SELECT jsonb_object_agg(content_type, cnt) FROM type_counts),
    (SELECT jsonb_agg(jsonb_build_object('tag', tag, 'count', cnt)) FROM tag_counts),
    COALESCE((SELECT cs FROM streak_info), 0),
    COALESCE((SELECT ls FROM streak_info), 0),
    COALESCE((SELECT tr FROM streak_info), 0),
    (SELECT cnt FROM week_reviews),
    (SELECT COUNT(*) FROM public.bookmark_collections WHERE user_id = p_user_id);
END;
$$ LANGUAGE plpgsql;

-- AC 3, 4: Advanced bookmark search
CREATE OR REPLACE FUNCTION search_bookmarks(
  p_user_id UUID,
  p_query TEXT DEFAULT NULL,
  p_content_type TEXT DEFAULT NULL,
  p_collection_id UUID DEFAULT NULL,
  p_tags TEXT[] DEFAULT NULL,
  p_date_from TIMESTAMPTZ DEFAULT NULL,
  p_date_to TIMESTAMPTZ DEFAULT NULL,
  p_sort_by TEXT DEFAULT 'newest',
  p_limit INTEGER DEFAULT 50
)
RETURNS TABLE (
  id UUID,
  content_type TEXT,
  content_id UUID,
  title TEXT,
  snippet TEXT,
  tags TEXT[],
  collection_id UUID,
  review_count INTEGER,
  ease_factor DECIMAL,
  next_review_date TIMESTAMPTZ,
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
    b.tags,
    b.collection_id,
    COALESCE(b.review_count, 0),
    COALESCE(b.ease_factor, 2.5),
    b.next_review_date,
    b.bookmarked_at
  FROM public.bookmarks b
  WHERE b.user_id = p_user_id
    AND (p_query IS NULL OR 
         b.title ILIKE '%' || p_query || '%' OR 
         b.snippet ILIKE '%' || p_query || '%' OR
         EXISTS (SELECT 1 FROM unnest(b.tags) t WHERE t ILIKE '%' || p_query || '%'))
    AND (p_content_type IS NULL OR b.content_type = p_content_type)
    AND (p_collection_id IS NULL OR b.collection_id = p_collection_id)
    AND (p_tags IS NULL OR b.tags && p_tags)
    AND (p_date_from IS NULL OR b.bookmarked_at >= p_date_from)
    AND (p_date_to IS NULL OR b.bookmarked_at <= p_date_to)
  ORDER BY
    CASE WHEN p_sort_by = 'newest' THEN b.bookmarked_at END DESC,
    CASE WHEN p_sort_by = 'oldest' THEN b.bookmarked_at END ASC,
    CASE WHEN p_sort_by = 'reviewed' THEN b.review_count END DESC,
    CASE WHEN p_sort_by = 'alphabetical' THEN b.title END ASC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE public.bookmark_collections IS 'Story 9.10 AC 5: Custom collections for organizing bookmarks';
COMMENT ON FUNCTION bulk_move_to_collection IS 'Story 9.10 AC 6: Bulk move bookmarks to collection';
COMMENT ON FUNCTION get_bookmark_stats IS 'Story 9.10 AC 8: Bookmark statistics dashboard';
COMMENT ON FUNCTION search_bookmarks IS 'Story 9.10 AC 2-4: Advanced search with filters and sorting';

