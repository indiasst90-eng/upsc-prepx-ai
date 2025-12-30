-- Mock Tests & Confidence Meter Migration
-- Date: December 26, 2025
-- Features: Mock tests, confidence tracking, analytics

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- MOCK TEST TEMPLATES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS mock_tests_template (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    test_type TEXT NOT NULL CHECK (test_type IN ('gs1', 'gs2', 'gs3', 'gs4', 'csat', 'full')),
    test_name TEXT NOT NULL,
    -- Questions stored as JSON
    questions_json JSONB NOT NULL DEFAULT '[]',
    -- Configuration
    time_limit_minutes INTEGER NOT NULL DEFAULT 120,
    total_questions INTEGER NOT NULL DEFAULT 20,
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN ALTER TABLE mock_tests_template ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT gen_random_uuid(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE mock_tests_template ADD COLUMN IF NOT EXISTS test_type TEXT NOT NULL CHECK (test_type IN ('gs1', 'gs2', 'gs3', 'gs4', 'csat', 'full')); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE mock_tests_template ADD COLUMN IF NOT EXISTS test_name TEXT NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE mock_tests_template ADD COLUMN IF NOT EXISTS questions_json JSONB NOT NULL DEFAULT '[]'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE mock_tests_template ADD COLUMN IF NOT EXISTS time_limit_minutes INTEGER NOT NULL DEFAULT 120; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE mock_tests_template ADD COLUMN IF NOT EXISTS total_questions INTEGER NOT NULL DEFAULT 20; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE mock_tests_template ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE mock_tests_template ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
END $migration$;


-- Indexes for mock_tests_template
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_mock_tests_template_type ON mock_tests_template(test_type);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_mock_tests_template_active ON mock_tests_template(is_active);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================
-- MOCK TESTS (User Attempts)
-- ============================================
CREATE TABLE IF NOT EXISTS mock_tests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL ,
    -- Test info
    test_type TEXT NOT NULL,
    test_name TEXT,
    -- Questions
    question_ids UUID[] DEFAULT '{}',
    total_questions INTEGER NOT NULL DEFAULT 0,
    -- Timing
    time_limit_minutes INTEGER NOT NULL DEFAULT 120,
    time_taken_seconds INTEGER DEFAULT 0,
    -- Progress
    attempted_questions INTEGER DEFAULT 0,
    correct_answers INTEGER DEFAULT 0,
    -- Score
    score DECIMAL(5,2) DEFAULT 0,
    -- Ranking
    all_india_rank INTEGER,
    percentile DECIMAL(5,2),
    -- Confidence metrics
    avg_confidence DECIMAL(3,2),
    confidence_accuracy_correlation DECIMAL(5,2),
    -- Status
    status TEXT DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed', 'abandoned')),
    -- Timestamps
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN ALTER TABLE mock_tests ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT gen_random_uuid(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE mock_tests ADD COLUMN IF NOT EXISTS user_id UUID NOT NULL ; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE mock_tests ADD COLUMN IF NOT EXISTS test_type TEXT NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE mock_tests ADD COLUMN IF NOT EXISTS question_ids UUID[] DEFAULT '{}'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE mock_tests ADD COLUMN IF NOT EXISTS total_questions INTEGER NOT NULL DEFAULT 0; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE mock_tests ADD COLUMN IF NOT EXISTS time_limit_minutes INTEGER NOT NULL DEFAULT 120; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE mock_tests ADD COLUMN IF NOT EXISTS time_taken_seconds INTEGER DEFAULT 0; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE mock_tests ADD COLUMN IF NOT EXISTS attempted_questions INTEGER DEFAULT 0; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE mock_tests ADD COLUMN IF NOT EXISTS correct_answers INTEGER DEFAULT 0; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE mock_tests ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed', 'abandoned')); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE mock_tests ADD COLUMN IF NOT EXISTS started_at TIMESTAMP WITH TIME ZONE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE mock_tests ADD COLUMN IF NOT EXISTS completed_at TIMESTAMP WITH TIME ZONE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE mock_tests ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
END $migration$;


-- Add foreign keys if referenced tables exist
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'users') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'mock_tests_user_id_fkey') THEN
            ALTER TABLE mock_tests ADD CONSTRAINT mock_tests_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        END IF;
    END IF;
EXCEPTION WHEN others THEN NULL;
END $$;


-- Indexes for mock_tests
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_mock_tests_user ON mock_tests(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_mock_tests_type ON mock_tests(test_type);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_mock_tests_status ON mock_tests(status);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_mock_tests_score ON mock_tests(score DESC);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_mock_tests_rank ON mock_tests(all_india_rank) WHERE all_india_rank IS NOT NULL;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================
-- CONFIDENCE RECORDS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS confidence_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL ,
    -- Context
    context_type TEXT NOT NULL CHECK (context_type IN ('quiz', 'mock_test', 'answer_writing', 'pyq')),
    context_id TEXT NOT NULL, -- question_id or attempt_id
    question_id UUID,
    -- Confidence data
    pre_confidence INTEGER NOT NULL CHECK (pre_confidence BETWEEN 1 AND 5),
    post_confidence INTEGER CHECK (post_confidence BETWEEN 1 AND 5),
    -- Outcome
    is_correct BOOLEAN,
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN ALTER TABLE confidence_records ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT gen_random_uuid(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE confidence_records ADD COLUMN IF NOT EXISTS user_id UUID NOT NULL ; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE confidence_records ADD COLUMN IF NOT EXISTS context_type TEXT NOT NULL CHECK (context_type IN ('quiz', 'mock_test', 'answer_writing', 'pyq')); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE confidence_records ADD COLUMN IF NOT EXISTS context_id TEXT NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE confidence_records ADD COLUMN IF NOT EXISTS pre_confidence INTEGER NOT NULL CHECK (pre_confidence BETWEEN 1 AND 5); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE confidence_records ADD COLUMN IF NOT EXISTS post_confidence INTEGER CHECK (post_confidence BETWEEN 1 AND 5); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE confidence_records ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
END $migration$;


-- Add foreign keys if referenced tables exist
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'users') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'confidence_records_user_id_fkey') THEN
            ALTER TABLE confidence_records ADD CONSTRAINT confidence_records_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        END IF;
    END IF;
EXCEPTION WHEN others THEN NULL;
END $$;

-- Indexes for confidence_records
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_confidence_records_user ON confidence_records(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_confidence_records_context ON confidence_records(context_type, context_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_confidence_records_created ON confidence_records(created_at DESC);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================
-- CONFIDENCE ANALYTICS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS confidence_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL ,
    -- Period
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    -- Metrics
    total_questions INTEGER NOT NULL,
    correct_count INTEGER NOT NULL,
    accuracy DECIMAL(5,2) NOT NULL,
    avg_confidence DECIMAL(3,2) NOT NULL,
    confidence_accuracy_correlation DECIMAL(5,2),
    -- Calibration
    high_confidence_correct INTEGER,
    high_confidence_incorrect INTEGER,
    low_confidence_correct INTEGER,
    low_confidence_incorrect INTEGER,
    -- Timestamps
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, period_start, period_end)
);

DO $migration$ BEGIN
    BEGIN ALTER TABLE confidence_analytics ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT gen_random_uuid(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE confidence_analytics ADD COLUMN IF NOT EXISTS user_id UUID NOT NULL ; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE confidence_analytics ADD COLUMN IF NOT EXISTS period_start DATE NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE confidence_analytics ADD COLUMN IF NOT EXISTS period_end DATE NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE confidence_analytics ADD COLUMN IF NOT EXISTS total_questions INTEGER NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE confidence_analytics ADD COLUMN IF NOT EXISTS correct_count INTEGER NOT NULL; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE confidence_analytics ADD COLUMN IF NOT EXISTS calculated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
END $migration$;


-- Add foreign keys if referenced tables exist
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'users') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'confidence_analytics_user_id_fkey') THEN
            ALTER TABLE confidence_analytics ADD CONSTRAINT confidence_analytics_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        END IF;
    END IF;
EXCEPTION WHEN others THEN NULL;
END $$;

-- Indexes for confidence_analytics
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_confidence_analytics_user ON confidence_analytics(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_confidence_analytics_period ON confidence_analytics(period_start, period_end);
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
        ALTER TABLE mock_tests_template ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE mock_tests ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE confidence_records ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE confidence_analytics ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Mock test templates - public read access

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Anyone can view mock test templates" ON mock_tests_template
    FOR SELECT USING (true);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Mock tests - user only

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can view own mock tests" ON mock_tests
    FOR SELECT USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can manage own mock tests" ON mock_tests
    FOR ALL USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Confidence records - user only

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can view own confidence records" ON confidence_records
    FOR SELECT USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can manage own confidence records" ON confidence_records
    FOR ALL USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Confidence analytics - user only

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can view own confidence analytics" ON confidence_analytics
    FOR SELECT USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can manage own confidence analytics" ON confidence_analytics
    FOR ALL USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================
-- FUNCTIONS AND TRIGGERS
-- ============================================

-- Update mock test score
DO $migration$ BEGIN
    BEGIN
        CREATE OR REPLACE FUNCTION update_mock_test_score()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.total_questions > 0 THEN
        NEW.score = ROUND((NEW.correct_answers * 100.0 / NEW.total_questions), 2);
    END IF;
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
        CREATE TRIGGER update_mock_test_score_trigger
    BEFORE INSERT OR UPDATE ON mock_tests
    FOR EACH ROW EXECUTE FUNCTION update_mock_test_score();
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Calculate confidence calibration
DO $migration$ BEGIN
    BEGIN
        CREATE OR REPLACE FUNCTION calculate_confidence_calibration(p_user_id UUID, p_start_date DATE, p_end_date DATE)
RETURNS JSONB AS $$
DECLARE
    v_total INTEGER := 0;
    v_correct INTEGER := 0;
    v_avg_confidence DECIMAL := 0;
    v_correlation DECIMAL := 0;
    v_high_correct INTEGER := 0;
    v_high_incorrect INTEGER := 0;
    v_low_correct INTEGER := 0;
    v_low_incorrect INTEGER := 0;
    v_result JSONB;
BEGIN
    -- Get confidence records for period
    SELECT
        COUNT(*) INTO v_total,
        SUM(CASE WHEN is_correct THEN 1 ELSE 0 END) INTO v_correct,
        AVG(pre_confidence) INTO v_avg_confidence
    FROM confidence_records
    WHERE user_id = p_user_id
      AND created_at::DATE >= p_start_date
      AND created_at::DATE <= p_end_date
      AND is_correct IS NOT NULL;

    -- Calculate calibration
    SELECT
        SUM(CASE WHEN pre_confidence >= 4 AND is_correct THEN 1 ELSE 0 END) INTO v_high_correct,
        SUM(CASE WHEN pre_confidence >= 4 AND NOT is_correct THEN 1 ELSE 0 END) INTO v_high_incorrect,
        SUM(CASE WHEN pre_confidence <= 2 AND is_correct THEN 1 ELSE 0 END) INTO v_low_correct,
        SUM(CASE WHEN pre_confidence <= 2 AND NOT is_correct THEN 1 ELSE 0 END) INTO v_low_incorrect
    FROM confidence_records
    WHERE user_id = p_user_id
      AND created_at::DATE >= p_start_date
      AND created_at::DATE <= p_end_date
      AND is_correct IS NOT NULL;

    -- Calculate correlation (simplified)
    v_correlation := CASE
        WHEN v_total > 0 THEN
            ROUND(
                ((v_high_correct * 1.0 + v_low_correct * 1.0) / NULLIF(v_total, 0) * 100) -
                (((v_high_correct + v_low_correct) * 1.0 / NULLIF(v_total, 0) * 100) *
                 (v_correct * 1.0 / NULLIF(v_total, 0) * 100) / 100)
                , 2
            )
        ELSE 0
    END;

    v_result := jsonb_build_object(
        'total_questions', v_total,
        'correct_answers', v_correct,
        'accuracy', ROUND((v_correct * 100.0 / NULLIF(v_total, 0)), 2),
        'avg_confidence', ROUND(v_avg_confidence, 2),
        'correlation', v_correlation,
        'high_confidence', jsonb_build_object(
            'correct', v_high_correct,
            'incorrect', v_high_incorrect,
            'accuracy', ROUND((v_high_correct * 100.0 / NULLIF(v_high_correct + v_high_incorrect, 0)), 2)
        ),
        'low_confidence', jsonb_build_object(
            'correct', v_low_correct,
            'incorrect', v_low_incorrect,
            'accuracy', ROUND((v_low_correct * 100.0 / NULLIF(v_low_correct + v_low_incorrect, 0)), 2)
        )
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================
-- HELPER VIEW: Confidence Dashboard
-- ============================================
CREATE OR REPLACE VIEW confidence_dashboard AS
SELECT
    user_id,
    COUNT(*) as total_questions,
    SUM(CASE WHEN is_correct THEN 1 ELSE 0 END) as correct_answers,
    ROUND(AVG(pre_confidence)::numeric, 2) as avg_pre_confidence,
    ROUND(AVG(CASE WHEN is_correct = true THEN pre_confidence ELSE NULL END)::numeric, 2) as avg_confidence_correct,
    ROUND(AVG(CASE WHEN is_correct = false THEN pre_confidence ELSE NULL END)::numeric, 2) as avg_confidence_incorrect,
    COUNT(CASE WHEN pre_confidence >= 4 AND is_correct = true THEN 1 ELSE NULL END) as high_conf_correct,
    COUNT(CASE WHEN pre_confidence >= 4 AND is_correct = false THEN 1 ELSE NULL END) as high_conf_incorrect,
    COUNT(CASE WHEN pre_confidence <= 2 AND is_correct = true THEN 1 ELSE NULL END) as low_conf_correct,
    COUNT(CASE WHEN pre_confidence <= 2 AND is_correct = false THEN 1 ELSE NULL END) as low_conf_incorrect,
    ROUND(
        (COUNT(CASE WHEN pre_confidence >= 4 AND is_correct = true THEN 1 ELSE NULL END)::decimal /
         NULLIF(COUNT(CASE WHEN pre_confidence >= 4 THEN 1 ELSE NULL END), 0) * 100)::numeric, 2
    ) as high_conf_accuracy,
    ROUND(
        (COUNT(CASE WHEN pre_confidence <= 2 AND is_correct = true THEN 1 ELSE NULL END)::decimal /
         NULLIF(COUNT(CASE WHEN pre_confidence <= 2 THEN 1 ELSE NULL END), 0) * 100)::numeric, 2
    ) as low_conf_accuracy
FROM confidence_records
WHERE is_correct IS NOT NULL
GROUP BY user_id;

-- Print migration status
SELECT 'Mock tests migration completed successfully' AS status;

-- Show tables
SELECT table_name, (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = 'public' AND table_name = t.table_name) AS column_count
FROM information_schema.tables t
WHERE table_schema = 'public'
  AND table_name IN ('mock_tests_template', 'mock_tests', 'confidence_records', 'confidence_analytics')
ORDER BY table_name;


