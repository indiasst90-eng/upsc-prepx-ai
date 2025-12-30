-- Migration 038: Practice Sessions Table
-- Story 8.5 AC 8 & Story 8.9: Practice session persistence

CREATE TABLE IF NOT EXISTS public.practice_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL ,
  session_type TEXT NOT NULL CHECK (session_type IN ('pyq_practice', 'generated_practice', 'mixed')),
  session_config JSONB NOT NULL DEFAULT '{}'::jsonb,
  questions UUID[] NOT NULL,
  answers JSONB DEFAULT '{}'::jsonb,
  score INTEGER,
  accuracy DECIMAL(5,2),
  time_taken_seconds INTEGER,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'paused', 'completed', 'abandoned')),
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_practice_sessions_user_id ON public.practice_sessions(user_id);
CREATE INDEX idx_practice_sessions_status ON public.practice_sessions(status);
CREATE INDEX idx_practice_sessions_created_at ON public.practice_sessions(created_at DESC);

ALTER TABLE public.practice_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own sessions"
  ON public.practice_sessions FOR ALL
  USING (auth.uid() = user_id);

CREATE TRIGGER update_practice_sessions_updated_at
  BEFORE UPDATE ON public.practice_sessions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

COMMENT ON TABLE public.practice_sessions IS 'Story 8.5 AC 8 & Story 8.9: Practice session tracking';

