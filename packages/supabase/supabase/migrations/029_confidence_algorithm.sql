-- Migration: 029_confidence_algorithm.sql
-- Story: 6.8 - Confidence Meter Algorithm Tuning

CREATE TABLE IF NOT EXISTS public.confidence_algorithm_config (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  version TEXT NOT NULL UNIQUE,
  quiz_weight DECIMAL(3,2) DEFAULT 0.40,
  time_weight DECIMAL(3,2) DEFAULT 0.20,
  video_weight DECIMAL(3,2) DEFAULT 0.20,
  answer_weight DECIMAL(3,2) DEFAULT 0.20,
  decay_rate DECIMAL(3,2) DEFAULT 0.05,
  is_active BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN
INSERT INTO public.confidence_algorithm_config (version, is_active) 
VALUES ('v1', TRUE);
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        COMMENT ON TABLE public.confidence_algorithm_config IS 'Confidence scoring algorithm configuration';
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


