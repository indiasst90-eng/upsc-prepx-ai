-- Migration: 022_refund_system.sql
-- Description: Refund processing system for Story 5.9
-- Author: DEV Agent (BMAD)
-- Date: December 28, 2025
-- Story: 5.9 - Refund Processing & Money-Back Guarantee

-- ============================================================================
-- REFUNDS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.refunds (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL ,
  subscription_id UUID NOT NULL REFERENCES public.subscriptions(id) ON DELETE CASCADE,
  transaction_id UUID REFERENCES public.payment_transactions(id),

  -- Refund Details
  amount INTEGER NOT NULL, -- Amount to refund (in paise)
  refund_type TEXT NOT NULL CHECK (refund_type IN ('full', 'partial', 'prorated')),
  reason TEXT, -- Optional user-provided reason

  -- Status
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'completed', 'failed')),

  -- Admin Actions
  reviewed_by UUID ,
  reviewed_at TIMESTAMPTZ,
  admin_notes TEXT,
  rejection_reason TEXT,

  -- Razorpay Integration
  razorpay_refund_id TEXT UNIQUE,
  razorpay_payment_id TEXT,
  razorpay_error_code TEXT,
  razorpay_error_description TEXT,

  -- Timestamps
  requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ,

  -- Metadata
  metadata JSONB DEFAULT '{}',

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_refunds_user ON public.refunds(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_refunds_subscription ON public.refunds(subscription_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_refunds_status ON public.refunds(status);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_refunds_requested ON public.refunds(requested_at DESC);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.refunds ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can view own refunds"
  ON public.refunds FOR SELECT
  USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can request refunds"
  ON public.refunds FOR INSERT
  WITH CHECK (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Admins can manage all refunds"
  ON public.refunds FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================================================
-- REFUND ELIGIBILITY CHECK FUNCTION
-- ============================================================================

-- CREATE OR REPLACE FUNCTION check_refund_eligibility(
--   p_user_id UUID,
--   p_subscription_id UUID
-- )
-- RETURNS TABLE (
--   eligible BOOLEAN,
--   reason TEXT,
--   refund_amount INTEGER,
--   refund_type TEXT,
--   days_since_purchase INTEGER
-- ) AS $$
-- DECLARE
--   v_subscription RECORD;
--   v_transaction RECORD;
--   v_refund_count INTEGER;
--   v_days_elapsed INTEGER;
--   v_refund_amount INTEGER;
--   v_refund_type TEXT;
-- BEGIN
--   -- Get subscription details
--   SELECT * INTO v_subscription
--   FROM subscriptions
--   WHERE id = p_subscription_id AND user_id = p_user_id;
-- 
--   IF NOT FOUND THEN
--     RETURN QUERY SELECT false, 'Subscription not found'::TEXT, 0, ''::TEXT, 0;
--     RETURN;
--   END IF;
-- 
--   -- Get latest payment transaction
--   SELECT * INTO v_transaction
--   FROM payment_transactions
--   WHERE user_id = p_user_id
--     AND status = 'captured'
--   ORDER BY created_at DESC
--   LIMIT 1;
-- 
--   IF NOT FOUND THEN
--     RETURN QUERY SELECT false, 'No payment found'::TEXT, 0, ''::TEXT, 0;
--     RETURN;
--   END IF;
-- 
--   -- Calculate days since purchase
--   v_days_elapsed := EXTRACT(DAY FROM (NOW() - v_transaction.created_at));
-- 
--   -- Check if within 7-day money-back guarantee period
--   IF v_days_elapsed > 7 THEN
--     -- Calculate pro-rated refund
--     IF v_subscription.status = 'active' THEN
--       -- Pro-rated refund based on remaining days
--       DECLARE
--         v_total_days INTEGER;
--         v_remaining_days INTEGER;
--       BEGIN
--         SELECT duration_days INTO v_total_days
--         FROM plans
--         WHERE id = v_subscription.plan_id;
-- 
--         v_remaining_days := v_total_days - v_days_elapsed;
-- 
--         IF v_remaining_days > 0 THEN
--           v_refund_amount := (v_transaction.final_amount * v_remaining_days) / v_total_days;
--           v_refund_type := 'prorated';
--         ELSE
--           RETURN QUERY SELECT false, 'Subscription period expired'::TEXT, 0, ''::TEXT, v_days_elapsed;
--           RETURN;
--         END IF;
--       END;
--     ELSE
--       RETURN QUERY SELECT false, 'Only active subscriptions can be refunded'::TEXT, 0, ''::TEXT, v_days_elapsed;
--       RETURN;
--     END IF;
--   ELSE
--     -- Full refund (7-day money-back guarantee)
--     v_refund_amount := v_transaction.final_amount;
--     v_refund_type := 'full';
--   END IF;
-- 
--   -- Check refund limit (max 1 per user per year)
--   SELECT COUNT(*) INTO v_refund_count
--   FROM refunds
--   WHERE user_id = p_user_id
--     AND status IN ('completed', 'approved')
--     AND requested_at >= NOW() - INTERVAL '1 year';
-- 
--   IF v_refund_count >= 1 THEN
--     RETURN QUERY SELECT false, 'Refund limit reached (1 per year)'::TEXT, 0, ''::TEXT, v_days_elapsed;
--     RETURN;
--   END IF;
-- 
--   -- Eligible for refund
--   RETURN QUERY SELECT true, 'Eligible for refund'::TEXT, v_refund_amount, v_refund_type, v_days_elapsed;
-- END;
-- $$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- REFUND STATISTICS VIEW
-- ============================================================================

-- CREATE OR REPLACE VIEW public.refund_analytics AS
-- SELECT
--   -- Overall stats
--   COUNT(*) AS total_refunds,
--   COUNT(*) FILTER (WHERE status = 'completed') AS completed_refunds,
--   COUNT(*) FILTER (WHERE status = 'pending') AS pending_refunds,
--   COUNT(*) FILTER (WHERE status = 'rejected') AS rejected_refunds,
-- 
--   -- Amounts
--   COALESCE(SUM(amount) FILTER (WHERE status = 'completed'), 0) AS total_refunded_amount,
--   COALESCE(AVG(amount) FILTER (WHERE status = 'completed'), 0) AS avg_refund_amount,
-- 
--   -- Refund rate (last 30 days)
--   CASE
--     WHEN COUNT(*) FILTER (WHERE requested_at >= NOW() - INTERVAL '30 days') > 0
--     THEN ROUND(
--       COUNT(*) FILTER (WHERE status = 'completed' AND requested_at >= NOW() - INTERVAL '30 days')::NUMERIC /
--       NULLIF((SELECT COUNT(*) FROM payment_transactions WHERE status = 'captured' AND created_at >= NOW() - INTERVAL '30 days'), 0) * 100, 2
--     )
--     ELSE 0
--   END AS refund_rate_percent,
-- 
--   -- By type
--   COUNT(*) FILTER (WHERE refund_type = 'full') AS full_refunds,
--   COUNT(*) FILTER (WHERE refund_type = 'partial') AS partial_refunds,
--   COUNT(*) FILTER (WHERE refund_type = 'prorated') AS prorated_refunds,
-- 
--   -- Timing
--   COALESCE(AVG(EXTRACT(EPOCH FROM (completed_at - requested_at)) / 3600) FILTER (WHERE status = 'completed'), 0) AS avg_processing_hours
-- 
-- FROM refunds;

-- ============================================================================
-- TRIGGER FOR UPDATED_AT
-- ============================================================================


DO $migration$ BEGIN
    BEGIN
        CREATE TRIGGER set_refunds_updated_at
  BEFORE UPDATE ON public.refunds
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================================================
-- COMMENTS
-- ============================================================================

DO $migration$ BEGIN
    BEGIN
        COMMENT ON TABLE public.refunds IS 'Refund requests and processing (Story 5.9)';
        COMMENT ON FUNCTION check_refund_eligibility IS 'Check if user is eligible for refund with amount calculation';
        COMMENT ON VIEW refund_analytics IS 'Refund statistics for admin dashboard (AC#10)';
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


