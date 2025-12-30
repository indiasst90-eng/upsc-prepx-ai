-- Migration 044: AI Teaching Assistant Conversation System
-- Story 9.1: Conversation Engine with context awareness

-- ============================================
-- ASSISTANT CONVERSATIONS TABLE (AC 9)
-- ============================================

CREATE TABLE IF NOT EXISTS public.assistant_conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL ,
  session_id UUID NOT NULL DEFAULT uuid_generate_v4(),
  message_text TEXT NOT NULL,
  response_text TEXT NOT NULL,
  context_json JSONB DEFAULT '{}',
  message_type TEXT DEFAULT 'chat' CHECK (message_type IN ('chat', 'doubt', 'explanation', 'practice', 'motivation')),
  follow_up_suggestions TEXT[] DEFAULT '{}',
  sources_used JSONB DEFAULT '[]',
  confidence_score DECIMAL(3,2) DEFAULT 0.5,
  response_time_ms INTEGER,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for efficient querying
CREATE INDEX idx_assistant_conv_user ON public.assistant_conversations(user_id);
CREATE INDEX idx_assistant_conv_session ON public.assistant_conversations(session_id);
CREATE INDEX idx_assistant_conv_created ON public.assistant_conversations(created_at DESC);
CREATE INDEX idx_assistant_conv_user_session ON public.assistant_conversations(user_id, session_id);

-- ============================================
-- ASSISTANT USAGE TRACKING (AC 10)
-- ============================================

CREATE TABLE IF NOT EXISTS public.assistant_usage (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL ,
  usage_date DATE NOT NULL DEFAULT CURRENT_DATE,
  message_count INTEGER NOT NULL DEFAULT 0,
  last_message_at TIMESTAMPTZ,
  UNIQUE(user_id, usage_date)
);

CREATE INDEX idx_assistant_usage_user_date ON public.assistant_usage(user_id, usage_date);

-- ============================================
-- RLS POLICIES
-- ============================================

ALTER TABLE public.assistant_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assistant_usage ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own conversations"
  ON public.assistant_conversations FOR ALL
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view own usage"
  ON public.assistant_usage FOR ALL
  USING (auth.uid() = user_id);

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- AC 2: Get conversation history for context
CREATE OR REPLACE FUNCTION get_conversation_context(
  p_user_id UUID,
  p_session_id UUID DEFAULT NULL,
  p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
  id UUID,
  message_text TEXT,
  response_text TEXT,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ac.id,
    ac.message_text,
    ac.response_text,
    ac.created_at
  FROM public.assistant_conversations ac
  WHERE ac.user_id = p_user_id
    AND (p_session_id IS NULL OR ac.session_id = p_session_id)
  ORDER BY ac.created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- AC 3: Get user learning context for personalization
CREATE OR REPLACE FUNCTION get_user_learning_context(p_user_id UUID)
RETURNS TABLE (
  user_name TEXT,
  weak_topics JSONB,
  strong_topics JSONB,
  recent_topics JSONB,
  study_stats JSONB,
  exam_date DATE
) AS $$
DECLARE
  v_name TEXT;
  v_weak JSONB;
  v_strong JSONB;
  v_recent JSONB;
  v_stats JSONB;
  v_exam DATE;
BEGIN
  -- Get user name
  SELECT COALESCE(full_name, email) INTO v_name
  FROM auth.users
  WHERE id = p_user_id;
  
  -- Get weak topics from question attempts
  SELECT jsonb_agg(jsonb_build_object('topic', topic, 'accuracy', accuracy))
  INTO v_weak
  FROM (
    SELECT 
      COALESCE(gq.topic, 'General') as topic,
      ROUND((COUNT(*) FILTER (WHERE qa.is_correct)::DECIMAL / NULLIF(COUNT(*), 0)) * 100, 1) as accuracy
    FROM public.question_attempts qa
    LEFT JOIN public.generated_questions gq ON qa.question_id = gq.id
    WHERE qa.user_id = p_user_id
      AND qa.created_at >= NOW() - INTERVAL '30 days'
    GROUP BY COALESCE(gq.topic, 'General')
    HAVING COUNT(*) >= 3 AND 
           ROUND((COUNT(*) FILTER (WHERE qa.is_correct)::DECIMAL / NULLIF(COUNT(*), 0)) * 100, 1) < 50
    ORDER BY accuracy ASC
    LIMIT 5
  ) weak;
  
  -- Get strong topics
  SELECT jsonb_agg(jsonb_build_object('topic', topic, 'accuracy', accuracy))
  INTO v_strong
  FROM (
    SELECT 
      COALESCE(gq.topic, 'General') as topic,
      ROUND((COUNT(*) FILTER (WHERE qa.is_correct)::DECIMAL / NULLIF(COUNT(*), 0)) * 100, 1) as accuracy
    FROM public.question_attempts qa
    LEFT JOIN public.generated_questions gq ON qa.question_id = gq.id
    WHERE qa.user_id = p_user_id
      AND qa.created_at >= NOW() - INTERVAL '30 days'
    GROUP BY COALESCE(gq.topic, 'General')
    HAVING COUNT(*) >= 3 AND 
           ROUND((COUNT(*) FILTER (WHERE qa.is_correct)::DECIMAL / NULLIF(COUNT(*), 0)) * 100, 1) >= 80
    ORDER BY accuracy DESC
    LIMIT 5
  ) strong;
  
  -- Get recently studied topics
  SELECT jsonb_agg(DISTINCT COALESCE(gq.topic, 'General'))
  INTO v_recent
  FROM public.question_attempts qa
  LEFT JOIN public.generated_questions gq ON qa.question_id = gq.id
  WHERE qa.user_id = p_user_id
    AND qa.created_at >= NOW() - INTERVAL '7 days';
  
  -- Get study stats
  SELECT jsonb_build_object(
    'total_questions', COUNT(*),
    'accuracy', ROUND((COUNT(*) FILTER (WHERE is_correct)::DECIMAL / NULLIF(COUNT(*), 0)) * 100, 1),
    'days_active', COUNT(DISTINCT DATE(created_at)),
    'avg_time_per_question', ROUND(AVG(time_taken_seconds))
  )
  INTO v_stats
  FROM public.question_attempts
  WHERE user_id = p_user_id
    AND created_at >= NOW() - INTERVAL '30 days';
  
  -- Get exam date from user preferences (if set)
  SELECT (preferences->>'exam_date')::DATE INTO v_exam
  FROM public.user_profiles
  WHERE id = p_user_id;
  
  RETURN QUERY SELECT
    COALESCE(v_name, 'Student'),
    COALESCE(v_weak, '[]'::jsonb),
    COALESCE(v_strong, '[]'::jsonb),
    COALESCE(v_recent, '[]'::jsonb),
    COALESCE(v_stats, '{}'::jsonb),
    v_exam;
END;
$$ LANGUAGE plpgsql;

-- AC 10: Check and update message usage
CREATE OR REPLACE FUNCTION check_assistant_usage(
  p_user_id UUID,
  p_is_pro BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
  allowed BOOLEAN,
  messages_today INTEGER,
  limit_reached BOOLEAN,
  daily_limit INTEGER
) AS $$
DECLARE
  v_count INTEGER;
  v_limit INTEGER;
BEGIN
  -- Pro users get unlimited (represented as 9999)
  v_limit := CASE WHEN p_is_pro THEN 9999 ELSE 50 END;
  
  -- Get today's count
  SELECT COALESCE(message_count, 0) INTO v_count
  FROM public.assistant_usage
  WHERE user_id = p_user_id AND usage_date = CURRENT_DATE;
  
  -- If no record exists, count is 0
  IF v_count IS NULL THEN v_count := 0; END IF;
  
  RETURN QUERY SELECT
    v_count < v_limit,
    v_count,
    v_count >= v_limit,
    v_limit;
END;
$$ LANGUAGE plpgsql;

-- Increment usage count
CREATE OR REPLACE FUNCTION increment_assistant_usage(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
  v_new_count INTEGER;
BEGIN
  INSERT INTO public.assistant_usage (user_id, usage_date, message_count, last_message_at)
  VALUES (p_user_id, CURRENT_DATE, 1, NOW())
  ON CONFLICT (user_id, usage_date)
  DO UPDATE SET 
    message_count = assistant_usage.message_count + 1,
    last_message_at = NOW()
  RETURNING message_count INTO v_new_count;
  
  RETURN v_new_count;
END;
$$ LANGUAGE plpgsql;

-- Save conversation
CREATE OR REPLACE FUNCTION save_conversation(
  p_user_id UUID,
  p_session_id UUID,
  p_message TEXT,
  p_response TEXT,
  p_context JSONB DEFAULT '{}',
  p_message_type TEXT DEFAULT 'chat',
  p_follow_ups TEXT[] DEFAULT '{}',
  p_sources JSONB DEFAULT '[]',
  p_confidence DECIMAL DEFAULT 0.5,
  p_response_time INTEGER DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_id UUID;
BEGIN
  INSERT INTO public.assistant_conversations (
    user_id, session_id, message_text, response_text, context_json,
    message_type, follow_up_suggestions, sources_used, confidence_score, response_time_ms
  )
  VALUES (
    p_user_id, p_session_id, p_message, p_response, p_context,
    p_message_type, p_follow_ups, p_sources, p_confidence, p_response_time
  )
  RETURNING id INTO v_id;
  
  RETURN v_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE public.assistant_conversations IS 'Story 9.1 AC 9: Chat history storage';
COMMENT ON TABLE public.assistant_usage IS 'Story 9.1 AC 10: Rate limiting tracking';
COMMENT ON FUNCTION get_conversation_context IS 'Story 9.1 AC 2: Get conversation history for context';
COMMENT ON FUNCTION get_user_learning_context IS 'Story 9.1 AC 3: Get user learning context for personalization';
COMMENT ON FUNCTION check_assistant_usage IS 'Story 9.1 AC 10: Check rate limits';

