-- COMBINED MIGRATIONS FOR UPSC PrepX-AI
-- Run this on VPS PostgreSQL: docker exec -i supabase_db_my-project psql -U postgres -d postgres < combined_migrations.sql

-- ============================================================================
-- 001_core_schema.sql - Core database schema
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Users Table
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own data" ON public.users FOR SELECT USING (auth.uid() = id);

DROP TRIGGER IF EXISTS set_users_updated_at ON public.users;
CREATE TRIGGER set_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- User Profiles Table
CREATE TABLE IF NOT EXISTS public.user_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID UNIQUE NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  full_name TEXT,
  phone TEXT,
  avatar_url TEXT,
  role TEXT NOT NULL DEFAULT 'student' CHECK (role IN ('student', 'admin')),
  onboarding_completed BOOLEAN DEFAULT FALSE,
  preferences JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON public.user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON public.user_profiles(role);
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own profile" ON public.user_profiles FOR ALL USING (auth.uid() = user_id);

DROP TRIGGER IF EXISTS set_user_profiles_updated_at ON public.user_profiles;
CREATE TRIGGER set_user_profiles_updated_at BEFORE UPDATE ON public.user_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Plans Table
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

CREATE INDEX IF NOT EXISTS idx_plans_slug ON public.plans(slug);
CREATE INDEX IF NOT EXISTS idx_plans_active ON public.plans(is_active) WHERE is_active = true;
ALTER TABLE public.plans ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Plans are publicly readable" ON public.plans;
CREATE POLICY "Plans are publicly readable" ON public.plans FOR SELECT TO authenticated USING (is_active = true);

DROP POLICY IF EXISTS "Anonymous can view active plans" ON public.plans;
CREATE POLICY "Anonymous can view active plans" ON public.plans FOR SELECT TO anon USING (is_active = true);

-- Subscriptions Table
CREATE TABLE IF NOT EXISTS public.subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID UNIQUE NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
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

CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON public.subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON public.subscriptions(status);
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own subscription" ON public.subscriptions FOR SELECT USING (auth.uid() = user_id);

DROP TRIGGER IF EXISTS set_subscriptions_updated_at ON public.subscriptions;
CREATE TRIGGER set_subscriptions_updated_at BEFORE UPDATE ON public.subscriptions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Entitlements Table
CREATE TABLE IF NOT EXISTS public.entitlements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  feature_slug TEXT NOT NULL,
  limit_type TEXT NOT NULL CHECK (limit_type IN ('unlimited', 'daily', 'monthly', 'total')),
  limit_value INTEGER,
  usage_count INTEGER DEFAULT 0,
  last_reset_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, feature_slug)
);

CREATE INDEX IF NOT EXISTS idx_entitlements_user_feature ON public.entitlements(user_id, feature_slug);
ALTER TABLE public.entitlements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own entitlements" ON public.entitlements FOR SELECT USING (auth.uid() = user_id);

DROP TRIGGER IF EXISTS set_entitlements_updated_at ON public.entitlements;
CREATE TRIGGER set_entitlements_updated_at BEFORE UPDATE ON public.entitlements FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Audit Logs Table
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  resource_id UUID,
  metadata JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON public.audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON public.audit_logs(created_at DESC);
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Seed Plans
INSERT INTO public.plans (name, slug, price_inr, duration_days, features) VALUES
  ('Monthly Pro', 'monthly', 599, 30, '{"videos": "unlimited", "notes": "unlimited", "search": "unlimited"}'::jsonb),
  ('Quarterly Pro', 'quarterly', 1499, 90, '{"videos": "unlimited", "notes": "unlimited", "discount": "17%"}'::jsonb),
  ('Half-Yearly Pro', 'half-yearly', 2699, 180, '{"videos": "unlimited", "notes": "unlimited", "discount": "25%"}'::jsonb),
  ('Annual Pro', 'annual', 4999, 365, '{"videos": "unlimited", "notes": "unlimited", "discount": "30%"}'::jsonb)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- 002_entitlement_functions.sql
-- ============================================================================

CREATE OR REPLACE FUNCTION increment_entitlement_usage(p_user_id UUID, p_feature_slug TEXT)
RETURNS void AS $$
BEGIN
  UPDATE entitlements SET usage_count = usage_count + 1, updated_at = NOW()
  WHERE user_id = p_user_id AND feature_slug = p_feature_slug;
  IF NOT FOUND THEN
    INSERT INTO entitlements (user_id, feature_slug, limit_type, limit_value, usage_count, last_reset_at)
    VALUES (p_user_id, p_feature_slug, 'daily', 3, 1, NOW());
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION check_feature_access(p_user_id UUID, p_feature_slug TEXT)
RETURNS TABLE (allowed BOOLEAN, reason TEXT, usage_count INTEGER, limit_value INTEGER) AS $$
DECLARE
  v_subscription RECORD;
  v_entitlement RECORD;
  v_now TIMESTAMPTZ := NOW();
BEGIN
  SELECT * INTO v_subscription FROM subscriptions WHERE user_id = p_user_id;
  IF NOT FOUND THEN RETURN QUERY SELECT false, 'no_subscription'::TEXT, 0, 0; RETURN; END IF;
  IF v_subscription.status = 'trial' AND v_now < v_subscription.trial_expires_at THEN
    RETURN QUERY SELECT true, 'trial_active'::TEXT, 0, 0; RETURN;
  END IF;
  IF v_subscription.status = 'active' AND v_now < v_subscription.subscription_expires_at THEN
    RETURN QUERY SELECT true, 'subscription_active'::TEXT, 0, 0; RETURN;
  END IF;
  SELECT * INTO v_entitlement FROM entitlements WHERE user_id = p_user_id AND feature_slug = p_feature_slug;
  IF NOT FOUND THEN
    INSERT INTO entitlements (user_id, feature_slug, limit_type, limit_value, usage_count, last_reset_at)
    VALUES (p_user_id, p_feature_slug, 'daily', 3, 0, v_now);
    RETURN QUERY SELECT true, 'free_tier'::TEXT, 0, 3; RETURN;
  END IF;
  IF v_entitlement.limit_type = 'unlimited' THEN
    RETURN QUERY SELECT true, 'unlimited'::TEXT, v_entitlement.usage_count, v_entitlement.limit_value; RETURN;
  END IF;
  IF v_entitlement.usage_count < v_entitlement.limit_value THEN
    RETURN QUERY SELECT true, 'within_limit'::TEXT, v_entitlement.usage_count, v_entitlement.limit_value; RETURN;
  END IF;
  RETURN QUERY SELECT false, 'limit_reached'::TEXT, v_entitlement.usage_count, v_entitlement.limit_value;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 003_knowledge_base_tables.sql
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS vector;

-- Syllabus Nodes
CREATE TABLE IF NOT EXISTS public.syllabus_nodes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  parent_id UUID REFERENCES public.syllabus_nodes(id) ON DELETE CASCADE,
  level INTEGER NOT NULL CHECK (level BETWEEN 1 AND 5),
  path TEXT NOT NULL,
  description TEXT,
  syllabus_code TEXT,
  paper TEXT CHECK (paper IN ('GS1', 'GS2', 'GS3', 'GS4', 'CSAT', 'Essay')),
  total_content_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_syllabus_parent ON public.syllabus_nodes(parent_id);
CREATE INDEX IF NOT EXISTS idx_syllabus_slug ON public.syllabus_nodes(slug);
ALTER TABLE public.syllabus_nodes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Syllabus nodes are publicly readable" ON public.syllabus_nodes;
CREATE POLICY "Syllabus nodes are publicly readable" ON public.syllabus_nodes FOR SELECT TO anon, authenticated USING (true);

-- PDF Uploads
CREATE TABLE IF NOT EXISTS public.pdf_uploads (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  filename TEXT NOT NULL,
  storage_path TEXT UNIQUE NOT NULL,
  subject TEXT,
  book_title TEXT,
  author TEXT,
  edition TEXT,
  upload_status TEXT NOT NULL DEFAULT 'pending' CHECK (upload_status IN ('pending', 'processing', 'completed', 'failed')),
  chunks_created INTEGER DEFAULT 0,
  processing_errors TEXT,
  uploaded_by UUID REFERENCES public.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pdf_uploads_status ON public.pdf_uploads(upload_status);
ALTER TABLE public.pdf_uploads ENABLE ROW LEVEL SECURITY;

-- Knowledge Chunks with Vector
CREATE TABLE IF NOT EXISTS public.knowledge_chunks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pdf_upload_id UUID REFERENCES public.pdf_uploads(id) ON DELETE CASCADE,
  chunk_text TEXT NOT NULL,
  content_vector vector(1536),
  source_page INTEGER,
  chunk_index INTEGER,
  syllabus_node_ids UUID[] NOT NULL DEFAULT '{}',
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_knowledge_chunks_pdf ON public.knowledge_chunks(pdf_upload_id);
ALTER TABLE public.knowledge_chunks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Knowledge chunks are publicly readable" ON public.knowledge_chunks;
CREATE POLICY "Knowledge chunks are publicly readable" ON public.knowledge_chunks FOR SELECT TO anon, authenticated USING (true);

-- Comprehensive Notes
CREATE TABLE IF NOT EXISTS public.comprehensive_notes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  topic TEXT NOT NULL,
  syllabus_node_id UUID REFERENCES public.syllabus_nodes(id),
  summary TEXT,
  detailed_content TEXT,
  comprehensive_content TEXT,
  key_facts JSONB DEFAULT '[]',
  sources TEXT[] DEFAULT '{}',
  manim_diagram_url TEXT,
  video_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.comprehensive_notes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Notes are publicly readable" ON public.comprehensive_notes;
CREATE POLICY "Notes are publicly readable" ON public.comprehensive_notes FOR SELECT TO anon, authenticated USING (true);

-- Daily Updates
CREATE TABLE IF NOT EXISTS public.daily_updates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  date DATE NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('national', 'international', 'economy', 'environment', 'science', 'polity', 'security')),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  source_url TEXT,
  importance TEXT CHECK (importance IN ('low', 'medium', 'high', 'critical')),
  syllabus_mappings UUID[] DEFAULT '{}',
  video_url TEXT,
  pdf_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_daily_updates_date ON public.daily_updates(date DESC);
ALTER TABLE public.daily_updates ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Daily updates are publicly readable" ON public.daily_updates;
CREATE POLICY "Daily updates are publicly readable" ON public.daily_updates FOR SELECT TO anon, authenticated USING (true);

-- Seed Syllabus Taxonomy
INSERT INTO public.syllabus_nodes (name, slug, parent_id, level, path, syllabus_code, paper) VALUES
  ('General Studies Paper 1', 'gs1', NULL, 1, '/gs1', 'GS1', 'GS1'),
  ('General Studies Paper 2', 'gs2', NULL, 1, '/gs2', 'GS2', 'GS2'),
  ('General Studies Paper 3', 'gs3', NULL, 1, '/gs3', 'GS3', 'GS3'),
  ('General Studies Paper 4', 'gs4', NULL, 1, '/gs4', 'GS4', 'GS4'),
  ('CSAT (Paper 2)', 'csat', NULL, 1, '/csat', 'CSAT', 'CSAT'),
  ('Essay Paper', 'essay', NULL, 1, '/essay', 'ESSAY', 'Essay')
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- 009_video_jobs.sql
-- ============================================================================

CREATE TABLE IF NOT EXISTS job_queue_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  max_concurrent_renders INTEGER DEFAULT 10,
  max_manim_renders INTEGER DEFAULT 4,
  job_timeout_minutes INTEGER DEFAULT 10,
  retry_interval_minutes INTEGER DEFAULT 5,
  peak_hour_start TIME DEFAULT '06:00',
  peak_hour_end TIME DEFAULT '21:00',
  peak_worker_multiplier DECIMAL DEFAULT 1.5,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_type TEXT NOT NULL CHECK (job_type IN ('doubt', 'topic_short', 'daily_ca')),
  priority TEXT NOT NULL CHECK (priority IN ('high', 'medium', 'low')),
  status TEXT NOT NULL DEFAULT 'queued' CHECK (status IN ('queued', 'processing', 'completed', 'failed', 'cancelled')),
  payload JSONB NOT NULL,
  queue_position INTEGER,
  retry_count INTEGER DEFAULT 0,
  max_retries INTEGER DEFAULT 3,
  error_message TEXT,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_jobs_status ON jobs(status);
CREATE INDEX IF NOT EXISTS idx_jobs_priority ON jobs(priority);
CREATE INDEX IF NOT EXISTS idx_jobs_user_id ON jobs(user_id);

INSERT INTO job_queue_config (id) VALUES (gen_random_uuid()) ON CONFLICT DO NOTHING;

CREATE OR REPLACE FUNCTION update_queue_positions()
RETURNS TRIGGER AS $$
BEGIN
  WITH ranked_jobs AS (
    SELECT id, ROW_NUMBER() OVER (
      ORDER BY CASE priority WHEN 'high' THEN 1 WHEN 'medium' THEN 2 WHEN 'low' THEN 3 END, created_at ASC
    ) as new_position
    FROM jobs WHERE status = 'queued'
  )
  UPDATE jobs SET queue_position = ranked_jobs.new_position FROM ranked_jobs WHERE jobs.id = ranked_jobs.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_queue_positions ON jobs;
CREATE TRIGGER trigger_update_queue_positions AFTER INSERT OR UPDATE OF status, priority ON jobs
FOR EACH STATEMENT EXECUTE FUNCTION update_queue_positions();

CREATE OR REPLACE FUNCTION get_queue_stats()
RETURNS TABLE (
  total_queued BIGINT, total_processing BIGINT, total_completed_today BIGINT, total_failed_today BIGINT,
  avg_wait_time_minutes NUMERIC, high_priority_count BIGINT, medium_priority_count BIGINT, low_priority_count BIGINT
) AS $$
BEGIN
  RETURN QUERY SELECT
    COUNT(*) FILTER (WHERE status = 'queued'),
    COUNT(*) FILTER (WHERE status = 'processing'),
    COUNT(*) FILTER (WHERE status = 'completed' AND completed_at >= CURRENT_DATE),
    COUNT(*) FILTER (WHERE status = 'failed' AND updated_at >= CURRENT_DATE),
    AVG(EXTRACT(EPOCH FROM (COALESCE(started_at, NOW()) - created_at)) / 60) FILTER (WHERE status IN ('processing', 'completed')),
    COUNT(*) FILTER (WHERE status = 'queued' AND priority = 'high'),
    COUNT(*) FILTER (WHERE status = 'queued' AND priority = 'medium'),
    COUNT(*) FILTER (WHERE status = 'queued' AND priority = 'low')
  FROM jobs;
END;
$$ LANGUAGE plpgsql;

-- Calculate word count function
CREATE OR REPLACE FUNCTION calculate_word_count(text_value TEXT)
RETURNS INTEGER AS $$
BEGIN
  RETURN array_length(string_to_array(text_value, ' '), 1);
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- DONE
-- ============================================================================
SELECT 'All migrations applied successfully!' as result;
