-- Migration 061: Ethics Simulator Multi-Stage Advanced
-- Story 12.2: Ethics Simulator - Multi-Stage Advanced
-- 
-- Implements:
-- AC 1: Multi-stage flow
-- AC 2: Personality analysis
-- AC 3: Scoring dimensions
-- AC 4: Report card
-- AC 5: Improvement suggestions
-- AC 6: Interview prep questions
-- AC 7: Peer comparison
-- AC 8: Difficulty levels
-- AC 9: Video summary
-- AC 10: Retry options

-- =================================================================
-- SIMULATION SCENARIOS TABLE (AC 1, 8)
-- =================================================================
CREATE TABLE IF NOT EXISTS simulation_scenarios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Basic info
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  context TEXT NOT NULL,
  
  -- AC 8: Difficulty levels with roles
  difficulty_level TEXT NOT NULL CHECK (difficulty_level IN ('easy', 'medium', 'hard')),
  role_title TEXT NOT NULL, -- 'Student', 'Bureaucrat', 'Minister'
  role_description TEXT,
  
  -- Scenario content
  initial_situation TEXT NOT NULL,
  stakeholders JSONB DEFAULT '[]'::jsonb,
  constraints TEXT[] DEFAULT '{}',
  
  -- Structure
  total_stages INTEGER DEFAULT 3,
  time_limit_minutes INTEGER DEFAULT 30,
  
  -- Categorization
  category TEXT,
  tags TEXT[] DEFAULT '{}',
  
  -- Status
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
  is_featured BOOLEAN DEFAULT false,
  
  -- Stats
  attempts_count INTEGER DEFAULT 0,
  avg_score DECIMAL(5, 2),
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =================================================================
-- SIMULATION STAGES TABLE (AC 1)
-- =================================================================
CREATE TABLE IF NOT EXISTS simulation_stages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scenario_id UUID REFERENCES simulation_scenarios(id) ON DELETE CASCADE NOT NULL,
  
  -- Stage info
  stage_number INTEGER NOT NULL,
  stage_type TEXT NOT NULL CHECK (stage_type IN ('decision', 'consequence', 'adjustment', 'final')),
  
  -- Content
  title TEXT NOT NULL,
  narrative TEXT NOT NULL,
  instructions TEXT,
  
  -- Questions/prompts for user response
  prompts JSONB DEFAULT '[]'::jsonb,
  -- Example: [{"id": "prompt1", "type": "essay", "question": "What would you do?", "min_words": 100}]
  
  -- Expected elements in good response (for scoring)
  evaluation_criteria JSONB DEFAULT '{}'::jsonb,
  -- Example: {"stakeholders_mentioned": 5, "frameworks_applied": 2}
  
  -- Next stage logic
  next_stage_conditions JSONB DEFAULT '{}'::jsonb,
  
  -- Timing
  time_limit_minutes INTEGER DEFAULT 10,
  
  -- Order
  sort_order INTEGER DEFAULT 0,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =================================================================
-- SIMULATION SESSIONS TABLE (AC 1, 2, 3)
-- =================================================================
CREATE TABLE IF NOT EXISTS simulation_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID  NOT NULL,
  scenario_id UUID REFERENCES simulation_scenarios(id) ON DELETE CASCADE NOT NULL,
  
  -- Current state
  current_stage_number INTEGER DEFAULT 1,
  status TEXT DEFAULT 'in_progress' CHECK (status IN (
    'in_progress', 'completed', 'abandoned', 'retry'
  )),
  
  -- AC 10: Retry tracking
  retry_count INTEGER DEFAULT 0,
  original_session_id UUID REFERENCES simulation_sessions(id),
  retry_context TEXT, -- Different context for retry
  
  -- AC 3: Scoring dimensions
  dimension_scores JSONB DEFAULT '{
    "decision_quality": 0,
    "reasoning_depth": 0,
    "stakeholder_consideration": 0,
    "practical_implementation": 0
  }'::jsonb,
  
  -- AC 2: Personality analysis
  ethical_tendency JSONB DEFAULT '{
    "utilitarian": 0,
    "deontological": 0,
    "virtue": 0,
    "care": 0,
    "justice": 0
  }'::jsonb,
  
  -- Overall scores
  total_score INTEGER DEFAULT 0,
  max_possible_score INTEGER DEFAULT 100,
  percentile_rank DECIMAL(5, 2),
  
  -- Timing
  started_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  total_time_seconds INTEGER DEFAULT 0,
  
  -- Stage responses stored here or separately
  stage_responses JSONB DEFAULT '{}'::jsonb,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =================================================================
-- STAGE RESPONSES TABLE (AC 1, 3)
-- =================================================================
CREATE TABLE IF NOT EXISTS simulation_responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES simulation_sessions(id) ON DELETE CASCADE NOT NULL,
  stage_id UUID REFERENCES simulation_stages(id) ON DELETE CASCADE NOT NULL,
  
  -- User response
  response_text TEXT,
  response_data JSONB DEFAULT '{}'::jsonb, -- For structured responses
  
  -- AC 3: Stage-specific scores
  dimension_scores JSONB DEFAULT '{
    "decision_quality": 0,
    "reasoning_depth": 0,
    "stakeholder_consideration": 0,
    "practical_implementation": 0
  }'::jsonb,
  
  -- AC 2: Ethical tendency indicators from this response
  ethical_indicators JSONB DEFAULT '{}'::jsonb,
  
  -- AI evaluation
  ai_feedback TEXT,
  ai_score INTEGER DEFAULT 0,
  evaluation_details JSONB DEFAULT '{}'::jsonb,
  
  -- Timing
  time_spent_seconds INTEGER DEFAULT 0,
  submitted_at TIMESTAMPTZ DEFAULT NOW()
);

-- =================================================================
-- USER ETHICS PROFILE TABLE (AC 2, 4)
-- =================================================================
CREATE TABLE IF NOT EXISTS ethics_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID  NOT NULL UNIQUE,
  
  -- AC 2: Personality analysis aggregate
  ethical_tendency JSONB DEFAULT '{
    "utilitarian": 50,
    "deontological": 50,
    "virtue": 50,
    "care": 50,
    "justice": 50
  }'::jsonb,
  
  -- Primary tendency
  primary_tendency TEXT,
  secondary_tendency TEXT,
  
  -- AC 3: Dimension proficiency
  dimension_proficiency JSONB DEFAULT '{
    "decision_quality": 50,
    "reasoning_depth": 50,
    "stakeholder_consideration": 50,
    "practical_implementation": 50
  }'::jsonb,
  
  -- Stats
  simulations_completed INTEGER DEFAULT 0,
  total_time_spent_minutes INTEGER DEFAULT 0,
  average_score DECIMAL(5, 2) DEFAULT 50.00,
  best_score DECIMAL(5, 2) DEFAULT 0,
  
  -- AC 7: Peer comparison data
  global_percentile DECIMAL(5, 2) DEFAULT 50.00,
  difficulty_percentiles JSONB DEFAULT '{
    "easy": 50,
    "medium": 50,
    "hard": 50
  }'::jsonb,
  
  -- Strengths and weaknesses
  strengths TEXT[] DEFAULT '{}',
  weaknesses TEXT[] DEFAULT '{}',
  
  -- AC 9: Video summary
  profile_video_url TEXT,
  profile_video_status TEXT DEFAULT 'pending',
  last_video_generated_at TIMESTAMPTZ,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =================================================================
-- REPORT CARDS TABLE (AC 4, 5, 6)
-- =================================================================
CREATE TABLE IF NOT EXISTS simulation_report_cards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES simulation_sessions(id) ON DELETE CASCADE NOT NULL UNIQUE,
  user_id UUID  NOT NULL,
  
  -- AC 4: Comprehensive analysis
  overall_grade TEXT CHECK (overall_grade IN ('A+', 'A', 'B+', 'B', 'C+', 'C', 'D', 'F')),
  percentage_score DECIMAL(5, 2),
  
  -- Dimension breakdown
  dimension_analysis JSONB DEFAULT '{}'::jsonb,
  -- Example: {"decision_quality": {"score": 85, "grade": "A", "feedback": "..."}}
  
  -- AC 2: Ethical profile analysis
  ethical_profile_summary TEXT,
  tendency_breakdown JSONB DEFAULT '{}'::jsonb,
  
  -- Strengths and weaknesses
  key_strengths TEXT[] DEFAULT '{}',
  areas_for_improvement TEXT[] DEFAULT '{}',
  
  -- AC 5: Improvement suggestions
  recommended_resources JSONB DEFAULT '[]'::jsonb,
  -- Example: [{"type": "article", "title": "...", "url": "...", "reason": "..."}]
  
  suggested_practice_areas TEXT[] DEFAULT '{}',
  
  -- AC 6: Interview prep questions
  interview_questions JSONB DEFAULT '[]'::jsonb,
  -- Example: [{"question": "...", "context": "...", "suggested_approach": "..."}]
  
  -- AC 7: Peer comparison
  percentile_rank DECIMAL(5, 2),
  comparison_stats JSONB DEFAULT '{}'::jsonb,
  -- Example: {"better_than": 75, "top_performers_avg": 92}
  
  -- Generated analysis
  ai_narrative TEXT,
  
  -- Timestamps
  generated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =================================================================
-- PEER COMPARISON DATA (AC 7)
-- =================================================================
CREATE TABLE IF NOT EXISTS simulation_benchmarks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scenario_id UUID REFERENCES simulation_scenarios(id) ON DELETE CASCADE NOT NULL UNIQUE,
  
  -- Aggregate stats for comparison
  total_attempts INTEGER DEFAULT 0,
  average_score DECIMAL(5, 2),
  median_score DECIMAL(5, 2),
  top_10_percent_avg DECIMAL(5, 2),
  top_25_percent_avg DECIMAL(5, 2),
  
  -- Distribution
  score_distribution JSONB DEFAULT '{}'::jsonb,
  -- Example: {"0-20": 5, "21-40": 15, "41-60": 40, "61-80": 30, "81-100": 10}
  
  -- Dimension averages
  dimension_averages JSONB DEFAULT '{}'::jsonb,
  
  -- Top responses (anonymized)
  top_responses JSONB DEFAULT '[]'::jsonb,
  
  -- Updated periodically
  last_calculated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =================================================================
-- INDEXES
-- =================================================================
CREATE INDEX IF NOT EXISTS idx_sim_scenarios_difficulty ON simulation_scenarios(difficulty_level);
CREATE INDEX IF NOT EXISTS idx_sim_scenarios_status ON simulation_scenarios(status);
CREATE INDEX IF NOT EXISTS idx_sim_stages_scenario ON simulation_stages(scenario_id);
CREATE INDEX IF NOT EXISTS idx_sim_stages_number ON simulation_stages(scenario_id, stage_number);
CREATE INDEX IF NOT EXISTS idx_sim_sessions_user ON simulation_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sim_sessions_scenario ON simulation_sessions(scenario_id);
CREATE INDEX IF NOT EXISTS idx_sim_responses_session ON simulation_responses(session_id);
CREATE INDEX IF NOT EXISTS idx_ethics_profiles_user ON ethics_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_report_cards_session ON simulation_report_cards(session_id);
CREATE INDEX IF NOT EXISTS idx_report_cards_user ON simulation_report_cards(user_id);

-- =================================================================
-- FUNCTIONS
-- =================================================================

-- Start simulation session
CREATE OR REPLACE FUNCTION start_simulation(
  p_user_id UUID,
  p_scenario_id UUID,
  p_retry_session_id UUID DEFAULT NULL,
  p_retry_context TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
  v_session_id UUID;
  v_retry_count INTEGER := 0;
BEGIN
  -- Get retry count if retrying
  IF p_retry_session_id IS NOT NULL THEN
    SELECT COALESCE(retry_count, 0) + 1 INTO v_retry_count
    FROM simulation_sessions WHERE id = p_retry_session_id;
  END IF;

  INSERT INTO simulation_sessions (
    user_id, scenario_id, original_session_id, retry_count, retry_context
  ) VALUES (
    p_user_id, p_scenario_id, p_retry_session_id, v_retry_count, p_retry_context
  ) RETURNING id INTO v_session_id;
  
  -- Update scenario attempt count
  UPDATE simulation_scenarios 
  SET attempts_count = attempts_count + 1 
  WHERE id = p_scenario_id;
  
  RETURN v_session_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Submit stage response (AC 1, 3)
CREATE OR REPLACE FUNCTION submit_stage_response(
  p_session_id UUID,
  p_stage_id UUID,
  p_response_text TEXT,
  p_response_data JSONB DEFAULT '{}'::jsonb,
  p_time_spent INTEGER DEFAULT 0
) RETURNS UUID AS $$
DECLARE
  v_response_id UUID;
  v_stage_number INTEGER;
BEGIN
  -- Get stage number
  SELECT stage_number INTO v_stage_number FROM simulation_stages WHERE id = p_stage_id;
  
  -- Insert response
  INSERT INTO simulation_responses (
    session_id, stage_id, response_text, response_data, time_spent_seconds
  ) VALUES (
    p_session_id, p_stage_id, p_response_text, p_response_data, p_time_spent
  ) RETURNING id INTO v_response_id;
  
  -- Update session
  UPDATE simulation_sessions SET
    current_stage_number = v_stage_number + 1,
    total_time_seconds = total_time_seconds + p_time_spent,
    updated_at = NOW()
  WHERE id = p_session_id;
  
  RETURN v_response_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Complete simulation and generate report (AC 4)
CREATE OR REPLACE FUNCTION complete_simulation(
  p_session_id UUID,
  p_dimension_scores JSONB,
  p_ethical_tendency JSONB,
  p_total_score INTEGER
) RETURNS UUID AS $$
DECLARE
  v_report_id UUID;
  v_user_id UUID;
  v_scenario_id UUID;
  v_percentile DECIMAL(5, 2);
  v_grade TEXT;
BEGIN
  -- Get session info
  SELECT user_id, scenario_id INTO v_user_id, v_scenario_id
  FROM simulation_sessions WHERE id = p_session_id;
  
  -- Update session
  UPDATE simulation_sessions SET
    status = 'completed',
    dimension_scores = p_dimension_scores,
    ethical_tendency = p_ethical_tendency,
    total_score = p_total_score,
    completed_at = NOW()
  WHERE id = p_session_id;
  
  -- Calculate percentile (simplified)
  SELECT COALESCE(
    (COUNT(*) FILTER (WHERE total_score < p_total_score)::decimal / NULLIF(COUNT(*), 0) * 100),
    50
  ) INTO v_percentile
  FROM simulation_sessions
  WHERE scenario_id = v_scenario_id AND status = 'completed';
  
  -- Determine grade
  v_grade := CASE 
    WHEN p_total_score >= 95 THEN 'A+'
    WHEN p_total_score >= 85 THEN 'A'
    WHEN p_total_score >= 75 THEN 'B+'
    WHEN p_total_score >= 65 THEN 'B'
    WHEN p_total_score >= 55 THEN 'C+'
    WHEN p_total_score >= 45 THEN 'C'
    WHEN p_total_score >= 35 THEN 'D'
    ELSE 'F'
  END;
  
  -- Create report card
  INSERT INTO simulation_report_cards (
    session_id, user_id, overall_grade, percentage_score, 
    percentile_rank, dimension_analysis, tendency_breakdown
  ) VALUES (
    p_session_id, v_user_id, v_grade, p_total_score,
    v_percentile, p_dimension_scores, p_ethical_tendency
  ) RETURNING id INTO v_report_id;
  
  -- Update user profile
  PERFORM update_ethics_profile(v_user_id, p_dimension_scores, p_ethical_tendency, p_total_score);
  
  RETURN v_report_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update user ethics profile (AC 2, 4)
CREATE OR REPLACE FUNCTION update_ethics_profile(
  p_user_id UUID,
  p_dimension_scores JSONB,
  p_ethical_tendency JSONB,
  p_score INTEGER
) RETURNS VOID AS $$
DECLARE
  v_primary TEXT;
  v_secondary TEXT;
  v_max_score INTEGER := 0;
  v_second_max INTEGER := 0;
  v_key TEXT;
  v_val INTEGER;
BEGIN
  -- Find primary and secondary tendencies
  FOR v_key, v_val IN SELECT * FROM jsonb_each_text(p_ethical_tendency)
  LOOP
    IF v_val::integer > v_max_score THEN
      v_secondary := v_primary;
      v_second_max := v_max_score;
      v_primary := v_key;
      v_max_score := v_val::integer;
    ELSIF v_val::integer > v_second_max THEN
      v_secondary := v_key;
      v_second_max := v_val::integer;
    END IF;
  END LOOP;

  INSERT INTO ethics_profiles (
    user_id, ethical_tendency, dimension_proficiency,
    primary_tendency, secondary_tendency,
    simulations_completed, average_score, best_score
  ) VALUES (
    p_user_id, p_ethical_tendency, p_dimension_scores,
    v_primary, v_secondary,
    1, p_score, p_score
  )
  ON CONFLICT (user_id) DO UPDATE SET
    ethical_tendency = (
      SELECT jsonb_object_agg(key, ((COALESCE(ethics_profiles.ethical_tendency->>key, '50')::integer + 
             COALESCE(p_ethical_tendency->>key, '50')::integer) / 2)::text)
      FROM jsonb_object_keys(p_ethical_tendency) AS key
    ),
    dimension_proficiency = (
      SELECT jsonb_object_agg(key, ((COALESCE(ethics_profiles.dimension_proficiency->>key, '50')::integer + 
             COALESCE(p_dimension_scores->>key, '50')::integer) / 2)::text)
      FROM jsonb_object_keys(p_dimension_scores) AS key
    ),
    primary_tendency = v_primary,
    secondary_tendency = v_secondary,
    simulations_completed = ethics_profiles.simulations_completed + 1,
    average_score = (ethics_profiles.average_score + p_score) / 2,
    best_score = GREATEST(ethics_profiles.best_score, p_score),
    updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get peer comparison (AC 7)
CREATE OR REPLACE FUNCTION get_peer_comparison(
  p_session_id UUID
) RETURNS JSONB AS $$
DECLARE
  v_scenario_id UUID;
  v_user_score INTEGER;
  v_stats JSONB;
BEGIN
  SELECT scenario_id, total_score INTO v_scenario_id, v_user_score
  FROM simulation_sessions WHERE id = p_session_id;
  
  SELECT jsonb_build_object(
    'your_score', v_user_score,
    'average_score', AVG(total_score),
    'median_score', PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_score),
    'top_10_avg', AVG(total_score) FILTER (WHERE total_score >= PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY total_score)),
    'better_than_percent', (COUNT(*) FILTER (WHERE total_score < v_user_score)::decimal / NULLIF(COUNT(*), 0) * 100),
    'total_attempts', COUNT(*)
  ) INTO v_stats
  FROM simulation_sessions
  WHERE scenario_id = v_scenario_id AND status = 'completed';
  
  RETURN v_stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get scenarios by difficulty (AC 8)
CREATE OR REPLACE FUNCTION get_simulation_scenarios(
  p_difficulty TEXT DEFAULT NULL,
  p_limit INTEGER DEFAULT 20
) RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT jsonb_agg(s ORDER BY s.is_featured DESC, s.attempts_count DESC) INTO v_result
  FROM (
    SELECT id, title, description, difficulty_level, role_title,
           is_featured, attempts_count, avg_score, total_stages, time_limit_minutes
    FROM simulation_scenarios
    WHERE status = 'published'
      AND (p_difficulty IS NULL OR difficulty_level = p_difficulty)
    ORDER BY is_featured DESC, attempts_count DESC
    LIMIT p_limit
  ) s;
  
  RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =================================================================
-- SAMPLE DATA (AC 8)
-- =================================================================

-- Easy scenario (Student role)
INSERT INTO simulation_scenarios (
  title, description, context, difficulty_level, role_title, role_description,
  initial_situation, stakeholders, total_stages, status
) VALUES (
  'Campus Ethics Challenge',
  'Navigate ethical dilemmas as a college student leader.',
  'You are the president of your college student council. A cheating scandal has emerged.',
  'easy',
  'Student Council President',
  'You lead the student body and must balance fairness, friendship, and institutional integrity.',
  'Your best friend has been caught sharing exam answers. The matter is now before the disciplinary committee where you have influence.',
  '["Friend", "Other students", "Faculty", "Administration", "Your conscience"]'::jsonb,
  3,
  'published'
);

-- Medium scenario (Bureaucrat role)
INSERT INTO simulation_scenarios (
  title, description, context, difficulty_level, role_title, role_description,
  initial_situation, stakeholders, total_stages, status
) VALUES (
  'District Development Dilemma',
  'Balance development goals with ground realities as a bureaucrat.',
  'You are the District Collector facing pressure from multiple directions.',
  'medium',
  'District Collector (IAS)',
  'Senior bureaucrat responsible for district administration, development, and law & order.',
  'A major infrastructure project requires displacing a tribal community. Political pressure is mounting for quick clearance, but the community has not been properly consulted.',
  '["Tribal community", "State government", "Central ministry", "NGOs", "Media", "Local politicians", "Contractors"]'::jsonb,
  4,
  'published'
);

-- Hard scenario (Minister role)
INSERT INTO simulation_scenarios (
  title, description, context, difficulty_level, role_title, role_description,
  initial_situation, stakeholders, total_stages, status
) VALUES (
  'National Policy Crisis',
  'Make decisions that affect millions as a cabinet minister.',
  'You are the Health Minister during a pandemic outbreak.',
  'hard',
  'Union Health Minister',
  'Cabinet minister responsible for national health policy during a crisis.',
  'A deadly outbreak requires immediate decisions about lockdowns, resource allocation, and transparency. International pressure, economic concerns, and public health compete for priority.',
  '["Citizens", "Healthcare workers", "State governments", "Opposition parties", "International community", "Business sector", "Media", "Scientific community"]'::jsonb,
  5,
  'published'
);

-- =================================================================
-- ROW LEVEL SECURITY
-- =================================================================
ALTER TABLE simulation_scenarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE simulation_stages ENABLE ROW LEVEL SECURITY;
ALTER TABLE simulation_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE simulation_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE ethics_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE simulation_report_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE simulation_benchmarks ENABLE ROW LEVEL SECURITY;

-- Public access to published scenarios
CREATE POLICY "Anyone can view published scenarios" ON simulation_scenarios
  FOR SELECT USING (status = 'published');

CREATE POLICY "Anyone can view stages of published scenarios" ON simulation_stages
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM simulation_scenarios WHERE id = scenario_id AND status = 'published')
  );

-- User-specific data
CREATE POLICY "Users can manage own sessions" ON simulation_sessions
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own responses" ON simulation_responses
  FOR ALL USING (
    EXISTS (SELECT 1 FROM simulation_sessions WHERE id = session_id AND user_id = auth.uid())
  );

CREATE POLICY "Users can view own profile" ON ethics_profiles
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "System can update profiles" ON ethics_profiles
  FOR ALL USING (true);

CREATE POLICY "Users can view own report cards" ON simulation_report_cards
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Anyone can view benchmarks" ON simulation_benchmarks
  FOR SELECT USING (true);

