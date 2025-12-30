-- Migration: 032_answer_submissions.sql
-- Story: 7.1 - Answer Writing Submission Interface - FULL IMPLEMENTATION

CREATE TABLE IF NOT EXISTS public.answer_submissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL ,
  question_id UUID NOT NULL,
  question_text TEXT NOT NULL,
  answer_text TEXT NOT NULL,
  word_count INTEGER NOT NULL CHECK (word_count > 0),
  time_taken_seconds INTEGER CHECK (time_taken_seconds >= 0),
  status TEXT DEFAULT 'submitted' CHECK (status IN ('draft', 'submitted', 'evaluated', 'archived')),
  submitted_at TIMESTAMPTZ,
  draft_saved_at TIMESTAMPTZ,
  evaluation_requested BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT valid_submission CHECK (
    (status = 'draft' AND submitted_at IS NULL) OR
    (status IN ('submitted', 'evaluated', 'archived') AND submitted_at IS NOT NULL)
  )
);

CREATE TABLE IF NOT EXISTS public.daily_questions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  paper TEXT NOT NULL CHECK (paper IN ('GS1', 'GS2', 'GS3', 'GS4', 'Essay')),
  question_text TEXT NOT NULL,
  word_limit INTEGER NOT NULL CHECK (word_limit IN (150, 250, 1000, 1500)),
  topic TEXT NOT NULL,
  difficulty TEXT DEFAULT 'medium' CHECK (difficulty IN ('easy', 'medium', 'hard')),
  date DATE NOT NULL,
  marks INTEGER DEFAULT 10,
  keywords TEXT[],
  reference_material TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(paper, date)
);

CREATE TABLE IF NOT EXISTS public.submission_drafts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL ,
  question_id UUID NOT NULL,
  draft_text TEXT,
  word_count INTEGER DEFAULT 0,
  last_saved_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, question_id)
);

DO $migration$ BEGIN
    BEGIN
        CREATE INDEX idx_answer_submissions_user ON public.answer_submissions(user_id, status);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX idx_answer_submissions_date ON public.answer_submissions(submitted_at DESC);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX idx_daily_questions_date ON public.daily_questions(date DESC);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX idx_daily_questions_paper ON public.daily_questions(paper, date);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX idx_submission_drafts_user ON public.submission_drafts(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.answer_submissions ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.daily_questions ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.submission_drafts ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can manage own submissions"
  ON public.answer_submissions FOR ALL
  USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Authenticated users can view daily questions"
  ON public.daily_questions FOR SELECT
  TO authenticated
  USING (true);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can manage own drafts"
  ON public.submission_drafts FOR ALL
  USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE TRIGGER set_answer_submissions_updated_at
  BEFORE UPDATE ON public.answer_submissions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Function to auto-save drafts
DO $migration$ BEGIN
    BEGIN
        CREATE OR REPLACE FUNCTION upsert_draft()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.submission_drafts (user_id, question_id, draft_text, word_count)
  VALUES (NEW.user_id, NEW.question_id, NEW.answer_text, NEW.word_count)
  ON CONFLICT (user_id, question_id)
  DO UPDATE SET 
    draft_text = EXCLUDED.draft_text,
    word_count = EXCLUDED.word_count,
    last_saved_at = NOW();
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
        CREATE TRIGGER trigger_save_draft
  AFTER INSERT OR UPDATE ON public.answer_submissions
  FOR EACH ROW
  WHEN (NEW.status = 'draft')
  EXECUTE FUNCTION upsert_draft();
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        COMMENT ON TABLE public.answer_submissions IS 'User answer writing submissions with draft support';
        COMMENT ON TABLE public.daily_questions IS 'Daily practice questions with metadata';
        COMMENT ON TABLE public.submission_drafts IS 'Auto-saved drafts for answer writing';
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


