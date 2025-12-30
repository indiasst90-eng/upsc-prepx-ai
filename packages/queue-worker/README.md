# Video Queue Worker

Standalone service that processes video generation jobs from the Supabase queue.

## Features

- ✅ Priority-based job processing (high > medium > low)
- ✅ Concurrency limits (10 concurrent, 4 Manim max)
- ✅ Automatic timeout detection (10 minutes)
- ✅ Retry logic (3 attempts with exponential backoff)
- ✅ Peak hour handling
- ✅ Real-time queue statistics

## Deployment Options

### Option 1: Deploy via Coolify (Recommended)

1. Open Coolify: http://89.117.60.144:8000
2. Create **New Resource** → **Docker Compose**
3. Upload files from this directory
4. Set environment variables:
   - `SUPABASE_URL=http://89.117.60.144:54321`
   - `SUPABASE_SERVICE_ROLE_KEY=<your_key>`
5. Deploy

### Option 2: Deploy via Docker

```bash
# Build image
docker build -t queue-worker .

# Run container
docker run -d \
  --name queue-worker \
  --restart always \
  -e SUPABASE_URL=http://89.117.60.144:54321 \
  -e SUPABASE_SERVICE_ROLE_KEY=<your_key> \
  -e WORKER_INTERVAL_MS=60000 \
  queue-worker
```

### Option 3: Run Directly with Node.js

```bash
# Install dependencies
npm install

# Create .env file
cp .env.example .env
# Edit .env with your credentials

# Start worker
npm start
```

## Configuration

### Environment Variables

- `SUPABASE_URL` - Supabase API URL (default: http://89.117.60.144:54321)
- `SUPABASE_SERVICE_ROLE_KEY` - Service role key for database access (required)
- `WORKER_INTERVAL_MS` - How often to check queue in milliseconds (default: 60000 = 1 minute)

### Queue Configuration

All queue settings are stored in the `job_queue_config` table:

- `max_concurrent_renders` - Maximum concurrent jobs (default: 10)
- `max_manim_renders` - Maximum concurrent Manim jobs (default: 4)
- `job_timeout_minutes` - Job timeout in minutes (default: 10)
- `retry_interval_minutes` - Retry interval in minutes (default: 5)
- `peak_hour_start` - Peak hour start time (default: 06:00)
- `peak_hour_end` - Peak hour end time (default: 21:00)
- `peak_worker_multiplier` - Capacity multiplier during peak (default: 1.5)

## Monitoring

### View Logs

```bash
# Docker
docker logs -f queue-worker

# PM2
pm2 logs queue-worker
```

### Queue Statistics

The worker prints statistics every cycle:

```
📊 Queue Stats:
   Queued: 5
   Processing: 2
   Completed Today: 127
   Failed Today: 3
```

## Integration with Video Services

To integrate with actual video rendering:

1. Modify `processJob()` function in `index.js`
2. Add HTTP calls to:
   - Manim API: http://89.117.60.144:5000
   - Revideo API: http://89.117.60.144:5001
   - Video Orchestrator: http://89.117.60.144:8103

Example:

```javascript
async function processJob(job) {
  if (job.job_type === 'doubt') {
    // Call video orchestrator
    const response = await fetch('http://89.117.60.144:8103/render', {
      method: 'POST',
      body: JSON.stringify(job.payload)
    });

    const result = await response.json();

    // Update job with video URL
    await supabase
      .from('jobs')
      .update({
        status: 'completed',
        payload: { ...job.payload, video_url: result.url }
      })
      .eq('id', job.id);
  }
}
```

## Troubleshooting

### Worker not processing jobs

1. Check database connection:
   ```bash
   curl http://89.117.60.144:54321/rest/v1/jobs?select=id&limit=1 \
     -H "apikey: YOUR_KEY"
   ```

2. Check if jobs exist:
   ```bash
   curl http://89.117.60.144:54321/rest/v1/jobs?status=eq.queued \
     -H "apikey: YOUR_KEY"
   ```

3. Check worker logs for errors

### Jobs stuck in processing

- Worker will automatically timeout jobs after 10 minutes
- Check `job_timeout_minutes` in `job_queue_config`
- Manually reset stuck jobs:
  ```sql
  UPDATE jobs
  SET status = 'queued', retry_count = retry_count + 1
  WHERE status = 'processing' AND started_at < NOW() - INTERVAL '10 minutes';
  ```

## Architecture

```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │ POST /jobs
       ▼
┌─────────────┐
│  Supabase   │◄──────┐
│   (Queue)   │       │
└──────┬──────┘       │
       │              │
       │ SELECT       │ UPDATE
       ▼              │
┌─────────────┐       │
│    Queue    │───────┘
│   Worker    │
└──────┬──────┘
       │
       │ HTTP Calls
       ▼
┌─────────────┐
│   Manim/    │
│  Revideo/   │
│Orchestrator │
└─────────────┘
```

## License

MIT
