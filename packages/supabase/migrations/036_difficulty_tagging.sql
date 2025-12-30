-- Migration 036: Question Difficulty Tagging & Adaptive System
-- Story 8.8: Difficulty classification and adaptive practice

-- Add difficulty tracking to existing tables
ALTER TABLE public.pyq_questions 
ADD COLUMN IF NOT EXISTS success_rate DECIMAL(5,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS attempt_count INTEGER DEFAULT 0;

-- NOTE: generated_questions ALTER is handled in 041_difficulty_adaptive_complete.sql
-- because generated_questions table is created in 039_generated_questions.sql

-- Drop existing tables/functions if they exist (for clean re-run)
DROP TRIGGER IF EXISTS trigger_update_question_difficulty ON public.question_attempts;
DROP FUNCTION IF EXISTS update_question_difficulty();
DROP TABLE IF EXISTS public.user_difficulty_stats CASCADE;
DROP TABLE IF EXISTS public.question_attempts CASCADE;

-- Table: question_attempts (track user performance)
CREATE TABLE IF NOT EXISTS public.question_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL ,
  question_id UUID NOT NULL,
  question_type TEXT NOT NULL CHECK (question_type IN ('pyq', 'generated')),
  is_correct BOOLEAN NOT NULL,
  time_taken_seconds INTEGER,
  difficulty_at_attempt TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX idx_question_attempts_user_id ON public.question_attempts(user_id);
CREATE INDEX idx_question_attempts_question ON public.question_attempts(question_id, question_type);
CREATE INDEX idx_question_attempts_created_at ON public.question_attempts(created_at DESC);

-- Table: user_difficulty_stats (aggregate performance by difficulty)
CREATE TABLE IF NOT EXISTS public.user_difficulty_stats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL ,
  difficulty_level TEXT NOT NULL CHECK (difficulty_level IN ('easy', 'medium', 'hard')),
  total_attempts INTEGER DEFAULT 0,
  correct_attempts INTEGER DEFAULT 0,
  success_rate DECIMAL(5,2) DEFAULT 0.00,
  avg_time_seconds INTEGER DEFAULT 0,
  last_updated TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, difficulty_level)
);

-- Function: Update question difficulty based on success rate
CREATE OR REPLACE FUNCTION update_question_difficulty()
RETURNS TRIGGER AS $$
DECLARE
  v_success_rate DECIMAL(5,2);
BEGIN
  -- Calculate success rate for this question
  SELECT (COUNT(*) FILTER (WHERE is_correct = true)::DECIMAL / NULLIF(COUNT(*), 0)) * 100
  INTO v_success_rate
  FROM public.question_attempts
  WHERE question_id = NEW.question_id;
  
  v_success_rate := COALESCE(v_success_rate, 50.0);

  -- Update success rate for PYQ questions
  IF NEW.question_type = 'pyq' THEN
    UPDATE public.pyq_questions
    SET 
      attempt_count = COALESCE(attempt_count, 0) + 1,
      success_rate = v_success_rate,
      difficulty = CASE
        WHEN v_success_rate > 70 THEN 'easy'
        WHEN v_success_rate < 40 THEN 'hard'
        ELSE 'medium'
      END
    WHERE id = NEW.question_id;
  END IF;

  -- Update user difficulty stats
  INSERT INTO public.user_difficulty_stats (user_id, difficulty_level, total_attempts, correct_attempts, success_rate)
  VALUES (
    NEW.user_id,
    NEW.difficulty_at_attempt,
    1,
    CASE WHEN NEW.is_correct THEN 1 ELSE 0 END,
    CASE WHEN NEW.is_correct THEN 100.00 ELSE 0.00 END
  )
  ON CONFLICT (user_id, difficulty_level) DO UPDATE SET
    total_attempts = user_difficulty_stats.total_attempts + 1,
    correct_attempts = user_difficulty_stats.correct_attempts + CASE WHEN NEW.is_correct THEN 1 ELSE 0 END,
    success_rate = ((user_difficulty_stats.correct_attempts + CASE WHEN NEW.is_correct THEN 1 ELSE 0 END)::DECIMAL / 
                    (user_difficulty_stats.total_attempts + 1)) * 100,
    last_updated = now();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Update difficulty after each attempt
CREATE TRIGGER trigger_update_question_difficulty
  AFTER INSERT ON public.question_attempts
  FOR EACH ROW
  EXECUTE FUNCTION update_question_difficulty();

-- RLS Policies
ALTER TABLE public.question_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_difficulty_stats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own attempts"
  ON public.question_attempts FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own attempts"
  ON public.question_attempts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own stats"
  ON public.user_difficulty_stats FOR SELECT
  USING (auth.uid() = user_id);

-- Comments
COMMENT ON TABLE public.question_attempts IS 'Story 8.8: Track user performance on questions';
COMMENT ON TABLE public.user_difficulty_stats IS 'Story 8.8: Aggregate user performance by difficulty level';
COMMENT ON FUNCTION update_question_difficulty IS 'Story 8.8: Auto-update question difficulty based on success rate';

