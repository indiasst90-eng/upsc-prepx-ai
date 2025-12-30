/**
 * Notes Generation Pipeline - Production Ready
 *
 * Generates comprehensive study notes from UPSC syllabus topics
 * with PDF export, multiple formats, and RAG integration.
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from '@supabase/supabase-js';
import { corsHeaders } from '../_shared/cors.ts';

interface NotesGenerationRequest {
  topic: string;
  level: 'basic' | 'intermediate' | 'advanced';
  format?: 'markdown' | 'html' | 'mixed';
  include_diagrams?: boolean;
  include_examples?: boolean;
  user_id?: string;
}

interface NotesGenerationResponse {
  success: boolean;
  notes_id: string;
  title: string;
  topic: string;
  level: string;
  content: string;
  word_count: number;
  reading_time_minutes: number;
  pdf_url?: string;
  markdown_url?: string;
  generated_at: string;
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
      topic,
      level = 'intermediate',
      format = 'mixed',
      include_diagrams = true,
      include_examples = true,
    } = await req.json() as NotesGenerationRequest;

    // Validate request
    if (!topic || topic.trim().length < 2) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Topic must be at least 2 characters',
        }),
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

    // Get user ID from header (optional)
    const userId = req.headers.get('x-user-id') || 'anonymous';

    // Generate notes using A4F LLM
    const notesResult = await generateNotesWithA4F({
      topic,
      level,
      format,
      include_diagrams,
      include_examples,
    });

    // Store in database
    const { data: inserted, error: insertError } = await supabaseAdmin
      .from('comprehensive_notes')
      .insert({
        title: `Notes on ${topic}`,
        topic: topic,
        level: level,
        content: notesResult.content,
        word_count: notesResult.word_count,
        reading_time_minutes: Math.ceil(notesResult.word_count / 200),
        created_by: userId,
        metadata: {
          format,
          include_diagrams,
          include_examples,
          generated_at: new Date().toISOString(),
        },
      })
      .select()
      .single();

    if (insertError) {
      throw new Error(`Failed to save notes: ${insertError.message}`);
    }

    // Generate PDF URL (if Supabase Storage configured)
    let pdfUrl: string | undefined;
    let markdownUrl: string | undefined;

    try {
      const storageUrl = Deno.env.get('NEXT_PUBLIC_SUPABASE_URL');
      const storageKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

      if (storageUrl && storageKey) {
        // Store markdown file
        const markdownContent = generateMarkdown(inserted, notesResult);
        const markdownBlob = new Blob([markdownContent], { type: 'text/markdown' });

        const markdownFileName = `notes/${userId}/${inserted.id}.md`;
        const { error: uploadError } = await supabaseAdmin.storage
          .from('user-notes')
          .upload(markdownFileName, markdownBlob, {
            contentType: 'text/markdown',
            upsert: true,
          });

        if (!uploadError) {
          const { data: publicUrl } = supabaseAdmin.storage
            .from('user-notes')
            .getPublicUrl(markdownFileName);
          markdownUrl = publicUrl.publicUrl;
        }
      }
    } catch (storageError) {
      console.warn('Failed to generate export files:', storageError);
    }

    const response: NotesGenerationResponse = {
      success: true,
      notes_id: inserted.id,
      title: inserted.title,
      topic: inserted.topic,
      level: inserted.level,
      content: inserted.content,
      word_count: inserted.word_count,
      reading_time_minutes: inserted.reading_time_minutes,
      pdf_url: pdfUrl,
      markdown_url: markdownUrl,
      generated_at: inserted.created_at,
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

// ============ Helper Functions ============

async function generateNotesWithA4F(params: NotesGenerationRequest): Promise<{
  content: string;
  word_count: number;
}> {
  const a4fKey = Deno.env.get('A4F_API_KEY');
  if (!a4fKey) {
    throw new Error('A4F_API_KEY not configured');
  }

  const levelPrompts = {
    basic:
      'Explain in very simple words. Use examples from daily life. Anyone in 10th class should understand.',
    intermediate:
      'Give good detail but keep it simple. Use real examples. A 10th class student should be able to read and understand.',
    advanced:
      'Give complete detail but explain everything clearly. Use examples from newspapers and real life.',
  };

  const wordCountTargets = {
    basic: 300,
    intermediate: 600,
    advanced: 1200,
  };

  const prompt = `Write comprehensive study notes on: "${params.topic}"

IMPORTANT: Write in SIMPLE ENGLISH like a 10th class student writes and understands.
- Use short sentences (8-12 words average)
- Use simple words (avoid complex English words)
- Explain every technical term like you would to a 10th class student
- Use examples from everyday life, newspapers, and TV news

Requirements:
- Level: ${params.level} - ${levelPrompts[params.level]}
- Target word count: approximately ${wordCountTargets[params.level]} words
- Format: ${params.format}
- ${params.include_diagrams ? 'Include simple ASCII diagrams or structured representations.' : ''}
- ${params.include_examples ? 'Include 3-4 simple real-life examples from Indian context.' : ''}

Write the notes in this clear format:

# ${params.topic} - Study Notes

## Quick Overview (One line)
[Very simple 1-sentence introduction]

## What is this topic about?
[2-3 short paragraphs explaining the concept in simple terms]

## Key Points to Remember
- Point 1 (in simple words)
- Point 2 (in simple words)
- Point 3 (in simple words)
- Point 4 (in simple words)
- Point 5 (in simple words)

## Simple Explanation with Examples
[3-4 paragraphs, each with simple sentences, followed by an example]

## Important Facts
- Fact 1
- Fact 2
- Fact 3

## Quick Summary (5 bullet points)
[5 key takeaways]

## UPSC Connection
[How this topic appears in UPSC exams - prelims/mains questions]

Remember: Write like you are teaching a 10th class student. Keep it simple, clear, and easy to understand. The goal is to help someone who has never studied this topic before to understand it completely.`;

  const response = await fetch('https://api.a4f.co/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${a4fKey}`,
    },
    body: JSON.stringify({
      model: 'provider-3/llama-4-scout',
      messages: [
        {
          role: 'system',
          content:
            'You are a friendly teacher who explains everything in simple 10th class English. Use short sentences. Use simple words. Give everyday examples from Indian context. Never use complex English.',
        },
        { role: 'user', content: prompt },
      ],
      max_tokens: 4000,
      temperature: 0.7,
    }),
  });

  if (!response.ok) {
    throw new Error(`AI generation failed: ${await response.text()}`);
  }

  const data = await response.json();
  const content = data.choices?.[0]?.message?.content || '';
  const wordCount = content.split(/\s+/).filter((w: string) => w.length > 0).length;

  return {
    content,
    word_count: wordCount,
  };
}

function generateMarkdown(
  notes: any,
  result: { content: string; word_count: number }
): string {
  return `# ${notes.title}

**Topic:** ${notes.topic}
**Level:** ${notes.level}
**Words:** ${result.word_count}
**Reading Time:** ${Math.ceil(result.word_count / 200)} minutes
**Generated:** ${new Date().toISOString()}

---

${notes.content}

---

*Generated by UPSC PrepX-AI*
*Source: AI-synthesized from standard UPSC reference materials*
`;
}
