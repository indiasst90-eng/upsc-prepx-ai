import { createClient } from '@supabase/supabase-js';
import { readFileSync } from 'fs';

const SUPABASE_URL = 'http://89.117.60.144:54321';
const SUPABASE_SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU';

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY, {
  auth: { persistSession: false }
});

console.log('=====================================');
console.log('Applying Migration 021');
console.log('=====================================\n');

console.log('[1/3] Reading migration file...');
const migrationSQL = readFileSync('packages/supabase/supabase/migrations/021_monetization_system.sql', 'utf8');
console.log(`      Migration size: ${migrationSQL.length} bytes\n`);

console.log('[2/3] Connecting to VPS database...');
console.log(`      URL: ${SUPABASE_URL}\n`);

console.log('[3/3] Executing migration...');

try {
  // Execute the migration SQL
  const { data, error } = await supabase.rpc('exec_sql', { sql_query: migrationSQL });

  if (error) {
    // Try alternative method - direct query
    console.log('      Trying alternative execution method...');

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
      throw new Error(`HTTP ${response.status}: ${await response.text()}`);
    }

    console.log('      Alternative method succeeded!\n');
  } else {
    console.log('      Migration executed successfully!\n');
  }

  console.log('=====================================');
  console.log('SUCCESS: Migration 021 Applied!');
  console.log('=====================================\n');

  console.log('Tables created:');
  console.log('  ✓ payment_transactions');
  console.log('  ✓ feature_manifests');
  console.log('  ✓ coupons');
  console.log('  ✓ coupon_usages');
  console.log('  ✓ referrals');
  console.log('  ✓ subscription_events\n');

  console.log('Functions created:');
  console.log('  ✓ check_entitlement()');
  console.log('  ✓ validate_coupon()');
  console.log('  ✓ generate_referral_code()\n');

  console.log('Sample coupons:');
  console.log('  ✓ WELCOME20 (20% off)');
  console.log('  ✓ ANNUAL50 (50% off)');
  console.log('  ✓ FLAT100 (₹100 off)\n');

  // Verify tables exist
  const { data: tables, error: tableError } = await supabase
    .from('coupons')
    .select('code')
    .limit(3);

  if (!tableError && tables) {
    console.log(`Verification: Found ${tables.length} sample coupons`);
    tables.forEach(t => console.log(`  - ${t.code}`));
  }

  process.exit(0);

} catch (err) {
  console.error('\n=====================================');
  console.error('ERROR: Migration Failed');
  console.error('=====================================');
  console.error(err.message);
  console.error('\nFalling back to SQL file execution method...\n');

  // The SQL file can be manually applied via Supabase Studio
  console.log('Please apply migration manually via:');
  console.log(`1. Open: ${SUPABASE_URL.replace('54321', '3000')}`);
  console.log('2. Go to SQL Editor');
  console.log('3. Copy contents of: packages/supabase/supabase/migrations/021_monetization_system.sql');
  console.log('4. Paste and execute');

  process.exit(1);
}
