-- PYQ Videos & Question Bank Migration
-- Date: December 26, 2025
-- Features: PYQ videos, model answers, bookmarks

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- PYQ VIDEOS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS pyq_videos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- Question data
    question_text TEXT NOT NULL,
    gs_paper TEXT NOT NULL CHECK (gs_paper IN ('GS Paper I', 'GS Paper II', 'GS Paper III', 'GS Paper IV', 'CSAT')),
    year INTEGER NOT NULL CHECK (year BETWEEN 1990 AND 2030),
    -- Video data
    video_url TEXT NOT NULL,
    thumbnail_url TEXT,
    duration_seconds INTEGER DEFAULT 0,
    -- Metadata
    topics TEXT[] DEFAULT '{}',
    difficulty TEXT CHECK (difficulty IN ('easy', 'medium', 'hard')),
    -- Model answer
    model_answer TEXT,
    model_answer_generated_at TIMESTAMP WITH TIME ZONE,
    -- Statistics
    view_count INTEGER DEFAULT 0,
    like_count INTEGER DEFAULT 0,
    -- Status
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN ALTER TABLE pyq_videos ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT gen_random_uuid(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE pyq_videos ADD COLUMN IF NOT EXISTS question_text TEXT NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE pyq_videos ADD COLUMN IF NOT EXISTS gs_paper TEXT NOT NULL CHECK (gs_paper IN ('GS Paper I', 'GS Paper II', 'GS Paper III', 'GS Paper IV', 'CSAT')); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE pyq_videos ADD COLUMN IF NOT EXISTS year INTEGER NOT NULL CHECK (year BETWEEN 1990 AND 2030); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE pyq_videos ADD COLUMN IF NOT EXISTS video_url TEXT NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE pyq_videos ADD COLUMN IF NOT EXISTS duration_seconds INTEGER DEFAULT 0; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE pyq_videos ADD COLUMN IF NOT EXISTS topics TEXT[] DEFAULT '{}'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE pyq_videos ADD COLUMN IF NOT EXISTS difficulty TEXT CHECK (difficulty IN ('easy', 'medium', 'hard')); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE pyq_videos ADD COLUMN IF NOT EXISTS model_answer_generated_at TIMESTAMP WITH TIME ZONE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE pyq_videos ADD COLUMN IF NOT EXISTS view_count INTEGER DEFAULT 0; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE pyq_videos ADD COLUMN IF NOT EXISTS like_count INTEGER DEFAULT 0; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE pyq_videos ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE pyq_videos ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE pyq_videos ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
END $migration$;


-- Indexes for pyq_videos
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_pyq_videos_paper_year ON pyq_videos(gs_paper, year DESC);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_pyq_videos_status ON pyq_videos(status);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_pyq_videos_topics ON pyq_videos USING GIN(topics);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_pyq_videos_view_count ON pyq_videos(view_count DESC);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================
-- PYQ BOOKMARKS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS pyq_bookmarks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    question_id UUID,
    -- Frozen question data
    question_text TEXT NOT NULL,
    gs_paper TEXT,
    year INTEGER,
    topics TEXT[],
    -- Timestamps
    bookmarked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, question_id)
);

DO $migration$ BEGIN
    BEGIN ALTER TABLE pyq_bookmarks ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT gen_random_uuid(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE pyq_bookmarks ADD COLUMN IF NOT EXISTS user_id UUID NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE pyq_bookmarks ADD COLUMN IF NOT EXISTS question_text TEXT NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE pyq_bookmarks ADD COLUMN IF NOT EXISTS topics TEXT[]; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE pyq_bookmarks ADD COLUMN IF NOT EXISTS bookmarked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
END $migration$;


DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'users') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'pyq_bookmarks_user_id_fkey') THEN
            ALTER TABLE pyq_bookmarks ADD CONSTRAINT pyq_bookmarks_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        END IF;
    END IF;
EXCEPTION WHEN others THEN NULL;
END $$;

DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'pyq_videos') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'pyq_bookmarks_question_id_fkey') THEN
            ALTER TABLE pyq_bookmarks ADD CONSTRAINT pyq_bookmarks_question_id_fkey FOREIGN KEY (question_id) REFERENCES pyq_videos(id) ON DELETE CASCADE;
        END IF;
    END IF;
EXCEPTION WHEN others THEN NULL;
END $$;

-- Indexes for pyq_bookmarks
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_pyq_bookmarks_user ON pyq_bookmarks(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_pyq_bookmarks_date ON pyq_bookmarks(bookmarked_at DESC);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================
-- MODEL ANSWERS TABLE (Detailed answers)
-- ============================================
CREATE TABLE IF NOT EXISTS model_answers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_id UUID,
    -- Answer content
    answer_text TEXT NOT NULL,
    word_count INTEGER NOT NULL,
    -- Structure
    structure_json JSONB DEFAULT '{}',
    -- Quality metrics
    content_score DECIMAL(3,1),
    structure_score DECIMAL(3,1),
    language_score DECIMAL(3,1),
    total_score DECIMAL(4,1),
    -- Citations
    citations JSONB DEFAULT '[]',
    -- Status
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'reviewed', 'published')),
    reviewed_by UUID,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN ALTER TABLE model_answers ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT gen_random_uuid(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE model_answers ADD COLUMN IF NOT EXISTS answer_text TEXT NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE model_answers ADD COLUMN IF NOT EXISTS word_count INTEGER NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE model_answers ADD COLUMN IF NOT EXISTS structure_json JSONB DEFAULT '{}'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE model_answers ADD COLUMN IF NOT EXISTS citations JSONB DEFAULT '[]'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE model_answers ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'reviewed', 'published')); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE model_answers ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMP WITH TIME ZONE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE model_answers ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE model_answers ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
END $migration$;


DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'pyq_videos') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'model_answers_question_id_fkey') THEN
            ALTER TABLE model_answers ADD CONSTRAINT model_answers_question_id_fkey FOREIGN KEY (question_id) REFERENCES pyq_videos(id) ON DELETE CASCADE;
        END IF;
    END IF;
EXCEPTION WHEN others THEN NULL;
END $$;

-- Indexes for model_answers
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_model_answers_question ON model_answers(question_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_model_answers_score ON model_answers(total_score DESC);
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
        ALTER TABLE pyq_videos ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE pyq_bookmarks ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE model_answers ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- PYQ videos - public read access for published

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Anyone can view published PYQ videos" ON pyq_videos
    FOR SELECT USING (status = 'published');
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- PYQ bookmarks - user only

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can view own bookmarks" ON pyq_bookmarks
    FOR SELECT USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can manage own bookmarks" ON pyq_bookmarks
    FOR ALL USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Model answers - public read access

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Anyone can view model answers" ON model_answers
    FOR SELECT USING (status = 'published');
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================
-- FUNCTIONS AND TRIGGERS
-- ============================================

-- Update updated_at timestamp
DO $migration$ BEGIN
    BEGIN
        CREATE OR REPLACE FUNCTION update_pyq_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
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
        CREATE TRIGGER update_pyq_videos_updated_at
    BEFORE UPDATE ON pyq_videos
    FOR EACH ROW EXECUTE FUNCTION update_pyq_updated_at();
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE TRIGGER update_model_answers_updated_at
    BEFORE UPDATE ON model_answers
    FOR EACH ROW EXECUTE FUNCTION update_pyq_updated_at();
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================
-- SEED DATA: Sample PYQ Videos
-- ============================================

DO $migration$ BEGIN
    BEGIN
INSERT INTO pyq_videos (question_text, gs_paper, year, video_url, topics, difficulty, status)
VALUES
    -- GS Paper I
    ('Discuss the main features of the Indian National Congresss ideology and program during 1885-1905.', 'GS Paper I', 2023, 'http://89.117.60.144:5001/pyq/2023_gs1_1.mp4', ARRAY['Indian National Congress', 'British Raj', 'Moderates', 'History'], 'medium', 'published'),
    ('Evaluate the impact of the Bhakti movement on Indian society and culture.', 'GS Paper I', 2023, 'http://89.117.60.144:5001/pyq/2023_gs1_2.mp4', ARRAY['Bhakti Movement', 'Social Reform', 'Religion', 'Culture'], 'medium', 'published'),
    -- GS Paper II
    ('Discuss the role of the Governor in the Indian federal system.', 'GS Paper II', 2023, 'http://89.117.60.144:5001/pyq/2023_gs2_1.mp4', ARRAY['Governor', 'Federalism', 'Constitution', 'State Government'], 'easy', 'published'),
    ('Analyze the challenges faced by the Indian judicial system.', 'GS Paper II', 2023, 'http://89.117.60.144:5001/pyq/2023_gs2_2.mp4', ARRAY['Judiciary', 'Justice System', 'Supreme Court', 'Reforms'], 'hard', 'published'),
    -- GS Paper III
    ('Explain the concept of Sustainable Development Goals (SDGs) and Indias progress.', 'GS Paper III', 2023, 'http://89.117.60.144:5001/pyq/2023_gs3_1.mp4', ARRAY['SDGs', 'Sustainable Development', 'India', 'Environment'], 'medium', 'published'),
    ('Discuss the challenges and opportunities in Indias renewable energy sector.', 'GS Paper III', 2023, 'http://89.117.60.144:5001/pyq/2023_gs3_2.mp4', ARRAY['Renewable Energy', 'Solar', 'Wind', 'Climate Change'], 'medium', 'published'),
    -- GS Paper IV
    ('"Public service is a mission rather than a career." Comment with examples.', 'GS Paper IV', 2023, 'http://89.117.60.144:5001/pyq/2023_gs4_1.mp4', ARRAY['Ethics', 'Public Service', 'Integrity', 'Accountability'], 'medium', 'published'),
    -- CSAT
    ('If 15% of a number is 45, what is 30% of that number?', 'CSAT', 2023, 'http://89.117.60.144:5001/pyq/2023_csat_1.mp4', ARRAY['Percentage', 'Mathematics', 'CSAT'], 'easy', 'published'),
    ('Complete the series: 2, 5, 10, 17, 26, ...', 'CSAT', 2023, 'http://89.117.60.144:5001/pyq/2023_csat_2.mp4', ARRAY['Series', 'Mathematics', 'CSAT'], 'medium', 'published')
ON CONFLICT DO NOTHING;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Print migration status
SELECT 'PYQ videos migration completed successfully' AS status;

-- Show created tables
SELECT table_name, (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = 'public' AND table_name = t.table_name) AS column_count
FROM information_schema.tables t
WHERE table_schema = 'public'
  AND table_name IN ('pyq_videos', 'pyq_bookmarks', 'model_answers')
ORDER BY table_name;


