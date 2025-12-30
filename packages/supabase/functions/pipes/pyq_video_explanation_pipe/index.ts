// Story 8.4: PYQ Video Explanation Generation Pipe (FULL PRODUCTION)
// Pipe: pyq_video_explanation_pipe
// Pattern: REQUEST → AUTH_FILTER → ENTITLEMENT_CHECK → SCRIPT_ACTION → RENDER_ACTION → RESPONSE
// AC 1,3,6,7,8,9,10: Complete video generation with queue management and priority processing

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { generatePyqScript } from '../../actions/generate_pyq_script_action.ts';

serve(async (req) => {
  // CORS handling
  if (req.method === 'OPTIONS') {
    return new Response('ok', { 
      headers: { 
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
        'Access-Control-Allow-Headers': 'Authorization, Content-Type',
      } 
    });
  }

  try {
    // AC 9: AUTH FILTER - Verify authentication
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized', message: 'Authorization header required' }), 
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    );

    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized', message: 'Invalid or expired token' }), 
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Parse request body
    const { question_id, priority = 'prelims' } = await req.json();
    
    if (!question_id) {
      return new Response(
        JSON.stringify({ error: 'Bad Request', message: 'question_id is required' }), 
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Validate priority
    if (!['prelims', 'mains'].includes(priority)) {
      return new Response(
        JSON.stringify({ error: 'Bad Request', message: 'priority must be "prelims" or "mains"' }), 
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Verify question exists
    const { data: question, error: questionError } = await supabase
      .from('pyq_questions')
      .select('id, year, paper_type, number, subject')
      .eq('id', question_id)
      .single();

    if (questionError || !question) {
      return new Response(
        JSON.stringify({ error: 'Not Found', message: 'Question not found' }), 
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // AC 10: ENTITLEMENT CHECK - Pro feature
    const { data: profile } = await supabase
      .from('user_profiles')
      .select('subscription_tier, subscription_status')
      .eq('user_id', user.id)
      .single();

    if (profile?.subscription_tier !== 'pro' || profile?.subscription_status !== 'active') {
      return new Response(
        JSON.stringify({ 
          error: 'Forbidden', 
          message: 'Pro subscription required for video generation',
          upgrade_url: '/pricing'
        }), 
        { status: 403, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // AC 8,9: Check if video already exists or is in progress
    const { data: existing } = await supabase
      .from('pyq_videos')
      .select('id, status, video_url, created_at')
      .eq('question_id', question_id)
      .order('created_at', { ascending: false })
      .limit(1)
      .single();

    if (existing) {
      if (existing.status === 'completed' && existing.video_url) {
        return new Response(JSON.stringify({ 
          jobId: existing.id, 
          status: 'completed',
          video_url: existing.video_url,
          message: 'Video already generated'
        }), { 
          status: 200,
          headers: { 'Content-Type': 'application/json' }
        });
      }
      
      if (existing.status === 'queued' || existing.status === 'processing') {
        return new Response(JSON.stringify({ 
          jobId: existing.id, 
          status: existing.status,
          message: 'Video generation already in progress'
        }), { 
          status: 202,
          headers: { 'Content-Type': 'application/json' }
        });
      }
    }

    // AC 9: Check queue capacity (max 10 concurrent renders)
    const { count: activeJobs } = await supabase
      .from('pyq_videos')
      .select('id', { count: 'exact', head: true })
      .in('status', ['queued', 'processing']);

    if (activeJobs && activeJobs >= 10) {
      return new Response(JSON.stringify({ 
        error: 'Service Unavailable', 
        message: 'Video generation queue is full. Please try again in a few minutes.',
        queue_size: activeJobs
      }), { 
        status: 503,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    // AC 8,10: Create video job with priority
    const { data: videoJob, error: jobError } = await supabase
      .from('pyq_videos')
      .insert({
        question_id,
        status: 'queued',
        render_metadata: { 
          priority, 
          requested_by: user.id,
          requested_at: new Date().toISOString(),
          question_year: question.year,
          question_paper: question.paper_type,
        },
      })
      .select()
      .single();

    if (jobError) {
      console.error('Failed to create video job:', jobError);
      throw new Error(`Database error: ${jobError.message}`);
    }

    // AC 1,2,3,4,5: SCRIPT GENERATION ACTION (async with error handling)
    generatePyqScript(question_id, supabase)
      .then(async (script) => {
        // Update job with generated script
        const { error: updateError } = await supabase
          .from('pyq_videos')
          .update({ 
            script_text: script.script_text,
            status: 'processing',
            render_metadata: {
              ...videoJob.render_metadata,
              script_generated_at: new Date().toISOString(),
              sections_count: script.sections.length,
            }
          })
          .eq('id', videoJob.id);

        if (updateError) {
          throw new Error(`Failed to update job with script: ${updateError.message}`);
        }

        // AC 6,7: Call Video Orchestrator for rendering
        const orchestratorUrl = Deno.env.get('VPS_ORCHESTRATOR_URL') || 'http://89.117.60.144:8103';
        
        const renderResponse = await fetch(`${orchestratorUrl}/render-pyq-video`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            video_id: videoJob.id,
            question_id,
            question_metadata: script.question_metadata,
            script: script.sections,
            storage_path: `pyq-videos/${question.year}/${question.paper_type}/q${question.number}.mp4`,
            priority: priority === 'prelims' ? 1 : 2, // AC 10: Priority processing
          }),
        });

        if (!renderResponse.ok) {
          throw new Error(`Orchestrator error: ${renderResponse.status} ${renderResponse.statusText}`);
        }

        const renderResult = await renderResponse.json();
        
        // Update job with render job ID
        await supabase
          .from('pyq_videos')
          .update({ 
            render_metadata: {
              ...videoJob.render_metadata,
              render_job_id: renderResult.job_id,
              render_started_at: new Date().toISOString(),
            }
          })
          .eq('id', videoJob.id);

      })
      .catch(async (error) => {
        console.error('Video generation pipeline failed:', error);
        
        // AC 9: Update job status to failed with error details
        await supabase
          .from('pyq_videos')
          .update({ 
            status: 'failed', 
            render_metadata: { 
              ...videoJob.render_metadata,
              error: error.message,
              failed_at: new Date().toISOString(),
              stack_trace: error.stack,
            }
          })
          .eq('id', videoJob.id);
      });

    // AC 9: Return 202 Accepted with job ID
    return new Response(JSON.stringify({ 
      jobId: videoJob.id, 
      status: 'queued',
      message: 'Video generation started',
      estimated_time_minutes: 5,
      priority,
      question: {
        year: question.year,
        paper_type: question.paper_type,
        subject: question.subject,
      }
    }), { 
      status: 202,
      headers: { 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Unexpected error in pyq_video_explanation_pipe:', error);
    return new Response(
      JSON.stringify({ 
        error: 'Internal Server Error', 
        message: error.message,
        timestamp: new Date().toISOString()
      }), 
      { 
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      }
    );
  }
});
