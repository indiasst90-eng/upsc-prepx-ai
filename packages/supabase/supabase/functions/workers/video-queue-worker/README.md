# Video Queue Worker

## Overview
This Edge Function manages the video generation queue with priority-based processing, concurrency limits, timeout handling, and retry logic.

## Features
- **Priority-based Queue**: High (doubt), Medium (topic_short), Low (daily_ca)
- **Concurrency Limits**: Max 10 total renders, max 4 Manim renders
- **Timeout Handling**: Auto-fail jobs exceeding 10 minutes
- **Retry Logic**: 3 retries with exponential backoff
- **Peak Hour Scaling**: 1.5x workers during 6-9 AM and 8-11 PM

## Deployment

```bash
cd packages/supabase
supabase functions deploy video-queue-worker
```

## Cron Setup
Configure in Supabase Dashboard → Edge Functions → Cron Jobs:
```
*/1 * * * * # Run every minute
```

## Environment Variables
- `SUPABASE_URL`: Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY`: Service role key

## Testing

```bash
deno test --allow-all index.test.ts
```

## Usage

Jobs are automatically processed from the queue. To enqueue a job:

```typescript
import { enqueueJob } from './actions/queue_management_action.ts';

const job = await enqueueJob(supabase, 'doubt', {
  question: 'What is photosynthesis?',
  userId: 'user-123'
}, 'user-123');
```

## Monitoring
Access the admin dashboard at `/queue/monitoring` to view:
- Queue depth by priority
- Average wait time
- Throughput metrics
- Recent job history
