# Video Queue Management - Deployment Guide

## Prerequisites
- Supabase CLI installed
- Access to Supabase project
- Admin dashboard deployed

## Step 1: Deploy Database Migration

```bash
cd packages/supabase
supabase db push
```

This will create:
- `jobs` table
- `job_queue_config` table
- Indexes for performance
- Queue position update trigger
- Queue statistics function

## Step 2: Verify Migration

```bash
supabase db diff
```

Check that tables exist:
```sql
SELECT * FROM job_queue_config;
SELECT * FROM jobs LIMIT 5;
```

## Step 3: Deploy Queue Worker

```bash
cd packages/supabase
supabase functions deploy video-queue-worker
```

## Step 4: Configure Cron Job

1. Go to Supabase Dashboard
2. Navigate to Edge Functions
3. Select `video-queue-worker`
4. Add Cron Schedule: `*/1 * * * *` (every minute)
5. Save configuration

## Step 5: Test Queue System

### Enqueue a Test Job

```typescript
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

const { data, error } = await supabase.from('jobs').insert({
  job_type: 'doubt',
  priority: 'high',
  status: 'queued',
  payload: { question: 'Test question' },
  retry_count: 0,
  max_retries: 3
});

console.log('Job created:', data);
```

### Monitor Job Processing

```bash
# Check job status
SELECT id, job_type, priority, status, queue_position, created_at 
FROM jobs 
ORDER BY created_at DESC 
LIMIT 10;

# Check queue statistics
SELECT * FROM get_queue_stats();
```

## Step 6: Access Monitoring Dashboard

Navigate to: `https://your-admin-domain.com/queue/monitoring`

You should see:
- Queue statistics (queued, processing, completed, failed)
- Priority breakdown
- Average wait time
- Recent jobs table

## Step 7: Configure Environment Variables

Ensure these are set in Supabase Edge Function secrets:

```bash
supabase secrets set SUPABASE_URL=your-supabase-url
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

## Troubleshooting

### Worker Not Processing Jobs

1. Check cron job is active in Supabase Dashboard
2. View worker logs: `supabase functions logs video-queue-worker`
3. Verify environment variables are set

### Jobs Stuck in Processing

1. Check timeout configuration in `job_queue_config`
2. Manually reset stuck jobs:
```sql
UPDATE jobs 
SET status = 'queued', retry_count = retry_count + 1 
WHERE status = 'processing' 
AND started_at < NOW() - INTERVAL '10 minutes';
```

### High Queue Depth

1. Check concurrency limits in `job_queue_config`
2. Increase `max_concurrent_renders` if VPS can handle more load
3. Monitor VPS resources (CPU, memory)

## Performance Tuning

### Adjust Concurrency Limits

```sql
UPDATE job_queue_config 
SET max_concurrent_renders = 15,
    max_manim_renders = 6
WHERE id = (SELECT id FROM job_queue_config LIMIT 1);
```

### Adjust Peak Hours

```sql
UPDATE job_queue_config 
SET peak_hour_start = '06:00',
    peak_hour_end = '23:00',
    peak_worker_multiplier = 2.0
WHERE id = (SELECT id FROM job_queue_config LIMIT 1);
```

### Adjust Timeout and Retry

```sql
UPDATE job_queue_config 
SET job_timeout_minutes = 15,
    retry_interval_minutes = 3
WHERE id = (SELECT id FROM job_queue_config LIMIT 1);
```

## Monitoring Queries

### Queue Health Check

```sql
SELECT 
  status,
  COUNT(*) as count,
  AVG(EXTRACT(EPOCH FROM (NOW() - created_at)) / 60) as avg_age_minutes
FROM jobs
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY status;
```

### Failed Jobs Analysis

```sql
SELECT 
  job_type,
  error_message,
  COUNT(*) as failure_count
FROM jobs
WHERE status = 'failed'
AND created_at > NOW() - INTERVAL '7 days'
GROUP BY job_type, error_message
ORDER BY failure_count DESC;
```

### Throughput Metrics

```sql
SELECT 
  DATE_TRUNC('hour', completed_at) as hour,
  COUNT(*) as completed_jobs,
  AVG(EXTRACT(EPOCH FROM (completed_at - created_at)) / 60) as avg_processing_time_minutes
FROM jobs
WHERE status = 'completed'
AND completed_at > NOW() - INTERVAL '24 hours'
GROUP BY hour
ORDER BY hour DESC;
```

## Maintenance

### Clean Old Jobs (Run Weekly)

```sql
DELETE FROM jobs 
WHERE status IN ('completed', 'failed', 'cancelled')
AND completed_at < NOW() - INTERVAL '30 days';
```

### Reset Failed Jobs (Manual)

```sql
UPDATE jobs 
SET status = 'queued', 
    retry_count = 0, 
    error_message = NULL 
WHERE status = 'failed' 
AND id IN (SELECT id FROM jobs WHERE status = 'failed' LIMIT 10);
```

## Success Criteria

✅ Migration deployed successfully
✅ Worker deployed and running via cron
✅ Test jobs processed correctly
✅ Monitoring dashboard accessible
✅ Queue statistics updating in real-time
✅ Timeout and retry logic working
✅ Peak hour scaling active

## Support

For issues or questions:
1. Check worker logs: `supabase functions logs video-queue-worker`
2. Review queue statistics: `SELECT * FROM get_queue_stats()`
3. Check recent failures: `SELECT * FROM jobs WHERE status = 'failed' ORDER BY updated_at DESC LIMIT 10`
