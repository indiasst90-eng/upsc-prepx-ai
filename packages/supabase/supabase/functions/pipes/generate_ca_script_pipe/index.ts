/**
 * Daily CA Script Generator - Pipeline
 *
 * Generates structured video script from scraped articles.
 * Runs at 5:15 AM IST after scraper completes.
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from '@supabase/supabase-js';
import { corsHeaders } from '../_shared/cors.ts';

interface ScriptGenerationRequest {
  date?: string;
  force_regenerate?: boolean;
}

interface ScriptSection {
  title: string;
  duration_seconds: number;
  articles: Array<{
    id: string;
    title: string;
    summary: string;
    source: string;
    gs_markers: string[];
  }>;
  narration: string;
  visual_cues: string[];
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  const startTime = Date.now();
  const { date, force_regenerate } = await req.json() as ScriptGenerationRequest;

  const today = date || new Date().toISOString().split('T')[0];

  try {
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    // Check for existing script
    const { data: existingScript } = await supabaseAdmin
      .from('daily_ca_scripts')
      .select('*')
      .eq('date', today)
      .single();

    if (existingScript && !force_regenerate) {
      return new Response(
        JSON.stringify({
          success: true,
          data: existingScript,
          cached: true,
        }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    // Fetch today's articles
    const { data: articles, error: articlesError } = await supabaseAdmin
      .from('daily_updates')
      .select('*')
      .eq('date', today)
      .eq('status', 'pending_video')
      .order('relevance_score', { ascending: false })
      .limit(15);

    if (articlesError || !articles || articles.length === 0) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'No articles found for today',
          article_count: articles?.length || 0,
        }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 404,
        }
      );
    }

    // Group articles by topic
    const topicGroups = groupArticlesByTopic(articles);

    // Generate script sections
    const sections: ScriptSection[] = [];

    // Intro section
    const introSection: ScriptSection = {
      title: 'Introduction',
      duration_seconds: 30,
      articles: [],
      narration: `Good morning UPSC aspirants! Here's your daily dose of current affairs for ${formatDate(today)}. Today we'll cover ${topicGroups.length} important topics that are crucial for your preparation. Let's dive in!`,
      visual_cues: ['[TITLE_CARD]', '[DATE_DISPLAY]'],
    };
    sections.push(introSection);

    // Topic sections (2-3 minutes each)
    const a4fKey = Deno.env.get('A4F_API_KEY');

    for (const [topic, topicArticles] of Object.entries(topicGroups)) {
      if (topicArticles.length === 0) continue;

      const narration = a4fKey
        ? await generateTopicNarration(topic, topicArticles, a4fKey)
        : generateDefaultNarration(topic, topicArticles);

      sections.push({
        title: topic,
        duration_seconds: 120,
        articles: topicArticles.map((a) => ({
          id: a.id,
          title: a.title,
          summary: a.summary || '',
          source: a.source_name,
          gs_markers: a.papers || [],
        })),
        narration,
        visual_cues: ['[TOPIC_BANNER]', '[ARTICLE_CARDS]', '[KEY_POINT_HIGHLIGHT]'],
      });
    }

    // Conclusion with MCQ preview
    const conclusionSection: ScriptSection = {
      title: 'Conclusion & Practice',
      duration_seconds: 45,
      articles: [],
      narration: `That wraps up today's current affairs. Remember, regular revision is key! Here's a quick MCQ to test your understanding of today's topics. We'll cover the answers in tomorrow's edition. Stay focused, stay motivated!`,
      visual_cues: ['[MCQ_CARD]', '[NEXT_PREVIEW]', '[SUBSCRIBE_REMINDER]'],
    };
    sections.push(conclusionSection);

    // Calculate totals
    const totalWords = sections.reduce((sum, s) => sum + s.narration.split(/\s+/).length, 0);
    const totalDuration = sections.reduce((sum, s) => sum + s.duration_seconds, 0);

    // Prepare script data
    const scriptData = {
      date: today,
      script_sections: sections,
      total_duration_seconds: totalDuration,
      word_count: totalWords,
      article_count: articles.length,
      topics_covered: Object.keys(topicGroups),
      status: 'pending_visuals',
      generated_at: new Date().toISOString(),
    };

    // Save to database
    const { data: script, error } = await supabaseAdmin
      .from('daily_ca_scripts')
      .upsert(scriptData, { onConflict: 'date' })
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to save script: ${error.message}`);
    }

    // Update article statuses
    await supabaseAdmin
      .from('daily_updates')
      .update({ status: 'queued_script' })
      .eq('date', today)
      .eq('status', 'pending_video');

    // Queue video generation
    await supabaseAdmin.from('job_queue').insert({
      job_type: 'render_daily_ca',
      payload: { script_id: script.id, date: today },
      status: 'queued',
      created_at: new Date().toISOString(),
    });

    return new Response(
      JSON.stringify({
        success: true,
        data: {
          ...script,
          sections_count: sections.length,
          processing_time_seconds: (Date.now() - startTime) / 1000,
        },
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({
        success: false,
        error: (error as Error).message,
        processing_time_seconds: (Date.now() - startTime) / 1000,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    );
  }
});

/**
 * Group articles by topic using simple keyword matching
 */
function groupArticlesByTopic(articles: any[]): Record<string, any[]> {
  const topicKeywords: Record<string, string[]> = {
    'Polity & Governance': ['constitution', 'parliament', 'supreme court', 'governance', 'policy', 'amendment', 'bill', 'act', 'rights', 'federal'],
    'Economy': ['economy', 'economic', 'gdp', 'inflation', 'trade', 'budget', 'finance', 'banking', 'monetary', 'fiscal', 'market', 'stock'],
    'International Relations': ['india', 'china', 'usa', 'russia', 'un', 'diplomacy', 'foreign', 'treaty', 'agreement', 'bilateral', 'multilateral', 'global'],
    'Environment & Ecology': ['environment', 'climate', 'pollution', 'biodiversity', 'conservation', 'wildlife', 'sustainable', 'carbon', 'green', 'ecosystem'],
    'Science & Technology': ['technology', 'science', 'ai', 'digital', 'space', 'research', 'innovation', 'cyber', 'technology'],
    'Social Issues': ['social', 'education', 'health', 'women', 'poverty', 'inequality', 'employment', 'welfare', 'scheme'],
    'Security & Defense': ['security', 'defense', 'military', 'border', 'terrorism', 'intelligence', 'force', 'army'],
  };

  const groups: Record<string, any[]> = {};

  // Initialize groups
  for (const topic of Object.keys(topicKeywords)) {
    groups[topic] = [];
  }
  groups['Other'] = [];

  for (const article of articles) {
    const text = `${article.title} ${article.summary || ''} ${article.body_text || ''}`.toLowerCase();
    let assigned = false;

    for (const [topic, keywords] of Object.entries(topicKeywords)) {
      if (keywords.some((kw) => text.includes(kw))) {
        groups[topic].push(article);
        assigned = true;
        break;
      }
    }

    if (!assigned) {
      groups['Other'].push(article);
    }
  }

  // Remove empty groups
  const result: Record<string, any[]> = {};
  for (const [topic, articlesList] of Object.entries(groups)) {
    if (articlesList.length > 0) {
      result[topic] = articlesList;
    }
  }

  return result;
}

/**
 * Generate topic narration using AI
 */
async function generateTopicNarration(topic: string, articles: any[], apiKey: string): Promise<string> {
  try {
    const articleSummaries = articles
      .map((a, i) => `${i + 1}. ${a.title}: ${(a.summary || '').slice(0, 200)}`)
      .join('\n');

    const response = await fetch('https://api.a4f.co/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'provider-3/llama-4-scout',
        messages: [
          {
            role: 'system',
            content: `You are creating a news narration for UPSC aspirants.
Write a 150-200 word narration for this topic section.
Keep it:
- Simple 10th class English
- Exam-focused (mention GS papers where relevant)
- Engaging and concise
- Include transitions between articles`,
          },
          {
            role: 'user',
            content: `Topic: ${topic}

Articles:
${articleSummaries}

Write the narration:`,
          },
        ],
        max_tokens: 400,
        temperature: 0.7,
      }),
    });

    if (response.ok) {
      const data = await response.json();
      return data.choices?.[0]?.message?.content?.trim() || generateDefaultNarration(topic, articles);
    }
  } catch (error) {
    console.warn('AI narration generation failed:', error);
  }

  return generateDefaultNarration(topic, articles);
}

/**
 * Generate default narration without AI
 */
function generateDefaultNarration(topic: string, articles: any[]): string {
  const articleList = articles.map((a, i) => `${i + 1}. ${a.title}`).join(', ');
  return `Let's discuss ${topic}. ${articles.length} important developments today: ${articleList}. These topics are important for your UPSC preparation, especially for understanding current events and their implications.`;
}

/**
 * Format date for display
 */
function formatDate(dateStr: string): string {
  const date = new Date(dateStr);
  return date.toLocaleDateString('en-US', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  });
}
