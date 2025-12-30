-- Migration 059: Interactive Map Atlas System
-- Story 11.3: Interactive Map Atlas - 3D Geography Visualization
-- 
-- Implements:
-- AC 1: Map types (World, India, States, Districts)
-- AC 2: Data layers (political, physical, rivers, mountains, climate)
-- AC 3: 3D rendering support
-- AC 4: Time slider historical data
-- AC 5: Interactive elements (regions, paths, zones)
-- AC 6: Video tour generation
-- AC 7: Export functionality
-- AC 8: Embedded quizzes
-- AC 9: Offline maps caching
-- AC 10: Performance tracking

-- =================================================================
-- MAP REGIONS TABLE (AC 1, 2)
-- =================================================================
CREATE TABLE IF NOT EXISTS map_regions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- AC 1: Map types
  map_type TEXT NOT NULL CHECK (map_type IN ('world', 'india', 'state', 'district')),
  region_code TEXT NOT NULL,
  region_name TEXT NOT NULL,
  parent_region_id UUID REFERENCES map_regions(id),
  
  -- Geographic data
  centroid_lat DECIMAL(10, 6),
  centroid_lng DECIMAL(10, 6),
  bounds_north DECIMAL(10, 6),
  bounds_south DECIMAL(10, 6),
  bounds_east DECIMAL(10, 6),
  bounds_west DECIMAL(10, 6),
  area_sq_km DECIMAL(12, 2),
  
  -- GeoJSON data (stored as JSONB for flexibility)
  geojson JSONB,
  simplified_geojson JSONB, -- For performance (AC 10)
  
  -- AC 2: Physical features
  terrain_type TEXT[],
  climate_zone TEXT,
  avg_elevation_m INTEGER,
  
  -- Metadata
  population BIGINT,
  capital TEXT,
  official_language TEXT[],
  facts JSONB DEFAULT '[]'::jsonb,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(map_type, region_code)
);

-- =================================================================
-- MAP LAYERS TABLE (AC 2)
-- =================================================================
CREATE TABLE IF NOT EXISTS map_layers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Layer info
  layer_type TEXT NOT NULL CHECK (layer_type IN (
    'political', 'physical', 'rivers', 'mountains', 'climate',
    'districts', 'roads', 'railways', 'airports', 'ports',
    'agro_climatic', 'soil_types', 'minerals', 'industries'
  )),
  layer_name TEXT NOT NULL,
  description TEXT,
  
  -- Geographic data
  geojson JSONB NOT NULL,
  simplified_geojson JSONB, -- AC 10: Performance
  
  -- Styling
  default_style JSONB DEFAULT '{}'::jsonb,
  
  -- Visibility
  zoom_min INTEGER DEFAULT 1,
  zoom_max INTEGER DEFAULT 20,
  is_active BOOLEAN DEFAULT true,
  is_premium BOOLEAN DEFAULT false,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =================================================================
-- HISTORICAL MAPS TABLE (AC 4)
-- =================================================================
CREATE TABLE IF NOT EXISTS historical_maps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Time period (AC 4: 1947, 1956, current)
  year INTEGER NOT NULL,
  era_name TEXT,
  description TEXT,
  
  -- Map configuration
  map_type TEXT NOT NULL DEFAULT 'india',
  region_changes JSONB DEFAULT '[]'::jsonb,
  
  -- GeoJSON for this time period
  geojson JSONB NOT NULL,
  
  -- Metadata
  key_events TEXT[],
  notes TEXT,
  source TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =================================================================
-- MAP FEATURES TABLE (AC 2, 5)
-- =================================================================
CREATE TABLE IF NOT EXISTS map_features (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Feature info
  feature_type TEXT NOT NULL CHECK (feature_type IN (
    'river', 'mountain', 'peak', 'pass', 'lake', 'dam',
    'national_park', 'wildlife_sanctuary', 'trade_route',
    'migration_path', 'cultural_site', 'historical_site'
  )),
  feature_name TEXT NOT NULL,
  description TEXT,
  
  -- Geographic data
  geojson JSONB NOT NULL, -- LineString or Point
  
  -- Metadata
  length_km DECIMAL(10, 2),
  height_m INTEGER,
  facts JSONB DEFAULT '[]'::jsonb,
  images TEXT[],
  
  -- AC 5: Interactive elements
  is_clickable BOOLEAN DEFAULT true,
  popup_content JSONB,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =================================================================
-- USER MAP SESSIONS TABLE (AC 5, 9)
-- =================================================================
CREATE TABLE IF NOT EXISTS map_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID  NOT NULL,
  
  -- Session state
  current_map_type TEXT DEFAULT 'india',
  current_region_id UUID REFERENCES map_regions(id),
  zoom_level INTEGER DEFAULT 5,
  center_lat DECIMAL(10, 6) DEFAULT 20.5937,
  center_lng DECIMAL(10, 6) DEFAULT 78.9629,
  
  -- AC 2: Active layers
  active_layers TEXT[] DEFAULT '{"political"}',
  
  -- AC 4: Time slider position
  historical_year INTEGER DEFAULT 2024,
  
  -- AC 5: User drawings
  custom_paths JSONB DEFAULT '[]'::jsonb,
  highlighted_zones JSONB DEFAULT '[]'::jsonb,
  annotations JSONB DEFAULT '[]'::jsonb,
  
  -- AC 9: Offline preferences
  offline_enabled BOOLEAN DEFAULT false,
  cached_regions TEXT[] DEFAULT '{}',
  
  -- Timestamps
  last_activity TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =================================================================
-- MAP TOURS TABLE (AC 6)
-- =================================================================
CREATE TABLE IF NOT EXISTS map_tours (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID ,
  
  -- Tour info
  title TEXT NOT NULL,
  description TEXT,
  topic TEXT,
  
  -- Tour configuration
  waypoints JSONB NOT NULL DEFAULT '[]'::jsonb,
  total_duration_seconds INTEGER DEFAULT 0,
  
  -- AC 6: Video generation
  video_status TEXT DEFAULT 'pending' CHECK (video_status IN (
    'pending', 'generating', 'completed', 'failed'
  )),
  video_url TEXT,
  thumbnail_url TEXT,
  
  -- TTS narration
  narration_text TEXT,
  narration_url TEXT,
  
  -- Sharing
  is_public BOOLEAN DEFAULT false,
  view_count INTEGER DEFAULT 0,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =================================================================
-- MAP QUIZZES TABLE (AC 8)
-- =================================================================
CREATE TABLE IF NOT EXISTS map_quizzes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Quiz info
  quiz_type TEXT NOT NULL CHECK (quiz_type IN (
    'identify_state', 'identify_district', 'identify_river',
    'identify_mountain', 'locate_capital', 'boundary_challenge',
    'climate_zone', 'historical_map'
  )),
  title TEXT NOT NULL,
  description TEXT,
  
  -- Quiz configuration
  difficulty TEXT DEFAULT 'medium' CHECK (difficulty IN ('easy', 'medium', 'hard')),
  questions JSONB NOT NULL DEFAULT '[]'::jsonb,
  time_limit_seconds INTEGER DEFAULT 300,
  
  -- Region scope
  map_type TEXT DEFAULT 'india',
  region_scope UUID REFERENCES map_regions(id),
  
  -- Stats
  attempt_count INTEGER DEFAULT 0,
  avg_score DECIMAL(5, 2),
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =================================================================
-- MAP QUIZ ATTEMPTS TABLE (AC 8)
-- =================================================================
CREATE TABLE IF NOT EXISTS map_quiz_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quiz_id UUID REFERENCES map_quizzes(id) ON DELETE CASCADE NOT NULL,
  user_id UUID  NOT NULL,
  
  -- Attempt data
  answers JSONB NOT NULL DEFAULT '[]'::jsonb,
  score INTEGER DEFAULT 0,
  max_score INTEGER DEFAULT 0,
  percentage DECIMAL(5, 2),
  time_taken_seconds INTEGER,
  
  -- Status
  completed_at TIMESTAMPTZ,
  
  -- Timestamps
  started_at TIMESTAMPTZ DEFAULT NOW()
);

-- =================================================================
-- MAP EXPORTS TABLE (AC 7)
-- =================================================================
CREATE TABLE IF NOT EXISTS map_exports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID  NOT NULL,
  
  -- Export configuration
  export_type TEXT NOT NULL CHECK (export_type IN ('image', 'video', 'pdf')),
  format TEXT NOT NULL, -- png, jpg, mp4, pdf
  
  -- Map state at export
  map_config JSONB NOT NULL,
  
  -- Export status
  status TEXT DEFAULT 'pending' CHECK (status IN (
    'pending', 'processing', 'completed', 'failed'
  )),
  file_url TEXT,
  file_size_kb INTEGER,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ
);

-- =================================================================
-- OFFLINE MAP CACHE TABLE (AC 9)
-- =================================================================
CREATE TABLE IF NOT EXISTS map_offline_cache (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID  NOT NULL,
  
  -- Cache info
  region_id UUID REFERENCES map_regions(id),
  map_type TEXT NOT NULL,
  zoom_levels INTEGER[] DEFAULT '{5, 6, 7, 8}',
  
  -- Cache data
  tile_count INTEGER DEFAULT 0,
  cache_size_mb DECIMAL(10, 2) DEFAULT 0,
  
  -- Status
  status TEXT DEFAULT 'pending' CHECK (status IN (
    'pending', 'downloading', 'completed', 'expired'
  )),
  last_synced_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =================================================================
-- INDEXES
-- =================================================================
CREATE INDEX IF NOT EXISTS idx_regions_type ON map_regions(map_type);
CREATE INDEX IF NOT EXISTS idx_regions_parent ON map_regions(parent_region_id);
CREATE INDEX IF NOT EXISTS idx_regions_code ON map_regions(region_code);

CREATE INDEX IF NOT EXISTS idx_layers_type ON map_layers(layer_type);
CREATE INDEX IF NOT EXISTS idx_layers_active ON map_layers(is_active) WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_historical_year ON historical_maps(year);
CREATE INDEX IF NOT EXISTS idx_features_type ON map_features(feature_type);

CREATE INDEX IF NOT EXISTS idx_sessions_user ON map_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_tours_user ON map_tours(user_id);
CREATE INDEX IF NOT EXISTS idx_tours_public ON map_tours(is_public) WHERE is_public = true;

CREATE INDEX IF NOT EXISTS idx_quizzes_type ON map_quizzes(quiz_type);
CREATE INDEX IF NOT EXISTS idx_quiz_attempts_user ON map_quiz_attempts(user_id);

CREATE INDEX IF NOT EXISTS idx_exports_user ON map_exports(user_id);
CREATE INDEX IF NOT EXISTS idx_offline_cache_user ON map_offline_cache(user_id);

-- =================================================================
-- FUNCTIONS
-- =================================================================

-- Get region with layers
CREATE OR REPLACE FUNCTION get_map_region(
  p_region_id UUID DEFAULT NULL,
  p_region_code TEXT DEFAULT NULL,
  p_map_type TEXT DEFAULT 'india'
) RETURNS JSONB AS $$
DECLARE
  v_region RECORD;
  v_children JSONB;
BEGIN
  -- Get region
  IF p_region_id IS NOT NULL THEN
    SELECT * INTO v_region FROM map_regions WHERE id = p_region_id;
  ELSE
    SELECT * INTO v_region FROM map_regions 
    WHERE region_code = p_region_code AND map_type = p_map_type;
  END IF;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Region not found');
  END IF;
  
  -- Get child regions
  SELECT jsonb_agg(jsonb_build_object(
    'id', r.id,
    'code', r.region_code,
    'name', r.region_name,
    'map_type', r.map_type
  )) INTO v_children
  FROM map_regions r
  WHERE r.parent_region_id = v_region.id;
  
  RETURN jsonb_build_object(
    'region', row_to_json(v_region),
    'children', COALESCE(v_children, '[]'::jsonb)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get layers for map view
CREATE OR REPLACE FUNCTION get_map_layers(
  p_layer_types TEXT[],
  p_zoom INTEGER DEFAULT 5,
  p_use_simplified BOOLEAN DEFAULT true
) RETURNS JSONB AS $$
BEGIN
  RETURN (
    SELECT jsonb_agg(jsonb_build_object(
      'id', l.id,
      'type', l.layer_type,
      'name', l.layer_name,
      'geojson', CASE WHEN p_use_simplified AND l.simplified_geojson IS NOT NULL 
                      THEN l.simplified_geojson ELSE l.geojson END,
      'style', l.default_style
    ))
    FROM map_layers l
    WHERE l.layer_type = ANY(p_layer_types)
      AND l.is_active = true
      AND l.zoom_min <= p_zoom
      AND l.zoom_max >= p_zoom
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get historical map (AC 4)
CREATE OR REPLACE FUNCTION get_historical_map(
  p_year INTEGER,
  p_map_type TEXT DEFAULT 'india'
) RETURNS JSONB AS $$
DECLARE
  v_map RECORD;
BEGIN
  SELECT * INTO v_map
  FROM historical_maps
  WHERE year = p_year AND map_type = p_map_type;
  
  IF NOT FOUND THEN
    -- Return closest available year
    SELECT * INTO v_map
    FROM historical_maps
    WHERE map_type = p_map_type
    ORDER BY ABS(year - p_year)
    LIMIT 1;
  END IF;
  
  RETURN row_to_json(v_map)::jsonb;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Save map session (AC 5)
CREATE OR REPLACE FUNCTION save_map_session(
  p_user_id UUID,
  p_session_data JSONB
) RETURNS UUID AS $$
DECLARE
  v_session_id UUID;
BEGIN
  INSERT INTO map_sessions (
    user_id, current_map_type, current_region_id, zoom_level,
    center_lat, center_lng, active_layers, historical_year,
    custom_paths, highlighted_zones, annotations
  ) VALUES (
    p_user_id,
    p_session_data->>'map_type',
    (p_session_data->>'region_id')::UUID,
    (p_session_data->>'zoom')::INTEGER,
    (p_session_data->>'lat')::DECIMAL,
    (p_session_data->>'lng')::DECIMAL,
    ARRAY(SELECT jsonb_array_elements_text(p_session_data->'layers')),
    (p_session_data->>'year')::INTEGER,
    p_session_data->'paths',
    p_session_data->'zones',
    p_session_data->'annotations'
  )
  ON CONFLICT (user_id) DO UPDATE SET
    current_map_type = EXCLUDED.current_map_type,
    current_region_id = EXCLUDED.current_region_id,
    zoom_level = EXCLUDED.zoom_level,
    center_lat = EXCLUDED.center_lat,
    center_lng = EXCLUDED.center_lng,
    active_layers = EXCLUDED.active_layers,
    historical_year = EXCLUDED.historical_year,
    custom_paths = EXCLUDED.custom_paths,
    highlighted_zones = EXCLUDED.highlighted_zones,
    annotations = EXCLUDED.annotations,
    last_activity = NOW(),
    updated_at = NOW()
  RETURNING id INTO v_session_id;
  
  RETURN v_session_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create map tour (AC 6)
CREATE OR REPLACE FUNCTION create_map_tour(
  p_user_id UUID,
  p_title TEXT,
  p_waypoints JSONB,
  p_description TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
  v_tour_id UUID;
  v_duration INTEGER;
BEGIN
  -- Calculate duration (5 seconds per waypoint average)
  v_duration := jsonb_array_length(p_waypoints) * 5;
  
  INSERT INTO map_tours (
    user_id, title, description, waypoints, total_duration_seconds
  ) VALUES (
    p_user_id, p_title, p_description, p_waypoints, v_duration
  ) RETURNING id INTO v_tour_id;
  
  RETURN v_tour_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get quiz with questions (AC 8)
CREATE OR REPLACE FUNCTION get_map_quiz(
  p_quiz_id UUID
) RETURNS JSONB AS $$
DECLARE
  v_quiz RECORD;
BEGIN
  SELECT * INTO v_quiz FROM map_quizzes WHERE id = p_quiz_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Quiz not found');
  END IF;
  
  RETURN row_to_json(v_quiz)::jsonb;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Submit quiz attempt (AC 8)
CREATE OR REPLACE FUNCTION submit_quiz_attempt(
  p_quiz_id UUID,
  p_user_id UUID,
  p_answers JSONB,
  p_time_taken INTEGER
) RETURNS JSONB AS $$
DECLARE
  v_quiz RECORD;
  v_score INTEGER := 0;
  v_max_score INTEGER;
  v_percentage DECIMAL(5, 2);
  v_attempt_id UUID;
BEGIN
  -- Get quiz
  SELECT * INTO v_quiz FROM map_quizzes WHERE id = p_quiz_id;
  v_max_score := jsonb_array_length(v_quiz.questions);
  
  -- Calculate score (simplified - in production would compare answers)
  SELECT COUNT(*) INTO v_score
  FROM jsonb_array_elements(p_answers) AS a
  WHERE (a->>'is_correct')::BOOLEAN = true;
  
  v_percentage := (v_score::DECIMAL / v_max_score) * 100;
  
  -- Save attempt
  INSERT INTO map_quiz_attempts (
    quiz_id, user_id, answers, score, max_score, percentage,
    time_taken_seconds, completed_at
  ) VALUES (
    p_quiz_id, p_user_id, p_answers, v_score, v_max_score,
    v_percentage, p_time_taken, NOW()
  ) RETURNING id INTO v_attempt_id;
  
  -- Update quiz stats
  UPDATE map_quizzes SET
    attempt_count = attempt_count + 1,
    avg_score = (avg_score * attempt_count + v_percentage) / (attempt_count + 1)
  WHERE id = p_quiz_id;
  
  RETURN jsonb_build_object(
    'attempt_id', v_attempt_id,
    'score', v_score,
    'max_score', v_max_score,
    'percentage', v_percentage
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Request offline cache (AC 9)
CREATE OR REPLACE FUNCTION request_offline_cache(
  p_user_id UUID,
  p_region_id UUID,
  p_zoom_levels INTEGER[] DEFAULT '{5, 6, 7, 8}'
) RETURNS UUID AS $$
DECLARE
  v_cache_id UUID;
  v_region RECORD;
BEGIN
  SELECT * INTO v_region FROM map_regions WHERE id = p_region_id;
  
  INSERT INTO map_offline_cache (
    user_id, region_id, map_type, zoom_levels,
    expires_at
  ) VALUES (
    p_user_id, p_region_id, v_region.map_type, p_zoom_levels,
    NOW() + INTERVAL '30 days'
  ) RETURNING id INTO v_cache_id;
  
  -- Update session
  UPDATE map_sessions SET
    offline_enabled = true,
    cached_regions = array_append(cached_regions, v_region.region_code),
    updated_at = NOW()
  WHERE user_id = p_user_id;
  
  RETURN v_cache_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =================================================================
-- INSERT SAMPLE DATA
-- =================================================================

-- Insert India as base region
INSERT INTO map_regions (map_type, region_code, region_name, centroid_lat, centroid_lng, area_sq_km, population, capital)
VALUES ('india', 'IN', 'India', 20.5937, 78.9629, 3287263, 1428627663, 'New Delhi')
ON CONFLICT (map_type, region_code) DO NOTHING;

-- Insert historical map snapshots (AC 4)
INSERT INTO historical_maps (year, era_name, description, map_type, key_events, geojson) VALUES
(1947, 'Independence', 'India at independence with princely states', 'india', 
 ARRAY['Independence', 'Partition', 'Princely States Integration'],
 '{"type": "FeatureCollection", "features": []}'::jsonb),
(1956, 'States Reorganisation', 'India after States Reorganisation Act', 'india',
 ARRAY['States Reorganisation Act', 'Linguistic states formed'],
 '{"type": "FeatureCollection", "features": []}'::jsonb),
(2024, 'Current', 'Current political map of India', 'india',
 ARRAY['28 States', '8 Union Territories'],
 '{"type": "FeatureCollection", "features": []}'::jsonb)
ON CONFLICT DO NOTHING;

-- Insert sample map layers (AC 2)
INSERT INTO map_layers (layer_type, layer_name, description, geojson) VALUES
('political', 'State Boundaries', 'Political boundaries of Indian states', 
 '{"type": "FeatureCollection", "features": []}'::jsonb),
('rivers', 'Major Rivers', 'Major rivers of India', 
 '{"type": "FeatureCollection", "features": []}'::jsonb),
('mountains', 'Mountain Ranges', 'Major mountain ranges', 
 '{"type": "FeatureCollection", "features": []}'::jsonb),
('climate', 'Climate Zones', 'Climatic regions of India', 
 '{"type": "FeatureCollection", "features": []}'::jsonb)
ON CONFLICT DO NOTHING;

-- Insert sample quizzes (AC 8)
INSERT INTO map_quizzes (quiz_type, title, description, difficulty, questions) VALUES
('identify_state', 'Identify Indian States', 'Click on the correct state', 'easy',
 '[{"id": 1, "question": "Where is Maharashtra?", "answer": "MH", "options": ["MH", "KA", "TN", "GJ"]}]'::jsonb),
('identify_river', 'Major Rivers Quiz', 'Identify major rivers of India', 'medium',
 '[{"id": 1, "question": "Which river flows through Varanasi?", "answer": "Ganga", "options": ["Ganga", "Yamuna", "Godavari", "Krishna"]}]'::jsonb)
ON CONFLICT DO NOTHING;

-- =================================================================
-- ROW LEVEL SECURITY
-- =================================================================
ALTER TABLE map_regions ENABLE ROW LEVEL SECURITY;
ALTER TABLE map_layers ENABLE ROW LEVEL SECURITY;
ALTER TABLE historical_maps ENABLE ROW LEVEL SECURITY;
ALTER TABLE map_features ENABLE ROW LEVEL SECURITY;
ALTER TABLE map_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE map_tours ENABLE ROW LEVEL SECURITY;
ALTER TABLE map_quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE map_quiz_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE map_exports ENABLE ROW LEVEL SECURITY;
ALTER TABLE map_offline_cache ENABLE ROW LEVEL SECURITY;

-- Public read for map data
CREATE POLICY "Anyone can view regions" ON map_regions FOR SELECT USING (true);
CREATE POLICY "Anyone can view layers" ON map_layers FOR SELECT USING (is_active = true);
CREATE POLICY "Anyone can view historical maps" ON historical_maps FOR SELECT USING (true);
CREATE POLICY "Anyone can view features" ON map_features FOR SELECT USING (true);
CREATE POLICY "Anyone can view quizzes" ON map_quizzes FOR SELECT USING (true);

-- User-specific data
CREATE POLICY "Users can manage own sessions" ON map_sessions FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can view public and own tours" ON map_tours 
  FOR SELECT USING (is_public = true OR auth.uid() = user_id);
CREATE POLICY "Users can manage own tours" ON map_tours 
  FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own quiz attempts" ON map_quiz_attempts FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own exports" ON map_exports FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own offline cache" ON map_offline_cache FOR ALL USING (auth.uid() = user_id);

