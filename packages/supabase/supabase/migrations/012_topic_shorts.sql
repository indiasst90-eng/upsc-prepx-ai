-- Topic Shorts Feature Migration
-- Date: December 26, 2025
-- Feature: 60-Second Topic Shorts with caching

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- TOPIC SHORTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS topic_shorts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    syllabus_node_id UUID,
    -- Video data
    video_url TEXT,
    thumbnail_url TEXT,
    -- Script
    script_text TEXT, -- 150 words, fixed format
    -- Status tracking
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    error_message TEXT,
    -- Caching
    cached_until TIMESTAMP WITH TIME ZONE,
    -- Credits
    credits_used INTEGER DEFAULT 1,
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Add foreign keys if referenced tables exist
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'users') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'topic_shorts_user_id_fkey') THEN
            ALTER TABLE topic_shorts ADD CONSTRAINT topic_shorts_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        END IF;
    END IF;
EXCEPTION WHEN others THEN NULL;
END $$;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'syllabus_nodes') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'topic_shorts_syllabus_node_id_fkey') THEN
            ALTER TABLE topic_shorts ADD CONSTRAINT topic_shorts_syllabus_node_id_fkey FOREIGN KEY (syllabus_node_id) REFERENCES public.syllabus_nodes(id) ON DELETE SET NULL;
        END IF;
    END IF;
EXCEPTION WHEN others THEN NULL;
END $$;

-- Indexes for topic_shorts
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_topic_shorts_user_id ON topic_shorts(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_topic_shorts_syllabus_node ON topic_shorts(syllabus_node_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_topic_shorts_status ON topic_shorts(status);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
-- Partial index without NOW() - filter at query time instead
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_topic_shorts_cached ON topic_shorts(cached_until)
    WHERE cached_until IS NOT NULL;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_topic_shorts_created_at ON topic_shorts(created_at DESC);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

-- ============================================
-- TOPIC SHORTS VIEW STATISTICS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS topic_shorts_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    topic_short_id UUID NOT NULL,
    user_id UUID NOT NULL,
    -- Watch data
    watch_duration_seconds INTEGER DEFAULT 0,
    completed_watch BOOLEAN DEFAULT FALSE,
    -- Device info
    device_type TEXT,
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add foreign keys for topic_shorts_stats
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'topic_shorts_stats_topic_short_id_fkey') THEN
        ALTER TABLE topic_shorts_stats ADD CONSTRAINT topic_shorts_stats_topic_short_id_fkey FOREIGN KEY (topic_short_id) REFERENCES topic_shorts(id) ON DELETE CASCADE;
    END IF;
EXCEPTION WHEN others THEN NULL;
END $$;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'users') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'topic_shorts_stats_user_id_fkey') THEN
            ALTER TABLE topic_shorts_stats ADD CONSTRAINT topic_shorts_stats_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        END IF;
    END IF;
EXCEPTION WHEN others THEN NULL;
END $$;

-- Indexes for stats
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_topic_shorts_stats_short_id ON topic_shorts_stats(topic_short_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_topic_shorts_stats_user_id ON topic_shorts_stats(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

-- ============================================
-- RLS POLICIES
-- ============================================
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE topic_shorts ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE topic_shorts_stats ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

-- Users can view own topic shorts
DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can view own topic shorts" ON topic_shorts
    FOR SELECT USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can manage own topic shorts" ON topic_shorts
    FOR ALL USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can view own topic shorts stats" ON topic_shorts_stats
    FOR SELECT USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can manage own topic shorts stats" ON topic_shorts_stats
    FOR ALL USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

-- ============================================
-- FUNCTIONS AND TRIGGERS
-- ============================================

-- Update updated_at timestamp
DO $migration$ BEGIN
    BEGIN
        CREATE OR REPLACE FUNCTION update_topic_shorts_updated_at()
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

DO $migration$ BEGIN
    BEGIN
        CREATE TRIGGER update_topic_shorts_updated_at
    BEFORE UPDATE ON topic_shorts
    FOR EACH ROW EXECUTE FUNCTION update_topic_shorts_updated_at();
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Get cached topic short for a node
DO $migration$ BEGIN
    BEGIN
        CREATE OR REPLACE FUNCTION get_cached_topic_short(p_syllabus_node_id UUID)
RETURNS TABLE (
    id UUID,
    video_url TEXT,
    script_text TEXT,
    cached_until TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT ts.id, ts.video_url, ts.script_text, ts.cached_until
    FROM topic_shorts ts
    WHERE ts.syllabus_node_id = p_syllabus_node_id
      AND ts.status = 'completed'
      AND ts.cached_until > NOW()
    ORDER BY ts.created_at DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

-- Count topic shorts for user today
DO $migration$ BEGIN
    BEGIN
        CREATE OR REPLACE FUNCTION count_todays_topic_shorts(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM topic_shorts
    WHERE user_id = p_user_id
      AND created_at::DATE = CURRENT_DATE;
    RETURN v_count;
END;
$$ LANGUAGE plpgsql;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

-- ============================================
-- MIGRATION STATUS
-- ============================================
SELECT 'Topic shorts migration completed' AS status;

-- Show created tables
SELECT
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = 'public' AND table_name = t.table_name) AS column_count
FROM information_schema.tables t
WHERE table_schema = 'public'
  AND table_name IN ('topic_shorts', 'topic_shorts_stats')
ORDER BY table_name;
