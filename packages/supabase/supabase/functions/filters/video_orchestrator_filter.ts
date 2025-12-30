/**
 * Video Orchestrator Filter
 *
 * Calls the Video Orchestrator service (port 8103) which coordinates
 * multiple services (Manim, Revideo, Notes) for end-to-end video generation.
 */

const ORCHESTRATOR_URL = process.env.VPS_ORCHESTRATOR_URL || 'http://89.117.60.144:8103';

export type VideoType =
  | 'daily_news'
  | 'doubt_explainer'
  | 'notes_summary'
  | 'documentary'
  | 'pyq_explanation';

export interface VideoGenerationParams {
  type: VideoType;
  title: string;
  script: string;
  parameters: {
    topic?: string;
    questionId?: string;
    duration?: number;
    style?: 'formal' | 'conversational' | 'educational';
  };
  priority?: 'low' | 'medium' | 'high';
}

export interface VideoGenerationResult {
  jobId: string;
  status: 'queued' | 'processing' | 'completed' | 'failed';
  progress?: number;
  outputUrl?: string;
  thumbnailUrl?: string;
  error?: string;
  stages?: Array<{
    name: string;
    status: 'pending' | 'running' | 'completed' | 'failed';
    progress: number;
  }>;
  estimatedCompletionTime?: Date;
}

export async function videoOrchestratorFilter(
  params: VideoGenerationParams
): Promise<VideoGenerationResult> {
  const response = await fetch(`${ORCHESTRATOR_URL}/render`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
    },
    body: JSON.stringify({
      ...params,
      webhookUrl: `${process.env.SUPABASE_URL}/functions/v1/video_webhook`,
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    console.error(`[Orchestrator Filter] Error: ${response.status} - ${error}`);
    throw new Error(`Video orchestrator error: ${response.statusText}`);
  }

  return response.json();
}

export async function getVideoJobStatus(jobId: string): Promise<VideoGenerationResult> {
  const response = await fetch(`${ORCHESTRATOR_URL}/status/${jobId}`, {
    headers: {
      'Authorization': `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
    },
  });

  if (!response.ok) {
    throw new Error(`Status check failed: ${response.statusText}`);
  }

  return response.json();
}

export async function cancelVideoJob(jobId: string): Promise<void> {
  await fetch(`${ORCHESTRATOR_URL}/cancel/${jobId}`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
    },
  });
}

export async function getUserVideoQueue(userId: string): Promise<VideoGenerationResult[]> {
  const response = await fetch(`${ORCHESTRATOR_URL}/queue/${userId}`, {
    headers: {
      'Authorization': `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
    },
  });

  if (!response.ok) {
    throw new Error(`Queue fetch failed: ${response.statusText}`);
  }

  return response.json();
}
