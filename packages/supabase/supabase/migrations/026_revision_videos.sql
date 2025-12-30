-- Migration: 026_revision_videos.sql
-- Story: 6.4 - Revision Bundle Video Generation

CREATE TABLE IF NOT EXISTS public.revision_videos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL ,
  topic_id UUID NOT NULL REFERENCES public.topic_progress(id) ON DELETE CASCADE,
  video_url TEXT NOT NULL,
  duration_seconds INTEGER,
  status TEXT DEFAULT 'processing' CHECK (status IN ('processing', 'completed', 'failed')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, topic_id)
);

DO $migration$ BEGIN
    BEGIN
        CREATE INDEX idx_revision_videos_user ON public.revision_videos(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX idx_revision_videos_status ON public.revision_videos(status);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.revision_videos ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can view own revision videos"
  ON public.revision_videos FOR SELECT
  USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        COMMENT ON TABLE public.revision_videos IS 'Generated revision videos for weak topics';
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


