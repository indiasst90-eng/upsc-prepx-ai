-- Migration 064: Interview Debrief - Video Generation
-- Story 13.2: Interview Debrief Video Generation
-- 
-- AC 1: Debrief generation triggered after interview
-- AC 2: LLM analysis of transcript
-- AC 3: Video structure (summary, highlights, improvements)
-- AC 4: Manim visualizations (confidence, scores)
-- AC 5: Duration 5-8 minutes
-- AC 6: Render time <5 minutes
-- AC 7: Notification "debrief ready"
-- AC 8: Archive to history
-- AC 9: Share with mentor
-- AC 10: Compare with previous scores

-- =========================================
-- DEBRIEF VIDEOS TABLE (AC 1, 8)
-- =========================================
CREATE TABLE IF NOT EXISTS interview_debriefs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES interview_sessions(id) ON DELETE CASCADE UNIQUE,
  user_id UUID NOT NULL ,
  
  -- Generation status
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
    'pending', 'analyzing', 'scripting', 'rendering', 'ready', 'failed'
  )),
  
  -- LLM Analysis (AC 2)
  transcript_analysis JSONB,
  strengths_identified TEXT[],
  weaknesses_identified TEXT[],
  best_answers JSONB DEFAULT '[]', -- Array of {question, response, score, feedback}
  improvement_areas JSONB DEFAULT '[]',
  
  -- Video structure (AC 3)
  script JSONB, -- Structured script with sections
  script_sections JSONB DEFAULT '[
    {"type": "summary", "duration_seconds": 120},
    {"type": "best_answers", "duration_seconds": 180},
    {"type": "improvements", "duration_seconds": 120},
    {"type": "resources", "duration_seconds": 60}
  ]',
  
  -- Manim visualizations config (AC 4)
  visualizations JSONB DEFAULT '{
    "confidence_meter": true,
    "topic_scores_chart": true,
    "comparison_graph": true,
    "timeline": true
  }',
  
  -- Duration targets (AC 5)
  target_duration_seconds INTEGER DEFAULT 360, -- 6 minutes target
  actual_duration_seconds INTEGER,
  
  -- Render info (AC 6)
  render_started_at TIMESTAMPTZ,
  render_completed_at TIMESTAMPTZ,
  render_duration_seconds INTEGER,
  
  -- Video URLs
  video_url TEXT,
  thumbnail_url TEXT,
  
  -- Notification (AC 7)
  notification_sent BOOLEAN DEFAULT false,
  notification_sent_at TIMESTAMPTZ,
  
  -- Sharing (AC 9)
  share_enabled BOOLEAN DEFAULT false,
  share_token TEXT UNIQUE,
  shared_with TEXT[], -- Array of user IDs or emails
  mentor_feedback JSONB,
  
  -- Comparison data (AC 10)
  previous_session_id UUID REFERENCES interview_sessions(id),
  score_improvement DECIMAL(5,2),
  comparison_insights TEXT[],
  
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- =========================================
-- DEBRIEF SECTIONS (AC 3)
-- =========================================
CREATE TABLE IF NOT EXISTS debrief_sections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  debrief_id UUID NOT NULL REFERENCES interview_debriefs(id) ON DELETE CASCADE,
  
  section_type TEXT NOT NULL CHECK (section_type IN (
    'intro', 'summary', 'best_answer', 'improvement', 'comparison', 'resources', 'closing'
  )),
  sequence_number INTEGER NOT NULL,
  
  -- Content
  title TEXT NOT NULL,
  narration_text TEXT NOT NULL,
  
  -- Visual config
  visual_type TEXT CHECK (visual_type IN ('manim', 'highlight', 'chart', 'text')),
  visual_config JSONB,
  
  -- Timing
  start_time_seconds DECIMAL(8,2),
  duration_seconds DECIMAL(6,2),
  
  -- Rendering
  video_segment_url TEXT,
  render_status TEXT DEFAULT 'pending',
  
  created_at TIMESTAMPTZ DEFAULT now()
);

-- =========================================
-- MENTOR FEEDBACK (AC 9)
-- =========================================
CREATE TABLE IF NOT EXISTS mentor_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  debrief_id UUID NOT NULL REFERENCES interview_debriefs(id) ON DELETE CASCADE,
  mentor_id UUID ,
  mentor_email TEXT,
  
  -- Feedback
  overall_rating INTEGER CHECK (overall_rating BETWEEN 1 AND 5),
  comments TEXT,
  detailed_feedback JSONB,
  
  -- Question-specific feedback
  question_feedback JSONB DEFAULT '[]',
  
  -- Suggestions
  suggested_resources TEXT[],
  focus_areas TEXT[],
  
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- =========================================
-- PERFORMANCE COMPARISONS (AC 10)
-- =========================================
CREATE TABLE IF NOT EXISTS interview_comparisons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL ,
  
  -- Sessions being compared
  current_session_id UUID NOT NULL REFERENCES interview_sessions(id),
  previous_session_id UUID NOT NULL REFERENCES interview_sessions(id),
  
  -- Score comparisons
  current_overall_score DECIMAL(3,2),
  previous_overall_score DECIMAL(3,2),
  score_change DECIMAL(5,2),
  
  -- Dimension comparisons
  dimension_changes JSONB, -- {communication: +0.5, knowledge: -0.2, ...}
  
  -- Topic improvements
  topic_improvements JSONB, -- {polity: +1.2, ethics: +0.5, ...}
  topic_declines JSONB,
  
  -- Insights
  improvement_summary TEXT,
  concern_areas TEXT[],
  recommendations TEXT[],
  
  created_at TIMESTAMPTZ DEFAULT now()
);

-- =========================================
-- NOTIFICATION QUEUE (AC 7)
-- =========================================
CREATE TABLE IF NOT EXISTS debrief_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  debrief_id UUID NOT NULL REFERENCES interview_debriefs(id) ON DELETE CASCADE,
  user_id UUID NOT NULL ,
  
  notification_type TEXT NOT NULL CHECK (notification_type IN (
    'debrief_ready', 'mentor_shared', 'mentor_feedback', 'comparison_ready'
  )),
  
  -- Delivery channels
  send_push BOOLEAN DEFAULT true,
  send_email BOOLEAN DEFAULT true,
  send_in_app BOOLEAN DEFAULT true,
  
  -- Status
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed')),
  sent_at TIMESTAMPTZ,
  error_message TEXT,
  
  created_at TIMESTAMPTZ DEFAULT now()
);

-- =========================================
-- INDEXES
-- =========================================
CREATE INDEX IF NOT EXISTS idx_debriefs_session ON interview_debriefs(session_id);
CREATE INDEX IF NOT EXISTS idx_debriefs_user ON interview_debriefs(user_id);
CREATE INDEX IF NOT EXISTS idx_debriefs_status ON interview_debriefs(status);
CREATE INDEX IF NOT EXISTS idx_debriefs_share_token ON interview_debriefs(share_token);

CREATE INDEX IF NOT EXISTS idx_debrief_sections_debrief ON debrief_sections(debrief_id);
CREATE INDEX IF NOT EXISTS idx_debrief_sections_sequence ON debrief_sections(debrief_id, sequence_number);

CREATE INDEX IF NOT EXISTS idx_mentor_feedback_debrief ON mentor_feedback(debrief_id);

CREATE INDEX IF NOT EXISTS idx_comparisons_user ON interview_comparisons(user_id);
CREATE INDEX IF NOT EXISTS idx_comparisons_sessions ON interview_comparisons(current_session_id, previous_session_id);

CREATE INDEX IF NOT EXISTS idx_notifications_debrief ON debrief_notifications(debrief_id);
CREATE INDEX IF NOT EXISTS idx_notifications_pending ON debrief_notifications(status) WHERE status = 'pending';

-- =========================================
-- ROW LEVEL SECURITY
-- =========================================
ALTER TABLE interview_debriefs ENABLE ROW LEVEL SECURITY;
ALTER TABLE debrief_sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE mentor_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE interview_comparisons ENABLE ROW LEVEL SECURITY;
ALTER TABLE debrief_notifications ENABLE ROW LEVEL SECURITY;

-- Debrief access
CREATE POLICY "Users can view their debriefs"
  ON interview_debriefs FOR SELECT
  TO authenticated
  USING (user_id = auth.uid() OR share_token IS NOT NULL);

CREATE POLICY "System can manage debriefs"
  ON interview_debriefs FOR ALL
  TO authenticated
  USING (user_id = auth.uid());

-- Section access
CREATE POLICY "Users can view their debrief sections"
  ON debrief_sections FOR SELECT
  TO authenticated
  USING (
    debrief_id IN (SELECT id FROM interview_debriefs WHERE user_id = auth.uid())
  );

-- Mentor feedback
CREATE POLICY "Mentors can add feedback"
  ON mentor_feedback FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Users can view feedback on their debriefs"
  ON mentor_feedback FOR SELECT
  TO authenticated
  USING (
    debrief_id IN (SELECT id FROM interview_debriefs WHERE user_id = auth.uid())
  );

-- Comparisons
CREATE POLICY "Users can view their comparisons"
  ON interview_comparisons FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Notifications
CREATE POLICY "Users can view their notifications"
  ON debrief_notifications FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- =========================================
-- FUNCTIONS
-- =========================================

-- Function to trigger debrief generation (AC 1)
CREATE OR REPLACE FUNCTION trigger_debrief_generation()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Only trigger when session status changes to 'completed'
  IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
    -- Create debrief record
    INSERT INTO interview_debriefs (session_id, user_id, status)
    VALUES (NEW.id, NEW.user_id, 'pending');
    
    -- Get previous session for comparison (AC 10)
    UPDATE interview_debriefs
    SET previous_session_id = (
      SELECT id FROM interview_sessions
      WHERE user_id = NEW.user_id
        AND id != NEW.id
        AND status = 'completed'
      ORDER BY ended_at DESC
      LIMIT 1
    )
    WHERE session_id = NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Create trigger for automatic debrief generation
DROP TRIGGER IF EXISTS trigger_debrief_on_session_complete ON interview_sessions;
CREATE TRIGGER trigger_debrief_on_session_complete
  AFTER UPDATE ON interview_sessions
  FOR EACH ROW
  EXECUTE FUNCTION trigger_debrief_generation();

-- Function to generate comparison (AC 10)
CREATE OR REPLACE FUNCTION generate_interview_comparison(
  p_debrief_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_debrief interview_debriefs%ROWTYPE;
  v_current_eval interview_evaluations%ROWTYPE;
  v_previous_eval interview_evaluations%ROWTYPE;
  v_comparison JSONB;
BEGIN
  -- Get debrief
  SELECT * INTO v_debrief FROM interview_debriefs WHERE id = p_debrief_id;
  
  IF NOT FOUND OR v_debrief.previous_session_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'No previous session to compare');
  END IF;
  
  -- Get evaluations
  SELECT * INTO v_current_eval FROM interview_evaluations WHERE session_id = v_debrief.session_id;
  SELECT * INTO v_previous_eval FROM interview_evaluations WHERE session_id = v_debrief.previous_session_id;
  
  IF v_current_eval IS NULL OR v_previous_eval IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Missing evaluations');
  END IF;
  
  -- Calculate score improvement
  UPDATE interview_debriefs
  SET 
    score_improvement = v_current_eval.overall_score - v_previous_eval.overall_score,
    comparison_insights = ARRAY[
      CASE 
        WHEN v_current_eval.overall_score > v_previous_eval.overall_score 
        THEN 'Overall score improved by ' || ROUND((v_current_eval.overall_score - v_previous_eval.overall_score)::numeric, 1) || ' points'
        ELSE 'Overall score decreased by ' || ROUND((v_previous_eval.overall_score - v_current_eval.overall_score)::numeric, 1) || ' points'
      END
    ]
  WHERE id = p_debrief_id;
  
  -- Create comparison record
  INSERT INTO interview_comparisons (
    user_id,
    current_session_id,
    previous_session_id,
    current_overall_score,
    previous_overall_score,
    score_change,
    dimension_changes
  )
  VALUES (
    v_debrief.user_id,
    v_debrief.session_id,
    v_debrief.previous_session_id,
    v_current_eval.overall_score,
    v_previous_eval.overall_score,
    v_current_eval.overall_score - v_previous_eval.overall_score,
    jsonb_build_object(
      'communication', COALESCE(v_current_eval.communication_score, 0) - COALESCE(v_previous_eval.communication_score, 0),
      'knowledge', COALESCE(v_current_eval.knowledge_score, 0) - COALESCE(v_previous_eval.knowledge_score, 0),
      'analytical', COALESCE(v_current_eval.analytical_score, 0) - COALESCE(v_previous_eval.analytical_score, 0),
      'personality', COALESCE(v_current_eval.personality_score, 0) - COALESCE(v_previous_eval.personality_score, 0)
    )
  );
  
  RETURN jsonb_build_object(
    'success', true,
    'current_score', v_current_eval.overall_score,
    'previous_score', v_previous_eval.overall_score,
    'improvement', v_current_eval.overall_score - v_previous_eval.overall_score
  );
END;
$$;

-- Function to create share token (AC 9)
CREATE OR REPLACE FUNCTION create_debrief_share_token(
  p_debrief_id UUID
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_token TEXT;
BEGIN
  v_token := encode(gen_random_bytes(32), 'base64');
  v_token := replace(replace(replace(v_token, '+', '-'), '/', '_'), '=', '');
  
  UPDATE interview_debriefs
  SET 
    share_enabled = true,
    share_token = v_token
  WHERE id = p_debrief_id;
  
  RETURN v_token;
END;
$$;

-- Function to send notification (AC 7)
CREATE OR REPLACE FUNCTION queue_debrief_notification(
  p_debrief_id UUID,
  p_notification_type TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_notification_id UUID;
BEGIN
  SELECT user_id INTO v_user_id FROM interview_debriefs WHERE id = p_debrief_id;
  
  INSERT INTO debrief_notifications (debrief_id, user_id, notification_type)
  VALUES (p_debrief_id, v_user_id, p_notification_type)
  RETURNING id INTO v_notification_id;
  
  RETURN v_notification_id;
END;
$$;

-- =========================================
-- GRANTS
-- =========================================
GRANT EXECUTE ON FUNCTION generate_interview_comparison(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION create_debrief_share_token(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION queue_debrief_notification(UUID, TEXT) TO authenticated;

