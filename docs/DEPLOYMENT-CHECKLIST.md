# Video Queue Management - Complete Deployment Checklist

**VPS:** 89.117.60.144  
**Date:** December 24, 2025  
**Story:** 4.10 - Video Generation Queue Management

---

## Pre-Deployment Checklist

- [x] VPS accessible via SSH (port 22)
- [x] Supabase running on VPS (port 3000, 54321)
- [x] PostgreSQL accessible (port 5432)
- [x] Firewall configured correctly
- [x] PostgreSQL client installed locally

---

## Phase 1: Database Migration (15 minutes)

### 1.1 Test Database Connection
```bash
psql "postgresql://postgres:postgres@89.117.60.144:5432/postgres" -c "SELECT version();"
```
- [x] Connection successful
- [x] PostgreSQL version displayed

### 1.2 Deploy Migration
```bash
cd "e:\BMAD method\BMAD 4"
psql "postgresql://postgres:postgres@89.117.60.144:5432/postgres" -f "packages\supabase\supabase\migrations\009_video_jobs.sql"
```
- [x] Migration executed without errors
- [x] No error messages displayed

### 1.3 Verify Tables
```bash
psql "postgresql://postgres:postgres@89.117.60.144:5432/postgres" -c "\dt"
```
- [x] `jobs` table exists
- [x] `job_queue_config` table exists

### 1.4 Verify Functions
```bash
psql "postgresql://postgres:postgres@89.117.60.144:5432/postgres" -c "\df"
```
- [x] `update_queue_positions()` function exists
- [x] `get_queue_stats()` function exists

### 1.5 Check Default Config
```bash
psql "postgresql://postgres:postgres@89.117.60.144:5432/postgres" -c "SELECT * FROM job_queue_config;"
```
- [x] One config row exists
- [x] max_concurrent_renders = 10
- [x] max_manim_renders = 4
- [x] job_timeout_minutes = 10

### 1.6 Test Insert
```bash
psql "postgresql://postgres:postgres@89.117.60.144:5432/postgres" -c "
INSERT INTO jobs (job_type, priority, status, payload)
VALUES ('doubt', 'high', 'queued', '{\"test\": true}')
RETURNING id, queue_position;
"
```
- [x] Job inserted successfully
- [x] queue_position = 1

---

## Phase 2: Edge Function Deployment (20 minutes)

### 2.1 Prepare Supabase CLI
```bash
# Install Supabase CLI if not installed
npm install -g supabase

# Login to Supabase
supabase login
```
- [ ] Supabase CLI installed
- [ ] Logged in successfully

### 2.2 Link to Project
```bash
cd packages/supabase
supabase link --project-ref your-project-ref
```
- [ ] Project linked successfully

### 2.3 Deploy Worker Function
```bash
supabase functions deploy video-queue-worker --no-verify-jwt
```
- [ ] Function deployed successfully
- [ ] No deployment errors

### 2.4 Test Worker Function
```bash
curl -X POST http://89.117.60.144:54321/functions/v1/video-queue-worker \
  -H "Authorization: Bearer YOUR_ANON_KEY"
```
- [ ] Function responds with 200 OK
- [ ] Response: `{"success": true}`

---

## Phase 3: Cron Job Setup (10 minutes)

### Option A: Supabase Dashboard Cron

1. Open Supabase Studio: http://89.117.60.144:3000
2. Navigate to: Edge Functions → video-queue-worker
3. Click "Add Cron Schedule"
4. Enter: `*/1 * * * *` (every minute)
5. Save

- [ ] Cron schedule added in dashboard
- [ ] Schedule shows as active

### Option B: System Cron (Alternative)

SSH to VPS and add cron:
```bash
ssh root@89.117.60.144
crontab -e

# Add this line:
*/1 * * * * curl -X POST http://localhost:54321/functions/v1/video-queue-worker -H "Authorization: Bearer YOUR_SERVICE_KEY" >> /var/log/queue-worker.log 2>&1
```
- [ ] Cron job added
- [ ] Log file created

---

## Phase 4: Admin Dashboard Deployment (15 minutes)

### 4.1 Build Admin App
```bash
cd apps/admin
npm install
npm run build
```
- [ ] Dependencies installed
- [ ] Build successful

### 4.2 Deploy to VPS
```bash
# Copy build to VPS
scp -r .next root@89.117.60.144:/var/www/admin/

# Or use your deployment method (Vercel, Coolify, etc.)
```
- [ ] Files copied to VPS
- [ ] Admin app accessible

### 4.3 Configure Environment Variables
Create `.env.local` on VPS:
```bash
NEXT_PUBLIC_SUPABASE_URL=http://89.117.60.144:54321
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-key
```
- [ ] Environment variables set
- [ ] App can connect to Supabase

### 4.4 Access Dashboard
Navigate to: http://89.117.60.144:8000/queue/monitoring (or your admin URL)
- [ ] Dashboard loads successfully
- [ ] Statistics displayed
- [ ] Real-time updates working

---

## Phase 5: Integration Testing (20 minutes)

### 5.1 Test Job Submission
```bash
psql "postgresql://postgres:postgres@89.117.60.144:5432/postgres" -c "
INSERT INTO jobs (job_type, priority, status, payload, user_id) 
VALUES 
  ('doubt', 'high', 'queued', '{\"question\": \"Test 1\"}', gen_random_uuid()),
  ('topic_short', 'medium', 'queued', '{\"topic\": \"Test 2\"}', gen_random_uuid()),
  ('daily_ca', 'low', 'queued', '{\"date\": \"2025-12-24\"}', gen_random_uuid());
"
```
- [ ] 3 jobs inserted
- [ ] Queue positions assigned correctly (1, 2, 3)

### 5.2 Verify Queue Processing
Wait 2 minutes, then check:
```bash
psql "postgresql://postgres:postgres@89.117.60.144:5432/postgres" -c "
SELECT id, job_type, priority, status, queue_position, retry_count 
FROM jobs 
ORDER BY created_at DESC 
LIMIT 5;
"
```
- [ ] Jobs status changed from 'queued' to 'processing' or 'completed'
- [ ] Worker is processing jobs

### 5.3 Test Queue Statistics
```bash
psql "postgresql://postgres:postgres@89.117.60.144:5432/postgres" -c "SELECT * FROM get_queue_stats();"
```
- [ ] Statistics returned
- [ ] Counts are accurate

### 5.4 Test Priority Ordering
Insert jobs and verify high priority processed first:
```bash
psql "postgresql://postgres:postgres@89.117.60.144:5432/postgres" -c "
INSERT INTO jobs (job_type, priority, status, payload) 
VALUES 
  ('daily_ca', 'low', 'queued', '{}'),
  ('doubt', 'high', 'queued', '{}'),
  ('topic_short', 'medium', 'queued', '{}');

SELECT job_type, priority, queue_position 
FROM jobs 
WHERE status = 'queued' 
ORDER BY queue_position;
"
```
- [ ] High priority job has lowest queue_position
- [ ] Order: high → medium → low

### 5.5 Test Timeout Handling
Insert a job and manually set old started_at:
```bash
psql "postgresql://postgres:postgres@89.117.60.144:5432/postgres" -c "
INSERT INTO jobs (job_type, priority, status, payload, started_at) 
VALUES ('doubt', 'high', 'processing', '{}', NOW() - INTERVAL '15 minutes');
"
```
Wait 1 minute for worker to run, then check:
```bash
psql "postgresql://postgres:postgres@89.117.60.144:5432/postgres" -c "
SELECT status, retry_count, error_message 
FROM jobs 
WHERE started_at < NOW() - INTERVAL '10 minutes';
"
```
- [ ] Job status changed to 'queued' or 'failed'
- [ ] retry_count incremented
- [ ] error_message contains timeout info

### 5.6 Test Retry Logic
Check that failed jobs retry:
```bash
psql "postgresql://postgres:postgres@89.117.60.144:5432/postgres" -c "
SELECT id, status, retry_count, max_retries 
FROM jobs 
WHERE retry_count > 0;
"
```
- [ ] Jobs with retry_count > 0 exist
- [ ] Jobs retry up to max_retries (3)

---

## Phase 6: Monitoring Setup (10 minutes)

### 6.1 Check Worker Logs
```bash
# If using Supabase Dashboard
# Go to: Edge Functions → video-queue-worker → Logs

# If using system cron
tail -f /var/log/queue-worker.log
```
- [ ] Logs are being generated
- [ ] No error messages
- [ ] Processing messages visible

### 6.2 Set Up Alerts (Optional)
Configure alerts for:
- Queue depth > 50
- Failed jobs > 10 per hour
- Average wait time > 15 minutes

- [ ] Alerts configured
- [ ] Test alert triggered

### 6.3 Dashboard Monitoring
Access: http://89.117.60.144:8000/queue/monitoring
- [ ] Real-time statistics updating
- [ ] Priority breakdown visible
- [ ] Recent jobs table populated
- [ ] No console errors

---

## Phase 7: Performance Tuning (15 minutes)

### 7.1 Adjust Concurrency (if needed)
```bash
psql "postgresql://postgres:postgres@89.117.60.144:5432/postgres" -c "
UPDATE job_queue_config 
SET max_concurrent_renders = 15,
    max_manim_renders = 6
WHERE id = (SELECT id FROM job_queue_config LIMIT 1);
"
```
- [ ] Config updated
- [ ] Worker respects new limits

### 7.2 Configure Peak Hours
```bash
psql "postgresql://postgres:postgres@89.117.60.144:5432/postgres" -c "
UPDATE job_queue_config 
SET peak_hour_start = '06:00',
    peak_hour_end = '23:00',
    peak_worker_multiplier = 2.0;
"
```
- [ ] Peak hours configured
- [ ] Multiplier set

### 7.3 Monitor VPS Resources
```bash
ssh root@89.117.60.144
htop
# Check CPU and memory usage
```
- [ ] CPU usage acceptable (< 80%)
- [ ] Memory usage acceptable (< 80%)
- [ ] No resource bottlenecks

---

## Phase 8: Documentation & Handoff (10 minutes)

### 8.1 Update Documentation
- [ ] Deployment guide updated with actual values
- [ ] Quick reference updated
- [ ] Known issues documented

### 8.2 Create Runbook
Document common operations:
- [ ] How to restart worker
- [ ] How to clear stuck jobs
- [ ] How to adjust limits
- [ ] Emergency procedures

### 8.3 Team Training
- [ ] Demo dashboard to team
- [ ] Explain monitoring metrics
- [ ] Share troubleshooting guide

---

## Post-Deployment Verification (24 hours)

### Day 1 Checks
- [ ] Monitor queue depth every 4 hours
- [ ] Check for failed jobs
- [ ] Verify retry logic working
- [ ] Review worker logs

### Week 1 Checks
- [ ] Analyze throughput metrics
- [ ] Review average wait times
- [ ] Check for timeout patterns
- [ ] Optimize concurrency limits

---

## Rollback Plan (If Needed)

### Emergency Rollback
```bash
# Stop cron job
crontab -e  # Comment out the line

# Disable worker
supabase functions delete video-queue-worker

# Drop tables (CAUTION!)
psql "postgresql://postgres:postgres@89.117.60.144:5432/postgres" -c "
DROP TABLE IF EXISTS jobs CASCADE;
DROP TABLE IF EXISTS job_queue_config CASCADE;
"
```

---

## Success Criteria

✅ All database tables created
✅ All functions deployed
✅ Worker processing jobs automatically
✅ Cron job running every minute
✅ Dashboard accessible and updating
✅ Priority ordering working
✅ Timeout handling functional
✅ Retry logic operational
✅ No critical errors in logs
✅ VPS resources within limits

---

## Support Contacts

- **Database Issues:** Check Supabase logs
- **Worker Issues:** Check Edge Function logs
- **Dashboard Issues:** Check browser console
- **VPS Issues:** SSH to 89.117.60.144

---

**Deployment Status:** [ ] Not Started | [ ] In Progress | [ ] Complete | [ ] Rolled Back

**Deployed By:** _________________  
**Deployment Date:** _________________  
**Sign-off:** _________________
