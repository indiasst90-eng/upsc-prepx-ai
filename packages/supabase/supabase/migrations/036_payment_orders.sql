-- Migration: 036_payment_orders.sql
-- Description: Payment orders table for Razorpay integration
-- Date: December 28, 2025
-- Story: 5.2 - Razorpay Payment Gateway

-- Payment Orders Table
CREATE TABLE IF NOT EXISTS public.payment_orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL ,
  plan_id TEXT NOT NULL,
  amount INTEGER NOT NULL, -- Amount in INR
  currency TEXT DEFAULT 'INR',
  status TEXT DEFAULT 'created' CHECK (status IN ('created', 'paid', 'failed', 'refunded')),
  razorpay_order_id TEXT UNIQUE,
  razorpay_payment_id TEXT,
  error_message TEXT,
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add Razorpay fields to subscriptions table if not exists
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'subscriptions' AND column_name = 'razorpay_subscription_id') THEN
    ALTER TABLE public.subscriptions ADD COLUMN razorpay_subscription_id TEXT;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'subscriptions' AND column_name = 'razorpay_customer_id') THEN
    ALTER TABLE public.subscriptions ADD COLUMN razorpay_customer_id TEXT;
  END IF;
END $$;

-- Add Razorpay fields to invoices table if it exists
DO $$
BEGIN
  -- Only add columns if invoices table exists
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'invoices' AND table_schema = 'public') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'invoices' AND column_name = 'razorpay_payment_id') THEN
      ALTER TABLE public.invoices ADD COLUMN razorpay_payment_id TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'invoices' AND column_name = 'razorpay_order_id') THEN
      ALTER TABLE public.invoices ADD COLUMN razorpay_order_id TEXT;
    END IF;
  END IF;
END $$;

-- Indexes
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_payment_orders_user ON public.payment_orders(user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_payment_orders_status ON public.payment_orders(status);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_payment_orders_razorpay ON public.payment_orders(razorpay_order_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- RLS Policies
DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.payment_orders ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can view own orders" ON public.payment_orders
  FOR SELECT USING (auth.uid() = user_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Service role can manage orders" ON public.payment_orders
  FOR ALL USING (true);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

COMMENT ON TABLE public.payment_orders IS 'Razorpay payment orders for subscription purchases';


