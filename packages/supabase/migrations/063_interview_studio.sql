-- Migration 063: Interview Studio - WebRTC Real-Time AI
-- Story 13.1: Flagship Interview Prep Studio
-- 
-- AC 1: WebRTC video call (<500ms latency)
-- AC 2: AI interviewer with TTS
-- AC 3: Question bank (1000+ questions)
-- AC 4: Adaptive difficulty
-- AC 5: Visual aids during interview
-- AC 6: Real-time Manim (2-6s render)
-- AC 7: Recording with consent
-- AC 8: Session duration (15-30 min)
-- AC 9: Evaluation and feedback
-- AC 10: Panel mode (3 AI interviewers)

-- =========================================
-- INTERVIEW QUESTIONS BANK (AC 3)
-- =========================================
CREATE TABLE IF NOT EXISTS interview_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category TEXT NOT NULL CHECK (category IN (
    'current_affairs', 'polity', 'economy', 'history', 'geography',
    'science', 'ethics', 'international_relations', 'society', 'governance',
    'personality', 'situational', 'daf_based', 'hobby', 'opinion'
  )),
  topic TEXT NOT NULL,
  question TEXT NOT NULL,
  difficulty_level TEXT NOT NULL CHECK (difficulty_level IN ('easy', 'medium', 'hard', 'very_hard')),
  follow_up_questions JSONB DEFAULT '[]',
  expected_points JSONB DEFAULT '[]',
  time_expected_seconds INTEGER DEFAULT 120,
  interviewer_type TEXT DEFAULT 'chairperson' CHECK (interviewer_type IN (
    'chairperson', 'expert', 'psychology'
  )),
  keywords TEXT[] DEFAULT '{}',
  source TEXT,
  is_active BOOLEAN DEFAULT true,
  usage_count INTEGER DEFAULT 0,
  avg_score DECIMAL(3,2),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- =========================================
-- AI INTERVIEWER PROFILES (AC 2, AC 10)
-- =========================================
CREATE TABLE IF NOT EXISTS ai_interviewers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('chairperson', 'expert', 'psychology')),
  voice_id TEXT NOT NULL, -- TTS voice identifier
  avatar_url TEXT,
  personality_traits JSONB NOT NULL DEFAULT '{}',
  speaking_style TEXT NOT NULL,
  specialization TEXT[] DEFAULT '{}',
  intro_script TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- =========================================
-- INTERVIEW SESSIONS (AC 1, 7, 8)
-- =========================================
CREATE TABLE IF NOT EXISTS interview_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL ,
  session_type TEXT NOT NULL CHECK (session_type IN ('solo', 'panel')),
  status TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN (
    'scheduled', 'connecting', 'in_progress', 'completed', 'cancelled', 'error'
  )),
  
  -- Session configuration (AC 8)
  duration_minutes INTEGER NOT NULL DEFAULT 20 CHECK (duration_minutes BETWEEN 15 AND 30),
  difficulty_level TEXT NOT NULL DEFAULT 'medium',
  topics TEXT[] DEFAULT '{}',
  
  -- Panel mode (AC 10)
  interviewers JSONB DEFAULT '[]', -- Array of interviewer IDs and roles
  current_interviewer_id UUID,
  
  -- Recording consent (AC 7)
  recording_consent BOOLEAN DEFAULT false,
  recording_url TEXT,
  recording_status TEXT DEFAULT 'none' CHECK (recording_status IN (
    'none', 'recording', 'processing', 'ready', 'deleted'
  )),
  
  -- Timing
  scheduled_at TIMESTAMPTZ,
  started_at TIMESTAMPTZ,
  ended_at TIMESTAMPTZ,
  actual_duration_seconds INTEGER,
  
  -- WebRTC signaling (AC 1)
  signaling_server_url TEXT,
  room_id TEXT UNIQUE,
  ice_servers JSONB,
  
  -- Metrics
  connection_quality DECIMAL(3,2),
  latency_avg_ms INTEGER,
  
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- =========================================
-- INTERVIEW TRANSCRIPT (AC 2, 9)
-- =========================================
CREATE TABLE IF NOT EXISTS interview_transcript (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES interview_sessions(id) ON DELETE CASCADE,
  
  speaker TEXT NOT NULL CHECK (speaker IN ('user', 'interviewer', 'system')),
  interviewer_id UUID REFERENCES ai_interviewers(id),
  message TEXT NOT NULL,
  audio_url TEXT,
  
  timestamp_seconds DECIMAL(8,2) NOT NULL,
  duration_seconds DECIMAL(6,2),
  
  -- For user responses
  question_id UUID REFERENCES interview_questions(id),
  response_analysis JSONB, -- AI analysis of the response
  
  created_at TIMESTAMPTZ DEFAULT now()
);

-- =========================================
-- SESSION QUESTIONS (AC 3, 4)
-- =========================================
CREATE TABLE IF NOT EXISTS session_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES interview_sessions(id) ON DELETE CASCADE,
  question_id UUID NOT NULL REFERENCES interview_questions(id),
  interviewer_id UUID REFERENCES ai_interviewers(id),
  
  -- Order and timing
  sequence_number INTEGER NOT NULL,
  asked_at TIMESTAMPTZ,
  answered_at TIMESTAMPTZ,
  time_taken_seconds INTEGER,
  
  -- Adaptive difficulty (AC 4)
  difficulty_at_time TEXT,
  was_skipped BOOLEAN DEFAULT false,
  follow_up_asked BOOLEAN DEFAULT false,
  follow_up_question TEXT,
  
  -- Evaluation (AC 9)
  score DECIMAL(3,2) CHECK (score BETWEEN 0 AND 10),
  feedback JSONB,
  strengths TEXT[],
  areas_to_improve TEXT[],
  
  created_at TIMESTAMPTZ DEFAULT now()
);

-- =========================================
-- VISUAL AIDS REQUESTS (AC 5, 6)
-- =========================================
CREATE TABLE IF NOT EXISTS interview_visual_aids (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES interview_sessions(id) ON DELETE CASCADE,
  transcript_id UUID REFERENCES interview_transcript(id),
  
  request_type TEXT NOT NULL CHECK (request_type IN (
    'diagram', 'timeline', 'flowchart', 'map', 'chart', 'comparison'
  )),
  request_text TEXT NOT NULL,
  
  -- Manim generation (AC 6)
  manim_status TEXT DEFAULT 'pending' CHECK (manim_status IN (
    'pending', 'generating', 'ready', 'failed'
  )),
  render_started_at TIMESTAMPTZ,
  render_completed_at TIMESTAMPTZ,
  render_duration_ms INTEGER, -- Target: 2000-6000ms
  
  video_url TEXT,
  thumbnail_url TEXT,
  
  shown_at TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ DEFAULT now()
);

-- =========================================
-- SESSION EVALUATION (AC 9)
-- =========================================
CREATE TABLE IF NOT EXISTS interview_evaluations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES interview_sessions(id) ON DELETE CASCADE UNIQUE,
  
  -- Overall scores
  overall_score DECIMAL(3,2) CHECK (overall_score BETWEEN 0 AND 10),
  communication_score DECIMAL(3,2),
  knowledge_score DECIMAL(3,2),
  analytical_score DECIMAL(3,2),
  personality_score DECIMAL(3,2),
  
  -- Detailed feedback
  strengths TEXT[],
  weaknesses TEXT[],
  improvement_suggestions TEXT[],
  
  -- Body language (optional)
  body_language_enabled BOOLEAN DEFAULT false,
  eye_contact_score DECIMAL(3,2),
  posture_score DECIMAL(3,2),
  gestures_feedback TEXT,
  
  -- AI-generated summary
  summary TEXT,
  detailed_feedback JSONB,
  
  -- Resources
  suggested_resources JSONB DEFAULT '[]',
  
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- =========================================
-- INTERVIEW HISTORY & PROGRESS
-- =========================================
CREATE TABLE IF NOT EXISTS interview_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL ,
  
  total_sessions INTEGER DEFAULT 0,
  total_duration_minutes INTEGER DEFAULT 0,
  avg_score DECIMAL(3,2),
  best_score DECIMAL(3,2),
  
  -- Topic-wise performance
  topic_scores JSONB DEFAULT '{}',
  
  -- Progress tracking
  difficulty_progression TEXT[] DEFAULT '{}',
  improvement_areas TEXT[],
  
  -- Streaks
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  last_session_date DATE,
  
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  
  UNIQUE(user_id)
);

-- =========================================
-- SEED AI INTERVIEWERS (AC 10)
-- =========================================
INSERT INTO ai_interviewers (name, role, voice_id, personality_traits, speaking_style, specialization, intro_script) VALUES
(
  'Dr. Sharma',
  'chairperson',
  'voice_mature_male_1',
  '{"warmth": 0.7, "formality": 0.8, "patience": 0.9}',
  'Speaks in measured, thoughtful manner. Uses pauses effectively. Asks probing follow-ups.',
  ARRAY['general_administration', 'governance', 'current_affairs'],
  'Good morning. I am Dr. Sharma, and I will be chairing this interview board today. Please make yourself comfortable. We are here to understand you better as a person and a potential administrator.'
),
(
  'Prof. Iyer',
  'expert',
  'voice_mature_male_2',
  '{"intensity": 0.8, "technical": 0.9, "curiosity": 0.85}',
  'Asks technical, in-depth questions. Challenges responses constructively. Values precision.',
  ARRAY['economy', 'polity', 'international_relations'],
  'I am Professor Iyer. I specialize in political economy and international affairs. I look forward to our discussion.'
),
(
  'Dr. Mehra',
  'psychology',
  'voice_mature_female_1',
  '{"empathy": 0.9, "insight": 0.85, "warmth": 0.8}',
  'Asks situational and ethical questions. Explores motivations and values. Supportive but probing.',
  ARRAY['ethics', 'personality', 'situational', 'society'],
  'Hello, I am Dr. Mehra. I am interested in understanding your thought process and how you approach complex situations.'
);

-- =========================================
-- SEED SAMPLE QUESTIONS (AC 3)
-- =========================================
INSERT INTO interview_questions (category, topic, question, difficulty_level, interviewer_type, follow_up_questions, expected_points, time_expected_seconds) VALUES
-- Chairperson questions
('personality', 'Introduction', 'Tell us about yourself and what brings you to the civil services.', 'easy', 'chairperson',
  '["What inspired this decision?", "How did your family react?"]',
  '["Background", "Motivation", "Self-awareness", "Communication clarity"]', 180),

('current_affairs', 'Governance', 'What are your views on the new criminal laws replacing the colonial-era codes?', 'medium', 'chairperson',
  '["How will implementation challenges be addressed?", "What about federalism concerns?"]',
  '["Key changes", "Benefits", "Challenges", "Balanced view"]', 150),

('governance', 'Administration', 'If you become a District Collector, what would be your priorities in the first 100 days?', 'medium', 'chairperson',
  '["How would you handle political pressure?", "What about resource constraints?"]',
  '["Understanding of role", "Prioritization", "Stakeholder awareness", "Practicality"]', 180),

-- Expert questions
('polity', 'Constitution', 'Explain the concept of cooperative federalism and its challenges in India.', 'hard', 'expert',
  '["How has GST impacted federal relations?", "Compare with competitive federalism."]',
  '["Definition", "Constitutional provisions", "Recent developments", "Challenges", "Way forward"]', 180),

('economy', 'Policy', 'Analyze the impact of PLI schemes on manufacturing sector growth.', 'hard', 'expert',
  '["Which sectors have benefited most?", "What about MSMEs?"]',
  '["Scheme details", "Sectoral analysis", "Employment impact", "Challenges"]', 180),

('international_relations', 'Geopolitics', 'How should India navigate the US-China rivalry while protecting its interests?', 'very_hard', 'expert',
  '["What about the Quad?", "How does this affect our neighborhood policy?"]',
  '["Strategic autonomy", "Multi-alignment", "Economic considerations", "Regional stability"]', 180),

-- Psychology questions
('situational', 'Ethics', 'You discover your senior officer is involved in corruption. What would you do?', 'hard', 'psychology',
  '["What if you have no proof?", "What if your career is at stake?"]',
  '["Ethical clarity", "Practical approach", "Courage", "Awareness of consequences"]', 150),

('personality', 'Motivation', 'What failures have shaped you, and what did you learn from them?', 'medium', 'psychology',
  '["How did you cope?", "Would you do anything differently?"]',
  '["Self-awareness", "Resilience", "Growth mindset", "Honesty"]', 150),

('ethics', 'Values', 'What does integrity mean to you? Give an example from your life.', 'medium', 'psychology',
  '["Was it difficult?", "What did you sacrifice?"]',
  '["Definition", "Personal example", "Authenticity", "Value consistency"]', 150),

('opinion', 'Society', 'Do you think reservation policy needs reform? Justify your view.', 'very_hard', 'psychology',
  '["How do you respond to criticism of your position?", "What alternatives exist?"]',
  '["Balanced view", "Constitutional context", "Social awareness", "Nuanced thinking"]', 180);

-- =========================================
-- INDEXES
-- =========================================
CREATE INDEX IF NOT EXISTS idx_interview_questions_category ON interview_questions(category);
CREATE INDEX IF NOT EXISTS idx_interview_questions_difficulty ON interview_questions(difficulty_level);
CREATE INDEX IF NOT EXISTS idx_interview_questions_interviewer ON interview_questions(interviewer_type);
CREATE INDEX IF NOT EXISTS idx_interview_questions_active ON interview_questions(is_active) WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_interview_sessions_user ON interview_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_interview_sessions_status ON interview_sessions(status);
CREATE INDEX IF NOT EXISTS idx_interview_sessions_room ON interview_sessions(room_id);

CREATE INDEX IF NOT EXISTS idx_interview_transcript_session ON interview_transcript(session_id);
CREATE INDEX IF NOT EXISTS idx_interview_transcript_time ON interview_transcript(session_id, timestamp_seconds);

CREATE INDEX IF NOT EXISTS idx_session_questions_session ON session_questions(session_id);

CREATE INDEX IF NOT EXISTS idx_visual_aids_session ON interview_visual_aids(session_id);

CREATE INDEX IF NOT EXISTS idx_interview_history_user ON interview_history(user_id);

-- =========================================
-- ROW LEVEL SECURITY
-- =========================================
ALTER TABLE interview_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_interviewers ENABLE ROW LEVEL SECURITY;
ALTER TABLE interview_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE interview_transcript ENABLE ROW LEVEL SECURITY;
ALTER TABLE session_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE interview_visual_aids ENABLE ROW LEVEL SECURITY;
ALTER TABLE interview_evaluations ENABLE ROW LEVEL SECURITY;
ALTER TABLE interview_history ENABLE ROW LEVEL SECURITY;

-- Public read for questions and interviewers
CREATE POLICY "Questions are viewable by authenticated users"
  ON interview_questions FOR SELECT
  TO authenticated
  USING (is_active = true);

CREATE POLICY "Interviewers are viewable by authenticated users"
  ON ai_interviewers FOR SELECT
  TO authenticated
  USING (is_active = true);

-- User access to their sessions
CREATE POLICY "Users can view their interview sessions"
  ON interview_sessions FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create interview sessions"
  ON interview_sessions FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their interview sessions"
  ON interview_sessions FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id);

-- Transcript access
CREATE POLICY "Users can view their transcript"
  ON interview_transcript FOR SELECT
  TO authenticated
  USING (
    session_id IN (SELECT id FROM interview_sessions WHERE user_id = auth.uid())
  );

CREATE POLICY "System can insert transcript"
  ON interview_transcript FOR INSERT
  TO authenticated
  WITH CHECK (
    session_id IN (SELECT id FROM interview_sessions WHERE user_id = auth.uid())
  );

-- Session questions
CREATE POLICY "Users can view their session questions"
  ON session_questions FOR SELECT
  TO authenticated
  USING (
    session_id IN (SELECT id FROM interview_sessions WHERE user_id = auth.uid())
  );

-- Visual aids
CREATE POLICY "Users can view their visual aids"
  ON interview_visual_aids FOR SELECT
  TO authenticated
  USING (
    session_id IN (SELECT id FROM interview_sessions WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can request visual aids"
  ON interview_visual_aids FOR INSERT
  TO authenticated
  WITH CHECK (
    session_id IN (SELECT id FROM interview_sessions WHERE user_id = auth.uid())
  );

-- Evaluations
CREATE POLICY "Users can view their evaluations"
  ON interview_evaluations FOR SELECT
  TO authenticated
  USING (
    session_id IN (SELECT id FROM interview_sessions WHERE user_id = auth.uid())
  );

-- History
CREATE POLICY "Users can view their interview history"
  ON interview_history FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their interview history"
  ON interview_history FOR ALL
  TO authenticated
  USING (auth.uid() = user_id);

-- =========================================
-- FUNCTIONS
-- =========================================

-- Function to start interview session
CREATE OR REPLACE FUNCTION start_interview_session(
  p_session_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_session interview_sessions%ROWTYPE;
  v_room_id TEXT;
  v_questions JSONB;
BEGIN
  -- Get session
  SELECT * INTO v_session FROM interview_sessions WHERE id = p_session_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Session not found');
  END IF;
  
  -- Generate room ID
  v_room_id := 'interview_' || p_session_id::text;
  
  -- Update session
  UPDATE interview_sessions
  SET 
    status = 'in_progress',
    started_at = now(),
    room_id = v_room_id,
    ice_servers = '[{"urls": "stun:stun.l.google.com:19302"}]'::jsonb
  WHERE id = p_session_id;
  
  -- Select questions based on difficulty and topics
  SELECT jsonb_agg(q) INTO v_questions
  FROM (
    SELECT id, question, difficulty_level, interviewer_type, category
    FROM interview_questions
    WHERE is_active = true
      AND (
        v_session.topics IS NULL OR 
        v_session.topics = '{}' OR 
        category = ANY(v_session.topics)
      )
    ORDER BY 
      CASE v_session.difficulty_level
        WHEN 'easy' THEN CASE difficulty_level WHEN 'easy' THEN 1 WHEN 'medium' THEN 2 ELSE 3 END
        WHEN 'medium' THEN CASE difficulty_level WHEN 'medium' THEN 1 WHEN 'easy' THEN 2 ELSE 3 END
        WHEN 'hard' THEN CASE difficulty_level WHEN 'hard' THEN 1 WHEN 'medium' THEN 2 ELSE 3 END
        ELSE 2
      END,
      random()
    LIMIT 10
  ) q;
  
  RETURN jsonb_build_object(
    'success', true,
    'room_id', v_room_id,
    'questions', v_questions
  );
END;
$$;

-- Function to end interview and generate evaluation
CREATE OR REPLACE FUNCTION end_interview_session(
  p_session_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_session interview_sessions%ROWTYPE;
  v_avg_score DECIMAL;
  v_question_count INTEGER;
BEGIN
  -- Get session
  SELECT * INTO v_session FROM interview_sessions WHERE id = p_session_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Session not found');
  END IF;
  
  -- Calculate average score from session questions
  SELECT AVG(score), COUNT(*) INTO v_avg_score, v_question_count
  FROM session_questions
  WHERE session_id = p_session_id AND score IS NOT NULL;
  
  -- Update session
  UPDATE interview_sessions
  SET 
    status = 'completed',
    ended_at = now(),
    actual_duration_seconds = EXTRACT(EPOCH FROM (now() - started_at))
  WHERE id = p_session_id;
  
  -- Create evaluation record
  INSERT INTO interview_evaluations (session_id, overall_score)
  VALUES (p_session_id, COALESCE(v_avg_score, 0))
  ON CONFLICT (session_id) DO UPDATE
  SET overall_score = COALESCE(v_avg_score, 0),
      updated_at = now();
  
  -- Update user history
  INSERT INTO interview_history (user_id, total_sessions, avg_score, last_session_date)
  VALUES (v_session.user_id, 1, v_avg_score, CURRENT_DATE)
  ON CONFLICT (user_id) DO UPDATE
  SET 
    total_sessions = interview_history.total_sessions + 1,
    avg_score = (interview_history.avg_score * interview_history.total_sessions + COALESCE(v_avg_score, 0)) / (interview_history.total_sessions + 1),
    last_session_date = CURRENT_DATE,
    current_streak = CASE 
      WHEN interview_history.last_session_date = CURRENT_DATE - 1 THEN interview_history.current_streak + 1
      WHEN interview_history.last_session_date = CURRENT_DATE THEN interview_history.current_streak
      ELSE 1
    END,
    longest_streak = GREATEST(
      interview_history.longest_streak,
      CASE 
        WHEN interview_history.last_session_date = CURRENT_DATE - 1 THEN interview_history.current_streak + 1
        ELSE 1
      END
    ),
    updated_at = now();
  
  RETURN jsonb_build_object(
    'success', true,
    'questions_answered', v_question_count,
    'average_score', v_avg_score
  );
END;
$$;

-- =========================================
-- GRANTS
-- =========================================
GRANT EXECUTE ON FUNCTION start_interview_session(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION end_interview_session(UUID) TO authenticated;

