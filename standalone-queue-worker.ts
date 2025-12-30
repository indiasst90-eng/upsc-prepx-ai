// Standalone Video Queue Worker
// Deploy this file to your VPS and run with Deno
// Usage: deno run --allow-net --allow-env standalone-queue-worker.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

// Configuration
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "http://localhost:8001";
const SUPABASE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ||
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU";
const PORT = parseInt(Deno.env.get("PORT") || "8105");

// Types
interface JobQueueConfig {
  max_concurrent_renders: number;
  max_manim_renders: number;
  job_timeout_minutes: number;
  max_retries: number;
  retry_interval_minutes: number;
  peak_hour_start: string;
  peak_hour_end: string;
  peak_worker_multiplier: number;
}

interface VideoJob {
  id: string;
  job_type: string;
  priority: string;
  status: string;
  payload: any;
  retry_count: number;
  max_retries: number;
  started_at?: string;
  completed_at?: string;
  error_message?: string;
  queue_position?: number;
  created_at: string;
  updated_at: string;
}

// Utility Functions
function isPeakHour(): boolean {
  const hour = new Date().getHours();
  // Peak hours: 6-9 AM and 8-11 PM (20-23)
  return (hour >= 6 && hour < 9) || (hour >= 20 && hour < 23);
}

// Database Helper
async function dbFetch(path: string, options: RequestInit = {}) {
  const url = `${SUPABASE_URL}${path}`;
  const headers = {
    apikey: SUPABASE_KEY,
    Authorization: `Bearer ${SUPABASE_KEY}`,
    "Content-Type": "application/json",
    ...options.headers,
  };

  const response = await fetch(url, { ...options, headers });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Database error: ${response.status} - ${text}`);
  }

  const contentType = response.headers.get("content-type");
  if (contentType && contentType.includes("application/json")) {
    return await response.json();
  }

  return null;
}

// Timeout Handler
async function handleTimeouts(config: JobQueueConfig) {
  const timeoutThreshold = new Date();
  timeoutThreshold.setMinutes(
    timeoutThreshold.getMinutes() - config.job_timeout_minutes
  );

  const timedOutJobs = await dbFetch(
    `/rest/v1/jobs?status=eq.processing&started_at=lt.${timeoutThreshold.toISOString()}&select=*`
  );

  let timeoutCount = 0;

  for (const job of (timedOutJobs || [])) {
    const shouldRetry = job.retry_count < job.max_retries;

    const updateData = shouldRetry
      ? {
          status: "queued",
          retry_count: job.retry_count + 1,
          error_message: `Job timed out after ${config.job_timeout_minutes} minutes, retrying... (${job.retry_count + 1}/${job.max_retries})`,
          started_at: null,
          updated_at: new Date().toISOString(),
        }
      : {
          status: "failed",
          error_message: `Job exceeded maximum timeout (${config.job_timeout_minutes} minutes) and max retries (${job.max_retries})`,
          completed_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        };

    await dbFetch(`/rest/v1/jobs?id=eq.${job.id}`, {
      method: "PATCH",
      headers: { Prefer: "return=minimal" },
      body: JSON.stringify(updateData),
    });

    timeoutCount++;
    console.log(
      `[TIMEOUT] Job ${job.id} (${job.job_type}) - ${shouldRetry ? "Retrying" : "Failed"} - Attempt ${job.retry_count + 1}/${job.max_retries}`
    );
  }

  if (timeoutCount > 0) {
    console.log(`[TIMEOUT] Handled ${timeoutCount} timed out jobs`);
  }
}

// Queue Processor
async function processQueue(config: JobQueueConfig) {
  // Get currently processing jobs
  const processingJobs: VideoJob[] = await dbFetch(
    "/rest/v1/jobs?status=eq.processing&select=*"
  );

  const currentManimJobs = processingJobs.filter(
    (j) => j.job_type === "topic_short"
  ).length;
  const totalProcessing = processingJobs.length;

  // Calculate available slots with peak hour scaling
  const maxConcurrent = isPeakHour()
    ? Math.floor(config.max_concurrent_renders * config.peak_worker_multiplier)
    : config.max_concurrent_renders;

  const availableSlots = maxConcurrent - totalProcessing;

  console.log(
    `[QUEUE] Processing: ${totalProcessing}/${maxConcurrent} (Manim: ${currentManimJobs}/${config.max_manim_renders}) | Available slots: ${availableSlots} | Peak hour: ${isPeakHour()}`
  );

  if (availableSlots <= 0) {
    console.log("[QUEUE] No available slots, waiting...");
    return;
  }

  // Get next jobs from queue (FIFO by priority, then queue_position)
  const queuedJobs: VideoJob[] = await dbFetch(
    `/rest/v1/jobs?status=eq.queued&order=priority.desc,queue_position.asc&limit=${availableSlots}`
  );

  if (!queuedJobs || queuedJobs.length === 0) {
    console.log("[QUEUE] No jobs in queue");
    return;
  }

  let jobsStarted = 0;
  let manimStarted = 0;

  for (const job of queuedJobs) {
    // Check Manim-specific limit
    if (
      job.job_type === "topic_short" &&
      currentManimJobs + manimStarted >= config.max_manim_renders
    ) {
      console.log(
        `[QUEUE] Manim limit reached (${config.max_manim_renders}), skipping job ${job.id}`
      );
      continue;
    }

    // Mark job as processing
    await dbFetch(`/rest/v1/jobs?id=eq.${job.id}`, {
      method: "PATCH",
      headers: { Prefer: "return=minimal" },
      body: JSON.stringify({
        status: "processing",
        started_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      }),
    });

    jobsStarted++;
    if (job.job_type === "topic_short") {
      manimStarted++;
    }

    console.log(
      `[QUEUE] Started job ${job.id} | Type: ${job.job_type} | Priority: ${job.priority} | Queue pos: ${job.queue_position}`
    );

    // TODO: Call actual render services here
    // Example:
    // if (job.job_type === "doubt") {
    //   await fetch("http://localhost:8103/render", {
    //     method: "POST",
    //     body: JSON.stringify({ jobId: job.id, payload: job.payload }),
    //   });
    // }
  }

  if (jobsStarted > 0) {
    console.log(`[QUEUE] Started ${jobsStarted} jobs (${manimStarted} Manim)`);
  }
}

// Main Handler
serve(async (req) => {
  const startTime = Date.now();

  try {
    console.log(`\n[WORKER] ========== Queue Worker Execution Started ==========`);
    console.log(`[WORKER] Time: ${new Date().toISOString()}`);

    // Get queue configuration
    const configs: JobQueueConfig[] = await dbFetch(
      "/rest/v1/job_queue_config?select=*&limit=1"
    );

    if (!configs || configs.length === 0) {
      throw new Error("Queue configuration not found in database");
    }

    const config = configs[0];

    // Handle timeouts
    await handleTimeouts(config);

    // Process queue
    await processQueue(config);

    const duration = Date.now() - startTime;
    console.log(`[WORKER] ========== Execution Complete (${duration}ms) ==========\n`);

    return new Response(
      JSON.stringify({
        success: true,
        timestamp: new Date().toISOString(),
        duration_ms: duration,
      }),
      {
        headers: { "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (error) {
    const duration = Date.now() - startTime;
    console.error(`[WORKER] ========== Execution Failed (${duration}ms) ==========`);
    console.error(`[ERROR] ${error.message}`);
    console.error(error);

    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
        timestamp: new Date().toISOString(),
        duration_ms: duration,
      }),
      {
        headers: { "Content-Type": "application/json" },
        status: 500,
      }
    );
  }
}, { port: PORT });

console.log(`\n✅ Video Queue Worker Started`);
console.log(`📍 Listening on: http://localhost:${PORT}`);
console.log(`🔗 Supabase URL: ${SUPABASE_URL}`);
console.log(`🌐 Peak hours: 6-9 AM, 8-11 PM\n`);
