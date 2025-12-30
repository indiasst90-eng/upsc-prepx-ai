# Direct Deployment Guide (No CLI Required)

**For Self-Hosted Supabase on VPS 89.117.60.144**

Since Supabase CLI may not work with self-hosted instances, here's a direct deployment approach.

---

## Quick Start (Recommended Approach)

### Step 1: Create Standalone Edge Function Service

Instead of deploying to Supabase Edge Functions (which is complex for self-hosted), we'll create a standalone Deno service that runs alongside your other VPS services.

**Create on VPS:**

```bash
# SSH into VPS
ssh root@89.117.60.144

# Create directory
mkdir -p /opt/queue-worker
cd /opt/queue-worker
```

### Step 2: Copy Function Files

From your local machine, copy these 3 files to VPS:

```bash
# File 1: Main worker
scp "E:\BMAD method\BMAD 4\packages\supabase\supabase\functions\workers\video-queue-worker\index.ts" root@89.117.60.144:/opt/queue-worker/worker.ts

# File 2: Queue utilities (create combined file)
# We'll create a standalone version below
```

### Step 3: Create Standalone Worker File

On your VPS (`/opt/queue-worker/worker.ts`), create this combined file:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const SUPABASE_URL = "http://localhost:8001";
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU";

// Queue utilities inline
function assignJobPriority(jobType: string): string {
  const priorityMap: Record<string, string> = {
    doubt: "high",
    topic_short: "medium",
    daily_ca: "low",
  };
  return priorityMap[jobType] || "low";
}

function isPeakHour(): boolean {
  const hour = new Date().getHours();
  return (hour >= 6 && hour < 9) || (hour >= 20 && hour < 23);
}

async function handleTimeouts(config: any) {
  const timeoutThreshold = new Date();
  timeoutThreshold.setMinutes(
    timeoutThreshold.getMinutes() - config.job_timeout_minutes
  );

  const response = await fetch(
    `${SUPABASE_URL}/rest/v1/jobs?status=eq.processing&started_at=lt.${timeoutThreshold.toISOString()}`,
    {
      headers: {
        apikey: SUPABASE_KEY,
        Authorization: `Bearer ${SUPABASE_KEY}`,
      },
    }
  );

  const timedOutJobs = await response.json();

  for (const job of timedOutJobs || []) {
    const updateData =
      job.retry_count < job.max_retries
        ? {
            status: "queued",
            retry_count: job.retry_count + 1,
            error_message: "Job timed out, retrying...",
            updated_at: new Date().toISOString(),
          }
        : {
            status: "failed",
            error_message: "Job exceeded maximum timeout",
            completed_at: new Date().toISOString(),
            updated_at: new Date().toISOString(),
          };

    await fetch(`${SUPABASE_URL}/rest/v1/jobs?id=eq.${job.id}`, {
      method: "PATCH",
      headers: {
        apikey: SUPABASE_KEY,
        Authorization: `Bearer ${SUPABASE_KEY}`,
        "Content-Type": "application/json",
        Prefer: "return=minimal",
      },
      body: JSON.stringify(updateData),
    });

    console.log(`Job ${job.id} timeout handled`);
  }
}

async function processQueue(config: any) {
  // Get available render slots
  const processingResponse = await fetch(
    `${SUPABASE_URL}/rest/v1/jobs?status=eq.processing&select=*`,
    {
      headers: {
        apikey: SUPABASE_KEY,
        Authorization: `Bearer ${SUPABASE_KEY}`,
      },
    }
  );

  const processingJobs = await response.json();
  const currentManimJobs = processingJobs.filter((j: any) =>
    j.job_type === "topic_short"
  ).length;
  const totalProcessing = processingJobs.length;

  const maxConcurrent = isPeakHour()
    ? Math.floor(config.max_concurrent_renders * 1.5)
    : config.max_concurrent_renders;

  const availableSlots = maxConcurrent - totalProcessing;

  if (availableSlots <= 0) {
    console.log("No available slots, skipping...");
    return;
  }

  // Get next jobs from queue (FIFO by priority)
  const queueResponse = await fetch(
    `${SUPABASE_URL}/rest/v1/jobs?status=eq.queued&order=priority.desc,queue_position.asc&limit=${availableSlots}`,
    {
      headers: {
        apikey: SUPABASE_KEY,
        Authorization: `Bearer ${SUPABASE_KEY}`,
      },
    }
  );

  const queuedJobs = await queueResponse.json();

  for (const job of queuedJobs || []) {
    // Check Manim limit
    if (job.job_type === "topic_short" && currentManimJobs >= config.max_manim_renders) {
      console.log("Manim render limit reached, skipping Manim job");
      continue;
    }

    // Start processing
    await fetch(`${SUPABASE_URL}/rest/v1/jobs?id=eq.${job.id}`, {
      method: "PATCH",
      headers: {
        apikey: SUPABASE_KEY,
        Authorization: `Bearer ${SUPABASE_KEY}`,
        "Content-Type": "application/json",
        Prefer: "return=minimal",
      },
      body: JSON.stringify({
        status: "processing",
        started_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      }),
    });

    console.log(`Started processing job ${job.id} (${job.job_type})`);

    // TODO: Call actual render services here
    // For now, we just mark as processing
    // In production, you'd call Manim/Revideo services
  }
}

serve(async (req) => {
  try {
    // Get config
    const configResponse = await fetch(
      `${SUPABASE_URL}/rest/v1/job_queue_config?select=*&limit=1`,
      {
        headers: {
          apikey: SUPABASE_KEY,
          Authorization: `Bearer ${SUPABASE_KEY}`,
        },
      }
    );

    const configs = await configResponse.json();
    const config = configs[0];

    if (!config) {
      throw new Error("Queue config not found");
    }

    await handleTimeouts(config);
    await processQueue(config);

    return new Response(JSON.stringify({ success: true }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    console.error("Queue worker error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { "Content-Type": "application/json" },
      status: 500,
    });
  }
}, { port: 8105 });

console.log("Queue Worker running on http://localhost:8105");
```

### Step 4: Run Worker as Service

**Option A: Run with Deno directly**

```bash
deno run --allow-net --allow-env worker.ts
```

**Option B: Create systemd service**

Create `/etc/systemd/system/queue-worker.service`:

```ini
[Unit]
Description=Video Queue Worker
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/queue-worker
ExecStart=/usr/bin/deno run --allow-net --allow-env /opt/queue-worker/worker.ts
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
systemctl enable queue-worker
systemctl start queue-worker
systemctl status queue-worker
```

### Step 5: Set Up Cron Job

```bash
crontab -e
```

Add:
```bash
*/1 * * * * curl -X POST http://localhost:8105 >> /var/log/queue-worker-cron.log 2>&1
```

### Step 6: Test

```bash
# Check worker is running
curl http://localhost:8105

# Check logs
tail -f /var/log/queue-worker-cron.log

# Add test job
curl -X POST "http://localhost:8001/rest/v1/jobs" \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d '{"job_type":"doubt","priority":"high","status":"queued","payload":{"question":"Test"}}'
```

---

## Alternative: Deploy via Coolify (Easiest)

1. Access Coolify: http://89.117.60.144:8000
2. Create new "Deno" application
3. Name: `queue-worker`
4. Port: `8105`
5. Paste the worker.ts code above
6. Add environment variables (if needed)
7. Deploy
8. Set up cron to call the service

---

## Files Needed

I'll create a ready-to-deploy standalone worker file for you:

