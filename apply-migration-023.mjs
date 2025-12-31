import { createClient } from '@supabase/supabase-js';
import { readFileSync } from 'fs';

const SUPABASE_URL = 'http://89.117.60.144:54321';
const SUPABASE_SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU';

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY, {
  auth: { persistSession: false }
});

console.log('=====================================');
console.log('Applying Migration 023 - Study Schedules');
console.log('=====================================\n');

console.log('[1/3] Reading migration file...');
const migrationSQL = readFileSync('packages/supabase/supabase/migrations/023_study_schedules.sql', 'utf8');
console.log(`      Migration size: ${migrationSQL.length} bytes\n`);

console.log('[2/3] Connecting to VPS database...');
console.log(`      URL: ${SUPABASE_URL}\n`);

console.log('[3/3] Executing migration...');

try {
  const response = await fetch(`${SUPABASE_URL}/rest/v1/rpc/exec`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'apikey': SUPABASE_SERVICE_KEY,
      'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
      'Prefer': 'return=representation'
    },
    body: JSON.stringify({ query: migrationSQL })
  });

  if (!response.ok) {
    const errorText = await response.text();
    
    const { data, error } = await supabase.rpc('query', { 
      query_text: migrationSQL 
    });

    if (error) throw new Error(error.message);
  }

  console.log('      Migration executed successfully!\n');

  console.log('=====================================');
  console.log('SUCCESS: Migration 023 Applied!');
  console.log('=====================================\n');

  console.log('Tables created:');
  console.log('  ✓ study_schedules');
  console.log('  ✓ schedule_tasks\n');

  const { data: schedules, error: verifyError } = await supabase
    .from('study_schedules')
    .select('id')
    .limit(1);

  if (!verifyError) {
    console.log('Verification: Tables accessible ✓\n');
  }

  process.exit(0);

} catch (err) {
  console.error('\n=====================================');
  console.error('ERROR: Migration Failed');
  console.error('=====================================');
  console.error(err.message);
  console.error('\nManual application required:\n');
  console.log('1. Open: http://89.117.60.144:3000');
  console.log('2. Go to SQL Editor');
  console.log('3. Copy contents of: packages/supabase/supabase/migrations/023_study_schedules.sql');
  console.log('4. Paste and execute');

  process.exit(1);
}
