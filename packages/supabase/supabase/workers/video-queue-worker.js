#!/usr/bin/env node
/**
 * Video Queue Worker - Standalone Node.js worker for self-hosted Supabase
 * Calls Supabase REST API to manage video generation queue
 */

const http = require('http');

const SUPABASE_URL = process.env.SUPABASE_URL || 'http://89.117.60.144:54321';
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU';
const JOB_TIMEOUT_MINUTES = 10;
const MAX_RETRIES = 3;

const PIPE_URLS = {
  doubt: `${SUPABASE_URL.replace('/rest/v1', '')}/functions/v1/pipes/doubt_video_converter_pipe`,
  topic_short: `${SUPABASE_URL.replace('/rest/v1', '')}/functions/v1/pipes/topic_short_pipe`,
  daily_ca: `${SUPABASE_URL.replace('/rest/v1', '')}/functions/v1/pipes/daily_ca_video_pipe`
};

async function supabaseRequest(method, path, body = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, SUPABASE_URL);
    const options = {
      hostname: url.hostname,
      port: url.port,
      path: url.pathname + url.search,
      method,
      headers: {
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        'Content-Type': 'application/json',
        'apikey': SUPABASE_SERVICE_KEY
      }
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          resolve(data);
        }
      });
    });

    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

async function getConfig() {
  const data = await supabaseRequest('GET', '/rest/v1/job_queue_config?limit=1');
  return Array.isArray(data) ? data[0] : data;
}

async function getProcessingCount() {
  const data = await supabaseRequest('GET', '/rest/v1/jobs?status=eq.processing&select=id');
  return Array.isArray(data) ? data.length : 0;
}

async function handleTimeouts(config) {
  const timeoutThreshold = new Date();
  timeoutThreshold.setMinutes(timeoutThreshold.getMinutes() - JOB_TIMEOUT_MINUTES);

  const processingJobs = await supabaseRequest('GET', `/rest/v1/jobs?status=eq.processing&started_at=lt.${timeoutThreshold.toISOString()}`);

  for (const job of processingJobs || []) {
    if (job.retry_count < MAX_RETRIES) {
      await supabaseRequest('PATCH', `/rest/v1/jobs?id=eq.${job.id}`, {
        status: 'queued',
        retry_count: job.retry_count + 1,
        error_message: 'Job timed out, retrying...'
      });
      console.log(`Job ${job.id.slice(0,8)} timed out, retry ${job.retry_count + 1}/${MAX_RETRIES}`);
    } else {
      await supabaseRequest('PATCH', `/rest/v1/jobs?id=eq.${job.id}`, {
        status: 'failed',
        error_message: 'Job exceeded maximum timeout',
        completed_at: new Date().toISOString()
      });
      console.log(`Job ${job.id.slice(0,8)} failed after max retries`);
    }
  }
}

async function processQueue(config) {
  const processingCount = await getProcessingCount();

  if (processingCount >= config.max_concurrent_renders) {
    console.log(`Concurrency limit reached (${processingCount}/${config.max_concurrent_renders}), waiting...`);
    return;
  }

  // Get highest priority queued job
  const queuedJobs = await supabaseRequest('GET', '/rest/v1/jobs?status=eq.queued&order=priority.asc,created_at.asc&limit=1');

  if (!queuedJobs || queuedJobs.length === 0) {
    console.log('No jobs in queue');
    return;
  }

  const job = queuedJobs[0];

  // Mark as processing
  await supabaseRequest('PATCH', `/rest/v1/jobs?id=eq.${job.id}`, {
    status: 'processing',
    started_at: new Date().toISOString()
  });

  console.log(`Processing job ${job.id.slice(0,8)} (${job.job_type})`);

  try {
    const pipeUrl = PIPE_URLS[job.job_type];
    if (!pipeUrl) throw new Error(`Unknown job type: ${job.job_type}`);

    // Call the video generation pipe
    const response = await fetch(pipeUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`
      },
      body: JSON.stringify(job.payload)
    });

    if (!response.ok) {
      throw new Error(`Video generation failed: ${response.statusText}`);
    }

    // Mark as completed
    await supabaseRequest('PATCH', `/rest/v1/jobs?id=eq.${job.id}`, {
      status: 'completed',
      completed_at: new Date().toISOString()
    });

    console.log(`Job ${job.id.slice(0,8)} completed successfully`);
  } catch (error) {
    console.error(`Job ${job.id.slice(0,8)} failed:`, error.message);

    if (job.retry_count < MAX_RETRIES) {
      await supabaseRequest('PATCH', `/rest/v1/jobs?id=eq.${job.id}`, {
        status: 'queued',
        retry_count: job.retry_count + 1,
        error_message: error.message
      });
    } else {
      await supabaseRequest('PATCH', `/rest/v1/jobs?id=eq.${job.id}`, {
        status: 'failed',
        error_message: error.message,
        completed_at: new Date().toISOString()
      });
    }
  }
}

async function runWorker() {
  console.log(`[${new Date().toISOString()}] Video Queue Worker started`);

  try {
    const config = await getConfig();
    if (!config) {
      console.error('No queue config found, exiting');
      process.exit(1);
    }

    await handleTimeouts(config);
    await processQueue(config);

    console.log(`[${new Date().toISOString()}] Worker cycle complete`);
  } catch (error) {
    console.error('Worker error:', error);
  }
}

// Run worker
runWorker();
