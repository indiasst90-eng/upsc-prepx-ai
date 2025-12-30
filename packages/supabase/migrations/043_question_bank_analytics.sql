-- Migration 043: Complete Question Bank Analytics System
-- Story 8.10: Analytics & Insights Dashboard

-- ============================================
-- AC 3: SUBJECT-WISE BREAKDOWN
-- ============================================

CREATE OR REPLACE FUNCTION get_subject_analytics(
  p_user_id UUID,
  p_days INTEGER DEFAULT 30
)
RETURNS TABLE (
  subject TEXT,
  total_attempts INTEGER,
  correct_attempts INTEGER,
  accuracy DECIMAL(5,2),
  avg_time_seconds INTEGER,
  last_attempt TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  WITH attempts_with_topic AS (
    SELECT 
      qa.is_correct,
      qa.time_taken_seconds,
      qa.created_at,
      COALESCE(
        gq.topic,
        pq.subject,
        'Unknown'
      ) as topic
    FROM public.question_attempts qa
    LEFT JOIN public.generated_questions gq ON qa.question_id = gq.id AND qa.question_type = 'generated'
    LEFT JOIN public.pyq_questions pq ON qa.question_id = pq.id AND qa.question_type = 'pyq'
    WHERE qa.user_id = p_user_id
      AND qa.created_at >= NOW() - (p_days || ' days')::INTERVAL
  )
  SELECT 
    topic as subject,
    COUNT(*)::INTEGER as total_attempts,
    COUNT(*) FILTER (WHERE is_correct)::INTEGER as correct_attempts,
    CASE WHEN COUNT(*) > 0 
      THEN ROUND((COUNT(*) FILTER (WHERE is_correct)::DECIMAL / COUNT(*)) * 100, 2)
      ELSE 0
    END as accuracy,
    COALESCE(AVG(time_taken_seconds)::INTEGER, 0) as avg_time_seconds,
    MAX(created_at) as last_attempt
  FROM attempts_with_topic
  GROUP BY topic
  ORDER BY total_attempts DESC;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- AC 5: TIME ANALYSIS
-- ============================================

CREATE OR REPLACE FUNCTION get_time_analysis(
  p_user_id UUID,
  p_days INTEGER DEFAULT 30
)
RETURNS TABLE (
  avg_time_per_question INTEGER,
  total_practice_time_minutes INTEGER,
  is_rushing BOOLEAN,
  is_too_slow BOOLEAN,
  time_status TEXT,
  recommendation TEXT,
  time_by_difficulty JSONB
) AS $$
DECLARE
  v_avg_time INTEGER;
  v_total_time INTEGER;
  v_rushing BOOLEAN;
  v_too_slow BOOLEAN;
  v_status TEXT;
  v_rec TEXT;
  v_by_diff JSONB;
BEGIN
  -- Calculate average time
  SELECT 
    COALESCE(AVG(time_taken_seconds), 0)::INTEGER,
    COALESCE(SUM(time_taken_seconds) / 60, 0)::INTEGER
  INTO v_avg_time, v_total_time
  FROM public.question_attempts
  WHERE user_id = p_user_id
    AND created_at >= NOW() - (p_days || ' days')::INTERVAL;
  
  -- Determine time status (AC 5 thresholds)
  v_rushing := v_avg_time < 60;
  v_too_slow := v_avg_time > 180;
  
  IF v_rushing THEN
    v_status := 'rushing';
    v_rec := 'You''re answering too quickly (avg <60s). Take more time to read questions carefully.';
  ELSIF v_too_slow THEN
    v_status := 'too_slow';
    v_rec := 'You''re taking too long (avg >3 min). Practice more to improve speed.';
  ELSE
    v_status := 'optimal';
    v_rec := 'Your timing is good! Keep up the balanced approach.';
  END IF;
  
  -- Time by difficulty
  SELECT jsonb_object_agg(diff, avg_t)
  INTO v_by_diff
  FROM (
    SELECT 
      difficulty_at_attempt as diff,
      ROUND(AVG(time_taken_seconds))::INTEGER as avg_t
    FROM public.question_attempts
    WHERE user_id = p_user_id
      AND created_at >= NOW() - (p_days || ' days')::INTERVAL
    GROUP BY difficulty_at_attempt
  ) t;
  
  RETURN QUERY SELECT
    v_avg_time,
    v_total_time,
    v_rushing,
    v_too_slow,
    v_status,
    v_rec,
    COALESCE(v_by_diff, '{}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- AC 7 & 8: WEAK AND STRONG TOPICS
-- ============================================

CREATE OR REPLACE FUNCTION get_topic_analysis(
  p_user_id UUID,
  p_min_attempts INTEGER DEFAULT 3
)
RETURNS TABLE (
  weak_topics JSONB,
  strong_topics JSONB,
  improving_topics JSONB,
  declining_topics JSONB
) AS $$
DECLARE
  v_weak JSONB;
  v_strong JSONB;
BEGIN
  -- Get weak topics (<50% accuracy with min attempts)
  SELECT jsonb_agg(jsonb_build_object(
    'topic', subject,
    'accuracy', accuracy,
    'attempts', total_attempts,
    'recommendation', 'Practice ' || (10 - total_attempts) || ' more ' || subject || ' questions this week'
  ))
  INTO v_weak
  FROM get_subject_analytics(p_user_id, 30)
  WHERE accuracy < 50 AND total_attempts >= p_min_attempts;
  
  -- Get strong topics (>80% accuracy)
  SELECT jsonb_agg(jsonb_build_object(
    'topic', subject,
    'accuracy', accuracy,
    'attempts', total_attempts,
    'recommendation', 'Move to harder ' || subject || ' questions'
  ))
  INTO v_strong
  FROM get_subject_analytics(p_user_id, 30)
  WHERE accuracy >= 80 AND total_attempts >= p_min_attempts;
  
  RETURN QUERY SELECT
    COALESCE(v_weak, '[]'::jsonb),
    COALESCE(v_strong, '[]'::jsonb),
    '[]'::jsonb,
    '[]'::jsonb;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- AC 9: PYQ COVERAGE
-- ============================================

CREATE OR REPLACE FUNCTION get_pyq_coverage(p_user_id UUID)
RETURNS TABLE (
  total_pyqs INTEGER,
  attempted_pyqs INTEGER,
  coverage_percent DECIMAL(5,2),
  by_year JSONB,
  by_paper JSONB
) AS $$
DECLARE
  v_total INTEGER;
  v_attempted INTEGER;
  v_by_year JSONB;
  v_by_paper JSONB;
BEGIN
  -- Get total PYQs
  SELECT COUNT(*) INTO v_total FROM public.pyq_questions;
  
  -- Get attempted PYQs
  SELECT COUNT(DISTINCT question_id) INTO v_attempted
  FROM public.question_attempts
  WHERE user_id = p_user_id AND question_type = 'pyq';
  
  -- Coverage by year
  SELECT jsonb_object_agg(year, coverage)
  INTO v_by_year
  FROM (
    SELECT 
      pq.year,
      jsonb_build_object(
        'total', COUNT(pq.id),
        'attempted', COUNT(DISTINCT qa.question_id),
        'percent', ROUND((COUNT(DISTINCT qa.question_id)::DECIMAL / NULLIF(COUNT(pq.id), 0)) * 100, 1)
      ) as coverage
    FROM public.pyq_questions pq
    LEFT JOIN public.question_attempts qa ON qa.question_id = pq.id AND qa.user_id = p_user_id
    GROUP BY pq.year
    ORDER BY pq.year DESC
  ) t;
  
  -- Coverage by paper type
  SELECT jsonb_object_agg(paper, coverage)
  INTO v_by_paper
  FROM (
    SELECT 
      COALESCE(pq.paper, 'Unknown') as paper,
      jsonb_build_object(
        'total', COUNT(pq.id),
        'attempted', COUNT(DISTINCT qa.question_id),
        'percent', ROUND((COUNT(DISTINCT qa.question_id)::DECIMAL / NULLIF(COUNT(pq.id), 0)) * 100, 1)
      ) as coverage
    FROM public.pyq_questions pq
    LEFT JOIN public.question_attempts qa ON qa.question_id = pq.id AND qa.user_id = p_user_id
    GROUP BY pq.paper
  ) t;
  
  RETURN QUERY SELECT
    v_total,
    v_attempted,
    CASE WHEN v_total > 0 THEN ROUND((v_attempted::DECIMAL / v_total) * 100, 2) ELSE 0 END,
    COALESCE(v_by_year, '{}'::jsonb),
    COALESCE(v_by_paper, '{}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- AC 10: AI INSIGHTS DATA
-- ============================================

CREATE OR REPLACE FUNCTION get_ai_insights_data(p_user_id UUID)
RETURNS TABLE (
  insight_type TEXT,
  priority INTEGER,
  data JSONB
) AS $$
BEGIN
  -- Strong subject insight
  RETURN QUERY
  SELECT 'strong_subject'::TEXT, 1, jsonb_build_object(
    'subject', subject,
    'accuracy', accuracy,
    'message', 'You''re strong in ' || subject || ' (' || accuracy || '% accuracy). Consider tackling harder questions.'
  )
  FROM get_subject_analytics(p_user_id, 30)
  WHERE accuracy >= 80 AND total_attempts >= 5
  ORDER BY accuracy DESC
  LIMIT 1;
  
  -- Weak subject insight
  RETURN QUERY
  SELECT 'weak_subject'::TEXT, 2, jsonb_build_object(
    'subject', subject,
    'accuracy', accuracy,
    'message', subject || ' needs attention (' || accuracy || '% accuracy). Practice ' || (20 - total_attempts) || ' more MCQs this week.'
  )
  FROM get_subject_analytics(p_user_id, 30)
  WHERE accuracy < 50 AND total_attempts >= 3
  ORDER BY accuracy ASC
  LIMIT 1;
  
  -- Time insight
  RETURN QUERY
  SELECT 'time_analysis'::TEXT, 3, jsonb_build_object(
    'avg_time', avg_time_per_question,
    'status', time_status,
    'message', recommendation
  )
  FROM get_time_analysis(p_user_id, 30);
  
  -- Streak insight
  RETURN QUERY
  SELECT 'streak'::TEXT, 4, jsonb_build_object(
    'current_streak', COALESCE((
      SELECT COUNT(DISTINCT DATE(created_at))
      FROM public.question_attempts
      WHERE user_id = p_user_id
        AND created_at >= NOW() - INTERVAL '30 days'
    ), 0),
    'message', CASE 
      WHEN (SELECT COUNT(DISTINCT DATE(created_at)) FROM public.question_attempts WHERE user_id = p_user_id AND created_at >= NOW() - INTERVAL '7 days') >= 7
      THEN 'Amazing! You''ve practiced every day this week. Keep the momentum!'
      ELSE 'Try to practice daily to build consistency.'
    END
  );
  
  -- PYQ coverage insight
  RETURN QUERY
  SELECT 'pyq_coverage'::TEXT, 5, jsonb_build_object(
    'coverage_percent', coverage_percent,
    'message', CASE
      WHEN coverage_percent < 10 THEN 'You''ve only attempted ' || coverage_percent || '% of PYQs. Start with recent years!'
      WHEN coverage_percent < 50 THEN 'Good progress! ' || coverage_percent || '% PYQs covered. Keep going!'
      ELSE 'Excellent! You''ve covered ' || coverage_percent || '% of all PYQs.'
    END
  )
  FROM get_pyq_coverage(p_user_id);
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- COMPREHENSIVE ANALYTICS FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION get_complete_analytics(
  p_user_id UUID,
  p_days INTEGER DEFAULT 30
)
RETURNS TABLE (
  overall_stats JSONB,
  subject_breakdown JSONB,
  difficulty_breakdown JSONB,
  time_analysis JSONB,
  topic_analysis JSONB,
  pyq_coverage JSONB,
  daily_trend JSONB,
  ai_insights JSONB
) AS $$
DECLARE
  v_overall JSONB;
  v_subjects JSONB;
  v_difficulty JSONB;
  v_time JSONB;
  v_topics JSONB;
  v_pyq JSONB;
  v_trend JSONB;
  v_insights JSONB;
BEGIN
  -- Overall stats
  SELECT jsonb_build_object(
    'total_attempts', COUNT(*),
    'correct_attempts', COUNT(*) FILTER (WHERE is_correct),
    'accuracy', CASE WHEN COUNT(*) > 0 
      THEN ROUND((COUNT(*) FILTER (WHERE is_correct)::DECIMAL / COUNT(*)) * 100, 1)
      ELSE 0 END,
    'avg_time', COALESCE(AVG(time_taken_seconds), 0)::INTEGER
  )
  INTO v_overall
  FROM public.question_attempts
  WHERE user_id = p_user_id
    AND created_at >= NOW() - (p_days || ' days')::INTERVAL;
  
  -- Subject breakdown
  SELECT jsonb_agg(jsonb_build_object(
    'subject', subject,
    'attempts', total_attempts,
    'correct', correct_attempts,
    'accuracy', accuracy,
    'avg_time', avg_time_seconds
  ))
  INTO v_subjects
  FROM get_subject_analytics(p_user_id, p_days);
  
  -- Difficulty breakdown
  SELECT jsonb_agg(jsonb_build_object(
    'difficulty', difficulty_level,
    'attempts', total_attempts,
    'correct', correct_attempts,
    'accuracy', success_rate,
    'avg_time', avg_time_seconds
  ))
  INTO v_difficulty
  FROM public.user_difficulty_stats
  WHERE user_id = p_user_id;
  
  -- Time analysis
  SELECT jsonb_build_object(
    'avg_time', avg_time_per_question,
    'total_minutes', total_practice_time_minutes,
    'is_rushing', is_rushing,
    'is_too_slow', is_too_slow,
    'status', time_status,
    'recommendation', recommendation,
    'by_difficulty', time_by_difficulty
  )
  INTO v_time
  FROM get_time_analysis(p_user_id, p_days);
  
  -- Topic analysis
  SELECT jsonb_build_object(
    'weak', weak_topics,
    'strong', strong_topics
  )
  INTO v_topics
  FROM get_topic_analysis(p_user_id);
  
  -- PYQ coverage
  SELECT jsonb_build_object(
    'total', total_pyqs,
    'attempted', attempted_pyqs,
    'percent', coverage_percent,
    'by_year', by_year,
    'by_paper', by_paper
  )
  INTO v_pyq
  FROM get_pyq_coverage(p_user_id);
  
  -- Daily trend
  SELECT jsonb_agg(jsonb_build_object(
    'date', d,
    'attempts', attempts,
    'correct', correct,
    'accuracy', CASE WHEN attempts > 0 THEN ROUND((correct::DECIMAL / attempts) * 100, 1) ELSE 0 END
  ) ORDER BY d)
  INTO v_trend
  FROM (
    SELECT 
      DATE(created_at) as d,
      COUNT(*) as attempts,
      COUNT(*) FILTER (WHERE is_correct) as correct
    FROM public.question_attempts
    WHERE user_id = p_user_id
      AND created_at >= NOW() - (p_days || ' days')::INTERVAL
    GROUP BY DATE(created_at)
  ) daily;
  
  -- AI insights
  SELECT jsonb_agg(jsonb_build_object(
    'type', insight_type,
    'priority', priority,
    'data', data
  ) ORDER BY priority)
  INTO v_insights
  FROM get_ai_insights_data(p_user_id);
  
  RETURN QUERY SELECT
    COALESCE(v_overall, '{}'::jsonb),
    COALESCE(v_subjects, '[]'::jsonb),
    COALESCE(v_difficulty, '[]'::jsonb),
    COALESCE(v_time, '{}'::jsonb),
    COALESCE(v_topics, '{}'::jsonb),
    COALESCE(v_pyq, '{}'::jsonb),
    COALESCE(v_trend, '[]'::jsonb),
    COALESCE(v_insights, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- Comments
COMMENT ON FUNCTION get_subject_analytics IS 'Story 8.10 AC 3: Subject-wise performance breakdown';
COMMENT ON FUNCTION get_time_analysis IS 'Story 8.10 AC 5: Time analysis with rushing/slow detection';
COMMENT ON FUNCTION get_topic_analysis IS 'Story 8.10 AC 7-8: Weak and strong topic identification';
COMMENT ON FUNCTION get_pyq_coverage IS 'Story 8.10 AC 9: PYQ coverage by year and paper';
COMMENT ON FUNCTION get_ai_insights_data IS 'Story 8.10 AC 10: AI-powered personalized insights';
COMMENT ON FUNCTION get_complete_analytics IS 'Story 8.10: Comprehensive analytics dashboard data';

