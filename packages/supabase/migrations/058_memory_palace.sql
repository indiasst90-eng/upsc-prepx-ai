-- Migration 058: Memory Palace System
-- Story 11.2: Memory Palace - Facts to Animated Rooms
-- 
-- Implements:
-- AC 1: Input list of facts
-- AC 2: Palace themes (library, museum, courtroom, classroom)
-- AC 3: Mapping algorithm (5-10 rooms/stations)
-- AC 4: Visual elements per fact
-- AC 5-6: Animation flow and scene types
-- AC 7: Duration tracking
-- AC 8: Spaced repetition reviews
-- AC 9: User customization
-- AC 10: Export/download

-- =================================================================
-- MEMORY PALACES TABLE (AC 1, 2, 7)
-- =================================================================
CREATE TABLE IF NOT EXISTS memory_palaces (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID  NOT NULL,
  
  -- Basic info
  title TEXT NOT NULL,
  description TEXT,
  topic TEXT,
  subject TEXT,
  
  -- AC 2: Palace theme
  palace_theme TEXT NOT NULL DEFAULT 'library' CHECK (palace_theme IN (
    'library', 'museum', 'courtroom', 'classroom',
    'temple', 'garden', 'castle', 'market', 'custom'
  )),
  custom_theme_config JSONB,
  
  -- AC 1: Input facts
  input_facts TEXT[] NOT NULL DEFAULT '{}',
  facts_count INTEGER GENERATED ALWAYS AS (array_length(input_facts, 1)) STORED,
  
  -- AC 3: Rooms/stations count
  room_count INTEGER DEFAULT 0,
  
  -- AC 7: Duration (60-90s per 10 facts)
  estimated_duration_seconds INTEGER DEFAULT 0,
  actual_duration_seconds INTEGER,
  
  -- Animation status
  animation_status TEXT DEFAULT 'pending' CHECK (animation_status IN (
    'pending', 'generating', 'rendering', 'completed', 'failed'
  )),
  video_url TEXT,
  thumbnail_url TEXT,
  
  -- AC 10: Export
  export_status TEXT DEFAULT 'not_exported' CHECK (export_status IN (
    'not_exported', 'exporting', 'exported', 'failed'
  )),
  export_url TEXT,
  export_expires_at TIMESTAMPTZ,
  
  -- AC 8: Spaced repetition
  review_count INTEGER DEFAULT 0,
  last_reviewed_at TIMESTAMPTZ,
  next_review_at TIMESTAMPTZ,
  mastery_level INTEGER DEFAULT 0 CHECK (mastery_level BETWEEN 0 AND 5),
  
  -- User engagement
  view_count INTEGER DEFAULT 0,
  is_favorite BOOLEAN DEFAULT false,
  is_public BOOLEAN DEFAULT false,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =================================================================
-- PALACE STATIONS TABLE (AC 3, 4, 5, 6, 9)
-- =================================================================
CREATE TABLE IF NOT EXISTS palace_stations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  palace_id UUID REFERENCES memory_palaces(id) ON DELETE CASCADE NOT NULL,
  
  -- AC 3: Station/room info
  station_number INTEGER NOT NULL,
  room_name TEXT NOT NULL,
  room_description TEXT,
  
  -- AC 1, 4: Fact and visual
  fact_text TEXT NOT NULL,
  fact_keywords TEXT[],
  
  -- AC 4: Visual representation
  visual_type TEXT DEFAULT 'object' CHECK (visual_type IN (
    'object', 'character', 'symbol', 'scene', 'action', 'custom'
  )),
  visual_description TEXT,
  visual_config JSONB,
  
  -- AC 6: Scene timing
  entrance_duration_seconds REAL DEFAULT 2.0,
  station_duration_seconds REAL DEFAULT 12.5,
  transition_duration_seconds REAL DEFAULT 2.0,
  
  -- AC 9: Customization
  position_x REAL DEFAULT 0,
  position_y REAL DEFAULT 0,
  position_z REAL DEFAULT 0,
  custom_settings JSONB,
  
  -- Manim scene config
  manim_scene_config JSONB,
  
  -- Station order
  sort_order INTEGER NOT NULL DEFAULT 0,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(palace_id, station_number)
);

-- =================================================================
-- PALACE REVIEWS TABLE (AC 8)
-- =================================================================
CREATE TABLE IF NOT EXISTS palace_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  palace_id UUID REFERENCES memory_palaces(id) ON DELETE CASCADE NOT NULL,
  user_id UUID  NOT NULL,
  
  -- Review info
  review_number INTEGER NOT NULL,
  scheduled_at TIMESTAMPTZ NOT NULL,
  completed_at TIMESTAMPTZ,
  
  -- Review outcome
  recall_score INTEGER CHECK (recall_score BETWEEN 0 AND 5),
  stations_recalled INTEGER DEFAULT 0,
  total_stations INTEGER DEFAULT 0,
  time_spent_seconds INTEGER DEFAULT 0,
  
  -- Spaced repetition intervals (AC 8: 1, 3, 7, 14 days)
  interval_days INTEGER NOT NULL,
  
  -- Status
  status TEXT DEFAULT 'scheduled' CHECK (status IN (
    'scheduled', 'in_progress', 'completed', 'skipped'
  )),
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =================================================================
-- PALACE TEMPLATES TABLE (AC 2)
-- =================================================================
CREATE TABLE IF NOT EXISTS palace_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Template info
  theme_name TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL,
  description TEXT,
  
  -- Visual config
  room_styles JSONB NOT NULL DEFAULT '[]'::jsonb,
  object_library JSONB NOT NULL DEFAULT '[]'::jsonb,
  color_palette JSONB,
  ambient_audio TEXT,
  
  -- Manim config
  manim_base_config JSONB,
  
  -- Template image
  preview_image_url TEXT,
  
  -- Availability
  is_active BOOLEAN DEFAULT true,
  is_premium BOOLEAN DEFAULT false,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =================================================================
-- INDEXES
-- =================================================================
CREATE INDEX IF NOT EXISTS idx_palaces_user ON memory_palaces(user_id);
CREATE INDEX IF NOT EXISTS idx_palaces_theme ON memory_palaces(palace_theme);
CREATE INDEX IF NOT EXISTS idx_palaces_status ON memory_palaces(animation_status);
CREATE INDEX IF NOT EXISTS idx_palaces_next_review ON memory_palaces(next_review_at) 
  WHERE next_review_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_palaces_public ON memory_palaces(is_public) WHERE is_public = true;

CREATE INDEX IF NOT EXISTS idx_stations_palace ON palace_stations(palace_id);
CREATE INDEX IF NOT EXISTS idx_stations_order ON palace_stations(palace_id, sort_order);

CREATE INDEX IF NOT EXISTS idx_reviews_palace ON palace_reviews(palace_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user ON palace_reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_scheduled ON palace_reviews(scheduled_at) 
  WHERE status = 'scheduled';

-- =================================================================
-- FUNCTIONS
-- =================================================================

-- AC 1, 3: Create palace with facts
CREATE OR REPLACE FUNCTION create_memory_palace(
  p_user_id UUID,
  p_title TEXT,
  p_facts TEXT[],
  p_theme TEXT DEFAULT 'library',
  p_topic TEXT DEFAULT NULL,
  p_subject TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
  v_palace_id UUID;
  v_fact TEXT;
  v_station_num INTEGER := 1;
  v_room_count INTEGER;
BEGIN
  -- Calculate room count (AC 3: 5-10 rooms)
  v_room_count := LEAST(10, GREATEST(5, array_length(p_facts, 1)));
  
  -- Create palace
  INSERT INTO memory_palaces (
    user_id, title, input_facts, palace_theme, topic, subject, room_count,
    estimated_duration_seconds
  ) VALUES (
    p_user_id, p_title, p_facts, p_theme, p_topic, p_subject, v_room_count,
    -- AC 7: 60-90s per 10 facts (using 75s average)
    (array_length(p_facts, 1) * 7.5)::INTEGER
  ) RETURNING id INTO v_palace_id;
  
  -- Create stations for each fact
  FOREACH v_fact IN ARRAY p_facts LOOP
    INSERT INTO palace_stations (
      palace_id, station_number, room_name, fact_text, sort_order
    ) VALUES (
      v_palace_id, v_station_num,
      'Room ' || v_station_num,
      v_fact,
      v_station_num
    );
    v_station_num := v_station_num + 1;
  END LOOP;
  
  -- Schedule first review (AC 8: 1 day)
  INSERT INTO palace_reviews (
    palace_id, user_id, review_number, scheduled_at, interval_days, total_stations
  ) VALUES (
    v_palace_id, p_user_id, 1, NOW() + INTERVAL '1 day', 1, array_length(p_facts, 1)
  );
  
  -- Update next review
  UPDATE memory_palaces 
  SET next_review_at = NOW() + INTERVAL '1 day'
  WHERE id = v_palace_id;
  
  RETURN v_palace_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- AC 4: Update station visual
CREATE OR REPLACE FUNCTION update_station_visual(
  p_station_id UUID,
  p_visual_type TEXT,
  p_visual_description TEXT,
  p_visual_config JSONB DEFAULT NULL
) RETURNS BOOLEAN AS $$
BEGIN
  UPDATE palace_stations SET
    visual_type = p_visual_type,
    visual_description = p_visual_description,
    visual_config = COALESCE(p_visual_config, visual_config),
    updated_at = NOW()
  WHERE id = p_station_id;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- AC 9: Rearrange stations
CREATE OR REPLACE FUNCTION rearrange_palace_stations(
  p_palace_id UUID,
  p_station_order UUID[]
) RETURNS BOOLEAN AS $$
DECLARE
  v_station_id UUID;
  v_order INTEGER := 1;
BEGIN
  FOREACH v_station_id IN ARRAY p_station_order LOOP
    UPDATE palace_stations SET
      sort_order = v_order,
      station_number = v_order,
      room_name = 'Room ' || v_order,
      updated_at = NOW()
    WHERE id = v_station_id AND palace_id = p_palace_id;
    v_order := v_order + 1;
  END LOOP;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- AC 8: Complete review and schedule next
CREATE OR REPLACE FUNCTION complete_palace_review(
  p_review_id UUID,
  p_recall_score INTEGER,
  p_stations_recalled INTEGER,
  p_time_spent INTEGER
) RETURNS JSONB AS $$
DECLARE
  v_palace_id UUID;
  v_user_id UUID;
  v_review_num INTEGER;
  v_next_interval INTEGER;
  v_next_review_date TIMESTAMPTZ;
BEGIN
  -- Get review info
  SELECT palace_id, user_id, review_number INTO v_palace_id, v_user_id, v_review_num
  FROM palace_reviews WHERE id = p_review_id;
  
  -- Update review
  UPDATE palace_reviews SET
    completed_at = NOW(),
    recall_score = p_recall_score,
    stations_recalled = p_stations_recalled,
    time_spent_seconds = p_time_spent,
    status = 'completed'
  WHERE id = p_review_id;
  
  -- Calculate next interval based on review number (AC 8: 1, 3, 7, 14 days)
  v_next_interval := CASE v_review_num
    WHEN 1 THEN 3
    WHEN 2 THEN 7
    WHEN 3 THEN 14
    ELSE 30  -- After 4 reviews, monthly
  END;
  
  -- Adjust based on recall score
  IF p_recall_score < 3 THEN
    v_next_interval := GREATEST(1, v_next_interval / 2);
  END IF;
  
  v_next_review_date := NOW() + (v_next_interval || ' days')::INTERVAL;
  
  -- Schedule next review
  INSERT INTO palace_reviews (
    palace_id, user_id, review_number, scheduled_at, interval_days,
    total_stations
  ) VALUES (
    v_palace_id, v_user_id, v_review_num + 1, v_next_review_date, v_next_interval,
    p_stations_recalled
  );
  
  -- Update palace
  UPDATE memory_palaces SET
    review_count = review_count + 1,
    last_reviewed_at = NOW(),
    next_review_at = v_next_review_date,
    mastery_level = LEAST(5, GREATEST(0, (p_recall_score - 2) + mastery_level)),
    updated_at = NOW()
  WHERE id = v_palace_id;
  
  RETURN jsonb_build_object(
    'success', true,
    'next_review_at', v_next_review_date,
    'interval_days', v_next_interval
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get palace with stations
CREATE OR REPLACE FUNCTION get_palace_with_stations(
  p_palace_id UUID
) RETURNS JSONB AS $$
DECLARE
  v_palace RECORD;
  v_stations JSONB;
BEGIN
  SELECT * INTO v_palace FROM memory_palaces WHERE id = p_palace_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Palace not found');
  END IF;
  
  SELECT jsonb_agg(s ORDER BY s.sort_order) INTO v_stations
  FROM palace_stations s WHERE s.palace_id = p_palace_id;
  
  RETURN jsonb_build_object(
    'palace', row_to_json(v_palace),
    'stations', COALESCE(v_stations, '[]'::jsonb)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get user's palaces
CREATE OR REPLACE FUNCTION get_user_palaces(
  p_user_id UUID,
  p_theme TEXT DEFAULT NULL,
  p_limit INTEGER DEFAULT 20,
  p_offset INTEGER DEFAULT 0
) RETURNS JSONB AS $$
DECLARE
  v_palaces JSONB;
  v_total INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_total
  FROM memory_palaces
  WHERE user_id = p_user_id
    AND (p_theme IS NULL OR palace_theme = p_theme);
  
  SELECT jsonb_agg(p ORDER BY p.created_at DESC) INTO v_palaces
  FROM (
    SELECT id, title, palace_theme, facts_count, room_count,
           animation_status, video_url, thumbnail_url,
           mastery_level, next_review_at, is_favorite, created_at
    FROM memory_palaces
    WHERE user_id = p_user_id
      AND (p_theme IS NULL OR palace_theme = p_theme)
    ORDER BY created_at DESC
    LIMIT p_limit OFFSET p_offset
  ) p;
  
  RETURN jsonb_build_object(
    'palaces', COALESCE(v_palaces, '[]'::jsonb),
    'total', v_total
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get due reviews
CREATE OR REPLACE FUNCTION get_due_palace_reviews(
  p_user_id UUID
) RETURNS JSONB AS $$
BEGIN
  RETURN (
    SELECT jsonb_agg(r ORDER BY r.scheduled_at)
    FROM (
      SELECT pr.*, mp.title, mp.palace_theme, mp.facts_count
      FROM palace_reviews pr
      JOIN memory_palaces mp ON mp.id = pr.palace_id
      WHERE pr.user_id = p_user_id
        AND pr.status = 'scheduled'
        AND pr.scheduled_at <= NOW()
      ORDER BY pr.scheduled_at
      LIMIT 10
    ) r
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update animation status
CREATE OR REPLACE FUNCTION update_palace_animation(
  p_palace_id UUID,
  p_status TEXT,
  p_video_url TEXT DEFAULT NULL,
  p_thumbnail_url TEXT DEFAULT NULL,
  p_duration INTEGER DEFAULT NULL
) RETURNS BOOLEAN AS $$
BEGIN
  UPDATE memory_palaces SET
    animation_status = p_status,
    video_url = COALESCE(p_video_url, video_url),
    thumbnail_url = COALESCE(p_thumbnail_url, thumbnail_url),
    actual_duration_seconds = COALESCE(p_duration, actual_duration_seconds),
    updated_at = NOW()
  WHERE id = p_palace_id;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- AC 10: Request export
CREATE OR REPLACE FUNCTION request_palace_export(
  p_palace_id UUID
) RETURNS BOOLEAN AS $$
BEGIN
  UPDATE memory_palaces SET
    export_status = 'exporting',
    updated_at = NOW()
  WHERE id = p_palace_id;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =================================================================
-- INSERT DEFAULT TEMPLATES (AC 2)
-- =================================================================
INSERT INTO palace_templates (theme_name, display_name, description, room_styles, is_premium) VALUES
('library', 'Grand Library', 'A majestic library with towering bookshelves', 
 '[{"name": "Reading Room", "style": "classical"}, {"name": "Archive Section", "style": "dim"}, {"name": "Study Alcove", "style": "cozy"}]'::jsonb, false),
('museum', 'History Museum', 'A museum with exhibits in grand halls',
 '[{"name": "Ancient Hall", "style": "marble"}, {"name": "Gallery Wing", "style": "modern"}, {"name": "Artifact Room", "style": "spotlight"}]'::jsonb, false),
('courtroom', 'Supreme Court', 'A formal courtroom with wooden furnishings',
 '[{"name": "Hearing Chamber", "style": "formal"}, {"name": "Judge Bench", "style": "elevated"}, {"name": "Records Room", "style": "archive"}]'::jsonb, false),
('classroom', 'University Hall', 'A grand academic lecture hall',
 '[{"name": "Lecture Theater", "style": "tiered"}, {"name": "Seminar Room", "style": "intimate"}, {"name": "Lab", "style": "bright"}]'::jsonb, false),
('temple', 'Ancient Temple', 'A serene temple with sacred spaces',
 '[{"name": "Sanctum", "style": "sacred"}, {"name": "Meditation Hall", "style": "peaceful"}, {"name": "Prayer Room", "style": "candle-lit"}]'::jsonb, true),
('garden', 'Botanical Garden', 'A beautiful garden with pathways',
 '[{"name": "Rose Garden", "style": "colorful"}, {"name": "Zen Area", "style": "minimal"}, {"name": "Greenhouse", "style": "tropical"}]'::jsonb, true),
('castle', 'Medieval Castle', 'A grand castle with towers and halls',
 '[{"name": "Throne Room", "style": "royal"}, {"name": "Tower", "style": "stone"}, {"name": "Great Hall", "style": "banquet"}]'::jsonb, true),
('market', 'Ancient Bazaar', 'A bustling marketplace with colorful stalls',
 '[{"name": "Spice Lane", "style": "aromatic"}, {"name": "Silk Row", "style": "luxurious"}, {"name": "Food Court", "style": "vibrant"}]'::jsonb, true)
ON CONFLICT (theme_name) DO NOTHING;

-- =================================================================
-- ROW LEVEL SECURITY
-- =================================================================
ALTER TABLE memory_palaces ENABLE ROW LEVEL SECURITY;
ALTER TABLE palace_stations ENABLE ROW LEVEL SECURITY;
ALTER TABLE palace_reviews ENABLE ROW LEVEL SECURITY;

-- Palaces policies
CREATE POLICY "Users can view own palaces" ON memory_palaces
  FOR SELECT USING (auth.uid() = user_id OR is_public = true);

CREATE POLICY "Users can create own palaces" ON memory_palaces
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own palaces" ON memory_palaces
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own palaces" ON memory_palaces
  FOR DELETE USING (auth.uid() = user_id);

-- Stations policies
CREATE POLICY "Users can view stations of accessible palaces" ON palace_stations
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM memory_palaces WHERE id = palace_id 
            AND (user_id = auth.uid() OR is_public = true))
  );

CREATE POLICY "Users can manage own palace stations" ON palace_stations
  FOR ALL USING (
    EXISTS (SELECT 1 FROM memory_palaces WHERE id = palace_id AND user_id = auth.uid())
  );

-- Reviews policies
CREATE POLICY "Users can view own reviews" ON palace_reviews
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own reviews" ON palace_reviews
  FOR ALL USING (auth.uid() = user_id);

-- Templates are public read
ALTER TABLE palace_templates ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view active templates" ON palace_templates
  FOR SELECT USING (is_active = true);

