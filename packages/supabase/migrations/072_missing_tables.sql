-- Migration 072: Add missing tables requested by user
-- 1. daily_ca_videos
-- 2. doubt_videos
-- 3. knowledge_sources
-- 4. user_notes

-- ============================================================================
-- 1. DAILY CA VIDEOS
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.daily_ca_videos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date DATE NOT NULL,
    title TEXT,
    video_url TEXT NOT NULL,
    thumbnail_url TEXT,
    duration_seconds INTEGER DEFAULT 0,
    summary TEXT,
    topics TEXT[] DEFAULT '{}',
    status TEXT DEFAULT 'published' CHECK (status IN ('draft', 'published', 'archived')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(date)
);

-- RLS
ALTER TABLE public.daily_ca_videos ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    CREATE POLICY "Anyone can view daily_ca_videos"
        ON public.daily_ca_videos FOR SELECT USING (status = 'published');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Admin policy removed due to missing role column
-- DO $$ BEGIN
--     CREATE POLICY "Admins can manage daily_ca_videos"
--         ON public.daily_ca_videos FOR ALL USING (
--             EXISTS (SELECT 1 FROM public.user_profiles WHERE user_id = auth.uid() AND role = 'admin')
--         );
-- EXCEPTION WHEN duplicate_object THEN NULL; END $$;


-- ============================================================================
-- 2. DOUBT VIDEOS
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.doubt_videos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    video_url TEXT,
    thumbnail_url TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS
ALTER TABLE public.doubt_videos ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    CREATE POLICY "Users can view own doubt_videos"
        ON public.doubt_videos FOR SELECT USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE POLICY "Users can create doubt_videos"
        ON public.doubt_videos FOR INSERT WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================================================
-- 3. KNOWLEDGE SOURCES
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.knowledge_sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    base_url TEXT,
    source_type TEXT CHECK (source_type IN ('website', 'pdf', 'youtube', 'other')),
    is_active BOOLEAN DEFAULT TRUE,
    trust_score DECIMAL(3,2) DEFAULT 1.0,
    last_crawled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS
ALTER TABLE public.knowledge_sources ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    CREATE POLICY "Anyone can view knowledge_sources"
        ON public.knowledge_sources FOR SELECT USING (true);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================================================
-- 4. USER NOTES
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.user_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT,
    content TEXT,
    tags TEXT[] DEFAULT '{}',
    linked_resource_type TEXT, -- e.g., 'video', 'question', 'topic'
    linked_resource_id UUID,
    is_public BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS
ALTER TABLE public.user_notes ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    CREATE POLICY "Users can manage own notes"
        ON public.user_notes FOR ALL USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE POLICY "Users can view public notes"
        ON public.user_notes FOR SELECT USING (is_public = true);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
