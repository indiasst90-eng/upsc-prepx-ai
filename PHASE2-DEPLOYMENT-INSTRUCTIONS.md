# Phase 2: Edge Function Deployment Instructions

**VPS:** 89.117.60.144
**Date:** December 24, 2025
**Status:** Ready to Deploy

---

## Overview

This guide will help you deploy the video-queue-worker Edge Function to your self-hosted Supabase instance on the VPS.

---

## Prerequisites Verified

✅ VPS accessible at 89.117.60.144
✅ Supabase API running on port 8001
✅ Supabase Studio accessible on port 3000
✅ Phase 1 (Database Migration) completed
✅ PostgreSQL accessible on port 5432

---

## Deployment Options

### Option A: Using Supabase CLI (Recommended)

**Step 1: Install Supabase CLI** (if not already installed)

```bash
# Windows
npm install -g supabase

# Linux/Mac
brew install supabase/tap/supabase
```

**Step 2: Link to Self-Hosted Instance**

```bash
cd "E:\BMAD method\BMAD 4\packages\supabase"

# Set environment variable for self-hosted
set SUPABASE_URL=http://89.117.60.144:8001
set SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU

# Link project
supabase link --project-ref default
```

**Step 3: Deploy Edge Function**

```bash
cd supabase/functions

# Deploy video-queue-worker
supabase functions deploy video-queue-worker --no-verify-jwt
```

**Step 4: Set Environment Variables**

```bash
supabase secrets set SUPABASE_URL=http://89.117.60.144:8001
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU
```

---

### Option B: Manual Deployment via SSH

**Step 1: SSH into VPS**

```bash
ssh root@89.117.60.144
```

**Step 2: Navigate to Supabase Functions Directory**

```bash
cd /path/to/supabase/functions
# (Exact path depends on your Supabase installation)
```

**Step 3: Create Function Directory**

```bash
mkdir -p workers/video-queue-worker
mkdir -p shared
mkdir -p actions
```

**Step 4: Copy Files from Local Machine**

From your local machine (separate terminal):

```bash
# Copy video-queue-worker
scp "E:\BMAD method\BMAD 4\packages\supabase\supabase\functions\workers\video-queue-worker\index.ts" root@89.117.60.144:/path/to/supabase/functions/workers/video-queue-worker/

# Copy shared utilities
scp "E:\BMAD method\BMAD 4\packages\supabase\supabase\functions\shared\queue-utils.ts" root@89.117.60.144:/path/to/supabase/functions/shared/

# Copy actions
scp "E:\BMAD method\BMAD 4\packages\supabase\supabase\functions\actions\queue_management_action.ts" root@89.117.60.144:/path/to/supabase/functions/actions/
```

**Step 5: Set Environment Variables on VPS**

```bash
# Edit .env or docker-compose.yml
nano /path/to/supabase/.env

# Add these lines:
SUPABASE_URL=http://89.117.60.144:8001
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU
```

**Step 6: Restart Supabase Edge Functions**

```bash
# If using Docker
docker-compose restart supabase-edge-runtime

# Or restart entire Supabase stack
docker-compose restart
```

---

### Option C: Deploy via Coolify Dashboard

**Step 1: Access Coolify**

Navigate to: http://89.117.60.144:8000

**Step 2: Add New Service**

1. Click "New Service"
2. Select "Deno" or "Node.js" runtime
3. Name: `video-queue-worker`

**Step 3: Configure Service**

- **Port:** 54321 (or next available)
- **Environment Variables:**
  - `SUPABASE_URL=http://89.117.60.144:8001`
  - `SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU`

**Step 4: Upload Files**

Upload the following files via Coolify UI:
- `packages/supabase/supabase/functions/workers/video-queue-worker/index.ts`
- `packages/supabase/supabase/functions/shared/queue-utils.ts`
- `packages/supabase/supabase/functions/actions/queue_management_action.ts`

**Step 5: Deploy**

Click "Deploy" in Coolify dashboard.

---

## Testing the Deployment

### Test 1: Check Function Endpoint

```bash
curl -X POST "http://89.117.60.144:8001/functions/v1/video-queue-worker" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU" \
  -H "Content-Type: application/json"
```

**Expected Response:**
```json
{"success": true}
```

### Test 2: Add Test Job to Queue

```bash
curl -X POST "http://89.117.60.144:8001/rest/v1/jobs" \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d '{"job_type":"doubt","priority":"high","status":"queued","payload":{"question":"Test deployment"}}'
```

### Test 3: Check Job Processing

Wait 2 minutes, then check job status:

```bash
curl "http://89.117.60.144:8001/rest/v1/jobs?select=*&order=created_at.desc&limit=5" \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
```

---

## Setting Up Cron Job

### Method 1: System Cron (Linux)

**SSH into VPS:**
```bash
ssh root@89.117.60.144
```

**Edit crontab:**
```bash
crontab -e
```

**Add this line:**
```bash
*/1 * * * * curl -X POST http://localhost:8001/functions/v1/video-queue-worker -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU" >> /var/log/queue-worker.log 2>&1
```

**Verify cron is running:**
```bash
tail -f /var/log/queue-worker.log
```

### Method 2: Supabase Dashboard Cron

1. Navigate to: http://89.117.60.144:3000
2. Go to: Database → Extensions
3. Enable `pg_cron` extension (if available)
4. Run this SQL:

```sql
SELECT cron.schedule(
  'process-video-queue',
  '*/1 * * * *',
  $$
  SELECT net.http_post(
    url := 'http://localhost:8001/functions/v1/video-queue-worker',
    headers := '{"Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"}'::jsonb
  );
  $$
);
```

### Method 3: Docker Container with Cron

Create a separate Docker container that runs cron:

```dockerfile
FROM alpine:latest
RUN apk add --no-cache curl
RUN echo '*/1 * * * * curl -X POST http://89.117.60.144:8001/functions/v1/video-queue-worker -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"' > /etc/crontabs/root
CMD ["crond", "-f"]
```

---

## Verification Checklist

- [ ] Edge Function deployed successfully
- [ ] Function responds to HTTP POST requests
- [ ] Environment variables configured
- [ ] Cron job scheduled (every 1 minute)
- [ ] Test job inserted into queue
- [ ] Worker processes test job within 2 minutes
- [ ] Job status changes from 'queued' to 'processing' to 'completed'
- [ ] No errors in logs

---

## Troubleshooting

### Function Not Found (404)

**Problem:** Edge Function endpoint returns 404

**Solution:**
1. Check function is deployed: `supabase functions list`
2. Verify function path: `/functions/v1/video-queue-worker`
3. Check Supabase logs for deployment errors

### Authentication Error (401)

**Problem:** "Invalid authentication token"

**Solution:**
1. Verify you're using SERVICE_ROLE_KEY, not ANON_KEY
2. Check Authorization header format: `Bearer <key>`
3. Ensure key is correct in environment variables

### Function Timeout

**Problem:** Function takes too long to respond

**Solution:**
1. Check database connection is working
2. Verify `jobs` and `job_queue_config` tables exist
3. Check VPS resource usage (CPU/RAM)
4. Review Edge Function logs

### Cron Not Running

**Problem:** Jobs not being processed automatically

**Solution:**
1. Verify cron service is running: `systemctl status cron`
2. Check cron logs: `tail -f /var/log/queue-worker.log`
3. Test manual execution works first
4. Ensure curl command in cron has full path: `/usr/bin/curl`

---

## Next Steps After Phase 2

Once Phase 2 is complete:

1. **Phase 3:** Deploy Admin Dashboard (monitoring UI)
2. **Phase 4:** Integration Testing (end-to-end workflow)
3. **Phase 5:** Performance Tuning (adjust concurrency limits)
4. **Phase 6:** Production Monitoring (set up alerts)

---

## Support Commands

### View Recent Jobs
```bash
curl "http://89.117.60.144:8001/rest/v1/jobs?select=*&order=created_at.desc&limit=10" \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
```

### View Queue Statistics
```bash
curl -X POST "http://89.117.60.144:8001/rest/v1/rpc/get_queue_stats" \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0" \
  -H "Content-Type: application/json"
```

### Clear All Jobs
```bash
curl -X DELETE "http://89.117.60.144:8001/rest/v1/jobs?id=not.is.null" \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"
```

---

**Deployment Status:** Ready to Execute
**Estimated Time:** 30-45 minutes
**Difficulty:** Medium
