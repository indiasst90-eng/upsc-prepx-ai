-- Migration 039: AI Generated Questions System
-- Story 8.6: Question Bank - AI Question Generator Interface
-- AC 8: generated_questions table with user_id, topic, question_text, question_type, difficulty, options_json, model_answer

-- Generated Questions Table
CREATE TABLE IF NOT EXISTS public.generated_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL ,
  topic TEXT NOT NULL,
  syllabus_node_id UUID REFERENCES public.syllabus_nodes(id) ON DELETE SET NULL,
  question_text TEXT NOT NULL,
  question_type TEXT NOT NULL CHECK (question_type IN ('mcq', 'mains_150', 'mains_250', 'essay')),
  difficulty TEXT NOT NULL CHECK (difficulty IN ('easy', 'medium', 'hard')),
  options_json JSONB,  -- For MCQs: {options: [...], correct_answer: "A"}
  model_answer TEXT NOT NULL,
  key_points TEXT[],
  source_context TEXT,  -- RAG context used for generation
  generation_metadata JSONB,  -- Model, tokens, latency, etc.
  quality_score DECIMAL(3,2),  -- AI-assessed quality (0.00 - 1.00)
  is_reviewed BOOLEAN DEFAULT false,
  is_public BOOLEAN DEFAULT false,
  view_count INTEGER DEFAULT 0,
  practice_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes for performance (Story 8.6 AC 9)
CREATE INDEX idx_generated_questions_user_id ON public.generated_questions(user_id);
CREATE INDEX idx_generated_questions_topic ON public.generated_questions USING gin(to_tsvector('english', topic));
CREATE INDEX idx_generated_questions_type ON public.generated_questions(question_type);
CREATE INDEX idx_generated_questions_difficulty ON public.generated_questions(difficulty);
CREATE INDEX idx_generated_questions_created ON public.generated_questions(created_at DESC);
CREATE INDEX idx_generated_questions_syllabus ON public.generated_questions(syllabus_node_id);
CREATE INDEX idx_generated_questions_composite ON public.generated_questions(user_id, question_type, difficulty, created_at DESC);

-- Enable RLS
ALTER TABLE public.generated_questions ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view own generated questions"
  ON public.generated_questions FOR SELECT
  USING (auth.uid() = user_id OR is_public = true);

CREATE POLICY "Users can create own generated questions"
  ON public.generated_questions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own generated questions"
  ON public.generated_questions FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own generated questions"
  ON public.generated_questions FOR DELETE
  USING (auth.uid() = user_id);

-- Updated at trigger
CREATE TRIGGER update_generated_questions_updated_at
  BEFORE UPDATE ON public.generated_questions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Daily generation tracking for entitlements (Story 8.6 AC 10)
CREATE TABLE IF NOT EXISTS public.question_generation_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL ,
  question_count INTEGER NOT NULL,
  question_type TEXT NOT NULL,
  topic TEXT NOT NULL,
  generation_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_question_gen_logs_user_date ON public.question_generation_logs(user_id, generation_date);

ALTER TABLE public.question_generation_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own generation logs"
  ON public.question_generation_logs FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own generation logs"
  ON public.question_generation_logs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Function to get daily question count (Story 8.6 AC 10)
CREATE OR REPLACE FUNCTION get_daily_question_count(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER;
BEGIN
  SELECT COALESCE(SUM(question_count), 0) INTO v_count
  FROM question_generation_logs
  WHERE user_id = p_user_id
    AND generation_date = CURRENT_DATE;
  
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user can generate questions (Story 8.6 AC 10)
CREATE OR REPLACE FUNCTION check_question_generation_limit(
  p_user_id UUID,
  p_count INTEGER
)
RETURNS TABLE (
  allowed BOOLEAN,
  reason TEXT,
  current_usage INTEGER,
  daily_limit INTEGER,
  remaining INTEGER
) AS $$
DECLARE
  v_subscription RECORD;
  v_current_usage INTEGER;
  v_daily_limit INTEGER;
  v_now TIMESTAMPTZ := NOW();
BEGIN
  -- Get current daily usage
  v_current_usage := get_daily_question_count(p_user_id);
  
  -- Check subscription
  SELECT * INTO v_subscription
  FROM subscriptions
  WHERE user_id = p_user_id;
  
  -- Determine daily limit based on subscription
  IF v_subscription IS NULL THEN
    v_daily_limit := 5; -- Free tier default
  ELSIF v_subscription.status = 'trial' AND v_now < v_subscription.trial_expires_at THEN
    v_daily_limit := 9999; -- Unlimited for trial
  ELSIF v_subscription.status = 'active' AND v_now < v_subscription.subscription_expires_at THEN
    v_daily_limit := 9999; -- Unlimited for Pro
  ELSE
    v_daily_limit := 5; -- Free tier (expired or no subscription)
  END IF;
  
  -- Check if generation is allowed
  IF v_current_usage + p_count <= v_daily_limit THEN
    RETURN QUERY SELECT true, 'allowed'::TEXT, v_current_usage, v_daily_limit, v_daily_limit - v_current_usage;
  ELSE
    RETURN QUERY SELECT false, 'limit_exceeded'::TEXT, v_current_usage, v_daily_limit, v_daily_limit - v_current_usage;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to record question generation (Story 8.6 AC 10)
CREATE OR REPLACE FUNCTION record_question_generation(
  p_user_id UUID,
  p_count INTEGER,
  p_question_type TEXT,
  p_topic TEXT
)
RETURNS void AS $$
BEGIN
  INSERT INTO question_generation_logs (user_id, question_count, question_type, topic)
  VALUES (p_user_id, p_count, p_question_type, p_topic);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Comments
COMMENT ON TABLE public.generated_questions IS 'Story 8.6: AI-generated practice questions with user ownership';
COMMENT ON TABLE public.question_generation_logs IS 'Story 8.6 AC 10: Daily generation tracking for entitlements';
COMMENT ON FUNCTION get_daily_question_count IS 'Story 8.6: Returns daily question generation count for a user';
COMMENT ON FUNCTION check_question_generation_limit IS 'Story 8.6 AC 10: Validates generation against daily limits';
COMMENT ON FUNCTION record_question_generation IS 'Story 8.6: Records question generation for limit tracking';

