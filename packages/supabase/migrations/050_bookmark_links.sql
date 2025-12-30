-- Migration 050: Bookmark Auto-linking & Cross-references
-- Story 9.8: Semantic linking between bookmarks and related content

-- ============================================
-- BOOKMARK LINKS TABLE (AC 5)
-- ============================================

CREATE TABLE IF NOT EXISTS public.bookmark_links (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  bookmark_id UUID NOT NULL REFERENCES public.bookmarks(id) ON DELETE CASCADE,
  
  -- AC 2: Related content types
  related_content_type TEXT NOT NULL CHECK (related_content_type IN ('note', 'video', 'question', 'topic', 'mindmap', 'pyq', 'bookmark')),
  related_content_id UUID NOT NULL,
  
  -- AC 2: Link/Relationship types
  link_type TEXT NOT NULL CHECK (link_type IN ('related_topic', 'related_pyq', 'related_video', 'also_bookmarked', 'cross_subject', 'similar_concept')),
  
  -- AC 4: Relevance scoring
  relevance_score DECIMAL(4,3) NOT NULL DEFAULT 0.0 CHECK (relevance_score >= 0 AND relevance_score <= 1),
  
  -- Metadata
  metadata JSONB DEFAULT '{}',  -- cross_subjects, pyq_years, etc.
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Prevent duplicate links
  UNIQUE(bookmark_id, related_content_type, related_content_id)
);

-- Indexes for fast retrieval
CREATE INDEX idx_bookmark_links_bookmark ON public.bookmark_links(bookmark_id);
CREATE INDEX idx_bookmark_links_related ON public.bookmark_links(related_content_type, related_content_id);
CREATE INDEX idx_bookmark_links_type ON public.bookmark_links(link_type);
CREATE INDEX idx_bookmark_links_score ON public.bookmark_links(relevance_score DESC);

-- RLS Policies (inherit from bookmark ownership)
ALTER TABLE public.bookmark_links ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view links for their bookmarks"
  ON public.bookmark_links FOR SELECT
  USING (
    bookmark_id IN (
      SELECT id FROM public.bookmarks WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "System can insert links"
  ON public.bookmark_links FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Users can delete links for their bookmarks"
  ON public.bookmark_links FOR DELETE
  USING (
    bookmark_id IN (
      SELECT id FROM public.bookmarks WHERE user_id = auth.uid()
    )
  );

-- ============================================
-- LINK PROCESSING QUEUE (AC 10: Background)
-- ============================================

CREATE TABLE IF NOT EXISTS public.bookmark_link_queue (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  bookmark_id UUID NOT NULL REFERENCES public.bookmarks(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'complete', 'failed')),
  attempts INTEGER DEFAULT 0,
  error_message TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  processed_at TIMESTAMPTZ,
  UNIQUE(bookmark_id)
);

CREATE INDEX idx_link_queue_status ON public.bookmark_link_queue(status);

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Queue bookmark for auto-linking (AC 10: Non-blocking)
CREATE OR REPLACE FUNCTION queue_bookmark_for_linking(p_bookmark_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  INSERT INTO public.bookmark_link_queue (bookmark_id)
  VALUES (p_bookmark_id)
  ON CONFLICT (bookmark_id) DO UPDATE SET
    status = 'pending',
    attempts = 0,
    error_message = NULL,
    created_at = NOW();
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Get pending bookmarks for linking
CREATE OR REPLACE FUNCTION get_pending_link_jobs(p_limit INTEGER DEFAULT 10)
RETURNS TABLE (
  id UUID,
  bookmark_id UUID,
  content_type TEXT,
  title TEXT,
  snippet TEXT,
  user_id UUID
) AS $$
BEGIN
  RETURN QUERY
  WITH pending AS (
    SELECT q.id, q.bookmark_id
    FROM public.bookmark_link_queue q
    WHERE q.status = 'pending'
    ORDER BY q.created_at ASC
    LIMIT p_limit
    FOR UPDATE SKIP LOCKED
  )
  UPDATE public.bookmark_link_queue
  SET status = 'processing', attempts = attempts + 1
  FROM pending
  WHERE public.bookmark_link_queue.id = pending.id
  RETURNING 
    pending.id,
    pending.bookmark_id,
    (SELECT b.content_type FROM public.bookmarks b WHERE b.id = pending.bookmark_id),
    (SELECT b.title FROM public.bookmarks b WHERE b.id = pending.bookmark_id),
    (SELECT b.snippet FROM public.bookmarks b WHERE b.id = pending.bookmark_id),
    (SELECT b.user_id FROM public.bookmarks b WHERE b.id = pending.bookmark_id);
END;
$$ LANGUAGE plpgsql;

-- AC 5: Save discovered links
CREATE OR REPLACE FUNCTION save_bookmark_links(
  p_bookmark_id UUID,
  p_links JSONB  -- Array of {content_type, content_id, link_type, relevance_score, metadata}
)
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER := 0;
  v_link JSONB;
BEGIN
  FOR v_link IN SELECT * FROM jsonb_array_elements(p_links)
  LOOP
    INSERT INTO public.bookmark_links (
      bookmark_id,
      related_content_type,
      related_content_id,
      link_type,
      relevance_score,
      metadata
    ) VALUES (
      p_bookmark_id,
      v_link->>'content_type',
      (v_link->>'content_id')::UUID,
      v_link->>'link_type',
      COALESCE((v_link->>'relevance_score')::DECIMAL, 0.7),
      COALESCE(v_link->'metadata', '{}')
    )
    ON CONFLICT (bookmark_id, related_content_type, related_content_id) 
    DO UPDATE SET
      relevance_score = GREATEST(bookmark_links.relevance_score, EXCLUDED.relevance_score),
      metadata = bookmark_links.metadata || EXCLUDED.metadata;
    
    v_count := v_count + 1;
  END LOOP;
  
  -- Mark job complete
  UPDATE public.bookmark_link_queue
  SET status = 'complete', processed_at = NOW()
  WHERE bookmark_id = p_bookmark_id;
  
  RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- AC 6: Get related content for a bookmark
CREATE OR REPLACE FUNCTION get_bookmark_related_content(
  p_bookmark_id UUID,
  p_link_type TEXT DEFAULT NULL
)
RETURNS TABLE (
  link_id UUID,
  content_type TEXT,
  content_id UUID,
  link_type TEXT,
  relevance_score DECIMAL,
  metadata JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    bl.id,
    bl.related_content_type,
    bl.related_content_id,
    bl.link_type,
    bl.relevance_score,
    bl.metadata
  FROM public.bookmark_links bl
  WHERE bl.bookmark_id = p_bookmark_id
    AND (p_link_type IS NULL OR bl.link_type = p_link_type)
  ORDER BY bl.relevance_score DESC, bl.created_at DESC
  LIMIT 20;
END;
$$ LANGUAGE plpgsql;

-- AC 9: Find PYQ appearances for a concept
CREATE OR REPLACE FUNCTION find_pyq_appearances(
  p_concept TEXT,
  p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
  pyq_id UUID,
  year INTEGER,
  paper TEXT,
  question_preview TEXT,
  relevance_score DECIMAL
) AS $$
BEGIN
  -- This would use vector similarity in production
  -- For now, return text-based matches
  RETURN QUERY
  SELECT 
    q.id,
    q.year,
    q.paper,
    LEFT(q.question_text, 150) as question_preview,
    0.8::DECIMAL as relevance_score
  FROM public.pyq_questions q
  WHERE q.question_text ILIKE '%' || p_concept || '%'
     OR q.topic ILIKE '%' || p_concept || '%'
  ORDER BY q.year DESC
  LIMIT p_limit;
EXCEPTION
  WHEN undefined_table THEN
    RETURN;
END;
$$ LANGUAGE plpgsql;

-- AC 7: Get smart suggestions based on user's bookmarks
CREATE OR REPLACE FUNCTION get_bookmark_suggestions(
  p_user_id UUID,
  p_limit INTEGER DEFAULT 5
)
RETURNS TABLE (
  content_type TEXT,
  content_id UUID,
  title TEXT,
  reason TEXT,
  confidence DECIMAL
) AS $$
BEGIN
  -- Find content that's commonly bookmarked together
  RETURN QUERY
  WITH user_bookmarks AS (
    SELECT content_type, content_id, title 
    FROM public.bookmarks 
    WHERE user_id = p_user_id
  ),
  related_links AS (
    SELECT 
      bl.related_content_type,
      bl.related_content_id,
      bl.relevance_score,
      b.title as source_title
    FROM public.bookmark_links bl
    JOIN public.bookmarks b ON b.id = bl.bookmark_id
    WHERE b.user_id = p_user_id
      AND bl.link_type IN ('related_topic', 'similar_concept')
      AND NOT EXISTS (
        SELECT 1 FROM user_bookmarks ub 
        WHERE ub.content_id = bl.related_content_id
      )
  )
  SELECT DISTINCT ON (rl.related_content_id)
    rl.related_content_type,
    rl.related_content_id,
    rl.source_title,
    'Related to your bookmark: ' || rl.source_title,
    rl.relevance_score
  FROM related_links rl
  ORDER BY rl.related_content_id, rl.relevance_score DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- AC 8: Find cross-subject connections
CREATE OR REPLACE FUNCTION find_cross_subject_links(
  p_bookmark_id UUID
)
RETURNS TABLE (
  subject1 TEXT,
  subject2 TEXT,
  connection_topic TEXT,
  related_content_id UUID,
  related_content_type TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    bl.metadata->>'source_subject' as subject1,
    bl.metadata->>'target_subject' as subject2,
    bl.metadata->>'topic' as connection_topic,
    bl.related_content_id,
    bl.related_content_type
  FROM public.bookmark_links bl
  WHERE bl.bookmark_id = p_bookmark_id
    AND bl.link_type = 'cross_subject'
  ORDER BY bl.relevance_score DESC;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TRIGGER: Auto-queue on bookmark creation
-- ============================================

CREATE OR REPLACE FUNCTION trigger_queue_bookmark_linking()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM queue_bookmark_for_linking(NEW.id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS bookmark_auto_link_trigger ON public.bookmarks;
CREATE TRIGGER bookmark_auto_link_trigger
  AFTER INSERT ON public.bookmarks
  FOR EACH ROW
  EXECUTE FUNCTION trigger_queue_bookmark_linking();

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE public.bookmark_links IS 'Story 9.8: Cross-references between bookmarks and related content';
COMMENT ON TABLE public.bookmark_link_queue IS 'Story 9.8 AC 10: Background processing queue for link discovery';
COMMENT ON FUNCTION queue_bookmark_for_linking IS 'Story 9.8 AC 10: Queue bookmark for non-blocking link discovery';
COMMENT ON FUNCTION save_bookmark_links IS 'Story 9.8 AC 5: Save discovered semantic links';
COMMENT ON FUNCTION get_bookmark_related_content IS 'Story 9.8 AC 6: Retrieve related content for display';

