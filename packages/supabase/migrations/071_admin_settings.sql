-- Migration 071: Admin Settings & AI Configuration Tables
-- Full backend support for AI Provider settings and Ads management

-- Admin Settings Table (key-value store)
CREATE TABLE IF NOT EXISTS public.admin_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT NOT NULL UNIQUE,
  value JSONB NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('ai', 'ads', 'general', 'features', 'security')),
  description TEXT,
  is_sensitive BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_admin_settings_key ON public.admin_settings(key);
CREATE INDEX idx_admin_settings_category ON public.admin_settings(category);

-- AI Providers Table
CREATE TABLE IF NOT EXISTS public.ai_providers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  base_url TEXT NOT NULL DEFAULT '',
  api_key_encrypted TEXT,
  auth_type TEXT NOT NULL DEFAULT 'bearer',
  custom_headers JSONB,
  is_active BOOLEAN DEFAULT false,
  is_custom BOOLEAN DEFAULT false,
  description TEXT,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- AI Models Table
CREATE TABLE IF NOT EXISTS public.ai_models (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  model_id TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  model_type TEXT NOT NULL CHECK (model_type IN ('llm', 'tts', 'stt', 'embeddings', 'image')),
  provider_id TEXT NOT NULL,
  model_name TEXT NOT NULL,
  is_primary BOOLEAN DEFAULT false,
  is_fallback BOOLEAN DEFAULT false,
  config JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Ads Configuration Table
CREATE TABLE IF NOT EXISTS public.ads_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  global_enabled BOOLEAN DEFAULT true,
  hide_for_pro BOOLEAN DEFAULT true,
  ad_free_trial_days INTEGER DEFAULT 3,
  min_screens_between_ads INTEGER DEFAULT 5,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Ad Placements Table
CREATE TABLE IF NOT EXISTS public.ad_placements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  placement_id TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  location TEXT NOT NULL,
  ad_type TEXT NOT NULL CHECK (ad_type IN ('banner', 'interstitial', 'native', 'rewarded')),
  enabled BOOLEAN DEFAULT false,
  frequency INTEGER DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Ad Providers Table
CREATE TABLE IF NOT EXISTS public.ad_providers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  publisher_id TEXT,
  app_id TEXT,
  enabled BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Ad Revenue Table
CREATE TABLE IF NOT EXISTS public.ad_revenue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date DATE NOT NULL,
  impressions INTEGER DEFAULT 0,
  clicks INTEGER DEFAULT 0,
  revenue DECIMAL(10,2) DEFAULT 0,
  provider_id TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(date, provider_id)
);

-- Seed AI Providers
INSERT INTO public.ai_providers (provider_id, name, base_url, auth_type, is_active, description, display_order) VALUES
  ('a4f', 'A4F Unified API', 'https://api.a4f.co/v1', 'bearer', true, 'All-in-one gateway for 50+ AI models', 1),
  ('openai', 'OpenAI', 'https://api.openai.com/v1', 'bearer', false, 'GPT-4o, DALL-E, Whisper, TTS', 2),
  ('anthropic', 'Anthropic', 'https://api.anthropic.com/v1', 'api-key', false, 'Claude 3.5 Sonnet, Claude 3 Opus', 3),
  ('google', 'Google AI', 'https://generativelanguage.googleapis.com/v1beta', 'api-key', false, 'Gemini 2.0, Gemini Pro', 4),
  ('groq', 'Groq', 'https://api.groq.com/openai/v1', 'bearer', false, 'Ultra-fast Llama, Mixtral', 5),
  ('deepseek', 'DeepSeek', 'https://api.deepseek.com/v1', 'bearer', false, 'DeepSeek-V3, Coder', 6),
  ('mistral', 'Mistral AI', 'https://api.mistral.ai/v1', 'bearer', false, 'Mistral Large, Codestral', 7),
  ('openrouter', 'OpenRouter', 'https://openrouter.ai/api/v1', 'bearer', false, 'Unified API for all providers', 8),
  ('ollama', 'Ollama', 'http://localhost:11434', 'bearer', false, 'Self-hosted local LLMs', 9),
  ('custom1', 'Custom Provider 1', '', 'bearer', false, 'Your custom AI endpoint', 10),
  ('custom2', 'Custom Provider 2', '', 'bearer', false, 'Your custom AI endpoint', 11),
  ('custom3', 'Custom Provider 3', '', 'bearer', false, 'Your custom AI endpoint', 12)
ON CONFLICT (provider_id) DO NOTHING;

-- Seed AI Models
INSERT INTO public.ai_models (model_id, name, model_type, provider_id, model_name, is_primary, is_fallback) VALUES
  ('primary-llm', 'Primary LLM', 'llm', 'a4f', 'provider-3/llama-4-scout', true, false),
  ('fallback-llm', 'Fallback LLM', 'llm', 'a4f', 'provider-2/gpt-4.1', false, true),
  ('image-understanding', 'Image Understanding', 'llm', 'a4f', 'provider-3/gemini-2.5-flash', false, false),
  ('tts', 'Text-to-Speech', 'tts', 'a4f', 'provider-5/tts-1', true, false),
  ('stt', 'Speech-to-Text', 'stt', 'a4f', 'provider-5/whisper-1', true, false),
  ('embeddings', 'Embeddings', 'embeddings', 'a4f', 'provider-5/qwen3-embedding-8b', true, false),
  ('image-gen', 'Image Generation', 'image', 'a4f', 'provider-4/imagen-4', true, false)
ON CONFLICT (model_id) DO NOTHING;

-- Seed Ads Config
INSERT INTO public.ads_config (global_enabled, hide_for_pro, ad_free_trial_days, min_screens_between_ads) 
VALUES (true, true, 3, 5)
ON CONFLICT DO NOTHING;

-- Seed Ad Placements
INSERT INTO public.ad_placements (placement_id, name, location, ad_type, enabled, frequency) VALUES
  ('home-banner', 'Home Page Banner', 'dashboard', 'banner', true, 1),
  ('notes-interstitial', 'Notes Interstitial', 'notes', 'interstitial', false, 5),
  ('video-preroll', 'Video Pre-roll', 'videos', 'interstitial', false, 3),
  ('quiz-rewarded', 'Quiz Hint Rewarded', 'quiz', 'rewarded', true, 1),
  ('pyq-native', 'PYQ Native Ads', 'pyqs', 'native', false, 10),
  ('sidebar-banner', 'Sidebar Banner', 'global', 'banner', true, 1)
ON CONFLICT (placement_id) DO NOTHING;

-- Seed Ad Providers
INSERT INTO public.ad_providers (provider_id, name, enabled) VALUES
  ('google', 'Google AdMob / AdSense', true),
  ('facebook', 'Meta Audience Network', false),
  ('unity', 'Unity Ads', false),
  ('applovin', 'AppLovin MAX', false),
  ('custom', 'Custom Ad Server', false)
ON CONFLICT (provider_id) DO NOTHING;

-- RLS Policies
ALTER TABLE public.admin_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_providers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_models ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ads_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ad_placements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ad_providers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ad_revenue ENABLE ROW LEVEL SECURITY;

-- Service role access for all admin tables
CREATE POLICY "Service role full access to admin_settings" ON public.admin_settings FOR ALL USING (true);
CREATE POLICY "Service role full access to ai_providers" ON public.ai_providers FOR ALL USING (true);
CREATE POLICY "Service role full access to ai_models" ON public.ai_models FOR ALL USING (true);
CREATE POLICY "Service role full access to ads_config" ON public.ads_config FOR ALL USING (true);
CREATE POLICY "Service role full access to ad_placements" ON public.ad_placements FOR ALL USING (true);
CREATE POLICY "Service role full access to ad_providers" ON public.ad_providers FOR ALL USING (true);
CREATE POLICY "Service role full access to ad_revenue" ON public.ad_revenue FOR ALL USING (true);

-- Function to get active AI configuration
CREATE OR REPLACE FUNCTION get_active_ai_config()
RETURNS TABLE (
  model_id TEXT,
  model_type TEXT,
  provider_name TEXT,
  base_url TEXT,
  model_name TEXT,
  auth_type TEXT,
  is_primary BOOLEAN,
  is_fallback BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    m.model_id,
    m.model_type,
    p.name as provider_name,
    p.base_url,
    m.model_name,
    p.auth_type,
    m.is_primary,
    m.is_fallback
  FROM public.ai_models m
  JOIN public.ai_providers p ON m.provider_id = p.provider_id
  WHERE p.is_active = true
  ORDER BY m.is_primary DESC, m.is_fallback DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON TABLE public.admin_settings IS 'Platform configuration settings';
COMMENT ON TABLE public.ai_providers IS 'AI service provider configurations';
COMMENT ON TABLE public.ai_models IS 'AI model assignments for different use cases';
COMMENT ON TABLE public.ads_config IS 'Global advertising configuration';
COMMENT ON TABLE public.ad_placements IS 'Ad placement zones in the app';
COMMENT ON TABLE public.ad_providers IS 'Advertising network configurations';

