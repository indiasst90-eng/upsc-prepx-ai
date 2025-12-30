-- Quick Table Verification
-- Copy and paste this into Supabase SQL Editor

-- 1. List all public tables
SELECT tablename 
FROM pg_tables 
WHERE schemaname = 'public' 
ORDER BY tablename;

-- 2. Count tables by category
SELECT 
  'Total Tables' as category,
  COUNT(*)::text as count
FROM pg_tables 
WHERE schemaname = 'public'

UNION ALL

SELECT 'User/Auth Tables', COUNT(*)::text
FROM pg_tables 
WHERE schemaname = 'public' AND tablename ~ '^(users|user_|auth)'

UNION ALL

SELECT 'Video Tables', COUNT(*)::text
FROM pg_tables 
WHERE schemaname = 'public' AND tablename ~ 'video'

UNION ALL

SELECT 'Question/Quiz Tables', COUNT(*)::text
FROM pg_tables 
WHERE schemaname = 'public' AND tablename ~ '(question|quiz|pyq)'

UNION ALL

SELECT 'Documentary Tables', COUNT(*)::text
FROM pg_tables 
WHERE schemaname = 'public' AND tablename ~ 'documentary'

UNION ALL

SELECT 'Bookmark/Mindmap Tables', COUNT(*)::text
FROM pg_tables 
WHERE schemaname = 'public' AND tablename ~ '(bookmark|mindmap)'

UNION ALL

SELECT 'Admin/Settings Tables', COUNT(*)::text
FROM pg_tables 
WHERE schemaname = 'public' AND tablename ~ '(admin|settings|ai_|ad_)';

-- 3. Check critical tables exist
SELECT 
  table_name,
  CASE WHEN EXISTS (
    SELECT 1 FROM pg_tables 
    WHERE schemaname = 'public' AND tablename = table_name
  ) THEN '✅ EXISTS' ELSE '❌ MISSING' END as status
FROM (VALUES 
  ('users'),
  ('user_profiles'),
  ('subscriptions'),
  ('entitlements'),
  ('knowledge_sources'),
  ('knowledge_chunks'),
  ('doubt_videos'),
  ('daily_ca_videos'),
  ('jobs'),
  ('user_notes'),
  ('syllabus_nodes'),
  ('pyq_papers'),
  ('pyq_questions'),
  ('generated_questions'),
  ('question_attempts'),
  ('bookmarks'),
  ('mindmaps'),
  ('documentary_scripts'),
  ('documentary_chapters'),
  ('admin_settings'),
  ('ai_providers'),
  ('ai_models'),
  ('ads_config'),
  ('weekly_documentaries')
) AS t(table_name)
ORDER BY status DESC, table_name;
