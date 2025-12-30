/**
 * Revideo Composition Filter
 *
 * Calls the Revideo Renderer service (port 5001) to assemble final videos
 * with transitions, voiceovers, and animations.
 */

const REVIDEO_SERVICE_URL = process.env.VPS_REVIDEO_URL || 'http://89.117.60.144:5001';

export interface RevideoCompositionParams {
  template: 'daily_news' | 'doubt_explainer' | 'notes_summary' | 'documentary';
  script: string;
  assets: {
    manimScenes?: string[];
    images?: string[];
    audio?: string;
  };
  narration?: {
    text: string;
    voice?: string;
    language?: string;
  };
  settings?: {
    duration?: number;
    resolution?: '720p' | '1080p' | '4k';
    backgroundMusic?: string;
  };
}

export interface RevideoCompositionResult {
  renderId: string;
  status: 'queued' | 'rendering' | 'completed' | 'failed';
  outputUrl?: string;
  error?: string;
  progress?: number;
  estimatedTime?: number;
}

export async function revideoCompositionFilter(
  params: RevideoCompositionParams
): Promise<RevideoCompositionResult> {
  const response = await fetch(`${REVIDEO_SERVICE_URL}/render`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
    },
    body: JSON.stringify(params),
  });

  if (!response.ok) {
    const error = await response.text();
    console.error(`[Revideo Filter] Error: ${response.status} - ${error}`);
    throw new Error(`Revideo renderer error: ${response.statusText}`);
  }

  return response.json();
}

export async function getRenderStatus(renderId: string): Promise<RevideoCompositionResult> {
  const response = await fetch(`${REVIDEO_SERVICE_URL}/status/${renderId}`, {
    headers: {
      'Authorization': `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
    },
  });

  if (!response.ok) {
    throw new Error(`Status check failed: ${response.statusText}`);
  }

  return response.json();
}

export async function cancelRender(renderId: string): Promise<void> {
  await fetch(`${REVIDEO_SERVICE_URL}/cancel/${renderId}`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
    },
  });
}
