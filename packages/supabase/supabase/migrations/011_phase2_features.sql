-- Phase 2 Features Migration
-- Date: December 24, 2025
-- Features: Book-to-Notes, Chat Assistant, Bookmarks, Mindmaps, Confidence Meter

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- BOOK CONVERSIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS book_conversions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL ,
    book_title TEXT NOT NULL,
    author_name TEXT,
    file_name TEXT,
    file_url TEXT,
    file_size_bytes BIGINT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    progress_percent INTEGER DEFAULT 0,
    error_message TEXT,
    -- Output data
    notes_output JSONB DEFAULT '{}',
    mcqs_output JSONB DEFAULT '[]',
    summary_output JSONB DEFAULT '{}',
    -- Metadata
    total_pages INTEGER,
    processed_pages INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Indexes for book_conversions
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_book_conversions_user_id ON book_conversions(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_book_conversions_status ON book_conversions(status);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_book_conversions_created_at ON book_conversions(created_at DESC);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

-- ============================================
-- CHAT CONVERSATIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS chat_conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL ,
    title TEXT NOT NULL,
    topic TEXT,
    -- Messages stored as JSON array
    -- Format: [{role: 'user'|'assistant', content: '...', timestamp: '...'}]
    messages JSONB DEFAULT '[]',
    context JSONB DEFAULT '{}', -- User progress, weak topics, etc.
    message_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for chat_conversations
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_chat_conversations_user_id ON chat_conversations(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_chat_conversations_created_at ON chat_conversations(created_at DESC);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

-- ============================================
-- CHAT MESSAGE LOG TABLE (for analytics)
-- ============================================
CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES chat_conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL ,
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    tokens_used INTEGER,
    response_time_ms INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for chat_messages
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_chat_messages_conversation_id ON chat_messages(conversation_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_chat_messages_user_id ON chat_messages(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON chat_messages(created_at);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

-- ============================================
-- BOOKMARKS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS user_bookmarks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL ,
    -- The bookmarked concept
    concept_title TEXT NOT NULL,
    concept_summary TEXT,
    -- Auto-generated related content
    related_notes JSONB DEFAULT '[]',
    related_pyqs JSONB DEFAULT '[]',
    related_videos JSONB DEFAULT '[]',
    -- Tags and categorization
    tags TEXT[] DEFAULT '{}',
    category TEXT,
    -- Syllabus mapping
    syllabus_node_id UUID ,
    -- Revision scheduling
    revision_enabled BOOLEAN DEFAULT TRUE,
    next_revision_date TIMESTAMP WITH TIME ZONE,
    revision_count INTEGER DEFAULT 0,
    last_reviewed_at TIMESTAMP WITH TIME ZONE,
    -- Memory strength (for spaced repetition)
    memory_strength DECIMAL(3,2) DEFAULT 0.5 CHECK (memory_strength BETWEEN 0 AND 1),
    ease_factor DECIMAL(3,2) DEFAULT 2.5 CHECK (ease_factor BETWEEN 1.3 AND 2.5),
    interval_days INTEGER DEFAULT 1,
    -- Source context
    source_type TEXT, -- 'notes', 'news', 'video', 'practice', 'manual'
    source_id TEXT,
    source_context TEXT,
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for bookmarks
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_user_bookmarks_user_id ON user_bookmarks(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_user_bookmarks_syllabus_node ON user_bookmarks(syllabus_node_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_user_bookmarks_revision ON user_bookmarks(next_revision_date) WHERE revision_enabled = TRUE;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_user_bookmarks_tags ON user_bookmarks USING GIN(tags);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_user_bookmarks_created_at ON user_bookmarks(created_at DESC);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

-- ============================================
-- REVISION SCHEDULE TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS revision_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL ,
    bookmark_id UUID REFERENCES user_bookmarks(id) ON DELETE CASCADE,
    concept_title TEXT NOT NULL,
    -- Spaced repetition schedule
    scheduled_date DATE NOT NULL,
    priority TEXT DEFAULT 'medium' CHECK (priority IN ('high', 'medium', 'low')),
    -- Status
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'skipped', 'cancelled')),
    -- Review data
    review_notes TEXT,
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    time_spent_seconds INTEGER,
    -- Algorithm data (SM-2)
    ease_factor DECIMAL(3,2) DEFAULT 2.5,
    interval_days INTEGER DEFAULT 1,
    repetitions INTEGER DEFAULT 0,
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Indexes for revision_schedules
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_revision_schedules_user_id ON revision_schedules(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_revision_schedules_date ON revision_schedules(scheduled_date);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_revision_schedules_status ON revision_schedules(status);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

-- ============================================
-- MINDMAPS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS user_mindmaps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL ,
    title TEXT NOT NULL,
    topic TEXT NOT NULL,
    -- Mindmap structure as JSON
    -- Format: { nodes: [...], edges: [...] }
    structure JSONB NOT NULL DEFAULT '{"nodes": [], "edges": []}',
    -- Export formats
    png_url TEXT,
    pdf_url TEXT,
    -- Source
    source_type TEXT, -- 'text', 'url', 'notes', 'syllabus'
    source_id TEXT,
    source_text TEXT,
    -- Metadata
    node_count INTEGER DEFAULT 0,
    is_public BOOLEAN DEFAULT FALSE,
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for mindmaps
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_user_mindmaps_user_id ON user_mindmaps(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_user_mindmaps_topic ON user_mindmaps(topic);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_user_mindmaps_created_at ON user_mindmaps(created_at DESC);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

-- ============================================
-- CONFIDENCE SCORES TABLE (Concept Confidence Meter)
-- ============================================
CREATE TABLE IF NOT EXISTS confidence_scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL ,
    syllabus_node_id UUID ,
    -- Score components
    quiz_score DECIMAL(5,2), -- Average quiz score (0-100)
    practice_score DECIMAL(5,2), -- Practice session score
    time_spent_minutes INTEGER DEFAULT 0,
    revision_count INTEGER DEFAULT 0,
    -- Confidence calculation
    confidence_score DECIMAL(5,2) NOT NULL CHECK (confidence_score BETWEEN 0 AND 100),
    confidence_level TEXT CHECK (confidence_level IN ('low', 'medium', 'high')),
    -- Derived metrics
    strength_areas JSONB DEFAULT '[]',
    weak_areas JSONB DEFAULT '[]',
    suggested_actions JSONB DEFAULT '[]',
    -- Timestamps
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for confidence_scores
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_confidence_scores_user_id ON confidence_scores(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_confidence_scores_node ON confidence_scores(syllabus_node_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_confidence_scores_level ON confidence_scores(confidence_level);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_confidence_scores_calculated ON confidence_scores(calculated_at DESC);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

-- ============================================
-- DAILY PLANNER TABLES
-- ============================================
CREATE TABLE IF NOT EXISTS study_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL ,
    title TEXT NOT NULL,
    target_date DATE NOT NULL,
    -- Plan structure
    slots JSONB DEFAULT '[]', -- [{time: '06:00-07:00', topic: '...', task: '...'}]
    -- Status
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'completed', 'cancelled')),
    completion_percent DECIMAL(5,2) DEFAULT 0,
    -- Metadata
    total_hours_planned DECIMAL(4,2) DEFAULT 0,
    total_hours_completed DECIMAL(4,2) DEFAULT 0,
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for study_plans
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_study_plans_user_id ON study_plans(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_study_plans_target_date ON study_plans(target_date);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_study_plans_status ON study_plans(status);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

-- ============================================
-- FUNCTIONS AND TRIGGERS
-- ============================================

-- Function to update updated_at timestamp
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

-- Apply updated_at triggers

DO $migration$ BEGIN
    BEGIN
        CREATE TRIGGER update_book_conversions_updated_at
    BEFORE UPDATE ON book_conversions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE TRIGGER update_chat_conversations_updated_at
    BEFORE UPDATE ON chat_conversations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE TRIGGER update_user_bookmarks_updated_at
    BEFORE UPDATE ON user_bookmarks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE TRIGGER update_revision_schedules_updated_at
    BEFORE UPDATE ON revision_schedules
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE TRIGGER update_user_mindmaps_updated_at
    BEFORE UPDATE ON user_mindmaps
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE TRIGGER update_confidence_scores_updated_at
    BEFORE UPDATE ON confidence_scores
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE TRIGGER update_study_plans_updated_at
    BEFORE UPDATE ON study_plans
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

-- ============================================
-- RLS POLICIES (Row Level Security)
-- ============================================

DO $migration$ BEGIN
    BEGIN
        ALTER TABLE book_conversions ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE chat_conversations ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE user_bookmarks ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE revision_schedules ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE user_mindmaps ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE confidence_scores ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE study_plans ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

-- Policies for authenticated users

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can view own book conversions" ON book_conversions
    FOR SELECT USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can manage own book conversions" ON book_conversions
    FOR ALL USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can view own chat conversations" ON chat_conversations
    FOR SELECT USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can manage own chat conversations" ON chat_conversations
    FOR ALL USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can view own chat messages" ON chat_messages
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM chat_conversations WHERE id = chat_messages.conversation_id AND user_id = auth.uid())
    );
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can manage own chat messages" ON chat_messages
    FOR ALL USING (
        EXISTS (SELECT 1 FROM chat_conversations WHERE id = chat_messages.conversation_id AND user_id = auth.uid())
    );
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can view own bookmarks" ON user_bookmarks
    FOR SELECT USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can manage own bookmarks" ON user_bookmarks
    FOR ALL USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can view own revision schedules" ON revision_schedules
    FOR SELECT USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can manage own revision schedules" ON revision_schedules
    FOR ALL USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can view own mindmaps" ON user_mindmaps
    FOR SELECT USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can manage own mindmaps" ON user_mindmaps
    FOR ALL USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can view own confidence scores" ON confidence_scores
    FOR SELECT USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can manage own confidence scores" ON confidence_scores
    FOR ALL USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can view own study plans" ON study_plans
    FOR SELECT USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can manage own study plans" ON study_plans
    FOR ALL USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Calculate next revision date using SM-2 algorithm
DO $migration$ BEGIN
    BEGIN
        CREATE OR REPLACE FUNCTION calculate_next_revision(
    p_ease_factor DECIMAL,
    p_interval INTEGER,
    p_rating INTEGER
)
RETURNS TABLE (
    next_ease_factor DECIMAL,
    next_interval INTEGER,
    next_revision_date TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    v_ease_factor DECIMAL;
    v_interval INTEGER;
BEGIN
    -- SM-2 algorithm
    IF p_rating < 3 THEN
        v_interval := 1;
        v_ease_factor := p_ease_factor;
    ELSE
        v_ease_factor := p_ease_factor + (0.1 - (5 - p_rating) * (0.08 + (5 - p_rating) * 0.02));
        IF v_ease_factor < 1.3 THEN
            v_ease_factor := 1.3;
        END IF;

        IF p_interval = 0 THEN
            v_interval := 1;
        ELSIF p_interval = 1 THEN
            v_interval := 6;
        ELSE
            v_interval := ROUND(p_interval * v_ease_factor);
        END IF;
    END IF;

    RETURN QUERY
    SELECT
        v_ease_factor,
        v_interval,
        NOW() + (v_interval || ' days')::INTERVAL;
END;
$$ LANGUAGE plpgsql;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

-- Calculate confidence score from components
DO $migration$ BEGIN
    BEGIN
        CREATE OR REPLACE FUNCTION calculate_confidence_score(
    p_quiz_score DECIMAL,
    p_practice_score DECIMAL,
    p_time_spent INTEGER,
    p_revision_count INTEGER
)
RETURNS DECIMAL AS $$
DECLARE
    v_score DECIMAL;
BEGIN
    -- Weighted average
    v_score := COALESCE(p_quiz_score, 0) * 0.4 +
               COALESCE(p_practice_score, 0) * 0.3 +
               LEAST(COALESCE(p_time_spent, 0) / 60, 100) * 0.15 +
               LEAST(COALESCE(p_revision_count, 0) * 10, 100) * 0.15;

    RETURN ROUND(v_score, 2);
END;
$$ LANGUAGE plpgsql;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

-- Get confidence level from score
DO $migration$ BEGIN
    BEGIN
        CREATE OR REPLACE FUNCTION get_confidence_level(p_score DECIMAL)
RETURNS TEXT AS $$
BEGIN
    IF p_score < 40 THEN
        RETURN 'low';
    ELSIF p_score < 70 THEN
        RETURN 'medium';
    ELSE
        RETURN 'high';
    END IF;
END;
$$ LANGUAGE plpgsql;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

-- ============================================
-- SEED DATA
-- ============================================

-- Sample study plan templates
INSERT INTO study_plans (user_id, title, target_date, slots, status)
SELECT
    u.id,
    'Default 5-Hour Plan',
    CURRENT_DATE + 1,
    '[
        {"time": "06:00-07:00", "topic": "Current Affairs", "task": "Read newspaper"},
        {"time": "07:00-08:00", "topic": "GS Paper II", "task": "Polity NCERT"},
        {"time": "19:00-20:00", "topic": "GS Paper III", "task": "Economy"},
        {"time": "20:00-21:00", "topic": "Answer Writing", "task": "Practice questions"},
        {"time": "21:00-21:30", "topic": "Revision", "task": "Review bookmarks"}
    ]'::JSONB,
    'draft'
FROM auth.users u
WHERE u.id NOT IN (SELECT DISTINCT user_id FROM study_plans)
LIMIT 1;

-- Print migration status
SELECT 'Phase 2 migration completed successfully' AS status;

-- List created tables
SELECT
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = 'public' AND table_name = t.table_name) AS column_count
FROM information_schema.tables t
WHERE table_schema = 'public'
  AND table_name IN (
    'book_conversions', 'chat_conversations', 'chat_messages',
    'user_bookmarks', 'revision_schedules', 'user_mindmaps',
    'confidence_scores', 'study_plans'
  )
ORDER BY table_name;



