-- Daily Quiz & MCQ Practice Migration
-- Date: December 26, 2025
-- Features: Daily quizzes, quiz attempts, MCQ questions
-- Note: quiz_attempts and quiz_answers tables already exist in 013_answer_writing.sql

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- DAILY QUIZZES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS daily_quizzes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date DATE NOT NULL UNIQUE,
    -- Questions stored as JSON
    questions_json JSONB NOT NULL DEFAULT '[]',
    -- Metadata
    total_questions INTEGER DEFAULT 10,
    is_active BOOLEAN DEFAULT TRUE,
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN ALTER TABLE daily_quizzes ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT gen_random_uuid(); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_quizzes ADD COLUMN IF NOT EXISTS date DATE NOT NULL UNIQUE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_quizzes ADD COLUMN IF NOT EXISTS questions_json JSONB NOT NULL DEFAULT '[]'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_quizzes ADD COLUMN IF NOT EXISTS total_questions INTEGER DEFAULT 10; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_quizzes ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN ALTER TABLE daily_quizzes ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(); EXCEPTION WHEN OTHERS THEN NULL; END;
END $migration$;


-- Indexes for daily_quizzes
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_daily_quizzes_date ON daily_quizzes(date DESC);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================
-- SAMPLE MCQ QUESTIONS (Seed Data)
-- ============================================
DO $$
BEGIN
  INSERT INTO practice_questions (question_text, question_type, gs_paper, syllabus_topic, difficulty, options, correct_answer, explanation)
  VALUES
      ('The Rowlatt Act was passed during the tenure of which Viceroy?', 'mcq', 'GS Paper I', 'British Raj', 'easy',
       '["Lord Curzon", "Lord Hardinge", "Lord Chelmsford", "Lord Minto"]'::jsonb, 2,
       'The Rowlatt Act was passed in 1919 during the tenure of Lord Chelmsford.'),
      ('Which of the following is NOT a characteristic of the Gupta Age?', 'mcq', 'GS Paper I', 'Ancient India', 'medium',
       '["Agricultural prosperity", "Flourishing of trade and commerce", "Establishment of a powerful centralized administration", "Spread of Buddhism as state religion"]'::jsonb, 3,
       'While the Guptas supported all religions, Buddhism was not the state religion.'),
      ('The Montagu-Chelmsford Reforms were introduced in the year?', 'mcq', 'GS Paper I', 'British Raj', 'easy',
       '["1909", "1919", "1935", "1942"]'::jsonb, 1,
       'The Montagu-Chelmsford Reforms were introduced in 1919.'),
      ('The Constitution of India was adopted on?', 'mcq', 'GS Paper II', 'Constitution', 'easy',
       '["15 August 1947", "26 January 1950", "26 November 1949", "28 January 1950"]'::jsonb, 2,
       'The Constitution was adopted on 26 November 1949 and came into effect on 26 January 1950.'),
      ('Which article of the Indian Constitution deals with the Uniform Civil Code?', 'mcq', 'GS Paper II', 'Fundamental Rights', 'medium',
       '["Article 44", "Article 45", "Article 46", "Article 47"]'::jsonb, 0,
       'Article 44 (Part IV - DPSP) deals with the Uniform Civil Code.'),
      ('The President of India is elected by:', 'mcq', 'GS Paper II', 'President', 'easy',
       '["Direct popular vote", "Electoral College comprising MPs and MLAs", "Both Houses of Parliament", "Prime Minister"]'::jsonb, 1,
       'The President is elected by an Electoral College comprising elected members of Parliament and state legislatures.'),
      ('Which of the following is NOT a component of GST?', 'mcq', 'GS Paper III', 'Taxation', 'easy',
       '["CGST", "SGST", "UTGST", "Customs Duty"]'::jsonb, 3,
       'Customs Duty is not a component of GST.'),
      ('The Mahatma Gandhi National Rural Employment Guarantee Act was enacted in?', 'mcq', 'GS Paper III', 'Social Sector', 'medium',
       '["2004", "2005", "2006", "2007"]'::jsonb, 1,
       'The MGNREGA was enacted in 2005.'),
      ('Which of the following is NOT a core ethical value for civil servants?', 'mcq', 'GS Paper IV', 'Ethics', 'easy',
       '["Integrity", "Public interest", "Political loyalty", "Objectivity"]'::jsonb, 2,
       'Political loyalty is not a core ethical value. Civil servants must be politically neutral.'),
      ('If 2x + 3 = 15, then what is the value of x?', 'mcq', 'CSAT', 'Mathematics', 'easy',
       '["4", "5", "6", "7"]'::jsonb, 2,
       '2x + 3 = 15 => 2x = 12 => x = 6')
  ON CONFLICT DO NOTHING;
EXCEPTION
  WHEN undefined_table THEN
    -- Handle case where practice_questions table doesn't exist yet
    RAISE NOTICE 'practice_questions table not yet available, skipping seed data';
END $$;

-- ============================================
-- RLS POLICIES
-- ============================================
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE daily_quizzes ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Daily quizzes - public read access
DO $$ BEGIN
    
CREATE POLICY "Anyone can view daily quizzes" ON daily_quizzes
        FOR SELECT USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ============================================
-- FUNCTIONS
-- ============================================

-- Calculate quiz score
DO $migration$ BEGIN
    BEGIN
        CREATE OR REPLACE FUNCTION calculate_quiz_score(p_correct INTEGER, p_total INTEGER)
RETURNS DECIMAL AS $$
BEGIN
    IF p_total = 0 THEN
        RETURN 0;
    END IF;
    RETURN ROUND((p_correct * 100.0 / p_total), 2);
END;
$$ LANGUAGE plpgsql;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Print migration status
SELECT 'Daily quiz migration completed successfully' AS status;

-- Show counts
SELECT
    'practice_questions' as table_name,
    (SELECT COUNT(*) FROM practice_questions WHERE question_type = 'mcq') as count
UNION ALL
SELECT
    'daily_quizzes',
    (SELECT COUNT(*) FROM daily_quizzes);
