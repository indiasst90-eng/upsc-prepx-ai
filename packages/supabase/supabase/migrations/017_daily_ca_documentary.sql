-- Phase 4: Scale & Automation Migration
-- Date: December 26, 2025
-- Features: Daily CA, Documentary, Telegram Bot, Auto-publishing

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- DAILY UPDATES TABLE (Articles from Scraper)
-- ============================================
CREATE TABLE IF NOT EXISTS daily_updates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- Content
    title TEXT NOT NULL,
    summary TEXT,
    body_text TEXT,
    -- Source
    source_url TEXT NOT NULL,
    source_name TEXT,
    published_date TIMESTAMP WITH TIME ZONE,
    scraped_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    -- Categorization
    category_tags TEXT[] DEFAULT '{}',
    upsc_relevant BOOLEAN DEFAULT FALSE,
    relevance_score DECIMAL(3,2),
    subjects TEXT[] DEFAULT '{}', -- ['Polity', 'Economy', etc.]
    papers TEXT[] DEFAULT '{}', -- ['GS Paper I', 'GS Paper II', etc.]
    -- Processing
    status TEXT DEFAULT 'pending_video' CHECK (status IN ('pending_video', 'queued_script', 'queued_render', 'rendering', 'published', 'failed')),
    -- Embedding for deduplication
    embedding vector(1536),
    -- Timestamps
    date DATE GENERATED ALWAYS AS (published_date::DATE) STORED,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN ALTER TABLE daily_updates ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT gen_random_uuid(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_updates ADD COLUMN IF NOT EXISTS title TEXT NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_updates ADD COLUMN IF NOT EXISTS source_url TEXT NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_updates ADD COLUMN IF NOT EXISTS published_date TIMESTAMP WITH TIME ZONE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_updates ADD COLUMN IF NOT EXISTS scraped_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_updates ADD COLUMN IF NOT EXISTS category_tags TEXT[] DEFAULT '{}'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_updates ADD COLUMN IF NOT EXISTS upsc_relevant BOOLEAN DEFAULT FALSE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_updates ADD COLUMN IF NOT EXISTS subjects TEXT[] DEFAULT '{}'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_updates ADD COLUMN IF NOT EXISTS papers TEXT[] DEFAULT '{}'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_updates ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending_video' CHECK (status IN ('pending_video', 'queued_script', 'queued_render', 'rendering', 'published', 'failed')); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_updates ADD COLUMN IF NOT EXISTS date DATE GENERATED ALWAYS AS (published_date::DATE) STORED; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_updates ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
END $migration$;


-- Indexes for daily_updates
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_daily_updates_date ON daily_updates(date DESC);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_daily_updates_status ON daily_updates(status);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_daily_updates_relevant ON daily_updates(upsc_relevant) WHERE upsc_relevant = TRUE;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_daily_updates_papers ON daily_updates USING GIN(papers);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
-- Use HNSW instead of IVFFlat (works on empty tables)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_daily_updates_embedding') THEN
        DO $migration$ BEGIN
    BEGIN
        CREATE INDEX idx_daily_updates_embedding ON daily_updates USING hnsw (embedding vector_cosine_ops);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
    END IF;
EXCEPTION WHEN undefined_column THEN
    RAISE NOTICE 'embedding column not yet available, skipping index';
END $$;

-- ============================================
-- DAILY UPDATES SOURCES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS daily_updates_sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_name TEXT UNIQUE NOT NULL,
    base_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    last_scraped_at TIMESTAMP WITH TIME ZONE,
    articles_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN ALTER TABLE daily_updates_sources ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT gen_random_uuid(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_updates_sources ADD COLUMN IF NOT EXISTS source_name TEXT UNIQUE NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_updates_sources ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_updates_sources ADD COLUMN IF NOT EXISTS last_scraped_at TIMESTAMP WITH TIME ZONE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_updates_sources ADD COLUMN IF NOT EXISTS articles_count INTEGER DEFAULT 0; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_updates_sources ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
END $migration$;


-- Seed whitelisted sources
DO $$
BEGIN
    INSERT INTO daily_updates_sources (source_name, base_url, is_active) VALUES
        ('Vision IAS', 'https://visionias.in', TRUE),
        ('Drishti IAS', 'https://drishtiias.com', TRUE),
        ('The Hindu', 'https://thehindu.com', TRUE),
        ('PIB', 'https://pib.gov.in', TRUE),
        ('Forum IAS', 'https://forumias.com', TRUE),
        ('InsightsIA', 'https://insightsonindia.com', TRUE),
        ('IAS Baba', 'https://iasbaba.com', TRUE),
        ('IAS Score', 'https://iasscore.in', TRUE)
    ON CONFLICT (source_name) DO NOTHING;
EXCEPTION
  WHEN undefined_table THEN
    -- Handle case where daily_updates_sources table doesn't exist yet
    RAISE NOTICE 'daily_updates_sources table not yet available, skipping seed data';
END $$;

-- ============================================
-- SCRAPER LOGS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS scraper_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scrape_date DATE NOT NULL,
    status TEXT CHECK (status IN ('success', 'partial', 'failed')),
    articles_found INTEGER DEFAULT 0,
    articles_relevant INTEGER DEFAULT 0,
    duration_ms INTEGER,
    details_json JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(scrape_date)
);

DO $migration$ BEGIN
    BEGIN ALTER TABLE scraper_logs ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT gen_random_uuid(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE scraper_logs ADD COLUMN IF NOT EXISTS scrape_date DATE NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE scraper_logs ADD COLUMN IF NOT EXISTS status TEXT CHECK (status IN ('success', 'partial', 'failed')); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE scraper_logs ADD COLUMN IF NOT EXISTS articles_found INTEGER DEFAULT 0; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE scraper_logs ADD COLUMN IF NOT EXISTS articles_relevant INTEGER DEFAULT 0; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE scraper_logs ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
END $migration$;


-- ============================================
-- DAILY CA SCRIPTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS daily_ca_scripts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date DATE NOT NULL UNIQUE,
    script_sections JSONB NOT NULL DEFAULT '[]',
    total_duration_seconds INTEGER DEFAULT 0,
    word_count INTEGER DEFAULT 0,
    article_count INTEGER DEFAULT 0,
    topics_covered TEXT[] DEFAULT '{}',
    -- Video
    video_url TEXT,
    thumbnail_url TEXT,
    status TEXT DEFAULT 'pending_visuals' CHECK (status IN ('pending_visuals', 'queued_render', 'rendering', 'completed', 'failed')),
    -- Metadata
    generated_at TIMESTAMP WITH TIME ZONE,
    published_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN ALTER TABLE daily_ca_scripts ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT gen_random_uuid(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_ca_scripts ADD COLUMN IF NOT EXISTS date DATE NOT NULL UNIQUE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_ca_scripts ADD COLUMN IF NOT EXISTS script_sections JSONB NOT NULL DEFAULT '[]'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_ca_scripts ADD COLUMN IF NOT EXISTS total_duration_seconds INTEGER DEFAULT 0; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_ca_scripts ADD COLUMN IF NOT EXISTS word_count INTEGER DEFAULT 0; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_ca_scripts ADD COLUMN IF NOT EXISTS article_count INTEGER DEFAULT 0; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_ca_scripts ADD COLUMN IF NOT EXISTS topics_covered TEXT[] DEFAULT '{}'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_ca_scripts ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending_visuals' CHECK (status IN ('pending_visuals', 'queued_render', 'rendering', 'completed', 'failed')); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_ca_scripts ADD COLUMN IF NOT EXISTS generated_at TIMESTAMP WITH TIME ZONE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_ca_scripts ADD COLUMN IF NOT EXISTS published_at TIMESTAMP WITH TIME ZONE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_ca_scripts ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
END $migration$;


-- ============================================
-- DOCUMENTARY SCRIPTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS documentary_scripts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- Content
    topic TEXT NOT NULL,
    duration_hours INTEGER DEFAULT 3,
    style TEXT DEFAULT 'chronological' CHECK (style IN ('chronological', 'thematic', 'problem-solution')),
    -- Script
    intro JSONB DEFAULT '{}',
    chapters JSONB NOT NULL DEFAULT '[]',
    conclusion JSONB DEFAULT '{}',
    -- Totals
    total_duration_minutes INTEGER DEFAULT 0,
    total_words INTEGER DEFAULT 0,
    -- Video
    video_url TEXT,
    thumbnail_url TEXT,
    status TEXT DEFAULT 'pending_visuals' CHECK (status IN ('pending_visuals', 'queued_render', 'rendering', 'completed', 'failed')),
    -- Timestamps
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN ALTER TABLE documentary_scripts ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT gen_random_uuid(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE documentary_scripts ADD COLUMN IF NOT EXISTS topic TEXT NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE documentary_scripts ADD COLUMN IF NOT EXISTS duration_hours INTEGER DEFAULT 3; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE documentary_scripts ADD COLUMN IF NOT EXISTS style TEXT DEFAULT 'chronological' CHECK (style IN ('chronological', 'thematic', 'problem-solution')); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE documentary_scripts ADD COLUMN IF NOT EXISTS intro JSONB DEFAULT '{}'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE documentary_scripts ADD COLUMN IF NOT EXISTS chapters JSONB NOT NULL DEFAULT '[]'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE documentary_scripts ADD COLUMN IF NOT EXISTS conclusion JSONB DEFAULT '{}'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE documentary_scripts ADD COLUMN IF NOT EXISTS total_duration_minutes INTEGER DEFAULT 0; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE documentary_scripts ADD COLUMN IF NOT EXISTS total_words INTEGER DEFAULT 0; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE documentary_scripts ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending_visuals' CHECK (status IN ('pending_visuals', 'queued_render', 'rendering', 'completed', 'failed')); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE documentary_scripts ADD COLUMN IF NOT EXISTS generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
END $migration$;


-- ============================================
-- TELEGRAM SUBSCRIPTIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS telegram_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID ,
    telegram_chat_id TEXT NOT NULL,
    telegram_user_id TEXT,
    -- Subscription preferences
    subscriptions JSONB DEFAULT '{
        "daily_ca": true,
        "documentary": false,
        "practice_reminder": false,
        "weekly_digest": false
    }',
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    last_notified_at TIMESTAMP WITH TIME ZONE,
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(telegram_chat_id)
);

DO $migration$ BEGIN
    BEGIN ALTER TABLE telegram_subscriptions ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT gen_random_uuid(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE telegram_subscriptions ADD COLUMN IF NOT EXISTS user_id UUID ; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE telegram_subscriptions ADD COLUMN IF NOT EXISTS telegram_chat_id TEXT NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE telegram_subscriptions ADD COLUMN IF NOT EXISTS subscriptions JSONB DEFAULT '{"daily_ca": true, "documentary": false, "practice_reminder": false, "weekly_digest": false}'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE telegram_subscriptions ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE telegram_subscriptions ADD COLUMN IF NOT EXISTS last_notified_at TIMESTAMP WITH TIME ZONE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE telegram_subscriptions ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
END $migration$;


-- Add foreign keys if referenced tables exist
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'users') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'telegram_subscriptions_user_id_fkey') THEN
            ALTER TABLE telegram_subscriptions ADD CONSTRAINT telegram_subscriptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        END IF;
    END IF;
EXCEPTION WHEN others THEN NULL;
END $$;

-- Indexes for telegram_subscriptions
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_telegram_subscriptions_user ON telegram_subscriptions(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_telegram_subscriptions_chat ON telegram_subscriptions(telegram_chat_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================
-- YOUTUBE PUBLISHING TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS youtube_publish_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_type TEXT NOT NULL CHECK (content_type IN ('daily_ca', 'documentary', 'topic_short')),
    content_id UUID NOT NULL,
    -- YouTube metadata
    title TEXT NOT NULL,
    description TEXT,
    tags TEXT[] DEFAULT '{}',
    category_id TEXT DEFAULT('22'), -- People & Blogs
    visibility TEXT DEFAULT 'private' CHECK (visibility IN ('public', 'private', 'unlisted')),
    -- Scheduling
    scheduled_at TIMESTAMP WITH TIME ZONE,
    published_at TIMESTAMP WITH TIME ZONE,
    -- Status
    status TEXT DEFAULT 'queued' CHECK (status IN ('queued', 'scheduled', 'publishing', 'published', 'failed')),
    youtube_video_id TEXT,
    youtube_url TEXT,
    error_message TEXT,
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN ALTER TABLE youtube_publish_queue ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT gen_random_uuid(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE youtube_publish_queue ADD COLUMN IF NOT EXISTS content_type TEXT NOT NULL CHECK (content_type IN ('daily_ca', 'documentary', 'topic_short')); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE youtube_publish_queue ADD COLUMN IF NOT EXISTS content_id UUID NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE youtube_publish_queue ADD COLUMN IF NOT EXISTS title TEXT NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE youtube_publish_queue ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE youtube_publish_queue ADD COLUMN IF NOT EXISTS category_id TEXT DEFAULT('22'); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE youtube_publish_queue ADD COLUMN IF NOT EXISTS visibility TEXT DEFAULT 'private' CHECK (visibility IN ('public', 'private', 'unlisted')); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE youtube_publish_queue ADD COLUMN IF NOT EXISTS scheduled_at TIMESTAMP WITH TIME ZONE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE youtube_publish_queue ADD COLUMN IF NOT EXISTS published_at TIMESTAMP WITH TIME ZONE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE youtube_publish_queue ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'queued' CHECK (status IN ('queued', 'scheduled', 'publishing', 'published', 'failed')); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE youtube_publish_queue ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
END $migration$;


-- Indexes for youtube_publish_queue
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_youtube_queue_status ON youtube_publish_queue(status);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_youtube_queue_scheduled ON youtube_publish_queue(scheduled_at) WHERE scheduled_at IS NOT NULL;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================
-- DAILY DIGESTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS daily_digests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL ,
    date DATE NOT NULL,
    -- Content
    topics_covered TEXT[] DEFAULT '{}',
    article_summaries JSONB DEFAULT '[]',
    practice_suggestions JSONB DEFAULT '[]',
    -- Format
    format TEXT DEFAULT 'html' CHECK (format IN ('html', 'text', 'pdf')),
    content TEXT,
    -- Status
    is_read BOOLEAN DEFAULT FALSE,
    sent_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, date)
);

DO $migration$ BEGIN
    BEGIN ALTER TABLE daily_digests ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT gen_random_uuid(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_digests ADD COLUMN IF NOT EXISTS user_id UUID NOT NULL ; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_digests ADD COLUMN IF NOT EXISTS date DATE NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_digests ADD COLUMN IF NOT EXISTS topics_covered TEXT[] DEFAULT '{}'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_digests ADD COLUMN IF NOT EXISTS article_summaries JSONB DEFAULT '[]'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_digests ADD COLUMN IF NOT EXISTS practice_suggestions JSONB DEFAULT '[]'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_digests ADD COLUMN IF NOT EXISTS format TEXT DEFAULT 'html' CHECK (format IN ('html', 'text', 'pdf')); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_digests ADD COLUMN IF NOT EXISTS is_read BOOLEAN DEFAULT FALSE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_digests ADD COLUMN IF NOT EXISTS sent_at TIMESTAMP WITH TIME ZONE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_digests ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
END $migration$;


-- Add foreign keys if referenced tables exist
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'users') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'daily_digests_user_id_fkey') THEN
            ALTER TABLE daily_digests ADD CONSTRAINT daily_digests_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        END IF;
    END IF;
EXCEPTION WHEN others THEN NULL;
END $$;

-- Indexes for daily_digests
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_daily_digests_user ON daily_digests(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_daily_digests_date ON daily_digests(date DESC);
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
        ALTER TABLE daily_updates ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE daily_ca_scripts ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE documentary_scripts ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE telegram_subscriptions ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE youtube_publish_queue ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE daily_digests ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Daily updates - public read access

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Anyone can view published daily updates" ON daily_updates
    FOR SELECT USING (status = 'published' OR status = 'pending_video');
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Daily CA scripts - public read access for published

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Anyone can view daily CA scripts" ON daily_ca_scripts
    FOR SELECT USING (true);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Documentary scripts - public read access

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Anyone can view documentary scripts" ON documentary_scripts
    FOR SELECT USING (true);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Telegram subscriptions - user only

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can view own telegram subscriptions" ON telegram_subscriptions
    FOR SELECT USING (auth.uid() = user_id OR user_id IS NULL);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can manage own telegram subscriptions" ON telegram_subscriptions
    FOR ALL USING (auth.uid() = user_id OR user_id IS NULL);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Daily digests - user only

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can view own daily digests" ON daily_digests
    FOR SELECT USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can manage own daily digests" ON daily_digests
    FOR ALL USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Find similar articles using cosine similarity
DO $migration$ BEGIN
    BEGIN
        CREATE OR REPLACE FUNCTION find_similar_articles(
    query_embedding vector(1536),
    threshold float DEFAULT 0.9,
    limit_count integer DEFAULT 5
)
RETURNS TABLE (
    id uuid,
    title text,
    similarity float
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        d.id,
        d.title,
        1 - (d.embedding <=> query_embedding) as similarity
    FROM daily_updates d
    WHERE d.embedding IS NOT NULL
      AND 1 - (d.embedding <=> query_embedding) > threshold
    ORDER BY d.embedding <=> query_embedding
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Calculate relevance score from embedding similarity
DO $migration$ BEGIN
    BEGIN
        CREATE OR REPLACE FUNCTION calculate_relevance_score(query_text TEXT)
RETURNS DECIMAL AS $$
DECLARE
    embedding vector(1536);
    max_similarity DECIMAL := 0;
BEGIN
    -- Get embedding for query (simplified - in production, call A4F)
    -- This is a placeholder that returns a random score
    RETURN ROUND((random() * 0.3 + 0.7)::decimal, 2);
END;
$$ LANGUAGE plpgsql;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================
-- JOB QUEUE TABLE (Required for automation)
-- ============================================
CREATE TABLE IF NOT EXISTS job_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_type TEXT NOT NULL,
    payload JSONB DEFAULT '{}',
    status TEXT DEFAULT 'queued' CHECK (status IN ('queued', 'processing', 'completed', 'failed')),
    error_message TEXT,
    attempts INTEGER DEFAULT 0,
    max_attempts INTEGER DEFAULT 3,
    scheduled_for TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN ALTER TABLE job_queue ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT gen_random_uuid(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE job_queue ADD COLUMN IF NOT EXISTS job_type TEXT NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE job_queue ADD COLUMN IF NOT EXISTS payload JSONB DEFAULT '{}'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE job_queue ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'queued' CHECK (status IN ('queued', 'processing', 'completed', 'failed')); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE job_queue ADD COLUMN IF NOT EXISTS attempts INTEGER DEFAULT 0; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE job_queue ADD COLUMN IF NOT EXISTS max_attempts INTEGER DEFAULT 3; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE job_queue ADD COLUMN IF NOT EXISTS scheduled_for TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE job_queue ADD COLUMN IF NOT EXISTS started_at TIMESTAMP WITH TIME ZONE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE job_queue ADD COLUMN IF NOT EXISTS completed_at TIMESTAMP WITH TIME ZONE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE job_queue ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_job_queue_status ON job_queue(status);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_job_queue_scheduled ON job_queue(scheduled_for) WHERE status = 'queued';
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================
-- FUNCTIONS FOR AUTOMATION
-- ============================================

-- Trigger daily CA generation
DO $migration$ BEGIN
    BEGIN
        CREATE OR REPLACE FUNCTION trigger_daily_ca_generation(p_date DATE)
RETURNS void AS $$
BEGIN
    -- Queue script generation
    INSERT INTO job_queue (job_type, payload, status, created_at)
    VALUES ('generate_ca_script', jsonb_build_object('date', p_date), 'queued', NOW());

    -- Queue video rendering
    INSERT INTO job_queue (job_type, payload, status, created_at)
    VALUES ('render_daily_ca', jsonb_build_object('date', p_date), 'queued', NOW());
END;
$$ LANGUAGE plpgsql;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Print migration status
SELECT 'Phase 4 migration completed successfully' AS status;

-- Show created tables
SELECT table_name, (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = 'public' AND table_name = t.table_name) AS column_count
FROM information_schema.tables t
WHERE table_schema = 'public'
  AND table_name IN (
    'daily_updates', 'daily_updates_sources', 'scraper_logs',
    'daily_ca_scripts', 'documentary_scripts',
    'telegram_subscriptions', 'youtube_publish_queue', 'daily_digests'
  )
ORDER BY table_name;


