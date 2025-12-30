-- ============================================================================
-- Migration: 070_search_history.sql
-- Story: 1.8 - RAG Search UI Interface
-- Description: Search history table for logged-in users (AC 10)
-- ============================================================================

-- ============================================================================
-- 1. SEARCH HISTORY TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.search_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL ,
  query TEXT NOT NULL,
  filters JSONB DEFAULT '{}',
  results_count INTEGER DEFAULT 0,
  top_confidence_score DECIMAL(5, 4),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index for efficient user lookups (most recent first)
CREATE INDEX IF NOT EXISTS idx_search_history_user_recent 
  ON public.search_history(user_id, created_at DESC);

-- Index for query text search
CREATE INDEX IF NOT EXISTS idx_search_history_query 
  ON public.search_history USING gin(to_tsvector('english', query));

-- ============================================================================
-- 2. ROW-LEVEL SECURITY
-- ============================================================================

ALTER TABLE public.search_history ENABLE ROW LEVEL SECURITY;

-- Users can only access their own search history
CREATE POLICY "Users can view own search history"
  ON public.search_history
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own search history"
  ON public.search_history
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own search history"
  ON public.search_history
  FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================================
-- 3. CONTENT REPORTS TABLE (AC 8 - Report Incorrect Information)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.content_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  chunk_id UUID NOT NULL REFERENCES public.knowledge_chunks(id) ON DELETE CASCADE,
  report_type TEXT NOT NULL CHECK (report_type IN ('incorrect', 'outdated', 'incomplete', 'other')),
  description TEXT,
  query_context TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved', 'dismissed')),
  admin_notes TEXT,
  reviewed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_content_reports_status 
  ON public.content_reports(status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_content_reports_chunk 
  ON public.content_reports(chunk_id);

ALTER TABLE public.content_reports ENABLE ROW LEVEL SECURITY;

-- Users can submit reports
CREATE POLICY "Users can submit content reports"
  ON public.content_reports
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can view their own reports
CREATE POLICY "Users can view own reports"
  ON public.content_reports
  FOR SELECT
  USING (auth.uid() = user_id);

-- Admins can view all reports
CREATE POLICY "Admins can manage all reports"
  ON public.content_reports
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================================================
-- 4. FUNCTIONS
-- ============================================================================

-- Save search to history (maintains max 10 per user)
CREATE OR REPLACE FUNCTION save_search_history(
  p_user_id UUID,
  p_query TEXT,
  p_filters JSONB DEFAULT '{}',
  p_results_count INTEGER DEFAULT 0,
  p_top_confidence_score DECIMAL DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_new_id UUID;
  v_count INTEGER;
BEGIN
  -- Insert new search
  INSERT INTO public.search_history (
    user_id, query, filters, results_count, top_confidence_score
  ) VALUES (
    p_user_id, p_query, p_filters, p_results_count, p_top_confidence_score
  ) RETURNING id INTO v_new_id;
  
  -- Count user's history entries
  SELECT COUNT(*) INTO v_count
  FROM public.search_history
  WHERE user_id = p_user_id;
  
  -- If more than 10, delete oldest entries
  IF v_count > 10 THEN
    DELETE FROM public.search_history
    WHERE id IN (
      SELECT id FROM public.search_history
      WHERE user_id = p_user_id
      ORDER BY created_at ASC
      LIMIT v_count - 10
    );
  END IF;
  
  RETURN v_new_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get recent search history
CREATE OR REPLACE FUNCTION get_search_history(
  p_user_id UUID,
  p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
  id UUID,
  query TEXT,
  filters JSONB,
  results_count INTEGER,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    sh.id,
    sh.query,
    sh.filters,
    sh.results_count,
    sh.created_at
  FROM public.search_history sh
  WHERE sh.user_id = p_user_id
  ORDER BY sh.created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Clear user's search history
CREATE OR REPLACE FUNCTION clear_search_history(p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  DELETE FROM public.search_history WHERE user_id = p_user_id;
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Submit content report
CREATE OR REPLACE FUNCTION submit_content_report(
  p_user_id UUID,
  p_chunk_id UUID,
  p_report_type TEXT,
  p_description TEXT DEFAULT NULL,
  p_query_context TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_report_id UUID;
BEGIN
  INSERT INTO public.content_reports (
    user_id, chunk_id, report_type, description, query_context
  ) VALUES (
    p_user_id, p_chunk_id, p_report_type, p_description, p_query_context
  ) RETURNING id INTO v_report_id;
  
  RETURN v_report_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT SELECT, INSERT, DELETE ON public.search_history TO authenticated;
GRANT SELECT, INSERT ON public.content_reports TO authenticated;
GRANT EXECUTE ON FUNCTION save_search_history TO authenticated;
GRANT EXECUTE ON FUNCTION get_search_history TO authenticated;
GRANT EXECUTE ON FUNCTION clear_search_history TO authenticated;
GRANT EXECUTE ON FUNCTION submit_content_report TO authenticated;

