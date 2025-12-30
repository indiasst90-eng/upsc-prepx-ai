-- Execute migration 021 via Supabase REST API
-- This creates tables, functions, and sample data for Story 5.7

\echo 'Creating payment_transactions table...'
CREATE TABLE IF NOT EXISTS public.payment_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  plan_id UUID REFERENCES public.plans(id),
  razorpay_order_id TEXT UNIQUE,
  razorpay_payment_id TEXT UNIQUE,
  razorpay_subscription_id TEXT,
  razorpay_signature TEXT,
  amount_inr INTEGER NOT NULL,
  currency TEXT DEFAULT 'INR',
  status TEXT NOT NULL CHECK (status IN ('created', 'authorized', 'captured', 'failed', 'refunded', 'pending')),
  payment_method TEXT,
  coupon_code TEXT,
  discount_amount INTEGER DEFAULT 0,
  final_amount INTEGER NOT NULL,
  invoice_id TEXT,
  invoice_url TEXT,
  gst_amount INTEGER DEFAULT 0,
  error_code TEXT,
  error_description TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  captured_at TIMESTAMPTZ,
  refunded_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_payment_transactions_user ON public.payment_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_status ON public.payment_transactions(status);
ALTER TABLE public.payment_transactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own transactions" ON public.payment_transactions FOR SELECT USING (auth.uid() = user_id);
