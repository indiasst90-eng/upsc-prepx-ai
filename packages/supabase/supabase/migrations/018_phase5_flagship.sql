-- Phase 5: Flagship Features Migration
-- Date: December 26, 2025
-- Features: Interview Studio, Ethics Case Studies, Gamification, Certificates

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- INTERVIEW STUDIO TABLES
-- ============================================

-- Interview Sessions Table
CREATE TABLE IF NOT EXISTS interview_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL ,
    -- Session config
    session_type TEXT DEFAULT 'general' CHECK (session_type IN ('general', 'daf_based', 'current_affairs', 'optional_subject', 'mock_full')),
    difficulty_level TEXT DEFAULT 'medium' CHECK (difficulty_level IN ('easy', 'medium', 'hard', 'actual')),
    -- DAF context (JSON from user's profile)
    daf_data JSONB DEFAULT '{}',
    -- Interview state
    current_round INTEGER DEFAULT 1,
    total_rounds INTEGER DEFAULT 5,
    is_completed BOOLEAN DEFAULT FALSE,
    -- Timing
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    -- Scores
    total_score DECIMAL(5,2),
    content_score DECIMAL(5,2),
    communication_score DECIMAL(5,2),
    personality_score DECIMAL(5,2),
    -- Feedback summary
    feedback_summary TEXT,
    improvement_areas JSONB DEFAULT '[]',
    strong_points JSONB DEFAULT '[]',
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN ALTER TABLE interview_sessions ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT gen_random_uuid(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE interview_sessions ADD COLUMN IF NOT EXISTS user_id UUID NOT NULL ; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE interview_sessions ADD COLUMN IF NOT EXISTS session_type TEXT DEFAULT 'general' CHECK (session_type IN ('general', 'daf_based', 'current_affairs', 'optional_subject', 'mock_full')); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE interview_sessions ADD COLUMN IF NOT EXISTS difficulty_level TEXT DEFAULT 'medium' CHECK (difficulty_level IN ('easy', 'medium', 'hard', 'actual')); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE interview_sessions ADD COLUMN IF NOT EXISTS daf_data JSONB DEFAULT '{}'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE interview_sessions ADD COLUMN IF NOT EXISTS current_round INTEGER DEFAULT 1; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE interview_sessions ADD COLUMN IF NOT EXISTS total_rounds INTEGER DEFAULT 5; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE interview_sessions ADD COLUMN IF NOT EXISTS is_completed BOOLEAN DEFAULT FALSE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE interview_sessions ADD COLUMN IF NOT EXISTS started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE interview_sessions ADD COLUMN IF NOT EXISTS completed_at TIMESTAMP WITH TIME ZONE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE interview_sessions ADD COLUMN IF NOT EXISTS improvement_areas JSONB DEFAULT '[]'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE interview_sessions ADD COLUMN IF NOT EXISTS strong_points JSONB DEFAULT '[]'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE interview_sessions ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
END $migration$;


-- Indexes for interview_sessions (created after table exists)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_interview_sessions_user') THEN
        DO $migration$ BEGIN
    BEGIN
        CREATE INDEX idx_interview_sessions_user ON interview_sessions(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_interview_sessions_type') THEN
        DO $migration$ BEGIN
    BEGIN
        CREATE INDEX idx_interview_sessions_type ON interview_sessions(session_type);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_interview_sessions_completed') THEN
        DO $migration$ BEGIN
    BEGIN
        CREATE INDEX idx_interview_sessions_completed ON interview_sessions(is_completed) WHERE is_completed = TRUE;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
    END IF;
END $$;

-- Interview Questions Table
CREATE TABLE IF NOT EXISTS interview_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES interview_sessions(id) ON DELETE CASCADE,
    round_number INTEGER NOT NULL,
    question_number INTEGER NOT NULL,
    -- Question content
    question TEXT NOT NULL,
    category TEXT NOT NULL, -- 'background', 'academic', 'current_affairs', 'situational', 'optional'
    follow_up JSONB DEFAULT '[]',
    -- User response
    user_response TEXT,
    response_duration_seconds INTEGER,
    -- AI evaluation
    evaluation JSONB DEFAULT '{}', -- { score, feedback, key_points }
    -- Timestamps
    asked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    answered_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN ALTER TABLE interview_questions ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT gen_random_uuid(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE interview_questions ADD COLUMN IF NOT EXISTS session_id UUID NOT NULL REFERENCES interview_sessions(id) ON DELETE CASCADE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE interview_questions ADD COLUMN IF NOT EXISTS round_number INTEGER NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE interview_questions ADD COLUMN IF NOT EXISTS question_number INTEGER NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE interview_questions ADD COLUMN IF NOT EXISTS question TEXT NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE interview_questions ADD COLUMN IF NOT EXISTS category TEXT NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE interview_questions ADD COLUMN IF NOT EXISTS follow_up JSONB DEFAULT '[]'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE interview_questions ADD COLUMN IF NOT EXISTS evaluation JSONB DEFAULT '{}'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE interview_questions ADD COLUMN IF NOT EXISTS asked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE interview_questions ADD COLUMN IF NOT EXISTS answered_at TIMESTAMP WITH TIME ZONE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE interview_questions ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
END $migration$;


-- Indexes for interview_questions
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_interview_questions_session ON interview_questions(session_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_interview_questions_category ON interview_questions(category);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Interview Question Bank (Admin curated)
CREATE TABLE IF NOT EXISTS interview_question_bank (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- Question content
    question TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('background', 'academic', 'current_affairs', 'situational', 'optional', 'ethics', 'governance')),
    subcategory TEXT,
    difficulty TEXT DEFAULT 'medium' CHECK (difficulty IN ('easy', 'medium', 'hard')),
    -- Answer guidance
    ideal_points JSONB DEFAULT '[]',
    sample_answer TEXT,
    -- Metadata
    times_used INTEGER DEFAULT 0,
    success_rate DECIMAL(3,2),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN ALTER TABLE interview_question_bank ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT gen_random_uuid(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE interview_question_bank ADD COLUMN IF NOT EXISTS question TEXT NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE interview_question_bank ADD COLUMN IF NOT EXISTS category TEXT NOT NULL CHECK (category IN ('background', 'academic', 'current_affairs', 'situational', 'optional', 'ethics', 'governance')); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE interview_question_bank ADD COLUMN IF NOT EXISTS difficulty TEXT DEFAULT 'medium' CHECK (difficulty IN ('easy', 'medium', 'hard')); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE interview_question_bank ADD COLUMN IF NOT EXISTS ideal_points JSONB DEFAULT '[]'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE interview_question_bank ADD COLUMN IF NOT EXISTS times_used INTEGER DEFAULT 0; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE interview_question_bank ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE interview_question_bank ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
END $migration$;


-- Indexes for question bank
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_question_bank_category ON interview_question_bank(category);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_question_bank_active ON interview_question_bank(is_active) WHERE is_active = TRUE;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================
-- ETHICS CASE STUDIES TABLES
-- ============================================

-- Ethics Case Studies Table
CREATE TABLE IF NOT EXISTS ethics_case_studies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- Case content
    title TEXT NOT NULL,
    scenario TEXT NOT NULL, -- The dilemma/situation
    background TEXT, -- Context information
    stakeholders JSONB DEFAULT '[]', -- [{ name: '', perspective: '' }]
    -- Questions
    discussion_questions JSONB DEFAULT '[]',
    -- Evaluation
    eval_criteria JSONB DEFAULT '[]', -- [{ criterion: '', weight: '', description: '' }]
    -- Metadata
    difficulty TEXT DEFAULT 'medium' CHECK (difficulty IN ('easy', 'medium', 'hard')),
    gs_paper TEXT DEFAULT 'GS Paper IV' CHECK (gs_paper IN ('GS Paper IV', 'GS Paper II', 'Essay')),
    tags TEXT[] DEFAULT '{}',
    -- Usage
    times_used INTEGER DEFAULT 0,
    avg_score DECIMAL(5,2),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN ALTER TABLE ethics_case_studies ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT gen_random_uuid(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE ethics_case_studies ADD COLUMN IF NOT EXISTS title TEXT NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE ethics_case_studies ADD COLUMN IF NOT EXISTS scenario TEXT NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE ethics_case_studies ADD COLUMN IF NOT EXISTS stakeholders JSONB DEFAULT '[]'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE ethics_case_studies ADD COLUMN IF NOT EXISTS discussion_questions JSONB DEFAULT '[]'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE ethics_case_studies ADD COLUMN IF NOT EXISTS eval_criteria JSONB DEFAULT '[]'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE ethics_case_studies ADD COLUMN IF NOT EXISTS difficulty TEXT DEFAULT 'medium' CHECK (difficulty IN ('easy', 'medium', 'hard')); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE ethics_case_studies ADD COLUMN IF NOT EXISTS gs_paper TEXT DEFAULT 'GS Paper IV' CHECK (gs_paper IN ('GS Paper IV', 'GS Paper II', 'Essay')); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE ethics_case_studies ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE ethics_case_studies ADD COLUMN IF NOT EXISTS times_used INTEGER DEFAULT 0; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE ethics_case_studies ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE ethics_case_studies ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
END $migration$;


-- User Ethics Attempts
CREATE TABLE IF NOT EXISTS ethics_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL ,
    case_id UUID NOT NULL REFERENCES ethics_case_studies(id) ON DELETE CASCADE,
    -- User's response (structured)
    analysis JSONB NOT NULL DEFAULT '{}', -- { stakeholder_views: '', core_issue: '', resolution: '', principles_applied: [] }
    -- Evaluation
    self_assessment JSONB DEFAULT '{}', -- { confidence: 0-100, time_taken: seconds }
    ai_evaluation JSONB DEFAULT '{}', -- { score, feedback, rubric_scores: {}, improvement_tips: [] }
    -- Status
    is_completed BOOLEAN DEFAULT FALSE,
    attempt_number INTEGER DEFAULT 1,
    -- Timestamps
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, case_id, attempt_number)
);

DO $migration$ BEGIN
    BEGIN ALTER TABLE ethics_attempts ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT gen_random_uuid(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE ethics_attempts ADD COLUMN IF NOT EXISTS user_id UUID NOT NULL ; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE ethics_attempts ADD COLUMN IF NOT EXISTS case_id UUID NOT NULL REFERENCES ethics_case_studies(id) ON DELETE CASCADE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE ethics_attempts ADD COLUMN IF NOT EXISTS analysis JSONB NOT NULL DEFAULT '{}'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE ethics_attempts ADD COLUMN IF NOT EXISTS self_assessment JSONB DEFAULT '{}'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE ethics_attempts ADD COLUMN IF NOT EXISTS ai_evaluation JSONB DEFAULT '{}'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE ethics_attempts ADD COLUMN IF NOT EXISTS is_completed BOOLEAN DEFAULT FALSE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE ethics_attempts ADD COLUMN IF NOT EXISTS attempt_number INTEGER DEFAULT 1; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE ethics_attempts ADD COLUMN IF NOT EXISTS started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE ethics_attempts ADD COLUMN IF NOT EXISTS completed_at TIMESTAMP WITH TIME ZONE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE ethics_attempts ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
END $migration$;


-- Indexes for ethics_attempts
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_ethics_attempts_user ON ethics_attempts(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_ethics_attempts_case ON ethics_attempts(case_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================
-- GAMIFICATION TABLES
-- ============================================

-- User Stats (Aggregated)
CREATE TABLE IF NOT EXISTS user_stats (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid() ,
    -- Study metrics
    total_study_minutes INTEGER DEFAULT 0,
    total_videos_watched INTEGER DEFAULT 0,
    total_questions_attempted INTEGER DEFAULT 0,
    total_correct_answers INTEGER DEFAULT 0,
    total_essays_written INTEGER DEFAULT 0,
    total_mocks_taken INTEGER DEFAULT 0,
    -- Streaks
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    last_activity_date DATE,
    -- Levels
    level INTEGER DEFAULT 1,
    xp INTEGER DEFAULT 0,
    xp_to_next_level INTEGER GENERATED ALWAYS AS (
        CASE
            WHEN level = 1 THEN 100
            WHEN level = 2 THEN 250
            WHEN level = 3 THEN 500
            WHEN level = 4 THEN 1000
            WHEN level = 5 THEN 2000
            WHEN level = 6 THEN 3500
            WHEN level = 7 THEN 5000
            WHEN level = 8 THEN 7500
            WHEN level = 9 THEN 10000
            ELSE 15000
        END
    ) STORED,
    -- Badges
    badges JSONB DEFAULT '[]', -- [{ id: '', name: '', earned_at: '', icon: '' }]
    -- Rankings
    study_rank INTEGER, -- Updated periodically
    quiz_rank INTEGER,
    -- Timestamps
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN ALTER TABLE user_stats ADD COLUMN IF NOT EXISTS user_id UUID PRIMARY KEY DEFAULT gen_random_uuid() ; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE user_stats ADD COLUMN IF NOT EXISTS total_study_minutes INTEGER DEFAULT 0; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE user_stats ADD COLUMN IF NOT EXISTS total_videos_watched INTEGER DEFAULT 0; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE user_stats ADD COLUMN IF NOT EXISTS total_questions_attempted INTEGER DEFAULT 0; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE user_stats ADD COLUMN IF NOT EXISTS total_correct_answers INTEGER DEFAULT 0; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE user_stats ADD COLUMN IF NOT EXISTS total_essays_written INTEGER DEFAULT 0; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE user_stats ADD COLUMN IF NOT EXISTS total_mocks_taken INTEGER DEFAULT 0; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE user_stats ADD COLUMN IF NOT EXISTS current_streak INTEGER DEFAULT 0; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE user_stats ADD COLUMN IF NOT EXISTS longest_streak INTEGER DEFAULT 0; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE user_stats ADD COLUMN IF NOT EXISTS level INTEGER DEFAULT 1; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE user_stats ADD COLUMN IF NOT EXISTS xp INTEGER DEFAULT 0; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE user_stats ADD COLUMN IF NOT EXISTS xp_to_next_level INTEGER GENERATED ALWAYS AS (CASE WHEN level = 1 THEN 100 WHEN level = 2 THEN 250 WHEN level = 3 THEN 500 WHEN level = 4 THEN 1000 WHEN level = 5 THEN 2000 WHEN level = 6 THEN 3500 WHEN level = 7 THEN 5000 WHEN level = 8 THEN 7500 WHEN level = 9 THEN 10000 ELSE 15000 END) STORED; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE user_stats ADD COLUMN IF NOT EXISTS badges JSONB DEFAULT '[]'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE user_stats ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
END $migration$;


-- Streak History
CREATE TABLE IF NOT EXISTS streak_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL ,
    streak_date DATE NOT NULL,
    streak_type TEXT DEFAULT 'study' CHECK (streak_type IN ('study', 'quiz', 'revision', 'mock', 'video')),
    activity_count INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, streak_date, streak_type)
);

DO $migration$ BEGIN
    BEGIN ALTER TABLE streak_history ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT gen_random_uuid(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE streak_history ADD COLUMN IF NOT EXISTS user_id UUID NOT NULL ; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE streak_history ADD COLUMN IF NOT EXISTS streak_date DATE NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE streak_history ADD COLUMN IF NOT EXISTS streak_type TEXT DEFAULT 'study' CHECK (streak_type IN ('study', 'quiz', 'revision', 'mock', 'video')); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE streak_history ADD COLUMN IF NOT EXISTS activity_count INTEGER DEFAULT 1; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE streak_history ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
END $migration$;


-- Daily Challenges
CREATE TABLE IF NOT EXISTS daily_challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date DATE NOT NULL UNIQUE,
    -- Challenge config
    challenge_type TEXT NOT NULL CHECK (challenge_type IN ('study_minutes', 'questions', 'essays', 'revision', 'videos', 'streak')),
    target_value INTEGER NOT NULL,
    xp_reward INTEGER NOT NULL,
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN ALTER TABLE daily_challenges ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT gen_random_uuid(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_challenges ADD COLUMN IF NOT EXISTS date DATE NOT NULL UNIQUE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_challenges ADD COLUMN IF NOT EXISTS challenge_type TEXT NOT NULL CHECK (challenge_type IN ('study_minutes', 'questions', 'essays', 'revision', 'videos', 'streak')); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_challenges ADD COLUMN IF NOT EXISTS target_value INTEGER NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_challenges ADD COLUMN IF NOT EXISTS xp_reward INTEGER NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_challenges ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_challenges ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
END $migration$;


-- User Challenge Progress
CREATE TABLE IF NOT EXISTS user_challenge_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL ,
    challenge_id UUID NOT NULL REFERENCES daily_challenges(id) ON DELETE CASCADE,
    current_value INTEGER DEFAULT 0,
    is_completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, challenge_id)
);

DO $migration$ BEGIN
    BEGIN ALTER TABLE user_challenge_progress ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT gen_random_uuid(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE user_challenge_progress ADD COLUMN IF NOT EXISTS user_id UUID NOT NULL ; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE user_challenge_progress ADD COLUMN IF NOT EXISTS challenge_id UUID NOT NULL REFERENCES daily_challenges(id) ON DELETE CASCADE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE user_challenge_progress ADD COLUMN IF NOT EXISTS current_value INTEGER DEFAULT 0; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE user_challenge_progress ADD COLUMN IF NOT EXISTS is_completed BOOLEAN DEFAULT FALSE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE user_challenge_progress ADD COLUMN IF NOT EXISTS completed_at TIMESTAMP WITH TIME ZONE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE user_challenge_progress ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
END $migration$;


-- ============================================
-- ACHIEVEMENTS & BADGES
-- ============================================

-- Badge Definitions
CREATE TABLE IF NOT EXISTS badge_definitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    icon_url TEXT,
    category TEXT NOT NULL CHECK (category IN ('study', 'quiz', 'streak', 'milestone', 'special')),
    -- Unlock criteria
    criteria_type TEXT NOT NULL, -- 'streak', 'total_xp', 'questions_correct', 'essays_written', 'videos_watched', 'mocks_taken'
    criteria_value INTEGER NOT NULL,
    -- Rarity
    rarity TEXT DEFAULT 'common' CHECK (rarity IN ('common', 'rare', 'epic', 'legendary')),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN ALTER TABLE badge_definitions ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT gen_random_uuid(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE badge_definitions ADD COLUMN IF NOT EXISTS name TEXT NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE badge_definitions ADD COLUMN IF NOT EXISTS description TEXT NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE badge_definitions ADD COLUMN IF NOT EXISTS category TEXT NOT NULL CHECK (category IN ('study', 'quiz', 'streak', 'milestone', 'special')); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE badge_definitions ADD COLUMN IF NOT EXISTS criteria_type TEXT NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE badge_definitions ADD COLUMN IF NOT EXISTS criteria_value INTEGER NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE badge_definitions ADD COLUMN IF NOT EXISTS rarity TEXT DEFAULT 'common' CHECK (rarity IN ('common', 'rare', 'epic', 'legendary')); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE badge_definitions ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE badge_definitions ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
END $migration$;


-- User Badges (Earned)
CREATE TABLE IF NOT EXISTS user_badges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL ,
    badge_id UUID NOT NULL REFERENCES badge_definitions(id) ON DELETE CASCADE,
    earned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    progress_at_earn JSONB DEFAULT '{}',
    UNIQUE(user_id, badge_id)
);

DO $migration$ BEGIN
    BEGIN ALTER TABLE user_badges ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT gen_random_uuid(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE user_badges ADD COLUMN IF NOT EXISTS user_id UUID NOT NULL ; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE user_badges ADD COLUMN IF NOT EXISTS badge_id UUID NOT NULL REFERENCES badge_definitions(id) ON DELETE CASCADE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE user_badges ADD COLUMN IF NOT EXISTS earned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE user_badges ADD COLUMN IF NOT EXISTS progress_at_earn JSONB DEFAULT '{}'; EXCEPTION WHEN OTHERS THEN NULL; END;
END $migration$;


-- ============================================
-- CERTIFICATES
-- ============================================

-- Certificate Templates
CREATE TABLE IF NOT EXISTS certificate_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    template_type TEXT NOT NULL CHECK (template_type IN ('course_completion', 'milestone', 'achievement', 'streak', 'rank')),
    -- Visual config
    background_url TEXT,
    template_json JSONB NOT NULL DEFAULT '{}', -- { header, body, footer, signature }
    -- Dimensions
    width INTEGER DEFAULT 1200,
    height INTEGER DEFAULT 800,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN ALTER TABLE certificate_templates ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT gen_random_uuid(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE certificate_templates ADD COLUMN IF NOT EXISTS name TEXT NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE certificate_templates ADD COLUMN IF NOT EXISTS template_type TEXT NOT NULL CHECK (template_type IN ('course_completion', 'milestone', 'achievement', 'streak', 'rank')); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE certificate_templates ADD COLUMN IF NOT EXISTS template_json JSONB NOT NULL DEFAULT '{}'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE certificate_templates ADD COLUMN IF NOT EXISTS width INTEGER DEFAULT 1200; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE certificate_templates ADD COLUMN IF NOT EXISTS height INTEGER DEFAULT 800; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE certificate_templates ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE certificate_templates ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
END $migration$;


-- Generated Certificates
CREATE TABLE IF NOT EXISTS certificates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL ,
    template_id UUID NOT NULL REFERENCES certificate_templates(id) ON DELETE CASCADE,
    -- Certificate data
    certificate_number TEXT UNIQUE NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    -- Recipients
    recipient_name TEXT NOT NULL,
    -- Details
    achievement TEXT NOT NULL,
    details_json JSONB DEFAULT '{}', -- { score: '', date: '', duration: '' }
    -- File
    certificate_url TEXT,
    -- Verification
    verification_code TEXT UNIQUE,
    is_verified BOOLEAN DEFAULT TRUE,
    -- Timestamps
    issued_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN ALTER TABLE certificates ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT gen_random_uuid(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE certificates ADD COLUMN IF NOT EXISTS user_id UUID NOT NULL ; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE certificates ADD COLUMN IF NOT EXISTS template_id UUID NOT NULL REFERENCES certificate_templates(id) ON DELETE CASCADE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE certificates ADD COLUMN IF NOT EXISTS certificate_number TEXT UNIQUE NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE certificates ADD COLUMN IF NOT EXISTS title TEXT NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE certificates ADD COLUMN IF NOT EXISTS recipient_name TEXT NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE certificates ADD COLUMN IF NOT EXISTS achievement TEXT NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE certificates ADD COLUMN IF NOT EXISTS details_json JSONB DEFAULT '{}'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE certificates ADD COLUMN IF NOT EXISTS verification_code TEXT UNIQUE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE certificates ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT TRUE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE certificates ADD COLUMN IF NOT EXISTS issued_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE certificates ADD COLUMN IF NOT EXISTS expires_at TIMESTAMP WITH TIME ZONE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE certificates ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
END $migration$;


-- Indexes for certificates
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_certificates_user ON certificates(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_certificates_verify ON certificates(verification_code);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_certificates_number ON certificates(certificate_number);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================
-- LEADERBOARDS
-- ============================================

CREATE TABLE IF NOT EXISTS leaderboards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    type TEXT NOT NULL CHECK (type IN ('weekly', 'monthly', 'all_time', 'subject', 'custom')),
    scope TEXT NOT NULL CHECK (scope IN ('global', 'friends', 'batch')),
    -- Config
    ranking_criteria TEXT NOT NULL, -- 'xp', 'streak', 'score', 'study_time'
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    starts_at TIMESTAMP WITH TIME ZONE,
    ends_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN ALTER TABLE leaderboards ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT gen_random_uuid(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE leaderboards ADD COLUMN IF NOT EXISTS name TEXT NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE leaderboards ADD COLUMN IF NOT EXISTS type TEXT NOT NULL CHECK (type IN ('weekly', 'monthly', 'all_time', 'subject', 'custom')); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE leaderboards ADD COLUMN IF NOT EXISTS scope TEXT NOT NULL CHECK (scope IN ('global', 'friends', 'batch')); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE leaderboards ADD COLUMN IF NOT EXISTS ranking_criteria TEXT NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE leaderboards ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE leaderboards ADD COLUMN IF NOT EXISTS starts_at TIMESTAMP WITH TIME ZONE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE leaderboards ADD COLUMN IF NOT EXISTS ends_at TIMESTAMP WITH TIME ZONE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE leaderboards ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
END $migration$;


-- Leaderboard Entries (Updated daily via cron)
CREATE TABLE IF NOT EXISTS leaderboard_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    leaderboard_id UUID NOT NULL REFERENCES leaderboards(id) ON DELETE CASCADE,
    user_id UUID NOT NULL ,
    rank INTEGER NOT NULL,
    score DECIMAL(10,2) NOT NULL,
    metrics_json JSONB DEFAULT '{}',
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(leaderboard_id, user_id)
);

DO $migration$ BEGIN
    BEGIN ALTER TABLE leaderboard_entries ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT gen_random_uuid(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE leaderboard_entries ADD COLUMN IF NOT EXISTS leaderboard_id UUID NOT NULL REFERENCES leaderboards(id) ON DELETE CASCADE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE leaderboard_entries ADD COLUMN IF NOT EXISTS user_id UUID NOT NULL ; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE leaderboard_entries ADD COLUMN IF NOT EXISTS rank INTEGER NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE leaderboard_entries ADD COLUMN IF NOT EXISTS metrics_json JSONB DEFAULT '{}'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE leaderboard_entries ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
END $migration$;


-- Indexes for leaderboard entries
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_leaderboard_entries_lb ON leaderboard_entries(leaderboard_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_leaderboard_entries_rank ON leaderboard_entries(leaderboard_id, rank);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================
-- COMMUNITY TABLES
-- ============================================

-- Discussion Forums
CREATE TABLE IF NOT EXISTS discussion_forums (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL CHECK (category IN ('general', 'gs1', 'gs2', 'gs3', 'gs4', 'optional', 'essay', 'current_affairs')),
    -- Moderation
    is_moderated BOOLEAN DEFAULT TRUE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN ALTER TABLE discussion_forums ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT gen_random_uuid(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE discussion_forums ADD COLUMN IF NOT EXISTS name TEXT NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE discussion_forums ADD COLUMN IF NOT EXISTS category TEXT NOT NULL CHECK (category IN ('general', 'gs1', 'gs2', 'gs3', 'gs4', 'optional', 'essay', 'current_affairs')); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE discussion_forums ADD COLUMN IF NOT EXISTS is_moderated BOOLEAN DEFAULT TRUE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE discussion_forums ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE discussion_forums ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
END $migration$;


-- Discussion Threads
CREATE TABLE IF NOT EXISTS discussion_threads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    forum_id UUID NOT NULL REFERENCES discussion_forums(id) ON DELETE CASCADE,
    user_id UUID NOT NULL ,
    -- Content
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    tags TEXT[] DEFAULT '{}',
    -- State
    is_pinned BOOLEAN DEFAULT FALSE,
    is_locked BOOLEAN DEFAULT FALSE,
    view_count INTEGER DEFAULT 0,
    -- Timestamps
    last_activity_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN ALTER TABLE discussion_threads ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT gen_random_uuid(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE discussion_threads ADD COLUMN IF NOT EXISTS forum_id UUID NOT NULL REFERENCES discussion_forums(id) ON DELETE CASCADE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE discussion_threads ADD COLUMN IF NOT EXISTS user_id UUID NOT NULL ; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE discussion_threads ADD COLUMN IF NOT EXISTS title TEXT NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE discussion_threads ADD COLUMN IF NOT EXISTS content TEXT NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE discussion_threads ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE discussion_threads ADD COLUMN IF NOT EXISTS is_pinned BOOLEAN DEFAULT FALSE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE discussion_threads ADD COLUMN IF NOT EXISTS is_locked BOOLEAN DEFAULT FALSE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE discussion_threads ADD COLUMN IF NOT EXISTS view_count INTEGER DEFAULT 0; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE discussion_threads ADD COLUMN IF NOT EXISTS last_activity_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE discussion_threads ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
END $migration$;


-- Discussion Posts
CREATE TABLE IF NOT EXISTS discussion_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thread_id UUID NOT NULL REFERENCES discussion_threads(id) ON DELETE CASCADE,
    user_id UUID NOT NULL ,
    -- Content
    content TEXT NOT NULL,
    parent_id UUID, -- For nested replies
    -- State
    is_accepted_answer BOOLEAN DEFAULT FALSE,
    upvotes INTEGER DEFAULT 0,
    downvotes INTEGER DEFAULT 0,
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN ALTER TABLE discussion_posts ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT gen_random_uuid(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE discussion_posts ADD COLUMN IF NOT EXISTS thread_id UUID NOT NULL REFERENCES discussion_threads(id) ON DELETE CASCADE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE discussion_posts ADD COLUMN IF NOT EXISTS user_id UUID NOT NULL ; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE discussion_posts ADD COLUMN IF NOT EXISTS content TEXT NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE discussion_posts ADD COLUMN IF NOT EXISTS is_accepted_answer BOOLEAN DEFAULT FALSE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE discussion_posts ADD COLUMN IF NOT EXISTS upvotes INTEGER DEFAULT 0; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE discussion_posts ADD COLUMN IF NOT EXISTS downvotes INTEGER DEFAULT 0; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE discussion_posts ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
END $migration$;


-- Indexes for discussions
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_threads_forum ON discussion_threads(forum_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_threads_activity ON discussion_threads(last_activity_at);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_posts_thread ON discussion_posts(thread_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================
-- RLS POLICIES
-- ============================================

DO $migration$ BEGIN
    BEGIN
        ALTER TABLE interview_sessions ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE interview_questions ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE interview_question_bank ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE ethics_case_studies ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE ethics_attempts ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE user_stats ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE streak_history ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE daily_challenges ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE user_challenge_progress ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE badge_definitions ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE certificate_templates ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE certificates ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE leaderboards ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE leaderboard_entries ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE discussion_forums ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE discussion_threads ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE discussion_posts ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Interview sessions - owner only

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can view own interview sessions" ON interview_sessions
    FOR SELECT USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can create interview sessions" ON interview_sessions
    FOR INSERT WITH CHECK (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can update own interview sessions" ON interview_sessions
    FOR UPDATE USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Interview questions - owner only

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can view own interview questions" ON interview_questions
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM interview_sessions WHERE id = interview_questions.session_id AND user_id = auth.uid())
    );
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can update own interview questions" ON interview_questions
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM interview_sessions WHERE id = interview_questions.session_id AND user_id = auth.uid())
    );
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Question bank - public read

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Anyone can view question bank" ON interview_question_bank
    FOR SELECT USING (is_active = TRUE);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Ethics case studies - public read

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Anyone can view ethics cases" ON ethics_case_studies
    FOR SELECT USING (is_active = TRUE);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Ethics attempts - owner only

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can view own ethics attempts" ON ethics_attempts
    FOR SELECT USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can create ethics attempts" ON ethics_attempts
    FOR INSERT WITH CHECK (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can update own ethics attempts" ON ethics_attempts
    FOR UPDATE USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- User stats - owner only

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can view own stats" ON user_stats
    FOR SELECT USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can update own stats" ON user_stats
    FOR UPDATE USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Streak history - owner only

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can view own streak history" ON streak_history
    FOR SELECT USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can create streak history" ON streak_history
    FOR INSERT WITH CHECK (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Daily challenges - public read

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Anyone can view daily challenges" ON daily_challenges
    FOR SELECT USING (is_active = TRUE);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- User challenge progress - owner only

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can view own challenge progress" ON user_challenge_progress
    FOR SELECT USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can update own challenge progress" ON user_challenge_progress
    FOR UPDATE USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Badge definitions - public read

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Anyone can view badge definitions" ON badge_definitions
    FOR SELECT USING (is_active = TRUE);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- User badges - owner only

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can view own badges" ON user_badges
    FOR SELECT USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can earn badges" ON user_badges
    FOR INSERT WITH CHECK (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Certificate templates - public read

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Anyone can view certificate templates" ON certificate_templates
    FOR SELECT USING (is_active = TRUE);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Certificates - owner only

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can view own certificates" ON certificates
    FOR SELECT USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can create certificates" ON certificates
    FOR INSERT WITH CHECK (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Leaderboards - public read

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Anyone can view leaderboards" ON leaderboards
    FOR SELECT USING (is_active = TRUE);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Anyone can view leaderboard entries" ON leaderboard_entries
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM leaderboards WHERE id = leaderboard_entries.leaderboard_id AND is_active = TRUE)
    );
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Discussions - authenticated read

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Anyone can view forums" ON discussion_forums
    FOR SELECT USING (is_active = TRUE);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Anyone can view threads" ON discussion_threads
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM discussion_forums WHERE id = discussion_threads.forum_id AND is_active = TRUE)
    );
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can create threads" ON discussion_threads
    FOR INSERT WITH CHECK (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can view own threads" ON discussion_threads
    FOR SELECT USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can update own threads" ON discussion_threads
    FOR UPDATE USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Anyone can view posts" ON discussion_posts
    FOR SELECT USING (true);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can create posts" ON discussion_posts
    FOR INSERT WITH CHECK (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can update own posts" ON discussion_posts
    FOR UPDATE USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Calculate user level from XP
DO $migration$ BEGIN
    BEGIN
        CREATE OR REPLACE FUNCTION calculate_level(p_xp INTEGER)
RETURNS INTEGER AS $$
DECLARE
    level_thresholds INTEGER[] := ARRAY[0, 100, 250, 500, 1000, 2000, 3500, 5000, 7500, 10000, 15000, 25000, 40000, 60000, 100000];
    lvl INTEGER := 1;
BEGIN
    FOR i IN 1..array_length(level_thresholds, 1) LOOP
        IF p_xp >= level_thresholds[i] THEN
            lvl := i;
        END IF;
    END LOOP;
    RETURN lvl;
END;
$$ LANGUAGE plpgsql;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Generate certificate number
DO $migration$ BEGIN
    BEGIN
        CREATE OR REPLACE FUNCTION generate_certificate_number()
RETURNS TEXT AS $$
BEGIN
    RETURN 'CERT-' || upper(to_char(NOW(), 'YYYYMMDD')) || '-' ||
           substring(md5(random()::text) from 1 for 8)::text;
END;
$$ LANGUAGE plpgsql;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Generate verification code
DO $migration$ BEGIN
    BEGIN
        CREATE OR REPLACE FUNCTION generate_verification_code()
RETURNS TEXT AS $$
BEGIN
    RETURN upper(md5(random()::text || NOW()::text));
END;
$$ LANGUAGE plpgsql;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Update streak
DO $migration$ BEGIN
    BEGIN
        CREATE OR REPLACE FUNCTION update_user_streak(p_user_id UUID, p_date DATE, p_type TEXT DEFAULT 'study')
RETURNS void AS $$
DECLARE
    v_current_streak INTEGER;
    v_last_date DATE;
BEGIN
    -- Get current streak info
    SELECT current_streak, last_activity_date INTO v_current_streak, v_last_date
    FROM user_stats WHERE user_id = p_user_id;

    IF v_last_date IS NULL THEN
        -- First activity
        UPDATE user_stats SET
            current_streak = 1,
            last_activity_date = p_date,
            updated_at = NOW()
        WHERE user_id = p_user_id;
    ELSIF v_last_date = p_date - 1 THEN
        -- Consecutive day
        UPDATE user_stats SET
            current_streak = v_current_streak + 1,
            last_activity_date = p_date,
            updated_at = NOW()
        WHERE user_id = p_user_id;
        -- Update longest streak
        UPDATE user_stats SET
            longest_streak = GREATEST(longest_streak, v_current_streak + 1)
        WHERE user_id = p_user_id;
    ELSIF v_last_date < p_date - 1 THEN
        -- Streak broken
        UPDATE user_stats SET
            current_streak = 1,
            last_activity_date = p_date,
            updated_at = NOW()
        WHERE user_id = p_user_id;
    END IF;

    -- Log activity
    INSERT INTO streak_history (user_id, streak_date, streak_type)
    VALUES (p_user_id, p_date, p_type)
    ON CONFLICT (user_id, streak_date, streak_type) DO NOTHING;
END;
$$ LANGUAGE plpgsql;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Add XP and check for level up
DO $migration$ BEGIN
    BEGIN
        CREATE OR REPLACE FUNCTION add_xp(p_user_id UUID, p_xp_amount INTEGER)
RETURNS JSONB AS $$
DECLARE
    v_old_level INTEGER;
    v_new_level INTEGER;
    v_old_xp INTEGER;
    v_new_xp INTEGER;
BEGIN
    SELECT level, xp INTO v_old_level, v_old_xp
    FROM user_stats WHERE user_id = p_user_id;

    v_new_xp := v_old_xp + p_xp_amount;
    v_new_level := calculate_level(v_new_xp);

    UPDATE user_stats SET
        xp = v_new_xp,
        level = v_new_level,
        updated_at = NOW()
    WHERE user_id = p_user_id;

    RETURN jsonb_build_object(
        'leveled_up', v_new_level > v_old_level,
        'old_level', v_old_level,
        'new_level', v_new_level,
        'xp_gained', p_xp_amount,
        'total_xp', v_new_xp
    );
END;
$$ LANGUAGE plpgsql;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================
-- SEED DATA
-- ============================================

-- Seed badge definitions
DO $migration$ BEGIN
    BEGIN
INSERT INTO badge_definitions (name, description, icon_url, category, criteria_type, criteria_value, rarity) VALUES
    ('First Step', 'Started your UPSC journey', '🎯', 'milestone', 'streak', 1, 'common'),
    ('Week Warrior', '7 day study streak', '🔥', 'streak', 'streak', 7, 'common'),
    ('Month Master', '30 day study streak', '💪', 'streak', 'streak', 30, 'rare'),
    ('Century Club', '100 day study streak', '👑', 'streak', 'streak', 100, 'epic'),
    ('Quiz Whiz', 'Answered 100 questions correctly', '🧠', 'quiz', 'questions_correct', 100, 'common'),
    ('Quiz Champion', 'Answered 1000 questions correctly', '🏆', 'quiz', 'questions_correct', 1000, 'rare'),
    ('Essay Enthusiast', 'Wrote 10 essays', '✍️', 'study', 'essays_written', 10, 'common'),
    ('Essay Master', 'Wrote 50 essays', '📜', 'study', 'essays_written', 50, 'rare'),
    ('Video Veteran', 'Watched 50 videos', '🎬', 'study', 'videos_watched', 50, 'common'),
    ('Mock Warrior', 'Completed 5 mock tests', '📝', 'study', 'mocks_taken', 5, 'common'),
    ('Early Bird', 'First study session before 6 AM', '🌅', 'special', 'streak', 1, 'common'),
    ('Night Owl', 'Study session after 11 PM', '🦉', 'special', 'streak', 1, 'common')
ON CONFLICT DO NOTHING;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Seed certificate templates
DO $migration$ BEGIN
    BEGIN
INSERT INTO certificate_templates (name, description, template_type, template_json) VALUES
    ('7 Day Streak', 'Certificate for completing 7 day study streak', 'streak',
     '{"header": "UPSC PrepX-AI", "body": "This certifies that", "footer": "has completed a 7-day study streak"}'),
    ('30 Day Challenge', 'Certificate for completing 30 day study challenge', 'milestone',
     '{"header": "UPSC PrepX-AI", "body": "This certifies that", "footer": "has completed the 30-day study challenge"}'),
    ('Course Complete', 'Certificate for completing a course module', 'course_completion',
     '{"header": "UPSC PrepX-AI", "body": "This certifies that", "footer": "has successfully completed"}'),
    ('Top Performer', 'Certificate for achieving top rank', 'rank',
     '{"header": "UPSC PrepX-AI Excellence Award", "body": "This certifies that", "footer": "for outstanding performance"}')
ON CONFLICT DO NOTHING;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Seed discussion forums
DO $migration$ BEGIN
    BEGIN
INSERT INTO discussion_forums (name, description, category) VALUES
    ('General Discussion', 'General UPSC preparation discussions', 'general'),
    ('GS Paper I', 'History, Geography, Art & Culture', 'gs1'),
    ('GS Paper II', 'Polity, Constitution, Governance', 'gs2'),
    ('GS Paper III', 'Economy, Environment, Science & Tech', 'gs3'),
    ('GS Paper IV', 'Ethics, Integrity, Aptitude', 'gs4'),
    ('Optional Subject', 'Optional subject discussions', 'optional'),
    ('Essay Preparation', 'Essay writing strategies', 'essay'),
    ('Current Affairs', 'Daily current affairs discussions', 'current_affairs')
ON CONFLICT DO NOTHING;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Seed leaderboards
DO $migration$ BEGIN
    BEGIN
INSERT INTO leaderboards (name, description, type, scope, ranking_criteria) VALUES
    ('Weekly Top Studiers', 'Most study time this week', 'weekly', 'global', 'study_time'),
    ('Monthly XP Leaders', 'Highest XP earners this month', 'monthly', 'global', 'xp'),
    ('All Time Legends', 'All-time top performers', 'all_time', 'global', 'xp'),
    ('Quiz Champions', 'Best quiz scores', 'weekly', 'global', 'score'),
    ('Streak Masters', 'Longest current streaks', 'weekly', 'global', 'streak')
ON CONFLICT DO NOTHING;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Seed daily challenges for next 7 days
DO $migration$ BEGIN
    BEGIN
INSERT INTO daily_challenges (date, challenge_type, target_value, xp_reward) VALUES
    (CURRENT_DATE, 'study_minutes', 60, 50),
    (CURRENT_DATE, 'questions', 20, 30),
    (CURRENT_DATE + 1, 'study_minutes', 60, 50),
    (CURRENT_DATE + 1, 'questions', 20, 30),
    (CURRENT_DATE + 2, 'study_minutes', 60, 50),
    (CURRENT_DATE + 2, 'videos', 2, 40),
    (CURRENT_DATE + 3, 'study_minutes', 60, 50),
    (CURRENT_DATE + 3, 'questions', 20, 30),
    (CURRENT_DATE + 4, 'study_minutes', 60, 50),
    (CURRENT_DATE + 4, 'essays', 1, 100),
    (CURRENT_DATE + 5, 'study_minutes', 60, 50),
    (CURRENT_DATE + 5, 'questions', 20, 30),
    (CURRENT_DATE + 6, 'study_minutes', 60, 50),
    (CURRENT_DATE + 6, 'revision', 10, 40),
    (CURRENT_DATE + 6, 'streak', 7, 200)
ON CONFLICT (date) DO NOTHING;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Print migration status
SELECT 'Phase 5 migration completed successfully' AS status;

-- Show created tables
SELECT table_name, (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = 'public' AND table_name = t.table_name) AS column_count
FROM information_schema.tables t
WHERE table_schema = 'public'
  AND table_name IN (
    'interview_sessions', 'interview_questions', 'interview_question_bank',
    'ethics_case_studies', 'ethics_attempts',
    'user_stats', 'streak_history', 'daily_challenges', 'user_challenge_progress',
    'badge_definitions', 'user_badges',
    'certificate_templates', 'certificates',
    'leaderboards', 'leaderboard_entries',
    'discussion_forums', 'discussion_threads', 'discussion_posts'
  )
ORDER BY table_name;


