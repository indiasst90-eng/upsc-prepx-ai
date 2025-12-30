import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { checkConcurrencyLimits, isPeakHour, type VideoJob, type JobQueueConfig } from '../shared/queue-utils.ts';

const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

serve(async (req) => {
  try {
    const supabase = createClient(supabaseUrl, supabaseKey);
    const { data: config } = await supabase.from('job_queue_config').select('*').single() as { data: JobQueueConfig };

    await handleTimeouts(supabase, config);
    await processQueue(supabase, config);

    return new Response(JSON.stringify({ success: true }), {
      headers: { 'Content-Type': 'application/json' },
      status: 200
    });
  } catch (error) {
    console.error('Queue worker error:', error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500
    });
  }
});

async function handleTimeouts(supabase: any, config: JobQueueConfig) {
  const timeoutThreshold = new Date();
  timeoutThreshold.setMinutes(timeoutThreshold.getMinutes() - config.job_timeout_minutes);

  const { data: timedOutJobs } = await supabase.from('jobs').select('*').eq('status', 'processing').lt('started_at', timeoutThreshold.toISOString());

  for (const job of timedOutJobs || []) {
    if (job.retry_count < job.max_retries) {
      await supabase.from('jobs').update({
        status: 'queued',
        retry_count: job.retry_count + 1,
        error_message: 'Job timed out, retrying...',
        updated_at: new Date().toISOString()
      }).eq('id', job.id);
      console.log(`Job ${job.id} timed out, retry ${job.retry_count + 1}/${job.max_retries}`);
    } else {
      await supabase.from('jobs').update({
        status: 'failed',
        error_message: 'Job exceeded maximum timeout',
        completed_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      }).eq('id', job.id);
      console.log(`Job ${job.id} failed after max retries`);
    }
  }
}

async function processQueue(supabase: any, config: JobQueueConfig) {
  const peak = isPeakHour(config);
  const maxWorkers = peak ? Math.floor(config.max_concurrent_renders * config.peak_worker_multiplier) : config.max_concurrent_renders;

  console.log(`Processing queue (peak: ${peak}, max workers: ${maxWorkers})`);

  const { data: nextJob } = await supabase.from('jobs').select('*').eq('status', 'queued').order('priority', { ascending: true }).order('created_at', { ascending: true }).limit(1).single();

  if (!nextJob) {
    console.log('No jobs in queue');
    return;
  }

  const canProcess = await checkConcurrencyLimits(supabase, nextJob.job_type);
  if (!canProcess) {
    console.log('Concurrency limit reached, waiting...');
    return;
  }

  await supabase.from('jobs').update({
    status: 'processing',
    started_at: new Date().toISOString(),
    updated_at: new Date().toISOString()
  }).eq('id', nextJob.id);

  console.log(`Processing job ${nextJob.id} (${nextJob.job_type})`);

  try {
    await processVideoJob(supabase, nextJob);
    await supabase.from('jobs').update({
      status: 'completed',
      completed_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    }).eq('id', nextJob.id);
    console.log(`Job ${nextJob.id} completed successfully`);
  } catch (error) {
    console.error(`Job ${nextJob.id} failed:`, error);
    if (nextJob.retry_count < nextJob.max_retries) {
      await supabase.from('jobs').update({
        status: 'queued',
        retry_count: nextJob.retry_count + 1,
        error_message: error.message,
        updated_at: new Date().toISOString()
      }).eq('id', nextJob.id);
    } else {
      await supabase.from('jobs').update({
        status: 'failed',
        error_message: error.message,
        completed_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      }).eq('id', nextJob.id);
    }
  }
}

async function processVideoJob(supabase: any, job: VideoJob) {
  const pipeUrl = getPipeUrl(job.job_type);
  const response = await fetch(pipeUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${supabaseKey}` },
    body: JSON.stringify(job.payload)
  });

  if (!response.ok) throw new Error(`Video generation failed: ${response.statusText}`);
  return await response.json();
}

function getPipeUrl(jobType: string): string {
  const baseUrl = supabaseUrl.replace('/rest/v1', '/functions/v1');
  switch (jobType) {
    case 'doubt': return `${baseUrl}/pipes/doubt_video_converter_pipe`;
    case 'topic_short': return `${baseUrl}/pipes/topic_short_pipe`;
    case 'daily_ca': return `${baseUrl}/pipes/daily_ca_video_pipe`;
    default: throw new Error(`Unknown job type: ${jobType}`);
  }
}
