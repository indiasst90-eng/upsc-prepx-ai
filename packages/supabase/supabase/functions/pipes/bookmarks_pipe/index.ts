/**
 * Bookmarks Pipeline - Smart Bookmark Management with Spaced Repetition
 *
 * Features:
 * - CRUD operations for bookmarks
 * - Automatic spaced repetition scheduling (SM-2 algorithm)
 * - Related content suggestions (notes, videos, PYQs)
 * - Category and tag management
 * - Revision analytics
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from '@supabase/supabase-js';
import { corsHeaders } from '../_shared/cors.ts';

interface BookmarkRequest {
  action: 'create' | 'get' | 'list' | 'update' | 'delete' | 'review' | 'get_schedule';
  bookmark_id?: string;
  user_id?: string;
  // Create/Update params
  concept_title?: string;
  concept_summary?: string;
  tags?: string[];
  category?: string;
  syllabus_node_id?: string;
  source_type?: string;
  source_id?: string;
  source_context?: string;
  // Review params
  rating?: number; // 1-5 for SM-2
  review_notes?: string;
  time_spent_seconds?: number;
}

interface BookmarkResponse {
  success: boolean;
  data?: any;
  error?: string;
  next_revision_date?: string;
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
    const request = await req.json() as BookmarkRequest;
    const {
      action,
      bookmark_id,
      user_id: requested_user_id,
      concept_title,
      concept_summary,
      tags = [],
      category,
      syllabus_node_id,
      source_type,
      source_id,
      source_context,
      rating,
      review_notes,
      time_spent_seconds,
    } = request;

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

    // Handle different actions
    switch (action) {
      case 'create':
        return await handleCreate(supabaseAdmin, userId, {
          concept_title,
          concept_summary,
          tags,
          category,
          syllabus_node_id,
          source_type,
          source_id,
          source_context,
        });

      case 'get':
        return await handleGet(supabaseAdmin, bookmark_id!);

      case 'list':
        return await handleList(supabaseAdmin, userId, request);

      case 'update':
        return await handleUpdate(supabaseAdmin, bookmark_id!, {
          concept_title,
          concept_summary,
          tags,
          category,
        });

      case 'delete':
        return await handleDelete(supabaseAdmin, bookmark_id!);

      case 'review':
        return await handleReview(supabaseAdmin, bookmark_id!, {
          rating,
          review_notes,
          time_spent_seconds,
        });

      case 'get_schedule':
        return await handleGetSchedule(supabaseAdmin, userId, request);

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
 * Create a new bookmark
 */
async function handleCreate(
  supabase: any,
  userId: string,
  params: {
    concept_title?: string;
    concept_summary?: string;
    tags?: string[];
    category?: string;
    syllabus_node_id?: string;
    source_type?: string;
    source_id?: string;
    source_context?: string;
  }
): Promise<Response> {
  const {
    concept_title,
    concept_summary,
    tags,
    category,
    syllabus_node_id,
    source_type,
    source_id,
    source_context,
  } = params;

  if (!concept_title) {
    return new Response(
      JSON.stringify({ error: 'concept_title is required' }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    );
  }

  // Fetch related content from RAG
  let relatedNotes: string[] = [];
  let relatedPyqs: string[] = [];
  let relatedVideos: string[] = [];

  if (syllabus_node_id) {
    // Get notes for this syllabus node
    const { data: notes } = await supabase
      .from('comprehensive_notes')
      .select('id, title, content')
      .eq('syllabus_node_id', syllabus_node_id)
      .limit(3);

    if (notes) {
      relatedNotes = notes.map((n: any) => JSON.stringify({ id: n.id, title: n.title }));
    }

    // Get videos
    const { data: videos } = await supabase
      .from('topic_shorts')
      .select('id, status')
      .eq('syllabus_node_id', syllabus_node_id)
      .eq('status', 'completed')
      .limit(3);

    if (videos) {
      relatedVideos = videos.map((v: any) => v.id);
    }
  }

  // Generate initial spaced repetition schedule
  const now = new Date();
  const nextRevisionDate = new Date(now.getTime() + 24 * 60 * 60 * 1000); // 1 day

  const { data: bookmark, error } = await supabase
    .from('user_bookmarks')
    .insert({
      user_id: userId,
      concept_title,
      concept_summary,
      tags,
      category,
      syllabus_node_id,
      source_type,
      source_id,
      source_context,
      related_notes: relatedNotes,
      related_pyqs: relatedPyqs,
      related_videos: relatedVideos,
      revision_enabled: true,
      next_revision_date: nextRevisionDate.toISOString(),
      memory_strength: 0.5,
      ease_factor: 2.5,
      interval_days: 1,
      created_at: new Date().toISOString(),
    })
    .select()
    .single();

  if (error) {
    throw new Error(`Failed to create bookmark: ${error.message}`);
  }

  // Create initial revision schedule
  await supabase.from('revision_schedules').insert({
    user_id: userId,
    bookmark_id: bookmark.id,
    concept_title,
    scheduled_date: nextRevisionDate.toISOString().split('T')[0],
    priority: 'medium',
    status: 'pending',
  });

  return new Response(
    JSON.stringify({
      success: true,
      data: bookmark,
      next_revision_date: nextRevisionDate.toISOString(),
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}

/**
 * Get a single bookmark
 */
async function handleGet(supabase: any, bookmarkId: string): Promise<Response> {
  const { data: bookmark, error } = await supabase
    .from('user_bookmarks')
    .select('*')
    .eq('id', bookmarkId)
    .single();

  if (error || !bookmark) {
    return new Response(
      JSON.stringify({ error: 'Bookmark not found' }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 404,
      }
    );
  }

  return new Response(
    JSON.stringify({
      success: true,
      data: bookmark,
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}

/**
 * List bookmarks with filters
 */
async function handleList(
  supabase: any,
  userId: string,
  params: {
    category?: string;
    tag?: string;
    upcoming_only?: boolean;
    weak_areas_only?: boolean;
  }
): Promise<Response> {
  const { category, tag, upcoming_only, weak_areas_only } = params;

  let query = supabase
    .from('user_bookmarks')
    .select('*')
    .eq('user_id', userId);

  if (category) {
    query = query.eq('category', category);
  }

  if (tag) {
    query = query.contains('tags', [tag]);
  }

  if (upcoming_only) {
    query = query
      .eq('revision_enabled', true)
      .lte('next_revision_date', new Date().toISOString());
  }

  if (weak_areas_only) {
    query = query.lt('memory_strength', 0.5);
  }

  const { data: bookmarks, error } = await query.order('created_at', { ascending: false });

  if (error) {
    throw new Error(`Failed to fetch bookmarks: ${error.message}`);
  }

  // Get categories and tags summary
  const { data: categoryData } = await supabase
    .from('user_bookmarks')
    .select('category')
    .eq('user_id', userId)
    .not('category', 'is', null);

  const categories = [...new Set(categoryData?.map((b: any) => b.category))];

  return new Response(
    JSON.stringify({
      success: true,
      data: bookmarks,
      summary: {
        total: bookmarks?.length || 0,
        categories,
        upcoming: bookmarks?.filter((b: any) => b.next_revision_date && new Date(b.next_revision_date) <= new Date()).length || 0,
      },
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}

/**
 * Update a bookmark
 */
async function handleUpdate(
  supabase: any,
  bookmarkId: string,
  params: {
    concept_title?: string;
    concept_summary?: string;
    tags?: string[];
    category?: string;
  }
): Promise<Response> {
  const { concept_title, concept_summary, tags, category } = params;

  const updateData: any = { updated_at: new Date().toISOString() };
  if (concept_title) updateData.concept_title = concept_title;
  if (concept_summary !== undefined) updateData.concept_summary = concept_summary;
  if (tags) updateData.tags = tags;
  if (category) updateData.category = category;

  const { data: bookmark, error } = await supabase
    .from('user_bookmarks')
    .update(updateData)
    .eq('id', bookmarkId)
    .select()
    .single();

  if (error) {
    throw new Error(`Failed to update bookmark: ${error.message}`);
  }

  return new Response(
    JSON.stringify({
      success: true,
      data: bookmark,
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}

/**
 * Delete a bookmark
 */
async function handleDelete(supabase: any, bookmarkId: string): Promise<Response> {
  // Delete related revision schedules first
  await supabase.from('revision_schedules').delete().eq('bookmark_id', bookmarkId);

  const { error } = await supabase.from('user_bookmarks').delete().eq('id', bookmarkId);

  if (error) {
    throw new Error(`Failed to delete bookmark: ${error.message}`);
  }

  return new Response(
    JSON.stringify({ success: true }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}

/**
 * Review a bookmark (apply SM-2 algorithm for spaced repetition)
 */
async function handleReview(
  supabase: any,
  bookmarkId: string,
  params: {
    rating?: number;
    review_notes?: string;
    time_spent_seconds?: number;
  }
): Promise<Response> {
  const { rating, review_notes, time_spent_seconds } = params;

  if (!rating || rating < 1 || rating > 5) {
    return new Response(
      JSON.stringify({ error: 'Rating must be between 1 and 5' }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    );
  }

  // Get current bookmark
  const { data: bookmark, error: fetchError } = await supabase
    .from('user_bookmarks')
    .select('*')
    .eq('id', bookmarkId)
    .single();

  if (fetchError || !bookmark) {
    return new Response(
      JSON.stringify({ error: 'Bookmark not found' }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 404,
      }
    );
  }

  // Apply SM-2 algorithm
  const { ease_factor, interval_days } = bookmark;
  let newEaseFactor = Number(ease_factor);
  let newInterval = Number(interval_days);

  if (rating < 3) {
    // Reset on poor rating
    newInterval = 1;
    newEaseFactor = newEaseFactor;
  } else {
    // Improve based on rating
    newEaseFactor = newEaseFactor + (0.1 - (5 - rating) * (0.08 + (5 - rating) * 0.02));
    if (newEaseFactor < 1.3) newEaseFactor = 1.3;

    if (newInterval === 0 || newInterval === 1) {
      newInterval = 1;
    } else if (newInterval === 1) {
      newInterval = 6;
    } else {
      newInterval = Math.round(newInterval * newEaseFactor);
    }
  }

  // Calculate next revision date
  const nextRevisionDate = new Date(Date.now() + newInterval * 24 * 60 * 60 * 1000);
  const newMemoryStrength = rating / 5; // 0.2 to 1.0

  // Update bookmark
  const { data: updatedBookmark, error: updateError } = await supabase
    .from('user_bookmarks')
    .update({
      memory_strength: newMemoryStrength,
      ease_factor: newEaseFactor,
      interval_days: newInterval,
      next_revision_date: nextRevisionDate.toISOString(),
      last_reviewed_at: new Date().toISOString(),
      revision_count: (bookmark.revision_count || 0) + 1,
      updated_at: new Date().toISOString(),
    })
    .eq('id', bookmarkId)
    .select()
    .single();

  if (updateError) {
    throw new Error(`Failed to update bookmark: ${updateError.message}`);
  }

  // Create revision schedule record
  await supabase.from('revision_schedules').insert({
    user_id: bookmark.user_id,
    bookmark_id: bookmarkId,
    concept_title: bookmark.concept_title,
    scheduled_date: nextRevisionDate.toISOString().split('T')[0],
    priority: rating < 3 ? 'high' : 'medium',
    status: 'pending',
    review_notes,
    time_spent_seconds,
    rating,
    ease_factor: newEaseFactor,
    interval_days: newInterval,
  });

  return new Response(
    JSON.stringify({
      success: true,
      data: updatedBookmark,
      next_revision_date: nextRevisionDate.toISOString(),
      algorithm_result: {
        new_ease_factor: newEaseFactor,
        new_interval_days: newInterval,
      },
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}

/**
 * Get revision schedule
 */
async function handleGetSchedule(
  supabase: any,
  userId: string,
  params: {
    start_date?: string;
    end_date?: string;
    priority?: string;
  }
): Promise<Response> {
  const { start_date, end_date, priority } = params;

  let query = supabase
    .from('revision_schedules')
    .select('*')
    .eq('user_id', userId)
    .eq('status', 'pending')
    .gte('scheduled_date', start_date || new Date().toISOString().split('T')[0]);

  if (end_date) {
    query = query.lte('scheduled_date', end_date);
  }

  if (priority) {
    query = query.eq('priority', priority);
  }

  const { data: schedules, error } = await query.order('scheduled_date', { ascending: true });

  if (error) {
    throw new Error(`Failed to fetch schedule: ${error.message}`);
  }

  // Group by date
  const grouped: Record<string, any[]> = {};
  for (const schedule of schedules || []) {
    const date = schedule.scheduled_date;
    if (!grouped[date]) {
      grouped[date] = [];
    }
    grouped[date].push(schedule);
  }

  return new Response(
    JSON.stringify({
      success: true,
      data: schedules,
      grouped,
      summary: {
        total_items: schedules?.length || 0,
        high_priority: schedules?.filter((s: any) => s.priority === 'high').length || 0,
      },
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}
