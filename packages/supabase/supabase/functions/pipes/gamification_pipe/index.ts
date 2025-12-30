/**
 * Gamification Pipe - XP, Streaks, Badges, Leaderboards
 *
 * Manages user engagement features:
 * - XP tracking and level progression
 * - Daily streaks with bonus rewards
 * - Badge/achievement system
 * - Daily challenges
 * - Leaderboards (weekly, monthly, all-time)
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from '@supabase/supabase-js';
import { corsHeaders } from '../_shared/cors.ts';

interface GamificationRequest {
  action?: 'get_stats' | 'add_xp' | 'update_streak' | 'claim_badge' | 'get_challenges' | 'get_leaderboard' | 'get_badges' | 'get_streak_history';
  xp_amount?: number;
  streak_type?: 'study' | 'quiz' | 'revision' | 'mock' | 'video';
  badge_id?: string;
  leaderboard_type?: 'weekly' | 'monthly' | 'all_time' | 'subject';
  limit?: number;
}

interface UserStats {
  user_id: string;
  level: number;
  xp: number;
  xp_to_next_level: number;
  current_streak: number;
  longest_streak: number;
  total_study_minutes: number;
  total_questions_attempted: number;
  total_correct_answers: number;
  total_essays_written: number;
  total_mocks_taken: number;
  total_videos_watched: number;
  badges: any[];
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
    // Get user from auth
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
    const { data: { user } } = await supabase.auth.getUser();

    if (!user) {
      return new Response(JSON.stringify({ error: 'User not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // GET requests
    if (req.method === 'GET') {
      const url = new URL(req.url);
      const action = url.searchParams.get('action') as GamificationRequest['action'];

      if (action === 'get_stats') {
        return await getUserStats(supabase, user.id);
      }

      if (action === 'get_badges') {
        return await getBadges(supabase, user.id);
      }

      if (action === 'get_challenges') {
        return await getChallenges(supabase, user.id);
      }

      if (action === 'get_leaderboard') {
        const type = url.searchParams.get('type') || 'weekly';
        const limit = parseInt(url.searchParams.get('limit') || '10');
        return await getLeaderboard(supabaseAdmin, type, limit, user.id);
      }

      if (action === 'get_streak_history') {
        return await getStreakHistory(supabase, user.id);
      }
    }

    // POST requests
    const body = await req.json() as GamificationRequest;
    const { action, xp_amount, streak_type, badge_id, leaderboard_type, limit = 10 } = body;

    if (action === 'add_xp' && xp_amount) {
      return await addXp(supabaseAdmin, user.id, xp_amount);
    }

    if (action === 'update_streak' && streak_type) {
      return await updateStreak(supabaseAdmin, user.id, streak_type);
    }

    if (action === 'claim_badge' && badge_id) {
      return await claimBadge(supabaseAdmin, user.id, badge_id);
    }

    if (action === 'get_leaderboard') {
      return await getLeaderboard(supabaseAdmin, leaderboard_type || 'weekly', limit, user.id);
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
 * Get user stats
 */
async function getUserStats(supabase: any, userId: string) {
  // Get or create stats record
  let { data: stats, error } = await supabase
    .from('user_stats')
    .select('*')
    .eq('user_id', userId)
    .single();

  if (error || !stats) {
    // Create stats record
    const { data: newStats, error: createError } = await supabase
      .from('user_stats')
      .insert({ user_id: userId })
      .select()
      .single();

    if (createError) throw createError;
    stats = newStats;
  }

  // Get earned badges
  const { data: badges } = await supabase
    .from('user_badges')
    .select('badge_definitions(*)')
    .eq('user_id', userId);

  const earnedBadges = badges?.map((b: any) => ({
    ...b.badge_definitions,
    earned_at: b.earned_at,
  })) || [];

  // Calculate level progress
  const xpProgress = stats.xp > 0
    ? Math.min(100, (stats.xp / stats.xp_to_next_level) * 100)
    : 0;

  return new Response(JSON.stringify({
    success: true,
    data: {
      ...stats,
      badges: earnedBadges,
      xp_progress: xpProgress,
      level_name: getLevelName(stats.level),
    },
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

/**
 * Get level name based on level
 */
function getLevelName(level: number): string {
  const names: Record<number, string> = {
    1: 'Aspirant',
    2: 'Learner',
    3: 'Scholar',
    4: 'Strategist',
    5: 'Expert',
    6: 'Master',
    7: 'Champion',
    8: 'Legend',
    9: 'Supreme',
    10: 'UPSC Champion',
  };
  return names[level] || 'Aspirant';
}

/**
 * Add XP to user
 */
async function addXp(supabaseAdmin: any, userId: string, xpAmount: number) {
  // Call the database function
  const { data: result, error } = await supabaseAdmin
    .rpc('add_xp', { p_user_id: userId, p_xp_amount: xpAmount });

  if (error) throw error;

  // Check for level up
  const leveledUp = result?.leveled_up;

  // Check for new badges
  const { data: newBadges } = await supabaseAdmin
    .rpc('check_new_badges', { p_user_id: userId });

  return new Response(JSON.stringify({
    success: true,
    data: {
      xp_added: xpAmount,
      leveled_up: leveledUp,
      new_badges: newBadges || [],
      ...result,
    },
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

/**
 * Update user streak
 */
async function updateStreak(supabaseAdmin: any, userId: string, streakType: string) {
  const today = new Date().toISOString().split('T')[0];

  // Call the database function
  const { data: result, error } = await supabaseAdmin
    .rpc('update_user_streak', {
      p_user_id: userId,
      p_date: today,
      p_type: streakType,
    });

  if (error) throw error;

  // Get updated stats
  const { data: stats } = await supabaseAdmin
    .from('user_stats')
    .select('current_streak, longest_streak')
    .eq('user_id', userId)
    .single();

  // Check for streak badge
  const { data: badgeChecks } = await supabaseAdmin
    .from('badge_definitions')
    .select('id')
    .eq('criteria_type', 'streak')
    .lte('criteria_value', stats?.current_streak || 1);

  // Award badges if earned
  const newBadges = [];
  for (const badge of badgeChecks || []) {
    const { error: badgeError } = await supabaseAdmin
      .from('user_badges')
      .insert({
        user_id: userId,
        badge_id: badge.id,
        earned_at: new Date().toISOString(),
      })
      .select()
      .single();

    if (!badgeError) {
      const { data: badgeDef } = await supabaseAdmin
        .from('badge_definitions')
        .select('*')
        .eq('id', badge.id)
        .single();

      newBadges.push(badgeDef);
    }
  }

  return new Response(JSON.stringify({
    success: true,
    data: {
      current_streak: stats?.current_streak,
      longest_streak: stats?.longest_streak,
      streak_type: streakType,
      new_badges_earned: newBadges,
    },
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

/**
 * Claim a badge manually
 */
async function claimBadge(supabaseAdmin: any, userId: string, badgeId: string) {
  // Check if already earned
  const { data: existing } = await supabaseAdmin
    .from('user_badges')
    .select('*')
    .eq('user_id', userId)
    .eq('badge_id', badgeId)
    .single();

  if (existing) {
    return new Response(JSON.stringify({
      success: false,
      error: 'Badge already earned',
    }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // Get badge definition
  const { data: badge, error: badgeError } = await supabaseAdmin
    .from('badge_definitions')
    .select('*')
    .eq('id', badgeId)
    .single();

  if (badgeError) throw badgeError;

  // Check if criteria met
  const { data: stats } = await supabaseAdmin
    .from('user_stats')
    .select('*')
    .eq('user_id', userId)
    .single();

  const criteriaMet = checkBadgeCriteria(badge, stats);

  if (!criteriaMet) {
    return new Response(JSON.stringify({
      success: false,
      error: 'Badge criteria not met',
      progress: getBadgeProgress(badge, stats),
    }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // Award badge
  const { data: userBadge, error } = await supabaseAdmin
    .from('user_badges')
    .insert({
      user_id: userId,
      badge_id: badgeId,
      earned_at: new Date().toISOString(),
    })
    .select()
    .single();

  if (error) throw error;

  // Award XP bonus
  const xpBonus = { common: 50, rare: 100, epic: 250, legendary: 500 }[badge.rarity as string] || 50;
  await supabaseAdmin.rpc('add_xp', { p_user_id: userId, p_xp_amount: xpBonus });

  return new Response(JSON.stringify({
    success: true,
    data: {
      badge,
      user_badge: userBadge,
      xp_bonus: xpBonus,
    },
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

/**
 * Check if badge criteria are met
 */
function checkBadgeCriteria(badge: any, stats: any): boolean {
  if (!stats) return false;

  const criteriaMap: Record<string, string> = {
    streak: 'current_streak',
    total_xp: 'xp',
    questions_correct: 'total_correct_answers',
    essays_written: 'total_essays_written',
    videos_watched: 'total_videos_watched',
    mocks_taken: 'total_mocks_taken',
  };

  const field = criteriaMap[badge.criteria_type];
  if (!field) return false;

  return (stats[field] || 0) >= badge.criteria_value;
}

/**
 * Get badge progress
 */
function getBadgeProgress(badge: any, stats: any): { current: number; target: number; percentage: number } {
  if (!stats) return { current: 0, target: badge.criteria_value, percentage: 0 };

  const criteriaMap: Record<string, string> = {
    streak: 'current_streak',
    total_xp: 'xp',
    questions_correct: 'total_correct_answers',
    essays_written: 'total_essays_written',
    videos_watched: 'total_videos_watched',
    mocks_taken: 'total_mocks_taken',
  };

  const field = criteriaMap[badge.criteria_type];
  const current = field ? (stats[field] || 0) : 0;
  const percentage = Math.min(100, (current / badge.criteria_value) * 100);

  return { current, target: badge.criteria_value, percentage };
}

/**
 * Get available badges
 */
async function getBadges(supabase: any, userId: string) {
  // Get all badge definitions
  const { data: allBadges, error } = await supabase
    .from('badge_definitions')
    .select('*')
    .eq('is_active', true)
    .order('rarity')
    .order('criteria_value');

  if (error) throw error;

  // Get earned badges
  const { data: earned } = await supabase
    .from('user_badges')
    .select('badge_id, earned_at')
    .eq('user_id', userId);

  const earnedIds = new Set(earned?.map((e: any) => e.badge_id) || []);
  const earnedDates = new Map(earned?.map((e: any) => [e.badge_id, e.earned_at]) || []);

  // Get user stats for progress
  const { data: stats } = await supabase
    .from('user_stats')
    .select('*')
    .eq('user_id', userId)
    .single();

  const badgesWithProgress = allBadges?.map((badge: any) => {
    const isEarned = earnedIds.has(badge.id);
    const progress = isEarned ? null : getBadgeProgress(badge, stats);

    return {
      ...badge,
      is_earned: isEarned,
      earned_at: earnedDates.get(badge.id) || null,
      progress,
    };
  }) || [];

  return new Response(JSON.stringify({
    success: true,
    data: {
      badges: badgesWithProgress,
      total_earned: earnedIds.size,
      total_available: allBadges?.length || 0,
    },
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

/**
 * Get daily challenges
 */
async function getChallenges(supabase: any, userId: string) {
  const today = new Date().toISOString().split('T')[0];

  // Get active challenges
  const { data: challenges, error } = await supabase
    .from('daily_challenges')
    .select('*')
    .eq('is_active', true)
    .lte('date', today)
    .order('date')
    .limit(7);

  if (error) throw error;

  // Get user progress
  const { data: progress, error: progressError } = await supabase
    .from('user_challenge_progress')
    .select('*')
    .eq('user_id', userId);

  if (progressError) throw progressError;

  const progressMap = new Map(progress?.map((p: any) => [p.challenge_id, p]) || []);

  const challengesWithProgress = challenges?.map((challenge: any) => {
    const userProgress = progressMap.get(challenge.id);

    return {
      ...challenge,
      user_progress: userProgress?.current_value || 0,
      is_completed: userProgress?.is_completed || false,
      completed_at: userProgress?.completed_at || null,
      progress_percentage: Math.min(100, ((userProgress?.current_value || 0) / challenge.target_value) * 100),
    };
  }) || [];

  return new Response(JSON.stringify({
    success: true,
    data: challengesWithProgress,
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

/**
 * Get leaderboard
 */
async function getLeaderboard(supabaseAdmin: any, type: string, limit: number, currentUserId: string) {
  // For now, generate from user_stats table
  // In production, use leaderboard_entries table with pre-computed rankings

  const { data: entries, error } = await supabaseAdmin
    .from('user_stats')
    .select('user_id, xp, level, current_streak, longest_streak')
    .order('xp', { ascending: false })
    .limit(limit);

  if (error) throw error;

  // Get user profiles for names
  const userIds = entries?.map((e: any) => e.user_id) || [];
  const { data: profiles } = await supabaseAdmin
    .from('user_profiles')
    .select('user_id, full_name, avatar_url')
    .in('user_id', userIds);

  const profileMap = new Map(profiles?.map((p: any) => [p.user_id, p]) || []);

  const leaderboard = entries?.map((entry: any, index: number) => ({
    rank: index + 1,
    user_id: entry.user_id,
    name: profileMap.get(entry.user_id)?.full_name || `User ${entry.user_id.slice(0, 6)}`,
    avatar: profileMap.get(entry.user_id)?.avatar_url || null,
    xp: entry.xp,
    level: entry.level,
    streak: entry.current_streak,
    is_current_user: entry.user_id === currentUserId,
  })) || [];

  // Get current user rank
  const currentUserRank = leaderboard.findIndex((e: any) => e.is_current_user) + 1;

  return new Response(JSON.stringify({
    success: true,
    data: {
      leaderboard,
      current_user_rank: currentUserRank > 0 ? currentUserRank : null,
      type,
    },
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

/**
 * Get streak history
 */
async function getStreakHistory(supabase: any, userId: string) {
  const { data: history, error } = await supabase
    .from('streak_history')
    .select('*')
    .eq('user_id', userId)
    .order('streak_date', { ascending: false })
    .limit(30);

  if (error) throw error;

  return new Response(JSON.stringify({
    success: true,
    data: history,
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
