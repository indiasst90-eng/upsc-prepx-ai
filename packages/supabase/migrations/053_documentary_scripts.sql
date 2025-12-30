-- Story 10.1: Documentary Script Generator - Long-Form Content
-- Migration 053: Documentary scripts table and functions

-- Create documentary_scripts table (AC 9)
CREATE TABLE IF NOT EXISTS public.documentary_scripts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID ,
  topic TEXT NOT NULL, -- AC 2: Single topic or chapter
  topic_category TEXT, -- e.g., "Modern Indian History", "Geography"
  
  -- AC 3: Target duration 2-3 hours (15000-20000 words)
  target_duration_minutes INTEGER DEFAULT 180,
  target_word_count INTEGER DEFAULT 18000,
  actual_word_count INTEGER DEFAULT 0,
  
  -- Script metadata
  title TEXT NOT NULL,
  description TEXT,
  
  -- AC 4: Script structure
  introduction JSONB, -- { narration, visual_markers[], duration_minutes }
  conclusion JSONB,   -- { narration, visual_markers[], duration_minutes }
  
  -- AC 5: RAG sources used
  rag_sources JSONB DEFAULT '[]'::jsonb, -- Array of { chunk_id, source, relevance_score }
  source_count INTEGER DEFAULT 0,
  
  -- AC 6: Visual markers summary
  visual_markers JSONB DEFAULT '[]'::jsonb, -- [DIAGRAM], [TIMELINE], [MAP], etc.
  
  -- AC 7, 8: Voice styles
  voice_style TEXT DEFAULT 'documentary', -- documentary, conversational, academic
  narrator_voice TEXT DEFAULT 'narrator',
  expert_voice TEXT DEFAULT 'expert',
  
  -- Status tracking (AC 9)
  status TEXT DEFAULT 'generating' CHECK (status IN (
    'generating', 'pending_visuals', 'pending_review', 'approved', 'published', 'failed'
  )),
  
  -- AC 10: Quality check results
  quality_score DECIMAL(3, 2), -- 0.00 to 1.00
  quality_feedback JSONB, -- { coherence, flow, upsc_relevance, suggestions[] }
  reviewed_at TIMESTAMPTZ,
  
  -- Generation metadata
  generation_model TEXT,
  generation_time_seconds INTEGER,
  error_message TEXT,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create documentary_chapters table (AC 4: 8-10 chapters, 15-20 min each)
CREATE TABLE IF NOT EXISTS public.documentary_chapters (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  script_id UUID NOT NULL REFERENCES public.documentary_scripts(id) ON DELETE CASCADE,
  
  chapter_number INTEGER NOT NULL,
  title TEXT NOT NULL,
  
  -- Content
  narration TEXT NOT NULL, -- Full chapter narration text
  word_count INTEGER DEFAULT 0,
  duration_minutes INTEGER DEFAULT 15,
  
  -- AC 6: Visual markers for this chapter
  visual_markers JSONB DEFAULT '[]'::jsonb, -- Array of { type, description, position }
  
  -- AC 8: Voice assignments
  voice_segments JSONB DEFAULT '[]'::jsonb, -- Array of { voice: narrator|expert, text, start_pos, end_pos }
  
  -- Timestamps for chapter markers
  start_time_seconds INTEGER,
  end_time_seconds INTEGER,
  
  -- Quality
  quality_score DECIMAL(3, 2),
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  UNIQUE(script_id, chapter_number)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_documentary_scripts_user ON public.documentary_scripts(user_id);
CREATE INDEX IF NOT EXISTS idx_documentary_scripts_status ON public.documentary_scripts(status);
CREATE INDEX IF NOT EXISTS idx_documentary_scripts_topic ON public.documentary_scripts(topic);
CREATE INDEX IF NOT EXISTS idx_documentary_chapters_script ON public.documentary_chapters(script_id);

-- Enable RLS
ALTER TABLE public.documentary_scripts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documentary_chapters ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view own documentary scripts"
  ON public.documentary_scripts FOR SELECT
  USING (auth.uid() = user_id OR status = 'published');

CREATE POLICY "Users can create documentary scripts"
  ON public.documentary_scripts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own documentary scripts"
  ON public.documentary_scripts FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own documentary scripts"
  ON public.documentary_scripts FOR DELETE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view chapters of accessible scripts"
  ON public.documentary_chapters FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.documentary_scripts s 
    WHERE s.id = script_id AND (s.user_id = auth.uid() OR s.status = 'published')
  ));

CREATE POLICY "System can manage chapters"
  ON public.documentary_chapters FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.documentary_scripts s 
    WHERE s.id = script_id AND s.user_id = auth.uid()
  ));

-- Function to create a new documentary script (AC 1, 2)
CREATE OR REPLACE FUNCTION create_documentary_script(
  p_user_id UUID,
  p_topic TEXT,
  p_topic_category TEXT DEFAULT NULL,
  p_target_duration INTEGER DEFAULT 180,
  p_voice_style TEXT DEFAULT 'documentary'
) RETURNS UUID AS $$
DECLARE
  v_script_id UUID;
  v_title TEXT;
  v_target_words INTEGER;
BEGIN
  -- Calculate target word count based on duration (approx 100 words/min for narration)
  v_target_words := p_target_duration * 100;
  
  -- Generate title from topic
  v_title := 'Documentary: ' || p_topic;
  
  INSERT INTO public.documentary_scripts (
    user_id, topic, topic_category, title,
    target_duration_minutes, target_word_count, voice_style
  ) VALUES (
    p_user_id, p_topic, p_topic_category, v_title,
    p_target_duration, v_target_words, p_voice_style
  )
  RETURNING id INTO v_script_id;
  
  RETURN v_script_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to add a chapter to a documentary script
CREATE OR REPLACE FUNCTION add_documentary_chapter(
  p_script_id UUID,
  p_chapter_number INTEGER,
  p_title TEXT,
  p_narration TEXT,
  p_visual_markers JSONB DEFAULT '[]'::jsonb,
  p_voice_segments JSONB DEFAULT '[]'::jsonb
) RETURNS UUID AS $$
DECLARE
  v_chapter_id UUID;
  v_word_count INTEGER;
  v_duration INTEGER;
BEGIN
  -- Calculate word count
  v_word_count := array_length(regexp_split_to_array(trim(p_narration), '\s+'), 1);
  
  -- Estimate duration (100 words/min)
  v_duration := CEIL(v_word_count::DECIMAL / 100);
  
  INSERT INTO public.documentary_chapters (
    script_id, chapter_number, title, narration,
    word_count, duration_minutes, visual_markers, voice_segments
  ) VALUES (
    p_script_id, p_chapter_number, p_title, p_narration,
    v_word_count, v_duration, p_visual_markers, p_voice_segments
  )
  RETURNING id INTO v_chapter_id;
  
  -- Update script word count
  UPDATE public.documentary_scripts
  SET actual_word_count = (
    SELECT COALESCE(SUM(word_count), 0) 
    FROM public.documentary_chapters 
    WHERE script_id = p_script_id
  ),
  updated_at = NOW()
  WHERE id = p_script_id;
  
  RETURN v_chapter_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update script status after all chapters added
CREATE OR REPLACE FUNCTION finalize_documentary_script(
  p_script_id UUID,
  p_introduction JSONB,
  p_conclusion JSONB,
  p_rag_sources JSONB
) RETURNS BOOLEAN AS $$
DECLARE
  v_chapter_count INTEGER;
  v_total_words INTEGER;
  v_visual_markers JSONB;
BEGIN
  -- Count chapters and words
  SELECT COUNT(*), COALESCE(SUM(word_count), 0)
  INTO v_chapter_count, v_total_words
  FROM public.documentary_chapters
  WHERE script_id = p_script_id;
  
  -- Aggregate all visual markers
  SELECT jsonb_agg(marker)
  INTO v_visual_markers
  FROM (
    SELECT jsonb_array_elements(visual_markers) as marker
    FROM public.documentary_chapters
    WHERE script_id = p_script_id
  ) markers;
  
  -- Update script
  UPDATE public.documentary_scripts
  SET 
    introduction = p_introduction,
    conclusion = p_conclusion,
    rag_sources = p_rag_sources,
    source_count = jsonb_array_length(p_rag_sources),
    visual_markers = COALESCE(v_visual_markers, '[]'::jsonb),
    actual_word_count = v_total_words,
    status = 'pending_visuals',
    updated_at = NOW()
  WHERE id = p_script_id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to record quality review (AC 10)
CREATE OR REPLACE FUNCTION review_documentary_script(
  p_script_id UUID,
  p_quality_score DECIMAL,
  p_quality_feedback JSONB
) RETURNS BOOLEAN AS $$
BEGIN
  UPDATE public.documentary_scripts
  SET 
    quality_score = p_quality_score,
    quality_feedback = p_quality_feedback,
    reviewed_at = NOW(),
    status = CASE 
      WHEN p_quality_score >= 0.7 THEN 'approved'
      ELSE 'pending_review'
    END,
    updated_at = NOW()
  WHERE id = p_script_id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get documentary script with all chapters
CREATE OR REPLACE FUNCTION get_documentary_script(p_script_id UUID)
RETURNS TABLE (
  script JSONB,
  chapters JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    to_jsonb(s) as script,
    COALESCE(
      (SELECT jsonb_agg(to_jsonb(c) ORDER BY c.chapter_number)
       FROM public.documentary_chapters c
       WHERE c.script_id = s.id),
      '[]'::jsonb
    ) as chapters
  FROM public.documentary_scripts s
  WHERE s.id = p_script_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user's documentary scripts
CREATE OR REPLACE FUNCTION get_user_documentary_scripts(
  p_user_id UUID,
  p_status TEXT DEFAULT NULL,
  p_limit INTEGER DEFAULT 20
) RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT jsonb_agg(script_data ORDER BY created_at DESC)
  INTO v_result
  FROM (
    SELECT jsonb_build_object(
      'id', s.id,
      'topic', s.topic,
      'title', s.title,
      'status', s.status,
      'target_duration_minutes', s.target_duration_minutes,
      'actual_word_count', s.actual_word_count,
      'quality_score', s.quality_score,
      'chapter_count', (SELECT COUNT(*) FROM public.documentary_chapters WHERE script_id = s.id),
      'created_at', s.created_at
    ) as script_data,
    s.created_at
    FROM public.documentary_scripts s
    WHERE s.user_id = p_user_id
      AND (p_status IS NULL OR s.status = p_status)
    LIMIT p_limit
  ) scripts;
  
  RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION create_documentary_script TO authenticated;
GRANT EXECUTE ON FUNCTION add_documentary_chapter TO authenticated;
GRANT EXECUTE ON FUNCTION finalize_documentary_script TO authenticated;
GRANT EXECUTE ON FUNCTION review_documentary_script TO authenticated;
GRANT EXECUTE ON FUNCTION get_documentary_script TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_documentary_scripts TO authenticated;

