-- Migration 040: MCQ Distractor System
-- Story 8.7: Question Bank - MCQ Distractor Generation
-- AC 8: question_options table for storing distractors and explanations

-- Question Options Table (for MCQ distractors)
CREATE TABLE IF NOT EXISTS public.question_options (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id UUID NOT NULL,  -- Can reference generated_questions or pyq_questions
  question_source TEXT NOT NULL CHECK (question_source IN ('generated', 'pyq')),
  option_letter CHAR(1) NOT NULL CHECK (option_letter IN ('A', 'B', 'C', 'D')),
  option_text TEXT NOT NULL,
  is_correct BOOLEAN NOT NULL DEFAULT false,
  explanation TEXT,  -- AC 7: Why this option is correct/incorrect
  distractor_type TEXT CHECK (distractor_type IN ('common_mistake', 'partial_truth', 'related_concept', 'factual_error', 'date_error')),
  quality_score DECIMAL(3,2) DEFAULT 0.50,  -- AC 9: Quality scoring
  times_selected INTEGER DEFAULT 0,  -- AC 9: Track selection rate
  times_shown INTEGER DEFAULT 0,
  is_reviewed BOOLEAN DEFAULT false,  -- AC 10: Admin review flag
  reviewed_by UUID ,
  reviewed_at TIMESTAMPTZ,
  generation_metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(question_id, question_source, option_letter)
);

-- Indexes for performance
CREATE INDEX idx_question_options_question ON public.question_options(question_id, question_source);
CREATE INDEX idx_question_options_correct ON public.question_options(is_correct);
CREATE INDEX idx_question_options_quality ON public.question_options(quality_score);
CREATE INDEX idx_question_options_reviewed ON public.question_options(is_reviewed);

-- Enable RLS
ALTER TABLE public.question_options ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Anyone can view question options"
  ON public.question_options FOR SELECT
  USING (true);

CREATE POLICY "Admins can manage question options"
  ON public.question_options FOR ALL
  USING (auth.jwt()->>'role' = 'admin');

-- Question Attempt Tracking (for quality scoring - AC 9)
CREATE TABLE IF NOT EXISTS public.question_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL ,
  question_id UUID NOT NULL,
  question_source TEXT NOT NULL CHECK (question_source IN ('generated', 'pyq')),
  selected_option CHAR(1) NOT NULL CHECK (selected_option IN ('A', 'B', 'C', 'D')),
  is_correct BOOLEAN NOT NULL,
  time_taken_seconds INTEGER,
  shuffled_order TEXT[],  -- AC 6: Store the shuffled order shown to user
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Schema migration for existing table (from 036)
DO $$ 
BEGIN
  -- Rename question_type to question_source if it exists
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'question_attempts' AND column_name = 'question_type') THEN
    ALTER TABLE public.question_attempts RENAME COLUMN question_type TO question_source;
  END IF;

  -- Add missing columns
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'question_attempts' AND column_name = 'selected_option') THEN
    ALTER TABLE public.question_attempts ADD COLUMN selected_option CHAR(1) CHECK (selected_option IN ('A', 'B', 'C', 'D'));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'question_attempts' AND column_name = 'shuffled_order') THEN
    ALTER TABLE public.question_attempts ADD COLUMN shuffled_order TEXT[];
  END IF;
  
  -- Make question_source nullable temporarily if we need to backfill, or just set it
  -- But here we assume renaming handled it. 
  -- If we created new, it's fine.
END $$;

CREATE INDEX IF NOT EXISTS idx_question_attempts_user ON public.question_attempts(user_id);
CREATE INDEX idx_question_attempts_question ON public.question_attempts(question_id, question_source);
CREATE INDEX idx_question_attempts_correct ON public.question_attempts(is_correct);

ALTER TABLE public.question_attempts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own attempts"
  ON public.question_attempts FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own attempts"
  ON public.question_attempts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Updated at trigger
CREATE TRIGGER update_question_options_updated_at
  BEFORE UPDATE ON public.question_options
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Function to shuffle options (AC 6)
CREATE OR REPLACE FUNCTION shuffle_question_options(p_question_id UUID, p_source TEXT)
RETURNS TABLE (
  option_letter CHAR(1),
  option_text TEXT,
  shuffled_position INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    qo.option_letter,
    qo.option_text,
    (ROW_NUMBER() OVER (ORDER BY random()))::INTEGER as shuffled_position
  FROM question_options qo
  WHERE qo.question_id = p_question_id 
    AND qo.question_source = p_source
  ORDER BY random();
END;
$$ LANGUAGE plpgsql;

-- Function to record attempt and update option stats (AC 9)
CREATE OR REPLACE FUNCTION record_question_attempt(
  p_user_id UUID,
  p_question_id UUID,
  p_source TEXT,
  p_selected_option CHAR(1),
  p_is_correct BOOLEAN,
  p_time_taken INTEGER,
  p_shuffled_order TEXT[]
)
RETURNS void AS $$
BEGIN
  -- Record the attempt
  INSERT INTO question_attempts (
    user_id, question_id, question_source, selected_option, 
    is_correct, time_taken_seconds, shuffled_order
  )
  VALUES (
    p_user_id, p_question_id, p_source, p_selected_option,
    p_is_correct, p_time_taken, p_shuffled_order
  );

  -- Update option statistics (times_shown for all, times_selected for chosen)
  UPDATE question_options
  SET times_shown = times_shown + 1
  WHERE question_id = p_question_id AND question_source = p_source;

  UPDATE question_options
  SET times_selected = times_selected + 1
  WHERE question_id = p_question_id 
    AND question_source = p_source 
    AND option_letter = p_selected_option;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to calculate and update quality scores (AC 9)
CREATE OR REPLACE FUNCTION update_distractor_quality(p_question_id UUID, p_source TEXT)
RETURNS void AS $$
DECLARE
  v_total_attempts INTEGER;
  v_correct_rate DECIMAL;
  v_option RECORD;
BEGIN
  -- Get total attempts for this question
  SELECT COUNT(*) INTO v_total_attempts
  FROM question_attempts
  WHERE question_id = p_question_id AND question_source = p_source;

  IF v_total_attempts < 10 THEN
    -- Not enough data yet
    RETURN;
  END IF;

  -- Calculate correct answer rate
  SELECT COUNT(*)::DECIMAL / v_total_attempts INTO v_correct_rate
  FROM question_attempts
  WHERE question_id = p_question_id 
    AND question_source = p_source 
    AND is_correct = true;

  -- Update quality scores for each distractor
  FOR v_option IN 
    SELECT * FROM question_options 
    WHERE question_id = p_question_id AND question_source = p_source AND is_correct = false
  LOOP
    -- Good distractors should attract some selections (20-40%)
    -- Too many selections = maybe correct answer is wrong
    -- Too few = too obviously wrong
    DECLARE
      v_selection_rate DECIMAL;
      v_new_quality DECIMAL;
    BEGIN
      IF v_option.times_shown > 0 THEN
        v_selection_rate := v_option.times_selected::DECIMAL / v_option.times_shown;
        
        -- Quality score: ideal is around 15-25% selection rate
        IF v_selection_rate BETWEEN 0.15 AND 0.25 THEN
          v_new_quality := 0.90;  -- Excellent distractor
        ELSIF v_selection_rate BETWEEN 0.10 AND 0.30 THEN
          v_new_quality := 0.75;  -- Good distractor
        ELSIF v_selection_rate BETWEEN 0.05 AND 0.40 THEN
          v_new_quality := 0.60;  -- Acceptable distractor
        ELSIF v_selection_rate < 0.05 THEN
          v_new_quality := 0.30;  -- Too obviously wrong
        ELSE
          v_new_quality := 0.40;  -- Too many selecting this (confusing)
        END IF;

        UPDATE question_options
        SET quality_score = v_new_quality
        WHERE id = v_option.id;
      END IF;
    END;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get questions needing distractor improvement (AC 9, AC 10)
CREATE OR REPLACE FUNCTION get_questions_needing_review(p_min_attempts INTEGER DEFAULT 20)
RETURNS TABLE (
  question_id UUID,
  question_source TEXT,
  avg_quality_score DECIMAL,
  total_attempts INTEGER,
  correct_rate DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    qa.question_id,
    qa.question_source,
    AVG(qo.quality_score)::DECIMAL as avg_quality_score,
    COUNT(DISTINCT qa.id)::INTEGER as total_attempts,
    (SUM(CASE WHEN qa.is_correct THEN 1 ELSE 0 END)::DECIMAL / COUNT(*)::DECIMAL) as correct_rate
  FROM question_attempts qa
  JOIN question_options qo ON qo.question_id = qa.question_id AND qo.question_source = qa.question_source
  GROUP BY qa.question_id, qa.question_source
  HAVING COUNT(DISTINCT qa.id) >= p_min_attempts
    AND (
      AVG(qo.quality_score) < 0.50  -- Low quality distractors
      OR (SUM(CASE WHEN qa.is_correct THEN 1 ELSE 0 END)::DECIMAL / COUNT(*)::DECIMAL) > 0.90  -- Too easy
      OR (SUM(CASE WHEN qa.is_correct THEN 1 ELSE 0 END)::DECIMAL / COUNT(*)::DECIMAL) < 0.20  -- Too hard
    )
  ORDER BY AVG(qo.quality_score) ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Comments
COMMENT ON TABLE public.question_options IS 'Story 8.7 AC 8: MCQ options/distractors with explanations';
COMMENT ON TABLE public.question_attempts IS 'Story 8.7 AC 9: Track question attempts for quality scoring';
COMMENT ON FUNCTION shuffle_question_options IS 'Story 8.7 AC 6: Randomize option order';
COMMENT ON FUNCTION record_question_attempt IS 'Story 8.7 AC 9: Record attempt and update stats';
COMMENT ON FUNCTION update_distractor_quality IS 'Story 8.7 AC 9: Calculate quality based on selection rates';
COMMENT ON FUNCTION get_questions_needing_review IS 'Story 8.7 AC 10: Find questions needing admin review';

