-- Migration 062: Case Law Explainer - Legal Timelines
-- Story 12.3: Case Law Explainer - Legal Timelines & Amendments
-- 
-- Implements:
-- AC 1: Content types (SC cases, amendments, committees)
-- AC 2: Timeline visualization
-- AC 3: Manim animation configs
-- AC 4: Script generation
-- AC 5: Video duration 5-10 min
-- AC 6: Quiz with MCQs
-- AC 7: Related content
-- AC 8: Search functionality
-- AC 9: PDF download
-- AC 10: Admin content management

-- =================================================================
-- CASE LAW CONTENT TABLE (AC 1, 8)
-- =================================================================
CREATE TABLE IF NOT EXISTS case_law_content (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- AC 1: Content types
  content_type TEXT NOT NULL CHECK (content_type IN (
    'supreme_court_case', 'constitutional_amendment', 'committee_report',
    'high_court_case', 'tribunal_decision', 'ordinance', 'act'
  )),
  
  -- Basic info
  title TEXT NOT NULL,
  short_title TEXT, -- e.g., "Kesavananda Bharati case"
  citation TEXT, -- e.g., "(1973) 4 SCC 225"
  
  -- AC 8: Search fields
  year INTEGER,
  subject_area TEXT[], -- e.g., ['Constitutional Law', 'Basic Structure']
  keywords TEXT[] DEFAULT '{}',
  
  -- Content details
  summary TEXT NOT NULL,
  background TEXT,
  facts TEXT,
  issues TEXT[],
  held TEXT, -- Judgment/Decision
  ratio_decidendi TEXT, -- Core legal principle
  obiter_dicta TEXT,
  impact TEXT,
  
  -- Parties/People involved
  parties JSONB DEFAULT '{}', -- {"petitioner": "...", "respondent": "..."}
  bench JSONB DEFAULT '[]', -- [{"name": "...", "role": "Chief Justice"}]
  
  -- AC 2: Timeline data
  timeline_events JSONB DEFAULT '[]'::jsonb,
  -- Example: [{"date": "1973-04-24", "event": "Case filed", "description": "..."}]
  
  -- AC 7: Related content
  related_cases UUID[] DEFAULT '{}',
  related_amendments UUID[] DEFAULT '{}',
  related_articles TEXT[], -- e.g., ['Article 368', 'Article 13']
  
  -- AC 3: Animation configuration
  animation_config JSONB DEFAULT '{
    "diagram_type": "relationship",
    "flowchart_steps": [],
    "timeline_points": [],
    "comparison": null
  }'::jsonb,
  
  -- AC 4, 5: Script and video
  script TEXT,
  script_status TEXT DEFAULT 'pending',
  video_url TEXT,
  video_status TEXT DEFAULT 'pending',
  video_duration_seconds INTEGER,
  thumbnail_url TEXT,
  
  -- AC 9: PDF
  pdf_url TEXT,
  pdf_status TEXT DEFAULT 'pending',
  
  -- Stats
  view_count INTEGER DEFAULT 0,
  quiz_attempts INTEGER DEFAULT 0,
  avg_quiz_score DECIMAL(5, 2),
  
  -- Status
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'review', 'published', 'archived')),
  is_featured BOOLEAN DEFAULT false,
  
  -- AC 10: Admin
  created_by UUID ,
  reviewed_by UUID ,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  published_at TIMESTAMPTZ
);

-- =================================================================
-- CONSTITUTIONAL AMENDMENTS TABLE (AC 1, 2)
-- =================================================================
CREATE TABLE IF NOT EXISTS constitutional_amendments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  case_law_id UUID REFERENCES case_law_content(id) ON DELETE CASCADE,
  
  -- Amendment info
  amendment_number INTEGER NOT NULL,
  title TEXT NOT NULL,
  date_passed DATE,
  date_enforced DATE,
  
  -- Content
  purpose TEXT NOT NULL,
  key_changes JSONB DEFAULT '[]'::jsonb,
  -- Example: [{"article": "368", "before": "...", "after": "..."}]
  
  articles_affected TEXT[] DEFAULT '{}',
  
  -- Significance
  significance TEXT,
  controversies TEXT,
  
  -- Related cases
  related_cases UUID[] DEFAULT '{}',
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =================================================================
-- COMMITTEE REPORTS TABLE (AC 1)
-- =================================================================
CREATE TABLE IF NOT EXISTS committee_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  case_law_id UUID REFERENCES case_law_content(id) ON DELETE CASCADE,
  
  -- Committee info
  committee_name TEXT NOT NULL,
  chairman TEXT,
  members TEXT[],
  
  -- Report details
  year_constituted INTEGER,
  year_submitted INTEGER,
  mandate TEXT,
  
  -- Key recommendations
  recommendations JSONB DEFAULT '[]'::jsonb,
  -- Example: [{"title": "...", "description": "...", "implemented": true}]
  
  implementation_status TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =================================================================
-- QUIZ TABLE (AC 6)
-- =================================================================
CREATE TABLE IF NOT EXISTS case_law_quizzes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  case_law_id UUID REFERENCES case_law_content(id) ON DELETE CASCADE NOT NULL,
  
  -- Quiz config
  total_questions INTEGER DEFAULT 5,
  passing_score INTEGER DEFAULT 3,
  time_limit_seconds INTEGER DEFAULT 300, -- 5 minutes
  
  -- Questions stored as JSONB
  questions JSONB DEFAULT '[]'::jsonb,
  -- Example: [{"id": "q1", "question": "...", "options": [...], "correct": 0, "explanation": "..."}]
  
  -- Stats
  attempts_count INTEGER DEFAULT 0,
  avg_score DECIMAL(5, 2),
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =================================================================
-- QUIZ ATTEMPTS TABLE (AC 6)
-- =================================================================
CREATE TABLE IF NOT EXISTS case_law_quiz_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID  NOT NULL,
  quiz_id UUID REFERENCES case_law_quizzes(id) ON DELETE CASCADE NOT NULL,
  case_law_id UUID REFERENCES case_law_content(id) ON DELETE CASCADE NOT NULL,
  
  -- Results
  answers JSONB DEFAULT '{}'::jsonb,
  score INTEGER DEFAULT 0,
  max_score INTEGER DEFAULT 5,
  passed BOOLEAN DEFAULT false,
  
  -- Timing
  time_taken_seconds INTEGER DEFAULT 0,
  completed_at TIMESTAMPTZ DEFAULT NOW()
);

-- =================================================================
-- USER PROGRESS TABLE
-- =================================================================
CREATE TABLE IF NOT EXISTS case_law_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID  NOT NULL,
  case_law_id UUID REFERENCES case_law_content(id) ON DELETE CASCADE NOT NULL,
  
  -- Progress
  viewed BOOLEAN DEFAULT false,
  video_watched_percent INTEGER DEFAULT 0,
  quiz_completed BOOLEAN DEFAULT false,
  quiz_score INTEGER,
  pdf_downloaded BOOLEAN DEFAULT false,
  
  -- Notes
  user_notes TEXT,
  bookmarked BOOLEAN DEFAULT false,
  
  -- Timestamps
  first_viewed_at TIMESTAMPTZ DEFAULT NOW(),
  last_viewed_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id, case_law_id)
);

-- =================================================================
-- INDEXES
-- =================================================================
CREATE INDEX IF NOT EXISTS idx_case_law_type ON case_law_content(content_type);
CREATE INDEX IF NOT EXISTS idx_case_law_year ON case_law_content(year);
CREATE INDEX IF NOT EXISTS idx_case_law_status ON case_law_content(status);
CREATE INDEX IF NOT EXISTS idx_case_law_featured ON case_law_content(is_featured) WHERE is_featured = true;
CREATE INDEX IF NOT EXISTS idx_case_law_keywords ON case_law_content USING GIN(keywords);
CREATE INDEX IF NOT EXISTS idx_case_law_subjects ON case_law_content USING GIN(subject_area);

CREATE INDEX IF NOT EXISTS idx_amendments_number ON constitutional_amendments(amendment_number);
CREATE INDEX IF NOT EXISTS idx_amendments_case ON constitutional_amendments(case_law_id);

CREATE INDEX IF NOT EXISTS idx_quizzes_case ON case_law_quizzes(case_law_id);
CREATE INDEX IF NOT EXISTS idx_quiz_attempts_user ON case_law_quiz_attempts(user_id);
CREATE INDEX IF NOT EXISTS idx_quiz_attempts_quiz ON case_law_quiz_attempts(quiz_id);

CREATE INDEX IF NOT EXISTS idx_progress_user ON case_law_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_progress_case ON case_law_progress(case_law_id);

-- Full text search index (AC 8)
CREATE INDEX IF NOT EXISTS idx_case_law_search ON case_law_content 
USING GIN(to_tsvector('english', COALESCE(title, '') || ' ' || COALESCE(summary, '') || ' ' || COALESCE(citation, '')));

-- =================================================================
-- FUNCTIONS
-- =================================================================

-- Search case law content (AC 8)
CREATE OR REPLACE FUNCTION search_case_law(
  p_query TEXT DEFAULT NULL,
  p_content_type TEXT DEFAULT NULL,
  p_year INTEGER DEFAULT NULL,
  p_subject TEXT DEFAULT NULL,
  p_limit INTEGER DEFAULT 20,
  p_offset INTEGER DEFAULT 0
) RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
  v_total INTEGER;
BEGIN
  -- Count total
  SELECT COUNT(*) INTO v_total
  FROM case_law_content
  WHERE status = 'published'
    AND (p_content_type IS NULL OR content_type = p_content_type)
    AND (p_year IS NULL OR year = p_year)
    AND (p_subject IS NULL OR p_subject = ANY(subject_area))
    AND (p_query IS NULL OR 
         to_tsvector('english', COALESCE(title, '') || ' ' || COALESCE(summary, '') || ' ' || COALESCE(citation, '')) 
         @@ plainto_tsquery('english', p_query)
         OR title ILIKE '%' || p_query || '%'
         OR citation ILIKE '%' || p_query || '%');

  -- Get results
  SELECT jsonb_agg(r ORDER BY r.is_featured DESC, r.view_count DESC) INTO v_result
  FROM (
    SELECT id, title, short_title, citation, content_type, year, 
           subject_area, summary, is_featured, view_count,
           video_url IS NOT NULL as has_video,
           pdf_url IS NOT NULL as has_pdf
    FROM case_law_content
    WHERE status = 'published'
      AND (p_content_type IS NULL OR content_type = p_content_type)
      AND (p_year IS NULL OR year = p_year)
      AND (p_subject IS NULL OR p_subject = ANY(subject_area))
      AND (p_query IS NULL OR 
           to_tsvector('english', COALESCE(title, '') || ' ' || COALESCE(summary, '') || ' ' || COALESCE(citation, '')) 
           @@ plainto_tsquery('english', p_query)
           OR title ILIKE '%' || p_query || '%'
           OR citation ILIKE '%' || p_query || '%')
    ORDER BY is_featured DESC, view_count DESC
    LIMIT p_limit OFFSET p_offset
  ) r;

  RETURN jsonb_build_object(
    'items', COALESCE(v_result, '[]'::jsonb),
    'total', v_total
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get case with related content (AC 7)
CREATE OR REPLACE FUNCTION get_case_law_detail(
  p_case_id UUID,
  p_user_id UUID DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_case RECORD;
  v_related JSONB;
  v_quiz JSONB;
  v_progress JSONB;
BEGIN
  -- Get main case
  SELECT * INTO v_case FROM case_law_content WHERE id = p_case_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Case not found');
  END IF;
  
  -- Increment view count
  UPDATE case_law_content SET view_count = view_count + 1 WHERE id = p_case_id;
  
  -- Get related content
  SELECT jsonb_agg(jsonb_build_object(
    'id', c.id,
    'title', c.title,
    'content_type', c.content_type,
    'year', c.year
  )) INTO v_related
  FROM case_law_content c
  WHERE c.id = ANY(v_case.related_cases) AND c.status = 'published';
  
  -- Get quiz
  SELECT jsonb_build_object(
    'id', q.id,
    'total_questions', q.total_questions,
    'time_limit', q.time_limit_seconds,
    'attempts', q.attempts_count
  ) INTO v_quiz
  FROM case_law_quizzes q
  WHERE q.case_law_id = p_case_id;
  
  -- Get user progress
  IF p_user_id IS NOT NULL THEN
    SELECT jsonb_build_object(
      'viewed', p.viewed,
      'video_watched_percent', p.video_watched_percent,
      'quiz_completed', p.quiz_completed,
      'quiz_score', p.quiz_score,
      'bookmarked', p.bookmarked
    ) INTO v_progress
    FROM case_law_progress p
    WHERE p.user_id = p_user_id AND p.case_law_id = p_case_id;
  END IF;
  
  RETURN jsonb_build_object(
    'case', row_to_json(v_case),
    'related', COALESCE(v_related, '[]'::jsonb),
    'quiz', v_quiz,
    'progress', v_progress
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Submit quiz attempt (AC 6)
CREATE OR REPLACE FUNCTION submit_case_law_quiz(
  p_user_id UUID,
  p_quiz_id UUID,
  p_answers JSONB,
  p_time_taken INTEGER
) RETURNS JSONB AS $$
DECLARE
  v_quiz RECORD;
  v_score INTEGER := 0;
  v_questions JSONB;
  v_passed BOOLEAN;
  v_attempt_id UUID;
BEGIN
  SELECT * INTO v_quiz FROM case_law_quizzes WHERE id = p_quiz_id;
  v_questions := v_quiz.questions;
  
  -- Calculate score
  FOR i IN 0..(jsonb_array_length(v_questions) - 1)
  LOOP
    IF (p_answers->>(i::text))::integer = (v_questions->i->>'correct')::integer THEN
      v_score := v_score + 1;
    END IF;
  END LOOP;
  
  v_passed := v_score >= v_quiz.passing_score;
  
  -- Record attempt
  INSERT INTO case_law_quiz_attempts (
    user_id, quiz_id, case_law_id, answers, score, max_score, passed, time_taken_seconds
  ) VALUES (
    p_user_id, p_quiz_id, v_quiz.case_law_id, p_answers, v_score, v_quiz.total_questions, v_passed, p_time_taken
  ) RETURNING id INTO v_attempt_id;
  
  -- Update quiz stats
  UPDATE case_law_quizzes SET
    attempts_count = attempts_count + 1,
    avg_score = (COALESCE(avg_score, 0) * attempts_count + v_score) / (attempts_count + 1)
  WHERE id = p_quiz_id;
  
  -- Update user progress
  INSERT INTO case_law_progress (user_id, case_law_id, quiz_completed, quiz_score)
  VALUES (p_user_id, v_quiz.case_law_id, true, v_score)
  ON CONFLICT (user_id, case_law_id) DO UPDATE SET
    quiz_completed = true,
    quiz_score = GREATEST(case_law_progress.quiz_score, v_score);
  
  RETURN jsonb_build_object(
    'attempt_id', v_attempt_id,
    'score', v_score,
    'max_score', v_quiz.total_questions,
    'passed', v_passed,
    'questions', v_questions
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =================================================================
-- SAMPLE DATA (AC 1)
-- =================================================================

-- Landmark Supreme Court Case
INSERT INTO case_law_content (
  content_type, title, short_title, citation, year,
  subject_area, keywords, summary, background, facts, issues, held,
  ratio_decidendi, impact, parties, bench, status, is_featured
) VALUES (
  'supreme_court_case',
  'Kesavananda Bharati vs State of Kerala',
  'Kesavananda Bharati case',
  '(1973) 4 SCC 225',
  1973,
  ARRAY['Constitutional Law', 'Basic Structure', 'Amendment Power'],
  ARRAY['basic structure', 'constitutional amendment', 'article 368', 'fundamental rights'],
  'Landmark case that established the Basic Structure Doctrine, limiting Parliament''s power to amend the Constitution.',
  'The case arose from a challenge to the Kerala Land Reforms Act, 1963.',
  'Sri Kesavananda Bharati, head of a Hindu mutt in Kerala, challenged the validity of the Kerala Land Reforms Act.',
  ARRAY['Can Parliament amend any part of the Constitution?', 'Is there a limit to the amending power under Article 368?'],
  'Parliament can amend any provision of the Constitution but cannot alter its basic structure.',
  'Parliament has wide powers of amendment but cannot destroy the basic structure or framework of the Constitution.',
  'Created judicial review of constitutional amendments, fundamentally shaped Indian constitutional jurisprudence.',
  '{"petitioner": "His Holiness Kesavananda Bharati Sripadagalvaru", "respondent": "State of Kerala"}'::jsonb,
  '[{"name": "S.M. Sikri", "role": "Chief Justice"}, {"name": "A.N. Grover", "role": "Justice"}]'::jsonb,
  'published',
  true
);

-- Constitutional Amendment
INSERT INTO case_law_content (
  content_type, title, short_title, year,
  subject_area, keywords, summary, impact, status
) VALUES (
  'constitutional_amendment',
  '42nd Constitutional Amendment Act, 1976',
  '42nd Amendment',
  1976,
  ARRAY['Constitutional Law', 'Fundamental Rights', 'Directive Principles'],
  ARRAY['mini constitution', 'emergency', '42nd amendment', 'fundamental duties'],
  'Known as the "Mini Constitution" for the extensive changes it made, including adding Fundamental Duties.',
  'Significantly altered the balance between Fundamental Rights and Directive Principles.',
  'published'
);

-- Committee Report
INSERT INTO case_law_content (
  content_type, title, short_title, year,
  subject_area, keywords, summary, status
) VALUES (
  'committee_report',
  'Sarkaria Commission Report on Centre-State Relations',
  'Sarkaria Commission',
  1988,
  ARRAY['Federalism', 'Centre-State Relations', 'Constitutional Bodies'],
  ARRAY['federalism', 'state autonomy', 'governors', 'all india services'],
  'Comprehensive report on improving Centre-State relations in India''s federal structure.',
  'published'
);

-- =================================================================
-- ROW LEVEL SECURITY
-- =================================================================
ALTER TABLE case_law_content ENABLE ROW LEVEL SECURITY;
ALTER TABLE constitutional_amendments ENABLE ROW LEVEL SECURITY;
ALTER TABLE committee_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE case_law_quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE case_law_quiz_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE case_law_progress ENABLE ROW LEVEL SECURITY;

-- Public read for published content
CREATE POLICY "Anyone can view published case law" ON case_law_content
  FOR SELECT USING (status = 'published');

CREATE POLICY "Anyone can view amendments" ON constitutional_amendments
  FOR SELECT USING (true);

CREATE POLICY "Anyone can view committee reports" ON committee_reports
  FOR SELECT USING (true);

CREATE POLICY "Anyone can view quizzes" ON case_law_quizzes
  FOR SELECT USING (true);

-- User-specific data
CREATE POLICY "Users can manage own quiz attempts" ON case_law_quiz_attempts
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own progress" ON case_law_progress
  FOR ALL USING (auth.uid() = user_id);

