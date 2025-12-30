-- Story 10.3: Weekly Documentary - Current Affairs Analysis
-- Migration 055: Weekly documentary tables and functions

-- Create weekly_documentaries table (AC 2, 6, 8, 9)
CREATE TABLE IF NOT EXISTS public.weekly_documentaries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Week identifier
  week_start_date DATE NOT NULL,
  week_end_date DATE NOT NULL,
  week_number INTEGER NOT NULL,
  year INTEGER NOT NULL,
  
  -- Content
  title TEXT NOT NULL, -- e.g., "Week 52, 2025: Key UPSC Current Affairs"
  description TEXT,
  
  -- AC 3: Top topics extracted
  top_topics JSONB DEFAULT '[]'::jsonb, -- Array of { topic, category, importance_score, daily_ca_ids[] }
  
  -- AC 4: Script structure
  script_content JSONB, -- { week_overview, top_stories[], segments[], expert_quotes[], quiz_preview }
  
  -- AC 5: Manim visuals
  manim_scenes JSONB DEFAULT '[]'::jsonb, -- Data charts, timelines, comparisons
  
  -- Video details (AC 6)
  video_url TEXT,
  video_duration_seconds INTEGER, -- 15-30 minutes = 900-1800 seconds
  thumbnail_url TEXT,
  
  -- AC 10: Social clips
  social_clips JSONB DEFAULT '[]'::jsonb, -- Array of { id, url, title, duration_seconds, platform }
  
  -- Rendering (AC 7)
  render_priority INTEGER DEFAULT 50, -- 0-100, where lower = higher priority
  render_status TEXT DEFAULT 'pending' CHECK (render_status IN (
    'pending', 'aggregating', 'scripting', 'rendering', 'published', 'failed'
  )),
  render_started_at TIMESTAMPTZ,
  render_completed_at TIMESTAMPTZ,
  
  -- AC 8: Publish schedule
  scheduled_publish_at TIMESTAMPTZ, -- Monday 8 AM
  published_at TIMESTAMPTZ,
  
  -- Source tracking (AC 2)
  daily_ca_ids UUID[] DEFAULT '{}', -- References to daily CA videos used
  source_news_count INTEGER DEFAULT 0,
  
  -- Metadata
  view_count INTEGER DEFAULT 0,
  like_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  UNIQUE(year, week_number)
);

-- Create weekly_doc_segments table for detailed segment storage
CREATE TABLE IF NOT EXISTS public.weekly_doc_segments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  documentary_id UUID NOT NULL REFERENCES public.weekly_documentaries(id) ON DELETE CASCADE,
  
  segment_type TEXT NOT NULL CHECK (segment_type IN (
    'week_overview', 'top_story', 'economy', 'polity', 'ir', 'environment', 
    'science_tech', 'expert_interview', 'quiz_preview'
  )),
  segment_order INTEGER NOT NULL,
  title TEXT NOT NULL,
  
  -- Content
  narration TEXT NOT NULL,
  duration_seconds INTEGER,
  
  -- Visual assets
  manim_scene_id TEXT, -- Reference to manim scene
  visual_assets JSONB DEFAULT '[]'::jsonb,
  
  -- For expert interviews (AC 4)
  expert_name TEXT,
  expert_title TEXT,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  UNIQUE(documentary_id, segment_order)
);

-- Create weekly_doc_schedule for cron job tracking (AC 1)
CREATE TABLE IF NOT EXISTS public.weekly_doc_schedule (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  scheduled_time TIMESTAMPTZ NOT NULL, -- Sunday 8 PM IST
  triggered_at TIMESTAMPTZ,
  documentary_id UUID REFERENCES public.weekly_documentaries(id),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'running', 'completed', 'failed')),
  error_message TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_weekly_docs_year_week ON public.weekly_documentaries(year, week_number);
CREATE INDEX IF NOT EXISTS idx_weekly_docs_status ON public.weekly_documentaries(render_status);
CREATE INDEX IF NOT EXISTS idx_weekly_docs_published ON public.weekly_documentaries(published_at);
CREATE INDEX IF NOT EXISTS idx_weekly_segments_doc ON public.weekly_doc_segments(documentary_id);

-- Enable RLS
ALTER TABLE public.weekly_documentaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weekly_doc_segments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weekly_doc_schedule ENABLE ROW LEVEL SECURITY;

-- RLS Policies - publicly viewable when published
CREATE POLICY "Anyone can view published weekly documentaries"
  ON public.weekly_documentaries FOR SELECT
  USING (render_status = 'published');

CREATE POLICY "Anyone can view segments of published documentaries"
  ON public.weekly_doc_segments FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.weekly_documentaries d 
    WHERE d.id = documentary_id AND d.render_status = 'published'
  ));

-- Service role policies for generation
CREATE POLICY "Service can manage weekly documentaries"
  ON public.weekly_documentaries FOR ALL
  USING (TRUE)
  WITH CHECK (TRUE);

CREATE POLICY "Service can manage segments"
  ON public.weekly_doc_segments FOR ALL
  USING (TRUE)
  WITH CHECK (TRUE);

-- Function to create weekly documentary (AC 1, 2)
CREATE OR REPLACE FUNCTION create_weekly_documentary(
  p_week_start DATE DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
  v_doc_id UUID;
  v_week_start DATE;
  v_week_end DATE;
  v_week_num INTEGER;
  v_year INTEGER;
  v_title TEXT;
BEGIN
  -- Calculate week dates (default to current week)
  v_week_start := COALESCE(p_week_start, date_trunc('week', CURRENT_DATE)::DATE);
  v_week_end := v_week_start + INTERVAL '6 days';
  v_week_num := EXTRACT(WEEK FROM v_week_start);
  v_year := EXTRACT(YEAR FROM v_week_start);
  
  v_title := 'Week ' || v_week_num || ', ' || v_year || ': UPSC Current Affairs Analysis';
  
  -- Create documentary record
  INSERT INTO public.weekly_documentaries (
    week_start_date, week_end_date, week_number, year, title,
    scheduled_publish_at, render_priority
  ) VALUES (
    v_week_start, v_week_end, v_week_num, v_year, v_title,
    (v_week_end + INTERVAL '1 day' + INTERVAL '8 hours'), -- Monday 8 AM
    50 -- Medium priority (AC 7)
  )
  ON CONFLICT (year, week_number) DO UPDATE
  SET updated_at = NOW()
  RETURNING id INTO v_doc_id;
  
  RETURN v_doc_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to aggregate daily CA content (AC 2)
CREATE OR REPLACE FUNCTION aggregate_weekly_content(
  p_doc_id UUID
) RETURNS JSONB AS $$
DECLARE
  v_doc RECORD;
  v_daily_ca JSONB;
  v_topics JSONB;
BEGIN
  SELECT * INTO v_doc FROM public.weekly_documentaries WHERE id = p_doc_id;
  
  IF v_doc IS NULL THEN
    RETURN jsonb_build_object('error', 'Documentary not found');
  END IF;
  
  -- Update status
  UPDATE public.weekly_documentaries
  SET render_status = 'aggregating',
      render_started_at = NOW()
  WHERE id = p_doc_id;
  
  -- In production, this would fetch actual daily CA videos
  -- For now, we simulate the aggregation
  v_daily_ca := jsonb_build_object(
    'video_count', 7,
    'topic_count', 35,
    'categories', jsonb_build_array('Economy', 'Polity', 'IR', 'Environment', 'Science')
  );
  
  RETURN v_daily_ca;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to extract top topics (AC 3)
CREATE OR REPLACE FUNCTION extract_weekly_topics(
  p_doc_id UUID,
  p_topics JSONB
) RETURNS BOOLEAN AS $$
BEGIN
  UPDATE public.weekly_documentaries
  SET top_topics = p_topics,
      source_news_count = jsonb_array_length(p_topics),
      render_status = 'scripting',
      updated_at = NOW()
  WHERE id = p_doc_id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to save script content (AC 4)
CREATE OR REPLACE FUNCTION save_weekly_script(
  p_doc_id UUID,
  p_script_content JSONB,
  p_segments JSONB
) RETURNS BOOLEAN AS $$
DECLARE
  v_segment JSONB;
  v_order INTEGER := 0;
BEGIN
  -- Save script content
  UPDATE public.weekly_documentaries
  SET script_content = p_script_content,
      updated_at = NOW()
  WHERE id = p_doc_id;
  
  -- Delete existing segments
  DELETE FROM public.weekly_doc_segments WHERE documentary_id = p_doc_id;
  
  -- Insert new segments
  FOR v_segment IN SELECT * FROM jsonb_array_elements(p_segments)
  LOOP
    v_order := v_order + 1;
    INSERT INTO public.weekly_doc_segments (
      documentary_id, segment_type, segment_order, title, narration,
      duration_seconds, expert_name, expert_title
    ) VALUES (
      p_doc_id,
      v_segment->>'segment_type',
      v_order,
      v_segment->>'title',
      v_segment->>'narration',
      (v_segment->>'duration_seconds')::INTEGER,
      v_segment->>'expert_name',
      v_segment->>'expert_title'
    );
  END LOOP;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to complete rendering and publish (AC 8)
CREATE OR REPLACE FUNCTION publish_weekly_documentary(
  p_doc_id UUID,
  p_video_url TEXT,
  p_duration INTEGER,
  p_thumbnail TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
BEGIN
  UPDATE public.weekly_documentaries
  SET video_url = p_video_url,
      video_duration_seconds = p_duration,
      thumbnail_url = p_thumbnail,
      render_status = 'published',
      render_completed_at = NOW(),
      published_at = NOW(),
      updated_at = NOW()
  WHERE id = p_doc_id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to add social clips (AC 10)
CREATE OR REPLACE FUNCTION add_social_clips(
  p_doc_id UUID,
  p_clips JSONB
) RETURNS BOOLEAN AS $$
BEGIN
  UPDATE public.weekly_documentaries
  SET social_clips = p_clips,
      updated_at = NOW()
  WHERE id = p_doc_id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get weekly documentary archive (AC 9)
CREATE OR REPLACE FUNCTION get_weekly_documentary_archive(
  p_year INTEGER DEFAULT NULL,
  p_limit INTEGER DEFAULT 12
) RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT jsonb_agg(doc ORDER BY week_start_date DESC)
  INTO v_result
  FROM (
    SELECT jsonb_build_object(
      'id', id,
      'title', title,
      'week_number', week_number,
      'year', year,
      'week_start_date', week_start_date,
      'week_end_date', week_end_date,
      'video_url', video_url,
      'video_duration_seconds', video_duration_seconds,
      'thumbnail_url', thumbnail_url,
      'view_count', view_count,
      'published_at', published_at,
      'top_topics_count', jsonb_array_length(top_topics)
    ) as doc,
    week_start_date
    FROM public.weekly_documentaries
    WHERE render_status = 'published'
      AND (p_year IS NULL OR year = p_year)
    ORDER BY week_start_date DESC
    LIMIT p_limit
  ) docs;
  
  RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get single weekly documentary with segments
CREATE OR REPLACE FUNCTION get_weekly_documentary(p_doc_id UUID)
RETURNS TABLE (
  documentary JSONB,
  segments JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    to_jsonb(d) as documentary,
    COALESCE(
      (SELECT jsonb_agg(to_jsonb(s) ORDER BY s.segment_order)
       FROM public.weekly_doc_segments s
       WHERE s.documentary_id = d.id),
      '[]'::jsonb
    ) as segments
  FROM public.weekly_documentaries d
  WHERE d.id = p_doc_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to increment view count
CREATE OR REPLACE FUNCTION increment_weekly_doc_views(p_doc_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE public.weekly_documentaries
  SET view_count = view_count + 1
  WHERE id = p_doc_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION create_weekly_documentary TO authenticated;
GRANT EXECUTE ON FUNCTION aggregate_weekly_content TO authenticated;
GRANT EXECUTE ON FUNCTION extract_weekly_topics TO authenticated;
GRANT EXECUTE ON FUNCTION save_weekly_script TO authenticated;
GRANT EXECUTE ON FUNCTION publish_weekly_documentary TO authenticated;
GRANT EXECUTE ON FUNCTION add_social_clips TO authenticated;
GRANT EXECUTE ON FUNCTION get_weekly_documentary_archive TO authenticated;
GRANT EXECUTE ON FUNCTION get_weekly_documentary TO authenticated;
GRANT EXECUTE ON FUNCTION increment_weekly_doc_views TO authenticated;

