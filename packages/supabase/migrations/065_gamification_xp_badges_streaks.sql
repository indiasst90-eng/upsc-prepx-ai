-- ============================================================================
-- Migration 065: Gamification - XP, Badges & Streaks System
-- Story 14.1: Gamification
-- ============================================================================

-- ============================================================================
-- 1. GAMIFICATION SETTINGS (AC 10: Opt-out)
-- ============================================================================

CREATE TABLE IF NOT EXISTS gamification_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL ,
  enabled BOOLEAN NOT NULL DEFAULT true,
  show_xp BOOLEAN NOT NULL DEFAULT true,
  show_badges BOOLEAN NOT NULL DEFAULT true,
  show_streaks BOOLEAN NOT NULL DEFAULT true,
  show_3d_rooms BOOLEAN NOT NULL DEFAULT true,
  daily_goal_minutes INTEGER DEFAULT 30,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id)
);

-- ============================================================================
-- 2. USER LEVELS & XP (AC 1, AC 5)
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_xp (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL ,
  total_xp INTEGER NOT NULL DEFAULT 0,
  current_level INTEGER NOT NULL DEFAULT 1,
  xp_to_next_level INTEGER NOT NULL DEFAULT 100,
  lifetime_xp INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id)
);

-- ============================================================================
-- 3. XP TRANSACTIONS (AC 1: XP system)
-- ============================================================================

CREATE TABLE IF NOT EXISTS xp_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL ,
  amount INTEGER NOT NULL,
  activity_type TEXT NOT NULL, -- 'video_watched', 'quiz_completed', 'doubt_asked', 'notes_generated', 'streak_bonus'
  source_id TEXT, -- ID of the source entity
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_xp_transactions_user ON xp_transactions(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_xp_transactions_type ON xp_transactions(activity_type);

-- XP values as defined in AC 1
COMMENT ON TABLE xp_transactions IS 'XP earned: video=10, quiz=20, doubt=15, notes=25, streak_bonus=50';

-- ============================================================================
-- 4. BADGES DEFINITION (AC 2)
-- Drop old badge_definitions from 041 and recreate with new schema
-- ============================================================================

DROP TABLE IF EXISTS badge_definitions CASCADE;

CREATE TABLE IF NOT EXISTS badge_definitions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  icon_url TEXT,
  category TEXT NOT NULL, -- 'milestone', 'streak', 'achievement', 'explorer'
  criteria JSONB NOT NULL, -- { type: 'first_topic' | 'streak_days' | 'quiz_perfect' | 'visit_papers', value: 7 }
  xp_reward INTEGER DEFAULT 0,
  rarity TEXT DEFAULT 'common', -- common, rare, epic, legendary
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Seed default badges (AC 2)
INSERT INTO badge_definitions (slug, name, description, category, criteria, xp_reward, rarity, display_order) VALUES
  ('first_steps', 'First Steps', 'Complete your first topic', 'milestone', '{"type": "first_topic", "value": 1}'::jsonb, 50, 'common', 1),
  ('week_warrior', 'Week Warrior', 'Maintain a 7-day study streak', 'streak', '{"type": "streak_days", "value": 7}'::jsonb, 100, 'common', 2),
  ('quiz_master', 'Quiz Master', 'Score 100% on 10 quizzes', 'achievement', '{"type": "quiz_perfect", "value": 10}'::jsonb, 200, 'rare', 3),
  ('syllabus_explorer', 'Syllabus Explorer', 'Visit all GS papers', 'explorer', '{"type": "visit_papers", "value": 4}'::jsonb, 150, 'rare', 4),
  ('consistent', 'Consistent', 'Maintain a 30-day study streak', 'streak', '{"type": "streak_days", "value": 30}'::jsonb, 500, 'epic', 5),
  ('note_taker', 'Note Taker', 'Generate 50 notes', 'achievement', '{"type": "notes_count", "value": 50}'::jsonb, 100, 'common', 6),
  ('curious_mind', 'Curious Mind', 'Ask 25 doubts', 'achievement', '{"type": "doubts_count", "value": 25}'::jsonb, 100, 'common', 7),
  ('video_learner', 'Video Learner', 'Watch 100 videos', 'achievement', '{"type": "videos_count", "value": 100}'::jsonb, 150, 'rare', 8),
  ('century', 'Century', 'Reach 100-day streak', 'streak', '{"type": "streak_days", "value": 100}'::jsonb, 1000, 'legendary', 9),
  ('knowledge_seeker', 'Knowledge Seeker', 'Reach Level 10', 'milestone', '{"type": "level", "value": 10}'::jsonb, 300, 'rare', 10)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- 5. USER BADGES (earned badges)
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_badges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL ,
  badge_id UUID NOT NULL REFERENCES badge_definitions(id) ON DELETE CASCADE,
  earned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  notified BOOLEAN DEFAULT false,
  displayed BOOLEAN DEFAULT true,
  UNIQUE(user_id, badge_id)
);

CREATE INDEX IF NOT EXISTS idx_user_badges_user ON user_badges(user_id, earned_at DESC);

-- ============================================================================
-- 6. STREAKS (AC 3: consecutive days with 30 min study)
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_streaks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL ,
  current_streak INTEGER NOT NULL DEFAULT 0,
  longest_streak INTEGER NOT NULL DEFAULT 0,
  last_activity_date DATE,
  streak_start_date DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id)
);

-- ============================================================================
-- 7. DAILY ACTIVITY (for streak tracking)
-- ============================================================================

CREATE TABLE IF NOT EXISTS daily_activity (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL ,
  activity_date DATE NOT NULL,
  study_minutes INTEGER NOT NULL DEFAULT 0,
  videos_watched INTEGER DEFAULT 0,
  quizzes_completed INTEGER DEFAULT 0,
  doubts_asked INTEGER DEFAULT 0,
  notes_generated INTEGER DEFAULT 0,
  xp_earned INTEGER DEFAULT 0,
  streak_counted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, activity_date)
);

CREATE INDEX IF NOT EXISTS idx_daily_activity_user_date ON daily_activity(user_id, activity_date DESC);

-- ============================================================================
-- 8. SUBJECT ROOMS (AC 4: 3D virtual rooms per subject)
-- ============================================================================

CREATE TABLE IF NOT EXISTS subject_rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_code TEXT NOT NULL UNIQUE, -- 'polity', 'history', 'geography', 'economics', 'science', 'art_culture', 'environment', 'ethics'
  name TEXT NOT NULL,
  description TEXT,
  theme_color TEXT DEFAULT '#3B82F6',
  icon TEXT, -- icon name or emoji
  model_url TEXT, -- 3D model URL if any
  unlocked_by_default BOOLEAN DEFAULT true,
  unlock_xp_required INTEGER DEFAULT 0,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Seed subject rooms
INSERT INTO subject_rooms (subject_code, name, description, theme_color, icon, display_order) VALUES
  ('polity', 'Indian Polity', 'Constitution, Governance & Politics', '#EF4444', '🏛️', 1),
  ('history', 'History', 'Ancient, Medieval & Modern India', '#F59E0B', '📜', 2),
  ('geography', 'Geography', 'Physical, Human & Economic', '#10B981', '🌍', 3),
  ('economics', 'Economics', 'Macro, Micro & Indian Economy', '#3B82F6', '📊', 4),
  ('science', 'Science & Tech', 'Current Affairs & Basics', '#8B5CF6', '🔬', 5),
  ('art_culture', 'Art & Culture', 'Indian Heritage & Arts', '#EC4899', '🎭', 6),
  ('environment', 'Environment', 'Ecology & Biodiversity', '#22C55E', '🌱', 7),
  ('ethics', 'Ethics', 'GS Paper 4 - Ethics & Integrity', '#6366F1', '⚖️', 8)
ON CONFLICT (subject_code) DO NOTHING;

-- ============================================================================
-- 9. USER ROOM PROGRESS
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_room_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL ,
  room_id UUID NOT NULL REFERENCES subject_rooms(id) ON DELETE CASCADE,
  visited BOOLEAN DEFAULT false,
  first_visited_at TIMESTAMPTZ,
  time_spent_minutes INTEGER DEFAULT 0,
  topics_completed INTEGER DEFAULT 0,
  total_topics INTEGER DEFAULT 0,
  completion_percentage DECIMAL(5,2) DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, room_id)
);

-- ============================================================================
-- 10. LEVEL DEFINITIONS
-- ============================================================================

CREATE TABLE IF NOT EXISTS level_definitions (
  level INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  xp_required INTEGER NOT NULL,
  title TEXT,
  perks JSONB DEFAULT '[]'::jsonb
);

-- Seed levels
INSERT INTO level_definitions (level, name, xp_required, title, perks) VALUES
  (1, 'Aspirant', 0, 'UPSC Aspirant', '[]'::jsonb),
  (2, 'Learner', 100, 'Dedicated Learner', '[]'::jsonb),
  (3, 'Scholar', 300, 'Rising Scholar', '[]'::jsonb),
  (4, 'Student', 600, 'Focused Student', '[]'::jsonb),
  (5, 'Achiever', 1000, 'Goal Achiever', '[]'::jsonb),
  (6, 'Expert', 1500, 'Subject Expert', '[]'::jsonb),
  (7, 'Master', 2200, 'Knowledge Master', '[]'::jsonb),
  (8, 'Elite', 3000, 'Elite Aspirant', '[]'::jsonb),
  (9, 'Champion', 4000, 'UPSC Champion', '[]'::jsonb),
  (10, 'Legend', 5500, 'UPSC Legend', '[]'::jsonb),
  (11, 'Titan', 7500, 'Study Titan', '[]'::jsonb),
  (12, 'Sage', 10000, 'Wisdom Sage', '[]'::jsonb),
  (13, 'Grandmaster', 15000, 'Grandmaster', '[]'::jsonb),
  (14, 'Immortal', 20000, 'Immortal Scholar', '[]'::jsonb),
  (15, 'Transcendent', 30000, 'Transcendent', '[]'::jsonb)
ON CONFLICT (level) DO NOTHING;

-- ============================================================================
-- 11. MILESTONES & CELEBRATIONS (AC 6)
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_milestones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL ,
  milestone_type TEXT NOT NULL, -- 'level_up', 'badge_earned', 'streak_milestone', 'xp_milestone'
  milestone_value INTEGER,
  data JSONB,
  celebrated BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_user_milestones_user ON user_milestones(user_id, created_at DESC);

-- ============================================================================
-- 12. SELF-COMPARISON METRICS (AC 8: "You vs Last Month")
-- ============================================================================

CREATE TABLE IF NOT EXISTS monthly_stats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL ,
  month_year TEXT NOT NULL, -- '2025-12'
  total_xp INTEGER DEFAULT 0,
  study_minutes INTEGER DEFAULT 0,
  videos_watched INTEGER DEFAULT 0,
  quizzes_completed INTEGER DEFAULT 0,
  quizzes_perfect INTEGER DEFAULT 0,
  doubts_asked INTEGER DEFAULT 0,
  notes_generated INTEGER DEFAULT 0,
  streak_days INTEGER DEFAULT 0,
  badges_earned INTEGER DEFAULT 0,
  subjects_visited JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, month_year)
);

-- ============================================================================
-- 13. FUNCTIONS
-- ============================================================================

-- Drop existing functions to allow recreation with different signatures
DROP FUNCTION IF EXISTS check_and_award_badges(UUID) CASCADE;
DROP FUNCTION IF EXISTS award_xp(UUID, INTEGER, TEXT, TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS update_user_streak(UUID, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS get_self_comparison(UUID) CASCADE;

-- Award XP to user
CREATE OR REPLACE FUNCTION award_xp(
  p_user_id UUID,
  p_amount INTEGER,
  p_activity_type TEXT,
  p_source_id TEXT DEFAULT NULL,
  p_description TEXT DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
  v_new_total INTEGER;
  v_current_level INTEGER;
  v_new_level INTEGER;
  v_xp_for_next INTEGER;
  v_gamification_enabled BOOLEAN;
BEGIN
  -- Check if gamification is enabled
  SELECT enabled INTO v_gamification_enabled
  FROM gamification_settings WHERE user_id = p_user_id;
  
  IF v_gamification_enabled = false THEN
    RETURN 0;
  END IF;
  
  -- Insert XP transaction
  INSERT INTO xp_transactions (user_id, amount, activity_type, source_id, description)
  VALUES (p_user_id, p_amount, p_activity_type, p_source_id, p_description);
  
  -- Update user XP
  INSERT INTO user_xp (user_id, total_xp, lifetime_xp)
  VALUES (p_user_id, p_amount, p_amount)
  ON CONFLICT (user_id) DO UPDATE SET
    total_xp = user_xp.total_xp + p_amount,
    lifetime_xp = user_xp.lifetime_xp + p_amount,
    updated_at = now();
  
  -- Get new total and check for level up
  SELECT total_xp, current_level INTO v_new_total, v_current_level
  FROM user_xp WHERE user_id = p_user_id;
  
  -- Calculate new level
  SELECT level INTO v_new_level
  FROM level_definitions
  WHERE xp_required <= v_new_total
  ORDER BY level DESC LIMIT 1;
  
  v_new_level := COALESCE(v_new_level, 1);
  
  -- Get XP for next level
  SELECT xp_required INTO v_xp_for_next
  FROM level_definitions WHERE level = v_new_level + 1;
  
  v_xp_for_next := COALESCE(v_xp_for_next, v_new_total + 1000);
  
  -- Update level if changed
  IF v_new_level > v_current_level THEN
    UPDATE user_xp SET 
      current_level = v_new_level,
      xp_to_next_level = v_xp_for_next - v_new_total
    WHERE user_id = p_user_id;
    
    -- Create milestone for level up
    INSERT INTO user_milestones (user_id, milestone_type, milestone_value, data)
    VALUES (p_user_id, 'level_up', v_new_level, 
      jsonb_build_object('previous_level', v_current_level, 'new_level', v_new_level));
  ELSE
    UPDATE user_xp SET xp_to_next_level = v_xp_for_next - v_new_total
    WHERE user_id = p_user_id;
  END IF;
  
  -- Update daily activity
  INSERT INTO daily_activity (user_id, activity_date, xp_earned)
  VALUES (p_user_id, CURRENT_DATE, p_amount)
  ON CONFLICT (user_id, activity_date) DO UPDATE SET
    xp_earned = daily_activity.xp_earned + p_amount,
    updated_at = now();
  
  -- Update monthly stats
  INSERT INTO monthly_stats (user_id, month_year, total_xp)
  VALUES (p_user_id, to_char(CURRENT_DATE, 'YYYY-MM'), p_amount)
  ON CONFLICT (user_id, month_year) DO UPDATE SET
    total_xp = monthly_stats.total_xp + p_amount,
    updated_at = now();
  
  RETURN p_amount;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update streak
CREATE OR REPLACE FUNCTION update_user_streak(p_user_id UUID, p_study_minutes INTEGER)
RETURNS JSONB AS $$
DECLARE
  v_last_date DATE;
  v_current_streak INTEGER;
  v_longest_streak INTEGER;
  v_today DATE := CURRENT_DATE;
  v_daily_goal INTEGER;
  v_result JSONB;
BEGIN
  -- Get daily goal
  SELECT daily_goal_minutes INTO v_daily_goal
  FROM gamification_settings WHERE user_id = p_user_id;
  v_daily_goal := COALESCE(v_daily_goal, 30);
  
  -- Update daily activity
  INSERT INTO daily_activity (user_id, activity_date, study_minutes)
  VALUES (p_user_id, v_today, p_study_minutes)
  ON CONFLICT (user_id, activity_date) DO UPDATE SET
    study_minutes = daily_activity.study_minutes + p_study_minutes,
    updated_at = now();
  
  -- Get current streak info
  SELECT last_activity_date, current_streak, longest_streak
  INTO v_last_date, v_current_streak, v_longest_streak
  FROM user_streaks WHERE user_id = p_user_id;
  
  -- Initialize if not exists
  IF v_current_streak IS NULL THEN
    INSERT INTO user_streaks (user_id, current_streak, longest_streak, last_activity_date, streak_start_date)
    VALUES (p_user_id, 0, 0, NULL, NULL);
    v_current_streak := 0;
    v_longest_streak := 0;
  END IF;
  
  -- Check if daily goal met
  IF p_study_minutes >= v_daily_goal THEN
    -- Check if continuing streak
    IF v_last_date IS NULL OR v_last_date = v_today - 1 THEN
      v_current_streak := v_current_streak + 1;
      IF v_current_streak > v_longest_streak THEN
        v_longest_streak := v_current_streak;
      END IF;
      
      UPDATE user_streaks SET
        current_streak = v_current_streak,
        longest_streak = v_longest_streak,
        last_activity_date = v_today,
        streak_start_date = COALESCE(streak_start_date, v_today),
        updated_at = now()
      WHERE user_id = p_user_id;
      
      -- Award streak bonus XP
      PERFORM award_xp(p_user_id, 50, 'streak_bonus', NULL, 'Daily streak bonus');
      
    ELSIF v_last_date = v_today THEN
      -- Already counted today
      NULL;
    ELSE
      -- Streak broken, start new
      v_current_streak := 1;
      UPDATE user_streaks SET
        current_streak = 1,
        last_activity_date = v_today,
        streak_start_date = v_today,
        updated_at = now()
      WHERE user_id = p_user_id;
    END IF;
    
    -- Mark as streak counted
    UPDATE daily_activity SET streak_counted = true
    WHERE user_id = p_user_id AND activity_date = v_today;
  END IF;
  
  -- Return result
  v_result := jsonb_build_object(
    'current_streak', v_current_streak,
    'longest_streak', v_longest_streak,
    'daily_goal', v_daily_goal,
    'study_minutes', p_study_minutes
  );
  
  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check and award badges
CREATE OR REPLACE FUNCTION check_and_award_badges(p_user_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_badge RECORD;
  v_earned BOOLEAN;
  v_result JSONB := '[]'::jsonb;
  v_value INTEGER;
BEGIN
  FOR v_badge IN 
    SELECT * FROM badge_definitions WHERE id NOT IN (
      SELECT badge_id FROM user_badges WHERE user_id = p_user_id
    )
  LOOP
    v_earned := false;
    
    -- Check criteria
    CASE v_badge.criteria->>'type'
      WHEN 'first_topic' THEN
        SELECT COUNT(*) >= (v_badge.criteria->>'value')::int INTO v_earned
        FROM user_room_progress WHERE user_id = p_user_id AND visited = true;
        
      WHEN 'streak_days' THEN
        SELECT current_streak >= (v_badge.criteria->>'value')::int INTO v_earned
        FROM user_streaks WHERE user_id = p_user_id;
        
      WHEN 'quiz_perfect' THEN
        SELECT COALESCE(quizzes_perfect, 0) >= (v_badge.criteria->>'value')::int INTO v_earned
        FROM monthly_stats WHERE user_id = p_user_id
        ORDER BY month_year DESC LIMIT 1;
        
      WHEN 'visit_papers' THEN
        SELECT COUNT(DISTINCT room_id) >= (v_badge.criteria->>'value')::int INTO v_earned
        FROM user_room_progress WHERE user_id = p_user_id AND visited = true;
        
      WHEN 'notes_count' THEN
        SELECT COALESCE(SUM(notes_generated), 0) >= (v_badge.criteria->>'value')::int INTO v_earned
        FROM daily_activity WHERE user_id = p_user_id;
        
      WHEN 'doubts_count' THEN
        SELECT COALESCE(SUM(doubts_asked), 0) >= (v_badge.criteria->>'value')::int INTO v_earned
        FROM daily_activity WHERE user_id = p_user_id;
        
      WHEN 'videos_count' THEN
        SELECT COALESCE(SUM(videos_watched), 0) >= (v_badge.criteria->>'value')::int INTO v_earned
        FROM daily_activity WHERE user_id = p_user_id;
        
      WHEN 'level' THEN
        SELECT current_level >= (v_badge.criteria->>'value')::int INTO v_earned
        FROM user_xp WHERE user_id = p_user_id;
        
      ELSE
        v_earned := false;
    END CASE;
    
    IF v_earned THEN
      -- Award badge
      INSERT INTO user_badges (user_id, badge_id)
      VALUES (p_user_id, v_badge.id)
      ON CONFLICT (user_id, badge_id) DO NOTHING;
      
      -- Award XP reward
      IF v_badge.xp_reward > 0 THEN
        PERFORM award_xp(p_user_id, v_badge.xp_reward, 'badge_reward', v_badge.id::text, 'Badge earned: ' || v_badge.name);
      END IF;
      
      -- Create milestone
      INSERT INTO user_milestones (user_id, milestone_type, milestone_value, data)
      VALUES (p_user_id, 'badge_earned', 1, 
        jsonb_build_object('badge_id', v_badge.id, 'badge_name', v_badge.name, 'badge_slug', v_badge.slug));
      
      v_result := v_result || jsonb_build_object('badge', v_badge.slug, 'name', v_badge.name);
    END IF;
  END LOOP;
  
  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get self-comparison stats (AC 8)
CREATE OR REPLACE FUNCTION get_self_comparison(p_user_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_current RECORD;
  v_previous RECORD;
  v_current_month TEXT := to_char(CURRENT_DATE, 'YYYY-MM');
  v_previous_month TEXT := to_char(CURRENT_DATE - INTERVAL '1 month', 'YYYY-MM');
BEGIN
  SELECT * INTO v_current FROM monthly_stats 
  WHERE user_id = p_user_id AND month_year = v_current_month;
  
  SELECT * INTO v_previous FROM monthly_stats 
  WHERE user_id = p_user_id AND month_year = v_previous_month;
  
  RETURN jsonb_build_object(
    'current_month', v_current_month,
    'previous_month', v_previous_month,
    'current', jsonb_build_object(
      'xp', COALESCE(v_current.total_xp, 0),
      'study_minutes', COALESCE(v_current.study_minutes, 0),
      'videos', COALESCE(v_current.videos_watched, 0),
      'quizzes', COALESCE(v_current.quizzes_completed, 0),
      'notes', COALESCE(v_current.notes_generated, 0),
      'streak_days', COALESCE(v_current.streak_days, 0)
    ),
    'previous', jsonb_build_object(
      'xp', COALESCE(v_previous.total_xp, 0),
      'study_minutes', COALESCE(v_previous.study_minutes, 0),
      'videos', COALESCE(v_previous.videos_watched, 0),
      'quizzes', COALESCE(v_previous.quizzes_completed, 0),
      'notes', COALESCE(v_previous.notes_generated, 0),
      'streak_days', COALESCE(v_previous.streak_days, 0)
    ),
    'change', jsonb_build_object(
      'xp', COALESCE(v_current.total_xp, 0) - COALESCE(v_previous.total_xp, 0),
      'study_minutes', COALESCE(v_current.study_minutes, 0) - COALESCE(v_previous.study_minutes, 0),
      'videos', COALESCE(v_current.videos_watched, 0) - COALESCE(v_previous.videos_watched, 0),
      'quizzes', COALESCE(v_current.quizzes_completed, 0) - COALESCE(v_previous.quizzes_completed, 0),
      'notes', COALESCE(v_current.notes_generated, 0) - COALESCE(v_previous.notes_generated, 0)
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 14. ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE gamification_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_xp ENABLE ROW LEVEL SECURITY;
ALTER TABLE xp_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_activity ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_room_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_milestones ENABLE ROW LEVEL SECURITY;
ALTER TABLE monthly_stats ENABLE ROW LEVEL SECURITY;

-- Users can read/write their own data
CREATE POLICY "Users can manage their gamification settings"
  ON gamification_settings FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can read their XP"
  ON user_xp FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can read their XP transactions"
  ON xp_transactions FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can read their badges"
  ON user_badges FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can read their streaks"
  ON user_streaks FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their daily activity"
  ON daily_activity FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their room progress"
  ON user_room_progress FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can read their milestones"
  ON user_milestones FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update milestone celebration"
  ON user_milestones FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their monthly stats"
  ON monthly_stats FOR ALL USING (auth.uid() = user_id);

-- Public tables
CREATE POLICY "Anyone can read badge definitions"
  ON badge_definitions FOR SELECT TO authenticated USING (true);

CREATE POLICY "Anyone can read subject rooms"
  ON subject_rooms FOR SELECT TO authenticated USING (true);

CREATE POLICY "Anyone can read level definitions"
  ON level_definitions FOR SELECT TO authenticated USING (true);

-- ============================================================================
-- 15. TRIGGERS
-- ============================================================================

-- Initialize gamification for new users
CREATE OR REPLACE FUNCTION init_user_gamification()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO gamification_settings (user_id) VALUES (NEW.id) ON CONFLICT DO NOTHING;
  INSERT INTO user_xp (user_id) VALUES (NEW.id) ON CONFLICT DO NOTHING;
  INSERT INTO user_streaks (user_id) VALUES (NEW.id) ON CONFLICT DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS init_gamification_trigger ON auth.users;
CREATE TRIGGER init_gamification_trigger
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION init_user_gamification();

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

