-- Migration: 025_revision_targets.sql
-- Story: 6.3 - Smart Revision Booster Algorithm

CREATE TABLE IF NOT EXISTS public.revision_targets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL ,
  topic_id UUID NOT NULL REFERENCES public.topic_progress(id) ON DELETE CASCADE,
  weakness_score DECIMAL(5,2) NOT NULL,
  identified_date DATE NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed')),
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, topic_id, identified_date)
);

DO $migration$ BEGIN
    BEGIN
        CREATE INDEX idx_revision_targets_user ON public.revision_targets(user_id, status);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX idx_revision_targets_date ON public.revision_targets(identified_date);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.revision_targets ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can manage own revision targets"
  ON public.revision_targets FOR ALL
  USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        COMMENT ON TABLE public.revision_targets IS 'Weekly identified weak topics for revision';
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


