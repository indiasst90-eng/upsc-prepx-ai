-- ============================================================================
-- Migration 066: Topic Difficulty Predictor - AI Prognosis
-- Story 14.2: Topic Difficulty Predictor
-- ============================================================================

-- ============================================================================
-- 1. TOPIC DEFINITIONS
-- ============================================================================

CREATE TABLE IF NOT EXISTS upsc_topics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  subject TEXT NOT NULL, -- polity, history, geography, economics, science, art_culture, environment, ethics
  paper TEXT NOT NULL, -- GS1, GS2, GS3, GS4, CSAT, Essay
  parent_topic_id UUID REFERENCES upsc_topics(id),
  syllabus_section TEXT,
  keywords TEXT[],
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_upsc_topics_subject ON upsc_topics(subject);
CREATE INDEX IF NOT EXISTS idx_upsc_topics_paper ON upsc_topics(paper);

-- ============================================================================
-- 2. HISTORICAL PYQ DATA (AC 1: 2010-2024)
-- ============================================================================

CREATE TABLE IF NOT EXISTS pyq_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  topic_id UUID REFERENCES upsc_topics(id) ON DELETE CASCADE,
  year INTEGER NOT NULL CHECK (year >= 2010 AND year <= 2030),
  question_count INTEGER NOT NULL DEFAULT 0,
  marks_total INTEGER DEFAULT 0,
  paper TEXT NOT NULL,
  difficulty_observed DECIMAL(3,1) CHECK (difficulty_observed >= 1 AND difficulty_observed <= 10),
  question_types JSONB DEFAULT '[]'::jsonb, -- ['MCQ', 'Short', 'Long', 'Essay']
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(topic_id, year, paper)
);

CREATE INDEX IF NOT EXISTS idx_pyq_history_topic_year ON pyq_history(topic_id, year DESC);

-- ============================================================================
-- 3. TOPIC DIFFICULTY PREDICTIONS (AC 2-4)
-- ============================================================================

CREATE TABLE IF NOT EXISTS topic_predictions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  topic_id UUID NOT NULL REFERENCES upsc_topics(id) ON DELETE CASCADE,
  difficulty_score DECIMAL(3,1) NOT NULL CHECK (difficulty_score >= 1 AND difficulty_score <= 10),
  weightage_prediction DECIMAL(5,2) DEFAULT 0, -- Expected % of marks in exam
  confidence_score DECIMAL(3,2) CHECK (confidence_score >= 0 AND confidence_score <= 1),
  predicted_questions INTEGER DEFAULT 0,
  time_recommendation_hours DECIMAL(4,1) DEFAULT 0, -- AC 6: Study time suggestion
  
  -- Factors contributing to prediction
  frequency_factor DECIMAL(3,2) DEFAULT 0, -- Based on PYQ frequency
  performance_factor DECIMAL(3,2) DEFAULT 0, -- Based on user performance
  relevance_factor DECIMAL(3,2) DEFAULT 0, -- Based on news/current affairs
  
  -- Trend data (AC 7)
  trend_direction TEXT CHECK (trend_direction IN ('rising', 'stable', 'declining')),
  trend_strength DECIMAL(3,2) DEFAULT 0,
  year_over_year_change DECIMAL(5,2) DEFAULT 0,
  
  -- Alert flags (AC 8)
  is_trending BOOLEAN DEFAULT false,
  alert_message TEXT,
  
  model_version TEXT DEFAULT '1.0',
  prediction_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  UNIQUE(topic_id, prediction_date)
);

CREATE INDEX IF NOT EXISTS idx_topic_predictions_topic ON topic_predictions(topic_id, prediction_date DESC);
CREATE INDEX IF NOT EXISTS idx_topic_predictions_trending ON topic_predictions(is_trending) WHERE is_trending = true;

-- ============================================================================
-- 4. USER PERFORMANCE DATA (for aggregate difficulty)
-- ============================================================================

CREATE TABLE IF NOT EXISTS topic_user_performance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  topic_id UUID NOT NULL REFERENCES upsc_topics(id) ON DELETE CASCADE,
  user_id UUID NOT NULL ,
  questions_attempted INTEGER DEFAULT 0,
  questions_correct INTEGER DEFAULT 0,
  average_time_seconds INTEGER,
  last_attempt_date DATE,
  proficiency_level TEXT CHECK (proficiency_level IN ('beginner', 'intermediate', 'advanced', 'mastered')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(topic_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_topic_perf_user ON topic_user_performance(user_id);

-- ============================================================================
-- 5. NEWS SIGNALS (for current relevance)
-- ============================================================================

CREATE TABLE IF NOT EXISTS topic_news_signals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  topic_id UUID NOT NULL REFERENCES upsc_topics(id) ON DELETE CASCADE,
  signal_date DATE NOT NULL,
  news_count INTEGER DEFAULT 0,
  relevance_score DECIMAL(3,2) DEFAULT 0,
  key_headlines TEXT[],
  source_urls TEXT[],
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(topic_id, signal_date)
);

-- ============================================================================
-- 6. PREDICTION REPORTS (AC 9: Export)
-- ============================================================================

CREATE TABLE IF NOT EXISTS prediction_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL ,
  report_type TEXT NOT NULL, -- 'full', 'subject', 'paper', 'custom'
  filter_criteria JSONB DEFAULT '{}',
  generated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  pdf_url TEXT,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- 7. MODEL TRAINING HISTORY (AC 10: Weekly retraining)
-- ============================================================================

CREATE TABLE IF NOT EXISTS prediction_model_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  model_version TEXT NOT NULL,
  trained_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  training_data_start DATE,
  training_data_end DATE,
  topics_count INTEGER,
  accuracy_score DECIMAL(4,3),
  model_parameters JSONB DEFAULT '{}',
  notes TEXT
);

-- ============================================================================
-- 8. SEED TOPICS (UPSC Syllabus Structure)
-- ============================================================================

INSERT INTO upsc_topics (name, subject, paper, keywords) VALUES
  -- Polity
  ('Constitution of India', 'polity', 'GS2', ARRAY['constitution', 'preamble', 'amendments']),
  ('Fundamental Rights', 'polity', 'GS2', ARRAY['rights', 'article 14-32', 'writs']),
  ('Directive Principles', 'polity', 'GS2', ARRAY['dpsp', 'article 36-51', 'welfare']),
  ('Parliament', 'polity', 'GS2', ARRAY['lok sabha', 'rajya sabha', 'bills']),
  ('Judiciary', 'polity', 'GS2', ARRAY['supreme court', 'high court', 'PIL']),
  ('Federalism', 'polity', 'GS2', ARRAY['centre-state', 'GST', 'schedules']),
  ('Local Governance', 'polity', 'GS2', ARRAY['panchayat', 'municipality', '73rd amendment']),
  
  -- History
  ('Ancient India', 'history', 'GS1', ARRAY['indus valley', 'vedic', 'maurya', 'gupta']),
  ('Medieval India', 'history', 'GS1', ARRAY['delhi sultanate', 'mughal', 'vijayanagara']),
  ('Modern India', 'history', 'GS1', ARRAY['british', 'freedom struggle', 'independence']),
  ('World History', 'history', 'GS1', ARRAY['world wars', 'colonialism', 'industrial revolution']),
  ('Art & Architecture', 'history', 'GS1', ARRAY['temples', 'paintings', 'sculpture']),
  
  -- Geography
  ('Physical Geography', 'geography', 'GS1', ARRAY['landforms', 'climate', 'drainage']),
  ('Human Geography', 'geography', 'GS1', ARRAY['population', 'settlement', 'migration']),
  ('Indian Geography', 'geography', 'GS1', ARRAY['physiography', 'rivers', 'minerals']),
  ('Economic Geography', 'geography', 'GS3', ARRAY['agriculture', 'industry', 'resources']),
  
  -- Economics
  ('Indian Economy', 'economics', 'GS3', ARRAY['GDP', 'inflation', 'fiscal policy']),
  ('Agriculture', 'economics', 'GS3', ARRAY['MSP', 'irrigation', 'land reforms']),
  ('Infrastructure', 'economics', 'GS3', ARRAY['transport', 'energy', 'telecom']),
  ('External Sector', 'economics', 'GS3', ARRAY['trade', 'FDI', 'balance of payments']),
  
  -- Science & Tech
  ('Space Technology', 'science', 'GS3', ARRAY['ISRO', 'satellites', 'missions']),
  ('Biotechnology', 'science', 'GS3', ARRAY['genetics', 'GMO', 'CRISPR']),
  ('IT & Computers', 'science', 'GS3', ARRAY['AI', 'cybersecurity', 'digital']),
  ('Defense Technology', 'science', 'GS3', ARRAY['missiles', 'nuclear', 'DRDO']),
  
  -- Environment
  ('Ecology', 'environment', 'GS3', ARRAY['ecosystem', 'biodiversity', 'conservation']),
  ('Climate Change', 'environment', 'GS3', ARRAY['global warming', 'Paris agreement', 'COP']),
  ('Pollution', 'environment', 'GS3', ARRAY['air', 'water', 'waste management']),
  ('Wildlife', 'environment', 'GS3', ARRAY['national parks', 'endangered species', 'CITES']),
  
  -- Ethics
  ('Ethics Basics', 'ethics', 'GS4', ARRAY['values', 'morality', 'integrity']),
  ('Aptitude', 'ethics', 'GS4', ARRAY['civil services aptitude', 'probity', 'attitude']),
  ('Case Studies', 'ethics', 'GS4', ARRAY['dilemmas', 'decision making', 'ethical frameworks']),
  ('Emotional Intelligence', 'ethics', 'GS4', ARRAY['EQ', 'empathy', 'self-awareness'])
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 9. SAMPLE PYQ HISTORY (2010-2024 for demonstration)
-- ============================================================================

-- Generate sample PYQ data for each topic
DO $$
DECLARE
  topic_rec RECORD;
  y INTEGER;
  base_count INTEGER;
  trend DECIMAL;
BEGIN
  FOR topic_rec IN SELECT id, subject FROM upsc_topics LOOP
    base_count := 2 + floor(random() * 5)::int;
    trend := (random() - 0.5) * 0.3; -- -0.15 to +0.15 annual trend
    
    FOR y IN 2010..2024 LOOP
      INSERT INTO pyq_history (topic_id, year, question_count, marks_total, paper, difficulty_observed)
      VALUES (
        topic_rec.id,
        y,
        GREATEST(0, base_count + floor((y - 2017) * trend + (random() - 0.5) * 2)::int),
        GREATEST(0, (base_count + floor((y - 2017) * trend)::int) * (10 + floor(random() * 10)::int)),
        CASE 
          WHEN topic_rec.subject = 'ethics' THEN 'GS4'
          WHEN topic_rec.subject IN ('economics', 'science', 'environment') THEN 'GS3'
          WHEN topic_rec.subject = 'polity' THEN 'GS2'
          ELSE 'GS1'
        END,
        3 + random() * 6 -- Difficulty between 3-9
      )
      ON CONFLICT (topic_id, year, paper) DO NOTHING;
    END LOOP;
  END LOOP;
END $$;

-- ============================================================================
-- 10. PREDICTION FUNCTIONS
-- ============================================================================

-- Calculate topic difficulty based on multiple factors
CREATE OR REPLACE FUNCTION calculate_topic_difficulty(p_topic_id UUID)
RETURNS TABLE (
  difficulty_score DECIMAL,
  weightage_prediction DECIMAL,
  confidence_score DECIMAL,
  time_recommendation DECIMAL,
  trend_direction TEXT,
  is_trending BOOLEAN
) AS $$
DECLARE
  v_frequency_score DECIMAL;
  v_performance_score DECIMAL;
  v_trend_value DECIMAL;
  v_recent_questions INTEGER;
  v_older_questions INTEGER;
BEGIN
  -- Calculate frequency factor (based on PYQ counts)
  SELECT 
    COALESCE(AVG(question_count), 0) INTO v_frequency_score
  FROM pyq_history 
  WHERE topic_id = p_topic_id AND year >= 2020;
  
  -- Calculate trend (compare recent 5 years vs older 5 years)
  SELECT COALESCE(SUM(question_count), 0) INTO v_recent_questions
  FROM pyq_history WHERE topic_id = p_topic_id AND year >= 2020;
  
  SELECT COALESCE(SUM(question_count), 0) INTO v_older_questions
  FROM pyq_history WHERE topic_id = p_topic_id AND year BETWEEN 2015 AND 2019;
  
  IF v_older_questions > 0 THEN
    v_trend_value := (v_recent_questions - v_older_questions)::decimal / v_older_questions;
  ELSE
    v_trend_value := 0;
  END IF;
  
  -- Calculate base difficulty from observed values
  SELECT COALESCE(AVG(difficulty_observed), 5) INTO difficulty_score
  FROM pyq_history WHERE topic_id = p_topic_id AND year >= 2018;
  
  -- Adjust based on frequency (more questions = more important = potentially harder)
  difficulty_score := LEAST(10, GREATEST(1, difficulty_score + (v_frequency_score - 3) * 0.2));
  
  -- Calculate weightage (expected % of questions)
  weightage_prediction := LEAST(15, v_frequency_score * 1.5);
  
  -- Confidence based on data availability
  SELECT 
    LEAST(1.0, COUNT(*)::decimal / 15) INTO confidence_score
  FROM pyq_history WHERE topic_id = p_topic_id;
  
  -- Time recommendation (hours = difficulty * 1.5 + frequency * 0.5)
  time_recommendation := difficulty_score * 1.5 + v_frequency_score * 0.5;
  
  -- Determine trend direction
  IF v_trend_value > 0.15 THEN
    trend_direction := 'rising';
    is_trending := true;
  ELSIF v_trend_value < -0.15 THEN
    trend_direction := 'declining';
    is_trending := false;
  ELSE
    trend_direction := 'stable';
    is_trending := false;
  END IF;
  
  -- Mark as trending if recent surge
  IF v_recent_questions > v_older_questions * 1.3 THEN
    is_trending := true;
  END IF;
  
  RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

-- Generate predictions for all topics
CREATE OR REPLACE FUNCTION generate_all_predictions()
RETURNS INTEGER AS $$
DECLARE
  topic_rec RECORD;
  pred_rec RECORD;
  count_updated INTEGER := 0;
BEGIN
  FOR topic_rec IN SELECT id, name FROM upsc_topics LOOP
    SELECT * INTO pred_rec FROM calculate_topic_difficulty(topic_rec.id);
    
    INSERT INTO topic_predictions (
      topic_id, difficulty_score, weightage_prediction, confidence_score,
      time_recommendation_hours, trend_direction, is_trending, prediction_date
    )
    VALUES (
      topic_rec.id, pred_rec.difficulty_score, pred_rec.weightage_prediction,
      pred_rec.confidence_score, pred_rec.time_recommendation, 
      pred_rec.trend_direction, pred_rec.is_trending, CURRENT_DATE
    )
    ON CONFLICT (topic_id, prediction_date) DO UPDATE SET
      difficulty_score = EXCLUDED.difficulty_score,
      weightage_prediction = EXCLUDED.weightage_prediction,
      confidence_score = EXCLUDED.confidence_score,
      time_recommendation_hours = EXCLUDED.time_recommendation_hours,
      trend_direction = EXCLUDED.trend_direction,
      is_trending = EXCLUDED.is_trending,
      updated_at = now();
    
    count_updated := count_updated + 1;
  END LOOP;
  
  RETURN count_updated;
END;
$$ LANGUAGE plpgsql;

-- Run initial prediction generation
SELECT generate_all_predictions();

-- Get predictions with alerts (AC 8)
CREATE OR REPLACE FUNCTION get_trending_topics(p_limit INTEGER DEFAULT 10)
RETURNS TABLE (
  topic_id UUID,
  topic_name TEXT,
  subject TEXT,
  difficulty_score DECIMAL,
  trend_direction TEXT,
  alert_message TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    t.id,
    t.name,
    t.subject,
    p.difficulty_score,
    p.trend_direction,
    CASE 
      WHEN p.trend_direction = 'rising' THEN 
        'This topic is trending up in PYQs, prioritize it!'
      WHEN p.is_trending THEN
        'High activity detected - focus on this topic'
      ELSE
        NULL
    END
  FROM topic_predictions p
  JOIN upsc_topics t ON t.id = p.topic_id
  WHERE p.prediction_date = CURRENT_DATE
    AND (p.is_trending = true OR p.trend_direction = 'rising')
  ORDER BY p.difficulty_score DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Get heatmap data (AC 5)
CREATE OR REPLACE FUNCTION get_difficulty_heatmap(p_subject TEXT DEFAULT NULL)
RETURNS TABLE (
  topic_id UUID,
  topic_name TEXT,
  subject TEXT,
  paper TEXT,
  difficulty_score DECIMAL,
  color_intensity INTEGER -- 1-10 for visualization
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    t.id,
    t.name,
    t.subject,
    t.paper,
    p.difficulty_score,
    CEIL(p.difficulty_score)::INTEGER
  FROM topic_predictions p
  JOIN upsc_topics t ON t.id = p.topic_id
  WHERE p.prediction_date = CURRENT_DATE
    AND (p_subject IS NULL OR t.subject = p_subject)
  ORDER BY t.subject, p.difficulty_score DESC;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 11. ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE upsc_topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE pyq_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE topic_predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE topic_user_performance ENABLE ROW LEVEL SECURITY;
ALTER TABLE topic_news_signals ENABLE ROW LEVEL SECURITY;
ALTER TABLE prediction_reports ENABLE ROW LEVEL SECURITY;

-- Public read for topics and predictions
CREATE POLICY "Anyone can read topics"
  ON upsc_topics FOR SELECT TO authenticated USING (true);

CREATE POLICY "Anyone can read PYQ history"
  ON pyq_history FOR SELECT TO authenticated USING (true);

CREATE POLICY "Anyone can read predictions"
  ON topic_predictions FOR SELECT TO authenticated USING (true);

CREATE POLICY "Anyone can read news signals"
  ON topic_news_signals FOR SELECT TO authenticated USING (true);

-- User-specific performance data
CREATE POLICY "Users can manage their performance data"
  ON topic_user_performance FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their reports"
  ON prediction_reports FOR ALL USING (auth.uid() = user_id);

-- ============================================================================
-- 12. SCHEDULED RETRAINING (AC 10)
-- ============================================================================

-- This would be triggered by a cron job or Edge Function
COMMENT ON FUNCTION generate_all_predictions() IS 
  'Should be called weekly via pg_cron or Edge Function to retrain predictions';

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

