-- Migration: 034_pyq_system.sql
-- Epic 8: PYQs & Question Bank (Stories 8.1-8.10)

-- Story 8.1 - PYQ Papers
CREATE TABLE IF NOT EXISTS public.pyq_papers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  year INTEGER NOT NULL,
  paper_type TEXT NOT NULL CHECK (paper_type IN ('Prelims', 'Mains_GS1', 'Mains_GS2', 'Mains_GS3', 'Mains_GS4', 'Essay')),
  file_url TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
  progress INTEGER DEFAULT 0,
  uploaded_by UUID ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Story 8.2 - PYQ Questions
CREATE TABLE IF NOT EXISTS public.pyq_questions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  paper_id UUID NOT NULL REFERENCES public.pyq_papers(id) ON DELETE CASCADE,
  question_number INTEGER NOT NULL,
  question_text TEXT NOT NULL,
  question_type TEXT CHECK (question_type IN ('MCQ', 'Descriptive')),
  options_json JSONB,
  correct_answer TEXT,
  marks INTEGER,
  word_limit INTEGER,
  subject TEXT,
  topic TEXT,
  difficulty TEXT DEFAULT 'medium' CHECK (difficulty IN ('easy', 'medium', 'hard')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Story 8.3 - Model Answers for PYQs
CREATE TABLE IF NOT EXISTS public.pyq_model_answers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  question_id UUID NOT NULL REFERENCES public.pyq_questions(id) ON DELETE CASCADE,
  answer_text TEXT NOT NULL,
  key_points TEXT[],
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Story 8.4 - PYQ Video Explanations
CREATE TABLE IF NOT EXISTS public.pyq_videos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  question_id UUID NOT NULL REFERENCES public.pyq_questions(id) ON DELETE CASCADE,
  video_url TEXT NOT NULL,
  duration_seconds INTEGER,
  status TEXT DEFAULT 'processing' CHECK (status IN ('processing', 'completed', 'failed')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Story 8.6 - AI Generated Questions
CREATE TABLE IF NOT EXISTS public.generated_questions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  topic TEXT NOT NULL,
  question_text TEXT NOT NULL,
  question_type TEXT NOT NULL,
  options_json JSONB,
  correct_answer TEXT,
  difficulty TEXT DEFAULT 'medium',
  created_by UUID ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Story 8.9 - Practice Sessions
CREATE TABLE IF NOT EXISTS public.practice_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL ,
  session_type TEXT NOT NULL CHECK (session_type IN ('pyq', 'topic', 'mock')),
  questions_json JSONB NOT NULL,
  answers_json JSONB,
  score INTEGER,
  total_questions INTEGER,
  time_taken_seconds INTEGER,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Story 8.10 - Question Bank Analytics
CREATE TABLE IF NOT EXISTS public.question_analytics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  question_id UUID NOT NULL,
  total_attempts INTEGER DEFAULT 0,
  correct_attempts INTEGER DEFAULT 0,
  avg_time_seconds INTEGER,
  difficulty_rating DECIMAL(3,2),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN
        CREATE INDEX idx_pyq_papers_year ON public.pyq_papers(year, paper_type);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX idx_pyq_questions_paper ON public.pyq_questions(paper_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX idx_pyq_questions_subject ON public.pyq_questions(subject, topic);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX idx_practice_sessions_user ON public.practice_sessions(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX idx_question_analytics_question ON public.question_analytics(question_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.pyq_papers ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.pyq_questions ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.pyq_model_answers ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.pyq_videos ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.generated_questions ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.practice_sessions ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.question_analytics ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Admins can manage PYQ papers" ON public.pyq_papers FOR ALL USING (
  EXISTS (SELECT 1 FROM public.user_profiles WHERE user_id = auth.uid() AND role = 'admin')
);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Anyone can view PYQ questions" ON public.pyq_questions FOR SELECT TO authenticated USING (true);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Anyone can view model answers" ON public.pyq_model_answers FOR SELECT TO authenticated USING (true);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Anyone can view PYQ videos" ON public.pyq_videos FOR SELECT TO authenticated USING (true);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can manage own practice sessions" ON public.practice_sessions FOR ALL USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Anyone can view question analytics" ON public.question_analytics FOR SELECT TO authenticated USING (true);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        COMMENT ON TABLE public.pyq_papers IS 'Uploaded PYQ PDF papers';
        COMMENT ON TABLE public.pyq_questions IS 'Extracted questions from PYQs';
        COMMENT ON TABLE public.practice_sessions IS 'User practice session records';
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


