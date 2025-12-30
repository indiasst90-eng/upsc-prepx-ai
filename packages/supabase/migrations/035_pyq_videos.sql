-- Migration 035: PYQ Video Explanations System
-- Story 8.4: Video generation for PYQ explanations

-- Table: pyq_videos
CREATE TABLE IF NOT EXISTS public.pyq_videos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id UUID NOT NULL REFERENCES public.pyq_questions(id) ON DELETE CASCADE,
  video_url TEXT,
  duration_seconds INTEGER,
  script_text TEXT,
  status TEXT NOT NULL DEFAULT 'queued' CHECK (status IN ('queued', 'processing', 'completed', 'failed')),
  render_metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX idx_pyq_videos_question_id ON public.pyq_videos(question_id);
CREATE INDEX idx_pyq_videos_status ON public.pyq_videos(status);
CREATE INDEX idx_pyq_videos_created_at ON public.pyq_videos(created_at DESC);

-- RLS Policies
ALTER TABLE public.pyq_videos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view pyq videos"
  ON public.pyq_videos FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Service role can manage pyq videos"
  ON public.pyq_videos FOR ALL
  USING (auth.jwt()->>'role' = 'service_role');

-- Updated at trigger
CREATE TRIGGER update_pyq_videos_updated_at
  BEFORE UPDATE ON public.pyq_videos
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Comments
COMMENT ON TABLE public.pyq_videos IS 'Story 8.4: Video explanations for PYQ questions';
COMMENT ON COLUMN public.pyq_videos.status IS 'Video generation status: queued, processing, completed, failed';
COMMENT ON COLUMN public.pyq_videos.render_metadata IS 'Metadata from video rendering process (job_id, scenes, etc)';

