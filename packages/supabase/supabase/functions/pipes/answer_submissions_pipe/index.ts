/**
 * Answer Submissions Pipeline
 *
 * Handles answer writing practice:
 * - Question selection (daily, topic-based, PYQ)
 * - Answer submission with timed mode
 * - Auto-save drafts
 * - Entitlement checks for evaluations
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from '@supabase/supabase-js';
import { corsHeaders } from '../_shared/cors.ts';

interface AnswerRequest {
  action: 'get_questions' | 'submit' | 'get_submission' | 'list_submissions' | 'get_daily_questions';
  question_id?: string;
  submission_id?: string;
  user_id?: string;
  // Submit params
  answer_text?: string;
  time_taken_seconds?: number;
  // List params
  limit?: number;
  offset?: number;
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
    const request = await req.json() as AnswerRequest;
    const { action, question_id, submission_id, user_id: requested_user_id, answer_text, time_taken_seconds, limit = 10, offset = 0 } = request;

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    const userId = requested_user_id || req.headers.get('x-user-id');

    if (!userId) {
      return new Response(
        JSON.stringify({ error: 'Authentication required' }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 401,
        }
      );
    }

    switch (action) {
      case 'get_daily_questions':
        return await handleGetDailyQuestions(supabaseAdmin);

      case 'get_questions':
        return await handleGetQuestions(supabaseAdmin, request);

      case 'submit':
        return await handleSubmit(supabaseAdmin, userId, {
          question_id: question_id!,
          answer_text: answer_text!,
          time_taken_seconds: time_taken_seconds || 0,
        });

      case 'get_submission':
        return await handleGetSubmission(supabaseAdmin, submission_id!);

      case 'list_submissions':
        return await handleListSubmissions(supabaseAdmin, userId, { limit, offset });

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
 * Get daily questions (5 questions, 1 per GS paper)
 */
async function handleGetDailyQuestions(supabase: any): Promise<Response> {
  const today = new Date().toISOString().split('T')[0];

  // Check if daily questions exist for today
  const { data: existingQuestions } = await supabase
    .from('daily_questions')
    .select('*')
    .eq('date', today)
    .order('gs_paper');

  if (existingQuestions && existingQuestions.length >= 5) {
    return new Response(
      JSON.stringify({
        success: true,
        data: existingQuestions,
        date: today,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }

  // Generate new daily questions (placeholder - in production, use AI or curated bank)
  const gsPapers = ['GS Paper I', 'GS Paper II', 'GS Paper III', 'GS Paper IV', 'CSAT'];
  const newQuestions: any[] = [];

  for (let i = 0; i < 5; i++) {
    const { data: question } = await supabase
      .from('practice_questions')
      .select('*')
      .eq('gs_paper', gsPapers[i])
      .eq('question_type', 'answer')
      .order('created_at', { ascending: false })
      .limit(1)
      .single();

    if (question) {
      const { data: dailyQuestion } = await supabase
        .from('daily_questions')
        .insert({
          question_id: question.id,
          question_text: question.question_text,
          gs_paper: gsPapers[i],
          word_limit: question.word_limit || 200,
          time_limit_minutes: question.time_limit_minutes || 12,
          difficulty: question.difficulty || 'medium',
          syllabus_topic: question.syllabus_topic,
          date: today,
        })
        .select()
        .single();
      if (dailyQuestion) newQuestions.push(dailyQuestion);
    }
  }

  return new Response(
    JSON.stringify({
      success: true,
      data: newQuestions.length > 0 ? newQuestions : existingQuestions || [],
      date: today,
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}

/**
 * Get questions by filter
 */
async function handleGetQuestions(supabase: any, params: any): Promise<Response> {
  const { gs_paper, topic, difficulty, question_type, limit = 20 } = params;

  let query = supabase.from('practice_questions').select('*').eq('question_type', 'answer');

  if (gs_paper) query = query.eq('gs_paper', gs_paper);
  if (topic) query = query.ilike('syllabus_topic', `%${topic}%`);
  if (difficulty) query = query.eq('difficulty', difficulty);
  if (question_type) query = query.eq('question_type', question_type);

  const { data: questions, error } = await query.order('created_at', { ascending: false }).limit(limit);

  if (error) {
    throw new Error(`Failed to fetch questions: ${error.message}`);
  }

  return new Response(
    JSON.stringify({
      success: true,
      data: questions,
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}

/**
 * Submit an answer for evaluation
 */
async function handleSubmit(
  supabase: any,
  userId: string,
  params: { question_id: string; answer_text: string; time_taken_seconds: number }
): Promise<Response> {
  const { question_id, answer_text, time_taken_seconds } = params;

  // Validate
  if (!question_id || !answer_text) {
    return new Response(
      JSON.stringify({ error: 'Question ID and answer text are required' }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    );
  }

  // Check user's subscription for evaluation entitlement
  const { data: subscription } = await supabase
    .from('subscriptions')
    .select('status, trial_expires_at, evaluation_credits')
    .eq('user_id', userId)
    .single();

  const isPro =
    subscription?.status === 'active' ||
    (subscription?.status === 'trial' &&
      subscription?.trial_expires_at &&
      new Date(subscription.trial_expires_at) > new Date());

  // Check evaluation credits
  const today = new Date().toISOString().split('T')[0];
  const { count: todayEvaluations } = await supabase
    .from('answer_submissions')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', userId)
    .gte('submitted_at', today)
    .not('evaluation_status', '=', 'pending');

  let evaluationCredits = subscription?.evaluation_credits ?? 0;
  let evaluationEnabled = isPro || evaluationCredits > 0 || (!isPro && todayEvaluations < 2);

  if (!evaluationEnabled) {
    return new Response(
      JSON.stringify({
        success: false,
        error: 'EVALUATION_LIMIT_REACHED',
        message: isPro ? 'No evaluation credits remaining' : 'Daily limit of 2 free evaluations reached',
        upgrade_required: !isPro,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 403,
      }
    );
  }

  // Get question details
  const { data: question } = await supabase
    .from('practice_questions')
    .select('*')
    .eq('id', question_id)
    .single();

  if (!question) {
    return new Response(
      JSON.stringify({ error: 'Question not found' }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 404,
      }
    );
  }

  // Calculate word count
  const wordCount = answer_text.trim().split(/\s+/).filter(Boolean).length;

  // Create submission
  const { data: submission, error } = await supabase
    .from('answer_submissions')
    .insert({
      user_id: userId,
      question_id,
      question_text: question.question_text,
      gs_paper: question.gs_paper,
      syllabus_topic: question.syllabus_topic,
      answer_text,
      word_count: wordCount,
      time_taken_seconds,
      word_limit: question.word_limit,
      evaluation_enabled: evaluationEnabled,
      evaluation_status: evaluationEnabled ? 'pending' : 'disabled',
      submitted_at: new Date().toISOString(),
    })
    .select()
    .single();

  if (error) {
    throw new Error(`Failed to submit answer: ${error.message}`);
  }

  // Trigger async evaluation if enabled
  if (evaluationEnabled) {
    // Deduct credit for Pro users
    if (isPro && evaluationCredits > 0) {
      await supabase
        .from('subscriptions')
        .update({ evaluation_credits: evaluationCredits - 1 })
        .eq('user_id', userId);

      // Fire-and-forget evaluation
      evaluateAnswerAsync(submission.id, question, answer_text);
    } else {
      // Free user - use daily free evaluation
      evaluateAnswerAsync(submission.id, question, answer_text);
    }
  }

  return new Response(
    JSON.stringify({
      success: true,
      data: {
        submission_id: submission.id,
        word_count: wordCount,
        time_taken_seconds,
        evaluation_enabled: evaluationEnabled,
        evaluation_credits_remaining: isPro ? evaluationCredits - 1 : 2 - (todayEvaluations + 1),
      },
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}

/**
 * Async evaluation helper
 */
async function evaluateAnswerAsync(submissionId: string, question: any, answerText: string) {
  // In production, this would call the evaluate_answer_pipe
  try {
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    // Create a placeholder - actual evaluation happens via webhook or queue
    await supabaseAdmin
      .from('answer_evaluations')
      .insert({
        submission_id: submissionId,
        status: 'processing',
        created_at: new Date().toISOString(),
      });

    // Trigger evaluation function
    await fetch(`${Deno.env.get('SUPABASE_URL')}/functions/v1/evaluate_answer_pipe`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
      },
      body: JSON.stringify({
        submission_id: submissionId,
        question_text: question.question_text,
        answer_text: answerText,
        syllabus_topic: question.syllabus_topic,
        gs_paper: question.gs_paper,
      }),
    });
  } catch (error) {
    console.error('Failed to trigger evaluation:', error);
  }
}

/**
 * Get a single submission with evaluation
 */
async function handleGetSubmission(supabase: any, submissionId: string): Promise<Response> {
  const { data: submission, error } = await supabase
    .from('answer_submissions')
    .select('*')
    .eq('id', submissionId)
    .single();

  if (error || !submission) {
    return new Response(
      JSON.stringify({ error: 'Submission not found' }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 404,
      }
    );
  }

  // Get evaluation if exists
  const { data: evaluation } = await supabase
    .from('answer_evaluations')
    .select('*')
    .eq('submission_id', submissionId)
    .single();

  return new Response(
    JSON.stringify({
      success: true,
      data: {
        ...submission,
        evaluation,
      },
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}

/**
 * List user's submissions
 */
async function handleListSubmissions(
  supabase: any,
  userId: string,
  params: { limit: number; offset: number }
): Promise<Response> {
  const { limit, offset } = params;

  const { data: submissions, error, count } = await supabase
    .from('answer_submissions')
    .select('*, evaluation:answer_evaluations(*)', { count: 'exact' })
    .eq('user_id', userId)
    .order('submitted_at', { ascending: false })
    .range(offset, offset + limit - 1);

  if (error) {
    throw new Error(`Failed to fetch submissions: ${error.message}`);
  }

  return new Response(
    JSON.stringify({
      success: true,
      data: submissions,
      pagination: {
        total: count || 0,
        limit,
        offset,
        has_more: (offset + limit) < (count || 0),
      },
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}
