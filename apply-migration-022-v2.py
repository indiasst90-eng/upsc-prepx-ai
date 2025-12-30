#!/usr/bin/env python3
"""
Direct Migration 022 Application - Multi-request approach
Splits large migration into smaller chunks to avoid size limits.
"""

import requests
import time

SUPABASE_URL = "http://89.117.60.144:54321"
ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"

headers = {
    'apikey': ANON_KEY,
    'Authorization': f'Bearer {SERVICE_KEY}',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation'
}

def execute_sql(sql_statement, description):
    """Execute a single SQL statement"""
    print(f"[{description}]...")

    try:
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/rpc",
            json={"sql_query": sql_statement},
            headers=headers,
            timeout=60
        )

        if response.status_code == 200:
            result = response.json()
            if result.get('error'):
                print(f"  ✗ Error: {result.get('error')}")
                return False
            print("  ✓ Success")
            return True
        else:
            print(f"  ✗ HTTP {response.status_code}: {response.text[:100]}")
            return False

    except requests.RequestException as e:
        print(f"  ✗ Request error: {e}")
        return False
    except Exception as e:
        print(f"  ✗ Unexpected error: {e}")
        return False

def execute_migrations():
    """Execute all migrations in sequence"""
    print("=" * 60)
    print("Applying Migration 022: Refund System")
    print("=" * 60)
    print()

    all_success = True

    # 1. Create refunds table
    all_success &= execute_sql("""
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
          rejection_reason TEXT,
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
    """, "Create refunds table")

    time.sleep(2)

    # 2. Create indexes
    all_success &= execute_sql("""
        CREATE INDEX IF NOT EXISTS idx_refunds_user ON public.refunds(user_id);
        CREATE INDEX IF NOT EXISTS idx_refunds_subscription ON public.refunds(subscription_id);
        CREATE INDEX IF NOT EXISTS idx_refunds_status ON public.refunds(status);
        CREATE INDEX IF NOT EXISTS idx_refunds_requested ON public.refunds(requested_at DESC);
    """, "Create indexes")

    time.sleep(2)

    # 3. Enable RLS and policies
    all_success &= execute_sql("""
        ALTER TABLE public.refunds ENABLE ROW LEVEL SECURITY;

        CREATE POLICY "Users can view own refunds"
          ON public.refunds FOR SELECT
          USING (auth.uid() = user_id);

        CREATE POLICY "Users can request refunds"
          ON public.refunds FOR INSERT
          WITH CHECK (auth.uid() = user_id);

        CREATE POLICY "Admins can manage all refunds"
          ON public.refunds FOR ALL
          USING (EXISTS (SELECT 1 FROM public.user_profiles WHERE user_id = auth.uid() AND role = 'admin'));
    """, "Enable RLS and policies")

    time.sleep(2)

    # 4. Create check_refund_eligibility function
    all_success &= execute_sql("""
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
          SELECT * INTO v_subscription FROM subscriptions WHERE id = p_subscription_id AND user_id = p_user_id;

          IF NOT FOUND THEN
            RETURN QUERY SELECT false, 'Subscription not found'::TEXT, 0, ''::TEXT, 0;
            RETURN;
          END IF;

          SELECT * INTO v_transaction FROM payment_transactions
          WHERE user_id = p_user_id AND status = 'captured'
          ORDER BY created_at DESC LIMIT 1;

          IF NOT FOUND THEN
            RETURN QUERY SELECT false, 'No payment found'::TEXT, 0, ''::TEXT, 0;
            RETURN;
          END IF;

          v_days_elapsed := EXTRACT(DAY FROM (NOW() - v_transaction.created_at));

          IF v_days_elapsed > 7 THEN
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
            ELSE
              RETURN QUERY SELECT false, 'Only active subscriptions can be refunded'::TEXT, 0, ''::TEXT, v_days_elapsed;
            RETURN;
          END IF;
          RETURN QUERY SELECT false, 'Only active subscriptions can be refunded'::TEXT, 0, ''::TEXT, v_days_elapsed;
          RETURN;
        END IF;

          SELECT COUNT(*) INTO v_refund_count FROM refunds
          WHERE user_id = p_user_id
            AND status IN ('completed', 'approved')
            AND requested_at >= NOW() - INTERVAL '1 year';

          IF v_refund_count >= 1 THEN
            RETURN QUERY SELECT false, 'Refund limit reached (1 per year)'::TEXT, 0, ''::TEXT, v_days_elapsed;
            RETURN;
          END IF;

          RETURN QUERY SELECT true, 'Eligible for refund'::TEXT, v_refund_amount, v_refund_type, v_days_elapsed;
        END;
        $$ LANGUAGE plpgsql SECURITY DEFINER;
    """, "Create check_refund_eligibility function")

    time.sleep(3)

    # 5. Create refund_analytics view
    all_success &= execute_sql("""
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
    """, "Create refund_analytics view")

    time.sleep(3)

    # 6. Create trigger
    all_success &= execute_sql("""
        CREATE TRIGGER set_refunds_updated_at
          BEFORE UPDATE ON public.refunds
          FOR EACH ROW
          EXECUTE FUNCTION update_updated_at_column();
    """, "Create trigger")

    time.sleep(2)

    print()
    print("=" * 60)
    if all_success:
        print("SUCCESS: Migration 022 Applied Successfully!")
        print("=" * 60)
        print()
        print("Tables created:")
        print("  ✓ refunds")
        print("  ✓ refund_analytics")
        print()
        print("Functions created:")
        print("  ✓ check_refund_eligibility()")
        print()
        print("Indexes created:")
        print("  ✓ idx_refunds_user")
        print("  ✓ idx_refunds_subscription")
        print("  ✓ idx_refunds_status")
        print("  ✓ idx_refunds_requested")
        print()
        print("Policies enabled:")
        print("  ✓ Users can view own refunds")
        print("  ✓ Users can request refunds")
        print("  ✓ Admins can manage all refunds")
        print()
        print("Triggers created:")
        print("  ✓ set_refunds_updated_at")
        print()
        print("Verification:")
        print("Run: SELECT * FROM refunds LIMIT 5;")
        print()
        return True
    else:
        print("=" * 60)
        print("ERROR: Migration Failed - Some steps failed")
        print("=" * 60)
        print()
        print("MANUAL APPLICATION REQUIRED:")
        print("=" * 60)
        print("1. Open Supabase Studio: http://89.117.60.144:3000")
        print("2. Go to SQL Editor")
        print("3. Open: packages/supabase/supabase/migrations/022_refund_system.sql")
        print("4. Copy & Run")
        print()
        return False

if __name__ == '__main__':
    execute_migrations()
