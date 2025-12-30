-- Migration: 030_notification_preferences.sql
-- Story: 6.9 - Revision Bundle Push Notifications

CREATE TABLE IF NOT EXISTS public.notification_preferences (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL ,
  notification_type TEXT NOT NULL CHECK (notification_type IN ('weekly_targets', 'daily_reminder', 'flashcard_review', 'quiz_available')),
  enabled BOOLEAN DEFAULT TRUE,
  preferred_time TIME DEFAULT '09:00:00',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, notification_type)
);

DO $migration$ BEGIN
    BEGIN
        CREATE INDEX idx_notification_preferences_user ON public.notification_preferences(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can manage own notification preferences"
  ON public.notification_preferences FOR ALL
  USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE TRIGGER set_notification_preferences_updated_at
  BEFORE UPDATE ON public.notification_preferences
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        COMMENT ON TABLE public.notification_preferences IS 'User notification preferences';
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


