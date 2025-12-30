-- Story 10.2: Documentary Chapter Assembly - Multi-Segment Rendering
-- Migration 054: Extend documentary system with rendering capabilities

-- Add rendering fields to documentary_chapters (AC 1, 5, 6, 7)
ALTER TABLE public.documentary_chapters
ADD COLUMN IF NOT EXISTS render_status TEXT DEFAULT 'pending' CHECK (render_status IN (
  'pending', 'queued', 'rendering', 'completed', 'failed', 'stitching'
)),
ADD COLUMN IF NOT EXISTS render_job_id TEXT,
ADD COLUMN IF NOT EXISTS video_url TEXT,
ADD COLUMN IF NOT EXISTS video_duration_seconds INTEGER,
ADD COLUMN IF NOT EXISTS render_started_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS render_completed_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS render_error TEXT,
ADD COLUMN IF NOT EXISTS render_attempts INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS audio_url TEXT, -- TTS audio
ADD COLUMN IF NOT EXISTS music_track TEXT, -- Background music (AC 3)
ADD COLUMN IF NOT EXISTS transition_type TEXT DEFAULT 'fade' CHECK (transition_type IN ('fade', 'slide', 'dissolve', 'wipe'));

-- Add final video fields to documentary_scripts (AC 8, 9)
ALTER TABLE public.documentary_scripts
ADD COLUMN IF NOT EXISTS final_video_url TEXT,
ADD COLUMN IF NOT EXISTS final_video_duration_seconds INTEGER,
ADD COLUMN IF NOT EXISTS final_render_status TEXT DEFAULT 'pending' CHECK (final_render_status IN (
  'pending', 'rendering_chapters', 'stitching', 'completed', 'failed'
)),
ADD COLUMN IF NOT EXISTS final_render_started_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS final_render_completed_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS credits_data JSONB, -- AC 9: End credits
ADD COLUMN IF NOT EXISTS music_config JSONB DEFAULT '{"track": "ambient_education", "volume": 0.15}'::jsonb,
ADD COLUMN IF NOT EXISTS quality_check_passed BOOLEAN DEFAULT FALSE, -- AC 10
ADD COLUMN IF NOT EXISTS quality_check_notes TEXT;

-- Create documentary_render_queue for managing parallel rendering (AC 1, 5)
CREATE TABLE IF NOT EXISTS public.documentary_render_queue (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  chapter_id UUID NOT NULL REFERENCES public.documentary_chapters(id) ON DELETE CASCADE,
  script_id UUID NOT NULL REFERENCES public.documentary_scripts(id) ON DELETE CASCADE,
  priority INTEGER DEFAULT 0,
  status TEXT DEFAULT 'queued' CHECK (status IN ('queued', 'processing', 'completed', 'failed')),
  worker_id TEXT,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  error_message TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(chapter_id)
);

-- Create documentary_template_config for chapter templates (AC 2)
CREATE TABLE IF NOT EXISTS public.documentary_template_config (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  config JSONB NOT NULL DEFAULT '{
    "title_card_duration": 5,
    "intro_animation_duration": 3,
    "summary_overlay_duration": 30,
    "transition_duration": 2,
    "title_font": "Roboto",
    "title_color": "#FFFFFF",
    "background_color": "#1a1a2e",
    "accent_color": "#4ECDC4"
  }'::jsonb,
  is_default BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Insert default template
INSERT INTO public.documentary_template_config (name, description, is_default)
VALUES ('DocumentaryChapterTemplate', 'Default documentary chapter template with title cards, animations, and transitions', TRUE)
ON CONFLICT (name) DO NOTHING;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_doc_chapters_render_status ON public.documentary_chapters(render_status);
CREATE INDEX IF NOT EXISTS idx_doc_render_queue_status ON public.documentary_render_queue(status);
CREATE INDEX IF NOT EXISTS idx_doc_render_queue_priority ON public.documentary_render_queue(priority DESC, created_at ASC);
CREATE INDEX IF NOT EXISTS idx_doc_scripts_final_status ON public.documentary_scripts(final_render_status);

-- Enable RLS on new table
ALTER TABLE public.documentary_render_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documentary_template_config ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view render queue for own scripts"
  ON public.documentary_render_queue FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.documentary_scripts s 
    WHERE s.id = script_id AND s.user_id = auth.uid()
  ));

CREATE POLICY "Anyone can view template configs"
  ON public.documentary_template_config FOR SELECT
  USING (TRUE);

-- Function to queue all chapters for rendering (AC 1)
CREATE OR REPLACE FUNCTION queue_documentary_rendering(
  p_script_id UUID,
  p_max_concurrency INTEGER DEFAULT 4
) RETURNS INTEGER AS $$
DECLARE
  v_chapter RECORD;
  v_queued_count INTEGER := 0;
  v_priority INTEGER := 0;
BEGIN
  -- Update script status
  UPDATE public.documentary_scripts
  SET final_render_status = 'rendering_chapters',
      final_render_started_at = NOW(),
      updated_at = NOW()
  WHERE id = p_script_id;
  
  -- Queue each chapter
  FOR v_chapter IN 
    SELECT id, chapter_number 
    FROM public.documentary_chapters 
    WHERE script_id = p_script_id 
    ORDER BY chapter_number
  LOOP
    -- Insert into queue with priority (earlier chapters = higher priority)
    INSERT INTO public.documentary_render_queue (chapter_id, script_id, priority)
    VALUES (v_chapter.id, p_script_id, 100 - v_chapter.chapter_number)
    ON CONFLICT (chapter_id) DO UPDATE SET
      status = 'queued',
      priority = EXCLUDED.priority,
      started_at = NULL,
      completed_at = NULL,
      error_message = NULL;
    
    -- Update chapter status
    UPDATE public.documentary_chapters
    SET render_status = 'queued',
        render_attempts = 0,
        render_error = NULL
    WHERE id = v_chapter.id;
    
    v_queued_count := v_queued_count + 1;
  END LOOP;
  
  RETURN v_queued_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get next chapter to render (AC 5: max concurrency)
CREATE OR REPLACE FUNCTION get_next_chapter_to_render(
  p_max_concurrency INTEGER DEFAULT 4,
  p_worker_id TEXT DEFAULT NULL
) RETURNS TABLE (
  queue_id UUID,
  chapter_id UUID,
  script_id UUID,
  chapter_number INTEGER,
  title TEXT,
  narration TEXT,
  visual_markers JSONB,
  voice_segments JSONB,
  music_track TEXT,
  transition_type TEXT,
  template_config JSONB
) AS $$
DECLARE
  v_current_processing INTEGER;
  v_queue_item RECORD;
BEGIN
  -- Check current processing count
  SELECT COUNT(*) INTO v_current_processing
  FROM public.documentary_render_queue
  WHERE status = 'processing';
  
  IF v_current_processing >= p_max_concurrency THEN
    RETURN;
  END IF;
  
  -- Get next queued item
  SELECT q.id, q.chapter_id, q.script_id
  INTO v_queue_item
  FROM public.documentary_render_queue q
  WHERE q.status = 'queued'
  ORDER BY q.priority DESC, q.created_at ASC
  LIMIT 1
  FOR UPDATE SKIP LOCKED;
  
  IF v_queue_item IS NULL THEN
    RETURN;
  END IF;
  
  -- Mark as processing
  UPDATE public.documentary_render_queue
  SET status = 'processing',
      worker_id = p_worker_id,
      started_at = NOW()
  WHERE id = v_queue_item.id;
  
  UPDATE public.documentary_chapters
  SET render_status = 'rendering',
      render_started_at = NOW(),
      render_attempts = render_attempts + 1
  WHERE id = v_queue_item.chapter_id;
  
  -- Return chapter data with template
  RETURN QUERY
  SELECT 
    v_queue_item.id as queue_id,
    c.id as chapter_id,
    c.script_id,
    c.chapter_number,
    c.title,
    c.narration,
    c.visual_markers,
    c.voice_segments,
    c.music_track,
    c.transition_type,
    t.config as template_config
  FROM public.documentary_chapters c
  CROSS JOIN public.documentary_template_config t
  WHERE c.id = v_queue_item.chapter_id
    AND t.is_default = TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to mark chapter render complete (AC 6)
CREATE OR REPLACE FUNCTION complete_chapter_render(
  p_queue_id UUID,
  p_video_url TEXT,
  p_video_duration INTEGER,
  p_audio_url TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
  v_chapter_id UUID;
  v_script_id UUID;
  v_all_complete BOOLEAN;
BEGIN
  -- Get chapter info
  SELECT chapter_id, script_id INTO v_chapter_id, v_script_id
  FROM public.documentary_render_queue
  WHERE id = p_queue_id;
  
  IF v_chapter_id IS NULL THEN
    RETURN FALSE;
  END IF;
  
  -- Update queue
  UPDATE public.documentary_render_queue
  SET status = 'completed',
      completed_at = NOW()
  WHERE id = p_queue_id;
  
  -- Update chapter
  UPDATE public.documentary_chapters
  SET render_status = 'completed',
      video_url = p_video_url,
      video_duration_seconds = p_video_duration,
      audio_url = COALESCE(p_audio_url, audio_url),
      render_completed_at = NOW()
  WHERE id = v_chapter_id;
  
  -- Check if all chapters complete
  SELECT NOT EXISTS (
    SELECT 1 FROM public.documentary_chapters
    WHERE script_id = v_script_id
      AND render_status NOT IN ('completed')
  ) INTO v_all_complete;
  
  -- If all complete, trigger stitching
  IF v_all_complete THEN
    UPDATE public.documentary_scripts
    SET final_render_status = 'stitching'
    WHERE id = v_script_id;
  END IF;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to mark chapter render failed
CREATE OR REPLACE FUNCTION fail_chapter_render(
  p_queue_id UUID,
  p_error_message TEXT
) RETURNS BOOLEAN AS $$
DECLARE
  v_chapter_id UUID;
BEGIN
  SELECT chapter_id INTO v_chapter_id
  FROM public.documentary_render_queue
  WHERE id = p_queue_id;
  
  UPDATE public.documentary_render_queue
  SET status = 'failed',
      completed_at = NOW(),
      error_message = p_error_message
  WHERE id = p_queue_id;
  
  UPDATE public.documentary_chapters
  SET render_status = 'failed',
      render_error = p_error_message,
      render_completed_at = NOW()
  WHERE id = v_chapter_id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to complete final video stitching (AC 8)
CREATE OR REPLACE FUNCTION complete_documentary_stitch(
  p_script_id UUID,
  p_final_video_url TEXT,
  p_total_duration INTEGER,
  p_quality_passed BOOLEAN DEFAULT TRUE,
  p_quality_notes TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
BEGIN
  UPDATE public.documentary_scripts
  SET final_video_url = p_final_video_url,
      final_video_duration_seconds = p_total_duration,
      final_render_status = 'completed',
      final_render_completed_at = NOW(),
      quality_check_passed = p_quality_passed,
      quality_check_notes = p_quality_notes,
      status = 'published',
      updated_at = NOW()
  WHERE id = p_script_id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get rendering progress
CREATE OR REPLACE FUNCTION get_documentary_render_progress(p_script_id UUID)
RETURNS TABLE (
  total_chapters INTEGER,
  completed_chapters INTEGER,
  failed_chapters INTEGER,
  rendering_chapters INTEGER,
  queued_chapters INTEGER,
  estimated_time_remaining_minutes INTEGER,
  final_status TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*)::INTEGER as total_chapters,
    COUNT(*) FILTER (WHERE c.render_status = 'completed')::INTEGER as completed_chapters,
    COUNT(*) FILTER (WHERE c.render_status = 'failed')::INTEGER as failed_chapters,
    COUNT(*) FILTER (WHERE c.render_status = 'rendering')::INTEGER as rendering_chapters,
    COUNT(*) FILTER (WHERE c.render_status = 'queued')::INTEGER as queued_chapters,
    (COUNT(*) FILTER (WHERE c.render_status IN ('queued', 'rendering')) * 20)::INTEGER as estimated_time_remaining_minutes,
    s.final_render_status as final_status
  FROM public.documentary_chapters c
  JOIN public.documentary_scripts s ON s.id = c.script_id
  WHERE c.script_id = p_script_id
  GROUP BY s.final_render_status;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to set credits data (AC 9)
CREATE OR REPLACE FUNCTION set_documentary_credits(
  p_script_id UUID,
  p_credits JSONB
) RETURNS BOOLEAN AS $$
BEGIN
  UPDATE public.documentary_scripts
  SET credits_data = p_credits,
      updated_at = NOW()
  WHERE id = p_script_id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION queue_documentary_rendering TO authenticated;
GRANT EXECUTE ON FUNCTION get_next_chapter_to_render TO authenticated;
GRANT EXECUTE ON FUNCTION complete_chapter_render TO authenticated;
GRANT EXECUTE ON FUNCTION fail_chapter_render TO authenticated;
GRANT EXECUTE ON FUNCTION complete_documentary_stitch TO authenticated;
GRANT EXECUTE ON FUNCTION get_documentary_render_progress TO authenticated;
GRANT EXECUTE ON FUNCTION set_documentary_credits TO authenticated;

