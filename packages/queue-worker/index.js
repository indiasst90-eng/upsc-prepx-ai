// Standalone Video Queue Worker
// Processes video generation jobs from the queue

import { createClient } from '@supabase/supabase-js';

// Configuration from environment
const SUPABASE_URL = process.env.SUPABASE_URL || 'http://89.117.60.144:54321';
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const WORKER_INTERVAL_MS = parseInt(process.env.WORKER_INTERVAL_MS || '60000'); // 1 minute default

// Initialize Supabase client
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

console.log('🚀 Video Queue Worker Starting...');
console.log(`📍 Supabase URL: ${SUPABASE_URL}`);
console.log(`⏱️  Worker Interval: ${WORKER_INTERVAL_MS}ms`);

// Get queue configuration
async function getQueueConfig() {
  const { data, error } = await supabase
    .from('job_queue_config')
    .select('*')
    .limit(1)
    .single();

  if (error) {
    console.error('❌ Error fetching queue config:', error);
    return {
      max_concurrent_renders: 10,
      max_manim_renders: 4,
      job_timeout_minutes: 10,
      retry_interval_minutes: 5,
    };
  }

  return data;
}

// Check if we're in peak hour
function isPeakHour(config) {
  const now = new Date();
  const hour = now.getHours();

  const peakStartHour = config.peak_hour_start ? parseInt(config.peak_hour_start.split(':')[0]) : 6;
  const peakEndHour = config.peak_hour_end ? parseInt(config.peak_hour_end.split(':')[0]) : 21;

  return hour >= peakStartHour && hour <= peakEndHour;
}

// Get currently processing jobs count
async function getProcessingCount() {
  const { count, error } = await supabase
    .from('jobs')
    .select('*', { count: 'exact', head: true })
    .eq('status', 'processing');

  if (error) {
    console.error('❌ Error counting processing jobs:', error);
    return 0;
  }

  return count || 0;
}

// Get next job from queue
async function getNextJob(config) {
  const processingCount = await getProcessingCount();

  // Check if we've hit concurrency limit
  if (processingCount >= config.max_concurrent_renders) {
    console.log(`⏸️  Concurrency limit reached (${processingCount}/${config.max_concurrent_renders})`);
    return null;
  }

  // Get next queued job (ordered by priority and created_at)
  const { data, error } = await supabase
    .from('jobs')
    .select('*')
    .eq('status', 'queued')
    .order('priority', { ascending: true })  // high=1, medium=2, low=3
    .order('created_at', { ascending: true })
    .limit(1)
    .single();

  if (error && error.code !== 'PGRST116') { // PGRST116 = no rows
    console.error('❌ Error fetching next job:', error);
    return null;
  }

  return data;
}

// Mark job as processing
async function startJob(jobId) {
  const { data, error } = await supabase
    .from('jobs')
    .update({
      status: 'processing',
      started_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    })
    .eq('id', jobId)
    .select()
    .single();

  if (error) {
    console.error(`❌ Error starting job ${jobId}:`, error);
    return null;
  }

  return data;
}

// Categorize errors for better handling
function categorizeError(error) {
  const message = error.message || '';

  if (message.includes('timeout') || message.includes('ETIMEDOUT') || message.includes('ECONNREFUSED')) {
    return { type: 'TIMEOUT', retryable: true };
  }
  if (message.includes('API error') || message.includes('500') || message.includes('502') || message.includes('503')) {
    return { type: 'API_ERROR', retryable: true };
  }
  if (message.includes('Invalid input') || message.includes('400') || message.includes('422')) {
    return { type: 'INVALID_INPUT', retryable: false };
  }
  if (message.includes('404')) {
    return { type: 'NOT_FOUND', retryable: false };
  }
  return { type: 'UNKNOWN', retryable: true };
}

// Process a single job using Video Orchestrator
async function processJob(job) {
  console.log(`\n🎬 Processing ${job.job_type} job ${job.id.substring(0, 8)}...`);
  console.log(`   Type: ${job.job_type}`);
  console.log(`   Priority: ${job.priority}`);
  console.log(`   Payload:`, JSON.stringify(job.payload).substring(0, 100));

  try {
    // Use Video Orchestrator for end-to-end video generation
    console.log(`   📡 Calling Video Orchestrator API...`);

    const orchestratorUrl = 'http://89.117.60.144:8103/render';
    const requestBody = {
      job_id: job.id,
      job_type: job.job_type,
      input: job.payload.question || job.payload.topic || job.payload.content,
      style: job.payload.style || 'detailed',
      length: job.payload.length || 60,
      voice: job.payload.voice || 'default'
    };

    console.log(`   → Request: ${orchestratorUrl}`);
    console.log(`   → Payload: ${JSON.stringify(requestBody).substring(0, 150)}...`);

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 600000); // 10 minutes

    const response = await fetch(orchestratorUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: JSON.stringify(requestBody),
      signal: controller.signal
    });

    clearTimeout(timeoutId);

    const result = await response.json();

    if (!response.ok) {
      throw new Error(`Video Orchestrator error (${response.status}): ${result.error || result.message || 'Unknown error'}`);
    }

    console.log(`   ✅ Video generated successfully`);
    console.log(`   → Video URL: ${result.video_url || 'N/A'}`);
    console.log(`   → Duration: ${result.duration || 'N/A'}s`);

    // Update job with video URL and metadata
    const { error } = await supabase
      .from('jobs')
      .update({
        status: 'completed',
        completed_at: new Date().toISOString(),
        payload: {
          ...job.payload,
          video_url: result.video_url,
          thumbnail_url: result.thumbnail_url,
          duration: result.duration,
          processing_time_ms: result.processing_time_ms
        },
        updated_at: new Date().toISOString()
      })
      .eq('id', job.id);

    if (error) throw error;

    console.log(`   ✅ Job completed successfully`);
    return true;

  } catch (error) {
    console.error(`   ❌ Job failed:`, error.message);

    // Categorize error
    const errorInfo = categorizeError(error);
    console.log(`   → Error type: ${errorInfo.type} (Retryable: ${errorInfo.retryable})`);

    // Determine if we should retry
    const shouldRetry = errorInfo.retryable && job.retry_count < job.max_retries;

    // Store detailed error information
    const errorDetails = JSON.stringify({
      message: error.message,
      type: errorInfo.type,
      retryable: errorInfo.retryable,
      timestamp: new Date().toISOString(),
      stack: error.stack?.substring(0, 500)
    });

    if (shouldRetry) {
      await supabase
        .from('jobs')
        .update({
          status: 'queued',
          retry_count: job.retry_count + 1,
          error_message: errorDetails,
          updated_at: new Date().toISOString()
        })
        .eq('id', job.id);

      console.log(`   🔄 Job queued for retry (${job.retry_count + 1}/${job.max_retries})`);
    } else {
      await supabase
        .from('jobs')
        .update({
          status: 'failed',
          error_message: errorDetails,
          updated_at: new Date().toISOString()
        })
        .eq('id', job.id);

      const reason = errorInfo.retryable ? 'max retries reached' : 'non-retryable error';
      console.log(`   ⛔ Job failed permanently (${reason})`);
    }

    return false;
  }
}

// Check for timeout jobs
async function checkTimeouts(config) {
  const timeoutMinutes = config.job_timeout_minutes || 10;
  const timeoutDate = new Date();
  timeoutDate.setMinutes(timeoutDate.getMinutes() - timeoutMinutes);

  const { data: timeoutJobs, error } = await supabase
    .from('jobs')
    .select('*')
    .eq('status', 'processing')
    .lt('started_at', timeoutDate.toISOString());

  if (error) {
    console.error('❌ Error checking timeouts:', error);
    return;
  }

  if (timeoutJobs && timeoutJobs.length > 0) {
    console.log(`\n⏰ Found ${timeoutJobs.length} timed out job(s)`);

    for (const job of timeoutJobs) {
      console.log(`   Timing out job ${job.id.substring(0, 8)}...`);

      if (job.retry_count < job.max_retries) {
        await supabase
          .from('jobs')
          .update({
            status: 'queued',
            retry_count: job.retry_count + 1,
            error_message: 'Job timed out',
            updated_at: new Date().toISOString()
          })
          .eq('id', job.id);
      } else {
        await supabase
          .from('jobs')
          .update({
            status: 'failed',
            error_message: 'Job timed out (max retries exceeded)',
            updated_at: new Date().toISOString()
          })
          .eq('id', job.id);
      }
    }
  }
}

// Main worker loop
async function workerLoop() {
  try {
    console.log('\n🔄 Worker cycle started...');

    // Get configuration
    const config = await getQueueConfig();

    // Check for timeouts
    await checkTimeouts(config);

    // Process next job
    const nextJob = await getNextJob(config);

    if (nextJob) {
      const startedJob = await startJob(nextJob.id);
      if (startedJob) {
        await processJob(startedJob);
      }
    } else {
      console.log('   📭 No jobs in queue');
    }

    // Get queue stats
    const { data: stats } = await supabase.rpc('get_queue_stats');
    if (stats) {
      console.log(`\n📊 Queue Stats:`);
      console.log(`   Queued: ${stats.total_queued}`);
      console.log(`   Processing: ${stats.total_processing}`);
      console.log(`   Completed Today: ${stats.total_completed_today}`);
      console.log(`   Failed Today: ${stats.total_failed_today}`);
    }

  } catch (error) {
    console.error('❌ Worker cycle error:', error);
  }
}

// Start the worker
async function start() {
  console.log('\n✅ Worker ready!\n');

  // Run immediately
  await workerLoop();

  // Then run on interval
  setInterval(workerLoop, WORKER_INTERVAL_MS);
}

// Handle shutdown gracefully
process.on('SIGTERM', () => {
  console.log('\n👋 Shutting down worker...');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('\n👋 Shutting down worker...');
  process.exit(0);
});

// Start the worker
start().catch(error => {
  console.error('❌ Fatal error:', error);
  process.exit(1);
});
