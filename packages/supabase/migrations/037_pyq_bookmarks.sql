-- Migration 037: PYQ Bookmarking System (Enhanced)
-- Story 8.5 AC 7: Users can bookmark questions for later review

CREATE TABLE IF NOT EXISTS public.pyq_bookmarks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL ,
  question_id UUID NOT NULL REFERENCES public.pyq_questions(id) ON DELETE CASCADE,
  notes TEXT,
  tags TEXT[],
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, question_id)
);

CREATE INDEX idx_pyq_bookmarks_user_id ON public.pyq_bookmarks(user_id);
CREATE INDEX idx_pyq_bookmarks_question_id ON public.pyq_bookmarks(question_id);
CREATE INDEX idx_pyq_bookmarks_created_at ON public.pyq_bookmarks(created_at DESC);
CREATE INDEX idx_pyq_bookmarks_tags ON public.pyq_bookmarks USING gin(tags);

ALTER TABLE public.pyq_bookmarks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own bookmarks"
  ON public.pyq_bookmarks FOR ALL
  USING (auth.uid() = user_id);

CREATE TRIGGER update_pyq_bookmarks_updated_at
  BEFORE UPDATE ON public.pyq_bookmarks
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

COMMENT ON TABLE public.pyq_bookmarks IS 'Story 8.5 AC 7: Bookmark PYQ questions for later review';
COMMENT ON COLUMN public.pyq_bookmarks.tags IS 'User-defined tags for organizing bookmarks';

