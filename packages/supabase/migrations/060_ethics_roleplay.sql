-- Migration 060: Ethics Roleplay Branching Scenarios
-- Story 12.1: Ethics Roleplay - Branching Scenarios
-- 
-- Implements:
-- AC 1: Scenario types (governance, social, professional, environmental)
-- AC 2: Branching logic with choices
-- AC 3: 3+ levels deep
-- AC 4: Ethical frameworks evaluation
-- AC 5: Score calculation
-- AC 6: Choice feedback
-- AC 7: Video feedback
-- AC 8: Progress tracking
-- AC 9: Admin interface support
-- AC 10: Content library

-- =================================================================
-- ETHICS SCENARIOS TABLE (AC 1, 10)
-- =================================================================
CREATE TABLE IF NOT EXISTS ethics_scenarios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- AC 1: Scenario types
  scenario_type TEXT NOT NULL CHECK (scenario_type IN (
    'governance', 'social', 'professional', 'environmental',
    'personal', 'legal', 'administrative', 'crisis'
  )),
  
  -- Basic info
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  context TEXT,
  
  -- Tags and metadata
  difficulty TEXT DEFAULT 'medium' CHECK (difficulty IN ('easy', 'medium', 'hard')),
  tags TEXT[] DEFAULT '{}',
  keywords TEXT[] DEFAULT '{}',
  
  -- AC 3: Depth info
  max_depth INTEGER DEFAULT 3,
  total_nodes INTEGER DEFAULT 0,
  total_endings INTEGER DEFAULT 0,
  
  -- AC 4: Primary ethical framework
  primary_framework TEXT CHECK (primary_framework IN (
    'utilitarian', 'deontological', 'virtue', 'justice', 'mixed'
  )),
  
  -- Content status
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'review', 'published', 'archived')),
  is_featured BOOLEAN DEFAULT false,
  
  -- Stats
  play_count INTEGER DEFAULT 0,
  avg_score DECIMAL(5, 2),
  avg_completion_time_seconds INTEGER,
  
  -- Video feedback (AC 7)
  best_path_video_url TEXT,
  best_path_video_status TEXT DEFAULT 'pending',
  
  -- Admin (AC 9)
  created_by UUID ,
  reviewed_by UUID ,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  published_at TIMESTAMPTZ
);

-- =================================================================
-- SCENARIO NODES TABLE (AC 2, 3)
-- =================================================================
CREATE TABLE IF NOT EXISTS scenario_nodes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scenario_id UUID REFERENCES ethics_scenarios(id) ON DELETE CASCADE NOT NULL,
  
  -- Node info
  node_type TEXT NOT NULL CHECK (node_type IN ('root', 'decision', 'consequence', 'ending')),
  level INTEGER NOT NULL DEFAULT 0, -- AC 3: depth level
  
  -- Content
  title TEXT NOT NULL,
  narrative TEXT NOT NULL,
  situation_context TEXT,
  
  -- For endings
  ending_type TEXT CHECK (ending_type IN ('best', 'good', 'neutral', 'bad', 'worst')),
  ending_summary TEXT,
  
  -- AC 4: Framework relevance at this node
  framework_weights JSONB DEFAULT '{}'::jsonb,
  
  -- Ordering
  sort_order INTEGER DEFAULT 0,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =================================================================
-- SCENARIO CHOICES TABLE (AC 2, 4, 5, 6)
-- =================================================================
CREATE TABLE IF NOT EXISTS scenario_choices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  node_id UUID REFERENCES scenario_nodes(id) ON DELETE CASCADE NOT NULL,
  
  -- Choice content
  choice_text TEXT NOT NULL,
  choice_label TEXT, -- A, B, C, D or custom
  
  -- AC 2: Branching - where this choice leads
  next_node_id UUID REFERENCES scenario_nodes(id),
  
  -- AC 4: Ethical framework alignment
  framework_scores JSONB DEFAULT '{}'::jsonb,
  -- Example: {"utilitarian": 8, "deontological": 3, "virtue": 5, "justice": 7}
  
  -- AC 5: Score contribution
  ethical_score INTEGER DEFAULT 0 CHECK (ethical_score BETWEEN -10 AND 10),
  reasoning_weight REAL DEFAULT 1.0,
  
  -- AC 6: Feedback
  immediate_feedback TEXT,
  detailed_explanation TEXT,
  ethical_analysis TEXT,
  
  -- Hints
  hint_text TEXT,
  show_hint_after_seconds INTEGER DEFAULT 30,
  
  -- Stats
  selection_count INTEGER DEFAULT 0,
  selection_percentage DECIMAL(5, 2),
  
  -- Ordering
  sort_order INTEGER DEFAULT 0,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =================================================================
-- USER SCENARIO SESSIONS TABLE (AC 5, 8)
-- =================================================================
CREATE TABLE IF NOT EXISTS ethics_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID  NOT NULL,
  scenario_id UUID REFERENCES ethics_scenarios(id) ON DELETE CASCADE NOT NULL,
  
  -- Session state
  current_node_id UUID REFERENCES scenario_nodes(id),
  path_taken UUID[] DEFAULT '{}', -- Array of node IDs
  choices_made UUID[] DEFAULT '{}', -- Array of choice IDs
  
  -- AC 5: Scoring
  cumulative_score INTEGER DEFAULT 0,
  max_possible_score INTEGER DEFAULT 0,
  framework_scores JSONB DEFAULT '{
    "utilitarian": 0,
    "deontological": 0,
    "virtue": 0,
    "justice": 0
  }'::jsonb,
  
  -- Timing
  started_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  time_spent_seconds INTEGER DEFAULT 0,
  
  -- Result
  ending_reached TEXT,
  final_score_percentage DECIMAL(5, 2),
  
  -- Feedback viewed
  feedback_viewed BOOLEAN DEFAULT false,
  
  -- Status
  status TEXT DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed', 'abandoned'))
);

-- =================================================================
-- USER ETHICS PROGRESS TABLE (AC 8)
-- =================================================================
CREATE TABLE IF NOT EXISTS ethics_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID  NOT NULL UNIQUE,
  
  -- Overall stats
  scenarios_completed INTEGER DEFAULT 0,
  scenarios_attempted INTEGER DEFAULT 0,
  total_playtime_seconds INTEGER DEFAULT 0,
  
  -- AC 5, 8: Scoring over time
  overall_ethics_score DECIMAL(5, 2) DEFAULT 50.00,
  best_ethics_score DECIMAL(5, 2) DEFAULT 0,
  
  -- AC 4: Framework proficiency
  framework_proficiency JSONB DEFAULT '{
    "utilitarian": 50,
    "deontological": 50,
    "virtue": 50,
    "justice": 50
  }'::jsonb,
  
  -- Type proficiency (AC 1)
  type_proficiency JSONB DEFAULT '{
    "governance": 50,
    "social": 50,
    "professional": 50,
    "environmental": 50
  }'::jsonb,
  
  -- Achievements
  perfect_scores INTEGER DEFAULT 0,
  best_endings_reached INTEGER DEFAULT 0,
  streak_days INTEGER DEFAULT 0,
  last_played_at TIMESTAMPTZ,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =================================================================
-- ETHICS FEEDBACK VIDEOS TABLE (AC 7)
-- =================================================================
CREATE TABLE IF NOT EXISTS ethics_feedback_videos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scenario_id UUID REFERENCES ethics_scenarios(id) ON DELETE CASCADE NOT NULL,
  
  -- Video info
  path_type TEXT NOT NULL CHECK (path_type IN ('best', 'alternative', 'common_mistake')),
  path_nodes UUID[] NOT NULL,
  
  -- Video generation
  video_status TEXT DEFAULT 'pending' CHECK (video_status IN (
    'pending', 'generating', 'completed', 'failed'
  )),
  video_url TEXT,
  thumbnail_url TEXT,
  duration_seconds INTEGER,
  
  -- Narration
  narration_script TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  generated_at TIMESTAMPTZ
);

-- =================================================================
-- INDEXES
-- =================================================================
CREATE INDEX IF NOT EXISTS idx_scenarios_type ON ethics_scenarios(scenario_type);
CREATE INDEX IF NOT EXISTS idx_scenarios_status ON ethics_scenarios(status);
CREATE INDEX IF NOT EXISTS idx_scenarios_featured ON ethics_scenarios(is_featured) WHERE is_featured = true;
CREATE INDEX IF NOT EXISTS idx_scenarios_published ON ethics_scenarios(published_at) WHERE status = 'published';

CREATE INDEX IF NOT EXISTS idx_nodes_scenario ON scenario_nodes(scenario_id);
CREATE INDEX IF NOT EXISTS idx_nodes_level ON scenario_nodes(level);
CREATE INDEX IF NOT EXISTS idx_nodes_type ON scenario_nodes(node_type);

CREATE INDEX IF NOT EXISTS idx_choices_node ON scenario_choices(node_id);
CREATE INDEX IF NOT EXISTS idx_choices_next ON scenario_choices(next_node_id);

CREATE INDEX IF NOT EXISTS idx_sessions_user ON ethics_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_scenario ON ethics_sessions(scenario_id);
CREATE INDEX IF NOT EXISTS idx_sessions_status ON ethics_sessions(status);

CREATE INDEX IF NOT EXISTS idx_progress_user ON ethics_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_feedback_scenario ON ethics_feedback_videos(scenario_id);

-- =================================================================
-- FUNCTIONS
-- =================================================================

-- Get scenario with root node
CREATE OR REPLACE FUNCTION get_ethics_scenario(
  p_scenario_id UUID
) RETURNS JSONB AS $$
DECLARE
  v_scenario RECORD;
  v_root_node RECORD;
  v_choices JSONB;
BEGIN
  SELECT * INTO v_scenario FROM ethics_scenarios WHERE id = p_scenario_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Scenario not found');
  END IF;
  
  -- Get root node
  SELECT * INTO v_root_node FROM scenario_nodes 
  WHERE scenario_id = p_scenario_id AND node_type = 'root'
  ORDER BY sort_order LIMIT 1;
  
  -- Get choices for root node
  SELECT jsonb_agg(c ORDER BY c.sort_order) INTO v_choices
  FROM scenario_choices c
  WHERE c.node_id = v_root_node.id;
  
  RETURN jsonb_build_object(
    'scenario', row_to_json(v_scenario),
    'root_node', row_to_json(v_root_node),
    'choices', COALESCE(v_choices, '[]'::jsonb)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get node with choices (AC 2)
CREATE OR REPLACE FUNCTION get_scenario_node(
  p_node_id UUID
) RETURNS JSONB AS $$
DECLARE
  v_node RECORD;
  v_choices JSONB;
BEGIN
  SELECT * INTO v_node FROM scenario_nodes WHERE id = p_node_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Node not found');
  END IF;
  
  -- Get choices
  SELECT jsonb_agg(jsonb_build_object(
    'id', c.id,
    'choice_text', c.choice_text,
    'choice_label', c.choice_label,
    'has_next', c.next_node_id IS NOT NULL,
    'hint_text', c.hint_text
  ) ORDER BY c.sort_order) INTO v_choices
  FROM scenario_choices c
  WHERE c.node_id = p_node_id;
  
  RETURN jsonb_build_object(
    'node', row_to_json(v_node),
    'choices', COALESCE(v_choices, '[]'::jsonb),
    'is_ending', v_node.node_type = 'ending'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Start scenario session (AC 5)
CREATE OR REPLACE FUNCTION start_ethics_session(
  p_user_id UUID,
  p_scenario_id UUID
) RETURNS UUID AS $$
DECLARE
  v_session_id UUID;
  v_root_node_id UUID;
BEGIN
  -- Get root node
  SELECT id INTO v_root_node_id FROM scenario_nodes
  WHERE scenario_id = p_scenario_id AND node_type = 'root'
  LIMIT 1;
  
  -- Create session
  INSERT INTO ethics_sessions (
    user_id, scenario_id, current_node_id, path_taken
  ) VALUES (
    p_user_id, p_scenario_id, v_root_node_id, ARRAY[v_root_node_id]
  ) RETURNING id INTO v_session_id;
  
  -- Update scenario play count
  UPDATE ethics_scenarios 
  SET play_count = play_count + 1 
  WHERE id = p_scenario_id;
  
  -- Update user progress
  INSERT INTO ethics_progress (user_id, scenarios_attempted)
  VALUES (p_user_id, 1)
  ON CONFLICT (user_id) DO UPDATE SET
    scenarios_attempted = ethics_progress.scenarios_attempted + 1,
    last_played_at = NOW(),
    updated_at = NOW();
  
  RETURN v_session_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Make choice and progress (AC 2, 5, 6)
CREATE OR REPLACE FUNCTION make_ethics_choice(
  p_session_id UUID,
  p_choice_id UUID
) RETURNS JSONB AS $$
DECLARE
  v_session RECORD;
  v_choice RECORD;
  v_next_node RECORD;
  v_is_ending BOOLEAN;
  v_new_score INTEGER;
  v_framework_updates JSONB;
BEGIN
  -- Get session
  SELECT * INTO v_session FROM ethics_sessions WHERE id = p_session_id;
  
  -- Get choice with feedback
  SELECT * INTO v_choice FROM scenario_choices WHERE id = p_choice_id;
  
  -- Update choice stats
  UPDATE scenario_choices SET selection_count = selection_count + 1 WHERE id = p_choice_id;
  
  -- Calculate new cumulative score (AC 5)
  v_new_score := v_session.cumulative_score + v_choice.ethical_score;
  
  -- Update framework scores
  v_framework_updates := v_session.framework_scores;
  IF v_choice.framework_scores IS NOT NULL THEN
    v_framework_updates := jsonb_build_object(
      'utilitarian', COALESCE((v_session.framework_scores->>'utilitarian')::integer, 0) + 
                     COALESCE((v_choice.framework_scores->>'utilitarian')::integer, 0),
      'deontological', COALESCE((v_session.framework_scores->>'deontological')::integer, 0) + 
                       COALESCE((v_choice.framework_scores->>'deontological')::integer, 0),
      'virtue', COALESCE((v_session.framework_scores->>'virtue')::integer, 0) + 
                COALESCE((v_choice.framework_scores->>'virtue')::integer, 0),
      'justice', COALESCE((v_session.framework_scores->>'justice')::integer, 0) + 
                 COALESCE((v_choice.framework_scores->>'justice')::integer, 0)
    );
  END IF;
  
  -- Check if next node is ending
  IF v_choice.next_node_id IS NOT NULL THEN
    SELECT * INTO v_next_node FROM scenario_nodes WHERE id = v_choice.next_node_id;
    v_is_ending := v_next_node.node_type = 'ending';
  ELSE
    v_is_ending := TRUE;
  END IF;
  
  -- Update session
  UPDATE ethics_sessions SET
    current_node_id = v_choice.next_node_id,
    path_taken = array_append(path_taken, v_choice.next_node_id),
    choices_made = array_append(choices_made, p_choice_id),
    cumulative_score = v_new_score,
    framework_scores = v_framework_updates,
    status = CASE WHEN v_is_ending THEN 'completed' ELSE 'in_progress' END,
    completed_at = CASE WHEN v_is_ending THEN NOW() ELSE NULL END,
    ending_reached = CASE WHEN v_is_ending THEN v_next_node.ending_type ELSE NULL END,
    updated_at = NOW()
  WHERE id = p_session_id;
  
  -- If completed, update progress (AC 8)
  IF v_is_ending THEN
    PERFORM update_ethics_progress(v_session.user_id, p_session_id);
  END IF;
  
  RETURN jsonb_build_object(
    'success', true,
    'next_node_id', v_choice.next_node_id,
    'is_ending', v_is_ending,
    'immediate_feedback', v_choice.immediate_feedback,
    'ethical_analysis', v_choice.ethical_analysis,
    'score_change', v_choice.ethical_score,
    'new_cumulative_score', v_new_score
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update user progress after completion (AC 8)
CREATE OR REPLACE FUNCTION update_ethics_progress(
  p_user_id UUID,
  p_session_id UUID
) RETURNS VOID AS $$
DECLARE
  v_session RECORD;
  v_final_score DECIMAL(5, 2);
BEGIN
  SELECT * INTO v_session FROM ethics_sessions WHERE id = p_session_id;
  
  -- Calculate final score percentage
  IF v_session.max_possible_score > 0 THEN
    v_final_score := (v_session.cumulative_score::decimal / v_session.max_possible_score) * 100;
  ELSE
    v_final_score := 50.00; -- Neutral score
  END IF;
  
  -- Update session
  UPDATE ethics_sessions SET final_score_percentage = v_final_score WHERE id = p_session_id;
  
  -- Update progress
  UPDATE ethics_progress SET
    scenarios_completed = scenarios_completed + 1,
    overall_ethics_score = (overall_ethics_score + v_final_score) / 2,
    best_ethics_score = GREATEST(best_ethics_score, v_final_score),
    perfect_scores = perfect_scores + CASE WHEN v_final_score >= 90 THEN 1 ELSE 0 END,
    best_endings_reached = best_endings_reached + 
      CASE WHEN v_session.ending_reached = 'best' THEN 1 ELSE 0 END,
    updated_at = NOW()
  WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get user's ethics progress (AC 8)
CREATE OR REPLACE FUNCTION get_ethics_progress(
  p_user_id UUID
) RETURNS JSONB AS $$
DECLARE
  v_progress RECORD;
  v_recent_sessions JSONB;
BEGIN
  SELECT * INTO v_progress FROM ethics_progress WHERE user_id = p_user_id;
  
  -- Get recent sessions
  SELECT jsonb_agg(s ORDER BY s.completed_at DESC) INTO v_recent_sessions
  FROM (
    SELECT es.id, es.scenario_id, sc.title as scenario_title,
           es.final_score_percentage, es.ending_reached, es.completed_at
    FROM ethics_sessions es
    JOIN ethics_scenarios sc ON sc.id = es.scenario_id
    WHERE es.user_id = p_user_id AND es.status = 'completed'
    ORDER BY es.completed_at DESC
    LIMIT 10
  ) s;
  
  RETURN jsonb_build_object(
    'progress', row_to_json(v_progress),
    'recent_sessions', COALESCE(v_recent_sessions, '[]'::jsonb)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get published scenarios (AC 10)
CREATE OR REPLACE FUNCTION get_published_scenarios(
  p_scenario_type TEXT DEFAULT NULL,
  p_difficulty TEXT DEFAULT NULL,
  p_limit INTEGER DEFAULT 20,
  p_offset INTEGER DEFAULT 0
) RETURNS JSONB AS $$
DECLARE
  v_scenarios JSONB;
  v_total INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_total
  FROM ethics_scenarios
  WHERE status = 'published'
    AND (p_scenario_type IS NULL OR scenario_type = p_scenario_type)
    AND (p_difficulty IS NULL OR difficulty = p_difficulty);
  
  SELECT jsonb_agg(s ORDER BY s.is_featured DESC, s.play_count DESC) INTO v_scenarios
  FROM (
    SELECT id, title, description, scenario_type, difficulty, 
           is_featured, play_count, avg_score, max_depth
    FROM ethics_scenarios
    WHERE status = 'published'
      AND (p_scenario_type IS NULL OR scenario_type = p_scenario_type)
      AND (p_difficulty IS NULL OR difficulty = p_difficulty)
    ORDER BY is_featured DESC, play_count DESC
    LIMIT p_limit OFFSET p_offset
  ) s;
  
  RETURN jsonb_build_object(
    'scenarios', COALESCE(v_scenarios, '[]'::jsonb),
    'total', v_total
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Admin: Create scenario (AC 9)
CREATE OR REPLACE FUNCTION admin_create_scenario(
  p_admin_id UUID,
  p_title TEXT,
  p_description TEXT,
  p_scenario_type TEXT,
  p_difficulty TEXT DEFAULT 'medium'
) RETURNS UUID AS $$
DECLARE
  v_scenario_id UUID;
BEGIN
  INSERT INTO ethics_scenarios (
    title, description, scenario_type, difficulty, created_by
  ) VALUES (
    p_title, p_description, p_scenario_type, p_difficulty, p_admin_id
  ) RETURNING id INTO v_scenario_id;
  
  RETURN v_scenario_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =================================================================
-- INSERT SAMPLE SCENARIOS (AC 10)
-- =================================================================

-- Sample governance scenario
INSERT INTO ethics_scenarios (
  scenario_type, title, description, difficulty, primary_framework,
  status, max_depth, tags
) VALUES (
  'governance',
  'The Infrastructure Dilemma',
  'As a District Collector, you face a decision about land acquisition for a new highway that will displace several villages but benefit the larger region economically.',
  'medium',
  'utilitarian',
  'published',
  3,
  ARRAY['land acquisition', 'development', 'displacement', 'public interest']
);

INSERT INTO ethics_scenarios (
  scenario_type, title, description, difficulty, primary_framework,
  status, max_depth, tags
) VALUES (
  'professional',
  'Whistleblower''s Choice',
  'You discover that your senior officer is involved in financial irregularities. Reporting could end your career, but staying silent makes you complicit.',
  'hard',
  'deontological',
  'published',
  4,
  ARRAY['corruption', 'whistleblowing', 'integrity', 'loyalty']
);

INSERT INTO ethics_scenarios (
  scenario_type, title, description, difficulty, primary_framework,
  status, max_depth, tags
) VALUES (
  'social',
  'Caste Reservation Conflict',
  'As a university admissions officer, you face pressure from influential groups to bypass reservation rules for a "deserving" general category student.',
  'hard',
  'justice',
  'published',
  3,
  ARRAY['reservation', 'social justice', 'education', 'equality']
);

INSERT INTO ethics_scenarios (
  scenario_type, title, description, difficulty, primary_framework,
  status, max_depth, tags
) VALUES (
  'environmental',
  'Industrial vs Ecology',
  'A major company wants to set up a factory that will provide 5000 jobs but will affect a nearby wetland ecosystem. You must decide on the environmental clearance.',
  'medium',
  'mixed',
  'published',
  3,
  ARRAY['environment', 'industry', 'jobs', 'ecology', 'sustainable development']
);

-- =================================================================
-- ROW LEVEL SECURITY
-- =================================================================
ALTER TABLE ethics_scenarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE scenario_nodes ENABLE ROW LEVEL SECURITY;
ALTER TABLE scenario_choices ENABLE ROW LEVEL SECURITY;
ALTER TABLE ethics_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ethics_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE ethics_feedback_videos ENABLE ROW LEVEL SECURITY;

-- Public read for published scenarios
CREATE POLICY "Anyone can view published scenarios" ON ethics_scenarios
  FOR SELECT USING (status = 'published');

CREATE POLICY "Anyone can view nodes of published scenarios" ON scenario_nodes
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM ethics_scenarios WHERE id = scenario_id AND status = 'published')
  );

CREATE POLICY "Anyone can view choices of published scenarios" ON scenario_choices
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM scenario_nodes sn 
            JOIN ethics_scenarios es ON es.id = sn.scenario_id 
            WHERE sn.id = node_id AND es.status = 'published')
  );

-- User-specific data
CREATE POLICY "Users can manage own sessions" ON ethics_sessions
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view own progress" ON ethics_progress
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "System can update progress" ON ethics_progress
  FOR UPDATE USING (true);

CREATE POLICY "Anyone can view feedback videos" ON ethics_feedback_videos
  FOR SELECT USING (video_status = 'completed');

