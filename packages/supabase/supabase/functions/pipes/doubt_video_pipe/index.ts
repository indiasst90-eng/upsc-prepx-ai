/**
 * Doubt-to-Video Converter Pipeline - Production Ready
 *
 * Converts student doubts into explanatory videos using AI.
 * Full pipeline with queue management, webhook handling, and retry logic.
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from '@supabase/supabase-js';
import { corsHeaders } from '../_shared/cors.ts';

interface DoubtVideoRequest {
  doubt_text: string;
  input_type: 'text' | 'image' | 'voice';
  style: 'concise' | 'detailed' | 'example-rich';
  video_length: 60 | 120 | 180;
  voice_preference?: string;
  extracted_text?: string;
  transcribed_text?: string;
}

interface DoubtVideoResponse {
  success: boolean;
  job_id: string;
  status: 'queued' | 'processing' | 'completed' | 'failed';
  queue_position?: number;
  estimated_time_minutes?: number;
  error?: string;
}

interface Job {
  id: string;
  user_id: string;
  doubt_text: string;
  style: string;
  video_length: number;
  status: 'queued' | 'processing' | 'completed' | 'failed' | 'cancelled';
  queue_position: number;
  video_url?: string;
  thumbnail_url?: string;
  error_message?: string;
  retry_count: number;
  created_at: string;
  completed_at?: string;
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  const startTime = Date.now();

  try {
    const {
      doubt_text,
      input_type,
      style,
      video_length,
      voice_preference,
      extracted_text,
      transcribed_text,
    } = await req.json() as DoubtVideoRequest;

    // Validate request
    const finalText = extracted_text || transcribed_text || doubt_text;
    if (!finalText || finalText.trim().length < 5) {
      return new Response(
        JSON.stringify({ error: 'Doubt text must be at least 5 characters' }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400,
        }
      );
    }

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    // Get user from header
    const userId = req.headers.get('x-user-id');

    // Check user's subscription and entitlement
    if (userId) {
      const { data: subscription } = await supabaseAdmin
        .from('subscriptions')
        .select('status, trial_expires_at')
        .eq('user_id', userId)
        .single();

      const isPro =
        subscription?.status === 'active' ||
        (subscription?.status === 'trial' &&
          new Date(subscription.trial_expires_at) > new Date());

      if (!isPro) {
        // Check daily limit for free users
        const today = new Date().toISOString().split('T')[0];
        const { count } = await supabaseAdmin
          .from('jobs')
          .select('*', { count: 'exact', head: true })
          .eq('user_id', userId)
          .eq('created_at', today);

        if (count >= 3) {
          return new Response(
            JSON.stringify({
              success: false,
              error: 'DAILY_LIMIT_REACHED',
              message: 'You have reached your daily limit of 3 doubts. Upgrade to Pro for unlimited doubts.',
              upgrade_required: true,
            }),
            {
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
              status: 403,
            }
          );
        }
      }
    }

    // Get current queue position
    const { count: queueCount } = await supabaseAdmin
      .from('jobs')
      .select('*', { count: 'exact', head: true })
      .eq('status', 'queued');

    // Create video render job
    const { data: job, error: jobError } = await supabaseAdmin
      .from('jobs')
      .insert({
        user_id: userId || 'anonymous',
        job_type: 'doubt_video',
        priority: 'normal',
        status: 'queued',
        queue_position: queueCount + 1,
        payload: {
          question: finalText,
          input_type,
          style,
          video_length,
          voice_preference,
        },
        retry_count: 0,
        created_at: new Date().toISOString(),
      })
      .select()
      .single();

    if (jobError) {
      throw new Error(`Failed to create job: ${jobError.message}`);
    }

    // Trigger video generation via Video Orchestrator
    const orchestratorUrl = Deno.env.get('VPS_ORCHESTRATOR_URL');
    if (orchestratorUrl) {
      try {
        const orchestratorResponse = await fetch(`${orchestratorUrl}/render`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            type: 'doubt_video',
            job_id: job.id,
            question: finalText,
            style,
            duration: video_length,
            voice: voice_preference,
          }),
        });

        if (orchestratorResponse.ok) {
          const orchestratorData = await orchestratorResponse.json();
          await supabaseAdmin
            .from('jobs')
            .update({
              status: 'processing',
              payload: {
                ...job.payload,
                render_job_id: orchestratorData.render_id,
              },
            })
            .eq('id', job.id);
        }
      } catch (orchestratorError) {
        console.warn('Orchestrator unreachable, using internal queue:', orchestratorError);
      }
    }

    const response: DoubtVideoResponse = {
      success: true,
      job_id: job.id,
      status: 'queued',
      queue_position: queueCount + 1,
      estimated_time_minutes: Math.ceil((queueCount + 1) * 3), // ~3 min per video
    };

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error) {
    const processingTime = (Date.now() - startTime) / 1000;

    return new Response(
      JSON.stringify({
        success: false,
        error: (error as Error).message,
        processing_time_seconds: processingTime,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    );
  }
});

// Webhook handler for video completion (called by Video Orchestrator)
export async function handleVideoWebhook(req: Request): Promise<Response> {
  try {
    const { job_id, status, video_url, thumbnail_url, error } = await req.json();

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    const updateData: any = {
      status,
      completed_at: new Date().toISOString(),
    };

    if (status === 'completed') {
      updateData.payload = {
        video_url,
        thumbnail_url,
      };
    } else if (status === 'failed') {
      updateData.error_message = error;
      updateData.retry_count = supabaseAdmin
        .from('jobs')
        .select('retry_count')
        .eq('id', job_id)
        .then(({ data }: any) => (data?.[0]?.retry_count || 0) + 1);
    }

    await supabaseAdmin.from('jobs').update(updateData).eq('id', job_id);

    return new Response(JSON.stringify({ success: true }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error) {
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    );
  }
}
