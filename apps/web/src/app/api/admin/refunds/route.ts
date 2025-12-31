/**
 * Admin Refund Management API
 * Story 5.9 - Refund Processing & Money-Back Guarantee
 *
 * AC#3: Admin review queue in /admin/refunds
 * AC#5: Approval triggers Razorpay refund API
 * AC#6: Refund timeline (48 hours processing)
 * AC#10: Analytics and refund rate tracking
 */

import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

/**
 * Verify admin authentication
 */
async function verifyAdmin(authHeader: string | null) {
  if (!authHeader) return null;

  const token = authHeader.replace('Bearer ', '');
  const { data: { user }, error } = await supabase.auth.getUser(token);

  if (error || !user) return null;

  const { data: profile } = await supabase
    .from('user_profiles')
    .select('role')
    .eq('user_id', user.id)
    .single();

  if (!profile || profile.role !== 'admin') return null;

  return user;
}

/**
 * GET /api/admin/refunds
 * List all refund requests with filtering
 */
export async function GET(request: NextRequest) {
  try {
    const user = await verifyAdmin(request.headers.get('authorization'));
    if (!user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    // Get query params for filtering
    const { searchParams } = new URL(request.url);
    const status = searchParams.get('status');
    const limit = searchParams.get('limit');

    let query = supabase
      .from('refunds')
      .select(`
        *,
        user:users(email, full_name),
        subscription:subscriptions(plan:plans!slug)
        plan:plans!name,
        reviewed_by:users!full_name,
        reviewed_at,
        transaction:payment_transactions(amount_inr, created_at)
      `)
      .order('requested_at', { ascending: false })
      .limit(100);

    if (status && ['pending', 'approved', 'rejected', 'completed', 'failed'].includes(status)) {
      query = query.eq('status', status);
    }

    const { data: refunds, error } = await query;

    if (error) {
      console.error('Fetch refunds error:', error);
      return NextResponse.json({ error: 'Failed to fetch refunds' }, { status: 500 });
    }

    return NextResponse.json({ refunds });

  } catch (error) {
    console.error('GET refunds error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

/**
 * GET /api/admin/refunds/analytics
 * Refund statistics dashboard data
 */
export async function GET_analytics(request: NextRequest) {
  try {
    const user = await verifyAdmin(request.headers.get('authorization'));
    if (!user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    // Fetch refund analytics view
    const { data: analytics } = await supabase
      .from('refund_analytics')
      .select('*')
      .single();

    if (!analytics) {
      return NextResponse.json({ error: 'Analytics view not found' }, { status: 404 });
    }

    return NextResponse.json({ analytics });

  } catch (error) {
    console.error('Analytics error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
