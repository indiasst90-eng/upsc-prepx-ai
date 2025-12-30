/**
 * Topic Shorts Pipeline - 60-Second Video Generation
 *
 * Generates short explainer videos for any syllabus topic.
 * Features:
 * - Cache-first strategy (7-day cache)
 * - Credit-based access
 * - Fixed 150-word script format
 * - 1 simple Manim diagram + TTS
 * - <45s generation time target
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from '@supabase/supabase-js';
import { corsHeaders } from '../_shared/cors.ts';

interface TopicShortRequest {
  syllabus_node_id: string;
  user_id?: string;
}

interface TopicShortResponse {
  success: boolean;
  job_id?: string;
  video_url?: string;
  cached?: boolean;
  credits_cost: number;
  error?: string;
}

interface TopicShort {
  id: string;
  user_id: string;
  syllabus_node_id: string;
  video_url: string | null;
  script_text: string | null;
  status: 'pending' | 'processing' | 'completed' | 'failed';
  cached_until: string | null;
  credits_used: number;
  created_at: string;
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
    const { syllabus_node_id, user_id } = await req.json() as TopicShortRequest;

    if (!syllabus_node_id) {
      return new Response(
        JSON.stringify({ error: 'syllabus_node_id is required' }),
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

    // Fetch topic info
    const { data: topic, error: topicError } = await supabaseAdmin
      .from('syllabus_nodes')
      .select('id, title, description, parent_id')
      .eq('id', syllabus_node_id)
      .single();

    if (topicError || !topic) {
      return new Response(
        JSON.stringify({ error: 'Topic not found' }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 404,
        }
      );
    }

    // Check cache first
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();
    const { data: cachedVideo } = await supabaseAdmin
      .from('topic_shorts')
      .select('*')
      .eq('syllabus_node_id', syllabus_node_id)
      .eq('status', 'completed')
      .gt('cached_until', new Date().toISOString())
      .gt('created_at', sevenDaysAgo)
      .order('created_at', { ascending: false })
      .limit(1)
      .single();

    if (cachedVideo && cachedVideo.video_url) {
      // Return cached video
      return new Response(
        JSON.stringify({
          success: true,
          job_id: cachedVideo.id,
          video_url: cachedVideo.video_url,
          cached: true,
          credits_cost: 0, // Free since cached
          script_text: cachedVideo.script_text,
        } as TopicShortResponse & { cached: boolean; script_text?: string }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    // Entitlement check for non-cached video
    const targetUserId = user_id || req.headers.get('x-user-id');
    const creditsCost = 1;

    if (targetUserId) {
      // Check subscription
      const { data: subscription } = await supabaseAdmin
        .from('subscriptions')
        .select('status, trial_expires_at, credits_remaining')
        .eq('user_id', targetUserId)
        .single();

      const isPro =
        subscription?.status === 'active' ||
        (subscription?.status === 'trial' &&
          subscription?.trial_expires_at &&
          new Date(subscription.trial_expires_at) > new Date());

      // Check credit balance for Pro users
      if (isPro && subscription?.credits_remaining !== null && subscription?.credits_remaining < creditsCost) {
        return new Response(
          JSON.stringify({
            success: false,
            error: 'INSUFFICIENT_CREDITS',
            message: 'You need 1 credit to generate a topic short',
            upgrade_required: false,
            current_credits: subscription.credits_remaining,
            required_credits: creditsCost,
          }),
          {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 402,
          }
        );
      }

      // Free users limit
      if (!isPro) {
        const today = new Date().toISOString().split('T')[0];
        const { count } = await supabaseAdmin
          .from('topic_shorts')
          .select('*', { count: 'exact', head: true })
          .eq('user_id', targetUserId)
          .gte('created_at', today);

        if (count >= 2) {
          return new Response(
            JSON.stringify({
              success: false,
              error: 'DAILY_LIMIT_REACHED',
              message: 'You can generate 2 topic shorts per day on the free plan',
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

    // Generate script using RAG context
    const script = await generateTopicScript(topic, supabaseAdmin);

    // Create topic short record
    const { data: topicShort, error: insertError } = await supabaseAdmin
      .from('topic_shorts')
      .insert({
        user_id: targetUserId || 'anonymous',
        syllabus_node_id,
        script_text: script,
        status: 'processing',
        cached_until: null,
        credits_used: creditsCost,
        created_at: new Date().toISOString(),
      })
      .select()
      .single();

    if (insertError) {
      throw new Error(`Failed to create topic short: ${insertError.message}`);
    }

    // Trigger video generation
    const orchestratorUrl = Deno.env.get('VPS_ORCHESTRATOR_URL');
    if (orchestratorUrl) {
      try {
        await fetch(`${orchestratorUrl}/render_topic_short`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            topic_short_id: topicShort.id,
            topic_title: topic.title,
            script: script,
            user_id: targetUserId,
          }),
        });
      } catch (orchestratorError) {
        console.warn('Orchestrator unreachable for topic short:', orchestratorError);
      }
    }

    const response: TopicShortResponse = {
      success: true,
      job_id: topicShort.id,
      credits_cost: creditsCost,
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

/**
 * Generate 150-word topic script using RAG context
 */
async function generateTopicScript(topic: any, supabase: any): Promise<string> {
  const a4fKey = Deno.env.get('A4F_API_KEY');
  if (!a4fKey) {
    // Return simple fallback script
    return generateFallbackScript(topic.title, topic.description);
  }

  try {
    // Fetch RAG context for this topic
    const { data: chunks } = await supabase
      .from('knowledge_chunks')
      .select('content, source_file')
      .eq('syllabus_node_id', topic.id)
      .limit(5);

    const context = chunks?.map((c: any) => c.content).join('\n\n') || topic.description || '';

    // Generate script with A4F
    const response = await fetch('https://api.a4f.co/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${a4fKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'provider-3/llama-4-scout',
        messages: [
          {
            role: 'system',
            content: `You are an expert UPSC educator creating a 60-second video script.
Requirements:
- Exactly 150 words
- Simple 10th-class English level
- Structure: Hook (10 words) → Topic intro (20 words) → 3 key points (90 words) → Quick summary (30 words)
- Include visual cues like [DIAGRAM: process] or [DIAGRAM: comparison]
- No markdown, just plain text`,
          },
          {
            role: 'user',
            content: `Create a 60-second explainer script for: "${topic.title}"

Context from knowledge base:
${context.slice(0, 2000)}

Topic description: ${topic.description || 'No description available'}

Generate the script now:`,
          },
        ],
        max_tokens: 500,
        temperature: 0.7,
      }),
    });

    if (response.ok) {
      const data = await response.json();
      let script = data.choices?.[0]?.message?.content || '';
      // Ensure it's around 150 words
      return truncateToWords(script, 160);
    }
  } catch (error) {
    console.warn('Script generation failed, using fallback:', error);
  }

  return generateFallbackScript(topic.title, topic.description);
}

function generateFallbackScript(title: string, description: string): string {
  return `Let's understand ${title}.

This is a crucial topic for your UPSC preparation. ${description?.slice(0, 200) || 'This concept appears frequently in exams.'}

Here are the three key points to remember:

First, ${title} relates directly to the foundational framework of the subject. Understanding this helps you build core concepts.

Second, practical applications matter. In previous year questions, examiners test your ability to connect theory with real-world scenarios.

Third, remember to compare and contrast. Questions often ask you to analyze relationships between different aspects.

In summary, ${title} is essential for both prelims and mains. Focus on understanding rather than rote learning. Practice previous year questions to master this topic.`;
}

function truncateToWords(text: string, maxWords: number): string {
  const words = text.split(/\s+/);
  if (words.length <= maxWords) return text;
  return words.slice(0, maxWords).join(' ') + '...';
}

// Webhook handler for topic short completion
export async function handleTopicShortWebhook(req: Request): Promise<Response> {
  try {
    const { topic_short_id, status, video_url, thumbnail_url, error } = await req.json();

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    const updateData: any = {
      status,
      updated_at: new Date().toISOString(),
    };

    if (status === 'completed') {
      updateData.video_url = video_url;
      updateData.thumbnail_url = thumbnail_url;
      updateData.cached_until = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString();
    } else if (status === 'failed') {
      updateData.error_message = error;
    }

    await supabaseAdmin.from('topic_shorts').update(updateData).eq('id', topic_short_id);

    // Deduct credits if successful
    if (status === 'completed') {
      const { data: short } = await supabaseAdmin
        .from('topic_shorts')
        .select('user_id, credits_used')
        .eq('id', topic_short_id)
        .single();

      if (short && short.user_id !== 'anonymous') {
        await supabaseAdmin.rpc('deduct_user_credits', {
          user_id: short.user_id,
          amount: short.credits_used || 1,
        });
      }
    }

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
