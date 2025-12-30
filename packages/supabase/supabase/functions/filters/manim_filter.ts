/**
 * Manim Scene Generation Filter
 *
 * Calls the Manim Renderer service (port 5000) to generate mathematical
 * animations and diagram visualizations.
 */

const MANIM_SERVICE_URL = process.env.VPS_MANIM_URL || 'http://89.117.60.144:5000';

export interface ManimSceneParams {
  sceneType: 'graph' | 'flowchart' | 'process' | 'comparison' | 'map';
  data: Record<string, any>;
  duration?: number; // seconds
  resolution?: { width: number; height: number };
}

export interface ManimSceneResult {
  sceneId: string;
  status: 'queued' | 'rendering' | 'completed' | 'failed';
  renderUrl?: string;
  error?: string;
  estimatedTime?: number;
}

export async function manimSceneFilter(params: ManimSceneParams): Promise<ManimSceneResult> {
  const response = await fetch(`${MANIM_SERVICE_URL}/render`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
    },
    body: JSON.stringify({
      ...params,
      output_format: 'mp4',
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    console.error(`[Manim Filter] Error: ${response.status} - ${error}`);
    throw new Error(`Manim renderer error: ${response.statusText}`);
  }

  return response.json();
}

export async function getSceneStatus(sceneId: string): Promise<ManimSceneResult> {
  const response = await fetch(`${MANIM_SERVICE_URL}/status/${sceneId}`, {
    headers: {
      'Authorization': `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
    },
  });

  if (!response.ok) {
    throw new Error(`Status check failed: ${response.statusText}`);
  }

  return response.json();
}

export async function cancelScene(sceneId: string): Promise<void> {
  await fetch(`${MANIM_SERVICE_URL}/cancel/${sceneId}`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
    },
  });
}
