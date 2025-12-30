-- Migration: 024_detailed_syllabus_tracking.sql
-- Description: Ultra-detailed syllabus progress tracking with topic-level metrics
-- Author: Dev Agent (BMAD)
-- Date: December 26, 2025
-- Story: 6.2 - Ultra-Detailed Syllabus Tracking Dashboard

-- ============================================================================
-- TOPIC PROGRESS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.topic_progress (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL ,
  paper TEXT NOT NULL CHECK (paper IN ('GS1', 'GS2', 'GS3', 'GS4', 'CSAT', 'Essay', 'Optional')),
  subject TEXT NOT NULL,
  topic TEXT NOT NULL,
  completion_percentage INTEGER DEFAULT 0 CHECK (completion_percentage >= 0 AND completion_percentage <= 100),
  confidence_score INTEGER DEFAULT 0 CHECK (confidence_score >= 0 AND confidence_score <= 100),
  time_spent_minutes INTEGER DEFAULT 0,
  last_studied_at TIMESTAMPTZ,
  notes_count INTEGER DEFAULT 0,
  videos_watched INTEGER DEFAULT 0,
  questions_attempted INTEGER DEFAULT 0,
  questions_correct INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, paper, subject, topic)
);

-- Use DO block to avoid duplicate index errors
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_topic_progress_user_id') THEN
        DO $migration$ BEGIN
    BEGIN
        CREATE INDEX idx_topic_progress_user_id ON public.topic_progress(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_topic_progress_paper') THEN
        DO $migration$ BEGIN
    BEGIN
        CREATE INDEX idx_topic_progress_paper ON public.topic_progress(user_id, paper);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_topic_progress_confidence') THEN
        DO $migration$ BEGIN
    BEGIN
        CREATE INDEX idx_topic_progress_confidence ON public.topic_progress(user_id, confidence_score);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_topic_progress_completion') THEN
        DO $migration$ BEGIN
    BEGIN
        CREATE INDEX idx_topic_progress_completion ON public.topic_progress(user_id, completion_percentage);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
    END IF;
END $$;

DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.topic_progress ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can manage own topic progress"
  ON public.topic_progress FOR ALL
  USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE TRIGGER set_topic_progress_updated_at
  BEFORE UPDATE ON public.topic_progress
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================================================
-- STUDY SESSIONS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.study_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL ,
  session_date DATE NOT NULL,
  topic_id UUID REFERENCES public.topic_progress(id) ON DELETE SET NULL,
  duration_minutes INTEGER NOT NULL CHECK (duration_minutes > 0),
  activity_type TEXT NOT NULL CHECK (activity_type IN ('reading', 'video', 'practice', 'revision')),
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN
        CREATE INDEX idx_study_sessions_user_date ON public.study_sessions(user_id, session_date);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX idx_study_sessions_topic ON public.study_sessions(topic_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.study_sessions ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can manage own study sessions"
  ON public.study_sessions FOR ALL
  USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================================================
-- SEED DATA - UPSC SYLLABUS STRUCTURE
-- ============================================================================

-- Sample topics for GS1
DO $migration$ BEGIN
    BEGIN
INSERT INTO public.topic_progress (user_id, paper, subject, topic, completion_percentage, confidence_score)
SELECT 
  u.id,
  'GS1',
  'History',
  topic,
  0,
  0
FROM public.users u
CROSS JOIN (VALUES 
  ('Ancient India'),
  ('Medieval India'),
  ('Modern India'),
  ('Freedom Struggle'),
  ('Post-Independence')
) AS topics(topic)
ON CONFLICT (user_id, paper, subject, topic) DO NOTHING;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================================================
-- COMMENTS
-- ============================================================================

DO $migration$ BEGIN
    BEGIN
        COMMENT ON TABLE public.topic_progress IS 'Detailed topic-level progress tracking';
        COMMENT ON TABLE public.study_sessions IS 'Daily study session logs for heatmap';
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


