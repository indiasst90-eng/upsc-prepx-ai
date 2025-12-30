#!/usr/bin/env python3
"""
Apply Migration 022: Refund System to Supabase VPS
This script runs automatically using your VPS credentials.
"""

import requests
import sys
import time

# VPS Configuration
SUPABASE_URL = "http://89.117.60.144:54321"
ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"

# Migration SQL
MIGRATION_SQL = """
-- ============================================================================
-- REFUNDS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.refunds (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  subscription_id UUID NOT NULL REFERENCES public.subscriptions(id) ON DELETE CASCADE,
  transaction_id UUID REFERENCES public.payment_transactions(id),
  amount INTEGER NOT NULL,
  refund_type TEXT NOT NULL CHECK (refund_type IN ('full', 'partial', 'prorated')),
  reason TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'completed', 'failed')),
  reviewed_by UUID REFERENCES public.users(id),
  reviewed_at TIMESTAMPTZ,
  admin_notes TEXT,
  razorpay_refund_id TEXT UNIQUE,
  razorpay_payment_id TEXT,
  razorpay_error_code TEXT,
  razorpay_error_description TEXT,
  requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_refunds_user ON public.refunds(user_id);
CREATE INDEX IF NOT EXISTS idx_refunds_subscription ON public.refunds(subscription_id);
CREATE INDEX IF NOT EXISTS idx_refunds_status ON public.refunds(status);
CREATE INDEX IF NOT EXISTS idx_refunds_requested ON public.refunds(requested_at DESC);

ALTER TABLE public.refunds ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own refunds" ON public.refunds FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can request refunds" ON public.refunds FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Admins can manage all refunds" ON public.refunds FOR ALL USING (EXISTS (SELECT 1 FROM public.user_profiles WHERE user_id = auth.uid() AND role = 'admin'));

-- ============================================================================
-- REFUND ELIGIBILITY CHECK FUNCTION
-- ============================================================================

CREATE OR REPLACE FUNCTION check_refund_eligibility(
  p_user_id UUID,
  p_subscription_id UUID
)
RETURNS TABLE (
  eligible BOOLEAN,
  reason TEXT,
  refund_amount INTEGER,
  refund_type TEXT,
  days_since_purchase INTEGER
) AS $$
DECLARE
  v_subscription RECORD;
  v_transaction RECORD;
  v_refund_count INTEGER;
  v_days_elapsed INTEGER;
  v_refund_amount INTEGER;
  v_refund_type TEXT;
BEGIN
  -- Get subscription details
  SELECT * INTO v_subscription FROM subscriptions WHERE id = p_subscription_id AND user_id = p_user_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Subscription not found'::TEXT, 0, ''::TEXT, 0;
    RETURN;
  END IF;

  -- Get latest payment transaction
  SELECT * INTO v_transaction FROM payment_transactions
  WHERE user_id = p_user_id AND status = 'captured'
  ORDER BY created_at DESC LIMIT 1;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'No payment found'::TEXT, 0, ''::TEXT, 0;
    RETURN;
  END IF;

  -- Calculate days since purchase
  v_days_elapsed := EXTRACT(DAY FROM (NOW() - v_transaction.created_at));

  -- Check if within 7-day money-back guarantee period
  IF v_days_elapsed > 7 THEN
    -- Calculate pro-rated refund
    IF v_subscription.status = 'active' THEN
      DECLARE
        v_total_days INTEGER;
        v_remaining_days INTEGER;
      BEGIN
        SELECT duration_days INTO v_total_days FROM plans WHERE id = v_subscription.plan_id;
        v_remaining_days := v_total_days - v_days_elapsed;

        IF v_remaining_days > 0 THEN
          v_refund_amount := (v_transaction.final_amount * v_remaining_days) / v_total_days;
          v_refund_type := 'prorated';
        ELSE
          RETURN QUERY SELECT false, 'Subscription period expired'::TEXT, 0, ''::TEXT, v_days_elapsed;
          RETURN;
        END IF;
      END;
    ELSE
      RETURN QUERY SELECT false, 'Only active subscriptions can be refunded'::TEXT, 0, ''::TEXT, v_days_elapsed;
      RETURN;
    END IF;
  ELSE
    -- Full refund (7-day money-back guarantee)
    v_refund_amount := v_transaction.final_amount;
    v_refund_type := 'full';
  END IF;

  -- Check refund limit (max 1 per user per year)
  SELECT COUNT(*) INTO v_refund_count
  FROM refunds
  WHERE user_id = p_user_id
    AND status IN ('completed', 'approved')
    AND requested_at >= NOW() - INTERVAL '1 year';

  IF v_refund_count >= 1 THEN
    RETURN QUERY SELECT false, 'Refund limit reached (1 per year)'::TEXT, 0, ''::TEXT, v_days_elapsed;
    RETURN;
  END IF;

  -- Eligible for refund
  RETURN QUERY SELECT true, 'Eligible for refund'::TEXT, v_refund_amount, v_refund_type, v_days_elapsed;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- REFUND STATISTICS VIEW
-- ============================================================================

CREATE OR REPLACE VIEW public.refund_analytics AS
SELECT
  -- Overall stats
  COUNT(*) AS total_refunds,
  COUNT(*) FILTER (WHERE status = 'completed') AS completed_refunds,
  COUNT(*) FILTER (WHERE status = 'pending') AS pending_refunds,
  COUNT(*) FILTER (WHERE status = 'rejected') AS rejected_refunds,

  -- Amounts
  COALESCE(SUM(amount) FILTER (WHERE status = 'completed'), 0) AS total_refunded_amount,
  COALESCE(AVG(amount) FILTER (WHERE status = 'completed'), 0) AS avg_refund_amount,

  -- Refund rate (last 30 days)
  CASE
    WHEN COUNT(*) FILTER (WHERE requested_at >= NOW() - INTERVAL '30 days') > 0
    THEN ROUND(
      COUNT(*) FILTER (WHERE status = 'completed' AND requested_at >= NOW() - INTERVAL '30 days')::NUMERIC /
      NULLIF((SELECT COUNT(*) FROM payment_transactions WHERE status = 'captured' AND created_at >= NOW() - INTERVAL '30 days'), 0) * 100, 2
    )
    ELSE 0
  END AS refund_rate_percent,

  -- By type
  COUNT(*) FILTER (WHERE refund_type = 'full') AS full_refunds,
  COUNT(*) FILTER (WHERE refund_type = 'partial') AS partial_refunds,
  COUNT(*) FILTER (WHERE refund_type = 'prorated') AS prorated_refunds,

  -- Timing
  COALESCE(AVG(EXTRACT(EPOCH FROM (completed_at - requested_at)) / 3600) FILTER (WHERE status = 'completed'), 0) AS avg_processing_hours

FROM refunds;

-- ============================================================================
-- TRIGGER FOR UPDATED_AT
-- ============================================================================

CREATE TRIGGER set_refunds_updated_at
  BEFORE UPDATE ON public.refunds
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE public.refunds IS 'Refund requests and processing (Story 5.9)';
COMMENT ON FUNCTION check_refund_eligibility IS 'Check if user is eligible for refund with amount calculation (Story 5.9)';
COMMENT ON VIEW refund_analytics IS 'Refund statistics for admin dashboard (AC#10)';
"""

def execute_migration():
    print("=" * 60)
    print("Applying Migration 022: Refund System")
    print("=" * 60)
    print()

    # Execute via Supabase RPC
    headers = {
        'apikey': ANON_KEY,
        'Authorization': f'Bearer {SERVICE_KEY}',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation'
    }

    # Try using exec_sql function
    body = {"sql_query": MIGRATION_SQL}

    print("[1/2] Executing migration via Supabase API...")
    response = requests.post(f"{SUPABASE_URL}/rest/v1/rpc/exec", json=body, headers=headers, timeout=60)

    if response.status_code == 200:
        print("[2/2] Migration executed successfully!")
    else:
        print(f"[2/2] ERROR: HTTP {response.status_code}")
        try:
            error_data = response.json()
            print(f"       Details: {error_data}")
        except:
            print(f"       Response: {response.text[:200]}")
        return False

    print()
    print("=" * 60)
    print("SUCCESS: Migration 022 Applied!")
    print("=" * 60)
    print()
    print("Tables created:")
    print("  ✓ refunds")
    print("  ✓ refund_analytics")
    print()
    print("Functions created:")
    print("  ✓ check_refund_eligibility()")
    print()
    print("Verification:")
    print("Run: SELECT * FROM refunds LIMIT 5;")
    print()
    return True

def verify_migration():
    time.sleep(2)  # Wait for migration to complete

    print("=" * 60)
    print("Verifying Migration 022...")
    print("=" * 60)
    print()

    headers = {
        'apikey': ANON_KEY,
        'Authorization': f'Bearer {SERVICE_KEY}'
    }

    # Check if refunds table exists
    response = requests.get(f"{SUPABASE_URL}/rest/v1/refunds?limit=5&select=id,status", headers=headers, timeout=30)

    if response.status_code == 200:
        refunds = response.json()
        print(f"✓ Found {len(refunds)} refunds")
        for refund in refunds[:3]:
            print(f"  - ID: {refund.get('id', 'N/A')}")
            print(f"    Status: {refund.get('status', 'N/A')}")
            print(f"    Created: {refund.get('created_at', 'N/A')}")
        print()
        return True
    else:
        print(f"❌ HTTP {response.status_code}: {response.text[:100]}")
        return False

if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == 'verify':
        verify_migration()
    else:
        success = execute_migration()

        if success:
            # Give database a moment to process
            time.sleep(3)
            # Verify
            verify_migration()
        else:
            print()
            print("=" * 60)
            print("MANUAL APPLICATION REQUIRED")
            print("=" * 60)
            print()
            print("1. Open Supabase Studio: http://89.117.60.144:3000")
            print("2. Go to SQL Editor")
            print("3. Open: packages/supabase/supabase/migrations/022_refund_system.sql")
            print("4. Copy all content (Ctrl+A, Ctrl+C)")
            print("5. Paste into SQL Editor")
            print("6. Click 'Run'")
            print()
            print("=" * 60)
