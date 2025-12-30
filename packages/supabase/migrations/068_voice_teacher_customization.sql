-- Migration: 068_voice_teacher_customization.sql
-- Description: AI Voice Teacher - TTS Customization System
-- Story: 16.1
-- Created: 2025-12-28

-- =====================================================
-- VOICE PROVIDERS (TTS Services)
-- =====================================================
CREATE TABLE IF NOT EXISTS tts_providers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  api_endpoint TEXT,
  is_active BOOLEAN DEFAULT true,
  is_premium BOOLEAN DEFAULT false,
  features JSONB DEFAULT '{}',
  -- Features: voice_cloning, ssml, emotions, multi_language
  created_at TIMESTAMPTZ DEFAULT now()
);

-- =====================================================
-- AVAILABLE VOICES (AC 1)
-- =====================================================
CREATE TABLE IF NOT EXISTS voice_options (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID REFERENCES tts_providers(id),
  
  -- Voice identity
  voice_id TEXT NOT NULL, -- Provider's voice ID
  name TEXT NOT NULL,
  description TEXT,
  
  -- Characteristics (AC 1)
  gender TEXT NOT NULL CHECK (gender IN ('male', 'female', 'neutral')),
  accent TEXT NOT NULL DEFAULT 'indian_english' CHECK (accent IN ('indian_english', 'american', 'british', 'australian', 'neutral')),
  age_group TEXT DEFAULT 'adult' CHECK (age_group IN ('young', 'adult', 'senior')),
  
  -- Style presets (AC 3)
  style TEXT DEFAULT 'mentor' CHECK (style IN ('professor', 'mentor', 'peer', 'narrator', 'enthusiastic')),
  style_description TEXT,
  
  -- Sample audio for preview (AC 5)
  sample_audio_url TEXT,
  sample_duration_seconds INTEGER DEFAULT 10,
  
  -- Premium/Celebrity voices (AC 7)
  is_premium BOOLEAN DEFAULT false,
  is_celebrity BOOLEAN DEFAULT false,
  celebrity_name TEXT,
  required_tier TEXT DEFAULT 'free' CHECK (required_tier IN ('free', 'pro', 'annual')),
  
  -- Technical specs
  supported_languages TEXT[] DEFAULT ARRAY['en'],
  quality TEXT DEFAULT 'high' CHECK (quality IN ('standard', 'high', 'ultra')),
  
  -- Usage stats
  use_count INTEGER DEFAULT 0,
  avg_rating DECIMAL(3,2),
  
  is_active BOOLEAN DEFAULT true,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- =====================================================
-- USER VOICE PREFERENCES (AC 4)
-- =====================================================
CREATE TABLE IF NOT EXISTS user_voice_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID  UNIQUE,
  
  -- Selected voice
  selected_voice_id UUID REFERENCES voice_options(id),
  
  -- Speed control (AC 2)
  playback_speed DECIMAL(3,2) DEFAULT 1.0 CHECK (playback_speed BETWEEN 0.75 AND 1.5),
  
  -- Style override (AC 3)
  teaching_style TEXT DEFAULT 'mentor' CHECK (teaching_style IN ('professor', 'mentor', 'peer')),
  
  -- Accessibility options (AC 10)
  accessibility_settings JSONB DEFAULT '{
    "enhanced_clarity": false,
    "bass_boost": false,
    "noise_reduction": true,
    "auto_captions": true,
    "sign_language_overlay": false
  }',
  
  -- SSML preferences
  pitch_adjustment INTEGER DEFAULT 0 CHECK (pitch_adjustment BETWEEN -20 AND 20),
  emphasis_level TEXT DEFAULT 'moderate' CHECK (emphasis_level IN ('reduced', 'moderate', 'strong')),
  pause_duration TEXT DEFAULT 'normal' CHECK (pause_duration IN ('short', 'normal', 'long')),
  
  -- Application scope (AC 9)
  apply_to_videos BOOLEAN DEFAULT true,
  apply_to_assistant BOOLEAN DEFAULT true,
  apply_to_practice BOOLEAN DEFAULT true,
  apply_globally BOOLEAN DEFAULT true,
  
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- =====================================================
-- VOICE CLONING (AC 8 - Optional feature)
-- =====================================================
CREATE TABLE IF NOT EXISTS voice_clones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID ,
  
  -- Clone details
  name TEXT NOT NULL,
  description TEXT,
  
  -- Source audio
  source_audio_url TEXT NOT NULL,
  source_duration_seconds INTEGER NOT NULL CHECK (source_duration_seconds >= 60), -- Min 1 minute
  
  -- Processing status
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'ready', 'failed', 'expired')),
  processing_progress INTEGER DEFAULT 0,
  error_message TEXT,
  
  -- Provider reference
  provider_id UUID REFERENCES tts_providers(id),
  provider_voice_id TEXT, -- Generated voice ID from provider
  
  -- Sample for preview
  sample_audio_url TEXT,
  
  -- Consent and compliance
  consent_given BOOLEAN DEFAULT false,
  consent_timestamp TIMESTAMPTZ,
  
  -- Limits
  is_active BOOLEAN DEFAULT true,
  expires_at TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- =====================================================
-- STYLE PRESETS (AC 3)
-- =====================================================
CREATE TABLE IF NOT EXISTS voice_style_presets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Preset identity
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  description TEXT,
  icon TEXT,
  
  -- Style parameters
  style_type TEXT NOT NULL CHECK (style_type IN ('professor', 'mentor', 'peer')),
  
  -- SSML configuration
  ssml_config JSONB DEFAULT '{
    "rate": "medium",
    "pitch": "0%",
    "volume": "medium",
    "emphasis": "moderate"
  }',
  
  -- Prompt modifiers for AI
  prompt_prefix TEXT,
  prompt_suffix TEXT,
  tone_keywords TEXT[],
  
  -- Sample
  sample_text TEXT,
  
  is_default BOOLEAN DEFAULT false,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- =====================================================
-- TTS GENERATION LOG
-- =====================================================
CREATE TABLE IF NOT EXISTS tts_generation_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID ,
  voice_id UUID REFERENCES voice_options(id),
  clone_id UUID REFERENCES voice_clones(id),
  
  -- Request details
  text_content TEXT NOT NULL,
  text_length INTEGER NOT NULL,
  
  -- Voice settings used
  speed DECIMAL(3,2),
  style TEXT,
  pitch_adjustment INTEGER,
  
  -- Provider response
  provider_id UUID REFERENCES tts_providers(id),
  audio_url TEXT,
  duration_seconds DECIMAL(10,2),
  
  -- Status
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'generating', 'ready', 'failed')),
  error_message TEXT,
  
  -- Cost tracking
  characters_billed INTEGER,
  cost_cents INTEGER,
  
  -- Usage context
  context_type TEXT CHECK (context_type IN ('video', 'assistant', 'practice', 'preview', 'other')),
  context_id UUID,
  
  created_at TIMESTAMPTZ DEFAULT now()
);

-- =====================================================
-- SEED DATA: TTS Providers
-- =====================================================
INSERT INTO tts_providers (name, slug, is_active, is_premium, features) VALUES
('ElevenLabs', 'elevenlabs', true, true, '{"voice_cloning": true, "emotions": true, "multi_language": true}'),
('Google Cloud TTS', 'google', true, false, '{"ssml": true, "multi_language": true, "wavenet": true}'),
('Amazon Polly', 'polly', true, false, '{"ssml": true, "neural": true, "multi_language": true}'),
('Microsoft Azure', 'azure', true, false, '{"ssml": true, "neural": true, "custom_voice": true}'),
('A4F TTS', 'a4f', true, false, '{"integrated": true, "fast": true}')
ON CONFLICT (slug) DO NOTHING;

-- =====================================================
-- SEED DATA: Voice Options (AC 1)
-- =====================================================
INSERT INTO voice_options (voice_id, name, description, gender, accent, style, is_premium, required_tier, display_order) VALUES
-- Free voices
('aditya_v1', 'Aditya', 'Clear, professional Indian male voice perfect for academic content', 'male', 'indian_english', 'professor', false, 'free', 1),
('priya_v1', 'Priya', 'Warm, encouraging Indian female voice ideal for mentoring', 'female', 'indian_english', 'mentor', false, 'free', 2),
('rohan_v1', 'Rohan', 'Friendly, casual Indian male voice for peer-style learning', 'male', 'indian_english', 'peer', false, 'free', 3),
('maya_v1', 'Maya', 'Enthusiastic Indian female voice with clear pronunciation', 'female', 'indian_english', 'enthusiastic', false, 'free', 4),
-- Pro voices
('james_v1', 'James', 'American male professor voice with clear articulation', 'male', 'american', 'professor', true, 'pro', 5),
('sarah_v1', 'Sarah', 'American female mentor voice, warm and supportive', 'female', 'american', 'mentor', true, 'pro', 6),
('oliver_v1', 'Oliver', 'British male narrator voice, formal and authoritative', 'male', 'british', 'narrator', true, 'pro', 7),
('emma_v1', 'Emma', 'British female voice with crisp, clear delivery', 'female', 'british', 'professor', true, 'pro', 8),
-- Celebrity-style premium (AC 7)
('expert_historian', 'History Expert', 'Documentary-style narrator reminiscent of famous historians', 'male', 'british', 'narrator', true, 'annual', 9),
('ias_topper', 'IAS Mentor', 'Voice styled after successful UPSC toppers, motivational', 'female', 'indian_english', 'mentor', true, 'annual', 10)
ON CONFLICT DO NOTHING;

-- =====================================================
-- SEED DATA: Style Presets (AC 3)
-- =====================================================
INSERT INTO voice_style_presets (name, slug, description, style_type, icon, ssml_config, prompt_prefix, is_default, display_order) VALUES
(
  'Professor',
  'professor',
  'Formal, detailed explanations with academic precision. Perfect for complex topics.',
  'professor',
  '🎓',
  '{"rate": "slow", "pitch": "-5%", "emphasis": "strong"}',
  'Explain this in a formal, academic manner with detailed analysis:',
  false,
  1
),
(
  'Mentor',
  'mentor',
  'Warm, encouraging guidance with motivational elements. Ideal for daily learning.',
  'mentor',
  '🤝',
  '{"rate": "medium", "pitch": "0%", "emphasis": "moderate"}',
  'Explain this in a supportive, encouraging way that helps students understand:',
  true,
  2
),
(
  'Peer',
  'peer',
  'Casual, relatable explanations like a friend helping you study.',
  'peer',
  '👋',
  '{"rate": "medium-fast", "pitch": "+5%", "emphasis": "moderate"}',
  'Explain this casually and simply, like a friend would:',
  false,
  3
)
ON CONFLICT (slug) DO NOTHING;

-- =====================================================
-- FUNCTIONS
-- =====================================================

-- Get user's effective voice settings
CREATE OR REPLACE FUNCTION get_user_voice_settings(p_user_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_prefs RECORD;
  v_voice RECORD;
  v_clone RECORD;
  v_style RECORD;
BEGIN
  -- Get user preferences
  SELECT * INTO v_prefs FROM user_voice_preferences WHERE user_id = p_user_id;
  
  -- If no preferences, return defaults
  IF NOT FOUND THEN
    SELECT * INTO v_voice FROM voice_options WHERE is_active = true AND required_tier = 'free' ORDER BY display_order LIMIT 1;
    SELECT * INTO v_style FROM voice_style_presets WHERE is_default = true LIMIT 1;
    
    RETURN jsonb_build_object(
      'voice', to_jsonb(v_voice),
      'style', to_jsonb(v_style),
      'speed', 1.0,
      'accessibility', '{"enhanced_clarity": false, "noise_reduction": true}'::jsonb,
      'is_default', true
    );
  END IF;
  
  -- Get selected voice
  SELECT * INTO v_voice FROM voice_options WHERE id = v_prefs.selected_voice_id;
  
  -- Get style preset
  SELECT * INTO v_style FROM voice_style_presets WHERE style_type = v_prefs.teaching_style;
  
  -- Check for active voice clone
  SELECT * INTO v_clone FROM voice_clones 
  WHERE user_id = p_user_id AND status = 'ready' AND is_active = true
  ORDER BY created_at DESC LIMIT 1;
  
  RETURN jsonb_build_object(
    'voice', to_jsonb(v_voice),
    'clone', CASE WHEN v_clone.id IS NOT NULL THEN to_jsonb(v_clone) ELSE NULL END,
    'style', to_jsonb(v_style),
    'speed', v_prefs.playback_speed,
    'pitch_adjustment', v_prefs.pitch_adjustment,
    'accessibility', v_prefs.accessibility_settings,
    'apply_to', jsonb_build_object(
      'videos', v_prefs.apply_to_videos,
      'assistant', v_prefs.apply_to_assistant,
      'practice', v_prefs.apply_to_practice,
      'globally', v_prefs.apply_globally
    ),
    'is_default', false
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Save user voice preferences (AC 4)
CREATE OR REPLACE FUNCTION save_voice_preferences(
  p_user_id UUID,
  p_voice_id UUID DEFAULT NULL,
  p_speed DECIMAL DEFAULT 1.0,
  p_style TEXT DEFAULT 'mentor',
  p_pitch INTEGER DEFAULT 0,
  p_accessibility JSONB DEFAULT NULL,
  p_apply_globally BOOLEAN DEFAULT true
) RETURNS JSONB AS $$
DECLARE
  v_result RECORD;
BEGIN
  INSERT INTO user_voice_preferences (
    user_id, selected_voice_id, playback_speed, teaching_style,
    pitch_adjustment, accessibility_settings, apply_globally, updated_at
  ) VALUES (
    p_user_id, p_voice_id, p_speed, p_style,
    p_pitch, COALESCE(p_accessibility, '{}'::jsonb), p_apply_globally, now()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    selected_voice_id = COALESCE(p_voice_id, user_voice_preferences.selected_voice_id),
    playback_speed = p_speed,
    teaching_style = p_style,
    pitch_adjustment = p_pitch,
    accessibility_settings = COALESCE(p_accessibility, user_voice_preferences.accessibility_settings),
    apply_globally = p_apply_globally,
    updated_at = now()
  RETURNING * INTO v_result;
  
  RETURN to_jsonb(v_result);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Log TTS generation
CREATE OR REPLACE FUNCTION log_tts_generation(
  p_user_id UUID,
  p_voice_id UUID,
  p_text TEXT,
  p_context_type TEXT,
  p_context_id UUID DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
  v_log_id UUID;
BEGIN
  INSERT INTO tts_generation_log (
    user_id, voice_id, text_content, text_length,
    context_type, context_id, status
  ) VALUES (
    p_user_id, p_voice_id, p_text, length(p_text),
    p_context_type, p_context_id, 'pending'
  ) RETURNING id INTO v_log_id;
  
  RETURN v_log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Increment voice usage
CREATE OR REPLACE FUNCTION increment_voice_usage(p_voice_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE voice_options SET use_count = use_count + 1 WHERE id = p_voice_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get popular voices
CREATE OR REPLACE FUNCTION get_popular_voices(p_limit INTEGER DEFAULT 10)
RETURNS JSONB AS $$
BEGIN
  RETURN (
    SELECT jsonb_agg(to_jsonb(v.*))
    FROM (
      SELECT * FROM voice_options 
      WHERE is_active = true 
      ORDER BY use_count DESC, avg_rating DESC NULLS LAST
      LIMIT p_limit
    ) v
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- ROW LEVEL SECURITY
-- =====================================================
ALTER TABLE tts_providers ENABLE ROW LEVEL SECURITY;
ALTER TABLE voice_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_voice_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE voice_clones ENABLE ROW LEVEL SECURITY;
ALTER TABLE voice_style_presets ENABLE ROW LEVEL SECURITY;
ALTER TABLE tts_generation_log ENABLE ROW LEVEL SECURITY;

-- Public read for providers, voices, and presets
CREATE POLICY "Public can view providers" ON tts_providers FOR SELECT USING (is_active = true);
CREATE POLICY "Public can view voices" ON voice_options FOR SELECT USING (is_active = true);
CREATE POLICY "Public can view style presets" ON voice_style_presets FOR SELECT USING (true);

-- Users manage their own data
CREATE POLICY "Users manage own preferences" ON user_voice_preferences 
  FOR ALL TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Users manage own clones" ON voice_clones 
  FOR ALL TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Users view own TTS logs" ON tts_generation_log 
  FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Users create TTS logs" ON tts_generation_log 
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- INDEXES
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_voices_accent ON voice_options(accent);
CREATE INDEX IF NOT EXISTS idx_voices_gender ON voice_options(gender);
CREATE INDEX IF NOT EXISTS idx_voices_style ON voice_options(style);
CREATE INDEX IF NOT EXISTS idx_voices_premium ON voice_options(is_premium, required_tier);
CREATE INDEX IF NOT EXISTS idx_prefs_user ON user_voice_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_clones_user ON voice_clones(user_id);
CREATE INDEX IF NOT EXISTS idx_clones_status ON voice_clones(status);
CREATE INDEX IF NOT EXISTS idx_tts_log_user ON tts_generation_log(user_id);

-- =====================================================
-- TRIGGERS
-- =====================================================
CREATE OR REPLACE FUNCTION update_voice_prefs_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_voice_prefs_timestamp ON user_voice_preferences;
CREATE TRIGGER trigger_update_voice_prefs_timestamp
  BEFORE UPDATE ON user_voice_preferences
  FOR EACH ROW EXECUTE FUNCTION update_voice_prefs_timestamp();

-- =====================================================
-- COMMENTS
-- =====================================================
COMMENT ON TABLE voice_options IS 'Story 16.1: Available TTS voice options with accents, genders, and styles';
COMMENT ON TABLE user_voice_preferences IS 'Story 16.1: User voice customization preferences (AC 4)';
COMMENT ON TABLE voice_clones IS 'Story 16.1: User voice cloning for personalized TTS (AC 8)';
COMMENT ON TABLE voice_style_presets IS 'Story 16.1: Teaching style presets - Professor, Mentor, Peer (AC 3)';

