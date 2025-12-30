-- Migration: 009_video_jobs.sql
-- Video Job Queue Management Tables

-- Job Queue Configuration Table
CREATE TABLE IF NOT EXISTS job_queue_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  max_concurrent_renders INTEGER DEFAULT 10,
  max_manim_renders INTEGER DEFAULT 4,
  job_timeout_minutes INTEGER DEFAULT 10,
  retry_interval_minutes INTEGER DEFAULT 5,
  peak_hour_start TIME DEFAULT '06:00',
  peak_hour_end TIME DEFAULT '21:00',
  peak_worker_multiplier DECIMAL DEFAULT 1.5,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Video Jobs Table
CREATE TABLE IF NOT EXISTS jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_type TEXT NOT NULL CHECK (job_type IN ('doubt', 'topic_short', 'daily_ca')),
  priority TEXT NOT NULL CHECK (priority IN ('high', 'medium', 'low')),
  status TEXT NOT NULL DEFAULT 'queued' CHECK (status IN ('queued', 'processing', 'completed', 'failed', 'cancelled')),
  payload JSONB NOT NULL,
  queue_position INTEGER,
  retry_count INTEGER DEFAULT 0,
  max_retries INTEGER DEFAULT 3,
  error_message TEXT,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  user_id UUID 
);

-- Fix for existing jobs table schema mismatch
DO $$ 
DECLARE r record;
BEGIN
    -- 1. Add missing columns
    ALTER TABLE jobs ADD COLUMN IF NOT EXISTS queue_position INTEGER;
    ALTER TABLE jobs ADD COLUMN IF NOT EXISTS retry_count INTEGER DEFAULT 0;
    ALTER TABLE jobs ADD COLUMN IF NOT EXISTS max_retries INTEGER DEFAULT 3;
    ALTER TABLE jobs ADD COLUMN IF NOT EXISTS error_message TEXT;
    
    -- 2. Fix priority column if it is integer
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'jobs' AND column_name = 'priority' AND data_type = 'integer'
    ) THEN
        -- Drop constraints on priority first
        FOR r IN SELECT constraint_name FROM information_schema.constraint_column_usage WHERE table_name = 'jobs' AND column_name = 'priority'
        LOOP
            EXECUTE 'ALTER TABLE jobs DROP CONSTRAINT IF EXISTS ' || quote_ident(r.constraint_name);
        END LOOP;
        
        -- Change type
        ALTER TABLE jobs ALTER COLUMN priority TYPE TEXT USING 
            CASE 
                WHEN priority <= 3 THEN 'high' 
                WHEN priority <= 7 THEN 'medium' 
                ELSE 'low' 
            END;
            
        -- Add new constraint (might fail if data doesn't match, catch it?)
        BEGIN
            ALTER TABLE jobs ADD CHECK (priority IN ('high', 'medium', 'low'));
        EXCEPTION WHEN check_violation THEN
            RAISE NOTICE 'Could not add priority check constraint due to existing data';
        END;
    END IF;
EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'Skipping jobs table alteration due to privileges';
END $$;

-- Indexes
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_jobs_status ON jobs(status);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_jobs_priority ON jobs(priority);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_jobs_job_type ON jobs(job_type);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_jobs_created_at ON jobs(created_at);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_jobs_user_id ON jobs(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_jobs_queue_position ON jobs(queue_position) WHERE status = 'queued';
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_jobs_queue_processing ON jobs(status, priority, created_at) WHERE status = 'queued';
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

-- Seed default configuration
INSERT INTO job_queue_config (id) VALUES (gen_random_uuid())
ON CONFLICT DO NOTHING;

-- Function to update queue positions
DO $migration$ BEGIN
    BEGIN
        CREATE OR REPLACE FUNCTION update_queue_positions()
RETURNS TRIGGER AS $$
BEGIN
  WITH ranked_jobs AS (
    SELECT id, ROW_NUMBER() OVER (
      ORDER BY 
        CASE priority 
          WHEN 'high' THEN 1 
          WHEN 'medium' THEN 2 
          WHEN 'low' THEN 3 
        END,
        created_at ASC
    ) as new_position
    FROM jobs
    WHERE status = 'queued'
  )
  UPDATE jobs
  SET queue_position = ranked_jobs.new_position
  FROM ranked_jobs
  WHERE jobs.id = ranked_jobs.id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

-- Trigger to auto-update queue positions

DO $migration$ BEGIN
    BEGIN
        CREATE TRIGGER trigger_update_queue_positions
AFTER INSERT OR UPDATE OF status, priority ON jobs
FOR EACH STATEMENT
EXECUTE FUNCTION update_queue_positions();
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

-- Function to get queue statistics
DO $migration$ BEGIN
    BEGIN
        CREATE OR REPLACE FUNCTION get_queue_stats()
RETURNS TABLE (
  total_queued BIGINT,
  total_processing BIGINT,
  total_completed_today BIGINT,
  total_failed_today BIGINT,
  avg_wait_time_minutes NUMERIC,
  high_priority_count BIGINT,
  medium_priority_count BIGINT,
  low_priority_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*) FILTER (WHERE status = 'queued') as total_queued,
    COUNT(*) FILTER (WHERE status = 'processing') as total_processing,
    COUNT(*) FILTER (WHERE status = 'completed' AND completed_at >= CURRENT_DATE) as total_completed_today,
    COUNT(*) FILTER (WHERE status = 'failed' AND updated_at >= CURRENT_DATE) as total_failed_today,
    AVG(EXTRACT(EPOCH FROM (COALESCE(started_at, NOW()) - created_at)) / 60) FILTER (WHERE status IN ('processing', 'completed')) as avg_wait_time_minutes,
    COUNT(*) FILTER (WHERE status = 'queued' AND priority = 'high') as high_priority_count,
    COUNT(*) FILTER (WHERE status = 'queued' AND priority = 'medium') as medium_priority_count,
    COUNT(*) FILTER (WHERE status = 'queued' AND priority = 'low') as low_priority_count
  FROM jobs;
END;
$$ LANGUAGE plpgsql;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
