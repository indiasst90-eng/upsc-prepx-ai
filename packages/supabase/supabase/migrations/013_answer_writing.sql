-- Answer Writing & Practice Features Migration
-- Date: December 26, 2025
-- Features: Answer submissions, AI evaluation, Essay trainer, MCQ, Mock tests

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- PRACTICE QUESTIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS practice_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_text TEXT NOT NULL,
    question_type TEXT NOT NULL CHECK (question_type IN ('mcq', 'answer', 'essay')),
    gs_paper TEXT CHECK (gs_paper IN ('GS Paper I', 'GS Paper II', 'GS Paper III', 'GS Paper IV', 'CSAT')),
    syllabus_topic TEXT,
    difficulty TEXT CHECK (difficulty IN ('easy', 'medium', 'hard')),
    -- Answer/Essay specific
    word_limit INTEGER DEFAULT 200,
    time_limit_minutes INTEGER DEFAULT 12,
    -- MCQ specific
    options JSONB DEFAULT '[]',
    correct_answer INTEGER,
    explanation TEXT,
    -- PYQ specific
    is_pyq BOOLEAN DEFAULT FALSE,
    pyq_year INTEGER,
    -- Metadata
    source TEXT,
    tags TEXT[] DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for practice_questions
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_practice_questions_type ON practice_questions(question_type);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_practice_questions_paper ON practice_questions(gs_paper);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_practice_questions_topic ON practice_questions(syllabus_topic);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_practice_questions_difficulty ON practice_questions(difficulty);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_practice_questions_pyq ON practice_questions(is_pyq) WHERE is_pyq = TRUE;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================
-- DAILY QUESTIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS daily_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_id UUID NOT NULL REFERENCES practice_questions(id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    gs_paper TEXT NOT NULL,
    word_limit INTEGER DEFAULT 200,
    time_limit_minutes INTEGER DEFAULT 12,
    difficulty TEXT,
    syllabus_topic TEXT,
    date DATE NOT NULL,
    UNIQUE(gs_paper, date)
);

-- Indexes for daily_questions
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_daily_questions_date ON daily_questions(date);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_daily_questions_paper ON daily_questions(gs_paper);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================
-- ANSWER SUBMISSIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS answer_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    question_id UUID,
    -- Question info (frozen at submission time)
    question_text TEXT NOT NULL,
    gs_paper TEXT,
    syllabus_topic TEXT,
    -- Answer data
    answer_text TEXT NOT NULL,
    word_count INTEGER NOT NULL,
    word_limit INTEGER,
    time_taken_seconds INTEGER DEFAULT 0,
    -- Evaluation
    evaluation_enabled BOOLEAN DEFAULT TRUE,
    evaluation_status TEXT DEFAULT 'pending' CHECK (evaluation_status IN ('pending', 'processing', 'completed', 'failed', 'disabled')),
    evaluation_id UUID,
    -- Draft
    is_draft BOOLEAN DEFAULT FALSE,
    last_saved_at TIMESTAMP WITH TIME ZONE,
    -- Timestamps
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN
        ALTER TABLE answer_submissions ADD COLUMN IF NOT EXISTS question_text TEXT;
        ALTER TABLE answer_submissions ADD COLUMN IF NOT EXISTS gs_paper TEXT;
        ALTER TABLE answer_submissions ADD COLUMN IF NOT EXISTS syllabus_topic TEXT;
        ALTER TABLE answer_submissions ADD COLUMN IF NOT EXISTS answer_text TEXT;
        ALTER TABLE answer_submissions ADD COLUMN IF NOT EXISTS evaluation_status TEXT DEFAULT 'pending' CHECK (evaluation_status IN ('pending', 'processing', 'completed', 'failed', 'disabled'));
        ALTER TABLE answer_submissions ADD COLUMN IF NOT EXISTS evaluation_enabled BOOLEAN DEFAULT TRUE;
        ALTER TABLE answer_submissions ADD COLUMN IF NOT EXISTS evaluation_id UUID;
        ALTER TABLE answer_submissions ADD COLUMN IF NOT EXISTS is_draft BOOLEAN DEFAULT FALSE;
        ALTER TABLE answer_submissions ADD COLUMN IF NOT EXISTS last_saved_at TIMESTAMP WITH TIME ZONE;
        ALTER TABLE answer_submissions ADD COLUMN IF NOT EXISTS word_count INTEGER;
        ALTER TABLE answer_submissions ADD COLUMN IF NOT EXISTS word_limit INTEGER;
        ALTER TABLE answer_submissions ADD COLUMN IF NOT EXISTS time_taken_seconds INTEGER DEFAULT 0;
        ALTER TABLE answer_submissions ADD COLUMN IF NOT EXISTS submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Add FK constraints safely
DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'users') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'answer_submissions_user_id_fkey') THEN
            ALTER TABLE answer_submissions ADD CONSTRAINT answer_submissions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        END IF;
    END IF;
EXCEPTION WHEN others THEN NULL;
END $$;

DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'practice_questions') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'answer_submissions_question_id_fkey') THEN
            ALTER TABLE answer_submissions ADD CONSTRAINT answer_submissions_question_id_fkey FOREIGN KEY (question_id) REFERENCES practice_questions(id) ON DELETE CASCADE;
        END IF;
    END IF;
EXCEPTION WHEN others THEN NULL;
END $$;

-- Indexes for answer_submissions
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_answer_submissions_user ON answer_submissions(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_answer_submissions_status ON answer_submissions(evaluation_status);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_answer_submissions_date ON answer_submissions(submitted_at DESC);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_answer_submissions_paper ON answer_submissions(gs_paper);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================
-- ANSWER EVALUATIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS answer_evaluations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    submission_id UUID NOT NULL REFERENCES answer_submissions(id) ON DELETE CASCADE,
    -- Rubric scores (0-10 each)
    content_score DECIMAL(3,1) NOT NULL CHECK (content_score BETWEEN 0 AND 10),
    structure_score DECIMAL(3,1) NOT NULL CHECK (structure_score BETWEEN 0 AND 10),
    language_score DECIMAL(3,1) NOT NULL CHECK (language_score BETWEEN 0 AND 10),
    examples_score DECIMAL(3,1) NOT NULL CHECK (examples_score BETWEEN 0 AND 10),
    -- Total (sum of above, out of 40)
    total_score DECIMAL(4,1) NOT NULL,
    -- Feedback as JSON
    feedback_json JSONB DEFAULT '{}',
    -- Processing metadata
    status TEXT DEFAULT 'completed' CHECK (status IN ('processing', 'completed', 'failed')),
    error_message TEXT,
    processing_time_seconds DECIMAL(6,2),
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Indexes for answer_evaluations
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_answer_evaluations_submission ON answer_evaluations(submission_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_answer_evaluations_score ON answer_evaluations(total_score DESC);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================
-- ESSAY SUBMISSIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS essay_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    -- Essay topic
    topic TEXT NOT NULL,
    topic_category TEXT,
    -- Essay content
    essay_text TEXT NOT NULL,
    word_count INTEGER NOT NULL,
    word_limit INTEGER DEFAULT 1000,
    time_taken_seconds INTEGER DEFAULT 0,
    -- Evaluation
    evaluation_status TEXT DEFAULT 'pending' CHECK (evaluation_status IN ('pending', 'processing', 'completed', 'failed')),
    -- Scores
    thesis_score DECIMAL(3,1),
    argument_score DECIMAL(3,1),
    evidence_score DECIMAL(3,1),
    structure_score DECIMAL(3,1),
    language_score DECIMAL(3,1),
    total_score DECIMAL(4,1),
    feedback_json JSONB DEFAULT '{}',
    -- Timestamps
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN
        ALTER TABLE essay_submissions ADD COLUMN IF NOT EXISTS topic TEXT;
    EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'Error adding topic: %', SQLERRM; END;
    BEGIN
        ALTER TABLE essay_submissions ADD COLUMN IF NOT EXISTS essay_text TEXT;
    EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'Error adding essay_text: %', SQLERRM; END;
    BEGIN
        ALTER TABLE essay_submissions ADD COLUMN IF NOT EXISTS evaluation_status TEXT DEFAULT 'pending';
    EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'Error adding evaluation_status: %', SQLERRM; END;
    BEGIN
        ALTER TABLE essay_submissions ADD COLUMN IF NOT EXISTS word_count INTEGER;
    EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'Error adding word_count: %', SQLERRM; END;
END $migration$;

DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'users') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'essay_submissions_user_id_fkey') THEN
            ALTER TABLE essay_submissions ADD CONSTRAINT essay_submissions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        END IF;
    END IF;
EXCEPTION WHEN others THEN NULL;
END $$;

-- Indexes for essay_submissions
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_essay_submissions_user ON essay_submissions(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_essay_submissions_category ON essay_submissions(topic_category);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_essay_submissions_date ON essay_submissions(submitted_at DESC);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================
-- QUIZ ATTEMPTS TABLE (MCQ & Daily Quiz)
-- ============================================
CREATE TABLE IF NOT EXISTS quiz_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    quiz_type TEXT NOT NULL CHECK (quiz_type IN ('daily', 'topic', 'mock', 'pyq')),
    -- Quiz metadata
    topic TEXT,
    gs_paper TEXT,
    total_questions INTEGER NOT NULL,
    correct_answers INTEGER DEFAULT 0,
    score DECIMAL(5,2) GENERATED ALWAYS AS (
        CASE
            WHEN total_questions > 0 THEN (correct_answers * 100.0 / total_questions)
            ELSE 0
        END
    ) STORED,
    -- Timing
    time_taken_seconds INTEGER DEFAULT 0,
    -- Confidence data
    avg_confidence DECIMAL(3,2),
    -- Timestamps
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'users') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'quiz_attempts_user_id_fkey') THEN
            ALTER TABLE quiz_attempts ADD CONSTRAINT quiz_attempts_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        END IF;
    END IF;
EXCEPTION WHEN others THEN NULL;
END $$;

-- Indexes for quiz_attempts
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_quiz_attempts_user ON quiz_attempts(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_quiz_attempts_type ON quiz_attempts(quiz_type);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_quiz_attempts_topic ON quiz_attempts(topic);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_quiz_attempts_date ON quiz_attempts(completed_at DESC);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================
-- QUIZ ANSWERS TABLE (Individual answers)
-- ============================================
CREATE TABLE IF NOT EXISTS quiz_answers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    attempt_id UUID NOT NULL REFERENCES quiz_attempts(id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES practice_questions(id) ON DELETE CASCADE,
    -- User's answer
    selected_option INTEGER NOT NULL,
    is_correct BOOLEAN NOT NULL,
    -- Confidence (1-5 before answering, actual after)
    pre_confidence INTEGER CHECK (pre_confidence BETWEEN 1 AND 5),
    post_confidence INTEGER CHECK (post_confidence BETWEEN 1 AND 5),
    -- Timestamps
    answered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for quiz_answers
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_quiz_answers_attempt ON quiz_answers(attempt_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_quiz_answers_question ON quiz_answers(question_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================
-- MOCK TESTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS mock_tests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    -- Test info
    test_type TEXT NOT NULL CHECK (test_type IN ('gs1', 'gs2', 'gs3', 'gs4', 'csat', 'full')),
    test_name TEXT,
    -- Questions included
    question_ids UUID[] DEFAULT '{}',
    -- Timing
    time_limit_minutes INTEGER NOT NULL,
    time_taken_seconds INTEGER DEFAULT 0,
    -- Scoring
    total_questions INTEGER DEFAULT 0,
    attempted_questions INTEGER DEFAULT 0,
    correct_answers INTEGER DEFAULT 0,
    score DECIMAL(5,2) DEFAULT 0,
    -- Status
    status TEXT DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed', 'abandoned')),
    -- Ranking (updated periodically)
    all_india_rank INTEGER,
    percentile DECIMAL(5,2),
    -- Timestamps
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

DO $$ BEGIN
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
        CREATE INDEX IF NOT EXISTS idx_mock_tests_rank ON mock_tests(all_india_rank) WHERE all_india_rank IS NOT NULL;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================
-- STUDY SESSIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS study_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    -- Session info
    session_type TEXT NOT NULL CHECK (session_type IN ('study', 'revision', 'quiz', 'answer_writing', 'mock_test', 'video')),
    topic TEXT,
    gs_paper TEXT,
    -- Duration
    duration_minutes INTEGER NOT NULL,
    -- Metadata
    notes TEXT,
    completed_tasks INTEGER DEFAULT 0,
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'users') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'study_sessions_user_id_fkey') THEN
            ALTER TABLE study_sessions ADD CONSTRAINT study_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        END IF;
    END IF;
EXCEPTION WHEN others THEN NULL;
END $$;

-- Indexes for study_sessions
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_study_sessions_user ON study_sessions(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_study_sessions_type ON study_sessions(session_type);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_study_sessions_date ON study_sessions(created_at DESC);
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
        ALTER TABLE practice_questions ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE daily_questions ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE answer_submissions ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE answer_evaluations ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE essay_submissions ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE quiz_attempts ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE quiz_answers ENABLE ROW LEVEL SECURITY;
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
        ALTER TABLE study_sessions ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Practice questions - public read access
DO $$ BEGIN
    
CREATE POLICY "Anyone can view practice questions" ON practice_questions
        FOR SELECT USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
END $$;

-- Daily questions - public read access
DO $$ BEGIN
    
CREATE POLICY "Anyone can view daily questions" ON daily_questions
        FOR SELECT USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
END $$;

-- Answer submissions - user only
DO $$ BEGIN
    
CREATE POLICY "Users can view own answer submissions" ON answer_submissions
        FOR SELECT USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
END $$;

DO $$ BEGIN
    
CREATE POLICY "Users can manage own answer submissions" ON answer_submissions
        FOR ALL USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
END $$;

-- Answer evaluations - user only (via submission)
DO $$ BEGIN
    
CREATE POLICY "Users can view own answer evaluations" ON answer_evaluations
        FOR SELECT USING (
            EXISTS (SELECT 1 FROM answer_submissions WHERE id = answer_evaluations.submission_id AND user_id = auth.uid())
        );
EXCEPTION WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
END $$;

-- Essay submissions - user only
DO $$ BEGIN
    
CREATE POLICY "Users can view own essay submissions" ON essay_submissions
        FOR SELECT USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
END $$;

DO $$ BEGIN
    
CREATE POLICY "Users can manage own essay submissions" ON essay_submissions
        FOR ALL USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
END $$;

-- Quiz attempts - user only
DO $$ BEGIN
    
CREATE POLICY "Users can view own quiz attempts" ON quiz_attempts
        FOR SELECT USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
END $$;

DO $$ BEGIN
    
CREATE POLICY "Users can manage own quiz attempts" ON quiz_attempts
        FOR ALL USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
END $$;

-- Quiz answers - user only (via attempt)
DO $$ BEGIN
    
CREATE POLICY "Users can view own quiz answers" ON quiz_answers
        FOR SELECT USING (
            EXISTS (SELECT 1 FROM quiz_attempts WHERE id = quiz_answers.attempt_id AND user_id = auth.uid())
        );
EXCEPTION WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
END $$;

DO $$ BEGIN
    
CREATE POLICY "Users can manage own quiz answers" ON quiz_answers
        FOR ALL USING (
            EXISTS (SELECT 1 FROM quiz_attempts WHERE id = quiz_answers.attempt_id AND user_id = auth.uid())
        );
EXCEPTION WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
END $$;

-- Mock tests - user only
DO $$ BEGIN
    
CREATE POLICY "Users can view own mock tests" ON mock_tests
        FOR SELECT USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
END $$;

DO $$ BEGIN
    
CREATE POLICY "Users can manage own mock tests" ON mock_tests
        FOR ALL USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
END $$;

-- Study sessions - user only
DO $$ BEGIN
    
CREATE POLICY "Users can view own study sessions" ON study_sessions
        FOR SELECT USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
END $$;

DO $$ BEGIN
    
CREATE POLICY "Users can manage own study sessions" ON study_sessions
        FOR ALL USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
END $$;

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Calculate word count
DO $migration$ BEGIN
    BEGIN
        CREATE OR REPLACE FUNCTION calculate_word_count(text_value TEXT)
RETURNS INTEGER AS $$
BEGIN
    RETURN array_length(regexp_split_to_array(trim(text_value), '\s+'), 1);
END;
$$ LANGUAGE plpgsql;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Update submission word count
DO $migration$ BEGIN
    BEGIN
        CREATE OR REPLACE FUNCTION update_submission_word_count()
RETURNS TRIGGER AS $$
BEGIN
    NEW.word_count = calculate_word_count(NEW.answer_text);
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
        CREATE TRIGGER update_answer_submission_word_count
    BEFORE INSERT OR UPDATE OF answer_text ON answer_submissions
    FOR EACH ROW EXECUTE FUNCTION update_submission_word_count();
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Update essay word count
DO $migration$ BEGIN
    BEGIN
        CREATE OR REPLACE FUNCTION update_essay_word_count()
RETURNS TRIGGER AS $$
BEGIN
    NEW.word_count = calculate_word_count(NEW.essay_text);
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
        CREATE TRIGGER update_essay_word_count
    BEFORE INSERT OR UPDATE OF essay_text ON essay_submissions
    FOR EACH ROW EXECUTE FUNCTION update_essay_word_count();
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Calculate quiz score
DO $migration$ BEGIN
    BEGIN
        CREATE OR REPLACE FUNCTION calculate_quiz_score()
RETURNS TRIGGER AS $$
BEGIN
    NEW.score = CASE
        WHEN NEW.total_questions > 0 THEN (NEW.correct_answers * 100.0 / NEW.total_questions)
        ELSE 0
    END;
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
        CREATE TRIGGER update_quiz_score
    BEFORE INSERT OR UPDATE ON quiz_attempts
    FOR EACH ROW EXECUTE FUNCTION calculate_quiz_score();
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================
-- SEED DATA: Sample Practice Questions
-- ============================================

INSERT INTO practice_questions (question_text, question_type, gs_paper, syllabus_topic, difficulty, word_limit, time_limit_minutes, tags)
VALUES
    -- GS Paper I Questions
    ('Discuss the impact of British colonial policies on Indian agriculture. How did these policies shape the rural economy?', 'answer', 'GS Paper I', 'Colonial Period', 'medium', 250, 15, ARRAY['colonial', 'agriculture', 'economy']),
    ('Analyze the factors responsible for the rise of separatist movements in India post-independence.', 'answer', 'GS Paper I', 'Post-Independence', 'medium', 200, 12, ARRAY['separatism', 'independence', 'politics']),
    ('Explain the geographical factors that influence the distribution of rainfall in India.', 'answer', 'GS Paper I', 'Geography', 'easy', 150, 10, ARRAY['geography', 'rainfall', 'climate']),
    -- GS Paper II Questions
    ('Discuss the significance of the 73rd and 74th Constitutional Amendments in decentralized governance.', 'answer', 'GS Paper II', 'Governance', 'medium', 250, 15, ARRAY['constitution', 'panchayat', 'local government']),
    ('Evaluate the challenges in the implementation of the Right to Education Act.', 'answer', 'GS Paper II', 'Social Justice', 'medium', 200, 12, ARRAY['education', 'RTE', 'social policy']),
    -- GS Paper III Questions
    ('Analyze the impact of GST on the Indian economy and its challenges.', 'answer', 'GS Paper III', 'Economy', 'hard', 250, 15, ARRAY['GST', 'economy', 'taxation']),
    ('Discuss the measures taken by India to achieve energy security and the role of renewables.', 'answer', 'GS Paper III', 'Energy', 'medium', 200, 12, ARRAY['energy', 'renewables', 'security']),
    -- GS Paper IV Questions
    ('"Ethics is not a separate domain but is integrated into every aspect of governance." Comment.', 'answer', 'GS Paper IV', 'Ethics', 'medium', 200, 12, ARRAY['ethics', 'governance', 'accountability'])
ON CONFLICT DO NOTHING;

-- Print migration status
SELECT 'Answer writing migration completed successfully' AS status;

-- Show created tables
SELECT table_name, (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = 'public' AND table_name = t.table_name) AS column_count
FROM information_schema.tables t
WHERE table_schema = 'public'
  AND table_name IN (
    'practice_questions', 'daily_questions', 'answer_submissions', 'answer_evaluations',
    'essay_submissions', 'quiz_attempts', 'quiz_answers', 'mock_tests', 'study_sessions'
  )
ORDER BY table_name;



