/**
 * Story 10.3: Weekly Documentary - Current Affairs Analysis
 * Edge Function: generate_weekly_doc_pipe.ts
 * 
 * AC 1: Trigger every Sunday at 8 PM IST
 * 
 * This Edge Function is scheduled via Supabase cron job to run at:
 * - 14:30 UTC (8 PM IST) every Sunday
 * 
 * Cron schedule: 30 14 * * 0
 */

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// Configuration
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const API_BASE_URL = Deno.env.get('API_BASE_URL') || 'https://your-app.vercel.app';

// IST is UTC+5:30, so 8 PM IST = 14:30 UTC
const TRIGGER_HOUR_UTC = 14;
const TRIGGER_MINUTE_UTC = 30;

interface GenerationResult {
  success: boolean;
  doc_id?: string;
  error?: string;
  triggered_at: string;
}

serve(async (req: Request): Promise<Response> => {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  };

  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
    const now = new Date();
    
    console.log(`[Weekly Doc Pipe] Triggered at ${now.toISOString()}`);
    
    // Verify it's Sunday (0 = Sunday in JavaScript)
    const dayOfWeek = now.getUTCDay();
    const isScheduledTime = 
      dayOfWeek === 0 && // Sunday
      now.getUTCHours() === TRIGGER_HOUR_UTC &&
      now.getUTCMinutes() >= TRIGGER_MINUTE_UTC &&
      now.getUTCMinutes() < TRIGGER_MINUTE_UTC + 30; // 30 min window

    // Check if this is a manual trigger (has body with force: true)
    let forceRun = false;
    try {
      const body = await req.json();
      forceRun = body?.force === true;
    } catch {
      // No body, that's fine
    }

    if (!isScheduledTime && !forceRun) {
      return new Response(
        JSON.stringify({
          success: false,
          message: 'Not scheduled time (Sunday 8 PM IST)',
          current_time: now.toISOString(),
          day_of_week: dayOfWeek,
          expected_day: 0 // Sunday
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      );
    }

    // Calculate week dates
    const weekStart = getWeekStart(now);
    const weekEnd = new Date(weekStart);
    weekEnd.setDate(weekEnd.getDate() + 6);

    console.log(`[Weekly Doc Pipe] Generating for week: ${weekStart.toISOString().split('T')[0]} to ${weekEnd.toISOString().split('T')[0]}`);

    // Check if documentary already exists for this week
    const { data: existingDoc } = await supabase
      .from('weekly_documentaries')
      .select('id, render_status')
      .eq('week_start_date', weekStart.toISOString().split('T')[0])
      .single();

    if (existingDoc && existingDoc.render_status !== 'failed') {
      console.log(`[Weekly Doc Pipe] Documentary already exists: ${existingDoc.id}`);
      return new Response(
        JSON.stringify({
          success: true,
          message: 'Documentary already exists for this week',
          doc_id: existingDoc.id,
          status: existingDoc.render_status
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Trigger the generation pipeline via API
    const result = await triggerGeneration(weekStart);

    // Log the schedule entry
    await supabase.from('weekly_doc_schedule').insert({
      scheduled_time: now.toISOString(),
      triggered_at: now.toISOString(),
      documentary_id: result.doc_id,
      status: result.success ? 'running' : 'failed',
      error_message: result.error
    });

    return new Response(
      JSON.stringify(result),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error: any) {
    console.error('[Weekly Doc Pipe] Error:', error);
    
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
        triggered_at: new Date().toISOString()
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
    );
  }
});

// Get the start of the current week (Monday)
function getWeekStart(date: Date): Date {
  const d = new Date(date);
  const day = d.getUTCDay();
  // Adjust so Monday is the start of the week
  const diff = d.getUTCDate() - day + (day === 0 ? -6 : 1);
  d.setUTCDate(diff);
  d.setUTCHours(0, 0, 0, 0);
  return d;
}

// Trigger generation via API
async function triggerGeneration(weekStart: Date): Promise<GenerationResult> {
  try {
    const response = await fetch(`${API_BASE_URL}/api/weekly-documentary`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`
      },
      body: JSON.stringify({
        action: 'trigger',
        week_start: weekStart.toISOString().split('T')[0]
      })
    });

    const data = await response.json();

    return {
      success: data.success,
      doc_id: data.doc_id,
      error: data.error,
      triggered_at: new Date().toISOString()
    };

  } catch (error: any) {
    return {
      success: false,
      error: error.message,
      triggered_at: new Date().toISOString()
    };
  }
}

/**
 * To deploy this Edge Function:
 * 
 * 1. Create the function:
 *    supabase functions new generate-weekly-doc-pipe
 * 
 * 2. Deploy:
 *    supabase functions deploy generate-weekly-doc-pipe
 * 
 * 3. Set up cron schedule (in Supabase Dashboard > Edge Functions > Schedules):
 *    Schedule: 30 14 * * 0 (Every Sunday at 14:30 UTC = 8 PM IST)
 *    Function: generate-weekly-doc-pipe
 * 
 * 4. Or use SQL to set up pg_cron:
 *    SELECT cron.schedule(
 *      'weekly-documentary-generation',
 *      '30 14 * * 0',
 *      $$
 *      SELECT
 *        net.http_post(
 *          url:='https://your-project.supabase.co/functions/v1/generate-weekly-doc-pipe',
 *          headers:='{"Authorization": "Bearer YOUR_ANON_KEY"}'::jsonb,
 *          body:='{}'::jsonb
 *        ) AS request_id;
 *      $$
 *    );
 */
