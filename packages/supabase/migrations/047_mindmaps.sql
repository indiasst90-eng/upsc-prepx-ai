-- Migration 047: Mindmap Auto-generation
-- Story 9.4: Auto-generate mindmaps from various input sources

-- ============================================
-- MINDMAPS TABLE (AC 7)
-- ============================================

CREATE TABLE IF NOT EXISTS public.mindmaps (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL ,
  title TEXT NOT NULL,
  description TEXT,
  
  -- AC 1: Input source tracking
  source_type TEXT NOT NULL CHECK (source_type IN ('text', 'pdf', 'docx', 'url', 'notes')),
  source_id UUID,  -- Reference to notes or uploaded file
  source_url TEXT,
  source_text_length INTEGER,
  
  -- AC 5: JSON structure
  structure_json JSONB NOT NULL DEFAULT '{"nodes": [], "edges": []}',
  
  -- AC 6: Cross-topic relationships
  relationships JSONB DEFAULT '[]',
  
  -- AC 10: Quality metrics
  quality_score DECIMAL(3,2) DEFAULT 0,
  concept_coverage DECIMAL(3,2) DEFAULT 0,
  key_concepts JSONB DEFAULT '[]',
  
  -- AC 8: Validation
  is_valid BOOLEAN DEFAULT TRUE,
  validation_errors JSONB DEFAULT '[]',
  max_depth INTEGER DEFAULT 0,
  node_count INTEGER DEFAULT 0,
  
  -- AC 9: Processing time
  generation_time_ms INTEGER,
  
  -- Metadata
  is_public BOOLEAN DEFAULT FALSE,
  tags TEXT[] DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_mindmaps_user ON public.mindmaps(user_id);
CREATE INDEX idx_mindmaps_source ON public.mindmaps(source_type);
CREATE INDEX idx_mindmaps_created ON public.mindmaps(created_at DESC);
CREATE INDEX idx_mindmaps_public ON public.mindmaps(is_public) WHERE is_public = TRUE;

-- RLS Policies
ALTER TABLE public.mindmaps ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own mindmaps"
  ON public.mindmaps FOR SELECT
  USING (auth.uid() = user_id OR is_public = TRUE);

CREATE POLICY "Users can insert own mindmaps"
  ON public.mindmaps FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own mindmaps"
  ON public.mindmaps FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own mindmaps"
  ON public.mindmaps FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================
-- AC 8: VALIDATION FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION validate_mindmap_structure(p_structure JSONB)
RETURNS TABLE (
  is_valid BOOLEAN,
  max_depth INTEGER,
  node_count INTEGER,
  orphan_nodes INTEGER,
  errors JSONB
) AS $$
DECLARE
  v_nodes JSONB;
  v_node JSONB;
  v_node_id TEXT;
  v_parent_id TEXT;
  v_valid BOOLEAN := TRUE;
  v_max_depth INTEGER := 0;
  v_node_count INTEGER := 0;
  v_orphans INTEGER := 0;
  v_errors JSONB := '[]'::jsonb;
  v_node_ids TEXT[] := '{}';
  v_parent_ids TEXT[] := '{}';
BEGIN
  v_nodes := COALESCE(p_structure->'nodes', '[]'::jsonb);
  v_node_count := jsonb_array_length(v_nodes);
  
  -- Collect all node IDs and parent IDs
  FOR v_node IN SELECT * FROM jsonb_array_elements(v_nodes)
  LOOP
    v_node_id := v_node->>'id';
    v_parent_id := v_node->>'parent_id';
    
    IF v_node_id IS NOT NULL THEN
      v_node_ids := array_append(v_node_ids, v_node_id);
    END IF;
    
    IF v_parent_id IS NOT NULL AND v_parent_id != '' THEN
      v_parent_ids := array_append(v_parent_ids, v_parent_id);
    END IF;
    
    -- Check depth (AC 8: reasonable depth < 5 levels)
    IF (v_node->>'level')::INTEGER > v_max_depth THEN
      v_max_depth := (v_node->>'level')::INTEGER;
    END IF;
  END LOOP;
  
  -- Check for orphan nodes (parent_id not in node_ids, except root)
  FOR i IN 1..array_length(v_parent_ids, 1)
  LOOP
    IF v_parent_ids[i] IS NOT NULL AND NOT v_parent_ids[i] = ANY(v_node_ids) THEN
      v_orphans := v_orphans + 1;
      v_valid := FALSE;
    END IF;
  END LOOP;
  
  -- Validate depth limit
  IF v_max_depth >= 5 THEN
    v_errors := v_errors || jsonb_build_array(jsonb_build_object('type', 'depth_exceeded', 'message', 'Mindmap exceeds 5 levels'));
    v_valid := FALSE;
  END IF;
  
  -- Check for empty mindmap
  IF v_node_count = 0 THEN
    v_errors := v_errors || jsonb_build_array(jsonb_build_object('type', 'empty', 'message', 'Mindmap has no nodes'));
    v_valid := FALSE;
  END IF;
  
  RETURN QUERY SELECT v_valid, v_max_depth, v_node_count, v_orphans, v_errors;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- SAVE MINDMAP FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION save_mindmap(
  p_user_id UUID,
  p_title TEXT,
  p_source_type TEXT,
  p_structure JSONB,
  p_source_text_length INTEGER DEFAULT 0,
  p_source_url TEXT DEFAULT NULL,
  p_generation_time_ms INTEGER DEFAULT 0,
  p_key_concepts JSONB DEFAULT '[]',
  p_relationships JSONB DEFAULT '[]'
)
RETURNS UUID AS $$
DECLARE
  v_id UUID;
  v_validation RECORD;
  v_quality DECIMAL;
BEGIN
  -- Validate structure
  SELECT * INTO v_validation FROM validate_mindmap_structure(p_structure);
  
  -- Calculate quality score based on coverage
  v_quality := CASE
    WHEN jsonb_array_length(p_key_concepts) = 0 THEN 0.5
    ELSE LEAST(1.0, (v_validation.node_count::DECIMAL / GREATEST(jsonb_array_length(p_key_concepts), 1)))
  END;
  
  INSERT INTO public.mindmaps (
    user_id, title, source_type, source_url, source_text_length,
    structure_json, relationships, key_concepts,
    is_valid, validation_errors, max_depth, node_count,
    generation_time_ms, quality_score, concept_coverage
  ) VALUES (
    p_user_id, p_title, p_source_type, p_source_url, p_source_text_length,
    p_structure, p_relationships, p_key_concepts,
    v_validation.is_valid, v_validation.errors, v_validation.max_depth, v_validation.node_count,
    p_generation_time_ms, v_quality, v_quality
  )
  RETURNING id INTO v_id;
  
  RETURN v_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- GET USER MINDMAPS
-- ============================================

CREATE OR REPLACE FUNCTION get_user_mindmaps(p_user_id UUID, p_limit INTEGER DEFAULT 20)
RETURNS TABLE (
  id UUID,
  title TEXT,
  source_type TEXT,
  node_count INTEGER,
  quality_score DECIMAL,
  is_valid BOOLEAN,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    m.id,
    m.title,
    m.source_type,
    m.node_count,
    m.quality_score,
    m.is_valid,
    m.created_at
  FROM public.mindmaps m
  WHERE m.user_id = p_user_id
  ORDER BY m.created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE public.mindmaps IS 'Story 9.4 AC 7: Mindmap storage with auto-generation';
COMMENT ON FUNCTION validate_mindmap_structure IS 'Story 9.4 AC 8: Validate tree structure';
COMMENT ON FUNCTION save_mindmap IS 'Story 9.4: Save mindmap with validation';

