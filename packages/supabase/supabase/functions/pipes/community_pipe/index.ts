/**
 * Community Pipe - Forums, Discussions, Threads
 *
 * Manages community features:
 * - Discussion forums by GS paper/topic
 * - Thread creation and management
 * - Posts with nested replies
 * - Upvote/downvote system
 * - Moderation features
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from '@supabase/supabase-js';
import { corsHeaders } from '../_shared/cors.ts';

interface CommunityRequest {
  action?: 'list_forums' | 'get_forum' | 'list_threads' | 'get_thread' | 'create_thread' | 'create_post' | 'vote' | 'search';
  forum_id?: string;
  thread_id?: string;
  post_id?: string;
  parent_id?: string;
  // For thread creation
  thread?: {
    title: string;
    content: string;
    tags?: string[];
  };
  // For post creation
  post?: {
    content: string;
  };
  // For voting
  vote?: {
    direction: 'up' | 'down';
  };
  // Search params
  query?: string;
  limit?: number;
  offset?: number;
}

interface Forum {
  id: string;
  name: string;
  description: string;
  category: string;
  thread_count: number;
  post_count: number;
}

interface Thread {
  id: string;
  forum_id: string;
  user_id: string;
  user_name?: string;
  user_avatar?: string;
  title: string;
  content: string;
  tags: string[];
  is_pinned: boolean;
  is_locked: boolean;
  view_count: number;
  reply_count: number;
  last_activity_at: string;
  created_at: string;
  upvotes: number;
  downvotes: number;
  user_vote?: 'up' | 'down';
}

interface Post {
  id: string;
  thread_id: string;
  user_id: string;
  user_name?: string;
  user_avatar?: string;
  content: string;
  parent_id: string | null;
  is_accepted_answer: boolean;
  upvotes: number;
  downvotes: number;
  created_at: string;
  replies?: Post[];
  user_vote?: 'up' | 'down';
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
    const authHeader = req.headers.get('Authorization');
    let userId: string | null = null;
    let userVoteMap: Record<string, 'up' | 'down'> = {};

    // Get user if authenticated
    if (authHeader) {
      const supabase = createClient(
        Deno.env.get('SUPABASE_URL')!,
        authHeader.replace('Bearer ', '')
      );
      const { data: { user } } = await supabase.auth.getUser();
      if (user) userId = user.id;
    }

    // GET requests
    if (req.method === 'GET') {
      const url = new URL(req.url);
      const action = url.searchParams.get('action');
      const forumId = url.searchParams.get('forum_id');
      const threadId = url.searchParams.get('thread_id');
      const limit = parseInt(url.searchParams.get('limit') || '20');
      const offset = parseInt(url.searchParams.get('offset') || '0');

      if (action === 'list_forums') {
        return await listForums(supabaseAdmin);
      }

      if (action === 'get_forum' && forumId) {
        return await getForum(supabaseAdmin, forumId, limit);
      }

      if (action === 'list_threads' && forumId) {
        return await listThreads(supabaseAdmin, forumId, limit, offset, userId);
      }

      if (action === 'get_thread' && threadId) {
        return await getThread(supabaseAdmin, threadId, userId);
      }

      if (action === 'search') {
        const query = url.searchParams.get('query') || '';
        return await searchThreads(supabaseAdmin, query, limit);
      }
    }

    // POST requests
    const body = await req.json() as CommunityRequest;
    const { action, forum_id, thread_id, post_id, parent_id, thread, post, vote, query } = body;

    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Authentication required' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (action === 'create_thread' && forum_id && thread) {
      return await createThread(supabaseAdmin, userId!, forum_id, thread);
    }

    if (action === 'create_post' && thread_id && post) {
      return await createPost(supabaseAdmin, userId!, thread_id, post.content, parent_id);
    }

    if (action === 'vote' && post_id && vote) {
      return await handleVote(supabaseAdmin, userId!, post_id, vote.direction);
    }

    return new Response(JSON.stringify({ error: 'Invalid action' }), {
      status: 400,
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
 * List all forums
 */
async function listForums(supabaseAdmin: any) {
  const { data: forums, error } = await supabaseAdmin
    .from('discussion_forums')
    .select('*')
    .eq('is_active', true)
    .order('category');

  if (error) throw error;

  // Get counts for each forum
  const forumsWithCounts = await Promise.all(
    (forums || []).map(async (forum: any) => {
      const { count: threadCount } = await supabaseAdmin
        .from('discussion_threads')
        .select('*', { count: 'exact', head: true })
        .eq('forum_id', forum.id);

      const { count: postCount } = await supabaseAdmin
        .from('discussion_posts')
        .select('*', { count: 'exact', head: true })
        .eq('thread_id', forum.id);

      return {
        ...forum,
        thread_count: threadCount || 0,
        post_count: postCount || 0,
      };
    })
  );

  return new Response(JSON.stringify({
    success: true,
    data: forumsWithCounts,
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

/**
 * Get forum details
 */
async function getForum(supabaseAdmin: any, forumId: string, limit: number) {
  const { data: forum, error } = await supabaseAdmin
    .from('discussion_forums')
    .select('*')
    .eq('id', forumId)
    .single();

  if (error) throw error;

  // Get pinned threads
  const { data: pinnedThreads } = await supabaseAdmin
    .from('discussion_threads')
    .select('*')
    .eq('forum_id', forumId)
    .eq('is_pinned', true)
    .order('created_at', { ascending: false });

  return new Response(JSON.stringify({
    success: true,
    data: {
      forum,
      pinned_threads: pinnedThreads || [],
    },
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

/**
 * List threads in a forum
 */
async function listThreads(
  supabaseAdmin: any,
  forumId: string,
  limit: number,
  offset: number,
  userId: string | null
) {
  let query = supabaseAdmin
    .from('discussion_threads')
    .select(`
      *,
      user_profiles(full_name, avatar_url)
    `, { count: 'exact' })
    .eq('forum_id', forumId)
    .order('is_pinned', { ascending: false })
    .order('last_activity_at', { ascending: false })
    .range(offset, offset + limit - 1);

  const { data: threads, error, count } = await query;

  if (error) throw error;

  // Get user's votes
  const threadIds = threads?.map((t: any) => t.id) || [];
  let userVotes: any[] = [];

  if (userId && threadIds.length > 0) {
    const { data: votes } = await supabaseAdmin
      .from('thread_votes')
      .select('thread_id, vote_type')
      .eq('user_id', userId)
      .in('thread_id', threadIds);

    userVotes = votes || [];
  }

  const voteMap = new Map(userVotes.map((v: any) => [v.thread_id, v.vote_type]));

  const enrichedThreads = (threads || []).map((thread: any) => ({
    ...thread,
    user_name: thread.user_profiles?.full_name || 'Anonymous',
    user_avatar: thread.user_profiles?.avatar_url || null,
    user_vote: voteMap.get(thread.id) || null,
  }));

  return new Response(JSON.stringify({
    success: true,
    data: {
      threads: enrichedThreads,
      total_count: count || 0,
      has_more: (count || 0) > offset + limit,
    },
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

/**
 * Get single thread with posts
 */
async function getThread(
  supabaseAdmin: any,
  threadId: string,
  userId: string | null
) {
  // Get thread
  const { data: thread, error } = await supabaseAdmin
    .from('discussion_threads')
    .select(`
      *,
      user_profiles(full_name, avatar_url)
    `)
    .eq('id', threadId)
    .single();

  if (error) throw error;

  // Increment view count
  await supabaseAdmin
    .from('discussion_threads')
    .update({ view_count: (thread.view_count || 0) + 1 })
    .eq('id', threadId);

  // Get user's vote
  let userVote = null;
  if (userId) {
    const { data: vote } = await supabaseAdmin
      .from('thread_votes')
      .select('vote_type')
      .eq('user_id', userId)
      .eq('thread_id', threadId)
      .single();

    userVote = vote?.vote_type || null;
  }

  // Get posts (nested)
  const { data: posts, error: postsError } = await supabaseAdmin
    .from('discussion_posts')
    .select(`
      *,
      user_profiles(full_name, avatar_url)
    `)
    .eq('thread_id', threadId)
    .order('upvotes', { ascending: false })
    .order('created_at', { ascending: true });

  if (postsError) throw postsError;

  // Get user's votes on posts
  const postIds = posts?.map((p: any) => p.id) || [];
  let postVotes: any[] = [];

  if (userId && postIds.length > 0) {
    const { data: votes } = await supabaseAdmin
      .from('post_votes')
      .select('post_id, vote_type')
      .eq('user_id', userId)
      .in('post_id', postIds);

    postVotes = votes || [];
  }

  const postVoteMap = new Map(postVotes.map((v: any) => [v.post_id, v.vote_type]));

  // Build comment tree
  const postMap = new Map();
  const rootPosts: any[] = [];

  (posts || []).forEach((post: any) => {
    post.replies = [];
    post.user_vote = postVoteMap.get(post.id) || null;
    post.user_name = post.user_profiles?.full_name || 'Anonymous';
    post.user_avatar = post.user_profiles?.avatar_url || null;
    postMap.set(post.id, post);
  });

  (posts || []).forEach((post: any) => {
    if (post.parent_id) {
      const parent = postMap.get(post.parent_id);
      if (parent) {
        parent.replies.push(post);
      }
    } else {
      rootPosts.push(post);
    }
  });

  return new Response(JSON.stringify({
    success: true,
    data: {
      ...thread,
      user_name: thread.user_profiles?.full_name || 'Anonymous',
      user_avatar: thread.user_profiles?.avatar_url || null,
      user_vote: userVote,
      posts: rootPosts,
    },
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

/**
 * Create a new thread
 */
async function createThread(
  supabaseAdmin: any,
  userId: string,
  forumId: string,
  threadData: { title: string; content: string; tags?: string[] }
) {
  const { data: profile } = await supabaseAdmin
    .from('user_profiles')
    .select('full_name')
    .eq('user_id', userId)
    .single();

  const { data: thread, error } = await supabaseAdmin
    .from('discussion_threads')
    .insert({
      forum_id: forumId,
      user_id: userId,
      title: threadData.title,
      content: threadData.content,
      tags: threadData.tags || [],
      last_activity_at: new Date().toISOString(),
    })
    .select()
    .single();

  if (error) throw error;

  // Create initial post with thread content
  await supabaseAdmin
    .from('discussion_posts')
    .insert({
      thread_id: thread.id,
      user_id: userId,
      content: threadData.content,
    });

  return new Response(JSON.stringify({
    success: true,
    data: {
      ...thread,
      user_name: profile?.full_name || 'Anonymous',
    },
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

/**
 * Create a new post (reply)
 */
async function createPost(
  supabaseAdmin: any,
  userId: string,
  threadId: string,
  content: string,
  parentId?: string
) {
  const { data: profile } = await supabaseAdmin
    .from('user_profiles')
    .select('full_name')
    .eq('user_id', userId)
    .single();

  const { data: post, error } = await supabaseAdmin
    .from('discussion_posts')
    .insert({
      thread_id: threadId,
      user_id: userId,
      content,
      parent_id: parentId || null,
    })
    .select()
    .single();

  if (error) throw error;

  // Update thread activity
  await supabaseAdmin
    .from('discussion_threads')
    .update({
      last_activity_at: new Date().toISOString(),
      reply_count: supabaseAdmin.raw('reply_count + 1'),
    })
    .eq('id', threadId);

  return new Response(JSON.stringify({
    success: true,
    data: {
      ...post,
      user_name: profile?.full_name || 'Anonymous',
    },
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

/**
 * Handle voting on a post
 */
async function handleVote(
  supabaseAdmin: any,
  userId: string,
  postId: string,
  direction: 'up' | 'down'
) {
  // Check existing vote
  const { data: existingVote } = await supabaseAdmin
    .from('post_votes')
    .select('*')
    .eq('user_id', userId)
    .eq('post_id', postId)
    .single();

  if (existingVote) {
    if (existingVote.vote_type === direction) {
      // Remove vote
      await supabaseAdmin
        .from('post_votes')
        .delete()
        .eq('id', existingVote.id);

      await supabaseAdmin
        .from('discussion_posts')
        .update({
          upvotes: direction === 'up' ? supabaseAdmin.raw('upvotes - 1') : supabaseAdmin.raw('upvotes'),
          downvotes: direction === 'down' ? supabaseAdmin.raw('downvotes - 1') : supabaseAdmin.raw('downvotes'),
        })
        .eq('id', postId);
    } else {
      // Change vote
      await supabaseAdmin
        .from('post_votes')
        .update({ vote_type: direction })
        .eq('id', existingVote.id);

      await supabaseAdmin
        .from('discussion_posts')
        .update({
          upvotes: direction === 'up' ? supabaseAdmin.raw('upvotes + 1') : supabaseAdmin.raw('upvotes - 1'),
          downvotes: direction === 'down' ? supabaseAdmin.raw('downvotes + 1') : supabaseAdmin.raw('downvotes - 1'),
        })
        .eq('id', postId);
    }
  } else {
    // New vote
    await supabaseAdmin
      .from('post_votes')
      .insert({
        user_id: userId,
        post_id: postId,
        vote_type: direction,
      });

    await supabaseAdmin
      .from('discussion_posts')
      .update({
        upvotes: direction === 'up' ? supabaseAdmin.raw('upvotes + 1') : supabaseAdmin.raw('upvotes'),
        downvotes: direction === 'down' ? supabaseAdmin.raw('downvotes + 1') : supabaseAdmin.raw('downvotes'),
      })
      .eq('id', postId);
  }

  return new Response(JSON.stringify({
    success: true,
    data: { vote: direction },
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

/**
 * Search threads
 */
async function searchThreads(supabaseAdmin: any, query: string, limit: number) {
  const { data: threads, error } = await supabaseAdmin
    .from('discussion_threads')
    .select(`
      *,
      user_profiles(full_name),
      discussion_forums(name)
    `)
    .ilike('title', `%${query}%`)
    .order('last_activity_at', { ascending: false })
    .limit(limit);

  if (error) throw error;

  return new Response(JSON.stringify({
    success: true,
    data: threads,
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
