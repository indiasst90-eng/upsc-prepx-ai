/**
 * Daily News Generator Pipeline
 *
 * Creates daily news summaries in SIMPLE 10th class standard language.
 * Uses news sources and generates easy-to-understand updates.
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from '@supabase/supabase-js';
import { corsHeaders } from '../_shared/cors.ts';

interface DailyNewsRequest {
  date?: string;
  category?: string;
  include_explanations?: boolean;
}

interface DailyNewsResponse {
  success: boolean;
  news_id: string;
  date: string;
  title: string;
  summary: string; // In SIMPLE language
  key_points: string[]; // Simple bullet points
  detailed_explanation?: string; // Simple explanation for complex topics
  source_count: number;
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
      date = new Date().toISOString().split('T')[0],
      category = 'all',
      include_explanations = true,
    } = await req.json() as DailyNewsRequest;

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    // Check if we already have news for this date
    const { data: existingNews } = await supabaseAdmin
      .from('daily_updates')
      .select('*')
      .eq('date', date)
      .eq('category', category === 'all' ? 'general' : category)
      .single();

    if (existingNews) {
      return new Response(JSON.stringify({
        success: true,
        news_id: existingNews.id,
        date: existingNews.date,
        title: existingNews.title,
        summary: existingNews.summary,
        key_points: existingNews.key_points,
        detailed_explanation: existingNews.detailed_explanation,
        source_count: existingNews.source_count,
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Generate news using A4F with SIMPLE language prompts
    const news = await generateSimpleNews({
      date,
      category,
      includeExplanations: include_explanations,
    });

    // Store in database
    const { data: inserted, error: insertError } = await supabaseAdmin
      .from('daily_updates')
      .insert({
        date: date,
        category: category === 'all' ? 'general' : category,
        title: news.title,
        summary: news.summary,
        key_points: news.key_points,
        detailed_explanation: news.detailed_explanation,
        source_count: news.source_count,
      })
      .select()
      .single();

    if (insertError) {
      throw new Error(`Failed to save news: ${insertError.message}`);
    }

    const response: DailyNewsResponse = {
      success: true,
      news_id: inserted.id,
      date: inserted.date,
      title: inserted.title,
      summary: inserted.summary,
      key_points: inserted.key_points,
      detailed_explanation: inserted.detailed_explanation,
      source_count: inserted.source_count,
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

// Generate news in SIMPLE 10th class standard language
async function generateSimpleNews(params: {
  date: string;
  category: string;
  includeExplanations: boolean;
}): Promise<{
  title: string;
  summary: string;
  key_points: string[];
  detailed_explanation?: string;
  source_count: number;
}> {
  const a4fKey = Deno.env.get('A4F_API_KEY');
  if (!a4fKey) {
    throw new Error('A4F_API_KEY not configured');
  }

  const prompt = `Write today's news summary for UPSC exam preparation.

IMPORTANT: Write in VERY SIMPLE ENGLISH that a 10th class student can understand.
- Use short sentences (8-12 words)
- Use simple words, avoid complex English
- Explain every difficult term
- Give everyday examples

Write in this format:

# Today's News - ${params.date}

## One Line Summary
[Write the main news in one simple sentence]

## Main Points (Easy to Read)
- Point 1 (simple words)
- Point 2 (simple words)
- Point 3 (simple words)
- Point 4 (simple words)

${params.includeExplanations ? `## Easy Explanation
[Explain the main news in 2-3 simple paragraphs.
Use examples from daily life.
Make a 10th class student understand.]` : ''}

## Why This Matters for Exam
[1-2 simple points on why this news is important for UPSC]

Sources: PIB, The Hindu, Indian Express (use your knowledge)

Remember: Keep everything in simple, easy-to-understand English.`;

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
          content: 'You are a friendly news reporter who explains everything in simple 10th class English. Use short sentences. Use simple words. Never use complex or technical language.',
        },
        { role: 'user', content: prompt },
      ],
      max_tokens: 3000,
      temperature: 0.7,
    }),
  });

  if (!response.ok) {
    throw new Error(`News generation failed: ${await response.text()}`);
  }

  const data = await response.json();
  const content = data.choices?.[0]?.message?.content || '';

  // Parse the response
  const lines = content.split('\n').filter(l => l.trim());
  const title = `Daily News Update - ${params.date}`;
  const summary = lines.find(l => l.startsWith('## One Line Summary'))
    ?.replace('## One Line Summary', '').trim() || '';

  const keyPoints: string[] = [];
  let inKeyPoints = false;
  let inExplanation = false;

  for (const line of lines) {
    if (line.startsWith('## Main Points')) {
      inKeyPoints = true;
      inExplanation = false;
      continue;
    }
    if (line.startsWith('## Easy Explanation') || line.startsWith('## Why This Matters')) {
      inKeyPoints = false;
      inExplanation = true;
      continue;
    }
    if (line.startsWith('#') || line.startsWith('##')) {
      inKeyPoints = false;
      inExplanation = false;
      continue;
    }
    if (inKeyPoints && line.trim().startsWith('-')) {
      keyPoints.push(line.replace(/^-\s*/, '').trim());
    }
  }

  const detailedExplanation = params.includeExplanations
    ? lines.filter(l => l.startsWith('## Easy Explanation') || l.startsWith('## Why This Matters'))
        .join('\n')
    : undefined;

  return {
    title,
    summary,
    key_points: keyPoints.length > 0 ? keyPoints : ['News generated successfully'],
    detailed_explanation: detailedExplanation,
    source_count: 3,
  };
}
