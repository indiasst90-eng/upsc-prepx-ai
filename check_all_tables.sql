-- Comprehensive Table Verification Script
-- Run this in Supabase SQL Editor to check all tables

SELECT 
  schemaname,
  tablename,
  CASE 
    WHEN tablename IN (
      -- Core tables
      'users', 'user_profiles', 'subscriptions', 'entitlements', 'audit_logs',
      -- Knowledge base
      'knowledge_sources', 'knowledge_chunks', 'knowledge_embeddings',
      -- Video system
      'doubt_videos', 'daily_ca_videos', 'topic_shorts', 'jobs', 'job_queue_config',
      -- Notes
      'user_notes', 'note_versions', 'note_tags',
      -- Syllabus
      'syllabus_nodes', 'user_syllabus_progress',
      -- Study schedules
      'study_schedules', 'schedule_tasks', 'schedule_completions',
      -- Revision
      'revision_targets', 'revision_videos', 'flashcards', 'flashcard_reviews', 'revision_quizzes', 'quiz_attempts',
      -- Answer writing
      'answer_submissions', 'submission_drafts', 'daily_questions', 'answer_evaluations', 'model_answers',
      -- Essays
      'essay_submissions', 'essay_evaluations', 'user_essays',
      -- PYQ
      'pyq_papers', 'pyq_questions', 'pyq_model_answers', 'pyq_videos', 'pyq_bookmarks',
      -- Question bank
      'generated_questions', 'question_generation_logs', 'question_options', 'question_attempts',
      'user_difficulty_stats', 'difficulty_badges', 'badge_definitions',
      -- Practice sessions
      'practice_sessions', 'practice_session_questions', 'practice_session_analytics',
      -- Assistant
      'assistant_conversations', 'assistant_usage', 'assistant_preferences', 'assistant_checkins',
      -- Mindmaps
      'mindmaps', 'mindmap_versions', 'mindmap_shares', 'mindmap_collaborators', 'mindmap_edit_history',
      -- Bookmarks
      'bookmarks', 'bookmark_links', 'bookmark_link_queue', 'bookmark_reviews', 'review_streaks',
      'bookmark_collections',
      -- Documentary
      'documentary_scripts', 'documentary_chapters', 'documentary_render_queue', 'documentary_template_config',
      'documentary_watch_progress', 'chapter_watch_progress', 'documentary_downloads', 'documentary_offline_cache',
      'weekly_documentaries', 'weekly_doc_segments', 'weekly_doc_schedule',
      -- Advanced features
      'math_problems', 'math_solutions', 'memory_palace_rooms', 'memory_palace_items',
      'interactive_maps', 'map_markers', 'ethics_cases', 'ethics_responses',
      'case_laws', 'case_law_explanations', 'interview_sessions', 'interview_questions', 'interview_feedback',
      -- Gamification
      'user_xp', 'user_badges', 'user_streaks', 'leaderboards',
      -- Topic difficulty
      'topic_difficulty_predictions', 'user_topic_performance',
      -- 360 experiences
      'immersive_experiences', 'experience_interactions',
      -- Voice customization
      'voice_profiles', 'voice_samples',
      -- Social media
      'social_posts', 'post_analytics',
      -- Search
      'search_history', 'content_reports',
      -- Admin
      'admin_settings', 'ai_providers', 'ai_models', 'ads_config', 'ad_placements', 'ad_providers', 'ad_revenue',
      -- Monetization
      'payment_orders', 'payment_transactions', 'refund_requests',
      -- Notifications
      'notification_preferences', 'progress_videos',
      -- Test series
      'test_series', 'test_attempts',
      -- Performance
      'performance_analytics',
      -- Community
      'discussions', 'discussion_replies',
      -- Progress
      'user_progress', 'saved_lectures', 'pdf_downloads',
      -- Memory & Ethics
      'memory_palace_memories', 'ethics_responses'
    ) THEN '✅ EXISTS'
    ELSE '❓ UNKNOWN'
  END as status,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- Count total tables
SELECT 
  COUNT(*) as total_tables,
  COUNT(*) FILTER (WHERE tablename LIKE 'user%') as user_tables,
  COUNT(*) FILTER (WHERE tablename LIKE '%video%') as video_tables,
  COUNT(*) FILTER (WHERE tablename LIKE '%question%') as question_tables,
  COUNT(*) FILTER (WHERE tablename LIKE '%documentary%') as documentary_tables
FROM pg_tables
WHERE schemaname = 'public';

-- Check for missing critical tables
WITH expected_tables AS (
  SELECT unnest(ARRAY[
    'users', 'user_profiles', 'subscriptions', 'entitlements',
    'knowledge_sources', 'knowledge_chunks',
    'doubt_videos', 'daily_ca_videos', 'jobs',
    'user_notes', 'syllabus_nodes',
    'pyq_papers', 'pyq_questions',
    'generated_questions', 'question_attempts',
    'bookmarks', 'mindmaps',
    'documentary_scripts', 'documentary_chapters',
    'admin_settings', 'ai_providers', 'ai_models'
  ]) as table_name
),
existing_tables AS (
  SELECT tablename as table_name
  FROM pg_tables
  WHERE schemaname = 'public'
)
SELECT 
  e.table_name,
  CASE WHEN x.table_name IS NOT NULL THEN '✅ EXISTS' ELSE '❌ MISSING' END as status
FROM expected_tables e
LEFT JOIN existing_tables x ON e.table_name = x.table_name
ORDER BY status, e.table_name;
