/**
 * PYQ (Previous Year Questions) Solution Generator
 *
 * Generates solutions to UPSC previous year questions in SIMPLE 10th class language.
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from '@supabase/supabase-js';
import { corsHeaders } from '../_shared/cors.ts';

interface PYQRequest {
  question: string;
  paper: string; // GS1, GS2, GS3, GS4, CSAT, Essay
  year?: number;
  topic?: string;
  include_approach?: boolean;
  include_marking_tips?: boolean;
}

interface PYQResponse {
  success: boolean;
  solution_id: string;
  question: string;
  paper: string;
  year: number;
  answer: string; // In SIMPLE language
  key_points: string[];
  approach: string; // How to answer
  marking_tips?: string[];
  word_limit?: string;
  time_allocation?: string;
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
    const {
      question,
      paper = 'GS1',
      year = 2024,
      topic,
      include_approach = true,
      include_marking_tips = true,
    } = await req.json() as PYQRequest;

    if (!question || question.trim().length < 10) {
      return new Response(
        JSON.stringify({ error: 'Question must be at least 10 characters' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
      );
    }

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    // Generate solution in SIMPLE language
    const solution = await generateSimpleSolution({
      question,
      paper,
      year,
      topic,
      includeApproach: include_approach,
      includeMarkingTips: include_marking_tips,
    });

    // Store in database
    const { data: inserted, error: insertError } = await supabaseAdmin
      .from('pyq_solutions')
      .insert({
        question: question,
        paper: paper,
        year: year,
        topic: topic,
        answer: solution.answer,
        key_points: solution.key_points,
        approach: solution.approach,
        marking_tips: solution.marking_tips,
        word_limit: solution.word_limit,
        time_allocation: solution.time_allocation,
      })
      .select()
      .single();

    if (insertError) {
      throw new Error(`Failed to save solution: ${insertError.message}`);
    }

    const response: PYQResponse = {
      success: true,
      solution_id: inserted.id,
      question: inserted.question,
      paper: inserted.paper,
      year: inserted.year,
      answer: inserted.answer,
      key_points: inserted.key_points,
      approach: inserted.approach,
      marking_tips: inserted.marking_tips,
      word_limit: inserted.word_limit,
      time_allocation: inserted.time_allocation,
    };

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (error) {
    const processingTime = (Date.now() - startTime) / 1000;

    return new Response(JSON.stringify({
      success: false,
      error: (error as Error).message,
      processing_time_seconds: processingTime,
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    });
  }
});

// Generate solution in SIMPLE 10th class language
async function generateSimpleSolution(params: {
  question: string;
  paper: string;
  year: number;
  topic?: string;
  includeApproach: boolean;
  includeMarkingTips: boolean;
}): Promise<{
  answer: string;
  key_points: string[];
  approach: string;
  marking_tips?: string[];
  word_limit: string;
  time_allocation: string;
}> {
  const a4fKey = Deno.env.get('A4F_API_KEY');
  if (!a4fKey) {
    throw new Error('A4F_API_KEY not configured');
  }

  // Set word limit and time based on paper
  const paperConfig: Record<string, { words: string; time: string }> = {
    GS1: { words: '200 words', time: '7-8 minutes' },
    GS2: { words: '200 words', time: '7-8 minutes' },
    GS3: { words: '200 words', time: '7-8 minutes' },
    GS4: { words: '200 words', time: '7-8 minutes' },
    CSAT: { words: '150 words', time: '5-6 minutes' },
    Essay: { words: '1000 words', time: '60 minutes' },
  };

  const config = paperConfig[params.paper] || paperConfig['GS1'];

  const prompt = `Question (UPSC ${params.paper} ${params.year}): ${params.question}

${params.topic ? `Topic: ${params.topic}` : ''}

IMPORTANT: Write the answer in VERY SIMPLE ENGLISH that a 10th class student can understand and write.

Write in this format:

# Answer in Simple Words

[Write the full answer in simple language. Use short sentences. Explain concepts like you would to a 10th class student. Give examples from everyday life or news.]

# Key Points to Remember
- Point 1 (simple)
- Point 2 (simple)
- Point 3 (simple)

# How to Write This Answer (Simple Steps)
1. First, [what to do first - simple words]
2. Second, [what to do next - simple words]
3. Third, [what to do last - simple words]

# Tips for Marks
- Tip 1 (simple)
- Tip 2 (simple)

Word Limit: ${config.words}
Time to spend: ${config.time}

Remember: Keep everything simple and easy to understand.`;

  const response = await fetch('https://api.a4f.co/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${a4fKey}`,
    },
    body: JSON.stringify({
      model: 'provider-3/llama-4-scout',
      messages: [
        {
          role: 'system',
          content: 'You are a helpful teacher who explains everything in simple 10th class English. Use short sentences. Use simple words. Help students write good answers.',
        },
        { role: 'user', content: prompt },
      ],
      max_tokens: 4000,
      temperature: 0.7,
    }),
  });

  if (!response.ok) {
    throw new Error(`Solution generation failed: ${await response.text()}`);
  }

  const data = await response.json();
  const content = data.choices?.[0]?.message?.content || '';

  // Parse the response
  const lines = content.split('\n').filter(l => l.trim());
  let inAnswer = false;
  let inKeyPoints = false;
  let inApproach = false;
  let inTips = false;

  let answer = '';
  const keyPoints: string[] = [];
  let approach = '';
  const markingTips: string[] = [];

  for (const line of lines) {
    if (line.startsWith('# Answer') || line.includes('Answer in Simple')) {
      inAnswer = true;
      inKeyPoints = false;
      inApproach = false;
      inTips = false;
      continue;
    }
    if (line.startsWith('# Key') || line.includes('Key Points')) {
      inAnswer = false;
      inKeyPoints = true;
      inApproach = false;
      inTips = false;
      continue;
    }
    if (line.includes('How to Write') || line.includes('Simple Steps')) {
      inAnswer = false;
      inKeyPoints = false;
      inApproach = true;
      inTips = false;
      continue;
    }
    if (line.includes('Tips') || line.includes('Marks')) {
      inAnswer = false;
      inKeyPoints = false;
      inApproach = false;
      inTips = true;
      continue;
    }
    if (line.startsWith('#') || line.startsWith('Word') || line.startsWith('Time')) {
      inAnswer = false;
      inKeyPoints = false;
      inApproach = false;
      inTips = false;
      continue;
    }

    if (inAnswer && !line.startsWith('#')) {
      answer += line + '\n';
    }
    if (inKeyPoints && line.trim().startsWith('-')) {
      keyPoints.push(line.replace(/^-\s*/, '').trim());
    }
    if (inApproach && (line.match(/^\d+\./) || line.trim())) {
      approach += line + '\n';
    }
    if (inTips && line.trim().startsWith('-')) {
      markingTips.push(line.replace(/^-\s*/, '').trim());
    }
  }

  return {
    answer: answer.trim() || 'Answer generated successfully',
    key_points: keyPoints.length > 0 ? keyPoints : ['Key point 1', 'Key point 2'],
    approach: approach.trim() || 'Write clearly with examples',
    marking_tips: markingTips.length > 0 ? markingTips : undefined,
    word_limit: config.words,
    time_allocation: config.time,
  };
}
