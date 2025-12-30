/**
 * Daily Quiz Pipeline
 *
 * Features:
 * - Daily 10-question quiz
 * - Subject-wise randomization
 * - Streak tracking
 * - Performance analytics
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from '@supabase/supabase-js';
import { corsHeaders } from '../_shared/cors.ts';

interface DailyQuizRequest {
  action: 'get_daily' | 'submit' | 'get_result' | 'get_history' | 'get_stats';
  user_id?: string;
  attempt_id?: string;
  // Submit params
  answers?: Array<{ question_id: string; selected_option: number; confidence?: number }>;
  time_taken_seconds?: number;
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  try {
    const request = await req.json() as DailyQuizRequest;
    const {
      action,
      user_id: requested_user_id,
      attempt_id,
      answers,
      time_taken_seconds,
    } = request;

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    const userId = requested_user_id || req.headers.get('x-user-id');

    if (!userId && action !== 'get_daily') {
      return new Response(
        JSON.stringify({ error: 'Authentication required' }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 401,
        }
      );
    }

    switch (action) {
      case 'get_daily':
        return await handleGetDaily(supabaseAdmin);

      case 'submit':
        return await handleSubmit(supabaseAdmin, userId!, { attempt_id!, answers!, time_taken_seconds: time_taken_seconds || 0 });

      case 'get_result':
        return await handleGetResult(supabaseAdmin, attempt_id!);

      case 'get_history':
        return await handleGetHistory(supabaseAdmin, userId!, 20);

      case 'get_stats':
        return await handleGetStats(supabaseAdmin, userId!);

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
 * Get today's daily quiz
 */
async function handleGetDaily(supabase: any): Promise<Response> {
  const today = new Date().toISOString().split('T')[0];

  // Check if daily quiz already exists
  const { data: existingQuiz } = await supabase
    .from('daily_quizzes')
    .select('*')
    .eq('date', today)
    .single();

  if (existingQuiz && existingQuiz.questions_json) {
    // Return cached quiz (without correct answers)
    const questions = existingQuiz.questions_json.map((q: any) => ({
      id: q.id,
      question_text: q.question_text,
      options: q.options,
      gs_paper: q.gs_paper,
      topic: q.topic,
      difficulty: q.difficulty,
    }));

    return new Response(
      JSON.stringify({
        success: true,
        data: {
          quiz_id: existingQuiz.id,
          date: today,
          questions,
          total_questions: questions.length,
        },
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }

  // Generate new daily quiz (10 questions)
  const { data: questions, error } = await supabase
    .from('practice_questions')
    .select('*')
    .eq('question_type', 'mcq')
    .order('created_at', { ascending: false })
    .limit(50);

  if (error || !questions) {
    return new Response(
      JSON.stringify({ error: 'Failed to generate quiz' }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    );
  }

  // Randomly select 10 questions
  const shuffled = questions.sort(() => Math.random() - 0.5);
  const selectedQuestions = shuffled.slice(0, 10).map((q) => ({
    id: q.id,
    question_text: q.question_text,
    options: q.options,
    correct_answer: q.correct_answer,
    explanation: q.explanation,
    gs_paper: q.gs_paper,
    topic: q.syllabus_topic,
    difficulty: q.difficulty,
  }));

  // Save quiz
  const { data: quiz } = await supabase
    .from('daily_quizzes')
    .upsert({
      date: today,
      questions_json: selectedQuestions,
      created_at: new Date().toISOString(),
    })
    .select()
    .single();

  // Return without correct answers
  const publicQuestions = selectedQuestions.map((q) => ({
    id: q.id,
    question_text: q.question_text,
    options: q.options,
    gs_paper: q.gs_paper,
    topic: q.topic,
    difficulty: q.difficulty,
  }));

  return new Response(
    JSON.stringify({
      success: true,
      data: {
        quiz_id: quiz.id,
        date: today,
        questions: publicQuestions,
        total_questions: 10,
      },
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}

/**
 * Submit quiz answers
 */
async function handleSubmit(
  supabase: any,
  userId: string,
  params: { attempt_id: string; answers: any[]; time_taken_seconds: number }
): Promise<Response> {
  const { attempt_id, answers, time_taken_seconds } = params;

  // Get quiz questions
  const { data: quiz } = await supabase
    .from('daily_quizzes')
    .select('*')
    .eq('id', attempt_id)
    .single();

  if (!quiz) {
    return new Response(
      JSON.stringify({ error: 'Quiz not found' }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 404,
      }
    );
  }

  const questions = quiz.questions_json;
  let correctAnswers = 0;
  const results: any[] = [];

  // Grade answers
  for (const answer of answers) {
    const question = questions.find((q: any) => q.id === answer.question_id);
    if (!question) continue;

    const isCorrect = question.correct_answer === answer.selected_option;
    if (isCorrect) correctAnswers++;

    results.push({
      question_id: answer.question_id,
      selected_option: answer.selected_option,
      correct_option: question.correct_answer,
      is_correct: isCorrect,
      explanation: question.explanation,
      confidence: answer.confidence,
    });
  }

  const score = Math.round((correctAnswers / questions.length) * 100);

  // Create attempt record
  const { data: attempt, error } = await supabase
    .from('quiz_attempts')
    .insert({
      user_id: userId,
      quiz_type: 'daily',
      total_questions: questions.length,
      correct_answers: correctAnswers,
      time_taken_seconds,
      avg_confidence: answers.reduce((sum: number, a: any) => sum + (a.confidence || 3), 0) / answers.length,
      started_at: new Date(Date.now() - time_taken_seconds * 1000).toISOString(),
      completed_at: new Date().toISOString(),
    })
    .select()
    .single();

  if (error) {
    throw new Error(`Failed to submit quiz: ${error.message}`);
  }

  // Save individual answers
  for (const result of results) {
    await supabase.from('quiz_answers').insert({
      attempt_id: attempt.id,
      question_id: result.question_id,
      selected_option: result.selected_option,
      is_correct: result.is_correct,
      pre_confidence: result.confidence,
      answered_at: new Date().toISOString(),
    });
  }

  // Update streak
  await updateStreak(supabase, userId);

  return new Response(
    JSON.stringify({
      success: true,
      data: {
        attempt_id: attempt.id,
        score,
        correct_answers: correctAnswers,
        total_questions: questions.length,
        time_taken_seconds,
        results,
      },
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}

/**
 * Get quiz result
 */
async function handleGetResult(supabase: any, attemptId: string): Promise<Response> {
  const { data: attempt, error } = await supabase
    .from('quiz_attempts')
    .select('*')
    .eq('id', attemptId)
    .single();

  if (error || !attempt) {
    return new Response(
      JSON.stringify({ error: 'Attempt not found' }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 404,
      }
    );
  }

  const { data: answers } = await supabase
    .from('quiz_answers')
    .select('*')
    .eq('attempt_id', attemptId);

  return new Response(
    JSON.stringify({
      success: true,
      data: {
        ...attempt,
        answers,
      },
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}

/**
 * Get quiz history
 */
async function handleGetHistory(supabase: any, userId: string, limit: number): Promise<Response> {
  const { data: attempts, error, count } = await supabase
    .from('quiz_attempts')
    .select('*', { count: 'exact' })
    .eq('user_id', userId)
    .eq('quiz_type', 'daily')
    .order('completed_at', { ascending: false })
    .limit(limit);

  if (error) {
    throw new Error(`Failed to fetch history: ${error.message}`);
  }

  // Calculate trends
  const recentScores = attempts?.slice(0, 7).map((a: any) => a.score) || [];
  const avgScore = recentScores.length > 0
    ? Math.round(recentScores.reduce((a: number, b: number) => a + b, 0) / recentScores.length)
    : 0;

  return new Response(
    JSON.stringify({
      success: true,
      data: attempts,
      trends: {
        recent_scores: recentScores,
        avg_score: avgScore,
        improving: recentScores.length >= 2 && recentScores[0] > recentScores[1],
      },
      pagination: {
        total: count || 0,
        limit,
        has_more: (count || 0) > limit,
      },
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}

/**
 * Get user stats
 */
async function handleGetStats(supabase: any, userId: string): Promise<Response> {
  // Get profile
  const { data: profile } = await supabase
    .from('user_profiles')
    .select('current_streak, longest_streak, last_active_date')
    .eq('id', userId)
    .single();

  // Get quiz stats
  const { data: stats } = await supabase
    .from('quiz_attempts')
    .select('score, correct_answers, total_questions, completed_at')
    .eq('user_id', userId)
    .eq('quiz_type', 'daily');

  const totalQuizzes = stats?.length || 0;
  const totalCorrect = stats?.reduce((sum: number, s: any) => sum + s.correct_answers, 0) || 0;
  const totalQuestions = stats?.reduce((sum: number, s: any) => sum + s.total_questions, 0) || 0;
  const avgScore = totalQuizzes > 0
    ? Math.round(stats!.reduce((sum: number, s: any) => sum + s.score, 0) / totalQuizzes)
    : 0;
  const accuracy = totalQuestions > 0
    ? Math.round((totalCorrect / totalQuestions) * 100)
    : 0;

  // Today's quiz status
  const today = new Date().toISOString().split('T')[0];
  const { data: todayAttempt } = await supabase
    .from('quiz_attempts')
    .select('id, score')
    .eq('user_id', userId)
    .gte('completed_at', today)
    .single();

  return new Response(
    JSON.stringify({
      success: true,
      data: {
        streak: {
          current: profile?.current_streak || 0,
          longest: profile?.longest_streak || 0,
          last_active: profile?.last_active_date,
        },
        today_completed: !!todayAttempt,
        today_score: todayAttempt?.score,
        overall: {
          total_quizzes: totalQuizzes,
          avg_score: avgScore,
          accuracy,
          total_correct: totalCorrect,
          total_questions: totalQuestions,
        },
        badges: calculateBadges(profile, stats),
      },
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}

/**
 * Update user streak
 */
async function updateStreak(supabase: any, userId: string) {
  const today = new Date().toISOString().split('T')[0];
  const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString().split('T')[0];

  const { data: profile } = await supabase
    .from('user_profiles')
    .select('*')
    .eq('id', userId)
    .single();

  let newStreak = 1;
  if (profile) {
    if (profile.last_active_date === today) {
      // Already completed today
      return;
    } else if (profile.last_active_date === yesterday) {
      // Consecutive day
      newStreak = (profile.current_streak || 0) + 1;
    }
  }

  await supabase
    .from('user_profiles')
    .upsert({
      id: userId,
      current_streak: newStreak,
      longest_streak: Math.max(newStreak, profile?.longest_streak || 0),
      last_active_date: today,
      updated_at: new Date().toISOString(),
    });
}

/**
 * Calculate badges based on stats
 */
function calculateBadges(profile: any, stats: any[]): any[] {
  const badges = [];
  const totalQuizzes = stats?.length || 0;
  const currentStreak = profile?.current_streak || 0;

  // Streak badges
  if (currentStreak >= 7) badges.push({ id: 'week_streak', name: 'Week Warrior', icon: '🔥', description: '7 day streak' });
  if (currentStreak >= 30) badges.push({ id: 'month_streak', name: 'Monthly Master', icon: '🏆', description: '30 day streak' });

  // Quiz badges
  if (totalQuizzes >= 10) badges.push({ id: 'quiz_10', name: 'Quizzer', icon: '🎯', description: '10 quizzes completed' });
  if (totalQuizzes >= 50) badges.push({ id: 'quiz_50', name: 'Dedicated', icon: '⭐', description: '50 quizzes completed' });
  if (totalQuizzes >= 100) badges.push({ id: 'quiz_100', name: 'Century', icon: '💯', description: '100 quizzes completed' });

  // Score badges
  const avgScore = totalQuizzes > 0
    ? stats!.reduce((sum: number, s: any) => sum + s.score, 0) / totalQuizzes
    : 0;
  if (avgScore >= 80) badges.push({ id: 'high_score', name: 'High Scorer', icon: '🎓', description: '80% average' });
  if (avgScore >= 90) badges.push({ id: 'perfect', name: 'Perfectionist', icon: '👑', description: '90% average' });

  return badges;
}
