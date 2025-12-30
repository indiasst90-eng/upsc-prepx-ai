/**
 * Progress Dashboard Pipeline
 *
 * Features:
 * - Study time analytics
 * - Topic coverage tracking
 * - Weak/strong areas identification
 * - Confidence score calculation
 * - Personalized recommendations
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from '@supabase/supabase-js';
import { corsHeaders } from '../_shared/cors.ts';

interface ProgressRequest {
  user_id?: string;
  period?: '7d' | '30d' | '90d' | '1y';
  action: 'get_dashboard' | 'get_analytics' | 'get_weak_areas' | 'get_strengths' | 'get_recommendations';
}

interface ProgressResponse {
  success: boolean;
  data?: any;
  error?: string;
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  const startTime = Date.now();

  try {
    const request = await req.json() as ProgressRequest;
    const { user_id: requested_user_id, period = '30d', action } = request;

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    const userId = requested_user_id || req.headers.get('x-user-id');

    if (!userId) {
      return new Response(
        JSON.stringify({ error: 'User authentication required' }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 401,
        }
      );
    }

    // Calculate date range
    const daysMap: Record<string, number> = {
      '7d': 7,
      '30d': 30,
      '90d': 90,
      '1y': 365,
    };
    const days = daysMap[period] || 30;
    const startDate = new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString();

    switch (action) {
      case 'get_dashboard':
        return await handleGetDashboard(supabaseAdmin, userId, startDate, days);

      case 'get_analytics':
        return await handleGetAnalytics(supabaseAdmin, userId, startDate);

      case 'get_weak_areas':
        return await handleGetWeakAreas(supabaseAdmin, userId);

      case 'get_strengths':
        return await handleGetStrengths(supabaseAdmin, userId);

      case 'get_recommendations':
        return await handleGetRecommendations(supabaseAdmin, userId);

      default:
        return new Response(
          JSON.stringify({ error: 'Invalid action' }),
          {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 400,
          }
        );
    }
  } catch (error) {
    return new Response(
      JSON.stringify({
        success: false,
        error: (error as Error).message,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    );
  }
});

/**
 * Get complete dashboard data
 */
async function handleGetDashboard(
  supabase: any,
  userId: string,
  startDate: string,
  days: number
): Promise<Response> {
  // Get subscription status
  const { data: subscription } = await supabase
    .from('subscriptions')
    .select('status, trial_expires_at')
    .eq('user_id', userId)
    .single();

  const isPro =
    subscription?.status === 'active' ||
    (subscription?.status === 'trial' &&
      subscription?.trial_expires_at &&
      new Date(subscription.trial_expires_at) > new Date());

  // Get user profile
  const { data: profile } = await supabase
    .from('user_profiles')
    .select('*')
    .eq('id', userId)
    .single();

  // Study time analytics
  const { data: studySessions } = await supabase
    .from('study_sessions')
    .select('*')
    .eq('user_id', userId)
    .gte('created_at', startDate);

  const totalStudyTime = studySessions?.reduce((sum: number, s: any) => sum + (s.duration_minutes || 0), 0) || 0;
  const avgDailyStudy = Math.round(totalStudyTime / days);
  const sessionsCount = studySessions?.length || 0;

  // Topics covered
  const { count: topicsCovered } = await supabase
    .from('syllabus_progress')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', userId)
    .eq('status', 'completed');

  const { count: totalTopics } = await supabase
    .from('syllabus_nodes')
    .select('*', { count: 'exact', head: true });

  // Bookmarks stats
  const { data: bookmarks } = await supabase
    .from('user_bookmarks')
    .select('id, memory_strength, category')
    .eq('user_id', userId);

  const bookmarksCount = bookmarks?.length || 0;
  const avgMemoryStrength =
    bookmarks?.length > 0
      ? bookmarks.reduce((sum: number, b: any) => sum + (b.memory_strength || 0), 0) / bookmarks.length
      : 0;

  // Revision progress
  const { data: revisionSchedules } = await supabase
    .from('revision_schedules')
    .select('*')
    .eq('user_id', userId)
    .gte('created_at', startDate);

  const revisionsCompleted = revisionSchedules?.filter((r: any) => r.status === 'completed').length || 0;
  const revisionsPending = revisionSchedules?.filter((r: any) => r.status === 'pending').length || 0;

  // Quiz scores
  const { data: quizAttempts } = await supabase
    .from('quiz_attempts')
    .select('score, topic')
    .eq('user_id', userId)
    .gte('created_at', startDate);

  const avgQuizScore =
    quizAttempts?.length > 0
      ? quizAttempts.reduce((sum: number, q: any) => sum + (q.score || 0), 0) / quizAttempts.length
      : 0;

  // Videos watched
  const { count: videosWatched } = await supabase
    .from('video_views')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', userId)
    .gte('created_at', startDate);

  // Daily study pattern (last 7 days)
  const last7Days = Array.from({ length: 7 }, (_, i) => {
    const date = new Date(Date.now() - i * 24 * 60 * 60 * 1000);
    return date.toISOString().split('T')[0];
  }).reverse();

  const dailyStudyPattern = last7Days.map((date) => {
    const daySessions = studySessions?.filter((s: any) => s.created_at.split('T')[0] === date) || [];
    return {
      date,
      totalMinutes: daySessions.reduce((sum: number, s: any) => sum + (s.duration_minutes || 0), 0),
      sessions: daySessions.length,
    };
  });

  // Category-wise progress
  const categoryProgress: Record<string, { covered: number; total: number; avgConfidence: number }> = {};
  if (bookmarks) {
    for (const bookmark of bookmarks) {
      const cat = bookmark.category || 'Uncategorized';
      if (!categoryProgress[cat]) {
        categoryProgress[cat] = { covered: 0, total: 0, avgConfidence: 0, count: 0 };
      }
      categoryProgress[cat].avgConfidence += bookmark.memory_strength;
      categoryProgress[cat].count++;
    }
    for (const cat of Object.keys(categoryProgress)) {
      categoryProgress[cat].avgConfidence =
        categoryProgress[cat].count > 0
          ? categoryProgress[cat].avgConfidence / categoryProgress[cat].count
          : 0;
    }
  }

  // Calculate overall progress percentage
  const progressPercent = totalTopics
    ? Math.round(((topicsCovered || 0) / totalTopics) * 100)
    : 0;

  return new Response(
    JSON.stringify({
      success: true,
      data: {
        overview: {
          isPro,
          totalStudyTime,
          avgDailyStudy,
          sessionsCount,
          topicsCovered: topicsCovered || 0,
          totalTopics: totalTopics || 0,
          progressPercent,
          bookmarksCount,
          avgMemoryStrength,
          revisionsCompleted,
          revisionsPending,
          avgQuizScore: Math.round(avgQuizScore),
          videosWatched: videosWatched || 0,
        },
        dailyStudyPattern,
        categoryProgress: Object.entries(categoryProgress).map(([category, data]) => ({
          category,
          ...data,
          avgConfidence: Math.round(data.avgConfidence * 100),
        })),
        weeklyGoal: {
          targetMinutes: 420, // 7 hours
          currentMinutes: totalStudyTime,
          percentComplete: Math.min(Math.round((totalStudyTime / 420) * 100), 100),
        },
        streak: {
          current: profile?.current_streak || 0,
          longest: profile?.longest_streak || 0,
          lastActiveDate: profile?.last_active_date,
        },
      },
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}

/**
 * Get detailed analytics
 */
async function handleGetAnalytics(supabase: any, userId: string, startDate: string): Promise<Response> {
  // Get all study sessions with breakdown
  const { data: sessions } = await supabase
    .from('study_sessions')
    .select('*')
    .eq('user_id', userId)
    .gte('created_at', startDate)
    .order('created_at', { ascending: false });

  // Get quiz performance by topic
  const { data: quizAttempts } = await supabase
    .from('quiz_attempts')
    .select('score, topic, created_at')
    .eq('user_id', userId)
    .gte('created_at', startDate);

  // Group quiz scores by topic
  const quizByTopic: Record<string, { scores: number[]; attempts: number }> = {};
  for (const attempt of quizAttempts || []) {
    if (!quizByTopic[attempt.topic]) {
      quizByTopic[attempt.topic] = { scores: [], attempts: 0 };
    }
    quizByTopic[attempt.topic].scores.push(attempt.score);
    quizByTopic[attempt.topic].attempts++;
  }

  const topicPerformance = Object.entries(quizByTopic).map(([topic, data]) => ({
    topic,
    avgScore: Math.round(data.scores.reduce((a, b) => a + b, 0) / data.scores.length),
    attempts: data.attempts,
    trend: calculateTrend(data.scores),
  }));

  // Time distribution by hour
  const hourDistribution = Array.from({ length: 24 }, (_, hour) => ({
    hour,
    totalMinutes: 0,
    sessions: 0,
  }));

  for (const session of sessions || []) {
    const hour = new Date(session.created_at).getHours();
    hourDistribution[hour].totalMinutes += session.duration_minutes || 0;
    hourDistribution[hour].sessions++;
  }

  return new Response(
    JSON.stringify({
      success: true,
      data: {
        sessions,
        topicPerformance,
        hourDistribution: hourDistribution.filter((h) => h.sessions > 0),
        summary: {
          totalSessions: sessions?.length || 0,
          totalMinutes: sessions?.reduce((sum: number, s: any) => sum + (s.duration_minutes || 0), 0) || 0,
          avgSessionLength:
            sessions?.length > 0
              ? Math.round(
                  sessions.reduce((sum: number, s: any) => sum + (s.duration_minutes || 0), 0) / sessions.length
                )
              : 0,
        },
      },
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}

/**
 * Get weak areas
 */
async function handleGetWeakAreas(supabase: any, userId: string): Promise<Response> {
  // Get confidence scores below threshold
  const { data: lowConfidence } = await supabase
    .from('confidence_scores')
    .select('*')
    .eq('user_id', userId)
    .lt('confidence_score', 40)
    .order('confidence_score', { ascending: true })
    .limit(10);

  // Get bookmarks with low memory strength
  const { data: weakBookmarks } = await supabase
    .from('user_bookmarks')
    .select('*')
    .eq('user_id', userId)
    .lt('memory_strength', 0.4)
    .order('memory_strength', { ascending: true })
    .limit(10);

  // Get quiz topics with low scores
  const { data: quizAttempts } = await supabase
    .from('quiz_attempts')
    .select('topic, score')
    .eq('user_id', userId);

  const topicScores: Record<string, { total: number; count: number }> = {};
  for (const attempt of quizAttempts || []) {
    if (!topicScores[attempt.topic]) {
      topicScores[attempt.topic] = { total: 0, count: 0 };
    }
    topicScores[attempt.topic].total += attempt.score;
    topicScores[attempt.topic].count++;
  }

  const weakTopics = Object.entries(topicScores)
    .map(([topic, data]) => ({
      topic,
      avgScore: Math.round(data.total / data.count),
      attempts: data.count,
    }))
    .filter((t) => t.avgScore < 60)
    .sort((a, b) => a.avgScore - b.avgScore)
    .slice(0, 10);

  return new Response(
    JSON.stringify({
      success: true,
      data: {
        lowConfidenceTopics: lowConfidence || [],
        weakBookmarks: weakBookmarks || [],
        weakQuizTopics: weakTopics,
        count: (lowConfidence?.length || 0) + (weakBookmarks?.length || 0) + weakTopics.length,
      },
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}

/**
 * Get strength areas
 */
async function handleGetStrengths(supabase: any, userId: string): Promise<Response> {
  // Get high confidence scores
  const { data: highConfidence } = await supabase
    .from('confidence_scores')
    .select('*')
    .eq('user_id', userId)
    .gte('confidence_score', 70)
    .order('confidence_score', { ascending: false })
    .limit(10);

  // Get bookmarks with high memory strength
  const { data: strongBookmarks } = await supabase
    .from('user_bookmarks')
    .select('*')
    .eq('user_id', userId)
    .gte('memory_strength', 0.7)
    .order('memory_strength', { ascending: false })
    .limit(10);

  // Get quiz topics with high scores
  const { data: quizAttempts } = await supabase
    .from('quiz_attempts')
    .select('topic, score')
    .eq('user_id', userId);

  const topicScores: Record<string, { total: number; count: number }> = {};
  for (const attempt of quizAttempts || []) {
    if (!topicScores[attempt.topic]) {
      topicScores[attempt.topic] = { total: 0, count: 0 };
    }
    topicScores[attempt.topic].total += attempt.score;
    topicScores[attempt.topic].count++;
  }

  const strongTopics = Object.entries(topicScores)
    .map(([topic, data]) => ({
      topic,
      avgScore: Math.round(data.total / data.count),
      attempts: data.count,
    }))
    .filter((t) => t.avgScore >= 80)
    .sort((a, b) => b.avgScore - a.avgScore)
    .slice(0, 10);

  return new Response(
    JSON.stringify({
      success: true,
      data: {
        highConfidenceTopics: highConfidence || [],
        strongBookmarks: strongBookmarks || [],
        strongQuizTopics: strongTopics,
        count: (highConfidence?.length || 0) + (strongBookmarks?.length || 0) + strongTopics.length,
      },
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}

/**
 * Get personalized recommendations
 */
async function handleGetRecommendations(supabase: any, userId: string): Promise<Response> {
  const recommendations: Array<{
    type: string;
    priority: 'high' | 'medium' | 'low';
    title: string;
    description: string;
    action_url?: string;
  }> = [];

  // Get weak areas
  const { data: weakAreas } = await supabase
    .from('confidence_scores')
    .select('*')
    .eq('user_id', userId)
    .lt('confidence_score', 50)
    .order('confidence_score', { ascending: true })
    .limit(3);

  for (const area of weakAreas || []) {
    recommendations.push({
      type: 'improve',
      priority: 'high',
      title: `Improve: ${area.syllabus_node_id}`,
      description: 'Your confidence is low. Review notes and practice questions.',
      action_url: `/dashboard/practice?topic=${area.syllabus_node_id}`,
    });
  }

  // Get pending revisions
  const { data: pendingRevisions } = await supabase
    .from('revision_schedules')
    .select('*')
    .eq('user_id', userId)
    .eq('status', 'pending')
    .lte('scheduled_date', new Date().toISOString().split('T')[0])
    .limit(3);

  if (pendingRevisions && pendingRevisions.length > 0) {
    recommendations.push({
      type: 'revision',
      priority: 'high',
      title: 'Pending Revisions',
      description: `You have ${pendingRevisions.length} concepts scheduled for review today.`,
      action_url: '/dashboard/bookmarks?tab=schedule',
    });
  }

  // Get study streak info
  const { data: profile } = await supabase
    .from('user_profiles')
    .select('current_streak, last_active_date')
    .eq('id', userId)
    .single();

  if (profile && profile.current_streak < 3) {
    recommendations.push({
      type: 'streak',
      priority: 'medium',
      title: 'Build Your Streak',
      description: 'Study for 3+ days in a row to start building momentum.',
      action_url: '/dashboard',
    });
  }

  // Check quiz completion
  const { count: quizCount } = await supabase
    .from('quiz_attempts')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', userId);

  if (quizCount === 0) {
    recommendations.push({
      type: 'practice',
      priority: 'medium',
      title: 'Start Practicing',
      description: 'Take a quiz to assess your knowledge and get personalized recommendations.',
      action_url: '/dashboard/practice',
    });
  }

  // Sort by priority
  const priorityOrder = { high: 0, medium: 1, low: 2 };
  recommendations.sort((a, b) => priorityOrder[a.priority] - priorityOrder[b.priority]);

  return new Response(
    JSON.stringify({
      success: true,
      data: {
        recommendations,
        total: recommendations.length,
      },
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}

/**
 * Calculate trend from scores array
 */
function calculateTrend(scores: number[]): 'up' | 'down' | 'stable' {
  if (scores.length < 2) return 'stable';
  const recent = scores.slice(0, Math.ceil(scores.length / 2));
  const older = scores.slice(Math.ceil(scores.length / 2));
  const recentAvg = recent.reduce((a, b) => a + b, 0) / recent.length;
  const olderAvg = older.reduce((a, b) => a + b, 0) / older.length;
  const diff = recentAvg - olderAvg;
  if (diff > 5) return 'up';
  if (diff < -5) return 'down';
  return 'stable';
}
