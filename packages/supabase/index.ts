import { createClient } from '@supabase/supabase-js';
import { cookies } from 'next/headers';

// Client-side Supabase client (using ANON key)
export function createBrowserClient() {
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
  const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

  return createClient(supabaseUrl, supabaseAnonKey);
}

// Server-side Supabase client (using SERVICE_ROLE key)
export function createServerClient() {
  const supabaseUrl = process.env.SUPABASE_URL!;
  const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;

  return createClient(supabaseUrl, supabaseServiceKey);
}

// Typed database types (auto-generated schema types would go here)
export type User = {
  id: string;
  email: string;
  created_at: string;
};

export type Subscription = {
  id: string;
  user_id: string;
  plan: 'free' | 'pro' | 'enterprise';
  status: 'active' | 'expired' | 'cancelled';
  start_date: string;
  end_date: string;
};

export type VideoRender = {
  id: string;
  user_id: string;
  type: 'daily_news' | 'doubt_explainer' | 'notes_summary' | 'documentary';
  status: 'queued' | 'processing' | 'completed' | 'failed';
  priority: 'low' | 'medium' | 'high';
  progress: number;
  input_params: Record<string, any>;
  output_url: string | null;
  error_message: string | null;
  created_at: string;
  started_at: string | null;
  completed_at: string | null;
};

// Database table names
export const TABLES = {
  USERS: 'users',
  USER_PROFILES: 'user_profiles',
  SUBSCRIPTIONS: 'subscriptions',
  ENTITLEMENTS: 'entitlements',
  SYLLABUS_NODES: 'syllabus_nodes',
  KNOWLEDGE_CHUNKS: 'knowledge_chunks',
  COMPREHENSIVE_NOTES: 'comprehensive_notes',
  DAILY_UPDATES: 'daily_updates',
  VIDEO_RENDERS: 'video_renders',
  JOBS: 'jobs',
} as const;
