-- Migration 034: PYQ System Complete Schema (Enhanced for Story 8.5)
-- Stories 8.1-8.3: PYQ upload, extraction, model answers
-- Story 8.5 AC 9: Performance indexes for fast filtering

-- Table: pyq_papers
CREATE TABLE IF NOT EXISTS public.pyq_papers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  year INTEGER NOT NULL,
  paper_type TEXT NOT NULL CHECK (paper_type IN ('Prelims', 'Mains', 'Essay')),
  pdf_url TEXT,
  uploaded_by UUID ,
  uploaded_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  extraction_status TEXT DEFAULT 'pending' CHECK (extraction_status IN ('pending', 'processing', 'completed', 'failed')),
  UNIQUE(year, paper_type)
);

-- Table: pyq_questions (Enhanced with indexes)
CREATE TABLE IF NOT EXISTS public.pyq_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  paper_id UUID REFERENCES public.pyq_papers(id) ON DELETE CASCADE,
  year INTEGER NOT NULL,
  paper_type TEXT NOT NULL,
  number INTEGER NOT NULL,
  subject TEXT NOT NULL,
  topic TEXT,
  text TEXT NOT NULL,
  marks INTEGER,
  difficulty TEXT DEFAULT 'medium' CHECK (difficulty IN ('easy', 'medium', 'hard')),
  view_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Story 8.5 AC 9: Performance indexes for fast filtering
CREATE INDEX idx_pyq_questions_year ON public.pyq_questions(year DESC);
CREATE INDEX idx_pyq_questions_paper_type ON public.pyq_questions(paper_type);
CREATE INDEX idx_pyq_questions_subject ON public.pyq_questions(subject);
CREATE INDEX idx_pyq_questions_difficulty ON public.pyq_questions(difficulty);
CREATE INDEX idx_pyq_questions_topic ON public.pyq_questions(topic);
CREATE INDEX idx_pyq_questions_view_count ON public.pyq_questions(view_count DESC);
CREATE INDEX idx_pyq_questions_text_search ON public.pyq_questions USING gin(to_tsvector('english', text));
CREATE INDEX idx_pyq_questions_composite ON public.pyq_questions(year DESC, paper_type, subject, difficulty);

-- Table: pyq_model_answers
CREATE TABLE IF NOT EXISTS public.pyq_model_answers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id UUID NOT NULL REFERENCES public.pyq_questions(id) ON DELETE CASCADE,
  answer_text TEXT NOT NULL,
  answer_type TEXT DEFAULT 'ai_generated' CHECK (answer_type IN ('ai_generated', 'expert_verified', 'topper_answer')),
  sources TEXT[],
  generated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  verified_by UUID ,
  verified_at TIMESTAMPTZ
);

CREATE INDEX idx_pyq_model_answers_question_id ON public.pyq_model_answers(question_id);

-- RLS Policies
ALTER TABLE public.pyq_papers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pyq_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pyq_model_answers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view pyq papers"
  ON public.pyq_papers FOR SELECT
  USING (true);

CREATE POLICY "Admins can manage pyq papers"
  ON public.pyq_papers FOR ALL
  USING (auth.jwt()->>'role' = 'admin');

CREATE POLICY "Anyone can view pyq questions"
  ON public.pyq_questions FOR SELECT
  USING (true);

CREATE POLICY "Admins can manage pyq questions"
  ON public.pyq_questions FOR ALL
  USING (auth.jwt()->>'role' = 'admin');

CREATE POLICY "Anyone can view model answers"
  ON public.pyq_model_answers FOR SELECT
  USING (true);

CREATE POLICY "Admins can manage model answers"
  ON public.pyq_model_answers FOR ALL
  USING (auth.jwt()->>'role' = 'admin');

-- Updated at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_pyq_questions_updated_at
  BEFORE UPDATE ON public.pyq_questions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Comments
COMMENT ON TABLE public.pyq_papers IS 'Story 8.1: Uploaded PYQ PDF papers';
COMMENT ON TABLE public.pyq_questions IS 'Story 8.2: Extracted PYQ questions with Story 8.5 performance indexes';
COMMENT ON TABLE public.pyq_model_answers IS 'Story 8.3: AI-generated model answers for PYQs';
COMMENT ON INDEX idx_pyq_questions_text_search IS 'Story 8.5 AC 3: Full-text search index';
COMMENT ON INDEX idx_pyq_questions_composite IS 'Story 8.5 AC 9: Composite index for common filter combinations';

