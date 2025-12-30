// Story 8.6: Generate Questions Edge Function (Supabase Edge Function)
// AC 6: Edge Function generate_questions_pipe.ts orchestrates generation

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';

const A4F_BASE_URL = Deno.env.get('A4F_BASE_URL') || 'https://api.a4f.co/v1';
const A4F_API_KEY = Deno.env.get('A4F_API_KEY');
const PRIMARY_MODEL = 'provider-3/llama-4-scout';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// Story 8.6 AC 3: Question type configurations
const QUESTION_TYPE_CONFIG: Record<string, { label: string; answerFormat: string }> = {
  mcq: {
    label: 'Prelims MCQ',
    answerFormat: '4 options (A, B, C, D) with one correct answer and explanation for each option',
  },
  mains_150: {
    label: 'Mains 150-word',
    answerFormat: 'structured answer with introduction, body points, and conclusion (~150 words)',
  },
  mains_250: {
    label: 'Mains 250-word',
    answerFormat: 'detailed answer with intro, multiple body paragraphs, and conclusion (~250 words)',
  },
  essay: {
    label: 'Essay 1000-word',
    answerFormat: 'comprehensive essay with abstract, thesis, multiple sections, and conclusion (~1000 words)',
  },
};

// Story 8.6 AC 4: Difficulty configurations
const DIFFICULTY_CONFIG: Record<string, string> = {
  easy: 'Basic concepts, direct questions, fundamental understanding required',
  medium: 'Moderate complexity, requires analysis and application of concepts',
  hard: 'Advanced topics, requires critical thinking, inter-linking of concepts, and nuanced understanding',
};

interface GenerateRequest {
  topic: string;
  syllabus_node_id?: string;
  question_type: 'mcq' | 'mains_150' | 'mains_250' | 'essay';
  difficulty: 'easy' | 'medium' | 'hard';
  count: number;
}

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const startTime = Date.now();

  try {
    // Get authorization
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Create Supabase client
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    );

    // Verify user
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Parse request body
    const body: GenerateRequest = await req.json();
    const { topic, syllabus_node_id, question_type, difficulty, count } = body;

    // Validate required fields
    if (!topic || !question_type || !difficulty || !count) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: topic, question_type, difficulty, count' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Validate question type
    if (!['mcq', 'mains_150', 'mains_250', 'essay'].includes(question_type)) {
      return new Response(
        JSON.stringify({ error: 'Invalid question_type' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Validate difficulty
    if (!['easy', 'medium', 'hard'].includes(difficulty)) {
      return new Response(
        JSON.stringify({ error: 'Invalid difficulty' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Validate count (1-10)
    const questionCount = Math.min(Math.max(1, count), 10);

    // Story 8.6 AC 10: Check entitlements
    const { data: limitCheck } = await supabase.rpc('check_question_generation_limit', {
      p_user_id: user.id,
      p_count: questionCount,
    });

    const accessCheck = limitCheck?.[0] || { allowed: true, current_usage: 0, daily_limit: 5 };

    if (!accessCheck.allowed) {
      return new Response(
        JSON.stringify({
          error: 'Daily question generation limit reached',
          reason: accessCheck.reason,
          current_usage: accessCheck.current_usage,
          daily_limit: accessCheck.daily_limit,
          upgrade_required: true,
        }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Build AI prompt
    const typeConfig = QUESTION_TYPE_CONFIG[question_type];
    const difficultyDesc = DIFFICULTY_CONFIG[difficulty];

    const systemPrompt = `You are an expert UPSC question setter with deep knowledge of the UPSC Civil Services Examination pattern.
You create high-quality, exam-style questions that test conceptual understanding and application.

Guidelines:
1. Questions must be factually accurate and relevant to UPSC syllabus
2. Questions should test analytical thinking, not just rote memorization
3. For MCQs, all options should be plausible with clear differentiators
4. Model answers should be comprehensive and well-structured
5. Questions should be original and not directly copied from previous papers`;

    const userPrompt = `Generate ${questionCount} UPSC ${typeConfig.label} questions on the topic: "${topic}"

Difficulty Level: ${difficulty.toUpperCase()}
Difficulty Description: ${difficultyDesc}

For each question, provide:
1. Question text (clear, unambiguous, exam-style)
2. ${typeConfig.answerFormat}
3. Key points covered

IMPORTANT: Return ONLY a valid JSON array with no additional text.
Format:
[
  {
    "question_text": "...",
    "difficulty": "${difficulty}",
    ${question_type === 'mcq' ? '"options": ["Option A", "Option B", "Option C", "Option D"],\n    "correct_answer": "A",\n    "explanations": {"A": "...", "B": "...", "C": "...", "D": "..."},' : ''}
    "model_answer": "...",
    "key_points": ["point1", "point2", "point3"]
  }
]`;

    // Call A4F API
    const aiResponse = await fetch(`${A4F_BASE_URL}/chat/completions`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${A4F_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: PRIMARY_MODEL,
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt },
        ],
        temperature: 0.7,
        max_tokens: question_type === 'essay' ? 4000 : 2000,
      }),
    });

    if (!aiResponse.ok) {
      console.error('[Story 8.6] A4F API error:', await aiResponse.text());
      return new Response(
        JSON.stringify({ error: 'AI generation failed' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const aiResult = await aiResponse.json();
    const content = aiResult.choices?.[0]?.message?.content || '';
    const tokensUsed = aiResult.usage?.total_tokens || 0;

    // Parse JSON from AI response
    let questions: any[] = [];
    try {
      const jsonMatch = content.match(/\[[\s\S]*\]/);
      if (jsonMatch) {
        questions = JSON.parse(jsonMatch[0]);
      } else {
        questions = JSON.parse(content);
      }
    } catch (parseError) {
      console.error('[Story 8.6] JSON parse error:', parseError);
      return new Response(
        JSON.stringify({ error: 'Failed to parse generated questions' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Story 8.6 AC 9: Quality control validation
    const validatedQuestions = questions
      .map((q: any) => {
        const validated = {
          question_text: q.question_text || '',
          question_type,
          difficulty,
          model_answer: q.model_answer || '',
          key_points: Array.isArray(q.key_points) ? q.key_points : [],
          options_json: question_type === 'mcq' ? {
            options: q.options || [],
            correct_answer: q.correct_answer || 'A',
            explanations: q.explanations || {},
          } : null,
          quality_score: 0.8,
          is_valid: true,
        };

        // Quality checks
        if (!validated.question_text || validated.question_text.length < 20) {
          validated.is_valid = false;
          validated.quality_score = 0.3;
        }
        if (!validated.model_answer || validated.model_answer.length < 50) {
          validated.quality_score -= 0.2;
        }
        if (question_type === 'mcq' && (!q.options || q.options.length !== 4)) {
          validated.is_valid = false;
          validated.quality_score = 0.4;
        }

        return validated;
      })
      .filter((q: any) => q.is_valid);

    if (validatedQuestions.length === 0) {
      return new Response(
        JSON.stringify({ error: 'Generated questions did not pass quality validation' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Save to database
    const generationMetadata = {
      model: PRIMARY_MODEL,
      tokens_used: tokensUsed,
      latency_ms: Date.now() - startTime,
      generated_at: new Date().toISOString(),
    };

    const questionsToInsert = validatedQuestions.map((q: any) => ({
      user_id: user.id,
      topic,
      syllabus_node_id: syllabus_node_id || null,
      question_text: q.question_text,
      question_type: q.question_type,
      difficulty: q.difficulty,
      options_json: q.options_json,
      model_answer: q.model_answer,
      key_points: q.key_points,
      generation_metadata: generationMetadata,
      quality_score: q.quality_score,
    }));

    const { data: savedQuestions, error: insertError } = await supabase
      .from('generated_questions')
      .insert(questionsToInsert)
      .select();

    if (insertError) {
      console.error('[Story 8.6] Database insert error:', insertError);
    }

    // Record generation for limit tracking
    await supabase.rpc('record_question_generation', {
      p_user_id: user.id,
      p_count: validatedQuestions.length,
      p_question_type: question_type,
      p_topic: topic,
    });

    // Get updated daily usage
    const { data: newLimitCheck } = await supabase.rpc('check_question_generation_limit', {
      p_user_id: user.id,
      p_count: 0,
    });

    const newUsage = newLimitCheck?.[0] || {
      current_usage: accessCheck.current_usage + validatedQuestions.length,
      daily_limit: accessCheck.daily_limit,
    };

    return new Response(
      JSON.stringify({
        success: true,
        questions: validatedQuestions.map((q: any, idx: number) => ({
          id: savedQuestions?.[idx]?.id || `temp-${idx}`,
          question_text: q.question_text,
          question_type: q.question_type,
          difficulty: q.difficulty,
          options: q.options_json?.options,
          correct_answer: q.options_json?.correct_answer,
          explanations: q.options_json?.explanations,
          model_answer: q.model_answer,
          key_points: q.key_points,
          quality_score: q.quality_score,
        })),
        dailyLimit: {
          used: newUsage.current_usage,
          total: newUsage.daily_limit >= 9999 ? 'unlimited' : newUsage.daily_limit,
          remaining: newUsage.daily_limit >= 9999 ? 'unlimited' : newUsage.daily_limit - newUsage.current_usage,
        },
        metadata: {
          generated_count: validatedQuestions.length,
          requested_count: questionCount,
          latency_ms: Date.now() - startTime,
          tokens_used: tokensUsed,
        },
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('[Story 8.6] Edge function error:', error);
    return new Response(
      JSON.stringify({ error: 'Internal server error', latency_ms: Date.now() - startTime }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
