# Direct SQL Deployment to VPS
# Run this on your local machine to deploy the migration directly to VPS

## Prerequisites
Install PostgreSQL client:
```bash
# Windows (using Chocolatey)
choco install postgresql

# Or download from: https://www.postgresql.org/download/windows/
```

## Step 1: Test Connection

```bash
psql "postgresql://postgres:postgres@89.117.60.144:5432/postgres" -c "SELECT version();"
```

Expected output: PostgreSQL version information

## Step 2: Deploy Migration

```bash
psql "postgresql://postgres:postgres@89.117.60.144:5432/postgres" -f "packages/supabase/supabase/migrations/009_video_jobs.sql"
```

## Step 3: Verify Tables Created

```bash
psql "postgresql://postgres:postgres@89.117.60.144:5432/postgres" -c "
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('jobs', 'job_queue_config');
"
```

Expected output:
```
     table_name      
---------------------
 jobs
 job_queue_config
```

## Step 4: Verify Functions Created

```bash
psql "postgresql://postgres:postgres@89.117.60.144:5432/postgres" -c "
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('update_queue_positions', 'get_queue_stats');
"
```

Expected output:
```
      routine_name       
-------------------------
 update_queue_positions
 get_queue_stats
```

## Step 5: Check Default Config

```bash
psql "postgresql://postgres:postgres@89.117.60.144:5432/postgres" -c "SELECT * FROM job_queue_config;"
```

Expected output: One row with default configuration values

## Step 6: Insert Test Job

```bash
psql "postgresql://postgres:postgres@89.117.60.144:5432/postgres" -c "
INSERT INTO jobs (job_type, priority, status, payload) 
VALUES ('doubt', 'high', 'queued', '{\"question\": \"Test deployment\"}') 
RETURNING id, job_type, priority, status, queue_position;
"
```

## Step 7: Check Queue Statistics

```bash
psql "postgresql://postgres:postgres@89.117.60.144:5432/postgres" -c "SELECT * FROM get_queue_stats();"
```

## Troubleshooting

### Connection Refused
- Check firewall: Port 5432 should be open
- Verify Supabase is running: `curl http://89.117.60.144:3000`

### Authentication Failed
- Default Supabase password might be different
- Check Supabase configuration files on VPS

### Tables Already Exist
- Drop existing tables:
```bash
psql "postgresql://postgres:postgres@89.117.60.144:5432/postgres" -c "
DROP TABLE IF EXISTS jobs CASCADE;
DROP TABLE IF EXISTS job_queue_config CASCADE;
DROP FUNCTION IF EXISTS update_queue_positions CASCADE;
DROP FUNCTION IF EXISTS get_queue_stats CASCADE;
"
```
- Then re-run the migration

## Windows PowerShell Alternative

If bash doesn't work, use PowerShell:

```powershell
# Test connection
& "C:\Program Files\PostgreSQL\16\bin\psql.exe" -h 89.117.60.144 -p 5432 -U postgres -d postgres -c "SELECT version();"

# Deploy migration
& "C:\Program Files\PostgreSQL\16\bin\psql.exe" -h 89.117.60.144 -p 5432 -U postgres -d postgres -f "packages\supabase\supabase\migrations\009_video_jobs.sql"

# Verify
& "C:\Program Files\PostgreSQL\16\bin\psql.exe" -h 89.117.60.144 -p 5432 -U postgres -d postgres -c "SELECT * FROM job_queue_config;"
```

## Success Criteria

✅ Connection to VPS database successful
✅ Migration executed without errors
✅ Tables `jobs` and `job_queue_config` exist
✅ Functions `update_queue_positions` and `get_queue_stats` exist
✅ Default config row inserted
✅ Test job can be inserted
✅ Queue statistics can be retrieved

## Next Steps

After successful SQL deployment:
1. Deploy Edge Function (video-queue-worker)
2. Set up cron job
3. Deploy admin dashboard
4. Test end-to-end workflow
