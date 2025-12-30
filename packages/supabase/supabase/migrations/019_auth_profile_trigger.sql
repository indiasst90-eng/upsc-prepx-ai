-- Migration: 019_auth_profile_trigger.sql
-- Description: Automatic user profile creation trigger on auth.users INSERT
-- Author: Dev Agent James (Story 1.2 - Task 6)
-- Date: December 26, 2025

-- Create function to handle new user profile creation
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  trial_duration_days INT := 7;
BEGIN
  -- Insert into public.users table first
  INSERT INTO public.users (id, email, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.email,
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO NOTHING;

  -- Create user profile with trial subscription
  INSERT INTO public.user_profiles (
    user_id,
    full_name,
    avatar_url,
    role,
    onboarding_completed,
    preferences
  )
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    NEW.raw_user_meta_data->>'avatar_url',
    'student',
    FALSE,
    '{}'::jsonb
  )
  ON CONFLICT (user_id) DO NOTHING;

  -- Create subscription record with 7-day trial
  INSERT INTO public.subscriptions (
    user_id,
    status,
    trial_started_at,
    trial_expires_at
  )
  VALUES (
    NEW.id,
    'trial',
    NOW(),
    NOW() + (trial_duration_days || ' days')::INTERVAL
  )
  ON CONFLICT (user_id) DO NOTHING;

  -- Create default entitlements for trial user (unlimited access during trial)
  INSERT INTO public.entitlements (user_id, feature_slug, limit_type, limit_value, usage_count)
  VALUES
    (NEW.id, 'doubt_video_converter', 'unlimited', NULL, 0),
    (NEW.id, 'daily_ca_video', 'unlimited', NULL, 0),
    (NEW.id, 'notes_generation', 'unlimited', NULL, 0),
    (NEW.id, 'pyq_solutions', 'unlimited', NULL, 0),
    (NEW.id, 'answer_evaluation', 'unlimited', NULL, 0)
  ON CONFLICT (user_id, feature_slug) DO NOTHING;

  -- Log the user creation in audit_logs
  INSERT INTO public.audit_logs (
    user_id,
    action,
    resource_type,
    resource_id,
    details
  )
  VALUES (
    NEW.id,
    'user_registered',
    'user',
    NEW.id::TEXT,
    jsonb_build_object(
      'email', NEW.email,
      'provider', COALESCE(NEW.raw_app_meta_data->>'provider', 'email'),
      'trial_expires_at', NOW() + (trial_duration_days || ' days')::INTERVAL
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DO $migration$ BEGIN
    BEGIN
        -- Create trigger on auth.users table
        DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
        CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO authenticated;
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO service_role;

COMMENT ON FUNCTION public.handle_new_user() IS 'Automatically creates user profile, subscription (7-day trial), and entitlements when a new user signs up';


