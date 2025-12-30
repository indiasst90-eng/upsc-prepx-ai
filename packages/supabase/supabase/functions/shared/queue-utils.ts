export type JobType = 'doubt' | 'topic_short' | 'daily_ca';
export type Priority = 'high' | 'medium' | 'low';
export type JobStatus = 'queued' | 'processing' | 'completed' | 'failed' | 'cancelled';

export interface VideoJob {
  id: string;
  job_type: JobType;
  priority: Priority;
  status: JobStatus;
  payload: Record<string, any>;
  queue_position?: number;
  retry_count: number;
  max_retries: number;
  error_message?: string;
  started_at?: string;
  completed_at?: string;
  created_at: string;
  updated_at: string;
  user_id?: string;
}

export interface JobQueueConfig {
  max_concurrent_renders: number;
  max_manim_renders: number;
  job_timeout_minutes: number;
  retry_interval_minutes: number;
  peak_hour_start: string;
  peak_hour_end: string;
  peak_worker_multiplier: number;
}

export function assignJobPriority(jobType: JobType): Priority {
  switch (jobType) {
    case 'doubt': return 'high';
    case 'topic_short': return 'medium';
    case 'daily_ca': return 'low';
    default: return 'medium';
  }
}

export async function checkConcurrencyLimits(supabase: any, jobType: JobType): Promise<boolean> {
  const { data: config } = await supabase.from('job_queue_config').select('*').single();
  const { count: totalProcessing } = await supabase.from('jobs').select('*', { count: 'exact', head: true }).eq('status', 'processing');

  if (totalProcessing >= config.max_concurrent_renders) return false;

  if (jobType === 'topic_short') {
    const { count: manimProcessing } = await supabase.from('jobs').select('*', { count: 'exact', head: true }).eq('status', 'processing').eq('job_type', 'topic_short');
    if (manimProcessing >= config.max_manim_renders) return false;
  }

  return true;
}

export function isPeakHour(config: JobQueueConfig): boolean {
  const now = new Date();
  const currentTime = now.getHours() * 60 + now.getMinutes();
  const [peakStartHour, peakStartMin] = config.peak_hour_start.split(':').map(Number);
  const [peakEndHour, peakEndMin] = config.peak_hour_end.split(':').map(Number);
  const peakStart = peakStartHour * 60 + peakStartMin;
  const peakEnd = peakEndHour * 60 + peakEndMin;
  return currentTime >= peakStart && currentTime <= peakEnd;
}

export function calculateEstimatedWaitTime(queuePosition: number, avgProcessingTime: number = 5): number {
  return queuePosition * avgProcessingTime;
}

export async function getQueuePosition(supabase: any, jobId: string): Promise<{ position: number; totalAhead: number }> {
  const { data: job } = await supabase.from('jobs').select('queue_position, priority').eq('id', jobId).single();
  const { count: totalAhead } = await supabase.from('jobs').select('*', { count: 'exact', head: true }).eq('status', 'queued').lt('queue_position', job.queue_position);
  return { position: job.queue_position || 0, totalAhead: totalAhead || 0 };
}
