import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { assignJobPriority, type JobType } from '../shared/queue-utils.ts';

export async function enqueueJob(
  supabase: any,
  jobType: JobType,
  payload: Record<string, any>,
  userId?: string
) {
  const priority = assignJobPriority(jobType);
  
  const { data, error } = await supabase.from('jobs').insert({
    job_type: jobType,
    priority,
    status: 'queued',
    payload,
    user_id: userId,
    retry_count: 0,
    max_retries: 3
  }).select().single();

  if (error) throw error;
  return data;
}

export async function cancelJob(supabase: any, jobId: string) {
  const { error } = await supabase.from('jobs').update({
    status: 'cancelled',
    updated_at: new Date().toISOString()
  }).eq('id', jobId).eq('status', 'queued');

  if (error) throw error;
}

export async function getJobStatus(supabase: any, jobId: string) {
  const { data, error } = await supabase.from('jobs').select('*').eq('id', jobId).single();
  if (error) throw error;
  return data;
}
