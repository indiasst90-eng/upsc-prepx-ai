-- Migration: 028_revision_quizzes.sql
-- Story: 6.6 - Revision Bundle Quick Quiz

CREATE TABLE IF NOT EXISTS public.revision_quizzes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL ,
  topic_id UUID NOT NULL REFERENCES public.topic_progress(id) ON DELETE CASCADE,
  questions_json JSONB NOT NULL,
  score INTEGER,
  total_questions INTEGER DEFAULT 10,
  time_taken_seconds INTEGER,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN
        CREATE INDEX idx_revision_quizzes_user ON public.revision_quizzes(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX idx_revision_quizzes_topic ON public.revision_quizzes(topic_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.revision_quizzes ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can manage own revision quizzes"
  ON public.revision_quizzes FOR ALL
  USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        COMMENT ON TABLE public.revision_quizzes IS 'Quick quizzes for revision targets';
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


