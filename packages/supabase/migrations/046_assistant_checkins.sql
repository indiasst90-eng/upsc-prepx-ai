-- Migration 046: AI Teaching Assistant Motivational Check-ins
-- Story 9.3: Daily check-ins, milestones, and engagement tracking

-- ============================================
-- ASSISTANT CHECK-INS TABLE (AC 6)
-- ============================================

CREATE TABLE IF NOT EXISTS public.assistant_checkins (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL ,
  checkin_type TEXT NOT NULL CHECK (checkin_type IN ('daily', 'milestone', 'struggle', 'streak', 'welcome')),
  message TEXT NOT NULL,
  sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  user_response TEXT,
  response_at TIMESTAMPTZ,
  video_url TEXT,
  metadata JSONB DEFAULT '{}',
  is_read BOOLEAN DEFAULT FALSE,
  engagement_score INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_checkins_user ON public.assistant_checkins(user_id);
CREATE INDEX idx_checkins_sent ON public.assistant_checkins(sent_at DESC);
CREATE INDEX idx_checkins_type ON public.assistant_checkins(checkin_type);
CREATE INDEX idx_checkins_user_unread ON public.assistant_checkins(user_id, is_read) WHERE is_read = FALSE;

-- ============================================
-- USER ASSISTANT SETTINGS (AC 9)
-- ============================================

-- Add check-in settings to assistant_preferences if exists, else create separate table
DO $$
BEGIN
  -- Add columns to existing assistant_preferences table
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'assistant_preferences') THEN
    ALTER TABLE public.assistant_preferences 
      ADD COLUMN IF NOT EXISTS checkin_enabled BOOLEAN DEFAULT TRUE,
      ADD COLUMN IF NOT EXISTS preferred_checkin_time TIME DEFAULT '09:00',
      ADD COLUMN IF NOT EXISTS timezone TEXT DEFAULT 'Asia/Kolkata',
      ADD COLUMN IF NOT EXISTS notification_channel TEXT DEFAULT 'push' CHECK (notification_channel IN ('push', 'email', 'both', 'none')),
      ADD COLUMN IF NOT EXISTS last_checkin_sent_at TIMESTAMPTZ;
  END IF;
END $$;

-- ============================================
-- CHECK-IN ANALYTICS TABLE (AC 10)
-- ============================================

CREATE TABLE IF NOT EXISTS public.assistant_checkin_analytics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL ,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  checkins_sent INTEGER DEFAULT 0,
  checkins_read INTEGER DEFAULT 0,
  checkins_responded INTEGER DEFAULT 0,
  avg_response_time_hours DECIMAL(5,2),
  study_days_in_period INTEGER DEFAULT 0,
  correlation_score DECIMAL(3,2),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, period_start)
);

-- RLS Policies
ALTER TABLE public.assistant_checkins ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assistant_checkin_analytics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own checkins"
  ON public.assistant_checkins FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can respond to own checkins"
  ON public.assistant_checkins FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view own analytics"
  ON public.assistant_checkin_analytics FOR SELECT
  USING (auth.uid() = user_id);

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- AC 2: Analyze user activity for personalized messages
CREATE OR REPLACE FUNCTION analyze_user_activity(p_user_id UUID)
RETURNS TABLE (
  activity_type TEXT,
  days_since_last_activity INTEGER,
  topics_this_week INTEGER,
  questions_this_week INTEGER,
  current_streak INTEGER,
  accuracy_trend TEXT,
  milestones JSONB
) AS $$
DECLARE
  v_last_activity TIMESTAMPTZ;
  v_days_inactive INTEGER;
  v_topics INTEGER;
  v_questions INTEGER;
  v_streak INTEGER;
  v_trend TEXT;
  v_milestones JSONB;
  v_recent_accuracy DECIMAL;
  v_prev_accuracy DECIMAL;
BEGIN
  -- Days since last activity
  SELECT MAX(created_at) INTO v_last_activity
  FROM public.question_attempts
  WHERE user_id = p_user_id;
  
  v_days_inactive := COALESCE(EXTRACT(DAY FROM NOW() - v_last_activity)::INTEGER, 999);
  
  -- Topics this week (unique topics practiced)
  SELECT COUNT(DISTINCT COALESCE(gq.topic, 'General')) INTO v_topics
  FROM public.question_attempts qa
  LEFT JOIN public.generated_questions gq ON qa.question_id = gq.id
  WHERE qa.user_id = p_user_id
    AND qa.created_at >= NOW() - INTERVAL '7 days';
  
  -- Questions this week
  SELECT COUNT(*) INTO v_questions
  FROM public.question_attempts
  WHERE user_id = p_user_id
    AND created_at >= NOW() - INTERVAL '7 days';
  
  -- Calculate streak (consecutive days with activity)
  SELECT COUNT(DISTINCT DATE(created_at)) INTO v_streak
  FROM public.question_attempts
  WHERE user_id = p_user_id
    AND created_at >= NOW() - INTERVAL '30 days';
  
  -- Accuracy trend
  SELECT ROUND((COUNT(*) FILTER (WHERE is_correct)::DECIMAL / NULLIF(COUNT(*), 0)) * 100, 1)
  INTO v_recent_accuracy
  FROM public.question_attempts
  WHERE user_id = p_user_id
    AND created_at >= NOW() - INTERVAL '7 days';
  
  SELECT ROUND((COUNT(*) FILTER (WHERE is_correct)::DECIMAL / NULLIF(COUNT(*), 0)) * 100, 1)
  INTO v_prev_accuracy
  FROM public.question_attempts
  WHERE user_id = p_user_id
    AND created_at >= NOW() - INTERVAL '14 days'
    AND created_at < NOW() - INTERVAL '7 days';
  
  IF v_recent_accuracy IS NULL THEN
    v_trend := 'no_data';
  ELSIF v_prev_accuracy IS NULL OR v_recent_accuracy > v_prev_accuracy + 5 THEN
    v_trend := 'improving';
  ELSIF v_recent_accuracy < v_prev_accuracy - 5 THEN
    v_trend := 'declining';
  ELSE
    v_trend := 'stable';
  END IF;
  
  -- Check milestones
  v_milestones := '[]'::jsonb;
  
  -- 100 questions milestone
  IF (SELECT COUNT(*) FROM public.question_attempts WHERE user_id = p_user_id) >= 100 THEN
    v_milestones := v_milestones || '[{"type": "questions_100", "label": "100 Questions Completed!"}]'::jsonb;
  END IF;
  
  -- 7-day streak
  IF v_streak >= 7 THEN
    v_milestones := v_milestones || jsonb_build_array(jsonb_build_object('type', 'streak_7', 'label', v_streak || '-Day Streak!'));
  END IF;
  
  -- High accuracy
  IF v_recent_accuracy >= 80 THEN
    v_milestones := v_milestones || '[{"type": "high_accuracy", "label": "80%+ Accuracy This Week!"}]'::jsonb;
  END IF;
  
  -- Determine activity type
  RETURN QUERY SELECT
    CASE
      WHEN v_days_inactive >= 7 THEN 'inactive_long'
      WHEN v_days_inactive >= 3 THEN 'inactive_short'
      WHEN v_questions >= 50 THEN 'very_active'
      WHEN v_questions >= 20 THEN 'active'
      WHEN v_questions >= 5 THEN 'moderate'
      ELSE 'low'
    END,
    v_days_inactive,
    v_topics,
    v_questions,
    v_streak,
    v_trend,
    v_milestones;
END;
$$ LANGUAGE plpgsql;

-- AC 1: Create check-in message
CREATE OR REPLACE FUNCTION create_checkin(
  p_user_id UUID,
  p_checkin_type TEXT,
  p_message TEXT,
  p_metadata JSONB DEFAULT '{}'
)
RETURNS UUID AS $$
DECLARE
  v_id UUID;
BEGIN
  INSERT INTO public.assistant_checkins (user_id, checkin_type, message, metadata)
  VALUES (p_user_id, p_checkin_type, p_message, p_metadata)
  RETURNING id INTO v_id;
  
  -- Update last checkin time
  UPDATE public.assistant_preferences
  SET last_checkin_sent_at = NOW()
  WHERE user_id = p_user_id;
  
  RETURN v_id;
END;
$$ LANGUAGE plpgsql;

-- AC 7: Respond to check-in
CREATE OR REPLACE FUNCTION respond_to_checkin(
  p_checkin_id UUID,
  p_user_id UUID,
  p_response TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE public.assistant_checkins
  SET 
    user_response = p_response,
    response_at = NOW(),
    is_read = TRUE,
    engagement_score = engagement_score + 10
  WHERE id = p_checkin_id AND user_id = p_user_id;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Get pending check-ins for user
CREATE OR REPLACE FUNCTION get_pending_checkins(p_user_id UUID)
RETURNS TABLE (
  id UUID,
  checkin_type TEXT,
  message TEXT,
  sent_at TIMESTAMPTZ,
  video_url TEXT,
  metadata JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ac.id,
    ac.checkin_type,
    ac.message,
    ac.sent_at,
    ac.video_url,
    ac.metadata
  FROM public.assistant_checkins ac
  WHERE ac.user_id = p_user_id
    AND ac.is_read = FALSE
  ORDER BY ac.sent_at DESC
  LIMIT 5;
END;
$$ LANGUAGE plpgsql;

-- Mark check-in as read
CREATE OR REPLACE FUNCTION mark_checkin_read(p_checkin_id UUID, p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE public.assistant_checkins
  SET is_read = TRUE
  WHERE id = p_checkin_id AND user_id = p_user_id;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Get check-in settings
CREATE OR REPLACE FUNCTION get_checkin_settings(p_user_id UUID)
RETURNS TABLE (
  checkin_enabled BOOLEAN,
  preferred_checkin_time TIME,
  timezone TEXT,
  notification_channel TEXT,
  last_checkin_sent_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(ap.checkin_enabled, TRUE),
    COALESCE(ap.preferred_checkin_time, '09:00'::TIME),
    COALESCE(ap.timezone, 'Asia/Kolkata'),
    COALESCE(ap.notification_channel, 'push'),
    ap.last_checkin_sent_at
  FROM public.assistant_preferences ap
  WHERE ap.user_id = p_user_id
  UNION ALL
  SELECT TRUE, '09:00'::TIME, 'Asia/Kolkata', 'push', NULL
  WHERE NOT EXISTS (SELECT 1 FROM public.assistant_preferences WHERE user_id = p_user_id)
  LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE public.assistant_checkins IS 'Story 9.3 AC 6: Check-in messages and responses';
COMMENT ON TABLE public.assistant_checkin_analytics IS 'Story 9.3 AC 10: Engagement analytics';
COMMENT ON FUNCTION analyze_user_activity IS 'Story 9.3 AC 2,4: Analyze activity for personalized messages';
COMMENT ON FUNCTION create_checkin IS 'Story 9.3 AC 1: Create daily check-in';
COMMENT ON FUNCTION respond_to_checkin IS 'Story 9.3 AC 7: Handle user response';

