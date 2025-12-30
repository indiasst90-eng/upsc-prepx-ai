/**
 * Documentary Script Generator - Long-form Content
 *
 * Generates 2-3 hour documentary-style lecture scripts from topic content.
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from '@supabase/supabase-js';
import { corsHeaders } from '../_shared/cors.ts';

interface DocumentaryRequest {
  topic: string;
  syllabus_node_id?: string;
  duration_hours?: number; // 2 or 3
  style?: 'chronological' | 'thematic' | 'problem-solution';
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  const startTime = Date.now();
  const { topic, syllabus_node_id, duration_hours = 3, style = 'chronological' } = await req.json() as DocumentaryRequest;

  if (!topic) {
    return new Response(
      JSON.stringify({ error: 'Topic is required' }),
      { status: 400 }
    );
  }

  try {
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    // Fetch relevant content from RAG
    const { data: chunks } = await supabaseAdmin
      .from('knowledge_chunks')
      .select('*')
      .ilike('topics', `%${topic}%`)
      .order('relevance_score', { ascending: false })
      .limit(20);

    const contextData = chunks?.map((c: any) => c.content).join('\n\n').slice(0, 10000) || '';

    // Fetch syllabus context
    let syllabusContext = '';
    if (syllabus_node_id) {
      const { data: node } = await supabaseAdmin
        .from('syllabus_nodes')
        .select('*')
        .eq('id', syllabus_node_id)
        .single();

      if (node) {
        syllabusContext = `
Syllabus Context:
Title: ${node.title}
Description: ${node.description || 'N/A'}
Parent: ${node.parent_name || 'N/A'}
        `;
      }
    }

    const a4fKey = Deno.env.get('A4F_API_KEY');

    // Generate documentary structure
    const targetWords = duration_hours === 3 ? 18000 : 12000;
    const chapterCount = duration_hours === 3 ? 8 : 5;
    const wordsPerChapter = Math.floor(targetWords / chapterCount);

    // Generate chapters
    const chapters: any[] = [];
    const chapterThemes = getChapterThemes(topic, style);

    for (let i = 0; i < chapterCount; i++) {
      const chapter = await generateChapter(
        a4fKey,
        topic,
        chapterThemes[i],
        i + 1,
        chapterCount,
        wordsPerChapter,
        contextData,
        syllabusContext
      );
      chapters.push(chapter);
    }

    // Generate intro
    const intro = await generateIntro(a4fKey, topic, chapters, contextData, syllabusContext);

    // Generate conclusion
    const conclusion = await generateConclusion(a4fKey, topic, chapters, contextData);

    // Calculate totals
    const totalWords = intro.wordCount + chapters.reduce((sum: number, c: any) => sum + c.wordCount, 0) + conclusion.wordCount;
    const totalDuration = Math.round(totalWords / 150); // 150 words per minute for narration

    const scriptData = {
      topic,
      duration_hours,
      style,
      intro,
      chapters,
      conclusion,
      total_duration_minutes: totalDuration,
      total_words: totalWords,
      status: 'pending_visuals',
      created_at: new Date().toISOString(),
    };

    // Save to database
    const { data: script, error } = await supabaseAdmin
      .from('documentary_scripts')
      .insert(scriptData)
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to save script: ${error.message}`);
    }

    return new Response(
      JSON.stringify({
        success: true,
        data: {
          ...script,
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
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    );
  }
});

/**
 * Get chapter themes based on topic and style
 */
function getChapterThemes(topic: string, style: string): string[] {
  if (style === 'chronological') {
    return [
      `Introduction to ${topic} - Historical Background`,
      `Early Developments and Key Events`,
      `Major Turning Points`,
      `Evolution and Changes Over Time`,
      `Modern Era and Contemporary Context`,
      `Current Scenario and Recent Trends`,
      `Future Implications and Outlook`,
      `Summary and Key Takeaways`,
    ];
  } else if (style === 'thematic') {
    return [
      `Core Concepts and Fundamentals`,
      `Social and Cultural Dimensions`,
      `Economic Aspects`,
      `Political and Governance Issues`,
      `International Perspective`,
      `Challenges and Opportunities`,
      `Case Studies and Examples`,
      `Integration and Conclusion`,
    ];
  } else {
    return [
      `Problem Statement and Context`,
      `Root Causes Analysis`,
      `Current Situation Assessment`,
      `Stakeholder Perspectives`,
      `Existing Solutions and Their Effectiveness`,
      `Alternative Approaches`,
      `Recommendations`,
      `Way Forward`,
    ];
  }
}

/**
 * Generate intro section
 */
async function generateIntro(
  apiKey: string | undefined,
  topic: string,
  chapters: any[],
  contextData: string,
  syllabusContext: string
): Promise<{ narration: string; visualCues: string[]; wordCount: number }> {
  if (!apiKey) {
    return {
      narration: `Welcome to this comprehensive documentary on ${topic}. In the next few hours, we will explore this crucial topic in depth, covering ${chapters.length} major chapters. This content is designed to help you understand not just the facts, but the underlying concepts and their relevance to your UPSC examination.`,
      visualCues: ['[TITLE_CARD]', '[TOPIC_BANNER]', '[LEARNING_OBJECTIVES]'],
      wordCount: 80,
    };
  }

  try {
    const response = await fetch('https://api.a4f.co/v1/chat/completions', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: 'provider-3/llama-4-scout',
        messages: [
          {
            role: 'system',
            content: `Create a 60-90 word introduction for a documentary on "${topic}".
Include:
- Engaging hook
- Why this topic matters for UPSC
- What will be covered (${chapters.length} chapters)
Use simple 10th class English.`,
          },
          {
            role: 'user',
            content: `Topic: ${topic}\n\nSyllabus Context:\n${syllabusContext}\n\nContext:\n${contextData.slice(0, 1000)}`,
          },
        ],
        max_tokens: 200,
        temperature: 0.7,
      }),
    });

    if (response.ok) {
      const data = await response.json();
      const narration = data.choices?.[0]?.message?.content?.trim() || '';
      return {
        narration,
        visualCues: ['[TITLE_CARD]', '[TOPIC_BANNER]', '[CHAPTER_PREVIEW]'],
        wordCount: narration.split(/\s+/).length,
      };
    }
  } catch (error) {
    console.warn('Intro generation failed:', error);
  }

  return {
    narration: `Welcome to this documentary on ${topic}. Over the next few hours, we will explore this important topic in depth.`,
    visualCues: ['[TITLE_CARD]'],
    wordCount: 25,
  };
}

/**
 * Generate a single chapter
 */
async function generateChapter(
  apiKey: string | undefined,
  topic: string,
  chapterTheme: string,
  chapterNum: number,
  totalChapters: number,
  wordsTarget: number,
  contextData: string,
  syllabusContext: string
): Promise<{ title: string; narration: string; visualCues: string[]; wordCount: number }> {
  if (!apiKey) {
    return {
      title: chapterTheme,
      narration: `Chapter ${chapterNum}: ${chapterTheme}. This chapter covers the essential aspects of this topic relevant to your UPSC preparation.`,
      visualCues: ['[CHAPTER_TITLE]', '[DIAGRAM]', '[KEY_POINTS]'],
      wordCount: wordsTarget,
    };
  }

  try {
    const response = await fetch('https://api.a4f.co/v1/chat/completions', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: 'provider-3/llama-4-scout',
        messages: [
          {
            role: 'system',
            content: `Create Chapter ${chapterNum} of ${totalChapters} for a documentary on "${topic}".
Theme: ${chapterTheme}

Requirements:
- ${wordsTarget} words
- Include visual markers: [DIAGRAM], [TIMELINE], [MAP], [IMAGE], [INTERVIEW_CLIP]
- Include key points for UPSC
- Use simple 10th class English
- Structure: Context → Details → Examples → Key Takeaways`,
          },
          {
            role: 'user',
            content: `Generate the narration for this chapter:\n\nContext from syllabus:\n${syllabusContext}\n\nReference material:\n${contextData.slice(0, 2000)}`,
          },
        ],
        max_tokens: 4000,
        temperature: 0.7,
      }),
    });

    if (response.ok) {
      const data = await response.json();
      const narration = data.choices?.[0]?.message?.content?.trim() || '';
      return {
        title: chapterTheme,
        narration,
        visualCues: ['[CHAPTER_BANNER]', '[VISUAL_AID]', '[SUMMARY_CARD]'],
        wordCount: narration.split(/\s+/).length,
      };
    }
  } catch (error) {
    console.warn(`Chapter ${chapterNum} generation failed:`, error);
  }

  return {
    title: chapterTheme,
    narration: `Chapter ${chapterNum}: ${chapterTheme}. This is an important section of our documentary on ${topic}.`,
    visualCues: ['[CHAPTER_TITLE]'],
    wordCount: 20,
  };
}

/**
 * Generate conclusion section
 */
async function generateConclusion(
  apiKey: string | undefined,
  topic: string,
  chapters: any[],
  contextData: string
): Promise<{ narration: string; visualCues: string[]; wordCount: number }> {
  if (!apiKey) {
    return {
      narration: `This concludes our documentary on ${topic}. Remember, consistent revision is the key to success in UPSC. We covered ${chapters.length} important chapters today. Review these topics regularly and practice answer writing to strengthen your preparation.`,
      visualCues: ['[SUMMARY]', '[KEY_TAKEAWAYS]', '[NEXT_TOPIC_PREVIEW]'],
      wordCount: 50,
    };
  }

  try {
    const response = await fetch('https://api.a4f.co/v1/chat/completions', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: 'provider-3/llama-4-scout',
        messages: [
          {
            role: 'system',
            content: `Create a 60-90 word conclusion for a documentary on "${topic}".
Include:
- Summary of key points
- Exam relevance reminder
- Call to action for revision and practice
Use simple 10th class English.`,
          },
          {
            role: 'user',
            content: `Conclusion for documentary on ${topic}. Covered ${chapters.length} chapters.`,
          },
        ],
        max_tokens: 200,
        temperature: 0.7,
      }),
    });

    if (response.ok) {
      const data = await response.json();
      const narration = data.choices?.[0]?.message?.content?.trim() || '';
      return {
        narration,
        visualCues: ['[SUMMARY]', '[KEY_TAKEAWAYS]', '[EXAM_TIPS]'],
        wordCount: narration.split(/\s+/).length,
      };
    }
  } catch (error) {
    console.warn('Conclusion generation failed:', error);
  }

  return {
    narration: `This concludes our documentary on ${topic}. Review these topics regularly for your UPSC preparation.`,
    visualCues: ['[CONCLUSION]'],
    wordCount: 20,
  };
}
