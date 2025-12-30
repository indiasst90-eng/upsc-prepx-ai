-- Quick fixes for remaining migration errors
-- Run these ALTER statements before running the problematic migrations

-- Fix 017: Add status column to daily_ca_documentary table
DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'daily_ca_videos') THEN
        BEGIN
            ALTER TABLE daily_ca_videos ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending';
        EXCEPTION WHEN insufficient_privilege THEN
            RAISE NOTICE 'Skipping ALTER TABLE daily_ca_videos due to insufficient privileges';
        END;
    END IF;
END $$;

-- Fix 018: Add is_completed column to interview_sessions table
DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'interview_sessions') THEN
        BEGIN
            ALTER TABLE interview_sessions ADD COLUMN IF NOT EXISTS is_completed BOOLEAN DEFAULT FALSE;
        EXCEPTION WHEN insufficient_privilege THEN
            RAISE NOTICE 'Skipping ALTER TABLE interview_sessions due to insufficient privileges';
        END;
    END IF;
END $$;

-- Fix 023: Drop constraint if exists, create partial unique index instead
DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'study_schedules') THEN
        BEGIN
            -- Drop the problematic constraint if it exists
            ALTER TABLE study_schedules DROP CONSTRAINT IF EXISTS one_active_schedule_per_user;
            -- Create partial unique index
            DO $migration$ BEGIN
    BEGIN
        CREATE UNIQUE INDEX IF NOT EXISTS idx_one_active_schedule_per_user 
            ON study_schedules(user_id) 
            WHERE is_active = true;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
        EXCEPTION WHEN insufficient_privilege THEN
            RAISE NOTICE 'Skipping changes to study_schedules due to insufficient privileges';
        END;
    END IF;
END $$;

-- Fix 024: Add IF NOT EXISTS to index creation
-- This needs to be fixed in the migration file itself

-- Fix 036: Conditional ALTER for invoices table
DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'invoices') THEN
        BEGIN
            ALTER TABLE public.invoices ADD COLUMN IF NOT EXISTS razorpay_payment_id TEXT;
        EXCEPTION WHEN insufficient_privilege THEN
            RAISE NOTICE 'Skipping ALTER TABLE invoices due to insufficient privileges';
        END;
    END IF;
END $$;

SELECT 'Migration pre-fixes applied' AS status;
