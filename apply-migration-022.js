const { spawn } = require('child_process');
const fs = require('fs');

// VPS SSH Credentials
const VPS = {
  host: '89.117.60.144',
  user: 'root',
  password: '772877mAmcIaS'
};
const migrationPath = 'packages/supabase/supabase/migrations/022_refund_system.sql';
const sql = fs.readFileSync(migrationPath, 'utf8');

console.log('=====================================');
console.log('Applying Migration 022: Refund System');
console.log('=====================================\n');

// Create SSH command to execute SQL on VPS PostgreSQL
const sshCommand = `PGPASSWORD=postgres psql -h 127.0.0.1 -p 54322 -U postgres -d postgres -c "
  COPY (SELECT sql FROM (SELECT '\\$\$' || sql.replace(/'/g, '\\'\\$\\''').replace(/--.*/g, '')
  FROM public.migration_execute
)
  ON STDOUT;
  SELECT '\\\$';
"`;

console.log('[1/3] Connecting to VPS via SSH...');

const ssh = spawn('plink', [
  '-ssh', '-2',
  '-batch',
  '-pw', VPS.password,
  `${VPS.user}@${VPS.host}`,
  sshCommand
], { shell: true });

let output = '';
let error = '';

ssh.stdout.on('data', (data) => {
  output += data;
  process.stdout.write(data);
});

ssh.stderr.on('data', (data) => {
  error += data;
  process.stderr.write(data);
});

ssh.on('close', (code) => {
  console.log('\n=====================================');

  if (code === 0 && !error.includes('ERROR')) {
    console.log('SUCCESS: Migration 022 Applied Successfully!');
    console.log('\nTables created:');
    console.log('  ✓ refunds');
    console.log('  ✓ refund_analytics view');
    console.log('\nFunctions created:');
    console.log('  ✓ check_refund_eligibility()');
    console.log('\nVerification:');
    console.log('Run: SELECT * FROM refunds LIMIT 5;');
    process.exit(0);
  } else {
    console.log('ERROR: Migration Failed');
    console.log(`Exit code: ${code}`);
    if (error) console.log('Error output:', error);

    console.log('\n=====================================');
    console.log('MANUAL APPLICATION REQUIRED:');
    console.log('=====================================\n');
    console.log('Open Supabase Studio: http://89.117.60.144:3000');
    console.log('Go to SQL Editor');
    console.log('Open: packages/supabase/supabase/migrations/022_refund_system.sql');
    console.log('Copy & Paste → Click Run\n');
    process.exit(1);
  }
});

// Also output the SQL file for manual application
console.log('\n=====================================');
console.log('MIGRATION SQL CONTENT:');
console.log('=====================================');
console.log(sql);
console.log('\n=====================================');
