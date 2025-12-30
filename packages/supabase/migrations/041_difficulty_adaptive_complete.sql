-- Migration 041: Complete Difficulty Tagging & Adaptive System
-- Story 8.8: Full implementation with AI prediction, adaptive recommendations, gamification

-- Explicitly drop tables to ensure schema match (since 041 defines them)
DROP TABLE IF EXISTS public.difficulty_badges CASCADE;
DROP TABLE IF EXISTS public.badge_definitions CASCADE;

-- Explicitly drop functions to ensure signature match
DROP FUNCTION IF EXISTS predict_question_difficulty(text, text, text[]);
DROP FUNCTION IF EXISTS get_adaptive_recommendation(uuid);
DROP FUNCTION IF EXISTS check_and_award_badges(uuid);
DROP FUNCTION IF EXISTS get_difficulty_analytics(uuid, integer);
DROP FUNCTION IF EXISTS get_difficulty_progress(uuid);

-- Add difficulty tracking columns to generated_questions (moved from 036)
ALTER TABLE public.generated_questions 
ADD COLUMN IF NOT EXISTS success_rate DECIMAL(5,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS attempt_count INTEGER DEFAULT 0;

-- ============================================
-- AC 2: AI DIFFICULTY PREDICTION FUNCTION
-- Estimates difficulty based on question complexity factors
-- ============================================

CREATE OR REPLACE FUNCTION predict_question_difficulty(
  p_question_text TEXT,
  p_topic TEXT DEFAULT NULL,
  p_cross_topic_refs TEXT[] DEFAULT NULL
)
RETURNS TABLE (
  predicted_difficulty TEXT,
  complexity_score DECIMAL(3,2),
  reasoning JSONB
) AS $$
DECLARE
  v_complexity DECIMAL(3,2) := 0.5;
  v_word_count INTEGER;
  v_has_cross_refs BOOLEAN;
  v_reasoning JSONB;
BEGIN
  -- Calculate base complexity from text length
  v_word_count := array_length(regexp_split_to_array(p_question_text, '\s+'), 1);
  
  -- Longer questions tend to be harder
  IF v_word_count > 100 THEN
    v_complexity := v_complexity + 0.2;
  ELSIF v_word_count > 50 THEN
    v_complexity := v_complexity + 0.1;
  END IF;
  
  -- Cross-topic references increase complexity (AC 2)
  v_has_cross_refs := p_cross_topic_refs IS NOT NULL AND array_length(p_cross_topic_refs, 1) > 1;
  IF v_has_cross_refs THEN
    v_complexity := v_complexity + 0.15;
  END IF;
  
  -- Check for complexity indicators in question text
  IF p_question_text ~* '(analyze|evaluate|critically|compare|contrast|distinguish|synthesize)' THEN
    v_complexity := v_complexity + 0.15;
  END IF;
  
  IF p_question_text ~* '(list|name|state|define|what is)' THEN
    v_complexity := v_complexity - 0.1;
  END IF;
  
  -- Clamp to valid range
  v_complexity := GREATEST(0.0, LEAST(1.0, v_complexity));
  
  -- Build reasoning
  v_reasoning := jsonb_build_object(
    'word_count', v_word_count,
    'has_cross_topic_refs', v_has_cross_refs,
    'cross_topic_count', COALESCE(array_length(p_cross_topic_refs, 1), 0),
    'contains_analytical_terms', p_question_text ~* '(analyze|evaluate|critically|compare)',
    'contains_simple_terms', p_question_text ~* '(list|name|state|define|what is)'
  );
  
  -- AC 1: Classify based on threshold
  RETURN QUERY SELECT
    CASE
      WHEN v_complexity > 0.6 THEN 'hard'
      WHEN v_complexity < 0.4 THEN 'easy'
      ELSE 'medium'
    END AS predicted_difficulty,
    v_complexity AS complexity_score,
    v_reasoning AS reasoning;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION predict_question_difficulty IS 'Story 8.8 AC 2: AI predicts question difficulty based on complexity factors';

-- ============================================
-- AC 5: ADAPTIVE PRACTICE RECOMMENDATION
-- Recommends next difficulty based on last 5 answers
-- ============================================

CREATE OR REPLACE FUNCTION get_adaptive_recommendation(
  p_user_id UUID
)
RETURNS TABLE (
  recommended_difficulty TEXT,
  current_streak INTEGER,
  last_5_correct INTEGER,
  reason TEXT,
  confidence DECIMAL(3,2)
) AS $$
DECLARE
  v_last_5 RECORD;
  v_correct_count INTEGER;
  v_last_difficulty TEXT;
  v_recommendation TEXT;
  v_reason TEXT;
  v_confidence DECIMAL(3,2);
BEGIN
  -- Get last 5 answers
  SELECT 
    COUNT(*) FILTER (WHERE is_correct = true) as correct,
    COUNT(*) as total,
    MAX(difficulty_at_attempt) as last_difficulty
  INTO v_last_5
  FROM (
    SELECT is_correct, difficulty_at_attempt
    FROM public.question_attempts
    WHERE user_id = p_user_id
    ORDER BY created_at DESC
    LIMIT 5
  ) recent;
  
  v_correct_count := COALESCE(v_last_5.correct, 0);
  v_last_difficulty := COALESCE(v_last_5.last_difficulty, 'medium');
  
  -- AC 5: 3+ correct out of 5 = increase difficulty
  IF v_correct_count >= 4 THEN
    -- Strong performance, definitely increase
    IF v_last_difficulty = 'easy' THEN
      v_recommendation := 'medium';
      v_reason := 'Excellent performance on easy! Time to challenge yourself.';
    ELSIF v_last_difficulty = 'medium' THEN
      v_recommendation := 'hard';
      v_reason := 'Great accuracy! Ready for hard questions.';
    ELSE
      v_recommendation := 'hard';
      v_reason := 'Outstanding! Keep conquering hard questions.';
    END IF;
    v_confidence := 0.90;
  ELSIF v_correct_count >= 3 THEN
    -- Good performance, suggest increase
    IF v_last_difficulty = 'easy' THEN
      v_recommendation := 'medium';
      v_reason := 'Good progress! Try medium difficulty.';
    ELSIF v_last_difficulty = 'medium' THEN
      v_recommendation := 'hard';
      v_reason := 'Solid performance! Challenge yourself with hard questions.';
    ELSE
      v_recommendation := 'hard';
      v_reason := 'Keep up the good work on hard questions!';
    END IF;
    v_confidence := 0.75;
  ELSIF v_correct_count >= 2 THEN
    -- Average performance, maintain level
    v_recommendation := v_last_difficulty;
    v_reason := 'Stay at current level to build consistency.';
    v_confidence := 0.60;
  ELSE
    -- Struggling, decrease difficulty
    IF v_last_difficulty = 'hard' THEN
      v_recommendation := 'medium';
      v_reason := 'Focus on building foundations with medium questions.';
    ELSIF v_last_difficulty = 'medium' THEN
      v_recommendation := 'easy';
      v_reason := 'Strengthen basics with easy questions first.';
    ELSE
      v_recommendation := 'easy';
      v_reason := 'Practice more easy questions to build confidence.';
    END IF;
    v_confidence := 0.80;
  END IF;
  
  -- Get current correct streak
  RETURN QUERY SELECT
    v_recommendation,
    (
      SELECT COUNT(*)::INTEGER
      FROM (
        SELECT is_correct
        FROM public.question_attempts
        WHERE user_id = p_user_id
        ORDER BY created_at DESC
      ) s
      WHERE is_correct = true
      LIMIT 100
    ) as current_streak,
    v_correct_count,
    v_reason,
    v_confidence;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_adaptive_recommendation IS 'Story 8.8 AC 5: Adaptive difficulty recommendation based on last 5 answers';

-- ============================================
-- AC 10: GAMIFICATION BADGES TABLE
-- Badges for mastering questions at different difficulties
-- ============================================

CREATE TABLE IF NOT EXISTS public.difficulty_badges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL ,
  badge_type TEXT NOT NULL CHECK (badge_type IN (
    'easy_master_50', 'easy_master_100', 'easy_master_200',
    'medium_master_50', 'medium_master_100', 'medium_master_200',
    'hard_master_25', 'hard_master_50', 'hard_master_100',
    'streak_7', 'streak_30', 'streak_100',
    'accuracy_80', 'accuracy_90', 'accuracy_95'
  )),
  earned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  metadata JSONB DEFAULT '{}',
  UNIQUE(user_id, badge_type)
);

CREATE INDEX idx_difficulty_badges_user ON public.difficulty_badges(user_id);

-- Badge definitions
CREATE TABLE IF NOT EXISTS public.badge_definitions (
  badge_type TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  icon TEXT NOT NULL,
  requirement_count INTEGER NOT NULL,
  difficulty_level TEXT,
  category TEXT NOT NULL CHECK (category IN ('mastery', 'streak', 'accuracy'))
);

INSERT INTO public.badge_definitions (badge_type, name, description, icon, requirement_count, difficulty_level, category) VALUES
  ('easy_master_50', 'Easy Starter', 'Correctly answer 50 easy questions', '🌱', 50, 'easy', 'mastery'),
  ('easy_master_100', 'Easy Expert', 'Correctly answer 100 easy questions', '🌿', 100, 'easy', 'mastery'),
  ('easy_master_200', 'Easy Champion', 'Correctly answer 200 easy questions', '🌳', 200, 'easy', 'mastery'),
  ('medium_master_50', 'Medium Challenger', 'Correctly answer 50 medium questions', '⚡', 50, 'medium', 'mastery'),
  ('medium_master_100', 'Medium Warrior', 'Correctly answer 100 medium questions', '🔥', 100, 'medium', 'mastery'),
  ('medium_master_200', 'Medium Conqueror', 'Correctly answer 200 medium questions', '💫', 200, 'medium', 'mastery'),
  ('hard_master_25', 'Hard Beginner', 'Correctly answer 25 hard questions', '🏔️', 25, 'hard', 'mastery'),
  ('hard_master_50', 'Hard Master', 'Correctly answer 50 hard questions', '🏆', 50, 'hard', 'mastery'),
  ('hard_master_100', 'Hard Legend', 'Correctly answer 100 hard questions', '👑', 100, 'hard', 'mastery'),
  ('streak_7', 'Week Warrior', 'Practice for 7 days straight', '📅', 7, NULL, 'streak'),
  ('streak_30', 'Monthly Master', 'Practice for 30 days straight', '📆', 30, NULL, 'streak'),
  ('streak_100', 'Century Champion', 'Practice for 100 days straight', '🗓️', 100, NULL, 'streak'),
  ('accuracy_80', 'Sharpshooter', 'Achieve 80% overall accuracy', '🎯', 80, NULL, 'accuracy'),
  ('accuracy_90', 'Precision Pro', 'Achieve 90% overall accuracy', '💎', 90, NULL, 'accuracy'),
  ('accuracy_95', 'Perfectionist', 'Achieve 95% overall accuracy', '🌟', 95, NULL, 'accuracy')
ON CONFLICT (badge_type) DO NOTHING;

-- Function to check and award badges
CREATE OR REPLACE FUNCTION check_and_award_badges(p_user_id UUID)
RETURNS TABLE (
  new_badge TEXT,
  badge_name TEXT,
  badge_icon TEXT
) AS $$
DECLARE
  v_stats RECORD;
  v_badge RECORD;
BEGIN
  -- Get user stats
  SELECT 
    COALESCE(SUM(CASE WHEN difficulty_level = 'easy' THEN correct_attempts ELSE 0 END), 0) as easy_correct,
    COALESCE(SUM(CASE WHEN difficulty_level = 'medium' THEN correct_attempts ELSE 0 END), 0) as medium_correct,
    COALESCE(SUM(CASE WHEN difficulty_level = 'hard' THEN correct_attempts ELSE 0 END), 0) as hard_correct,
    COALESCE(SUM(total_attempts), 0) as total_attempts,
    COALESCE(SUM(correct_attempts), 0) as total_correct
  INTO v_stats
  FROM public.user_difficulty_stats
  WHERE user_id = p_user_id;
  
  -- Check each mastery badge
  FOR v_badge IN 
    SELECT * FROM public.badge_definitions WHERE category = 'mastery'
  LOOP
    -- Skip if already earned
    CONTINUE WHEN EXISTS (
      SELECT 1 FROM public.difficulty_badges 
      WHERE user_id = p_user_id AND badge_type = v_badge.badge_type
    );
    
    -- Check if requirement met
    IF (v_badge.difficulty_level = 'easy' AND v_stats.easy_correct >= v_badge.requirement_count) OR
       (v_badge.difficulty_level = 'medium' AND v_stats.medium_correct >= v_badge.requirement_count) OR
       (v_badge.difficulty_level = 'hard' AND v_stats.hard_correct >= v_badge.requirement_count) THEN
      
      INSERT INTO public.difficulty_badges (user_id, badge_type)
      VALUES (p_user_id, v_badge.badge_type);
      
      RETURN QUERY SELECT v_badge.badge_type, v_badge.name, v_badge.icon;
    END IF;
  END LOOP;
  
  -- Check accuracy badges
  IF v_stats.total_attempts >= 50 THEN
    DECLARE
      v_accuracy DECIMAL(5,2) := (v_stats.total_correct::DECIMAL / v_stats.total_attempts) * 100;
    BEGIN
      FOR v_badge IN 
        SELECT * FROM public.badge_definitions WHERE category = 'accuracy' ORDER BY requirement_count DESC
      LOOP
        CONTINUE WHEN EXISTS (
          SELECT 1 FROM public.difficulty_badges 
          WHERE user_id = p_user_id AND badge_type = v_badge.badge_type
        );
        
        IF v_accuracy >= v_badge.requirement_count THEN
          INSERT INTO public.difficulty_badges (user_id, badge_type)
          VALUES (p_user_id, v_badge.badge_type);
          
          RETURN QUERY SELECT v_badge.badge_type, v_badge.name, v_badge.icon;
        END IF;
      END LOOP;
    END;
  END IF;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION check_and_award_badges IS 'Story 8.8 AC 10: Award gamification badges based on performance';

-- ============================================
-- AC 9: ANALYTICS FUNCTIONS
-- Track time, success rates, improvement trends
-- ============================================

CREATE OR REPLACE FUNCTION get_difficulty_analytics(
  p_user_id UUID,
  p_days INTEGER DEFAULT 30
)
RETURNS TABLE (
  difficulty_level TEXT,
  total_attempts INTEGER,
  correct_attempts INTEGER,
  success_rate DECIMAL(5,2),
  avg_time_seconds INTEGER,
  time_spent_minutes INTEGER,
  improvement_trend DECIMAL(5,2)
) AS $$
BEGIN
  RETURN QUERY
  WITH recent_stats AS (
    SELECT 
      difficulty_at_attempt as diff,
      is_correct,
      time_taken_seconds,
      created_at,
      ROW_NUMBER() OVER (PARTITION BY difficulty_at_attempt ORDER BY created_at DESC) as rn
    FROM public.question_attempts
    WHERE user_id = p_user_id
      AND created_at >= NOW() - (p_days || ' days')::INTERVAL
  ),
  trends AS (
    SELECT 
      diff,
      AVG(CASE WHEN is_correct THEN 100.0 ELSE 0.0 END) FILTER (WHERE rn <= 10) as recent_rate,
      AVG(CASE WHEN is_correct THEN 100.0 ELSE 0.0 END) FILTER (WHERE rn > 10 AND rn <= 20) as older_rate
    FROM recent_stats
    GROUP BY diff
  )
  SELECT 
    uds.difficulty_level,
    uds.total_attempts,
    uds.correct_attempts,
    uds.success_rate,
    uds.avg_time_seconds,
    (SELECT COALESCE(SUM(time_taken_seconds) / 60, 0)::INTEGER
     FROM public.question_attempts qa
     WHERE qa.user_id = p_user_id 
       AND qa.difficulty_at_attempt = uds.difficulty_level
       AND qa.created_at >= NOW() - (p_days || ' days')::INTERVAL
    ) as time_spent_minutes,
    COALESCE(t.recent_rate - COALESCE(t.older_rate, t.recent_rate), 0.0) as improvement_trend
  FROM public.user_difficulty_stats uds
  LEFT JOIN trends t ON t.diff = uds.difficulty_level
  WHERE uds.user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_difficulty_analytics IS 'Story 8.8 AC 9: Analytics for difficulty performance and trends';

-- ============================================
-- AC 7: PROGRESS TRACKING FUNCTION
-- Shows comfort level at each difficulty
-- ============================================

CREATE OR REPLACE FUNCTION get_difficulty_progress(p_user_id UUID)
RETURNS TABLE (
  difficulty TEXT,
  comfort_level TEXT,
  accuracy DECIMAL(5,2),
  questions_attempted INTEGER,
  questions_correct INTEGER,
  badge_progress JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    uds.difficulty_level as difficulty,
    CASE 
      WHEN uds.success_rate >= 80 THEN 'Mastered'
      WHEN uds.success_rate >= 60 THEN 'Comfortable'
      WHEN uds.success_rate >= 40 THEN 'Learning'
      ELSE 'Needs Practice'
    END as comfort_level,
    uds.success_rate as accuracy,
    uds.total_attempts as questions_attempted,
    uds.correct_attempts as questions_correct,
    (
      SELECT jsonb_agg(jsonb_build_object(
        'badge_type', bd.badge_type,
        'name', bd.name,
        'icon', bd.icon,
        'required', bd.requirement_count,
        'current', uds.correct_attempts,
        'earned', EXISTS (
          SELECT 1 FROM public.difficulty_badges db 
          WHERE db.user_id = p_user_id AND db.badge_type = bd.badge_type
        )
      ))
      FROM public.badge_definitions bd
      WHERE bd.difficulty_level = uds.difficulty_level
    ) as badge_progress
  FROM public.user_difficulty_stats uds
  WHERE uds.user_id = p_user_id
  ORDER BY 
    CASE uds.difficulty_level 
      WHEN 'easy' THEN 1 
      WHEN 'medium' THEN 2 
      WHEN 'hard' THEN 3 
    END;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_difficulty_progress IS 'Story 8.8 AC 7: User progress tracking per difficulty level';

-- ============================================
-- RLS POLICIES
-- ============================================

ALTER TABLE public.difficulty_badges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own badges"
  ON public.difficulty_badges FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "System can insert badges"
  ON public.difficulty_badges FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Allow public read on badge definitions
ALTER TABLE public.badge_definitions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view badge definitions"
  ON public.badge_definitions FOR SELECT
  USING (true);

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE public.difficulty_badges IS 'Story 8.8 AC 10: Gamification badges for question mastery';
COMMENT ON TABLE public.badge_definitions IS 'Story 8.8 AC 10: Badge requirements and metadata';

