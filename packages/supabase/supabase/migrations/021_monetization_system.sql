-- Migration: 021_monetization_system.sql
-- Description: Complete monetization system for Stories 5.2-5.10
-- Author: Dev Agent (BMAD)
-- Date: December 27, 2025
-- Stories: 5.2 (Razorpay), 5.3 (Trial), 5.4 (Entitlements), 5.5-5.10

-- ============================================================================
-- STORY 5.2: PAYMENT TRANSACTIONS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.payment_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL ,
  plan_id UUID REFERENCES public.plans(id),

  -- Razorpay Fields
  razorpay_order_id TEXT UNIQUE,
  razorpay_payment_id TEXT UNIQUE,
  razorpay_subscription_id TEXT,
  razorpay_signature TEXT,

  -- Payment Details
  amount_inr INTEGER NOT NULL,
  currency TEXT DEFAULT 'INR',
  status TEXT NOT NULL CHECK (status IN ('created', 'authorized', 'captured', 'failed', 'refunded', 'pending')),
  payment_method TEXT, -- 'card', 'upi', 'netbanking', 'wallet'

  -- Coupon/Discount
  coupon_code TEXT,
  discount_amount INTEGER DEFAULT 0,
  final_amount INTEGER NOT NULL,

  -- Invoice
  invoice_id TEXT,
  invoice_url TEXT,
  gst_amount INTEGER DEFAULT 0,

  -- Metadata
  error_code TEXT,
  error_description TEXT,
  metadata JSONB DEFAULT '{}',

  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  captured_at TIMESTAMPTZ,
  refunded_at TIMESTAMPTZ
);

DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_payment_transactions_user ON public.payment_transactions(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_payment_transactions_status ON public.payment_transactions(status);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_payment_transactions_razorpay_order ON public.payment_transactions(razorpay_order_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_payment_transactions_razorpay_payment ON public.payment_transactions(razorpay_payment_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_payment_transactions_created ON public.payment_transactions(created_at DESC);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.payment_transactions ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

DO $$ BEGIN
    
CREATE POLICY "Users can view own transactions"
      ON public.payment_transactions FOR SELECT
      USING (auth.uid() = user_id);
EXCEPTION 
    WHEN duplicate_object THEN NULL;
    WHEN insufficient_privilege THEN NULL;
    WHEN OTHERS THEN NULL;
END $$;

-- ============================================================================
-- STORY 5.4: FEATURE MANIFESTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.feature_manifests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  feature_slug TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  tier TEXT NOT NULL CHECK (tier IN ('free', 'trial', 'pro')),

  -- Limits for free tier
  free_limit_type TEXT CHECK (free_limit_type IN ('unlimited', 'daily', 'monthly', 'total')),
  free_limit_value INTEGER,

  -- Display
  icon TEXT,
  category TEXT,
  sort_order INTEGER DEFAULT 0,

  -- Status
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_feature_manifests_slug ON public.feature_manifests(feature_slug);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_feature_manifests_tier ON public.feature_manifests(tier);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.feature_manifests ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Feature manifests are publicly readable"
  ON public.feature_manifests FOR SELECT
  TO authenticated, anon
  USING (is_active = true);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Seed feature manifests
DO $migration$ BEGIN
    BEGIN
INSERT INTO public.feature_manifests (feature_slug, name, description, tier, free_limit_type, free_limit_value, category, sort_order) VALUES
  ('doubt_videos', 'AI Doubt Video Generator', 'Convert your doubts into personalized video explanations', 'free', 'daily', 3, 'videos', 1),
  ('notes_generation', 'Smart Notes Generator', 'AI-powered comprehensive notes on any topic', 'free', 'daily', 5, 'study', 2),
  ('rag_search', 'Intelligent Knowledge Search', 'Search across all UPSC materials with AI', 'free', 'daily', 10, 'search', 3),
  ('daily_ca_video', 'Daily Current Affairs Video', 'Auto-generated video newspaper', 'trial', NULL, NULL, 'videos', 4),
  ('test_series', 'Test Series & Mock Tests', 'Practice with AI-evaluated tests', 'trial', NULL, NULL, 'practice', 5),
  ('pyq_database', 'PYQ Video Explanations', 'Previous year questions with video solutions', 'trial', NULL, NULL, 'practice', 6),
  ('essay_trainer', 'AI Essay Trainer', 'Practice essay writing with AI feedback', 'pro', NULL, NULL, 'practice', 7),
  ('documentary_lectures', '3-Hour Documentary Lectures', 'In-depth topic documentaries', 'pro', NULL, NULL, 'videos', 8),
  ('interview_prep', 'Live Interview Prep Studio', 'AI-powered mock interviews', 'pro', NULL, NULL, 'practice', 9),
  ('memory_palace', 'Memory Palace Visualizations', 'Mnemonics and memory techniques', 'pro', NULL, NULL, 'study', 10)
ON CONFLICT (feature_slug) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  tier = EXCLUDED.tier;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================================================
-- STORY 5.7: COUPONS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.coupons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT UNIQUE NOT NULL,

  -- Discount
  discount_type TEXT NOT NULL CHECK (discount_type IN ('percent', 'fixed')),
  discount_value INTEGER NOT NULL,

  -- Validity
  valid_from TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  valid_until TIMESTAMPTZ,
  max_uses INTEGER,
  used_count INTEGER DEFAULT 0,

  -- Restrictions
  min_plan TEXT, -- 'monthly', 'quarterly', 'half-yearly', 'annual'
  first_purchase_only BOOLEAN DEFAULT FALSE,
  per_user_limit INTEGER DEFAULT 1,

  -- User-specific
  email_locked TEXT, -- If set, only this email can use

  -- Metadata
  campaign_name TEXT,
  created_by UUID ,
  is_active BOOLEAN DEFAULT TRUE,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_coupons_code ON public.coupons(code);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_coupons_active ON public.coupons(is_active) WHERE is_active = true;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_coupons_valid ON public.coupons(valid_from, valid_until);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.coupons ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Admins can manage coupons"
  ON public.coupons FOR ALL
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
-- STORY 5.7: COUPON USAGE TRACKING
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.coupon_usages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coupon_id UUID NOT NULL REFERENCES public.coupons(id) ON DELETE CASCADE,
  user_id UUID NOT NULL ,
  transaction_id UUID REFERENCES public.payment_transactions(id),
  discount_applied INTEGER NOT NULL,
  used_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE(coupon_id, user_id, transaction_id)
);

DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_coupon_usages_coupon ON public.coupon_usages(coupon_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_coupon_usages_user ON public.coupon_usages(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.coupon_usages ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can view own coupon usage"
  ON public.coupon_usages FOR SELECT
  USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================================================
-- STORY 5.10: REFERRALS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.referrals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  referrer_id UUID NOT NULL ,
  referred_id UUID UNIQUE NOT NULL ,
  referral_code TEXT NOT NULL,

  -- Status
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'signed_up', 'subscribed', 'rewarded')),

  -- Reward tracking
  reward_type TEXT, -- 'free_month', 'discount'
  reward_value INTEGER,
  reward_applied_at TIMESTAMPTZ,

  -- Fraud detection
  ip_address INET,
  device_fingerprint TEXT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_referrals_referrer ON public.referrals(referrer_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_referrals_referred ON public.referrals(referred_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_referrals_code ON public.referrals(referral_code);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_referrals_status ON public.referrals(status);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can view own referrals"
  ON public.referrals FOR SELECT
  USING (auth.uid() = referrer_id OR auth.uid() = referred_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================================================
-- STORY 5.9: SUBSCRIPTION EVENTS TABLE (for lifecycle tracking)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.subscription_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subscription_id UUID NOT NULL REFERENCES public.subscriptions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL ,

  event_type TEXT NOT NULL CHECK (event_type IN (
    'trial_started', 'trial_reminder', 'trial_expired',
    'subscription_created', 'subscription_renewed', 'subscription_canceled',
    'renewal_reminder', 'renewal_failed', 'renewal_success',
    'downgrade_warning', 'downgraded_to_free', 'reactivated'
  )),

  -- Email tracking
  email_sent BOOLEAN DEFAULT FALSE,
  email_sent_at TIMESTAMPTZ,
  email_template TEXT,

  -- Event data
  metadata JSONB DEFAULT '{}',

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_subscription_events_subscription ON public.subscription_events(subscription_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_subscription_events_user ON public.subscription_events(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_subscription_events_type ON public.subscription_events(event_type);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_subscription_events_created ON public.subscription_events(created_at DESC);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.subscription_events ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can view own subscription events"
  ON public.subscription_events FOR SELECT
  USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================================================
-- ADD REFERRAL CODE TO USER PROFILES (Story 5.10)
-- ============================================================================

ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS referral_code TEXT UNIQUE,
  ADD COLUMN IF NOT EXISTS referred_by UUID ;

-- Generate referral code function
DO $migration$ BEGIN
    BEGIN
        CREATE OR REPLACE FUNCTION generate_referral_code()
RETURNS TEXT AS $$
DECLARE
  chars TEXT := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  result TEXT := '';
  i INTEGER;
BEGIN
  FOR i IN 1..6 LOOP
    result := result || substr(chars, floor(random() * length(chars) + 1)::integer, 1);
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Auto-generate referral code on profile creation
DO $migration$ BEGIN
    BEGIN
        CREATE OR REPLACE FUNCTION set_referral_code()
RETURNS TRIGGER AS $$
DECLARE
  new_code TEXT;
  code_exists BOOLEAN;
BEGIN
  IF NEW.referral_code IS NULL THEN
    LOOP
      new_code := generate_referral_code();
      SELECT EXISTS(SELECT 1 FROM user_profiles WHERE referral_code = new_code) INTO code_exists;
      EXIT WHEN NOT code_exists;
    END LOOP;
    NEW.referral_code := new_code;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE TRIGGER set_user_referral_code
  BEFORE INSERT ON public.user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION set_referral_code();
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================================================
-- ADD GRACE PERIOD AND RENEWAL FIELDS TO SUBSCRIPTIONS (Story 5.9)
-- ============================================================================

ALTER TABLE public.subscriptions
  ADD COLUMN IF NOT EXISTS grace_period_ends_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS renewal_attempts INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS last_renewal_attempt_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS razorpay_subscription_id TEXT;

-- ============================================================================
-- ENHANCED ENTITLEMENT CHECK FUNCTION (Story 5.4)
-- ============================================================================

DROP FUNCTION IF EXISTS public.check_entitlement(uuid, text) CASCADE;
CREATE OR REPLACE FUNCTION public.check_entitlement(
  p_user_id UUID,
  p_feature_slug TEXT
)
RETURNS TABLE (
  allowed BOOLEAN,
  reason TEXT,
  show_paywall BOOLEAN,
  upgrade_cta TEXT,
  usage_count INTEGER,
  limit_value INTEGER,
  tier TEXT
) AS $$
DECLARE
  v_subscription RECORD;
  v_entitlement RECORD;
  v_feature RECORD;
  v_now TIMESTAMPTZ := NOW();
BEGIN
  -- Get feature manifest
  SELECT * INTO v_feature
  FROM feature_manifests
  WHERE feature_slug = p_feature_slug AND is_active = true;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'feature_not_found'::TEXT, false, ''::TEXT, 0, 0, 'unknown'::TEXT;
    RETURN;
  END IF;

  -- Get subscription
  SELECT * INTO v_subscription
  FROM subscriptions
  WHERE user_id = p_user_id;

  -- No subscription = treat as free tier expired trial
  IF NOT FOUND THEN
    IF v_feature.tier = 'free' THEN
      RETURN QUERY SELECT true, 'free_tier'::TEXT, false, ''::TEXT, 0, COALESCE(v_feature.free_limit_value, 0), 'free'::TEXT;
    ELSE
      RETURN QUERY SELECT false, 'no_subscription'::TEXT, true, 'Start your 7-day free trial'::TEXT, 0, 0, 'none'::TEXT;
    END IF;
    RETURN;
  END IF;

  -- Active trial
  IF v_subscription.status = 'trial' AND v_now < v_subscription.trial_expires_at THEN
    RETURN QUERY SELECT true, 'trial_active'::TEXT, false, ''::TEXT, 0, 0, 'trial'::TEXT;
    RETURN;
  END IF;

  -- Active subscription
  IF v_subscription.status = 'active' AND v_now < v_subscription.subscription_expires_at THEN
    RETURN QUERY SELECT true, 'subscription_active'::TEXT, false, ''::TEXT, 0, 0, 'pro'::TEXT;
    RETURN;
  END IF;

  -- Grace period (Story 5.9)
  IF v_subscription.grace_period_ends_at IS NOT NULL AND v_now < v_subscription.grace_period_ends_at THEN
    RETURN QUERY SELECT true, 'grace_period'::TEXT, true, 'Update payment method to continue'::TEXT, 0, 0, 'grace'::TEXT;
    RETURN;
  END IF;

  -- Expired/cancelled - check feature tier
  IF v_feature.tier = 'free' THEN
    -- Check free tier limits
    SELECT * INTO v_entitlement
    FROM entitlements
    WHERE user_id = p_user_id AND feature_slug = p_feature_slug;

    IF NOT FOUND THEN
      -- Create default free tier entitlement
      INSERT INTO entitlements (user_id, feature_slug, limit_type, limit_value, usage_count, last_reset_at)
      VALUES (p_user_id, p_feature_slug, COALESCE(v_feature.free_limit_type, 'daily'), COALESCE(v_feature.free_limit_value, 3), 0, v_now)
      ON CONFLICT (user_id, feature_slug) DO NOTHING;

      RETURN QUERY SELECT true, 'free_tier'::TEXT, false, ''::TEXT, 0, COALESCE(v_feature.free_limit_value, 3), 'free'::TEXT;
      RETURN;
    END IF;

    -- Reset daily limits if needed
    IF v_entitlement.limit_type = 'daily' AND v_entitlement.last_reset_at < v_now - INTERVAL '1 day' THEN
      UPDATE entitlements
      SET usage_count = 0, last_reset_at = v_now
      WHERE user_id = p_user_id AND feature_slug = p_feature_slug;

      RETURN QUERY SELECT true, 'free_tier'::TEXT, false, ''::TEXT, 0, v_entitlement.limit_value, 'free'::TEXT;
      RETURN;
    END IF;

    -- Check if within limits
    IF v_entitlement.usage_count < v_entitlement.limit_value THEN
      RETURN QUERY SELECT true, 'within_limit'::TEXT, false, ''::TEXT, v_entitlement.usage_count, v_entitlement.limit_value, 'free'::TEXT;
      RETURN;
    END IF;

    -- Limit reached
    RETURN QUERY SELECT false, 'limit_reached'::TEXT, true, 'Upgrade to Pro for unlimited access'::TEXT, v_entitlement.usage_count, v_entitlement.limit_value, 'free'::TEXT;
    RETURN;
  END IF;

  -- Pro feature, no active subscription
  RETURN QUERY SELECT false, 'subscription_required'::TEXT, true, 'Upgrade to Pro to unlock this feature'::TEXT, 0, 0, 'expired'::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- COUPON VALIDATION FUNCTION (Story 5.7)
-- ============================================================================

DROP FUNCTION IF EXISTS validate_coupon(text, uuid, text, integer) CASCADE;
DROP FUNCTION IF EXISTS validate_coupon(text, uuid, text, integer) CASCADE;
CREATE OR REPLACE FUNCTION validate_coupon(
  p_code TEXT,
  p_user_id UUID,
  p_plan_slug TEXT,
  p_amount INTEGER
)
RETURNS TABLE (
  valid BOOLEAN,
  reason TEXT,
  discount_amount INTEGER,
  final_amount INTEGER,
  coupon_id UUID
) AS $$
DECLARE
  v_coupon RECORD;
  v_usage_count INTEGER;
  v_user_has_subscribed BOOLEAN;
  v_now TIMESTAMPTZ := NOW();
  v_discount INTEGER;
BEGIN
  -- Find coupon
  SELECT * INTO v_coupon
  FROM coupons
  WHERE UPPER(code) = UPPER(p_code) AND is_active = true;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Coupon not found'::TEXT, 0, p_amount, NULL::UUID;
    RETURN;
  END IF;

  -- Check validity dates
  IF v_now < v_coupon.valid_from THEN
    RETURN QUERY SELECT false, 'Coupon not yet valid'::TEXT, 0, p_amount, NULL::UUID;
    RETURN;
  END IF;

  IF v_coupon.valid_until IS NOT NULL AND v_now > v_coupon.valid_until THEN
    RETURN QUERY SELECT false, 'Coupon has expired'::TEXT, 0, p_amount, NULL::UUID;
    RETURN;
  END IF;

  -- Check max uses
  IF v_coupon.max_uses IS NOT NULL AND v_coupon.used_count >= v_coupon.max_uses THEN
    RETURN QUERY SELECT false, 'Coupon usage limit reached'::TEXT, 0, p_amount, NULL::UUID;
    RETURN;
  END IF;

  -- Check per-user limit
  SELECT COUNT(*) INTO v_usage_count
  FROM coupon_usages
  WHERE coupon_id = v_coupon.id AND user_id = p_user_id;

  IF v_usage_count >= v_coupon.per_user_limit THEN
    RETURN QUERY SELECT false, 'You have already used this coupon'::TEXT, 0, p_amount, NULL::UUID;
    RETURN;
  END IF;

  -- Check email lock
  IF v_coupon.email_locked IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = p_user_id AND email = v_coupon.email_locked) THEN
      RETURN QUERY SELECT false, 'This coupon is not valid for your account'::TEXT, 0, p_amount, NULL::UUID;
      RETURN;
    END IF;
  END IF;

  -- Check first purchase only
  IF v_coupon.first_purchase_only THEN
    SELECT EXISTS(
      SELECT 1 FROM payment_transactions
      WHERE user_id = p_user_id AND status = 'captured'
    ) INTO v_user_has_subscribed;

    IF v_user_has_subscribed THEN
      RETURN QUERY SELECT false, 'This coupon is only for first-time subscribers'::TEXT, 0, p_amount, NULL::UUID;
      RETURN;
    END IF;
  END IF;

  -- Check min plan
  IF v_coupon.min_plan IS NOT NULL THEN
    IF p_plan_slug NOT IN ('annual', 'half-yearly', 'quarterly', 'monthly') THEN
      RETURN QUERY SELECT false, 'Invalid plan'::TEXT, 0, p_amount, NULL::UUID;
      RETURN;
    END IF;

    -- Plan hierarchy: monthly < quarterly < half-yearly < annual
    IF v_coupon.min_plan = 'annual' AND p_plan_slug != 'annual' THEN
      RETURN QUERY SELECT false, 'This coupon is only valid for Annual plan'::TEXT, 0, p_amount, NULL::UUID;
      RETURN;
    END IF;
  END IF;

  -- Calculate discount
  IF v_coupon.discount_type = 'percent' THEN
    v_discount := (p_amount * v_coupon.discount_value / 100);
  ELSE
    v_discount := v_coupon.discount_value;
  END IF;

  -- Ensure discount doesn't exceed amount
  v_discount := LEAST(v_discount, p_amount);

  RETURN QUERY SELECT true, 'Coupon applied successfully'::TEXT, v_discount, (p_amount - v_discount), v_coupon.id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- REVENUE ANALYTICS VIEW (Story 5.8)
-- ============================================================================

CREATE OR REPLACE VIEW public.revenue_analytics AS
SELECT
  -- MRR Calculation (Placeholder until plans table schema is aligned)
  0::numeric AS mrr,

  -- Subscription counts
  COUNT(*) FILTER (WHERE s.status = 'active') AS active_subscriptions,
  COUNT(*) FILTER (WHERE s.status = 'trial') AS trial_subscriptions,
  COUNT(*) FILTER (WHERE s.status = 'canceled') AS canceled_subscriptions,
  COUNT(*) FILTER (WHERE s.status = 'expired') AS expired_subscriptions,

  -- Trial metrics
  COUNT(*) FILTER (WHERE s.created_at >= NOW() - INTERVAL '30 days' AND s.status = 'trial') AS trials_last_30_days,

  -- Churn rate (canceled in last 30 days / active at start of period)
  CASE
    WHEN COUNT(*) FILTER (WHERE s.status = 'active' OR s.status = 'canceled') > 0
    THEN ROUND(
      COUNT(*) FILTER (WHERE s.status = 'canceled' AND s.updated_at >= NOW() - INTERVAL '30 days')::NUMERIC /
      NULLIF(COUNT(*) FILTER (WHERE s.status = 'active' OR s.status = 'canceled'), 0) * 100, 2
    )
    ELSE 0
  END AS churn_rate_percent

FROM subscriptions s
LEFT JOIN plans p ON s.plan_id = p.id;

-- ============================================================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================================================


DO $migration$ BEGIN
    BEGIN
        CREATE TRIGGER set_payment_transactions_updated_at
  BEFORE UPDATE ON public.payment_transactions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE TRIGGER set_coupons_updated_at
  BEFORE UPDATE ON public.coupons
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE TRIGGER set_referrals_updated_at
  BEFORE UPDATE ON public.referrals
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================================================
-- SAMPLE COUPONS (Development)
-- ============================================================================

DO $migration$ BEGIN
    BEGIN
INSERT INTO public.coupons (code, discount_type, discount_value, valid_until, max_uses, campaign_name) VALUES
  ('WELCOME20', 'percent', 20, NOW() + INTERVAL '90 days', 1000, 'Welcome Campaign'),
  ('ANNUAL50', 'percent', 50, NOW() + INTERVAL '30 days', 100, 'Annual Promo'),
  ('FLAT100', 'fixed', 100, NOW() + INTERVAL '60 days', 500, 'Flat Discount')
ON CONFLICT (code) DO NOTHING;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================================================
-- COMMENTS
-- ============================================================================

-- COMMENT ON TABLE public.payment_transactions IS 'All payment transactions via Razorpay (Story 5.2)';
-- COMMENT ON TABLE public.feature_manifests IS 'Feature definitions and tier requirements (Story 5.4)';
-- COMMENT ON TABLE public.coupons IS 'Discount coupon definitions (Story 5.7)';
-- COMMENT ON TABLE public.coupon_usages IS 'Coupon redemption tracking (Story 5.7)';
-- COMMENT ON TABLE public.referrals IS 'User referral tracking (Story 5.10)';
-- COMMENT ON TABLE public.subscription_events IS 'Subscription lifecycle events (Story 5.9)';
-- COMMENT ON FUNCTION check_entitlement IS 'Comprehensive entitlement check with paywall info (Story 5.4)';
-- COMMENT ON FUNCTION validate_coupon IS 'Coupon validation with all restriction checks (Story 5.7)';
-- COMMENT ON VIEW revenue_analytics IS 'Real-time revenue metrics for admin dashboard (Story 5.8)';

DO $migration$ BEGIN
    BEGIN
        COMMENT ON TABLE public.payment_transactions IS 'All payment transactions via Razorpay (Story 5.2)';
        COMMENT ON TABLE public.feature_manifests IS 'Feature definitions and tier requirements (Story 5.4)';
        COMMENT ON TABLE public.coupons IS 'Discount coupon definitions (Story 5.7)';
        COMMENT ON TABLE public.coupon_usages IS 'Coupon redemption tracking (Story 5.7)';
        COMMENT ON TABLE public.referrals IS 'User referral tracking (Story 5.10)';
        COMMENT ON TABLE public.subscription_events IS 'Subscription lifecycle events (Story 5.9)';
        COMMENT ON FUNCTION check_entitlement IS 'Comprehensive entitlement check with paywall info (Story 5.4)';
        COMMENT ON FUNCTION validate_coupon IS 'Coupon validation with all restriction checks (Story 5.7)';
        COMMENT ON VIEW revenue_analytics IS 'Real-time revenue metrics for admin dashboard (Story 5.8)';
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


