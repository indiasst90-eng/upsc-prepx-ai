-- Story 10.4: Documentary Library - CDN Delivery & Chapter Navigation
-- Migration 056: Watch progress, downloads, CDN delivery, and library features

-- Add CDN and quality fields to documentary_scripts (AC 7, 8)
ALTER TABLE public.documentary_scripts
ADD COLUMN IF NOT EXISTS cdn_url TEXT,
ADD COLUMN IF NOT EXISTS cdn_provider TEXT DEFAULT 'cloudflare',
ADD COLUMN IF NOT EXISTS quality_versions JSONB DEFAULT '[]'::jsonb, -- [{quality: '1080p', url, size_mb}, ...]
ADD COLUMN IF NOT EXISTS transcript_pdf_url TEXT,
ADD COLUMN IF NOT EXISTS subject TEXT,
ADD COLUMN IF NOT EXISTS is_published BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS published_at TIMESTAMPTZ;

-- Add chapter markers to documentary_chapters (AC 3)
ALTER TABLE public.documentary_chapters
ADD COLUMN IF NOT EXISTS start_time_seconds INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS end_time_seconds INTEGER,
ADD COLUMN IF NOT EXISTS chapter_thumbnail_url TEXT;

-- Create user watch progress table (AC 4)
CREATE TABLE IF NOT EXISTS public.documentary_watch_progress (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL ,
  documentary_id UUID NOT NULL REFERENCES public.documentary_scripts(id) ON DELETE CASCADE,
  
  -- Progress tracking (AC 4)
  current_chapter_id UUID REFERENCES public.documentary_chapters(id),
  current_position_seconds INTEGER DEFAULT 0,
  total_watched_seconds INTEGER DEFAULT 0,
  completion_percentage DECIMAL(5, 2) DEFAULT 0,
  
  -- Watch history
  last_watched_at TIMESTAMPTZ DEFAULT NOW(),
  watch_count INTEGER DEFAULT 1,
  completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  
  -- Playback preferences
  preferred_quality TEXT DEFAULT '720p',
  playback_speed DECIMAL(2, 1) DEFAULT 1.0,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  UNIQUE(user_id, documentary_id)
);

-- Create chapter watch progress (for detailed tracking)
CREATE TABLE IF NOT EXISTS public.chapter_watch_progress (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL ,
  chapter_id UUID NOT NULL REFERENCES public.documentary_chapters(id) ON DELETE CASCADE,
  documentary_id UUID NOT NULL REFERENCES public.documentary_scripts(id) ON DELETE CASCADE,
  
  watched_seconds INTEGER DEFAULT 0,
  completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  UNIQUE(user_id, chapter_id)
);

-- Create downloads table (AC 5)
CREATE TABLE IF NOT EXISTS public.documentary_downloads (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL ,
  documentary_id UUID NOT NULL REFERENCES public.documentary_scripts(id) ON DELETE CASCADE,
  chapter_id UUID REFERENCES public.documentary_chapters(id), -- NULL for full documentary
  
  -- Download details (AC 5)
  download_type TEXT NOT NULL CHECK (download_type IN ('full', 'chapter')),
  quality TEXT NOT NULL DEFAULT '720p',
  file_size_mb INTEGER,
  download_url TEXT,
  
  -- Status
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'downloading', 'completed', 'expired', 'failed')),
  expires_at TIMESTAMPTZ, -- Download links expire
  downloaded_at TIMESTAMPTZ,
  
  -- Pro user check (AC 5)
  is_pro_user BOOLEAN DEFAULT FALSE,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create offline cache registry (AC 6)
CREATE TABLE IF NOT EXISTS public.documentary_offline_cache (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL ,
  documentary_id UUID NOT NULL REFERENCES public.documentary_scripts(id) ON DELETE CASCADE,
  
  -- Cache details (AC 6: up to 500MB per video)
  cache_size_mb INTEGER DEFAULT 0,
  quality TEXT DEFAULT '720p',
  cached_chapters UUID[] DEFAULT '{}',
  
  -- PWA cache
  cache_status TEXT DEFAULT 'none' CHECK (cache_status IN ('none', 'caching', 'cached', 'error')),
  cached_at TIMESTAMPTZ,
  last_accessed_at TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  UNIQUE(user_id, documentary_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_watch_progress_user ON public.documentary_watch_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_watch_progress_doc ON public.documentary_watch_progress(documentary_id);
CREATE INDEX IF NOT EXISTS idx_watch_progress_last ON public.documentary_watch_progress(last_watched_at DESC);
CREATE INDEX IF NOT EXISTS idx_chapter_progress_user ON public.chapter_watch_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_downloads_user ON public.documentary_downloads(user_id);
CREATE INDEX IF NOT EXISTS idx_offline_cache_user ON public.documentary_offline_cache(user_id);
CREATE INDEX IF NOT EXISTS idx_doc_scripts_published ON public.documentary_scripts(is_published) WHERE is_published = TRUE;
CREATE INDEX IF NOT EXISTS idx_doc_scripts_subject ON public.documentary_scripts(subject);

-- Enable RLS
ALTER TABLE public.documentary_watch_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chapter_watch_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documentary_downloads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documentary_offline_cache ENABLE ROW LEVEL SECURITY;

-- RLS Policies - users can only access their own data
CREATE POLICY "Users can view own watch progress"
  ON public.documentary_watch_progress FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own watch progress"
  ON public.documentary_watch_progress FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own chapter progress"
  ON public.chapter_watch_progress FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own chapter progress"
  ON public.chapter_watch_progress FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own downloads"
  ON public.documentary_downloads FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own downloads"
  ON public.documentary_downloads FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own offline cache"
  ON public.documentary_offline_cache FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own offline cache"
  ON public.documentary_offline_cache FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Function to update watch progress (AC 4)
CREATE OR REPLACE FUNCTION update_watch_progress(
  p_user_id UUID,
  p_documentary_id UUID,
  p_chapter_id UUID DEFAULT NULL,
  p_position_seconds INTEGER DEFAULT 0,
  p_quality TEXT DEFAULT '720p',
  p_speed DECIMAL DEFAULT 1.0
) RETURNS JSONB AS $$
DECLARE
  v_total_duration INTEGER;
  v_completion DECIMAL;
  v_result JSONB;
BEGIN
  -- Get total documentary duration
  SELECT COALESCE(SUM(duration_minutes * 60), 0)
  INTO v_total_duration
  FROM public.documentary_chapters
  WHERE script_id = p_documentary_id;
  
  -- Calculate completion percentage
  v_completion := CASE 
    WHEN v_total_duration > 0 THEN (p_position_seconds::DECIMAL / v_total_duration) * 100
    ELSE 0 
  END;
  
  -- Upsert watch progress
  INSERT INTO public.documentary_watch_progress (
    user_id, documentary_id, current_chapter_id, current_position_seconds,
    total_watched_seconds, completion_percentage, preferred_quality, playback_speed,
    last_watched_at, watch_count
  ) VALUES (
    p_user_id, p_documentary_id, p_chapter_id, p_position_seconds,
    p_position_seconds, LEAST(v_completion, 100), p_quality, p_speed,
    NOW(), 1
  )
  ON CONFLICT (user_id, documentary_id) 
  DO UPDATE SET
    current_chapter_id = COALESCE(EXCLUDED.current_chapter_id, documentary_watch_progress.current_chapter_id),
    current_position_seconds = EXCLUDED.current_position_seconds,
    total_watched_seconds = GREATEST(documentary_watch_progress.total_watched_seconds, EXCLUDED.total_watched_seconds),
    completion_percentage = LEAST(EXCLUDED.completion_percentage, 100),
    preferred_quality = EXCLUDED.preferred_quality,
    playback_speed = EXCLUDED.playback_speed,
    last_watched_at = NOW(),
    watch_count = documentary_watch_progress.watch_count + 1,
    completed = CASE WHEN EXCLUDED.completion_percentage >= 95 THEN TRUE ELSE documentary_watch_progress.completed END,
    completed_at = CASE WHEN EXCLUDED.completion_percentage >= 95 AND documentary_watch_progress.completed_at IS NULL THEN NOW() ELSE documentary_watch_progress.completed_at END,
    updated_at = NOW();
  
  SELECT jsonb_build_object(
    'success', true,
    'position', p_position_seconds,
    'completion', LEAST(v_completion, 100)
  ) INTO v_result;
  
  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get resume position (AC 4)
CREATE OR REPLACE FUNCTION get_resume_position(
  p_user_id UUID,
  p_documentary_id UUID
) RETURNS JSONB AS $$
DECLARE
  v_progress RECORD;
BEGIN
  SELECT * INTO v_progress
  FROM public.documentary_watch_progress
  WHERE user_id = p_user_id AND documentary_id = p_documentary_id;
  
  IF v_progress IS NULL THEN
    RETURN jsonb_build_object(
      'has_progress', false,
      'position', 0,
      'chapter_id', null
    );
  END IF;
  
  RETURN jsonb_build_object(
    'has_progress', true,
    'position', v_progress.current_position_seconds,
    'chapter_id', v_progress.current_chapter_id,
    'completion', v_progress.completion_percentage,
    'quality', v_progress.preferred_quality,
    'speed', v_progress.playback_speed,
    'last_watched', v_progress.last_watched_at
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to request download (AC 5)
CREATE OR REPLACE FUNCTION request_documentary_download(
  p_user_id UUID,
  p_documentary_id UUID,
  p_chapter_id UUID DEFAULT NULL,
  p_quality TEXT DEFAULT '720p',
  p_is_pro BOOLEAN DEFAULT FALSE
) RETURNS JSONB AS $$
DECLARE
  v_download_id UUID;
  v_download_type TEXT;
BEGIN
  -- Check if user is Pro (AC 5)
  IF NOT p_is_pro THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Download requires Pro subscription'
    );
  END IF;
  
  v_download_type := CASE WHEN p_chapter_id IS NULL THEN 'full' ELSE 'chapter' END;
  
  INSERT INTO public.documentary_downloads (
    user_id, documentary_id, chapter_id, download_type, quality, 
    is_pro_user, status, expires_at
  ) VALUES (
    p_user_id, p_documentary_id, p_chapter_id, v_download_type, p_quality,
    p_is_pro, 'pending', NOW() + INTERVAL '24 hours'
  )
  RETURNING id INTO v_download_id;
  
  RETURN jsonb_build_object(
    'success', true,
    'download_id', v_download_id,
    'type', v_download_type,
    'expires_in', '24 hours'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get documentary library with filters (AC 1)
CREATE OR REPLACE FUNCTION get_documentary_library(
  p_user_id UUID DEFAULT NULL,
  p_subject TEXT DEFAULT NULL,
  p_min_duration INTEGER DEFAULT NULL,
  p_max_duration INTEGER DEFAULT NULL,
  p_topic TEXT DEFAULT NULL,
  p_limit INTEGER DEFAULT 20,
  p_offset INTEGER DEFAULT 0
) RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT jsonb_agg(doc)
  INTO v_result
  FROM (
    SELECT jsonb_build_object(
      'id', d.id,
      'title', d.topic,
      'subject', d.subject,
      'description', LEFT(d.introduction->>'content', 200),
      'duration_minutes', d.target_duration_minutes,
      'chapter_count', (SELECT COUNT(*) FROM public.documentary_chapters c WHERE c.script_id = d.id),
      'cdn_url', d.cdn_url,
      'thumbnail_url', COALESCE(
        (SELECT chapter_thumbnail_url FROM public.documentary_chapters c WHERE c.script_id = d.id ORDER BY chapter_number LIMIT 1),
        '/images/doc-placeholder.jpg'
      ),
      'quality_versions', d.quality_versions,
      'transcript_available', d.transcript_pdf_url IS NOT NULL,
      'published_at', d.published_at,
      'view_count', COALESCE(d.view_count, 0),
      'user_progress', CASE 
        WHEN p_user_id IS NOT NULL THEN (
          SELECT jsonb_build_object(
            'position', wp.current_position_seconds,
            'completion', wp.completion_percentage,
            'completed', wp.completed
          )
          FROM public.documentary_watch_progress wp
          WHERE wp.user_id = p_user_id AND wp.documentary_id = d.id
        )
        ELSE NULL
      END
    ) as doc
    FROM public.documentary_scripts d
    WHERE d.is_published = TRUE
      AND (p_subject IS NULL OR d.subject = p_subject)
      AND (p_min_duration IS NULL OR d.target_duration_minutes >= p_min_duration)
      AND (p_max_duration IS NULL OR d.target_duration_minutes <= p_max_duration)
      AND (p_topic IS NULL OR d.topic ILIKE '%' || p_topic || '%')
    ORDER BY d.published_at DESC
    LIMIT p_limit
    OFFSET p_offset
  ) docs;
  
  RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get related documentaries (AC 10)
CREATE OR REPLACE FUNCTION get_related_documentaries(
  p_documentary_id UUID,
  p_limit INTEGER DEFAULT 5
) RETURNS JSONB AS $$
DECLARE
  v_subject TEXT;
  v_topic TEXT;
  v_result JSONB;
BEGIN
  -- Get current documentary's subject and topic
  SELECT subject, topic INTO v_subject, v_topic
  FROM public.documentary_scripts
  WHERE id = p_documentary_id;
  
  -- Find related documentaries
  SELECT jsonb_agg(doc)
  INTO v_result
  FROM (
    SELECT jsonb_build_object(
      'id', d.id,
      'title', d.topic,
      'subject', d.subject,
      'duration_minutes', d.target_duration_minutes,
      'thumbnail_url', '/images/doc-placeholder.jpg',
      'relevance_score', CASE 
        WHEN d.subject = v_subject THEN 0.8
        ELSE 0.5
      END + CASE 
        WHEN d.topic ILIKE '%' || split_part(v_topic, ' ', 1) || '%' THEN 0.2
        ELSE 0
      END
    ) as doc
    FROM public.documentary_scripts d
    WHERE d.id != p_documentary_id
      AND d.is_published = TRUE
      AND (d.subject = v_subject OR d.topic ILIKE '%' || split_part(v_topic, ' ', 1) || '%')
    ORDER BY 
      CASE WHEN d.subject = v_subject THEN 0 ELSE 1 END,
      d.published_at DESC
    LIMIT p_limit
  ) docs;
  
  RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get documentary with chapters for player (AC 2, 3)
CREATE OR REPLACE FUNCTION get_documentary_with_chapters(
  p_documentary_id UUID,
  p_user_id UUID DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_doc RECORD;
  v_chapters JSONB;
  v_progress JSONB;
BEGIN
  -- Get documentary
  SELECT * INTO v_doc
  FROM public.documentary_scripts
  WHERE id = p_documentary_id AND is_published = TRUE;
  
  IF v_doc IS NULL THEN
    RETURN jsonb_build_object('error', 'Documentary not found');
  END IF;
  
  -- Get chapters with markers (AC 3)
  SELECT jsonb_agg(ch ORDER BY ch->>'chapter_number')
  INTO v_chapters
  FROM (
    SELECT jsonb_build_object(
      'id', c.id,
      'chapter_number', c.chapter_number,
      'title', c.title,
      'duration_minutes', c.duration_minutes,
      'start_time', c.start_time_seconds,
      'end_time', c.end_time_seconds,
      'thumbnail', c.chapter_thumbnail_url
    ) as ch
    FROM public.documentary_chapters c
    WHERE c.script_id = p_documentary_id
  ) chapters;
  
  -- Get user progress if authenticated
  IF p_user_id IS NOT NULL THEN
    SELECT get_resume_position(p_user_id, p_documentary_id) INTO v_progress;
  ELSE
    v_progress := jsonb_build_object('has_progress', false);
  END IF;
  
  RETURN jsonb_build_object(
    'documentary', jsonb_build_object(
      'id', v_doc.id,
      'title', v_doc.topic,
      'subject', v_doc.subject,
      'duration_minutes', v_doc.target_duration_minutes,
      'cdn_url', v_doc.cdn_url,
      'quality_versions', v_doc.quality_versions,
      'transcript_url', v_doc.transcript_pdf_url
    ),
    'chapters', COALESCE(v_chapters, '[]'::jsonb),
    'progress', v_progress
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION update_watch_progress TO authenticated;
GRANT EXECUTE ON FUNCTION get_resume_position TO authenticated;
GRANT EXECUTE ON FUNCTION request_documentary_download TO authenticated;
GRANT EXECUTE ON FUNCTION get_documentary_library TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_related_documentaries TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_documentary_with_chapters TO authenticated, anon;

