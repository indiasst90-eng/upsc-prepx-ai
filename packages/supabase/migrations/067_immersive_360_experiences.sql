-- Migration: 067_immersive_360_experiences.sql
-- Description: 360° Immersive Visualizations with VR compatibility
-- Story: 15.1
-- Created: 2025-12-28

-- =====================================================
-- IMMERSIVE EXPERIENCE CATEGORIES
-- =====================================================
CREATE TABLE IF NOT EXISTS immersive_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  subject TEXT NOT NULL CHECK (subject IN ('history', 'geography', 'culture', 'monuments', 'battles', 'rivers', 'mountains')),
  description TEXT,
  thumbnail_url TEXT,
  icon TEXT DEFAULT '🌍',
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- =====================================================
-- IMMERSIVE EXPERIENCES (Main content)
-- =====================================================
CREATE TABLE IF NOT EXISTS immersive_experiences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID ,
  category_id UUID REFERENCES immersive_categories(id),
  
  -- Basic info
  title TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  description TEXT,
  subject TEXT NOT NULL CHECK (subject IN ('history', 'geography')),
  topic TEXT NOT NULL,
  
  -- Content specifications
  duration_seconds INTEGER NOT NULL CHECK (duration_seconds BETWEEN 300 AND 900), -- 5-15 minutes
  resolution TEXT DEFAULT '4K' CHECK (resolution IN ('1080p', '2K', '4K', '8K')),
  framerate INTEGER DEFAULT 60 CHECK (framerate IN (30, 60, 120)),
  
  -- Media URLs
  preview_thumbnail TEXT,
  preview_video_url TEXT,
  main_360_video_url TEXT,
  audio_narration_url TEXT,
  spatial_audio_config JSONB DEFAULT '{"enabled": true, "channels": 8}',
  
  -- VR/WebXR configuration
  webxr_config JSONB DEFAULT '{
    "enabled": true,
    "supported_headsets": ["Oculus Quest", "HTC Vive", "Valve Index", "PSVR2"],
    "fallback_mobile_360": true,
    "hand_tracking": false,
    "room_scale": true
  }',
  
  -- Navigation settings
  navigation_config JSONB DEFAULT '{
    "auto_rotate": false,
    "rotation_speed": 0.5,
    "zoom_enabled": true,
    "zoom_min": 0.5,
    "zoom_max": 2.0,
    "scene_transitions": "fade"
  }',
  
  -- Pro/Premium gating (AC 10)
  is_premium BOOLEAN DEFAULT true,
  required_tier TEXT DEFAULT 'pro' CHECK (required_tier IN ('free', 'pro', 'annual')),
  
  -- Status
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'processing', 'ready', 'published', 'archived')),
  published_at TIMESTAMPTZ,
  view_count INTEGER DEFAULT 0,
  avg_rating DECIMAL(3,2),
  
  -- Metadata
  tags TEXT[],
  upsc_relevance TEXT,
  syllabus_topics TEXT[],
  
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- =====================================================
-- IMMERSIVE SCENES (Multiple scenes per experience)
-- =====================================================
CREATE TABLE IF NOT EXISTS immersive_scenes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  experience_id UUID REFERENCES immersive_experiences(id) ON DELETE CASCADE,
  
  -- Scene info
  scene_order INTEGER NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  duration_seconds INTEGER NOT NULL,
  
  -- Media
  scene_360_url TEXT NOT NULL,
  thumbnail_url TEXT,
  audio_url TEXT,
  narration_text TEXT,
  
  -- Scene navigation
  start_position JSONB DEFAULT '{"x": 0, "y": 0, "z": 0}',
  initial_view_direction JSONB DEFAULT '{"yaw": 0, "pitch": 0}',
  
  -- Transition to next scene
  transition_type TEXT DEFAULT 'fade' CHECK (transition_type IN ('fade', 'dissolve', 'wipe', 'zoom', 'teleport')),
  transition_duration_ms INTEGER DEFAULT 1000,
  
  created_at TIMESTAMPTZ DEFAULT now()
);

-- =====================================================
-- INTERACTIVE HOTSPOTS (AC 3)
-- =====================================================
CREATE TABLE IF NOT EXISTS immersive_hotspots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scene_id UUID REFERENCES immersive_scenes(id) ON DELETE CASCADE,
  
  -- Position in 3D space (spherical coordinates)
  position JSONB NOT NULL, -- {"yaw": 45, "pitch": 10, "distance": 1}
  
  -- Hotspot appearance
  hotspot_type TEXT DEFAULT 'info' CHECK (hotspot_type IN ('info', 'media', 'quiz', 'navigation', 'audio')),
  icon TEXT DEFAULT 'ℹ️',
  label TEXT NOT NULL,
  size TEXT DEFAULT 'medium' CHECK (size IN ('small', 'medium', 'large')),
  color TEXT DEFAULT '#3B82F6',
  pulse_animation BOOLEAN DEFAULT true,
  
  -- Content displayed on click
  content JSONB NOT NULL,
  -- For info: {"title": "", "description": "", "images": [], "facts": []}
  -- For media: {"type": "video/image", "url": "", "caption": ""}
  -- For quiz: {"question": "", "options": [], "correct": 0, "explanation": ""}
  -- For navigation: {"target_scene_id": "", "transition": "fade"}
  -- For audio: {"url": "", "description": "", "autoplay": false}
  
  -- Visibility timing
  visible_from_seconds INTEGER DEFAULT 0,
  visible_until_seconds INTEGER,
  
  -- Analytics
  click_count INTEGER DEFAULT 0,
  
  created_at TIMESTAMPTZ DEFAULT now()
);

-- =====================================================
-- EMBEDDED QUIZZES (AC 4)
-- =====================================================
CREATE TABLE IF NOT EXISTS immersive_quizzes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  experience_id UUID REFERENCES immersive_experiences(id) ON DELETE CASCADE,
  scene_id UUID REFERENCES immersive_scenes(id),
  
  -- Quiz timing
  trigger_type TEXT DEFAULT 'timed' CHECK (trigger_type IN ('timed', 'hotspot', 'scene_end', 'experience_end')),
  trigger_at_seconds INTEGER,
  
  -- Question
  question TEXT NOT NULL,
  question_type TEXT DEFAULT 'mcq' CHECK (question_type IN ('mcq', 'true_false', 'short_answer')),
  options JSONB, -- ["Option A", "Option B", "Option C", "Option D"]
  correct_answer INTEGER, -- index for MCQ, 0/1 for T/F
  correct_text TEXT, -- for short answer
  explanation TEXT,
  
  -- Points
  points INTEGER DEFAULT 10,
  time_limit_seconds INTEGER DEFAULT 30,
  
  -- Visual
  overlay_style TEXT DEFAULT 'modal' CHECK (overlay_style IN ('modal', 'inline', 'bottom_bar')),
  
  created_at TIMESTAMPTZ DEFAULT now()
);

-- =====================================================
-- USER WATCH PROGRESS
-- =====================================================
CREATE TABLE IF NOT EXISTS immersive_user_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID ,
  experience_id UUID REFERENCES immersive_experiences(id) ON DELETE CASCADE,
  
  -- Progress
  current_scene_id UUID REFERENCES immersive_scenes(id),
  watch_progress_seconds INTEGER DEFAULT 0,
  total_watch_time_seconds INTEGER DEFAULT 0,
  completed_at TIMESTAMPTZ,
  
  -- Quiz results
  quizzes_attempted INTEGER DEFAULT 0,
  quizzes_correct INTEGER DEFAULT 0,
  total_quiz_points INTEGER DEFAULT 0,
  
  -- Hotspots explored
  hotspots_clicked UUID[] DEFAULT '{}',
  
  -- Rating
  user_rating INTEGER CHECK (user_rating BETWEEN 1 AND 5),
  
  -- Device info
  last_device TEXT,
  vr_headset_used TEXT,
  
  started_at TIMESTAMPTZ DEFAULT now(),
  last_watched_at TIMESTAMPTZ DEFAULT now(),
  
  UNIQUE(user_id, experience_id)
);

-- =====================================================
-- USER QUIZ RESPONSES
-- =====================================================
CREATE TABLE IF NOT EXISTS immersive_quiz_responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID ,
  quiz_id UUID REFERENCES immersive_quizzes(id) ON DELETE CASCADE,
  experience_id UUID REFERENCES immersive_experiences(id),
  
  user_answer INTEGER,
  user_answer_text TEXT,
  is_correct BOOLEAN NOT NULL,
  time_taken_seconds INTEGER,
  points_earned INTEGER DEFAULT 0,
  
  answered_at TIMESTAMPTZ DEFAULT now(),
  
  UNIQUE(user_id, quiz_id)
);

-- =====================================================
-- EXPERIENCE COLLECTIONS (Curated playlists)
-- =====================================================
CREATE TABLE IF NOT EXISTS immersive_collections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  description TEXT,
  thumbnail_url TEXT,
  
  -- Collection metadata
  subject TEXT,
  is_featured BOOLEAN DEFAULT false,
  display_order INTEGER DEFAULT 0,
  
  -- Requirements
  required_tier TEXT DEFAULT 'pro',
  
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS immersive_collection_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  collection_id UUID REFERENCES immersive_collections(id) ON DELETE CASCADE,
  experience_id UUID REFERENCES immersive_experiences(id) ON DELETE CASCADE,
  item_order INTEGER NOT NULL,
  
  UNIQUE(collection_id, experience_id)
);

-- =====================================================
-- VR DEVICE COMPATIBILITY (AC 2)
-- =====================================================
CREATE TABLE IF NOT EXISTS vr_device_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_name TEXT NOT NULL,
  manufacturer TEXT,
  
  -- Technical specs
  display_resolution TEXT,
  refresh_rate INTEGER,
  field_of_view INTEGER,
  
  -- WebXR support
  webxr_supported BOOLEAN DEFAULT true,
  hand_tracking BOOLEAN DEFAULT false,
  room_scale BOOLEAN DEFAULT true,
  
  -- Fallback options
  fallback_to_mobile BOOLEAN DEFAULT true,
  
  -- Optimized settings for this device
  recommended_config JSONB,
  
  created_at TIMESTAMPTZ DEFAULT now()
);

-- =====================================================
-- SPATIAL AUDIO MARKERS (AC 6)
-- =====================================================
CREATE TABLE IF NOT EXISTS spatial_audio_sources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scene_id UUID REFERENCES immersive_scenes(id) ON DELETE CASCADE,
  
  -- 3D position
  position JSONB NOT NULL, -- {"x": 0, "y": 0, "z": 0}
  
  -- Audio source
  audio_url TEXT NOT NULL,
  audio_type TEXT DEFAULT 'ambient' CHECK (audio_type IN ('ambient', 'narration', 'effect', 'music')),
  
  -- Spatialization
  rolloff_factor DECIMAL(3,2) DEFAULT 1.0,
  max_distance DECIMAL(5,2) DEFAULT 100.0,
  reference_distance DECIMAL(5,2) DEFAULT 1.0,
  
  -- Playback
  volume DECIMAL(3,2) DEFAULT 1.0,
  loop BOOLEAN DEFAULT false,
  autoplay BOOLEAN DEFAULT true,
  
  -- Timing
  start_at_seconds INTEGER DEFAULT 0,
  duration_seconds INTEGER,
  
  created_at TIMESTAMPTZ DEFAULT now()
);

-- =====================================================
-- SEED DATA: Categories
-- =====================================================
INSERT INTO immersive_categories (name, slug, subject, description, icon, display_order) VALUES
('Battle of Panipat', 'battle-panipat', 'battles', 'Experience the three historic battles of Panipat', '⚔️', 1),
('Himalayan Geography', 'himalayan-geography', 'mountains', 'Explore the majestic Himalayan mountain range', '🏔️', 2),
('Indus Valley Civilization', 'indus-valley', 'history', 'Walk through the ancient cities of Mohenjo-daro and Harappa', '🏛️', 3),
('Indian River Systems', 'indian-rivers', 'rivers', 'Journey along India''s major river systems', '🌊', 4),
('Mughal Architecture', 'mughal-architecture', 'monuments', 'Explore iconic Mughal monuments in VR', '🕌', 5),
('Western Ghats Biodiversity', 'western-ghats', 'geography', 'Discover the biodiversity hotspot of Western Ghats', '🌿', 6),
('Indian Independence Movement', 'independence-movement', 'history', 'Relive key moments of India''s freedom struggle', '🇮🇳', 7),
('Coastal Landforms', 'coastal-landforms', 'geography', 'Explore India''s diverse coastal geography', '🏖️', 8)
ON CONFLICT (slug) DO NOTHING;

-- =====================================================
-- SEED DATA: Sample Experience
-- =====================================================
INSERT INTO immersive_experiences (
  title, slug, description, subject, topic,
  duration_seconds, resolution, framerate,
  status, is_premium, required_tier,
  tags, upsc_relevance, syllabus_topics
) VALUES (
  'Battle of Plassey 1757',
  'battle-of-plassey-1757',
  'Experience the pivotal Battle of Plassey that laid the foundation for British colonial rule in India. Walk through the battlefield, understand the strategies, and witness key moments.',
  'history',
  'British Colonial Period',
  600, -- 10 minutes
  '4K',
  60,
  'published',
  true,
  'pro',
  ARRAY['british-india', 'battle', 'colonial-history', '18th-century'],
  'Frequently asked in GS Paper I - Modern Indian History',
  ARRAY['Modern History', 'Colonial Period', 'British East India Company']
) ON CONFLICT (slug) DO NOTHING;

-- =====================================================
-- SEED DATA: VR Devices
-- =====================================================
INSERT INTO vr_device_profiles (device_name, manufacturer, display_resolution, refresh_rate, field_of_view, webxr_supported, hand_tracking, room_scale) VALUES
('Quest 3', 'Meta', '2064x2208 per eye', 120, 110, true, true, true),
('Quest 2', 'Meta', '1832x1920 per eye', 90, 106, true, true, true),
('PSVR2', 'Sony', '2000x2040 per eye', 120, 110, true, false, true),
('Valve Index', 'Valve', '1440x1600 per eye', 144, 130, true, true, true),
('HTC Vive Pro 2', 'HTC', '2448x2448 per eye', 120, 120, true, true, true),
('Pico 4', 'Pico', '2160x2160 per eye', 90, 105, true, true, true),
('Mobile 360', 'Generic', 'Device Native', 60, 360, true, false, false);

-- =====================================================
-- FUNCTIONS
-- =====================================================

-- Check premium access
CREATE OR REPLACE FUNCTION check_immersive_access(
  p_user_id UUID,
  p_experience_id UUID
) RETURNS JSONB AS $$
DECLARE
  v_exp RECORD;
  v_user_tier TEXT;
  v_has_access BOOLEAN := false;
BEGIN
  -- Get experience requirements
  SELECT required_tier, is_premium INTO v_exp
  FROM immersive_experiences WHERE id = p_experience_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('access', false, 'reason', 'Experience not found');
  END IF;
  
  -- Free content
  IF NOT v_exp.is_premium THEN
    RETURN jsonb_build_object('access', true, 'reason', 'Free content');
  END IF;
  
  -- Check user subscription (simplified - would integrate with actual subscription table)
  SELECT tier INTO v_user_tier FROM user_subscriptions 
  WHERE user_id = p_user_id AND status = 'active'
  ORDER BY created_at DESC LIMIT 1;
  
  IF v_user_tier IS NULL THEN
    RETURN jsonb_build_object('access', false, 'reason', 'Subscription required', 'required_tier', v_exp.required_tier);
  END IF;
  
  -- Check tier hierarchy
  IF v_exp.required_tier = 'free' THEN
    v_has_access := true;
  ELSIF v_exp.required_tier = 'pro' AND v_user_tier IN ('pro', 'annual') THEN
    v_has_access := true;
  ELSIF v_exp.required_tier = 'annual' AND v_user_tier = 'annual' THEN
    v_has_access := true;
  END IF;
  
  IF v_has_access THEN
    RETURN jsonb_build_object('access', true, 'user_tier', v_user_tier);
  ELSE
    RETURN jsonb_build_object('access', false, 'reason', 'Higher tier required', 'user_tier', v_user_tier, 'required_tier', v_exp.required_tier);
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get experience with all data
CREATE OR REPLACE FUNCTION get_immersive_experience(
  p_experience_id UUID,
  p_user_id UUID DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_exp JSONB;
  v_scenes JSONB;
  v_hotspots JSONB;
  v_quizzes JSONB;
  v_progress JSONB;
BEGIN
  -- Get experience
  SELECT to_jsonb(e.*) INTO v_exp
  FROM immersive_experiences e
  WHERE e.id = p_experience_id;
  
  IF v_exp IS NULL THEN
    RETURN NULL;
  END IF;
  
  -- Get scenes with hotspots
  SELECT jsonb_agg(
    jsonb_build_object(
      'scene', to_jsonb(s.*),
      'hotspots', (
        SELECT COALESCE(jsonb_agg(to_jsonb(h.*)), '[]'::jsonb)
        FROM immersive_hotspots h WHERE h.scene_id = s.id
      ),
      'audio_sources', (
        SELECT COALESCE(jsonb_agg(to_jsonb(a.*)), '[]'::jsonb)
        FROM spatial_audio_sources a WHERE a.scene_id = s.id
      )
    ) ORDER BY s.scene_order
  ) INTO v_scenes
  FROM immersive_scenes s WHERE s.experience_id = p_experience_id;
  
  -- Get quizzes
  SELECT COALESCE(jsonb_agg(to_jsonb(q.*)), '[]'::jsonb) INTO v_quizzes
  FROM immersive_quizzes q WHERE q.experience_id = p_experience_id;
  
  -- Get user progress if logged in
  IF p_user_id IS NOT NULL THEN
    SELECT to_jsonb(up.*) INTO v_progress
    FROM immersive_user_progress up
    WHERE up.user_id = p_user_id AND up.experience_id = p_experience_id;
  END IF;
  
  RETURN jsonb_build_object(
    'experience', v_exp,
    'scenes', COALESCE(v_scenes, '[]'::jsonb),
    'quizzes', v_quizzes,
    'user_progress', v_progress
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Save user progress
CREATE OR REPLACE FUNCTION save_immersive_progress(
  p_user_id UUID,
  p_experience_id UUID,
  p_scene_id UUID,
  p_watch_seconds INTEGER,
  p_hotspots_clicked UUID[] DEFAULT NULL,
  p_device TEXT DEFAULT NULL,
  p_vr_headset TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_progress RECORD;
BEGIN
  INSERT INTO immersive_user_progress (
    user_id, experience_id, current_scene_id,
    watch_progress_seconds, total_watch_time_seconds,
    hotspots_clicked, last_device, vr_headset_used
  ) VALUES (
    p_user_id, p_experience_id, p_scene_id,
    p_watch_seconds, p_watch_seconds,
    COALESCE(p_hotspots_clicked, '{}'),
    p_device, p_vr_headset
  )
  ON CONFLICT (user_id, experience_id) DO UPDATE SET
    current_scene_id = p_scene_id,
    watch_progress_seconds = p_watch_seconds,
    total_watch_time_seconds = immersive_user_progress.total_watch_time_seconds + 
      (p_watch_seconds - immersive_user_progress.watch_progress_seconds),
    hotspots_clicked = CASE 
      WHEN p_hotspots_clicked IS NOT NULL 
      THEN array_cat(immersive_user_progress.hotspots_clicked, p_hotspots_clicked)
      ELSE immersive_user_progress.hotspots_clicked
    END,
    last_device = COALESCE(p_device, immersive_user_progress.last_device),
    vr_headset_used = COALESCE(p_vr_headset, immersive_user_progress.vr_headset_used),
    last_watched_at = now()
  RETURNING * INTO v_progress;
  
  -- Check if completed
  DECLARE
    v_total_duration INTEGER;
  BEGIN
    SELECT SUM(duration_seconds) INTO v_total_duration
    FROM immersive_scenes WHERE experience_id = p_experience_id;
    
    IF v_progress.watch_progress_seconds >= v_total_duration * 0.9 THEN
      UPDATE immersive_user_progress 
      SET completed_at = now()
      WHERE id = v_progress.id AND completed_at IS NULL;
    END IF;
  END;
  
  RETURN to_jsonb(v_progress);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Answer quiz
CREATE OR REPLACE FUNCTION answer_immersive_quiz(
  p_user_id UUID,
  p_quiz_id UUID,
  p_answer INTEGER,
  p_answer_text TEXT DEFAULT NULL,
  p_time_taken INTEGER DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_quiz RECORD;
  v_is_correct BOOLEAN;
  v_points INTEGER := 0;
BEGIN
  -- Get quiz
  SELECT * INTO v_quiz FROM immersive_quizzes WHERE id = p_quiz_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Quiz not found');
  END IF;
  
  -- Check answer
  IF v_quiz.question_type = 'short_answer' THEN
    v_is_correct := LOWER(TRIM(p_answer_text)) = LOWER(TRIM(v_quiz.correct_text));
  ELSE
    v_is_correct := p_answer = v_quiz.correct_answer;
  END IF;
  
  IF v_is_correct THEN
    v_points := v_quiz.points;
  END IF;
  
  -- Save response
  INSERT INTO immersive_quiz_responses (
    user_id, quiz_id, experience_id,
    user_answer, user_answer_text,
    is_correct, time_taken_seconds, points_earned
  ) VALUES (
    p_user_id, p_quiz_id, v_quiz.experience_id,
    p_answer, p_answer_text,
    v_is_correct, p_time_taken, v_points
  )
  ON CONFLICT (user_id, quiz_id) DO UPDATE SET
    user_answer = p_answer,
    user_answer_text = p_answer_text,
    is_correct = v_is_correct,
    time_taken_seconds = p_time_taken,
    points_earned = v_points,
    answered_at = now();
  
  -- Update progress
  UPDATE immersive_user_progress SET
    quizzes_attempted = quizzes_attempted + 1,
    quizzes_correct = quizzes_correct + (CASE WHEN v_is_correct THEN 1 ELSE 0 END),
    total_quiz_points = total_quiz_points + v_points
  WHERE user_id = p_user_id AND experience_id = v_quiz.experience_id;
  
  RETURN jsonb_build_object(
    'success', true,
    'is_correct', v_is_correct,
    'points_earned', v_points,
    'correct_answer', v_quiz.correct_answer,
    'explanation', v_quiz.explanation
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get discovery feed
CREATE OR REPLACE FUNCTION get_immersive_discovery(
  p_user_id UUID DEFAULT NULL,
  p_subject TEXT DEFAULT NULL,
  p_limit INTEGER DEFAULT 20
) RETURNS JSONB AS $$
DECLARE
  v_featured JSONB;
  v_by_subject JSONB;
  v_continue_watching JSONB;
  v_collections JSONB;
BEGIN
  -- Featured experiences
  SELECT COALESCE(jsonb_agg(to_jsonb(e.*) ORDER BY e.view_count DESC), '[]'::jsonb)
  INTO v_featured
  FROM immersive_experiences e
  WHERE e.status = 'published'
  AND (p_subject IS NULL OR e.subject = p_subject)
  LIMIT 5;
  
  -- By subject
  SELECT jsonb_object_agg(
    subject,
    (SELECT jsonb_agg(to_jsonb(e2.*) ORDER BY e2.created_at DESC)
     FROM immersive_experiences e2 
     WHERE e2.subject = e.subject AND e2.status = 'published'
     LIMIT 10)
  ) INTO v_by_subject
  FROM (SELECT DISTINCT subject FROM immersive_experiences WHERE status = 'published') e;
  
  -- Continue watching (for logged in users)
  IF p_user_id IS NOT NULL THEN
    SELECT COALESCE(jsonb_agg(jsonb_build_object(
      'experience', to_jsonb(e.*),
      'progress', to_jsonb(up.*)
    )), '[]'::jsonb) INTO v_continue_watching
    FROM immersive_user_progress up
    JOIN immersive_experiences e ON e.id = up.experience_id
    WHERE up.user_id = p_user_id
    AND up.completed_at IS NULL
    ORDER BY up.last_watched_at DESC
    LIMIT 5;
  END IF;
  
  -- Collections
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'collection', to_jsonb(c.*),
    'items', (
      SELECT jsonb_agg(to_jsonb(e.*) ORDER BY ci.item_order)
      FROM immersive_collection_items ci
      JOIN immersive_experiences e ON e.id = ci.experience_id
      WHERE ci.collection_id = c.id
    )
  )), '[]'::jsonb) INTO v_collections
  FROM immersive_collections c
  WHERE c.is_featured = true
  LIMIT 5;
  
  RETURN jsonb_build_object(
    'featured', v_featured,
    'by_subject', COALESCE(v_by_subject, '{}'::jsonb),
    'continue_watching', COALESCE(v_continue_watching, '[]'::jsonb),
    'collections', v_collections
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Increment view count
CREATE OR REPLACE FUNCTION increment_experience_view(p_experience_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE immersive_experiences 
  SET view_count = view_count + 1
  WHERE id = p_experience_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Rate experience
CREATE OR REPLACE FUNCTION rate_immersive_experience(
  p_user_id UUID,
  p_experience_id UUID,
  p_rating INTEGER
) RETURNS JSONB AS $$
BEGIN
  -- Validate rating
  IF p_rating < 1 OR p_rating > 5 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Rating must be 1-5');
  END IF;
  
  -- Update user progress with rating
  UPDATE immersive_user_progress
  SET user_rating = p_rating
  WHERE user_id = p_user_id AND experience_id = p_experience_id;
  
  -- Update average rating on experience
  UPDATE immersive_experiences SET avg_rating = (
    SELECT AVG(user_rating)::DECIMAL(3,2)
    FROM immersive_user_progress
    WHERE experience_id = p_experience_id AND user_rating IS NOT NULL
  ) WHERE id = p_experience_id;
  
  RETURN jsonb_build_object('success', true, 'rating', p_rating);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- ROW LEVEL SECURITY
-- =====================================================
ALTER TABLE immersive_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE immersive_experiences ENABLE ROW LEVEL SECURITY;
ALTER TABLE immersive_scenes ENABLE ROW LEVEL SECURITY;
ALTER TABLE immersive_hotspots ENABLE ROW LEVEL SECURITY;
ALTER TABLE immersive_quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE immersive_user_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE immersive_quiz_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE immersive_collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE immersive_collection_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE vr_device_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE spatial_audio_sources ENABLE ROW LEVEL SECURITY;

-- Public read for published content
CREATE POLICY "Public can view categories" ON immersive_categories FOR SELECT USING (is_active = true);
CREATE POLICY "Public can view published experiences" ON immersive_experiences FOR SELECT USING (status = 'published');
CREATE POLICY "Public can view scenes" ON immersive_scenes FOR SELECT USING (
  EXISTS (SELECT 1 FROM immersive_experiences e WHERE e.id = experience_id AND e.status = 'published')
);
CREATE POLICY "Public can view hotspots" ON immersive_hotspots FOR SELECT USING (
  EXISTS (SELECT 1 FROM immersive_scenes s JOIN immersive_experiences e ON e.id = s.experience_id 
          WHERE s.id = scene_id AND e.status = 'published')
);
CREATE POLICY "Public can view quizzes" ON immersive_quizzes FOR SELECT USING (
  EXISTS (SELECT 1 FROM immersive_experiences e WHERE e.id = experience_id AND e.status = 'published')
);
CREATE POLICY "Public can view collections" ON immersive_collections FOR SELECT TO authenticated USING (true);
CREATE POLICY "Public can view collection items" ON immersive_collection_items FOR SELECT TO authenticated USING (true);
CREATE POLICY "Public can view VR profiles" ON vr_device_profiles FOR SELECT USING (true);
CREATE POLICY "Public can view audio sources" ON spatial_audio_sources FOR SELECT USING (true);

-- User progress is private
CREATE POLICY "Users can manage own progress" ON immersive_user_progress 
  FOR ALL TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own quiz responses" ON immersive_quiz_responses 
  FOR ALL TO authenticated USING (auth.uid() = user_id);

-- =====================================================
-- INDEXES
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_experiences_subject ON immersive_experiences(subject);
CREATE INDEX IF NOT EXISTS idx_experiences_status ON immersive_experiences(status);
CREATE INDEX IF NOT EXISTS idx_experiences_premium ON immersive_experiences(is_premium, required_tier);
CREATE INDEX IF NOT EXISTS idx_scenes_experience ON immersive_scenes(experience_id, scene_order);
CREATE INDEX IF NOT EXISTS idx_hotspots_scene ON immersive_hotspots(scene_id);
CREATE INDEX IF NOT EXISTS idx_quizzes_experience ON immersive_quizzes(experience_id);
CREATE INDEX IF NOT EXISTS idx_progress_user ON immersive_user_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_progress_experience ON immersive_user_progress(experience_id);
CREATE INDEX IF NOT EXISTS idx_quiz_responses_user ON immersive_quiz_responses(user_id);

-- =====================================================
-- TRIGGERS
-- =====================================================
CREATE OR REPLACE FUNCTION update_experience_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_experience_timestamp ON immersive_experiences;
CREATE TRIGGER trigger_update_experience_timestamp
  BEFORE UPDATE ON immersive_experiences
  FOR EACH ROW EXECUTE FUNCTION update_experience_timestamp();

-- =====================================================
-- COMMENTS
-- =====================================================
COMMENT ON TABLE immersive_experiences IS 'Story 15.1: 360° immersive VR/mobile experiences for UPSC learning';
COMMENT ON TABLE immersive_scenes IS 'Individual scenes within an immersive experience with navigation';
COMMENT ON TABLE immersive_hotspots IS 'Interactive clickable hotspots in 360° scenes (AC 3)';
COMMENT ON TABLE immersive_quizzes IS 'Embedded quizzes during/after experiences (AC 4)';
COMMENT ON TABLE spatial_audio_sources IS 'Spatial audio sources for immersive audio (AC 6)';
COMMENT ON TABLE vr_device_profiles IS 'VR headset compatibility profiles (AC 2)';

