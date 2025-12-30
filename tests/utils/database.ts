/**
 * Database Test Utilities
 */

import { createClient } from '@supabase/supabase-js';

const testSupabaseUrl = process.env.TEST_SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL;
const testSupabaseKey = process.env.TEST_SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY;

export const testSupabase = createClient(testSupabaseUrl!, testSupabaseKey!);

export async function resetTestDatabase() {
  // Tables in reverse dependency order
  const tables = [
    'video_renders',
    'jobs',
    'practice_sessions',
    'answer_submissions',
    'comprehensive_notes',
    'daily_updates',
    'knowledge_chunks',
    'pdf_uploads',
    'syllabus_progress',
    'user_profiles',
    'users',
    'subscriptions',
    'entitlements',
  ];

  for (const table of tables) {
    await testSupabase.from(table).delete().neq('id', '00000000-0000-0000-0000-000000000000');
  }
}

export async function seedTestData() {
  // Create test user
  const { data: testUser, error: userError } = await testSupabase.auth.admin.createUser({
    email: 'test-free@example.com',
    password: 'test-password-123',
    email_confirm: true,
    user_metadata: { full_name: 'Test User' },
  });

  if (userError) {
    console.warn('Test user creation warning:', userError.message);
  }

  // Seed syllabus nodes
  await testSupabase.from('syllabus_nodes').insert([
    { code: 'GS1', name: 'General Studies 1', paper: 'GS1', topic: 'Overview', depth: 0 },
    { code: 'GS1-HIST', name: 'Indian History', paper: 'GS1', topic: 'History', parent_id: 'GS1', depth: 1 },
    { code: 'GS1-HIST-MED', name: 'Medieval History', paper: 'GS1', topic: 'History', parent_id: 'GS1-HIST', depth: 2 },
  ]);

  // Seed plans
  await testSupabase.from('plans').upsert([
    { code: 'free', name: 'Free', price_monthly: 0, features: {} },
    { code: 'pro', name: 'Pro', price_monthly: 599, features: {} },
  ]);

  console.log('Test data seeded successfully');
}
