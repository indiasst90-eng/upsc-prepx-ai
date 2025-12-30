/**
 * Type-safe Environment Configuration
 *
 * This package provides typed environment variables with validation using Zod.
 */

import { z } from 'zod';

// Schema for required environment variables
const requiredEnvSchema = z.object({
  // Supabase
  NEXT_PUBLIC_SUPABASE_URL: z.string().url(),
  NEXT_PUBLIC_SUPABASE_ANON_KEY: z.string().min(1),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1).optional(),

  // A4F
  A4F_API_KEY: z.string().startsWith('ddc-a4f-'),
  A4F_BASE_URL: z.string().url(),

  // VPS Services
  VPS_MANIM_URL: z.string().url(),
  VPS_REVIDEO_URL: z.string().url(),
  VPS_RAG_URL: z.string().url(),
  VPS_SEARCH_URL: z.string().url(),
  VPS_ORCHESTRATOR_URL: z.string().url(),
  VPS_NOTES_URL: z.string().url(),
  VPS_CRAWL4AI_URL: z.string().url().default('http://89.117.60.144:8105'),

  // Application
  NODE_ENV: z.enum(['development', 'staging', 'production']).default('development'),
  NEXT_PUBLIC_APP_URL: z.string().url(),
  NEXT_PUBLIC_ADMIN_URL: z.string().url(),
});

// Schema for optional environment variables
const optionalEnvSchema = z.object({
  // RevenueCat (required for subscription features)
  REVENUECAT_SECRET_API_KEY: z.string().optional(),
  REVENUECAT_PUBLIC_KEY: z.string().optional(),

  // Google Ads API
  GOOGLE_ADS_API_KEY: z.string().optional(),
  GOOGLE_ADS_CLIENT_ID: z.string().optional(),
  GOOGLE_ADS_CLIENT_SECRET: z.string().optional(),

  // Meta (Facebook) Ads API
  META_ADS_ACCESS_TOKEN: z.string().optional(),
  META_ADS_ACCOUNT_ID: z.string().optional(),

  // Optional services
  REDIS_URL: z.string().url().optional(),
  SENTRY_DSN: z.string().optional(),
  AXIOM_TOKEN: z.string().optional(),

  // Feature flags
  ENABLE_DEBUG_MODE: z.boolean().default(false),
  TRIAL_DURATION_DAYS: z.coerce.number().default(7),
  MAX_VIDEO_DURATION_SECONDS: z.coerce.number().default(600),
  RATE_LIMIT_REQUESTS_PER_MINUTE: z.coerce.number().default(100),
});

// Combined schema
const envSchema = requiredEnvSchema.merge(optionalEnvSchema);

// Type inference
export type Env = z.infer<typeof envSchema>;

// Singleton instance
let envInstance: Env | null = null;

/**
 * Get validated environment variables
 * Throws descriptive error if validation fails
 */
export function getEnv(): Env {
  if (envInstance) {
    return envInstance;
  }

  const result = envSchema.safeParse(process.env);

  if (!result.success) {
    const errors = result.error.errors.map(e => `${e.path.join('.')}: ${e.message}`).join('\n');
    throw new Error(`Environment validation failed:\n${errors}`);
  }

  envInstance = result.data;
  return envInstance;
}

/**
 * Check if running on server
 */
export function isServer(): boolean {
  return typeof window === 'undefined';
}

/**
 * Check if running on client
 */
export function isClient(): boolean {
  return typeof window !== 'undefined';
}

/**
 * Get current environment
 */
export function getEnvironment(): 'development' | 'staging' | 'production' {
  return getEnv().NODE_ENV;
}

/**
 * Check if debug mode is enabled
 */
export function isDebugMode(): boolean {
  return getEnv().ENABLE_DEBUG_MODE;
}

// Export individual values for convenience
export const env = {
  // Supabase
  SUPABASE_URL: () => getEnv().NEXT_PUBLIC_SUPABASE_URL,
  SUPABASE_ANON_KEY: () => getEnv().NEXT_PUBLIC_SUPABASE_ANON_KEY,
  SUPABASE_SERVICE_ROLE_KEY: () => getEnv().SUPABASE_SERVICE_ROLE_KEY,

  // A4F
  A4F_API_KEY: () => getEnv().A4F_API_KEY,
  A4F_BASE_URL: () => getEnv().A4F_BASE_URL,

  // VPS
  VPS_MANIM_URL: () => getEnv().VPS_MANIM_URL,
  VPS_REVIDEO_URL: () => getEnv().VPS_REVIDEO_URL,
  VPS_RAG_URL: () => getEnv().VPS_RAG_URL,
  VPS_SEARCH_URL: () => getEnv().VPS_SEARCH_URL,
  VPS_ORCHESTRATOR_URL: () => getEnv().VPS_ORCHESTRATOR_URL,
  VPS_NOTES_URL: () => getEnv().VPS_NOTES_URL,
  VPS_CRAWL4AI_URL: () => getEnv().VPS_CRAWL4AI_URL,

  // RevenueCat
  REVENUECAT_SECRET_API_KEY: () => getEnv().REVENUECAT_SECRET_API_KEY,
  REVENUECAT_PUBLIC_KEY: () => getEnv().REVENUECAT_PUBLIC_KEY,

  // Google Ads
  GOOGLE_ADS_API_KEY: () => getEnv().GOOGLE_ADS_API_KEY,
  GOOGLE_ADS_CLIENT_ID: () => getEnv().GOOGLE_ADS_CLIENT_ID,
  GOOGLE_ADS_CLIENT_SECRET: () => getEnv().GOOGLE_ADS_CLIENT_SECRET,

  // Meta Ads
  META_ADS_ACCESS_TOKEN: () => getEnv().META_ADS_ACCESS_TOKEN,
  META_ADS_ACCOUNT_ID: () => getEnv().META_ADS_ACCOUNT_ID,

  // App
  NODE_ENV: () => getEnv().NODE_ENV,
  NEXT_PUBLIC_APP_URL: () => getEnv().NEXT_PUBLIC_APP_URL,
  NEXT_PUBLIC_ADMIN_URL: () => getEnv().NEXT_PUBLIC_ADMIN_URL,
};
