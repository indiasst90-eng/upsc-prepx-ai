/**
 * PYQ Videos Pipeline
 *
 * Features:
 * - Browse PYQ by year, paper, topic
 * - Video explanations for PYQs
 * - Bookmark PYQs for revision
 * - Related concepts linking
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from '@supabase/supabase-js';
import { corsHeaders } from '../_shared/cors.ts';

interface PYQVideoRequest {
  action: 'list' | 'get' | 'get_by_year' | 'get_by_topic' | 'bookmark' | 'unbookmark' | 'list_bookmarks' | 'generate_model_answer';
  user_id?: string;
  // List params
  gs_paper?: string;
  year?: number;
  topic?: string;
  limit?: number;
  offset?: number;
  // Get params
  video_id?: string;
  question_id?: string;
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  try {
    const request = await req.json() as PYQVideoRequest;
    const {
      action,
      user_id: requested_user_id,
      gs_paper,
      year,
      topic,
      limit = 20,
      offset = 0,
      video_id,
      question_id,
    } = request;

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    const userId = requested_user_id || req.headers.get('x-user-id');

    switch (action) {
      case 'list':
        return await handleList(supabaseAdmin, { gs_paper, year, topic, limit, offset });

      case 'get':
        return await handleGet(supabaseAdmin, video_id!);

      case 'get_by_year':
        return await handleGetByYear(supabaseAdmin, year!);

      case 'get_by_topic':
        return await handleGetByTopic(supabaseAdmin, topic!, limit);

      case 'bookmark':
        return await handleBookmark(supabaseAdmin, userId!, question_id!);

      case 'unbookmark':
        return await handleUnbookmark(supabaseAdmin, userId!, question_id!);

      case 'list_bookmarks':
        return await handleListBookmarks(supabaseAdmin, userId!, limit, offset);

      case 'generate_model_answer':
        return await handleGenerateModelAnswer(supabaseAdmin, question_id!);

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
 * List PYQ videos with filters
 */
async function handleList(
  supabase: any,
  params: { gs_paper?: string; year?: number; topic?: string; limit: number; offset: number }
): Promise<Response> {
  const { gs_paper, year, topic, limit, offset } = params;

  let query = supabase
    .from('pyq_videos')
    .select('*', { count: 'exact' })
    .eq('status', 'published');

  if (gs_paper) query = query.eq('gs_paper', gs_paper);
  if (year) query = query.eq('year', year);
  if (topic) query = query.ilike('topics', `%${topic}%`);

  const { data: videos, error, count } = await query
    .order('year', { ascending: false })
    .order('gs_paper', { ascending: true })
    .range(offset, offset + limit - 1);

  if (error) {
    throw new Error(`Failed to fetch videos: ${error.message}`);
  }

  // Get available years and papers for filters
  const { data: yearsData } = await supabase
    .from('pyq_videos')
    .select('year')
    .eq('status', 'published')
    .distinct('year');

  const availableYears = yearsData?.map((y) => y.year).sort((a, b) => b - a) || [];

  return new Response(
    JSON.stringify({
      success: true,
      data: videos,
      filters: {
        years: availableYears,
        gs_papers: ['GS Paper I', 'GS Paper II', 'GS Paper III', 'GS Paper IV', 'CSAT'],
      },
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

/**
 * Get single video
 */
async function handleGet(supabase: any, videoId: string): Promise<Response> {
  const { data: video, error } = await supabase
    .from('pyq_videos')
    .select('*')
    .eq('id', videoId)
    .single();

  if (error || !video) {
    return new Response(
      JSON.stringify({ error: 'Video not found' }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 404,
      }
    );
  }

  // Get related videos
  const { data: relatedVideos } = await supabase
    .from('pyq_videos')
    .select('*')
    .eq('status', 'published')
    .eq('year', video.year)
    .neq('id', videoId)
    .limit(3);

  // Increment view count
  await supabase
    .from('pyq_videos')
    .update({ view_count: (video.view_count || 0) + 1 })
    .eq('id', videoId);

  return new Response(
    JSON.stringify({
      success: true,
      data: {
        ...video,
        related_videos: relatedVideos,
      },
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}

/**
 * Get videos by year
 */
async function handleGetByYear(supabase: any, year: number): Promise<Response> {
  const { data: videos, error } = await supabase
    .from('pyq_videos')
    .select('*')
    .eq('status', 'published')
    .eq('year', year)
    .order('gs_paper', { ascending: true });

  if (error) {
    throw new Error(`Failed to fetch videos: ${error.message}`);
  }

  // Group by paper
  const byPaper: Record<string, any[]> = {};
  for (const video of videos || []) {
    if (!byPaper[video.gs_paper]) {
      byPaper[video.gs_paper] = [];
    }
    byPaper[video.gs_paper].push(video);
  }

  return new Response(
    JSON.stringify({
      success: true,
      data: {
        year,
        by_paper: byPaper,
        total_count: videos?.length || 0,
      },
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}

/**
 * Get videos by topic
 */
async function handleGetByTopic(supabase: any, topic: string, limit: number): Promise<Response> {
  const { data: videos, error } = await supabase
    .from('pyq_videos')
    .select('*')
    .eq('status', 'published')
    .ilike('topics', `%${topic}%`)
    .order('year', { ascending: false })
    .limit(limit);

  if (error) {
    throw new Error(`Failed to fetch videos: ${error.message}`);
  }

  return new Response(
    JSON.stringify({
      success: true,
      data: videos,
      topic,
      count: videos?.length || 0,
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}

/**
 * Bookmark a PYQ
 */
async function handleBookmark(supabase: any, userId: string, questionId: string): Promise<Response> {
  // Check if already bookmarked
  const { data: existing } = await supabase
    .from('pyq_bookmarks')
    .select('*')
    .eq('user_id', userId)
    .eq('question_id', questionId)
    .single();

  if (existing) {
    return new Response(
      JSON.stringify({ success: true, data: existing, message: 'Already bookmarked' }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }

  // Get video/question info
  const { data: video } = await supabase
    .from('pyq_videos')
    .select('*')
    .eq('id', questionId)
    .single();

  const { data: bookmark, error } = await supabase
    .from('pyq_bookmarks')
    .insert({
      user_id: userId,
      question_id: questionId,
      question_text: video?.question_text,
      gs_paper: video?.gs_paper,
      year: video?.year,
      topics: video?.topics,
      bookmarked_at: new Date().toISOString(),
    })
    .select()
    .single();

  if (error) {
    throw new Error(`Failed to bookmark: ${error.message}`);
  }

  return new Response(
    JSON.stringify({ success: true, data: bookmark }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}

/**
 * Unbookmark a PYQ
 */
async function handleUnbookmark(supabase: any, userId: string, questionId: string): Promise<Response> {
  const { error } = await supabase
    .from('pyq_bookmarks')
    .delete()
    .eq('user_id', userId)
    .eq('question_id', questionId);

  if (error) {
    throw new Error(`Failed to unbookmark: ${error.message}`);
  }

  return new Response(
    JSON.stringify({ success: true }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}

/**
 * List user's bookmarks
 */
async function handleListBookmarks(
  supabase: any,
  userId: string,
  limit: number,
  offset: number
): Promise<Response> {
  const { data: bookmarks, error, count } = await supabase
    .from('pyq_bookmarks')
    .select('*', { count: 'exact' })
    .eq('user_id', userId)
    .order('bookmarked_at', { ascending: false })
    .range(offset, offset + limit - 1);

  if (error) {
    throw new Error(`Failed to fetch bookmarks: ${error.message}`);
  }

  return new Response(
    JSON.stringify({
      success: true,
      data: bookmarks,
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

/**
 * Generate model answer for a PYQ
 */
async function handleGenerateModelAnswer(supabase: any, questionId: string): Promise<Response> {
  // Get video/question info
  const { data: video, error: videoError } = await supabase
    .from('pyq_videos')
    .select('*')
    .eq('id', questionId)
    .single();

  if (videoError || !video) {
    return new Response(
      JSON.stringify({ error: 'Question not found' }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 404,
      }
    );
  }

  // Check if model answer already exists
  if (video.model_answer) {
    return new Response(
      JSON.stringify({
        success: true,
        data: { model_answer: video.model_answer },
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }

  const a4fKey = Deno.env.get('A4F_API_KEY');

  if (!a4fKey) {
    return new Response(
      JSON.stringify({ error: 'AI service not available' }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 503,
      }
    );
  }

  // Fetch RAG context
  let contextData = '';
  try {
    const { data: chunks } = await supabase
      .from('knowledge_chunks')
      .select('content')
      .ilike('topics', `%${video.topics?.[0]}%`)
      .limit(3);

    if (chunks && chunks.length > 0) {
      contextData = chunks.map((c: any) => c.content).join('\n\n').slice(0, 1500);
    }
  } catch (err) {
    console.warn('RAG context fetch failed:', err);
  }

  // Generate model answer
  const response = await fetch('https://api.a4f.co/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${a4fKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'provider-3/llama-4-scout',
      messages: [
        {
          role: 'system',
          content: `You are an expert UPSC examiner. Generate a model answer for a previous year question.

Requirements:
- Word limit: 150-250 words (appropriate for the question)
- Structure: Introduction, Main Body (with sub-points), Conclusion
- Include relevant facts, data, examples
- Use UPSC-appropriate language
- Start directly with the answer content`,
        },
        {
          role: 'user',
          content: `**Question (${video.gs_paper}, ${video.year}):**
${video.question_text}

${contextData ? `**Reference Material:**\n${contextData}` : ''}

Generate a model answer:`,
        },
      ],
      max_tokens: 800,
      temperature: 0.5,
    }),
  });

  if (!response.ok) {
    return new Response(
      JSON.stringify({ error: 'Failed to generate model answer' }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    );
  }

  const data = await response.json();
  const modelAnswer = data.choices?.[0]?.message?.content?.trim();

  // Save model answer
  await supabase
    .from('pyq_videos')
    .update({ model_answer: modelAnswer })
    .eq('id', questionId);

  return new Response(
    JSON.stringify({
      success: true,
      data: { model_answer: modelAnswer },
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}
