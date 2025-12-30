-- Migration: 033_answer_evaluation_system.sql
-- Stories: 7.2-7.10 - Complete Answer & Essay Evaluation System

-- Story 7.2 - Answer Evaluations
CREATE TABLE IF NOT EXISTS public.answer_evaluations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  submission_id UUID NOT NULL REFERENCES public.answer_submissions(id) ON DELETE CASCADE,
  content_score INTEGER CHECK (content_score >= 0 AND content_score <= 10),
  structure_score INTEGER CHECK (structure_score >= 0 AND structure_score <= 10),
  language_score INTEGER CHECK (language_score >= 0 AND language_score <= 10),
  examples_score INTEGER CHECK (examples_score >= 0 AND examples_score <= 10),
  total_score INTEGER,
  feedback_json JSONB,
  video_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Story 7.4 - Model Answers
CREATE TABLE IF NOT EXISTS public.model_answers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  question_id UUID NOT NULL,
  answer_text TEXT NOT NULL,
  word_count INTEGER,
  key_points TEXT[],
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Story 7.5 - Essay Submissions
CREATE TABLE IF NOT EXISTS public.essay_submissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL ,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  word_count INTEGER,
  status TEXT DEFAULT 'submitted',
  submitted_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Story 7.6 - Essay Evaluations
CREATE TABLE IF NOT EXISTS public.essay_evaluations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  essay_id UUID NOT NULL REFERENCES public.essay_submissions(id) ON DELETE CASCADE,
  introduction_score INTEGER,
  body_score INTEGER,
  conclusion_score INTEGER,
  coherence_score INTEGER,
  total_score INTEGER,
  feedback_json JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Story 7.8 - Test Series
CREATE TABLE IF NOT EXISTS public.test_series (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  description TEXT,
  paper TEXT,
  duration_minutes INTEGER,
  total_marks INTEGER,
  questions_json JSONB,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.test_attempts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL ,
  test_id UUID NOT NULL REFERENCES public.test_series(id) ON DELETE CASCADE,
  answers_json JSONB,
  score INTEGER,
  time_taken_seconds INTEGER,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Story 7.10 - Performance Analytics
CREATE TABLE IF NOT EXISTS public.performance_analytics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL ,
  metric_type TEXT NOT NULL,
  metric_value DECIMAL(10,2),
  period TEXT,
  data_json JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN
        CREATE INDEX idx_answer_evaluations_submission ON public.answer_evaluations(submission_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX idx_essay_submissions_user ON public.essay_submissions(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX idx_test_attempts_user ON public.test_attempts(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX idx_performance_analytics_user ON public.performance_analytics(user_id, metric_type);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.answer_evaluations ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.model_answers ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.essay_submissions ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.essay_evaluations ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.test_series ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.test_attempts ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.performance_analytics ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can view own evaluations" ON public.answer_evaluations FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.answer_submissions WHERE id = submission_id AND user_id = auth.uid())
);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Anyone can view model answers" ON public.model_answers FOR SELECT TO authenticated USING (true);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can manage own essays" ON public.essay_submissions FOR ALL USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can view own essay evaluations" ON public.essay_evaluations FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.essay_submissions WHERE id = essay_id AND user_id = auth.uid())
);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Anyone can view active tests" ON public.test_series FOR SELECT TO authenticated USING (is_active = true);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can manage own test attempts" ON public.test_attempts FOR ALL USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can view own analytics" ON public.performance_analytics FOR SELECT USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        COMMENT ON TABLE public.answer_evaluations IS 'AI evaluations of answer submissions';
        COMMENT ON TABLE public.model_answers IS 'Model answers for questions';
        COMMENT ON TABLE public.essay_submissions IS 'User essay submissions';
        COMMENT ON TABLE public.test_series IS 'Test series platform';
        COMMENT ON TABLE public.performance_analytics IS 'User performance metrics';
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


