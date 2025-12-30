-- Migration: 002_entitlement_functions.sql
-- Description: Functions for entitlement checking and usage tracking
-- Date: December 25, 2025

-- Clean up functions first to handle return type changes
DROP FUNCTION IF EXISTS increment_entitlement_usage(UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS check_feature_access(UUID, TEXT) CASCADE;

-- Function to increment entitlement usage
DO $migration$ BEGIN
    BEGIN
        CREATE OR REPLACE FUNCTION increment_entitlement_usage(
  p_user_id UUID,
  p_feature_slug TEXT
)
RETURNS void AS $$
BEGIN
  -- Update usage count
  UPDATE entitlements
  SET usage_count = usage_count + 1,
      updated_at = NOW()
  WHERE user_id = p_user_id
    AND feature_slug = p_feature_slug;

  -- If no entitlement exists, create one (free tier default)
  IF NOT FOUND THEN
    INSERT INTO entitlements (user_id, feature_slug, limit_type, limit_value, usage_count, last_reset_at)
    VALUES (p_user_id, p_feature_slug, 'daily', 3, 1, NOW());
  END IF;
EXCEPTION
  WHEN undefined_table OR undefined_column THEN
    -- Handle case where tables don't exist yet
    RAISE NOTICE 'Entitlements table not yet available, skipping increment: %', SQLERRM;
    RETURN;
END;
$$ LANGUAGE plpgsql;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

-- Function to check if feature is allowed
CREATE OR REPLACE FUNCTION check_feature_access(
  p_user_id UUID,
  p_feature_slug TEXT
)
RETURNS TABLE (
  allowed BOOLEAN,
  reason TEXT,
  usage_count INTEGER,
  limit_value INTEGER
) AS $$
DECLARE
  v_subscription RECORD;
  v_entitlement RECORD;
  v_now TIMESTAMPTZ := NOW();
BEGIN
  -- Check subscription
  SELECT * INTO v_subscription
  FROM subscriptions
  WHERE user_id = p_user_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'no_subscription', 0, 0;
    RETURN;
  END IF;

  -- Active trial
  IF v_subscription.status = 'trial' AND v_now < v_subscription.trial_expires_at THEN
    RETURN QUERY SELECT true, 'trial_active', 0, 0;
    RETURN;
  END IF;

  -- Active subscription
  IF v_subscription.status = 'active' AND v_now < v_subscription.subscription_expires_at THEN
    RETURN QUERY SELECT true, 'subscription_active', 0, 0;
    RETURN;
  END IF;

  -- Free tier - check limits
  SELECT * INTO v_entitlement
  FROM entitlements
  WHERE user_id = p_user_id
    AND feature_slug = p_feature_slug;

  IF NOT FOUND THEN
    -- Create default free tier entitlement
    INSERT INTO entitlements (user_id, feature_slug, limit_type, limit_value, usage_count, last_reset_at)
    VALUES (p_user_id, p_feature_slug, 'daily', 3, 0, v_now);

    RETURN QUERY SELECT true, 'free_tier', 0, 3;
    RETURN;
  END IF;

  -- Check if usage is within limit
  IF v_entitlement.limit_type = 'unlimited' THEN
    RETURN QUERY SELECT true, 'unlimited', v_entitlement.usage_count, v_entitlement.limit_value;
    RETURN;
  END IF;

  IF v_entitlement.usage_count < v_entitlement.limit_value THEN
    RETURN QUERY SELECT true, 'within_limit', v_entitlement.usage_count, v_entitlement.limit_value;
    RETURN;
  END IF;

  -- Limit reached
  RETURN QUERY SELECT false, 'limit_reached', v_entitlement.usage_count, v_entitlement.limit_value;
EXCEPTION
  WHEN undefined_table OR undefined_column THEN
    -- Handle case where tables don't exist yet
    RETURN QUERY SELECT false, 'tables_not_available', 0, 0;
    RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;



