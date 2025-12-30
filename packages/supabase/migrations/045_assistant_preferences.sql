-- Migration 045: AI Teaching Assistant Style Preferences
-- Story 9.2: Teaching Style Customization

-- ============================================
-- ASSISTANT PREFERENCES TABLE (AC 6)
-- ============================================

CREATE TABLE IF NOT EXISTS public.assistant_preferences (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL  UNIQUE,
  
  -- AC 2: Teaching approach
  teaching_style TEXT NOT NULL DEFAULT 'detailed' 
    CHECK (teaching_style IN ('concise', 'detailed', 'example_heavy', 'socratic')),
  
  -- AC 3: Tone control
  tone TEXT NOT NULL DEFAULT 'friendly'
    CHECK (tone IN ('formal', 'friendly', 'motivational', 'strict')),
  
  -- AC 4: Explanation depth (1=ELI5, 5=postgraduate)
  depth_level INTEGER NOT NULL DEFAULT 3 CHECK (depth_level BETWEEN 1 AND 5),
  
  -- AC 5: Language preference
  language TEXT NOT NULL DEFAULT 'english'
    CHECK (language IN ('english', 'hindi', 'hinglish')),
  
  -- AC 9: Active preset (if using preset)
  active_preset TEXT DEFAULT NULL
    CHECK (active_preset IN ('beginner_friendly', 'advanced_scholar', 'quick_revision', 'motivational_coach', NULL)),
  
  -- Additional customizations
  use_examples BOOLEAN DEFAULT TRUE,
  include_mnemonics BOOLEAN DEFAULT TRUE,
  suggest_practice BOOLEAN DEFAULT TRUE,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_assistant_pref_user ON public.assistant_preferences(user_id);

-- RLS Policies
ALTER TABLE public.assistant_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own preferences"
  ON public.assistant_preferences FOR ALL
  USING (auth.uid() = user_id);

-- ============================================
-- PRESET DEFINITIONS (AC 9)
-- ============================================

CREATE TABLE IF NOT EXISTS public.assistant_presets (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  teaching_style TEXT NOT NULL,
  tone TEXT NOT NULL,
  depth_level INTEGER NOT NULL,
  language TEXT NOT NULL DEFAULT 'english',
  use_examples BOOLEAN DEFAULT TRUE,
  include_mnemonics BOOLEAN DEFAULT TRUE,
  suggest_practice BOOLEAN DEFAULT TRUE,
  icon TEXT DEFAULT '📚'
);

-- AC 9: Insert preset definitions
INSERT INTO public.assistant_presets (id, name, description, teaching_style, tone, depth_level, use_examples, include_mnemonics, suggest_practice, icon)
VALUES 
  ('beginner_friendly', 'Beginner Friendly', 'Simple explanations with lots of examples, perfect for starting your UPSC journey', 'example_heavy', 'friendly', 2, TRUE, TRUE, TRUE, '🌱'),
  ('advanced_scholar', 'Advanced Scholar', 'In-depth, comprehensive explanations with academic rigor', 'detailed', 'formal', 5, TRUE, FALSE, TRUE, '🎓'),
  ('quick_revision', 'Quick Revision', 'Concise bullet points for fast revision before exams', 'concise', 'friendly', 3, FALSE, TRUE, FALSE, '⚡'),
  ('motivational_coach', 'Motivational Coach', 'Encouraging style with positive reinforcement and goal-oriented guidance', 'example_heavy', 'motivational', 3, TRUE, TRUE, TRUE, '💪')
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Get user preferences (with defaults)
CREATE OR REPLACE FUNCTION get_assistant_preferences(p_user_id UUID)
RETURNS TABLE (
  teaching_style TEXT,
  tone TEXT,
  depth_level INTEGER,
  language TEXT,
  active_preset TEXT,
  use_examples BOOLEAN,
  include_mnemonics BOOLEAN,
  suggest_practice BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(ap.teaching_style, 'detailed'),
    COALESCE(ap.tone, 'friendly'),
    COALESCE(ap.depth_level, 3),
    COALESCE(ap.language, 'english'),
    ap.active_preset,
    COALESCE(ap.use_examples, TRUE),
    COALESCE(ap.include_mnemonics, TRUE),
    COALESCE(ap.suggest_practice, TRUE)
  FROM public.assistant_preferences ap
  WHERE ap.user_id = p_user_id
  UNION ALL
  SELECT 'detailed', 'friendly', 3, 'english', NULL, TRUE, TRUE, TRUE
  WHERE NOT EXISTS (SELECT 1 FROM public.assistant_preferences WHERE user_id = p_user_id)
  LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- Save or update preferences
CREATE OR REPLACE FUNCTION save_assistant_preferences(
  p_user_id UUID,
  p_teaching_style TEXT DEFAULT NULL,
  p_tone TEXT DEFAULT NULL,
  p_depth_level INTEGER DEFAULT NULL,
  p_language TEXT DEFAULT NULL,
  p_active_preset TEXT DEFAULT NULL,
  p_use_examples BOOLEAN DEFAULT NULL,
  p_include_mnemonics BOOLEAN DEFAULT NULL,
  p_suggest_practice BOOLEAN DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_id UUID;
BEGIN
  INSERT INTO public.assistant_preferences (
    user_id, teaching_style, tone, depth_level, language,
    active_preset, use_examples, include_mnemonics, suggest_practice, updated_at
  )
  VALUES (
    p_user_id,
    COALESCE(p_teaching_style, 'detailed'),
    COALESCE(p_tone, 'friendly'),
    COALESCE(p_depth_level, 3),
    COALESCE(p_language, 'english'),
    p_active_preset,
    COALESCE(p_use_examples, TRUE),
    COALESCE(p_include_mnemonics, TRUE),
    COALESCE(p_suggest_practice, TRUE),
    NOW()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    teaching_style = COALESCE(EXCLUDED.teaching_style, assistant_preferences.teaching_style),
    tone = COALESCE(EXCLUDED.tone, assistant_preferences.tone),
    depth_level = COALESCE(EXCLUDED.depth_level, assistant_preferences.depth_level),
    language = COALESCE(EXCLUDED.language, assistant_preferences.language),
    active_preset = EXCLUDED.active_preset,
    use_examples = COALESCE(EXCLUDED.use_examples, assistant_preferences.use_examples),
    include_mnemonics = COALESCE(EXCLUDED.include_mnemonics, assistant_preferences.include_mnemonics),
    suggest_practice = COALESCE(EXCLUDED.suggest_practice, assistant_preferences.suggest_practice),
    updated_at = NOW()
  RETURNING id INTO v_id;
  
  RETURN v_id;
END;
$$ LANGUAGE plpgsql;

-- Apply preset to user preferences
CREATE OR REPLACE FUNCTION apply_assistant_preset(p_user_id UUID, p_preset_id TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  v_preset RECORD;
BEGIN
  SELECT * INTO v_preset FROM public.assistant_presets WHERE id = p_preset_id;
  
  IF v_preset IS NULL THEN
    RETURN FALSE;
  END IF;
  
  PERFORM save_assistant_preferences(
    p_user_id,
    v_preset.teaching_style,
    v_preset.tone,
    v_preset.depth_level,
    v_preset.language,
    p_preset_id,
    v_preset.use_examples,
    v_preset.include_mnemonics,
    v_preset.suggest_practice
  );
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- AC 10: Reset to defaults
CREATE OR REPLACE FUNCTION reset_assistant_preferences(p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE public.assistant_preferences
  SET 
    teaching_style = 'detailed',
    tone = 'friendly',
    depth_level = 3,
    language = 'english',
    active_preset = NULL,
    use_examples = TRUE,
    include_mnemonics = TRUE,
    suggest_practice = TRUE,
    updated_at = NOW()
  WHERE user_id = p_user_id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Get all presets
CREATE OR REPLACE FUNCTION get_all_presets()
RETURNS TABLE (
  id TEXT,
  name TEXT,
  description TEXT,
  teaching_style TEXT,
  tone TEXT,
  depth_level INTEGER,
  icon TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ap.id,
    ap.name,
    ap.description,
    ap.teaching_style,
    ap.tone,
    ap.depth_level,
    ap.icon
  FROM public.assistant_presets ap
  ORDER BY ap.name;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE public.assistant_preferences IS 'Story 9.2 AC 6: User teaching style preferences';
COMMENT ON TABLE public.assistant_presets IS 'Story 9.2 AC 9: Predefined teaching style presets';
COMMENT ON FUNCTION get_assistant_preferences IS 'Story 9.2: Get user preferences with defaults';
COMMENT ON FUNCTION save_assistant_preferences IS 'Story 9.2: Save or update preferences';
COMMENT ON FUNCTION apply_assistant_preset IS 'Story 9.2 AC 9: Apply preset to user';
COMMENT ON FUNCTION reset_assistant_preferences IS 'Story 9.2 AC 10: Reset to defaults';

