const { readFileSync } = require('fs');
const https = require('http');

const SUPABASE_URL = 'http://89.117.60.144:54321';
const SUPABASE_SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU';

console.log('=====================================');
console.log('Applying Migration 023 - Study Schedules');
console.log('=====================================\n');

const migrationSQL = readFileSync('packages/supabase/supabase/migrations/023_study_schedules.sql', 'utf8');

const postData = JSON.stringify({ query: migrationSQL });

const options = {
  hostname: '89.117.60.144',
  port: 54321,
  path: '/rest/v1/rpc/exec',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'apikey': SUPABASE_SERVICE_KEY,
    'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
    'Content-Length': Buffer.byteLength(postData)
  }
};

const req = https.request(options, (res) => {
  let data = '';

  res.on('data', (chunk) => {
    data += chunk;
  });

  res.on('end', () => {
    if (res.statusCode === 200 || res.statusCode === 201) {
      console.log('✓ Migration executed successfully!\n');
      console.log('Tables created:');
      console.log('  ✓ study_schedules');
      console.log('  ✓ schedule_tasks\n');
      process.exit(0);
    } else {
      console.error(`Error: HTTP ${res.statusCode}`);
      console.error(data);
      console.log('\nManual application required:');
      console.log('1. Open: http://89.117.60.144:3000');
      console.log('2. Go to SQL Editor');
      console.log('3. Execute: packages/supabase/supabase/migrations/023_study_schedules.sql');
      process.exit(1);
    }
  });
});

req.on('error', (e) => {
  console.error(`Error: ${e.message}`);
  process.exit(1);
});

req.write(postData);
req.end();
