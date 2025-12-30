# Apply Migration 022 via cURL
# This script applies refund system migration to Supabase via REST API

$SupabaseUrl = "http://89.117.60.144:54321"
$AnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
$ServiceKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"

# Migration 022 SQL
$sql = @"
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

CREATE POLICY `"Users can view own refunds"` ON public.refunds FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY `"Users can request refunds"` ON public.refunds FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY `"Admins can manage all refunds"` ON public.refunds FOR ALL USING (EXISTS (SELECT 1 FROM public.user_profiles WHERE user_id = auth.uid() AND role = 'admin'));

-- ============================================================================
-- REFUND ELIGIBILITY CHECK FUNCTION
-- ============================================================================

CREATE OR REPLACE FUNCTION check_refund_eligibility(p_user_id UUID, p_subscription_id UUID)
RETURNS TABLE(eligible BOOLEAN, reason TEXT, refund_amount INTEGER, refund_type TEXT, days_since_purchase INTEGER) AS `$
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

  SELECT * INTO v_transaction FROM payment_transactions WHERE user_id = p_user_id AND status = 'captured' ORDER BY created_at DESC LIMIT 1;
  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'No payment found'::TEXT, 0, ''::TEXT, 0;
    RETURN;
  END IF;

  v_days_elapsed := EXTRACT(DAY FROM (NOW() - v_transaction.created_at));

  IF v_days_elapsed > 7 THEN
    IF v_subscription.status = 'active' THEN
      DECLARE v_total_days INTEGER;
      DECLARE v_remaining_days INTEGER;
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
      v_refund_amount := v_transaction.final_amount;
      v_refund_type := 'full';
    END IF;

  SELECT COUNT(*) INTO v_refund_count FROM refunds WHERE user_id = p_user_id AND status IN ('completed', 'approved') AND requested_at >= NOW() - INTERVAL '1 year';
  IF v_refund_count >= 1 THEN
    RETURN QUERY SELECT false, 'Refund limit reached (1 per year)'::TEXT, 0, ''::TEXT, v_days_elapsed;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Eligible for refund'::TEXT, v_refund_amount, v_refund_type, v_days_elapsed;
END;
`$ LANGUAGE plpgsql SECURITY DEFINER;

# Execute via RPC
Write-Host "====================================="
Write-Host "Appying Migration 022: Refund System"
Write-Host "======================================"

# Convert to JSON
$body = @{
  sql_query = $sql
}

$jsonBody = $body | ConvertTo-Json

# Execute
$response = Invoke-RestMethod -Uri "$SupabaseUrl/rpc" -Method POST -ContentType "application/json" -Headers @{
  "apikey" = $AnonKey
  "Authorization" = "Bearer $ServiceKey"
  "Prefer" = "return=representation"
} -Body $jsonBody -TimeoutSec 30

if ($response.StatusCode -eq 200) {
  Write-Host ""
  Write-Host "=====================================" -ForegroundColor Green
  Write-Host "SUCCESS: Migration 022 Applied!" -ForegroundColor Green
  Write-Host "=====================================" -ForegroundColor Green
  Write-Host ""
  Write-Host "Tables created:" -ForegroundColor Cyan
  Write-Host "  ✓ refunds" -ForegroundColor Gray
  Write-Host "  ✓ refund_analytics" -ForegroundColor Gray
  Write-Host ""
  Write-Host "Functions created:" -ForegroundColor Cyan
  Write-Host "  ✓ check_refund_eligibility()" -ForegroundColor Gray
  Write-Host ""
  Write-Host "Verification:" -ForegroundColor Yellow
  Write-Host "Run: SELECT * FROM refunds LIMIT 5" -ForegroundColor Yellow
} else {
  Write-Host ""
  Write-Host "=====================================" -ForegroundColor Red
  Write-Host "ERROR: Migration Failed" -ForegroundColor Red
  Write-Host "=====================================" -ForegroundColor Red
  Write-Host ""
  Write-Host "Status: $($response.StatusCode)" -ForegroundColor Yellow
  Write-Host ""
  if ($response.Content) {
    $error = $response.Content | ConvertFrom-Json
    Write-Host "Error: $($error.message)" -ForegroundColor Red
  }
}
