-- Migration: 031_progress_videos.sql
-- Story: 6.10 - Weekly Progress Video Briefing

CREATE TABLE IF NOT EXISTS public.progress_videos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL ,
  week_number INTEGER NOT NULL,
  year INTEGER NOT NULL,
  video_url TEXT NOT NULL,
  stats_json JSONB NOT NULL,
  status TEXT DEFAULT 'processing' CHECK (status IN ('processing', 'completed', 'failed')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, week_number, year)
);

DO $migration$ BEGIN
    BEGIN
        CREATE INDEX idx_progress_videos_user ON public.progress_videos(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX idx_progress_videos_week ON public.progress_videos(week_number, year);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.progress_videos ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can view own progress videos"
  ON public.progress_videos FOR SELECT
  USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        COMMENT ON TABLE public.progress_videos IS 'Weekly personalized progress video summaries';
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


