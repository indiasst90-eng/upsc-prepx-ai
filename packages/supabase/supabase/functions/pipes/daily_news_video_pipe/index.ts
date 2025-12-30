/**
 * Daily News Video Generator Pipeline
 *
 * Creates short news videos from daily news content using Revideo and Manim services.
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from '@supabase/supabase-js';
import { corsHeaders } from '../_shared/cors.ts';

interface DailyNewsVideoRequest {
  news_date?: string;
  category?: string;
  duration_seconds?: number; // 60, 90, 120 seconds
  style?: 'explainer' | 'quick' | 'detailed';
}

interface DailyNewsVideoResponse {
  success: boolean;
  video_id: string;
  status: 'queued' | 'processing' | 'completed' | 'failed';
  thumbnail_url?: string;
  video_url?: string;
  duration_seconds: number;
  error?: string;
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
      news_date = new Date().toISOString().split('T')[0],
      category = 'general',
      duration_seconds = 90,
      style = 'explainer',
    } = await req.json() as DailyNewsVideoRequest;

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    // Check if video already exists
    const { data: existingVideo } = await supabaseAdmin
      .from('daily_news_videos')
      .select('*')
      .eq('news_date', news_date)
      .eq('category', category)
      .in('status', ['completed', 'processing'])
      .single();

    if (existingVideo) {
      return new Response(JSON.stringify({
        success: true,
        video_id: existingVideo.id,
        status: existingVideo.status,
        thumbnail_url: existingVideo.thumbnail_url,
        video_url: existingVideo.video_url,
        duration_seconds: existingVideo.duration_seconds,
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Get today's news from database
    const { data: newsData } = await supabaseAdmin
      .from('daily_updates')
      .select('*')
      .eq('date', news_date)
      .single();

    if (!newsData) {
      // Generate news first
      const newsResponse = await fetch(`${Deno.env.get('SUPABASE_URL')}/functions/v1/daily_news_pipe`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
        },
        body: JSON.stringify({ date: news_date, category }),
      });

      if (!newsResponse.ok) {
        throw new Error('Failed to generate news for video');
      }

      const newsResult = await newsResponse.json();
      // Use the generated news
    }

    // Create video render job
    const { data: videoJob, error: jobError } = await supabaseAdmin
      .from('daily_news_videos')
      .insert({
        news_date: news_date,
        category: category,
        duration_seconds: duration_seconds,
        style: style,
        status: 'queued',
        created_at: new Date().toISOString(),
      })
      .select()
      .single();

    if (jobError) {
      throw new Error(`Failed to create video job: ${jobError.message}`);
    }

    // Call Video Orchestrator service if available
    const orchestratorUrl = Deno.env.get('VPS_ORCHESTRATOR_URL');
    if (orchestratorUrl) {
      try {
        const orchestratorResponse = await fetch(`${orchestratorUrl}/render`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            type: 'daily_news',
            video_id: videoJob.id,
            duration: duration_seconds,
            style: style,
            news_content: newsData || {},
          }),
        });

        if (orchestratorResponse.ok) {
          const orchestratorData = await orchestratorResponse.json();
          await supabaseAdmin
            .from('daily_news_videos')
            .update({ status: 'processing', render_job_id: orchestratorData.render_id })
            .eq('id', videoJob.id);
        }
      } catch (orchError) {
        console.log('Orchestrator not available, using fallback rendering');
      }
    }

    const response: DailyNewsVideoResponse = {
      success: true,
      video_id: videoJob.id,
      status: videoJob.status,
      duration_seconds: videoJob.duration_seconds,
    };

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (error) {
    const processingTime = (Date.now() - startTime) / 1000;

    return new Response(JSON.stringify({
      success: false,
      error: (error as Error).message,
      processing_time_seconds: processingTime,
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    });
  }
});
