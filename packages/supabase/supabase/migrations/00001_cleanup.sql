-- CLEANUP SCRIPT: Run this FIRST before running 001_initial_schema.sql
-- This drops any partially created tables so we can start fresh

-- Drop tables in reverse dependency order
DROP TABLE IF EXISTS public.model_answers CASCADE;
DROP TABLE IF EXISTS public.pyq_bank CASCADE;
DROP TABLE IF EXISTS public.daily_updates CASCADE;
DROP TABLE IF EXISTS public.queue_config CASCADE;
DROP TABLE IF EXISTS public.jobs CASCADE;
DROP TABLE IF EXISTS public.video_renders CASCADE;
DROP TABLE IF EXISTS public.comprehensive_notes CASCADE;
DROP TABLE IF EXISTS public.knowledge_chunks CASCADE;
DROP TABLE IF EXISTS public.pdf_uploads CASCADE;
DROP TABLE IF EXISTS public.syllabus_progress CASCADE;
DROP TABLE IF EXISTS public.syllabus_nodes CASCADE;
DROP TABLE IF EXISTS public.entitlements CASCADE;
DROP TABLE IF EXISTS public.subscriptions CASCADE;
DROP TABLE IF EXISTS public.plans CASCADE;
DROP TABLE IF EXISTS public.user_profiles CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;
DROP TABLE IF EXISTS public.practice_sessions CASCADE;
DROP TABLE IF EXISTS public.practice_answers CASCADE;
DROP TABLE IF EXISTS public.answer_submissions CASCADE;

-- Drop functions that might exist
DROP FUNCTION IF EXISTS check_feature_access CASCADE;
DROP FUNCTION IF EXISTS increment_entitlement_usage CASCADE;

-- Now you can run 001_initial_schema.sql
SELECT 'Cleanup complete. Now run 001_initial_schema.sql' as status;
