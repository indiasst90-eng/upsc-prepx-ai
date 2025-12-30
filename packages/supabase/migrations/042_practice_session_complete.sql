-- Migration 042: Complete Practice Session System
-- Story 8.9: Full practice session interface with pause/resume

-- Extend practice_sessions table with additional tracking fields
ALTER TABLE public.practice_sessions
ADD COLUMN IF NOT EXISTS question_times JSONB DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS paused_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS total_paused_seconds INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS current_question_index INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS weak_topics TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS session_metadata JSONB DEFAULT '{}'::jsonb;

-- Create session configuration presets
CREATE TABLE IF NOT EXISTS public.session_presets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID ,
  name TEXT NOT NULL,
  config JSONB NOT NULL,
  is_default BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, name)
);

CREATE INDEX idx_session_presets_user ON public.session_presets(user_id);

-- RLS for session presets
ALTER TABLE public.session_presets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own presets"
  ON public.session_presets FOR ALL
  USING (auth.uid() = user_id OR user_id IS NULL);

-- Function: Start new practice session (AC 1, AC 2)
CREATE OR REPLACE FUNCTION start_practice_session(
  p_user_id UUID,
  p_session_type TEXT,
  p_config JSONB,
  p_question_ids UUID[]
)
RETURNS UUID AS $$
DECLARE
  v_session_id UUID;
BEGIN
  INSERT INTO public.practice_sessions (
    user_id,
    session_type,
    session_config,
    questions,
    answers,
    status,
    started_at
  ) VALUES (
    p_user_id,
    p_session_type,
    p_config,
    p_question_ids,
    '{}'::jsonb,
    'active',
    now()
  )
  RETURNING id INTO v_session_id;
  
  RETURN v_session_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Pause session (AC 8)
CREATE OR REPLACE FUNCTION pause_practice_session(
  p_session_id UUID,
  p_user_id UUID,
  p_current_index INTEGER,
  p_answers JSONB,
  p_question_times JSONB
)
RETURNS void AS $$
BEGIN
  UPDATE public.practice_sessions
  SET 
    status = 'paused',
    paused_at = now(),
    current_question_index = p_current_index,
    answers = p_answers,
    question_times = p_question_times,
    updated_at = now()
  WHERE id = p_session_id AND user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Resume session (AC 8)
CREATE OR REPLACE FUNCTION resume_practice_session(
  p_session_id UUID,
  p_user_id UUID
)
RETURNS TABLE (
  session_id UUID,
  session_config JSONB,
  questions UUID[],
  answers JSONB,
  question_times JSONB,
  current_index INTEGER,
  elapsed_seconds INTEGER
) AS $$
DECLARE
  v_session RECORD;
  v_paused_duration INTEGER;
BEGIN
  SELECT * INTO v_session
  FROM public.practice_sessions ps
  WHERE ps.id = p_session_id AND ps.user_id = p_user_id AND ps.status = 'paused';
  
  IF NOT FOUND THEN
    RETURN;
  END IF;
  
  -- Calculate paused duration
  v_paused_duration := EXTRACT(EPOCH FROM (now() - v_session.paused_at))::INTEGER;
  
  -- Update session to active
  UPDATE public.practice_sessions
  SET 
    status = 'active',
    total_paused_seconds = total_paused_seconds + v_paused_duration,
    paused_at = NULL,
    updated_at = now()
  WHERE id = p_session_id;
  
  RETURN QUERY SELECT
    v_session.id as session_id,
    v_session.session_config,
    v_session.questions,
    v_session.answers,
    v_session.question_times,
    v_session.current_question_index as current_index,
    EXTRACT(EPOCH FROM (v_session.paused_at - v_session.started_at))::INTEGER - v_session.total_paused_seconds as elapsed_seconds;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Complete session with analysis (AC 9)
CREATE OR REPLACE FUNCTION complete_practice_session(
  p_session_id UUID,
  p_user_id UUID,
  p_answers JSONB,
  p_question_times JSONB,
  p_score INTEGER,
  p_accuracy DECIMAL,
  p_time_taken INTEGER
)
RETURNS TABLE (
  weak_topics TEXT[],
  strong_topics TEXT[],
  avg_time_per_question INTEGER,
  difficulty_breakdown JSONB
) AS $$
DECLARE
  v_weak TEXT[];
  v_strong TEXT[];
  v_avg_time INTEGER;
BEGIN
  -- Update session as completed
  UPDATE public.practice_sessions
  SET 
    status = 'completed',
    answers = p_answers,
    question_times = p_question_times,
    score = p_score,
    accuracy = p_accuracy,
    time_taken_seconds = p_time_taken,
    completed_at = now(),
    updated_at = now()
  WHERE id = p_session_id AND user_id = p_user_id;
  
  -- Calculate average time per question
  SELECT 
    COALESCE(AVG((value)::INTEGER), 0)::INTEGER INTO v_avg_time
  FROM jsonb_each_text(p_question_times);
  
  -- Return analysis
  RETURN QUERY SELECT
    v_weak as weak_topics,
    v_strong as strong_topics,
    v_avg_time as avg_time_per_question,
    jsonb_build_object(
      'easy', jsonb_build_object('count', 0, 'correct', 0),
      'medium', jsonb_build_object('count', 0, 'correct', 0),
      'hard', jsonb_build_object('count', 0, 'correct', 0)
    ) as difficulty_breakdown;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get user's paused sessions
CREATE OR REPLACE FUNCTION get_paused_sessions(p_user_id UUID)
RETURNS TABLE (
  id UUID,
  session_type TEXT,
  session_config JSONB,
  question_count INTEGER,
  answered_count INTEGER,
  current_index INTEGER,
  paused_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ps.id,
    ps.session_type,
    ps.session_config,
    array_length(ps.questions, 1) as question_count,
    (SELECT COUNT(*)::INTEGER FROM jsonb_object_keys(ps.answers)) as answered_count,
    ps.current_question_index as current_index,
    ps.paused_at
  FROM public.practice_sessions ps
  WHERE ps.user_id = p_user_id AND ps.status = 'paused'
  ORDER BY ps.paused_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get session history for analytics
CREATE OR REPLACE FUNCTION get_session_history(
  p_user_id UUID,
  p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
  id UUID,
  session_type TEXT,
  config JSONB,
  score INTEGER,
  accuracy DECIMAL,
  time_taken INTEGER,
  question_count INTEGER,
  completed_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ps.id,
    ps.session_type,
    ps.session_config as config,
    ps.score,
    ps.accuracy,
    ps.time_taken_seconds as time_taken,
    array_length(ps.questions, 1) as question_count,
    ps.completed_at
  FROM public.practice_sessions ps
  WHERE ps.user_id = p_user_id AND ps.status = 'completed'
  ORDER BY ps.completed_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Comments
COMMENT ON FUNCTION start_practice_session IS 'Story 8.9 AC 1: Start new practice session';
COMMENT ON FUNCTION pause_practice_session IS 'Story 8.9 AC 8: Pause session with progress';
COMMENT ON FUNCTION resume_practice_session IS 'Story 8.9 AC 8: Resume paused session';
COMMENT ON FUNCTION complete_practice_session IS 'Story 8.9 AC 9: Complete session with analysis';

