-- Migration: 001_core_schema.sql
-- Description: Core database schema for users, profiles, subscriptions, and entitlements
-- Author: Dev Agent (BMAD)
-- Date: December 25, 2025
-- Story: 1.3 - Database Schema - Core Tables

-- ============================================================================
-- EXTENSIONS
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- TIMESTAMP TRIGGER FUNCTION
-- ============================================================================

DO $migration$ BEGIN
    BEGIN
        CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

-- ============================================================================
-- CORE TABLES
-- ============================================================================

-- 1. Users Table (extends auth.users)
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY ,
  email TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can view own data"
  ON public.users FOR SELECT
  USING (auth.uid() = id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE TRIGGER set_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

-- 2. User Profiles Table
CREATE TABLE IF NOT EXISTS public.user_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID UNIQUE NOT NULL ,
  full_name TEXT,
  phone TEXT,
  avatar_url TEXT,
  role TEXT NOT NULL DEFAULT 'student' CHECK (role IN ('student', 'admin')),
  onboarding_completed BOOLEAN DEFAULT FALSE,
  preferences JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON public.user_profiles(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON public.user_profiles(role);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can manage own profile"
  ON public.user_profiles FOR ALL
  USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE TRIGGER set_user_profiles_updated_at
  BEFORE UPDATE ON public.user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

-- 3. Plans Table
CREATE TABLE IF NOT EXISTS public.plans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT UNIQUE NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  price_inr INTEGER NOT NULL,
  duration_days INTEGER NOT NULL,
  features JSONB NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_plans_slug ON public.plans(slug);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_plans_active ON public.plans(is_active) WHERE is_active = true;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.plans ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Plans are publicly readable"
  ON public.plans FOR SELECT
  TO authenticated
  USING (is_active = true);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Anonymous can view active plans"
  ON public.plans FOR SELECT
  TO anon
  USING (is_active = true);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

-- 4. Subscriptions Table
CREATE TABLE IF NOT EXISTS public.subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID UNIQUE NOT NULL ,
  plan_id UUID REFERENCES public.plans(id),
  status TEXT NOT NULL CHECK (status IN ('trial', 'active', 'canceled', 'expired', 'paused')),
  trial_started_at TIMESTAMPTZ,
  trial_expires_at TIMESTAMPTZ,
  subscription_started_at TIMESTAMPTZ,
  subscription_expires_at TIMESTAMPTZ,
  auto_renew BOOLEAN DEFAULT TRUE,
  canceled_at TIMESTAMPTZ,
  revenuecat_subscription_id TEXT UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON public.subscriptions(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON public.subscriptions(status);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_subscriptions_trial_expires_at ON public.subscriptions(trial_expires_at);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_subscriptions_subscription_expires_at ON public.subscriptions(subscription_expires_at);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can view own subscription"
  ON public.subscriptions FOR SELECT
  USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE TRIGGER set_subscriptions_updated_at
  BEFORE UPDATE ON public.subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

-- 5. Entitlements Table
CREATE TABLE IF NOT EXISTS public.entitlements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL ,
  feature_slug TEXT NOT NULL,
  limit_type TEXT NOT NULL CHECK (limit_type IN ('unlimited', 'daily', 'monthly', 'total')),
  limit_value INTEGER,
  usage_count INTEGER DEFAULT 0,
  last_reset_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, feature_slug),
  CHECK (usage_count <= limit_value OR limit_value IS NULL)
);

DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_entitlements_user_feature ON public.entitlements(user_id, feature_slug);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_entitlements_user_id ON public.entitlements(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.entitlements ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can view own entitlements"
  ON public.entitlements FOR SELECT
  USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE TRIGGER set_entitlements_updated_at
  BEFORE UPDATE ON public.entitlements
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

-- 6. Audit Logs Table
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID ,
  action TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  resource_id UUID,
  metadata JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON public.audit_logs(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON public.audit_logs(action);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON public.audit_logs(created_at DESC);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_audit_logs_resource ON public.audit_logs(resource_type, resource_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Only admins can view audit logs"
  ON public.audit_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

-- ============================================================================
-- SEED DATA - SUBSCRIPTION PLANS
-- ============================================================================

INSERT INTO public.plans (name, slug, price_inr, duration_days, features) VALUES
  (
    'Monthly Pro',
    'monthly',
    599,
    30,
    '{
      "videos": "unlimited",
      "notes": "unlimited",
      "search": "unlimited",
      "doubt_videos": "unlimited",
      "ai_tutor": true,
      "test_series": true,
      "pyq_database": true
    }'::jsonb
  ),
  (
    'Quarterly Pro',
    'quarterly',
    1499,
    90,
    '{
      "videos": "unlimited",
      "notes": "unlimited",
      "search": "unlimited",
      "doubt_videos": "unlimited",
      "ai_tutor": true,
      "test_series": true,
      "pyq_database": true,
      "discount": "17%"
    }'::jsonb
  ),
  (
    'Half-Yearly Pro',
    'half-yearly',
    2699,
    180,
    '{
      "videos": "unlimited",
      "notes": "unlimited",
      "search": "unlimited",
      "doubt_videos": "unlimited",
      "ai_tutor": true,
      "test_series": true,
      "pyq_database": true,
      "discount": "25%"
    }'::jsonb
  ),
  (
    'Annual Pro',
    'annual',
    4999,
    365,
    '{
      "videos": "unlimited",
      "notes": "unlimited",
      "search": "unlimited",
      "doubt_videos": "unlimited",
      "ai_tutor": true,
      "test_series": true,
      "pyq_database": true,
      "discount": "30%",
      "priority_support": true
    }'::jsonb
  )
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- FUNCTIONS FOR TRIAL MANAGEMENT
-- ============================================================================

-- Function to create trial subscription on user signup
CREATE OR REPLACE FUNCTION create_trial_subscription()
RETURNS TRIGGER AS $$
BEGIN
  -- Create user record in public.users
  INSERT INTO public.users (id, email)
  VALUES (NEW.id, NEW.email)
  ON CONFLICT (id) DO NOTHING;

  -- Create user profile
  INSERT INTO public.user_profiles (user_id, full_name)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'name')
  ON CONFLICT (user_id) DO NOTHING;

  -- Create trial subscription
  INSERT INTO public.subscriptions (
    user_id,
    status,
    trial_started_at,
    trial_expires_at
  ) VALUES (
    NEW.id,
    'trial',
    NOW(),
    NOW() + INTERVAL '7 days'
  )
  ON CONFLICT (user_id) DO NOTHING;

  -- Create default entitlements for trial
  INSERT INTO public.entitlements (user_id, feature_slug, limit_type, limit_value) VALUES
    (NEW.id, 'doubt_videos', 'unlimited', NULL),
    (NEW.id, 'notes_generation', 'unlimited', NULL),
    (NEW.id, 'rag_search', 'unlimited', NULL),
    (NEW.id, 'test_series', 'unlimited', NULL),
    (NEW.id, 'pyq_database', 'unlimited', NULL)
  ON CONFLICT (user_id, feature_slug) DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger on auth.users table for automatic trial creation

DO $migration$ BEGIN
    BEGIN
        CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION create_trial_subscription();
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

-- ============================================================================
-- TEST DATA (Development Only)
-- ============================================================================

-- Note: Test users will be created through Supabase Auth UI or API
-- This section documents test credentials for development

COMMENT ON TABLE public.users IS 'Core user table extending auth.users';
COMMENT ON TABLE public.user_profiles IS 'User profile data and preferences';
COMMENT ON TABLE public.plans IS 'Subscription plan definitions';
COMMENT ON TABLE public.subscriptions IS 'User subscription records';
COMMENT ON TABLE public.entitlements IS 'Feature access limits per user';
COMMENT ON TABLE public.audit_logs IS 'System audit trail for compliance';



