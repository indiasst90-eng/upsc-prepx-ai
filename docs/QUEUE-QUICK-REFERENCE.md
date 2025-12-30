# Video Queue System - Quick Reference

## 🚀 Quick Start

### Enqueue a Job

```typescript
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

// Enqueue a doubt video
const { data: job } = await supabase.from('jobs').insert({
  job_type: 'doubt',
  priority: 'high',
  status: 'queued',
  payload: {
    question: 'What is photosynthesis?',
    userId: 'user-123'
  },
  user_id: 'user-123'
}).select().single();

console.log(`Job ${job.id} queued at position ${job.queue_position}`);
```

### Check Job Status

```typescript
const { data: job } = await supabase
  .from('jobs')
  .select('*')
  .eq('id', jobId)
  .single();

console.log(`Status: ${job.status}`);
console.log(`Queue Position: ${job.queue_position}`);
```

### Get Queue Statistics

```typescript
const { data: stats } = await supabase.rpc('get_queue_stats');

console.log(`Queued: ${stats[0].total_queued}`);
console.log(`Processing: ${stats[0].total_processing}`);
console.log(`Avg Wait: ${stats[0].avg_wait_time_minutes} min`);
```

### Cancel a Job

```typescript
await supabase
  .from('jobs')
  .update({ status: 'cancelled' })
  .eq('id', jobId)
  .eq('status', 'queued'); // Only cancel if still queued
```

---

## 📊 Job Types & Priorities

| Job Type | Priority | Use Case | Typical Wait |
|----------|----------|----------|--------------|
| `doubt` | High | User doubt videos | 1-3 min |
| `topic_short` | Medium | 60-sec topic shorts | 3-5 min |
| `daily_ca` | Low | Daily current affairs | 5-10 min |

---

## 🔧 Configuration

### View Current Config

```sql
SELECT * FROM job_queue_config;
```

### Update Concurrency Limits

```sql
UPDATE job_queue_config 
SET max_concurrent_renders = 15,
    max_manim_renders = 6;
```

### Update Peak Hours

```sql
UPDATE job_queue_config 
SET peak_hour_start = '06:00',
    peak_hour_end = '23:00',
    peak_worker_multiplier = 2.0;
```

---

## 📈 Monitoring

### Dashboard
Access: `/queue/monitoring`

### Key Metrics
- **Queue Depth**: Total jobs waiting
- **Processing Count**: Currently rendering
- **Avg Wait Time**: Time from queue to start
- **Throughput**: Jobs completed per hour

### SQL Queries

**Queue Health:**
```sql
SELECT status, COUNT(*) FROM jobs GROUP BY status;
```

**Recent Failures:**
```sql
SELECT * FROM jobs 
WHERE status = 'failed' 
ORDER BY updated_at DESC 
LIMIT 10;
```

**Throughput (Last 24h):**
```sql
SELECT COUNT(*) as completed
FROM jobs 
WHERE status = 'completed' 
AND completed_at > NOW() - INTERVAL '24 hours';
```

---

## 🐛 Troubleshooting

### Jobs Not Processing
1. Check cron job is active
2. View logs: `supabase functions logs video-queue-worker`
3. Verify worker is deployed

### Jobs Stuck in Processing
```sql
-- Reset stuck jobs
UPDATE jobs 
SET status = 'queued', retry_count = retry_count + 1 
WHERE status = 'processing' 
AND started_at < NOW() - INTERVAL '15 minutes';
```

### High Queue Depth
1. Check VPS resources (CPU, memory)
2. Increase concurrency limits
3. Review failed jobs for patterns

---

## 🔄 Job Lifecycle

```
Created → Queued → Processing → Completed
                      ↓
                   Failed → Retry (3x) → Failed (final)
                      ↓
                  Cancelled
```

---

## ⚙️ Default Settings

| Setting | Value | Description |
|---------|-------|-------------|
| Max Concurrent Renders | 10 | Total simultaneous jobs |
| Max Manim Renders | 4 | Manim-specific limit |
| Job Timeout | 10 min | Auto-fail threshold |
| Max Retries | 3 | Retry attempts |
| Retry Interval | 5 min | Time between retries |
| Peak Hours | 6-9 AM, 8-11 PM | High traffic periods |
| Peak Multiplier | 1.5x | Worker scaling factor |

---

## 📞 API Endpoints

### Enqueue Job
```typescript
POST /rest/v1/jobs
Body: {
  job_type: 'doubt',
  priority: 'high',
  status: 'queued',
  payload: { ... },
  user_id: 'user-123'
}
```

### Get Job Status
```typescript
GET /rest/v1/jobs?id=eq.{jobId}
```

### Get Queue Stats
```typescript
POST /rest/v1/rpc/get_queue_stats
```

---

## 🎯 Best Practices

1. **Always set user_id** for tracking
2. **Include error context** in payload
3. **Monitor queue depth** regularly
4. **Clean old jobs** weekly
5. **Tune limits** based on VPS capacity
6. **Log retry attempts** for debugging
7. **Use priority wisely** - don't overuse high priority

---

## 📚 Related Files

- Migration: `packages/supabase/supabase/migrations/009_video_jobs.sql`
- Worker: `packages/supabase/supabase/functions/workers/video-queue-worker/index.ts`
- Utils: `packages/supabase/supabase/functions/shared/queue-utils.ts`
- Dashboard: `apps/admin/src/app/queue/monitoring/page.tsx`
- Docs: `docs/QUEUE-DEPLOYMENT-GUIDE.md`

---

**Need Help?** Check the deployment guide or worker logs for detailed troubleshooting.
