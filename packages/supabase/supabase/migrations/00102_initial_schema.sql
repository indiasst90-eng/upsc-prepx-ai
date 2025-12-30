-- UPSC PrepX-AI Database Schema
-- Version: 1.0
-- Created: December 2025
-- Purpose: Core database tables for the UPSC preparation platform

-- Clean up any existing tables to ensure fresh start
DROP TABLE IF EXISTS public.model_answers CASCADE;
DROP TABLE IF EXISTS public.pyq_bank CASCADE;
DROP TABLE IF EXISTS public.daily_updates CASCADE;
DROP TABLE IF EXISTS public.queue_config CASCADE;
DROP TABLE IF EXISTS public.jobs CASCADE;
DROP TABLE IF EXISTS public.video_renders CASCADE;
DROP TABLE IF EXISTS public.comprehensive_notes CASCADE;
DROP TABLE IF EXISTS public.knowledge_chunks CASCADE;
DROP TABLE IF EXISTS public.pdf_uploads CASCADE;
DROP TABLE IF EXISTS public.syllabus_progress CASCADE;
DROP TABLE IF EXISTS public.syllabus_nodes CASCADE;
DROP TABLE IF EXISTS public.entitlements CASCADE;
DROP TABLE IF EXISTS public.subscriptions CASCADE;
DROP TABLE IF EXISTS public.plans CASCADE;
DROP TABLE IF EXISTS public.user_profiles CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
-- Note: In Supabase, the extension is called 'vector' not 'pgvector'
CREATE EXTENSION IF NOT EXISTS vector;

-- ============================================
-- USER MANAGEMENT
-- ============================================

-- Users table (extends Supabase auth.users)
-- Note: In Supabase, auth.users already exists. We link to it.
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    avatar_url TEXT,
    phone TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add foreign key to auth.users if it exists (Supabase environment)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'users') THEN
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.table_constraints 
            WHERE constraint_name = 'users_id_fkey' AND table_name = 'users'
        ) THEN
            ALTER TABLE public.users 
            ADD CONSTRAINT users_id_fkey 
            FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
        END IF;
    END IF;
EXCEPTION WHEN others THEN
    RAISE NOTICE 'Could not add auth.users foreign key: %', SQLERRM;
END $$;

-- User profiles
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL ,
    bio TEXT,
    target_year INTEGER CHECK (target_year >= 2024),
    preferred_language TEXT DEFAULT 'en',
    timezone TEXT DEFAULT 'Asia/Kolkata',
    notification_settings JSONB DEFAULT '{
        "email": true,
        "push": true,
        "daily_brief": true,
        "doubt_reminders": true
    }',
    learning_stats JSONB DEFAULT '{
        "total_videos_watched": 0,
        "total_notes_generated": 0,
        "total_questions_practiced": 0,
        "streak_days": 0,
        "last_activity_date": null
    }',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

-- ============================================
-- SUBSCRIPTIONS & ENTITLEMENTS
-- ============================================

-- Subscription plans
CREATE TABLE IF NOT EXISTS public.plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    code TEXT UNIQUE NOT NULL,
    price_monthly INTEGER NOT NULL,
    price_quarterly INTEGER,
    price_half_yearly INTEGER,
    price_annually INTEGER,
    features JSONB NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User subscriptions
CREATE TABLE IF NOT EXISTS public.subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL ,
    plan_id UUID NOT NULL REFERENCES public.plans(id),
    revenuecat_id TEXT UNIQUE,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expired', 'cancelled', 'paused', 'trial')),
    trial_ends_at TIMESTAMPTZ,
    current_period_start TIMESTAMPTZ,
    current_period_end TIMESTAMPTZ,
    cancel_at_period_end BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Feature entitlements
CREATE TABLE IF NOT EXISTS public.entitlements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL ,
    feature_code TEXT NOT NULL,
    daily_limit INTEGER,
    monthly_limit INTEGER,
    used_count INTEGER DEFAULT 0,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, feature_code)
);

-- ============================================
-- SYLLABUS
-- ============================================

-- UPSC Syllabus nodes
CREATE TABLE IF NOT EXISTS public.syllabus_nodes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    paper TEXT NOT NULL CHECK (paper IN ('GS1', 'GS2', 'GS3', 'GS4', 'Essay', 'CSAT')),
    topic TEXT,
    parent_id UUID REFERENCES public.syllabus_nodes(id),
    description TEXT,
    weight INTEGER DEFAULT 1,
    previous_year_questions JSONB DEFAULT '[]',
    is_mandatory BOOLEAN DEFAULT true,
    depth INTEGER DEFAULT 0,
    path TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User syllabus progress
CREATE TABLE IF NOT EXISTS public.syllabus_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL ,
    node_id UUID NOT NULL REFERENCES public.syllabus_nodes(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'not_started' CHECK (status IN ('not_started', 'in_progress', 'completed', 'revision_due')),
    confidence_level INTEGER CHECK (confidence_level >= 0 AND confidence_level <= 100),
    time_spent_minutes INTEGER DEFAULT 0,
    revision_count INTEGER DEFAULT 0,
    last_studied_at TIMESTAMPTZ,
    next_revision_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, node_id)
);

-- ============================================
-- KNOWLEDGE BASE (RAG)
-- ============================================

-- PDF uploads
CREATE TABLE IF NOT EXISTS public.pdf_uploads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID ,
    title TEXT NOT NULL,
    source TEXT NOT NULL,
    author TEXT,
    topic TEXT NOT NULL,
    file_size_bytes BIGINT,
    page_count INTEGER,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'indexed', 'failed')),
    error_message TEXT,
    uploaded_at TIMESTAMPTZ DEFAULT NOW(),
    processed_at TIMESTAMPTZ
);

-- Knowledge chunks (vector embeddings)
CREATE TABLE IF NOT EXISTS public.knowledge_chunks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pdf_upload_id UUID NOT NULL REFERENCES public.pdf_uploads(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    embedding vector(1536),
    metadata JSONB DEFAULT '{}',
    page_number INTEGER,
    chunk_index INTEGER,
    token_count INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create HNSW index for vector search (works on empty tables, unlike IVFFlat)
-- HNSW provides faster queries with slightly more memory usage
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_knowledge_chunks_embedding') THEN
        DO $migration$ BEGIN
    BEGIN
        CREATE INDEX idx_knowledge_chunks_embedding
        ON public.knowledge_chunks
        USING hnsw (embedding vector_cosine_ops);
    END IF;
EXCEPTION WHEN undefined_column THEN
    RAISE NOTICE 'embedding column not yet available, skipping index';
END $$;

-- ============================================
-- NOTES
-- ============================================

-- Comprehensive notes
CREATE TABLE IF NOT EXISTS public.comprehensive_notes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL ,
    title TEXT NOT NULL,
    topic TEXT NOT NULL,
    level TEXT NOT NULL CHECK (level IN ('basic', 'intermediate', 'advanced')),
    content JSONB NOT NULL,
    sections JSONB DEFAULT '[]',
    diagrams JSONB DEFAULT '[]',
    key_takeaways JSONB DEFAULT '[]',
    source_chunks UUID[] DEFAULT '{}',
    word_count INTEGER,
    reading_time_minutes INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- VIDEO RENDERS
-- ============================================

-- Video render jobs
CREATE TABLE IF NOT EXISTS public.video_renders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL ,
    type TEXT NOT NULL CHECK (type IN ('daily_news', 'doubt_explainer', 'notes_summary', 'documentary', 'pyq_explanation')),
    title TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'queued' CHECK (status IN ('queued', 'processing', 'completed', 'failed', 'cancelled')),
    priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
    progress INTEGER DEFAULT 0 CHECK (progress >= 0 AND progress <= 100),
    input_params JSONB DEFAULT '{}',
    output_url TEXT,
    thumbnail_url TEXT,
    duration_seconds INTEGER,
    error_message TEXT,
    queued_at TIMESTAMPTZ DEFAULT NOW(),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    retry_count INTEGER DEFAULT 0
);

-- ============================================
-- JOBS & QUEUE (Story 4.10)
-- ============================================

-- Job queue
CREATE TABLE IF NOT EXISTS public.jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL ,
    job_type TEXT NOT NULL CHECK (job_type IN ('video_render', 'notes_generation', 'pdf_processing', 'embedding_update')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'failed', 'cancelled')),
    priority INTEGER NOT NULL DEFAULT 5 CHECK (priority >= 1 AND priority <= 10),
    payload JSONB DEFAULT '{}',
    result JSONB DEFAULT '{}',
    error_message TEXT,
    progress INTEGER DEFAULT 0 CHECK (progress >= 0 AND progress <= 100),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Queue configuration
CREATE TABLE IF NOT EXISTS public.queue_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_type TEXT UNIQUE NOT NULL,
    max_concurrent INTEGER DEFAULT 5,
    timeout_minutes INTEGER DEFAULT 30,
    retry_limit INTEGER DEFAULT 3,
    is_enabled BOOLEAN DEFAULT true,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- DAILY UPDATES
-- ============================================

-- Daily current affairs
CREATE TABLE IF NOT EXISTS public.daily_updates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date DATE NOT NULL UNIQUE,
    title TEXT NOT NULL,
    summary TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('polity', 'economy', 'international', 'science_tech', 'environment', 'social', 'security')),
    source TEXT NOT NULL,
    relevance_score INTEGER DEFAULT 5 CHECK (relevance_score >= 1 AND relevance_score <= 10),
    video_script TEXT,
    video_status TEXT DEFAULT 'pending' CHECK (video_status IN ('pending', 'queued', 'processing', 'completed', 'failed')),
    video_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- PYQ (Previous Year Questions)
-- ============================================

-- PYQ bank
CREATE TABLE IF NOT EXISTS public.pyq_bank (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    year INTEGER NOT NULL CHECK (year >= 2013),
    paper TEXT NOT NULL CHECK (paper IN ('GS1', 'GS2', 'GS3', 'GS4', 'Essay', 'CSAT')),
    question_number INTEGER NOT NULL,
    question_text TEXT NOT NULL,
    optional_question BOOLEAN DEFAULT false,
    max_marks INTEGER DEFAULT 10,
    keywords TEXT[] DEFAULT '{}',
    difficulty TEXT DEFAULT 'medium' CHECK (difficulty IN ('easy', 'medium', 'hard')),
    topic_codes TEXT[] DEFAULT '{}',
    answer_template TEXT,
    video_explanation_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(year, paper, question_number)
);

-- Model answers
CREATE TABLE IF NOT EXISTS public.model_answers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pyq_id UUID NOT NULL REFERENCES public.pyq_bank(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    score INTEGER,
    key_points TEXT[] DEFAULT '{}',
    structure_analysis TEXT,
    language_quality TEXT,
    created_by TEXT,
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- PRACTICE & TESTS
-- ============================================

-- Practice sessions
CREATE TABLE IF NOT EXISTS public.practice_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL ,
    type TEXT NOT NULL CHECK (type IN ('pyq', 'mock', 'topic_quiz', 'flashcard')),
    topic_codes TEXT[] DEFAULT '{}',
    status TEXT NOT NULL DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed', 'abandoned')),
    score INTEGER,
    total_questions INTEGER,
    correct_answers INTEGER,
    time_spent_seconds INTEGER,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

-- Practice answers
CREATE TABLE IF NOT EXISTS public.practice_answers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES public.practice_sessions(id) ON DELETE CASCADE,
    question_id TEXT NOT NULL,
    question_type TEXT NOT NULL CHECK (question_type IN ('mcq', 'subjective', 'true_false')),
    user_answer TEXT,
    is_correct BOOLEAN,
    time_spent_seconds INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- ANSWER WRITING
-- ============================================

-- Answer submissions
CREATE TABLE IF NOT EXISTS public.answer_submissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL ,
    question_id UUID REFERENCES public.pyq_bank(id),
    custom_question TEXT,
    content TEXT NOT NULL,
    word_count INTEGER,
    status TEXT NOT NULL DEFAULT 'submitted' CHECK (status IN ('submitted', 'evaluated', 'revision_requested')),
    ai_score INTEGER CHECK (ai_score >= 0 AND ai_score <= 100),
    ai_feedback TEXT,
    human_feedback TEXT,
    submitted_at TIMESTAMPTZ DEFAULT NOW(),
    evaluated_at TIMESTAMPTZ
);

-- ============================================
-- BOOKMARKS & COLLECTIONS
-- ============================================

-- User bookmarks
CREATE TABLE IF NOT EXISTS public.bookmarks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL ,
    title TEXT NOT NULL,
    description TEXT,
    resource_type TEXT NOT NULL CHECK (resource_type IN ('notes', 'video', 'pyq', 'article', 'custom')),
    resource_id TEXT,
    content TEXT,
    tags TEXT[] DEFAULT '{}',
    collection_id UUID,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Bookmark collections
CREATE TABLE IF NOT EXISTS public.bookmark_collections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL ,
    name TEXT NOT NULL,
    description TEXT,
    color TEXT DEFAULT '#00f3ff',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- RLS POLICIES
-- ============================================

-- Enable RLS on all user tables
DO $$ BEGIN
    ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'Skipping RLS enablement for public.users due to insufficient privileges';
END $$;
DO $$ BEGIN
    ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'Skipping RLS enablement for public.user_profiles due to insufficient privileges';
END $$;
DO $$ BEGIN
    ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'Skipping RLS enablement for public.subscriptions due to insufficient privileges';
END $$;
DO $$ BEGIN
    ALTER TABLE public.entitlements ENABLE ROW LEVEL SECURITY;
EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'Skipping RLS enablement for public.entitlements due to insufficient privileges';
END $$;
DO $$ BEGIN
    ALTER TABLE public.syllabus_progress ENABLE ROW LEVEL SECURITY;
EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'Skipping RLS enablement for public.syllabus_progress due to insufficient privileges';
END $$;
DO $$ BEGIN
    ALTER TABLE public.comprehensive_notes ENABLE ROW LEVEL SECURITY;
EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'Skipping RLS enablement for public.comprehensive_notes due to insufficient privileges';
END $$;
DO $$ BEGIN
    ALTER TABLE public.video_renders ENABLE ROW LEVEL SECURITY;
EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'Skipping RLS enablement for public.video_renders due to insufficient privileges';
END $$;
DO $$ BEGIN
    ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'Skipping RLS enablement for public.jobs due to insufficient privileges';
END $$;
DO $$ BEGIN
    ALTER TABLE public.practice_sessions ENABLE ROW LEVEL SECURITY;
EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'Skipping RLS enablement for public.practice_sessions due to insufficient privileges';
END $$;
DO $$ BEGIN
    ALTER TABLE public.answer_submissions ENABLE ROW LEVEL SECURITY;
EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'Skipping RLS enablement for public.answer_submissions due to insufficient privileges';
END $$;
DO $$ BEGIN
    ALTER TABLE public.bookmarks ENABLE ROW LEVEL SECURITY;
EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'Skipping RLS enablement for public.bookmarks due to insufficient privileges';
END $$;
DO $$ BEGIN
    ALTER TABLE public.bookmark_collections ENABLE ROW LEVEL SECURITY;
EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'Skipping RLS enablement for public.bookmark_collections due to insufficient privileges';
END $$;

-- Policies: Users can only access their own data
DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can access own profile" ON public.users FOR SELECT USING (auth.uid() = id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (auth.uid() = id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can access own user_profiles" ON public.user_profiles FOR ALL USING (user_id = auth.uid());
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can access own subscriptions" ON public.subscriptions FOR SELECT USING (user_id = auth.uid());
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "System can manage subscriptions" ON public.subscriptions FOR ALL USING (auth.role() = 'service_role');
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can access own entitlements" ON public.entitlements FOR SELECT USING (user_id = auth.uid());
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can access own syllabus progress" ON public.syllabus_progress FOR ALL USING (user_id = auth.uid());
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can access own notes" ON public.comprehensive_notes FOR ALL USING (user_id = auth.uid());
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can access own video renders" ON public.video_renders FOR ALL USING (user_id = auth.uid());
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can access own jobs" ON public.jobs FOR ALL USING (user_id = auth.uid());
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can access own practice sessions" ON public.practice_sessions FOR ALL USING (user_id = auth.uid());
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can access own answer submissions" ON public.answer_submissions FOR ALL USING (user_id = auth.uid());
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can access own bookmarks" ON public.bookmarks FOR ALL USING (user_id = auth.uid());
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can access own collections" ON public.bookmark_collections FOR ALL USING (user_id = auth.uid());
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

-- ============================================
-- FUNCTIONS
-- ============================================

-- Update timestamp function
DROP FUNCTION IF EXISTS update_updated_at() CASCADE;
DO $migration$ BEGIN
    BEGIN
        CREATE OR REPLACE FUNCTION update_updated_at()
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

-- Apply updated_at trigger to relevant tables
DO $migration$ BEGIN
    BEGIN
        CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE TRIGGER update_subscriptions_updated_at
    BEFORE UPDATE ON public.subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE TRIGGER update_syllabus_progress_updated_at
    BEFORE UPDATE ON public.syllabus_progress
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE TRIGGER update_comprehensive_notes_updated_at
    BEFORE UPDATE ON public.comprehensive_notes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE TRIGGER update_video_renders_updated_at
    BEFORE UPDATE ON public.video_renders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE TRIGGER update_jobs_updated_at
    BEFORE UPDATE ON public.jobs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

-- Entitlement check function
-- Drop first to handle return type changes
DROP FUNCTION IF EXISTS check_entitlement(UUID, TEXT);
CREATE OR REPLACE FUNCTION check_entitlement(
    p_user_id UUID,
    p_feature_code TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    v_entitlement RECORD;
    v_used_count INTEGER;
    v_limit INTEGER;
BEGIN
    SELECT * INTO v_entitlement
    FROM public.entitlements
    WHERE user_id = p_user_id AND feature_code = p_feature_code;

    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    v_used_count := v_entitlement.used_count;
    v_limit := COALESCE(v_entitlement.daily_limit, v_entitlement.monthly_limit, 0);

    IF v_limit > 0 AND v_used_count >= v_limit THEN
        RETURN FALSE;
    END IF;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Increment entitlement usage
-- Drop first to handle return type changes
DROP FUNCTION IF EXISTS increment_entitlement_usage(UUID, TEXT);
CREATE OR REPLACE FUNCTION increment_entitlement_usage(
    p_user_id UUID,
    p_feature_code TEXT
)
RETURNS VOID AS $$
BEGIN
    UPDATE public.entitlements
    SET used_count = used_count + 1
    WHERE user_id = p_user_id AND feature_code = p_feature_code;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- SEED DATA
-- ============================================

-- Insert default plans
INSERT INTO public.plans (name, code, price_monthly, price_quarterly, price_half_yearly, price_annually, features)
VALUES
    ('Free', 'free', 0, NULL, NULL, NULL, '{"access_level": "basic", "video_quality": "720p", "daily_video_limit": 1}'),
    ('Pro', 'pro', 599, 1499, 2699, 4999, '{"access_level": "full", "video_quality": "1080p", "daily_video_limit": 10, "priority_queue": true}')
ON CONFLICT (code) DO NOTHING;

-- Insert queue configuration
INSERT INTO public.queue_config (job_type, max_concurrent, timeout_minutes, retry_limit)
VALUES
    ('video_render', 10, 60, 3),
    ('notes_generation', 5, 30, 2),
    ('pdf_processing', 3, 45, 2),
    ('embedding_update', 2, 60, 2)
ON CONFLICT (job_type) DO NOTHING;




