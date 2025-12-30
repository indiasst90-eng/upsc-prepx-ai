/**
 * Evaluate Answer Pipeline - AI Answer Evaluation Engine
 * Story 7.2 - Answer AI Evaluation Engine
 *
 * Evaluates UPSC Mains answers using rubric-based scoring:
 * - Content (40%): Keyword coverage, factual accuracy, depth using RAG
 * - Structure (30%): Intro, body, conclusion, logical flow
 * - Language (20%): Grammar, readability, word choice
 * - Examples (10%): Case studies, data points, Acts/Articles
 *
 * Processing time target: < 30 seconds
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// Configuration
const MAX_PROCESSING_TIME_MS = 30000; // 30 seconds
const A4F_BASE_URL = 'https://api.a4f.co/v1';
const PRIMARY_MODEL = 'provider-3/llama-4-scout';
const FALLBACK_MODEL = 'provider-2/gpt-4.1';

interface EvaluationRequest {
  submission_id: string;
  question_text: string;
  answer_text: string;
  syllabus_topic?: string;
  gs_paper?: string;
  word_limit?: number;
}

interface RubricScores {
  content_score: number;      // 0-10 (weight: 40%)
  structure_score: number;    // 0-10 (weight: 30%)
  language_score: number;     // 0-10 (weight: 20%)
  examples_score: number;     // 0-10 (weight: 10%)
  total_score: number;        // 0-40 (sum of all scores)
  weighted_percentage: number; // Weighted percentage score
  feedback: {
    content: string[];
    structure: string[];
    language: string[];
    examples: string[];
    suggestions: string[];
    key_points_missed: string[];
  };
}

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ error: 'Method not allowed' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 405 }
    );
  }

  const startTime = Date.now();

  try {
    const body = await req.json() as EvaluationRequest;
    const { submission_id, question_text, answer_text, syllabus_topic, gs_paper, word_limit } = body;

    // Validate required fields
    if (!submission_id || !question_text || !answer_text) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: submission_id, question_text, answer_text' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
      );
    }

    // Initialize Supabase client
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    // Update submission status to processing
    await supabaseAdmin
      .from('answer_submissions')
      .update({ evaluation_status: 'processing' })
      .eq('id', submission_id);

    // Create timeout promise
    const timeoutPromise = new Promise<never>((_, reject) => {
      setTimeout(() => reject(new Error('Evaluation timeout: exceeded 30 seconds')), MAX_PROCESSING_TIME_MS);
    });

    // Race evaluation against timeout
    const evaluation = await Promise.race([
      performEvaluation(
        supabaseAdmin,
        submission_id,
        question_text,
        answer_text,
        syllabus_topic,
        gs_paper,
        word_limit,
        startTime
      ),
      timeoutPromise,
    ]);

    const processingTime = (Date.now() - startTime) / 1000;

    return new Response(
      JSON.stringify({
        success: true,
        evaluation,
        processing_time_seconds: processingTime,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    const processingTime = (Date.now() - startTime) / 1000;
    const errorMessage = (error as Error).message;

    console.error('Evaluation error:', errorMessage);

    // Try to update submission status to failed
    try {
      const body = await req.clone().json();
      const supabaseAdmin = createClient(
        Deno.env.get('SUPABASE_URL')!,
        Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
      );

      await supabaseAdmin
        .from('answer_submissions')
        .update({ evaluation_status: 'failed' })
        .eq('id', body.submission_id);

      // Save failed evaluation record
      await supabaseAdmin
        .from('answer_evaluations')
        .upsert({
          submission_id: body.submission_id,
          status: 'failed',
          error_message: errorMessage,
          processing_time_seconds: processingTime,
        });
    } catch {}

    return new Response(
      JSON.stringify({
        success: false,
        error: errorMessage,
        processing_time_seconds: processingTime,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
    );
  }
});

/**
 * Main evaluation function with RAG-enhanced content verification
 */
async function performEvaluation(
  supabase: any,
  submissionId: string,
  questionText: string,
  answerText: string,
  syllabusTopic?: string,
  gsPaper?: string,
  wordLimit?: number,
  startTime?: number
): Promise<any> {
  const a4fKey = Deno.env.get('A4F_API_KEY');

  // Step 1: Fetch relevant context from RAG for content verification (AC#3)
  const ragContext = await fetchRAGContext(supabase, questionText, syllabusTopic);

  // Step 2: Extract key concepts from question for content scoring
  const keyConceptsFromQuestion = extractKeyConcepts(questionText);

  // Step 3: Perform AI evaluation with enhanced rubric
  let rubricScores: RubricScores;

  if (a4fKey) {
    rubricScores = await evaluateWithAI(
      a4fKey,
      questionText,
      answerText,
      ragContext,
      keyConceptsFromQuestion,
      wordLimit
    );
  } else {
    rubricScores = evaluateRuleBased(answerText, questionText, ragContext);
  }

  // Calculate processing time
  const processingTimeSeconds = startTime ? (Date.now() - startTime) / 1000 : 0;

  // Step 4: Save evaluation to database (AC#8)
  const evaluationData = {
    submission_id: submissionId,
    content_score: rubricScores.content_score,
    structure_score: rubricScores.structure_score,
    language_score: rubricScores.language_score,
    examples_score: rubricScores.examples_score,
    total_score: rubricScores.total_score,
    feedback_json: rubricScores.feedback,
    status: 'completed',
    processing_time_seconds: processingTimeSeconds,
    completed_at: new Date().toISOString(),
  };

  const { data: evaluation, error } = await supabase
    .from('answer_evaluations')
    .upsert(evaluationData, { onConflict: 'submission_id' })
    .select()
    .single();

  if (error) {
    throw new Error(`Failed to save evaluation: ${error.message}`);
  }

  // Update submission status to completed
  await supabase
    .from('answer_submissions')
    .update({
      evaluation_status: 'completed',
      evaluation_id: evaluation?.id,
    })
    .eq('id', submissionId);

  return {
    ...evaluation,
    weighted_percentage: rubricScores.weighted_percentage,
  };
}

/**
 * Fetch relevant context from RAG for content verification (AC#3)
 */
async function fetchRAGContext(
  supabase: any,
  questionText: string,
  syllabusTopic?: string
): Promise<string> {
  try {
    // Extract keywords from question
    const keywords = questionText
      .toLowerCase()
      .replace(/[^\w\s]/g, '')
      .split(/\s+/)
      .filter(w => w.length > 3 && !['what', 'where', 'when', 'which', 'discuss', 'analyze', 'examine', 'explain', 'describe'].includes(w));

    // Search knowledge chunks by topic and keywords
    let query = supabase
      .from('knowledge_chunks')
      .select('content, source_file, syllabus_node_id')
      .limit(5);

    if (syllabusTopic) {
      query = query.or(`topics.ilike.%${syllabusTopic}%,content.ilike.%${syllabusTopic}%`);
    }

    const { data: chunks } = await query;

    if (chunks && chunks.length > 0) {
      // Combine relevant chunks for context
      return chunks
        .map((c: any) => c.content)
        .join('\n\n')
        .slice(0, 3000);
    }

    return '';
  } catch (error) {
    console.warn('RAG context fetch failed:', error);
    return '';
  }
}

/**
 * Extract key concepts from question for content verification
 */
function extractKeyConcepts(questionText: string): string[] {
  const concepts: string[] = [];

  // Extract quoted terms
  const quotedMatches = questionText.match(/"([^"]+)"/g);
  if (quotedMatches) {
    concepts.push(...quotedMatches.map(m => m.replace(/"/g, '')));
  }

  // Extract capitalized terms (likely proper nouns/concepts)
  const capitalizedMatches = questionText.match(/\b[A-Z][a-z]+(?:\s[A-Z][a-z]+)*\b/g);
  if (capitalizedMatches) {
    concepts.push(...capitalizedMatches.filter(m => m.length > 2));
  }

  // Extract key action words that indicate what should be covered
  const actionWords = ['discuss', 'analyze', 'examine', 'evaluate', 'compare', 'contrast', 'explain', 'describe', 'assess', 'critically'];
  const questionLower = questionText.toLowerCase();

  for (const action of actionWords) {
    if (questionLower.includes(action)) {
      concepts.push(`${action}_required`);
    }
  }

  return [...new Set(concepts)];
}

/**
 * AI-based evaluation using A4F with enhanced rubric (AC#1-7)
 */
async function evaluateWithAI(
  apiKey: string,
  questionText: string,
  answerText: string,
  ragContext: string,
  keyConcepts: string[],
  wordLimit?: number
): Promise<RubricScores> {
  const wordCount = answerText.trim().split(/\s+/).filter(Boolean).length;

  // Build comprehensive evaluation prompt (AC#7)
  const prompt = buildEvaluationPrompt(questionText, answerText, ragContext, keyConcepts, wordCount, wordLimit);

  try {
    // Try primary model
    let response = await callAIModel(apiKey, PRIMARY_MODEL, prompt);

    if (!response.ok) {
      console.warn('Primary model failed, trying fallback');
      response = await callAIModel(apiKey, FALLBACK_MODEL, prompt);
    }

    if (!response.ok) {
      console.error('All AI models failed');
      return evaluateRuleBased(answerText, questionText, ragContext);
    }

    const data = await response.json();
    const content = data.choices?.[0]?.message?.content || '';

    return parseAIResponse(content, answerText, questionText, ragContext);

  } catch (error) {
    console.error('AI evaluation error:', error);
    return evaluateRuleBased(answerText, questionText, ragContext);
  }
}

/**
 * Build comprehensive evaluation prompt
 */
function buildEvaluationPrompt(
  questionText: string,
  answerText: string,
  ragContext: string,
  keyConcepts: string[],
  wordCount: number,
  wordLimit?: number
): string {
  return `You are a senior UPSC Mains examiner. Evaluate this answer for question: "${questionText}"

**RUBRIC (AC#1):**
- Content (40%): Keyword coverage, factual accuracy, depth of analysis, integration with current affairs
- Structure (30%): Introduction, body paragraphs, conclusion, logical flow, direct answer to question
- Language (20%): Grammar, sentence complexity, word choice, readability, formal academic tone
- Examples (10%): Case studies, statistics, committee reports, Acts/Articles, Supreme Court judgments

**KEY CONCEPTS TO COVER:** ${keyConcepts.join(', ') || 'General UPSC topics'}

${ragContext ? `**REFERENCE MATERIAL FOR FACTUAL VERIFICATION:**\n${ragContext}\n` : ''}

**STUDENT'S ANSWER:**
"${answerText}"

**WORD COUNT:** ${wordCount}${wordLimit ? ` / ${wordLimit} required` : ''}

**EVALUATION INSTRUCTIONS:**
1. Score each rubric category 0-10 (AC#9)
2. Identify specific strengths and weaknesses
3. Check factual accuracy against reference material if provided
4. Note which key concepts were covered vs missed
5. Provide actionable improvement suggestions

**RETURN JSON ONLY:**
{
  "content": <0-10>,
  "structure": <0-10>,
  "language": <0-10>,
  "examples": <0-10>,
  "content_feedback": ["specific feedback 1", "specific feedback 2"],
  "structure_feedback": ["specific feedback 1", "specific feedback 2"],
  "language_feedback": ["specific feedback 1"],
  "examples_feedback": ["specific feedback 1"],
  "suggestions": ["actionable suggestion 1", "actionable suggestion 2"],
  "key_points_missed": ["missed point 1", "missed point 2"]
}`;
}

/**
 * Call AI model with timeout
 */
async function callAIModel(apiKey: string, model: string, prompt: string): Promise<Response> {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 25000); // 25 second timeout for AI call

  try {
    const response = await fetch(`${A4F_BASE_URL}/chat/completions`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model,
        messages: [
          {
            role: 'system',
            content: 'You are an expert UPSC Mains examiner. Always return valid JSON only, no markdown or explanation.',
          },
          { role: 'user', content: prompt },
        ],
        max_tokens: 1500,
        temperature: 0.3,
      }),
      signal: controller.signal,
    });

    clearTimeout(timeoutId);
    return response;
  } catch (error) {
    clearTimeout(timeoutId);
    throw error;
  }
}

/**
 * Parse AI response and extract scores
 */
function parseAIResponse(
  content: string,
  answerText: string,
  questionText: string,
  ragContext: string
): RubricScores {
  try {
    // Extract JSON from response
    const jsonMatch = content.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      const parsed = JSON.parse(jsonMatch[0]);

      // Validate and clamp scores to 0-10
      const contentScore = Math.min(10, Math.max(0, Number(parsed.content) || 5));
      const structureScore = Math.min(10, Math.max(0, Number(parsed.structure) || 5));
      const languageScore = Math.min(10, Math.max(0, Number(parsed.language) || 5));
      const examplesScore = Math.min(10, Math.max(0, Number(parsed.examples) || 5));

      // Calculate total (out of 40) and weighted percentage (AC#9)
      const totalScore = contentScore + structureScore + languageScore + examplesScore;
      const weightedPercentage = (
        (contentScore * 0.4) +
        (structureScore * 0.3) +
        (languageScore * 0.2) +
        (examplesScore * 0.1)
      ) * 10; // Scale to 0-100%

      return {
        content_score: Math.round(contentScore * 10) / 10,
        structure_score: Math.round(structureScore * 10) / 10,
        language_score: Math.round(languageScore * 10) / 10,
        examples_score: Math.round(examplesScore * 10) / 10,
        total_score: Math.round(totalScore * 10) / 10,
        weighted_percentage: Math.round(weightedPercentage * 10) / 10,
        feedback: {
          content: parsed.content_feedback || ['Good coverage of topic'],
          structure: parsed.structure_feedback || ['Well-organized answer'],
          language: parsed.language_feedback || ['Clear language'],
          examples: parsed.examples_feedback || ['Consider adding more examples'],
          suggestions: parsed.suggestions || ['Continue practicing'],
          key_points_missed: parsed.key_points_missed || [],
        },
      };
    }
  } catch (parseError) {
    console.warn('Failed to parse AI response:', parseError);
  }

  return evaluateRuleBased(answerText, questionText, ragContext);
}

/**
 * Fallback rule-based evaluation (AC#3-6)
 */
function evaluateRuleBased(
  answerText: string,
  questionText: string,
  ragContext: string
): RubricScores {
  const wordCount = answerText.trim().split(/\s+/).filter(Boolean).length;
  const sentences = answerText.split(/[.!?]+/).filter(s => s.trim().length > 0);
  const avgSentenceLength = sentences.length > 0 ? wordCount / sentences.length : 0;
  const paragraphs = answerText.split(/\n\n+/).filter(p => p.trim().length > 0);

  // Content scoring (AC#3): Check keyword coverage
  const questionKeywords = questionText.toLowerCase().match(/\b\w{4,}\b/g) || [];
  const answerLower = answerText.toLowerCase();
  const keywordMatches = questionKeywords.filter(kw =>
    answerLower.includes(kw) && !['what', 'where', 'when', 'which', 'discuss', 'analyze'].includes(kw)
  );
  const keywordCoverage = questionKeywords.length > 0 ? keywordMatches.length / questionKeywords.length : 0.5;

  // Structure scoring (AC#4): Check intro, body, conclusion
  const hasIntroduction = /^(in\s|as\s|the\s|with\s|this\s|it\s|india)/i.test(answerText.trim());
  const hasConclusion = /\b(conclude|therefore|hence|thus|in\s+conclusion|in\s+sum|to\s+summarize|way\s+forward)\b/i.test(answerText);
  const hasTransitions = /\b(firstly|secondly|thirdly|furthermore|however|moreover|additionally|on\s+the\s+other\s+hand|in\s+contrast)\b/i.test(answerText);
  const hasSubheadings = /\n[A-Z][^.!?\n]+:\s*\n/m.test(answerText);

  // Language scoring (AC#5): Grammar and readability indicators
  const hasProperCapitalization = /^[A-Z]/.test(answerText.trim());
  const endsWithPunctuation = /[.!?]$/.test(answerText.trim());
  const hasProperPunctuation = (answerText.match(/[.!?,;:]/g) || []).length > wordCount / 20;

  // Examples scoring (AC#6): Detect case studies, data, Acts
  const hasDataPoints = /\d{4}|\d+\s*(%|percent|crore|lakh|billion|trillion|million)/i.test(answerText);
  const hasActsArticles = /\b(article\s*\d+|section\s*\d+|act\s*(of\s*)?\d{4}|amendment|constitution|IPC|CrPC|CPC)\b/i.test(answerText);
  const hasCaseStudies = /\b(case|court|judgment|ruling|verdict|supreme\s+court|high\s+court|bench)\b/i.test(answerText);
  const hasCommitteeReports = /\b(committee|commission|report|recommendation|NITI|Planning)/i.test(answerText);
  const hasSchemes = /\b(scheme|programme|mission|yojana|abhiyan|initiative)\b/i.test(answerText);

  // Calculate scores
  const contentScore = Math.min(10,
    3 + // Base score
    (keywordCoverage * 3) + // Keyword coverage (0-3)
    Math.min(2, wordCount / 150) + // Word count adequacy (0-2)
    (hasDataPoints ? 1 : 0) + // Data points (0-1)
    (hasActsArticles ? 1 : 0) // Legal references (0-1)
  );

  const structureScore = Math.min(10,
    2 + // Base score
    (hasIntroduction ? 2 : 0) + // Introduction (0-2)
    (hasConclusion ? 2 : 0) + // Conclusion (0-2)
    (hasTransitions ? 1.5 : 0) + // Transitions (0-1.5)
    (hasSubheadings ? 1 : 0) + // Subheadings (0-1)
    Math.min(1.5, paragraphs.length / 3) // Paragraph variety (0-1.5)
  );

  const languageScore = Math.min(10,
    4 + // Base score
    (hasProperCapitalization ? 1 : 0) + // Capitalization (0-1)
    (endsWithPunctuation ? 1 : 0) + // Punctuation (0-1)
    (hasProperPunctuation ? 1 : 0) + // Overall punctuation (0-1)
    Math.min(2, avgSentenceLength > 8 && avgSentenceLength < 25 ? 2 : 1) + // Sentence variety (0-2)
    (sentences.length > 5 ? 1 : 0) // Sufficient sentences (0-1)
  );

  const examplesScore = Math.min(10,
    (hasDataPoints ? 2.5 : 0) + // Data points (0-2.5)
    (hasActsArticles ? 2.5 : 0) + // Legal references (0-2.5)
    (hasCaseStudies ? 2 : 0) + // Case studies (0-2)
    (hasCommitteeReports ? 1.5 : 0) + // Committee reports (0-1.5)
    (hasSchemes ? 1.5 : 0) // Government schemes (0-1.5)
  );

  // Calculate totals
  const totalScore = contentScore + structureScore + languageScore + examplesScore;
  const weightedPercentage = (
    (contentScore * 0.4) +
    (structureScore * 0.3) +
    (languageScore * 0.2) +
    (examplesScore * 0.1)
  ) * 10;

  // Generate feedback
  const feedback = {
    content: [
      keywordCoverage > 0.5 ? 'Good coverage of key concepts from the question' : 'Try to address more concepts mentioned in the question',
      wordCount < 150 ? 'Consider expanding your answer with more analysis' : 'Adequate word count',
      hasDataPoints ? 'Good use of data and statistics' : 'Add more data points to strengthen your answer',
    ],
    structure: [
      hasIntroduction ? 'Strong introduction that sets context' : 'Add a clear introduction to set the context',
      hasConclusion ? 'Effective conclusion with way forward' : 'Include a summarizing conclusion with way forward',
      hasTransitions ? 'Good use of transition words' : 'Use transition words for better logical flow',
    ],
    language: [
      avgSentenceLength > 10 && avgSentenceLength < 22 ? 'Good sentence structure and variety' : 'Work on sentence length variety',
      'Maintain formal academic tone throughout',
      hasProperPunctuation ? 'Good punctuation usage' : 'Pay attention to punctuation',
    ],
    examples: [
      hasActsArticles ? 'Good reference to legal provisions' : 'Include relevant Articles/Acts/Laws',
      hasCaseStudies ? 'Good use of case law' : 'Add relevant case studies or judgments',
      hasCommitteeReports ? 'Good reference to committee reports' : 'Cite relevant committee reports',
    ],
    suggestions: [
      'Practice writing under timed conditions',
      'Review model answers for similar topics',
      'Focus on the weak areas identified above',
      'Use the UPSC syllabus to ensure comprehensive coverage',
    ],
    key_points_missed: [
      !hasDataPoints ? 'Statistical data and figures' : '',
      !hasActsArticles ? 'Constitutional/Legal provisions' : '',
      !hasCaseStudies ? 'Relevant case studies' : '',
      !hasConclusion ? 'Way forward section' : '',
    ].filter(Boolean),
  };

  return {
    content_score: Math.round(contentScore * 10) / 10,
    structure_score: Math.round(structureScore * 10) / 10,
    language_score: Math.round(languageScore * 10) / 10,
    examples_score: Math.round(examplesScore * 10) / 10,
    total_score: Math.round(totalScore * 10) / 10,
    weighted_percentage: Math.round(weightedPercentage * 10) / 10,
    feedback,
  };
}
