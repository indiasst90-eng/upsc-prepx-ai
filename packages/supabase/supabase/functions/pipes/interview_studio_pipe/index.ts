/**
 * Interview Studio Pipe - AI Mock Interviews
 *
 * Generates personalized interview questions based on user's DAF and provides
 * real-time evaluation with structured feedback.
 *
 * Features:
 * - DAF-based question generation (educational background, hobbies, service history)
 * - Current affairs integration
 * - Optional subject deep-dive
 * - Real-time evaluation with rubric scoring
 * - Comprehensive feedback with improvement suggestions
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from '@supabase/supabase-js';
import { corsHeaders } from '../_shared/cors.ts';

interface InterviewRequest {
  session_type?: 'general' | 'daf_based' | 'current_affairs' | 'optional_subject' | 'mock_full';
  difficulty?: 'easy' | 'medium' | 'hard' | 'actual';
  daf_data?: {
    name?: string;
    educational_background?: string[];
    hobbies?: string[];
    work_experience?: string[];
    service_preference?: string;
    home_state?: string;
    optional_subject?: string;
    previous_attempts?: number;
  };
  current_question_index?: number;
  user_response?: string;
  response_duration_seconds?: number;
}

interface Question {
  id: string;
  round: number;
  question_number: number;
  question: string;
  category: string;
  follow_up: string[];
  ideal_points: string[];
  sample_answer?: string;
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST' && req.method !== 'GET') {
    return new Response('Method not allowed', { status: 405 });
  }

  const startTime = Date.now();
  const supabaseAdmin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );

  try {
    // GET: List sessions or get a specific session
    if (req.method === 'GET') {
      const url = new URL(req.url);
      const action = url.searchParams.get('action');
      const sessionId = url.searchParams.get('session_id');

      if (action === 'list_sessions') {
        // Get auth user
        const authHeader = req.headers.get('Authorization');
        if (!authHeader) {
          return new Response(JSON.stringify({ error: 'Unauthorized' }), {
            status: 401,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          });
        }

        const supabase = createClient(
          Deno.env.get('SUPABASE_URL')!,
          authHeader.replace('Bearer ', '')
        );

        const { data: sessions, error } = await supabase
          .from('interview_sessions')
          .select('*')
          .order('created_at', { ascending: false })
          .limit(20);

        if (error) throw error;

        return new Response(JSON.stringify({ success: true, data: sessions }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      if (sessionId) {
        const { data: session } = await supabase
          .from('interview_sessions')
          .select('*')
          .eq('id', sessionId)
          .single();

        if (session) {
          const { data: questions } = await supabase
            .from('interview_questions')
            .select('*')
            .eq('session_id', sessionId)
            .order('question_number');

          return new Response(JSON.stringify({
            success: true,
            data: { ...session, questions },
          }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          });
        }
      }

      return new Response(JSON.stringify({ error: 'Session not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // POST: Create session, answer question, or complete session
    const body = await req.json() as InterviewRequest;
    const {
      session_type = 'general',
      difficulty = 'medium',
      daf_data = {},
      current_question_index,
      user_response,
      response_duration_seconds,
    } = body;

    const a4fKey = Deno.env.get('A4F_API_KEY');

    // Check if continuing an existing session
    if (current_question_index !== undefined && user_response) {
      return await handleQuestionAnswer(
        supabaseAdmin,
        a4fKey,
        body,
        startTime
      );
    }

    // Create new interview session
    const totalRounds = session_type === 'mock_full' ? 5 : 3;
    const sessionData = {
      user_id: 'system-user', // Will be replaced with actual auth
      session_type,
      difficulty,
      daf_data,
      current_round: 1,
      total_rounds: totalRounds,
      is_completed: false,
    };

    // For actual auth, we need to get user_id from auth header
    const authHeader = req.headers.get('Authorization');
    if (authHeader) {
      const supabase = createClient(
        Deno.env.get('SUPABASE_URL')!,
        authHeader.replace('Bearer ', '')
      );
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        sessionData.user_id = user.id;
      }
    }

    // Generate questions
    const questions = await generateInterviewQuestions(
      a4fKey,
      session_type,
      difficulty,
      daf_data,
      totalRounds
    );

    // Save session
    const { data: session, error: sessionError } = await supabaseAdmin
      .from('interview_sessions')
      .insert(sessionData)
      .select()
      .single();

    if (sessionError) throw sessionError;

    // Save questions
    const questionsToInsert = questions.map((q, i) => ({
      session_id: session.id,
      round_number: q.round,
      question_number: i + 1,
      question: q.question,
      category: q.category,
      follow_up: q.follow_up,
      asked_at: new Date().toISOString(),
    }));

    const { data: savedQuestions, error: qError } = await supabaseAdmin
      .from('interview_questions')
      .insert(questionsToInsert)
      .select();

    if (qError) throw qError;

    // Return first question
    return new Response(JSON.stringify({
      success: true,
      data: {
        session_id: session.id,
        session_type,
        difficulty,
        total_questions: questions.length,
        current_question: {
          number: 1,
          ...questions[0],
        },
        questions: savedQuestions,
      },
      processing_time_seconds: (Date.now() - startTime) / 1000,
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error) {
    return new Response(JSON.stringify({
      success: false,
      error: (error as Error).message,
      processing_time_seconds: (Date.now() - startTime) / 1000,
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});

/**
 * Handle user answering a question
 */
async function handleQuestionAnswer(
  supabaseAdmin: any,
  apiKey: string | undefined,
  body: InterviewRequest,
  startTime: number
) {
  const { current_question_index, user_response, response_duration_seconds } = body;

  // Get the session and question
  // In real implementation, would fetch from DB based on session context

  // Evaluate the response
  const evaluation = apiKey
    ? await evaluateResponse(apiKey, body)
    : generateDefaultEvaluation(user_response);

  // Calculate scores
  const contentScore = evaluation.rubric_scores?.content || 70;
  const communicationScore = evaluation.rubric_scores?.communication || 70;
  const personalityScore = evaluation.rubric_scores?.personality || 70;
  const totalScore = (contentScore * 0.4) + (communicationScore * 0.3) + (personalityScore * 0.3);

  return new Response(JSON.stringify({
    success: true,
    data: {
      question_index: current_question_index,
      evaluation: {
        score: totalScore,
        content_score: contentScore,
        communication_score: communicationScore,
        personality_score: personalityScore,
        feedback: evaluation.feedback,
        key_points: evaluation.key_points,
        improvement_suggestions: evaluation.improvement_suggestions,
        follow_up_questions: evaluation.follow_up_questions,
      },
      processing_time_seconds: (Date.now() - startTime) / 1000,
    },
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

/**
 * Generate interview questions based on session type and DAF
 */
async function generateInterviewQuestions(
  apiKey: string | undefined,
  sessionType: string,
  difficulty: string,
  dafData: any,
  totalRounds: number
): Promise<Question[]> {
  const questions: Question[] = [];
  const roundConfig = getRoundConfig(sessionType);

  for (let round = 1; round <= totalRounds; round++) {
    const roundQuestions = await generateRoundQuestions(
      apiKey,
      round,
      roundConfig[round - 1] || 'general',
      difficulty,
      dafData
    );
    questions.push(...roundQuestions);
  }

  return questions;
}

/**
 * Get round configuration based on session type
 */
function getRoundConfig(sessionType: string): string[] {
  const configs: Record<string, string[]> = {
    general: ['background', 'current_affairs', 'situational'],
    daf_based: ['background', 'background', 'situational'],
    current_affairs: ['current_affairs', 'current_affairs', 'situational'],
    optional_subject: ['optional', 'optional', 'situational'],
    mock_full: ['background', 'current_affairs', 'optional', 'situational', 'situational'],
  };
  return configs[sessionType] || configs.general;
}

/**
 * Generate questions for a specific round
 */
async function generateRoundQuestions(
  apiKey: string | undefined,
  roundNumber: number,
  category: string,
  difficulty: string,
  dafData: any
): Promise<Question[]> {
  const questionCount = roundNumber === 1 ? 3 : 2;
  const questions: Question[] = [];

  for (let i = 0; i < questionCount; i++) {
    const question = apiKey
      ? await generateQuestion(apiKey, category, difficulty, dafData, roundNumber, i + 1)
      : generateDefaultQuestion(category, difficulty, dafData);

    questions.push({
      id: `q-${roundNumber}-${i + 1}`,
      round: roundNumber,
      question_number: i + 1,
      ...question,
    });
  }

  return questions;
}

/**
 * Generate a single question using AI
 */
async function generateQuestion(
  apiKey: string,
  category: string,
  difficulty: string,
  dafData: any,
  roundNumber: number,
  questionNumber: number
): Promise<Omit<Question, 'id' | 'round' | 'question_number'>> {
  const difficultyModifier = {
    easy: 'basic level question',
    medium: 'moderate difficulty question',
    hard: 'challenging question that requires deep thinking',
    actual: 'UPSC interview board level question - realistic and probing',
  }[difficulty];

  const categoryPrompts: Record<string, string> = {
    background: `Generate a question about the candidate's background, education, hobbies, or work experience. Reference: ${JSON.stringify(dafData)}`,
    current_affairs: 'Generate a question on recent current affairs, preferably related to India\'s polity, economy, or international relations.',
    optional: `Generate a question on the optional subject: ${dafData.optional_subject || 'General Studies'}`,
    situational: 'Generate a situational or hypothetical question testing judgment, ethics, or problem-solving ability.',
    academic: 'Generate an academic question related to the candidate\'s educational background.',
  };

  const response = await fetch('https://api.a4f.co/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'provider-3/llama-4-scout',
      messages: [
        {
          role: 'system',
          content: `You are an expert UPSC interview board member creating ${difficultyModifier}.
Generate a question that:
- Tests authenticity and genuine interest
- Probes deeper understanding
- Is appropriate for a 2-3 minute response
- Includes 2-3 follow-up directions
- Lists key points interviewers look for

Return JSON:
{
  "question": "The main question",
  "category": "background/current_affairs/optional/situational/academic",
  "follow_up": ["Follow-up 1", "Follow-up 2"],
  "ideal_points": ["Point 1", "Point 2", "Point 3"],
  "sample_answer": "Brief sample answer direction"
}`,
        },
        {
          role: 'user',
          content: categoryPrompts[category] || categoryPrompts.background,
        },
      ],
      max_tokens: 500,
      temperature: 0.7,
    }),
  });

  if (response.ok) {
    const data = await response.json();
    const content = data.choices?.[0]?.message?.content || '';
    const jsonMatch = content.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      return JSON.parse(jsonMatch[0]);
    }
  }

  return generateDefaultQuestion(category, difficulty, dafData);
}

/**
 * Generate default question without AI
 */
function generateDefaultQuestion(
  category: string,
  difficulty: string,
  dafData: any
): Omit<Question, 'id' | 'round' | 'question_number'> {
  const questions: Record<string, string[]> = {
    background: [
      `Tell us about your educational background and how it has shaped your perspective.`,
      `What are your hobbies and how have they influenced your personality?`,
      `Why do you want to join the Indian Administrative Service?`,
    ],
    current_affairs: [
      `What do you think are the major challenges facing India today?`,
      `How do you stay updated with current affairs?`,
      `What is your opinion on recent economic reforms in India?`,
    ],
    optional: [
      `Explain the key concepts of your optional subject.`,
      `How does your optional subject relate to governance?`,
      `What attracted you to choose this optional subject?`,
    ],
    situational: [
      `If you witness corruption in your office, how would you handle it?`,
      `How would you balance development and environmental protection?`,
      `Describe a situation where you had to make a difficult decision.`,
    ],
  };

  const categoryQuestions = questions[category] || questions.background;
  const question = categoryQuestions[Math.floor(Math.random() * categoryQuestions.length)];

  return {
    question,
    category,
    follow_up: [
      'Can you elaborate on that?',
      'What specific examples can you cite?',
      'How would this apply in a real scenario?',
    ],
    ideal_points: [
      'Clear understanding of the topic',
      'Relevant examples and evidence',
      'Balanced perspective',
      'Practical application',
    ],
    sample_answer: 'Structure your answer with introduction, body, and conclusion.',
  };
}

/**
 * Evaluate user response using AI
 */
async function evaluateResponse(
  apiKey: string,
  body: InterviewRequest
): Promise<any> {
  const { user_response, current_question_index } = body;

  const response = await fetch('https://api.a4f.co/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'provider-3/llama-4-scout',
      messages: [
        {
          role: 'system',
          content: `Evaluate this UPSC interview response.
Scoring Rubric (0-100 each):
- Content: Knowledge depth, accuracy, examples (40%)
- Communication: Clarity, structure, confidence (30%)
- Personality: Authenticity, values, judgment (30%)

Return JSON:
{
  "rubric_scores": {
    "content": 0-100,
    "communication": 0-100,
    "personality": 0-100
  },
  "feedback": "Overall assessment",
  "key_points": ["What the candidate did well"],
  "improvement_suggestions": ["Areas to improve"],
  "follow_up_questions": ["Natural follow-up questions"]
}`,
        },
        {
          role: 'user',
          content: `Question ${current_question_index + 1}: ${body.user_response}`,
        },
      ],
      max_tokens: 600,
      temperature: 0.5,
    }),
  });

  if (response.ok) {
    const data = await response.json();
    const content = data.choices?.[0]?.message?.content || '';
    const jsonMatch = content.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      return JSON.parse(jsonMatch[0]);
    }
  }

  return generateDefaultEvaluation(body.user_response);
}

/**
 * Generate default evaluation without AI
 */
function generateDefaultEvaluation(response: string): any {
  const wordCount = response.split(/\s+/).length;
  const hasStructure = response.includes('.') && response.length > 50;

  const contentScore = Math.min(80, 60 + (wordCount > 50 ? 15 : 0) + (hasStructure ? 5 : 0));
  const communicationScore = Math.min(85, 70 + (wordCount > 30 ? 10 : 0) + (hasStructure ? 5 : 0));
  const personalityScore = 75;

  return {
    rubric_scores: {
      content: contentScore,
      communication: communicationScore,
      personality: personalityScore,
    },
    feedback: 'Good attempt! Your response showed understanding of the topic.',
    key_points: [
      'Clear expression of ideas',
      'Relevant to the question asked',
    ],
    improvement_suggestions: [
      'Try to include more specific examples',
      'Work on structuring your answer more clearly',
      'Practice speaking with more confidence',
    ],
    follow_up_questions: [
      'Can you give a specific example?',
      'How would this apply in a different context?',
    ],
  };
}
