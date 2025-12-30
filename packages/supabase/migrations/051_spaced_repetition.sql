-- Migration 051: Spaced Repetition Reminders
-- Story 9.9: SM-2 algorithm for bookmark review scheduling

-- ============================================
-- AC 3: Add review fields to bookmarks table
-- ============================================

ALTER TABLE public.bookmarks 
ADD COLUMN IF NOT EXISTS next_review_date TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS review_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS ease_factor DECIMAL(4,2) DEFAULT 2.5,
ADD COLUMN IF NOT EXISTS interval_days INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS last_reviewed_at TIMESTAMPTZ;

-- Index for daily scan (AC 4)
CREATE INDEX IF NOT EXISTS idx_bookmarks_next_review 
ON public.bookmarks(next_review_date)
WHERE next_review_date IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_bookmarks_due_review 
ON public.bookmarks(user_id, next_review_date)
WHERE next_review_date IS NOT NULL;

-- ============================================
-- REVIEW HISTORY TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.bookmark_reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL ,
  bookmark_id UUID NOT NULL REFERENCES public.bookmarks(id) ON DELETE CASCADE,
  
  -- Review result
  quality INTEGER NOT NULL CHECK (quality >= 0 AND quality <= 5),  -- SM-2 quality: 0-5
  response TEXT NOT NULL CHECK (response IN ('easy', 'medium', 'hard', 'again')),
  
  -- State before review
  previous_interval INTEGER,
  previous_ease_factor DECIMAL(4,2),
  
  -- State after review
  new_interval INTEGER,
  new_ease_factor DECIMAL(4,2),
  next_review_date TIMESTAMPTZ,
  
  -- Timing
  review_time_seconds INTEGER,
  reviewed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_bookmark_reviews_user ON public.bookmark_reviews(user_id);
CREATE INDEX idx_bookmark_reviews_bookmark ON public.bookmark_reviews(bookmark_id);
CREATE INDEX idx_bookmark_reviews_date ON public.bookmark_reviews(user_id, reviewed_at DESC);

-- RLS
ALTER TABLE public.bookmark_reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own reviews"
  ON public.bookmark_reviews FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own reviews"
  ON public.bookmark_reviews FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- ============================================
-- REVIEW STREAKS TABLE (AC 10)
-- ============================================

CREATE TABLE IF NOT EXISTS public.review_streaks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL  UNIQUE,
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  last_review_date DATE,
  total_reviews INTEGER DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_review_streaks_user ON public.review_streaks(user_id);

ALTER TABLE public.review_streaks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own streak"
  ON public.review_streaks FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can upsert own streak"
  ON public.review_streaks FOR ALL
  USING (auth.uid() = user_id);

-- ============================================
-- SM-2 ALGORITHM FUNCTIONS (AC 1)
-- ============================================

-- AC 2: Initial schedule intervals
-- Day 1, 3, 7, 14, 30, 60
CREATE OR REPLACE FUNCTION get_initial_interval(p_review_count INTEGER)
RETURNS INTEGER AS $$
BEGIN
  CASE p_review_count
    WHEN 0 THEN RETURN 1;
    WHEN 1 THEN RETURN 3;
    WHEN 2 THEN RETURN 7;
    WHEN 3 THEN RETURN 14;
    WHEN 4 THEN RETURN 30;
    ELSE RETURN 60;
  END CASE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- AC 1, 7, 8, 9: SM-2 algorithm implementation
CREATE OR REPLACE FUNCTION calculate_sm2_interval(
  p_current_interval INTEGER,
  p_ease_factor DECIMAL,
  p_quality INTEGER  -- 0-5 where 5=perfect, 0=complete blackout
)
RETURNS TABLE (
  new_interval INTEGER,
  new_ease_factor DECIMAL
) AS $$
DECLARE
  v_new_ef DECIMAL;
  v_new_interval INTEGER;
BEGIN
  -- Calculate new ease factor (minimum 1.3)
  v_new_ef := p_ease_factor + (0.1 - (5 - p_quality) * (0.08 + (5 - p_quality) * 0.02));
  v_new_ef := GREATEST(v_new_ef, 1.3);
  
  -- Calculate new interval
  IF p_quality < 3 THEN
    -- AC 8: If "Hard" (quality < 3), reset to 1 day
    v_new_interval := 1;
  ELSE
    IF p_current_interval = 1 THEN
      v_new_interval := 3;
    ELSIF p_current_interval = 3 THEN
      v_new_interval := 7;
    ELSE
      -- AC 9: If "Easy" (quality >= 4), multiply by ease factor
      v_new_interval := ROUND(p_current_interval * v_new_ef)::INTEGER;
    END IF;
  END IF;
  
  -- Cap maximum interval at 365 days
  v_new_interval := LEAST(v_new_interval, 365);
  
  RETURN QUERY SELECT v_new_interval, ROUND(v_new_ef, 2)::DECIMAL;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Convert response to quality
CREATE OR REPLACE FUNCTION response_to_quality(p_response TEXT)
RETURNS INTEGER AS $$
BEGIN
  CASE p_response
    WHEN 'easy' THEN RETURN 5;
    WHEN 'medium' THEN RETURN 3;
    WHEN 'hard' THEN RETURN 2;
    WHEN 'again' THEN RETURN 0;
    ELSE RETURN 3;
  END CASE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- AC 7: Process a review and update bookmark
CREATE OR REPLACE FUNCTION process_bookmark_review(
  p_user_id UUID,
  p_bookmark_id UUID,
  p_response TEXT,  -- 'easy', 'medium', 'hard', 'again'
  p_review_time_seconds INTEGER DEFAULT NULL
)
RETURNS TABLE (
  success BOOLEAN,
  new_interval INTEGER,
  next_review TIMESTAMPTZ
) AS $$
DECLARE
  v_bookmark RECORD;
  v_quality INTEGER;
  v_sm2 RECORD;
  v_next_review TIMESTAMPTZ;
BEGIN
  -- Get current bookmark state
  SELECT * INTO v_bookmark
  FROM public.bookmarks
  WHERE id = p_bookmark_id AND user_id = p_user_id;
  
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 0, NULL::TIMESTAMPTZ;
    RETURN;
  END IF;
  
  -- Convert response to SM-2 quality
  v_quality := response_to_quality(p_response);
  
  -- Calculate new interval using SM-2
  SELECT * INTO v_sm2 FROM calculate_sm2_interval(
    COALESCE(v_bookmark.interval_days, 1),
    COALESCE(v_bookmark.ease_factor, 2.5),
    v_quality
  );
  
  -- Calculate next review date
  v_next_review := NOW() + (v_sm2.new_interval || ' days')::INTERVAL;
  
  -- Record the review
  INSERT INTO public.bookmark_reviews (
    user_id, bookmark_id, quality, response,
    previous_interval, previous_ease_factor,
    new_interval, new_ease_factor, next_review_date,
    review_time_seconds
  ) VALUES (
    p_user_id, p_bookmark_id, v_quality, p_response,
    COALESCE(v_bookmark.interval_days, 1), COALESCE(v_bookmark.ease_factor, 2.5),
    v_sm2.new_interval, v_sm2.new_ease_factor, v_next_review,
    p_review_time_seconds
  );
  
  -- Update bookmark
  UPDATE public.bookmarks SET
    review_count = COALESCE(review_count, 0) + 1,
    interval_days = v_sm2.new_interval,
    ease_factor = v_sm2.new_ease_factor,
    next_review_date = v_next_review,
    last_reviewed_at = NOW(),
    updated_at = NOW()
  WHERE id = p_bookmark_id;
  
  -- Update streak
  PERFORM update_review_streak(p_user_id);
  
  RETURN QUERY SELECT TRUE, v_sm2.new_interval, v_next_review;
END;
$$ LANGUAGE plpgsql;

-- AC 10: Update review streak
CREATE OR REPLACE FUNCTION update_review_streak(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
  v_streak RECORD;
  v_today DATE := CURRENT_DATE;
BEGIN
  SELECT * INTO v_streak FROM public.review_streaks WHERE user_id = p_user_id;
  
  IF NOT FOUND THEN
    -- Create new streak record
    INSERT INTO public.review_streaks (user_id, current_streak, longest_streak, last_review_date, total_reviews)
    VALUES (p_user_id, 1, 1, v_today, 1);
  ELSIF v_streak.last_review_date = v_today THEN
    -- Already reviewed today, just increment total
    UPDATE public.review_streaks SET 
      total_reviews = total_reviews + 1,
      updated_at = NOW()
    WHERE user_id = p_user_id;
  ELSIF v_streak.last_review_date = v_today - 1 THEN
    -- Consecutive day, increment streak
    UPDATE public.review_streaks SET
      current_streak = current_streak + 1,
      longest_streak = GREATEST(longest_streak, current_streak + 1),
      last_review_date = v_today,
      total_reviews = total_reviews + 1,
      updated_at = NOW()
    WHERE user_id = p_user_id;
  ELSE
    -- Streak broken, reset to 1
    UPDATE public.review_streaks SET
      current_streak = 1,
      last_review_date = v_today,
      total_reviews = total_reviews + 1,
      updated_at = NOW()
    WHERE user_id = p_user_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- AC 4: Get bookmarks due for review today
CREATE OR REPLACE FUNCTION get_due_bookmarks(
  p_user_id UUID,
  p_limit INTEGER DEFAULT 50
)
RETURNS TABLE (
  id UUID,
  title TEXT,
  snippet TEXT,
  content_type TEXT,
  content_id UUID,
  review_count INTEGER,
  ease_factor DECIMAL,
  interval_days INTEGER,
  next_review_date TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    b.id,
    b.title,
    b.snippet,
    b.content_type,
    b.content_id,
    COALESCE(b.review_count, 0),
    COALESCE(b.ease_factor, 2.5),
    COALESCE(b.interval_days, 1),
    b.next_review_date
  FROM public.bookmarks b
  WHERE b.user_id = p_user_id
    AND (
      b.next_review_date IS NULL  -- New bookmarks
      OR b.next_review_date <= NOW()  -- Due bookmarks
    )
  ORDER BY b.next_review_date ASC NULLS FIRST
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- AC 4: Count due bookmarks (for notification)
CREATE OR REPLACE FUNCTION count_due_bookmarks(p_user_id UUID)
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COUNT(*)::INTEGER
    FROM public.bookmarks
    WHERE user_id = p_user_id
      AND (next_review_date IS NULL OR next_review_date <= NOW())
  );
END;
$$ LANGUAGE plpgsql;

-- Initialize new bookmarks for review
CREATE OR REPLACE FUNCTION initialize_bookmark_review(p_bookmark_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE public.bookmarks SET
    next_review_date = NOW() + INTERVAL '1 day',
    review_count = 0,
    ease_factor = 2.5,
    interval_days = 1
  WHERE id = p_bookmark_id
    AND next_review_date IS NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Auto-initialize review on bookmark creation
CREATE OR REPLACE FUNCTION trigger_init_bookmark_review()
RETURNS TRIGGER AS $$
BEGIN
  NEW.next_review_date := NOW() + INTERVAL '1 day';
  NEW.review_count := 0;
  NEW.ease_factor := 2.5;
  NEW.interval_days := 1;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS bookmark_init_review_trigger ON public.bookmarks;
CREATE TRIGGER bookmark_init_review_trigger
  BEFORE INSERT ON public.bookmarks
  FOR EACH ROW
  EXECUTE FUNCTION trigger_init_bookmark_review();

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON FUNCTION calculate_sm2_interval IS 'Story 9.9 AC 1: SM-2 algorithm implementation';
COMMENT ON FUNCTION process_bookmark_review IS 'Story 9.9 AC 7: Process review and update schedule';
COMMENT ON FUNCTION get_due_bookmarks IS 'Story 9.9 AC 4: Daily scan for due bookmarks';
COMMENT ON FUNCTION update_review_streak IS 'Story 9.9 AC 10: Track consecutive review days';

