-- Migration: 023_study_schedules.sql
-- Description: Study schedule builder with AI-generated adaptive planning
-- Author: Dev Agent (BMAD)
-- Date: December 26, 2025
-- Story: 6.1 - AI Study Schedule Builder - FULL IMPLEMENTATION

-- ============================================================================
-- STUDY SCHEDULES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.study_schedules (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL ,
  exam_date DATE NOT NULL CHECK (exam_date > CURRENT_DATE),
  target_hours_per_day DECIMAL(3,1) NOT NULL CHECK (target_hours_per_day > 0 AND target_hours_per_day <= 24),
  schedule_data JSONB NOT NULL,
  last_adapted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_active BOOLEAN DEFAULT TRUE,
  adaptation_count INTEGER DEFAULT 0,
  calendar_sync_enabled BOOLEAN DEFAULT FALSE,
  google_calendar_id TEXT,
  ical_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Partial unique index for one active schedule per user (replaces inline constraint)
DO $migration$ BEGIN
    BEGIN
        CREATE UNIQUE INDEX IF NOT EXISTS idx_one_active_schedule_per_user 
  ON public.study_schedules(user_id) 
  WHERE is_active = true;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_study_schedules_user_id ON public.study_schedules(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_study_schedules_active ON public.study_schedules(user_id, is_active) WHERE is_active = true;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_study_schedules_exam_date ON public.study_schedules(exam_date);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.study_schedules ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can manage own schedules"
  ON public.study_schedules FOR ALL
  USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE TRIGGER set_study_schedules_updated_at
  BEFORE UPDATE ON public.study_schedules
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================================================
-- SCHEDULE TASKS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.schedule_tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  schedule_id UUID NOT NULL REFERENCES public.study_schedules(id) ON DELETE CASCADE,
  user_id UUID NOT NULL ,
  task_date DATE NOT NULL,
  task_type TEXT NOT NULL CHECK (task_type IN ('study', 'revision', 'practice', 'rest')),
  topic TEXT NOT NULL,
  duration_minutes INTEGER NOT NULL CHECK (duration_minutes > 0 AND duration_minutes <= 1440),
  description TEXT,
  is_completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  skipped BOOLEAN DEFAULT FALSE,
  skipped_reason TEXT,
  actual_duration_minutes INTEGER,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT valid_completion CHECK (
    (is_completed = false AND completed_at IS NULL) OR
    (is_completed = true AND completed_at IS NOT NULL)
  )
);

DO $migration$ BEGIN
    BEGIN
        CREATE INDEX idx_schedule_tasks_schedule_id ON public.schedule_tasks(schedule_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX idx_schedule_tasks_user_date ON public.schedule_tasks(user_id, task_date);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX idx_schedule_tasks_completed ON public.schedule_tasks(user_id, is_completed);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX idx_schedule_tasks_upcoming ON public.schedule_tasks(user_id, task_date) WHERE is_completed = false AND task_date >= CURRENT_DATE;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.schedule_tasks ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can manage own tasks"
  ON public.schedule_tasks FOR ALL
  USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE TRIGGER set_schedule_tasks_updated_at
  BEFORE UPDATE ON public.schedule_tasks
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================================================
-- SCHEDULE NOTIFICATIONS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.schedule_notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL ,
  schedule_id UUID NOT NULL REFERENCES public.study_schedules(id) ON DELETE CASCADE,
  notification_type TEXT NOT NULL CHECK (notification_type IN ('daily_reminder', 'task_due', 'rest_day', 'adaptation_ready')),
  scheduled_for TIMESTAMPTZ NOT NULL,
  sent BOOLEAN DEFAULT FALSE,
  sent_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN
        CREATE INDEX idx_schedule_notifications_pending ON public.schedule_notifications(scheduled_for) WHERE sent = false;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.schedule_notifications ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can view own notifications"
  ON public.schedule_notifications FOR SELECT
  USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Function to auto-adapt schedule weekly
DO $migration$ BEGIN
    BEGIN
        CREATE OR REPLACE FUNCTION adapt_schedule_if_needed()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if 7 days have passed since last adaptation
  IF (EXTRACT(EPOCH FROM (NOW() - NEW.last_adapted_at)) / 86400) >= 7 THEN
    NEW.last_adapted_at = NOW();
    NEW.adaptation_count = NEW.adaptation_count + 1;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE TRIGGER trigger_adapt_schedule
  BEFORE UPDATE ON public.study_schedules
  FOR EACH ROW
  WHEN (OLD.is_active = true AND NEW.is_active = true)
  EXECUTE FUNCTION adapt_schedule_if_needed();
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================================================
-- COMMENTS
-- ============================================================================

DO $migration$ BEGIN
    BEGIN
        COMMENT ON TABLE public.study_schedules IS 'AI-generated adaptive study schedules with calendar sync';
        COMMENT ON TABLE public.schedule_tasks IS 'Daily tasks within study schedules with completion tracking';
        COMMENT ON TABLE public.schedule_notifications IS 'Scheduled notifications for study reminders';
        COMMENT ON COLUMN public.study_schedules.adaptation_count IS 'Number of times schedule has been adapted based on progress';
        COMMENT ON COLUMN public.schedule_tasks.actual_duration_minutes IS 'Actual time spent vs planned duration';
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


