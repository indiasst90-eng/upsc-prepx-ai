/**
 * Essay Trainer Pipeline
 *
 * Features:
 * - Essay topic generation (UPSC-style themes)
 * - Essay submission with word count enforcement
 * - AI evaluation using essay rubric
 * - Structure visualization and feedback
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from '@supabase/supabase-js';
import { corsHeaders } from '../_shared/cors.ts';

interface EssayRequest {
  action: 'generate_topic' | 'submit' | 'get_submission' | 'list_submissions' | 'get_evaluation';
  // Generate params
  category?: string;
  difficulty?: string;
  // Submit params
  topic?: string;
  essay_text?: string;
  time_taken_seconds?: number;
  // Common params
  submission_id?: string;
  user_id?: string;
}

interface EssayResponse {
  success: boolean;
  data?: any;
  error?: string;
}

const ESSAY_CATEGORIES = [
  'philosophical',
  'social',
  'economic',
  'political',
  'environmental',
  'international',
  'ethical',
  'scientific',
];

const SAMPLE_ESSAY_TOPICS = {
  philosophical: [
    'The pursuit of happiness: Is it a fundamental right or a personal journey?',
    'The tension between individual freedom and collective responsibility in modern democracy',
    'Is tolerance the same as acceptance? Analyzing the limits of pluralistic society',
    'The role of introspection in ethical decision-making',
  ],
  social: [
    'Digital divide in education: Challenge or opportunity for inclusive growth?',
    'The changing dynamics of family structure in urban India',
    'Caste-based reservations: A necessity or an obstacle to true equality?',
    'Impact of social media on youth culture and values',
  ],
  economic: [
    'Is economic growth compatible with environmental sustainability?',
    'The gig economy: Liberation or exploitation of labor?',
    'Universal Basic Income: A utopian dream or practical solution?',
    'The paradox of poverty amidst plenty in developing economies',
  ],
  political: [
    'Federalism in India: Strength or impediment to national integration?',
    'The crisis of institutional independence in a majoritarian democracy',
    'Civil society and state: Partners or adversaries in governance?',
    'The impact of electoral reforms on representative democracy',
  ],
  environmental: [
    'Climate justice: The responsibility of developed nations towards developing countries',
    'Is sustainable development a myth or a measurable goal?',
    'The conflict between development and conservation: Case for balanced approach',
    'Urbanization and its environmental challenges in Indian context',
  ],
  international: [
    'Multipolar world order: Challenges and opportunities for India',
    'The relevance of Non-Aligned Movement in contemporary geopolitics',
    'India-US relations: Strategic partnership or transactional relationship?',
    'Global governance reforms: Need for a more representative UN',
  ],
  ethical: [
    'The moral dilemma of artificial intelligence in governance',
    'Whistleblower protection: National security vs public interest',
    'The ethics of surveillance in the name of security',
    'Professional ethics in the age of commercialization',
  ],
  scientific: [
    'The ethics of genetic modification in agriculture',
    'Space exploration: Luxury or necessity for humanity?',
    'The role of science and technology in nation-building',
    'Balancing scientific progress with traditional wisdom',
  ],
};

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  try {
    const request = await req.json() as EssayRequest;
    const { action, category, difficulty, topic, essay_text, time_taken_seconds, submission_id, user_id: requested_user_id } = request;

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    const userId = requested_user_id || req.headers.get('x-user-id');

    if (!userId && action !== 'generate_topic') {
      return new Response(
        JSON.stringify({ error: 'Authentication required' }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 401,
        }
      );
    }

    switch (action) {
      case 'generate_topic':
        return await handleGenerateTopic(category, difficulty);

      case 'submit':
        return await handleSubmit(supabaseAdmin, userId!, { topic: topic!, essay_text: essay_text!, time_taken_seconds: time_taken_seconds || 0 });

      case 'get_submission':
        return await handleGetSubmission(supabaseAdmin, submission_id!);

      case 'list_submissions':
        return await handleListSubmissions(supabaseAdmin, userId!, { limit: 20, offset: 0 });

      case 'get_evaluation':
        return await handleGetEvaluation(supabaseAdmin, submission_id!);

      default:
        return new Response(
          JSON.stringify({ error: 'Invalid action' }),
          {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 400,
          }
        );
    }
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
 * Generate essay topic
 */
async function handleGenerateTopic(category?: string, difficulty?: string): Promise<Response> {
  const a4fKey = Deno.env.get('A4F_API_KEY');

  // If AI is available, generate custom topic
  if (a4fKey && category) {
    try {
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
              content: `Generate a UPSC Essay topic based on the given category.
Requirements:
- Current affairs relevance
- Philosophical depth
- Controversial but balanced
- 100-150 characters maximum
- Return only the topic, nothing else`,
            },
            {
              role: 'user',
              content: `Generate an essay topic on: ${category}. ${difficulty ? `Difficulty: ${difficulty}` : ''}`,
            },
          ],
          max_tokens: 100,
          temperature: 0.8,
        }),
      });

      if (response.ok) {
        const data = await response.json();
        const generatedTopic = data.choices?.[0]?.message?.content?.trim();
        if (generatedTopic) {
          return new Response(
            JSON.stringify({
              success: true,
              data: {
                topic: generatedTopic,
                category,
                difficulty: difficulty || 'medium',
                is_ai_generated: true,
              },
            }),
            {
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            }
          );
        }
      }
    } catch (error) {
      console.warn('AI topic generation failed, using fallback');
    }
  }

  // Fallback to sample topics
  const selectedCategory = category || ESSAY_CATEGORIES[Math.floor(Math.random() * ESSAY_CATEGORIES.length)];
  const topics = SAMPLE_ESSAY_TOPICS[selectedCategory as keyof typeof SAMPLE_ESSAY_TOPICS] || SAMPLE_ESSAY_TOPICS.social;
  const topic = topics[Math.floor(Math.random() * topics.length)];

  return new Response(
    JSON.stringify({
      success: true,
      data: {
        topic,
        category: selectedCategory,
        difficulty: difficulty || 'medium',
        is_ai_generated: false,
      },
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}

/**
 * Submit essay for evaluation
 */
async function handleSubmit(
  supabase: any,
  userId: string,
  params: { topic: string; essay_text: string; time_taken_seconds: number }
): Promise<Response> {
  const { topic, essay_text, time_taken_seconds } = params;

  if (!topic || !essay_text) {
    return new Response(
      JSON.stringify({ error: 'Topic and essay text are required' }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    );
  }

  // Calculate word count
  const words = essay_text.trim().split(/\s+/).filter(Boolean);
  const wordCount = words.length;

  // Determine category based on topic keywords
  let category = 'general';
  const topicLower = topic.toLowerCase();
  for (const cat of ESSAY_CATEGORIES) {
    if (topicLower.includes(cat) || isRelatedToCategory(topic, cat)) {
      category = cat;
      break;
    }
  }

  // Create submission
  const { data: submission, error } = await supabase
    .from('essay_submissions')
    .insert({
      user_id: userId,
      topic,
      topic_category: category,
      essay_text,
      word_count: wordCount,
      time_taken_seconds,
      evaluation_status: 'pending',
    })
    .select()
    .single();

  if (error) {
    throw new Error(`Failed to submit essay: ${error.message}`);
  }

  // Trigger async evaluation
  evaluateEssayAsync(submission.id, topic, essay_text, wordCount);

  return new Response(
    JSON.stringify({
      success: true,
      data: {
        submission_id: submission.id,
        word_count: wordCount,
        time_taken_seconds,
        category,
      },
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}

/**
 * Async essay evaluation
 */
async function evaluateEssayAsync(submissionId: string, topic: string, essayText: string, wordCount: number) {
  const supabaseAdmin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );

  const a4fKey = Deno.env.get('A4F_API_KEY');

  // Generate structure analysis
  const structureAnalysis = analyzeStructure(essayText);

  // Perform AI evaluation
  let evaluation = null;
  if (a4fKey) {
    evaluation = await evaluateWithAI(a4fKey, topic, essayText, wordCount);
  } else {
    evaluation = evaluateRuleBased(essayText, topic, wordCount);
  }

  // Save evaluation
  await supabaseAdmin
    .from('essay_submissions')
    .update({
      evaluation_status: 'completed',
      thesis_score: evaluation.thesis,
      argument_score: evaluation.argument,
      evidence_score: evaluation.evidence,
      structure_score: evaluation.structure,
      language_score: evaluation.language,
      total_score: evaluation.total,
      feedback_json: evaluation.feedback,
    })
    .eq('id', submissionId);
}

/**
 * Analyze essay structure
 */
function analyzeStructure(essayText: string) {
  const paragraphs = essayText.split(/\n\n+/).filter(Boolean);
  const sentences = essayText.split(/[.!?]+/).filter(Boolean);

  const introLength = paragraphs[0]?.length || 0;
  const conclusionLength = paragraphs[paragraphs.length - 1]?.length || 0;
  const bodyParagraphs = paragraphs.slice(1, -1);

  return {
    paragraph_count: paragraphs.length,
    sentence_count: sentences.length,
    avg_sentence_length: sentences.length > 0 ? Math.round(essayText.split(/\s+/).length / sentences.length) : 0,
    intro_length_ratio: introLength / essayText.length,
    conclusion_length_ratio: conclusionLength / essayText.length,
    body_paragraphs: bodyParagraphs.length,
  };
}

/**
 * AI-based essay evaluation
 */
async function evaluateWithAI(apiKey: string, topic: string, essayText: string, wordCount: number): Promise<any> {
  const structure = analyzeStructure(essayText);

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
          content: `You are an expert UPSC Essay evaluator. Evaluate this essay on: "${topic}"

Rubric (out of 10 each, total 50):
1. Thesis (10): Clarity, strength, and positioning of main argument
2. Arguments (10): Quality, depth, and logical flow of arguments
3. Evidence (10): Use of examples, data, case studies, current affairs
4. Structure (10): Introduction, body paragraphs, conclusion, transitions
5. Language (10): Grammar, expression, vocabulary, readability

Return JSON:
{
  "thesis": <0-10>,
  "argument": <0-10>,
  "evidence": <0-10>,
  "structure": <0-10>,
  "language": <0-10>,
  "strengths": ["point 1", "point 2"],
  "improvements": ["point 1", "point 2"],
  "word_count_feedback": "brief feedback on word count"
}`,
        },
        {
          role: 'user',
          content: `Topic: ${topic}

Essay (${wordCount} words):
${essayText.slice(0, 3000)}`,
        },
      ],
      max_tokens: 1500,
      temperature: 0.3,
    }),
  });

  if (!response.ok) {
    return evaluateRuleBased(essayText, topic, wordCount);
  }

  const data = await response.json();
  const content = data.choices?.[0]?.message?.content || '';

  try {
    const jsonMatch = content.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      const parsed = JSON.parse(jsonMatch[0]);
      return {
        thesis: Math.round(parsed.thesis * 10) / 10,
        argument: Math.round(parsed.argument * 10) / 10,
        evidence: Math.round(parsed.evidence * 10) / 10,
        structure: Math.round(parsed.structure * 10) / 10,
        language: Math.round(parsed.language * 10) / 10,
        total: Math.round((parsed.thesis + parsed.argument + parsed.evidence + parsed.structure + parsed.language) * 10) / 10,
        feedback: {
          strengths: parsed.strengths || [],
          improvements: parsed.improvements || [],
          word_count: parsed.word_count_feedback || '',
        },
      };
    }
  } catch (parseError) {
    console.warn('Failed to parse AI response:', parseError);
  }

  return evaluateRuleBased(essayText, topic, wordCount);
}

/**
 * Rule-based fallback evaluation
 */
function evaluateRuleBased(essayText: string, topic: string, wordCount: number): any {
  const structure = analyzeStructure(essayText);

  // Check for structural elements
  const hasIntroduction = /^(in|this essay|through|by)/i.test(essayText.trim());
  const hasConclusion = /\b(conclude|therefore|thus|hence|in conclusion|in sum)/i.test(essayText);
  const hasThesisStatement = /\b(therefore|hence|thus|this paper argues|essay argues)/i.test(essayText);

  // Check for examples
  const hasDataPoints = /\d{4}|percent|%|crore|lakh|billion|trillion/i.test(essayText);
  const hasCaseStudies = /\b(case|study|example|instance)/i.test(essayText);
  const hasCurrentAffairs = /\b(202[0-4]|recent|pandemic|climate|india|supreme court)/i.test(essayText);
  const hasQuotes = /[""'']/.test(essayText);

  // Calculate scores
  const thesisScore = 5 + (hasThesisStatement ? 2 : 0) + (wordCount >= 800 ? 2 : 0) + (wordCount >= 1200 ? 1 : 0);
  const argumentScore = 4 + (structure.body_paragraphs >= 2 ? 2 : 0) + (structure.avg_sentence_length > 10 ? 2 : 0);
  const evidenceScore = (hasDataPoints ? 3 : 0) + (hasCaseStudies ? 3 : 0) + (hasCurrentAffairs ? 2 : 0) + (hasQuotes ? 2 : 0);
  const structureScore = 3 + (hasIntroduction ? 2 : 0) + (hasConclusion ? 2 : 0) + (structure.body_paragraphs >= 2 ? 2 : 0) + (structure.avg_sentence_length > 10 ? 1 : 0);
  const languageScore = 5 + Math.min(3, structure.avg_sentence_length > 12 ? 3 : structure.avg_sentence_length > 8 ? 2 : 0);

  const totalScore = Math.min(50,
    thesisScore + argumentScore + evidenceScore + structureScore + languageScore
  );

  return {
    thesis: Math.min(10, thesisScore),
    argument: Math.min(10, argumentScore),
    evidence: Math.min(10, evidenceScore),
    structure: Math.min(10, structureScore),
    language: Math.min(10, languageScore),
    total: Math.round(totalScore * 10) / 10,
    feedback: {
      strengths: [
        structure.paragraph_count >= 4 ? 'Good paragraph structure' : null,
        hasIntroduction ? 'Clear introduction' : null,
        hasConclusion ? 'Effective conclusion' : null,
        hasDataPoints ? 'Good use of data' : null,
      ].filter(Boolean),
      improvements: [
        structure.paragraph_count < 4 ? 'Add more body paragraphs' : null,
        !hasDataPoints ? 'Include more statistics and data' : null,
        !hasCurrentAffairs ? 'Add current affairs examples' : null,
        structure.avg_sentence_length > 20 ? 'Shorten your sentences for clarity' : null,
      ].filter(Boolean),
      word_count: wordCount < 1000 ? 'Consider expanding to reach 1000+ words' : wordCount > 1500 ? 'Good length for comprehensive analysis' : 'Appropriate word count',
    },
  };
}

/**
 * Helper to check category relevance
 */
function isRelatedToCategory(topic: string, category: string): boolean {
  const keywords: Record<string, string[]> = {
    philosophical: ['think', 'believe', 'moral', 'ethic', 'philosophy', 'soul', 'spirit', 'meaning', 'purpose'],
    social: ['society', 'social', 'community', 'family', 'culture', 'tradition', 'change'],
    economic: ['economy', 'economic', 'growth', 'development', 'money', 'trade', 'market', 'employment'],
    political: ['government', 'political', 'state', 'democracy', 'power', 'policy', 'nation'],
    environmental: ['environment', 'climate', 'nature', '生态', 'sustainable', 'pollution', 'conservation'],
    international: ['world', 'global', 'international', 'foreign', 'relations', 'diplomacy'],
    ethical: ['right', 'wrong', 'moral', 'duty', 'responsibility', 'integrity', 'honesty'],
    scientific: ['science', 'scientific', 'technology', 'research', 'innovation', 'discovery'],
  };

  const topicLower = topic.toLowerCase();
  return keywords[category]?.some((kw) => topicLower.includes(kw)) || false;
}

/**
 * Get submission
 */
async function handleGetSubmission(supabase: any, submissionId: string): Promise<Response> {
  const { data: submission, error } = await supabase
    .from('essay_submissions')
    .select('*')
    .eq('id', submissionId)
    .single();

  if (error || !submission) {
    return new Response(
      JSON.stringify({ error: 'Submission not found' }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 404,
      }
    );
  }

  return new Response(
    JSON.stringify({ success: true, data: submission }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}

/**
 * List submissions
 */
async function handleListSubmissions(supabase: any, userId: string, params: { limit: number; offset: number }): Promise<Response> {
  const { data: submissions, error, count } = await supabase
    .from('essay_submissions')
    .select('*', { count: 'exact' })
    .eq('user_id', userId)
    .order('submitted_at', { ascending: false })
    .range(params.offset, params.offset + params.limit - 1);

  if (error) {
    throw new Error(`Failed to fetch submissions: ${error.message}`);
  }

  return new Response(
    JSON.stringify({
      success: true,
      data: submissions,
      pagination: {
        total: count || 0,
        limit: params.limit,
        offset: params.offset,
        has_more: (params.offset + params.limit) < (count || 0),
      },
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}

/**
 * Get evaluation
 */
async function handleGetEvaluation(supabase: any, submissionId: string): Promise<Response> {
  const { data: submission, error } = await supabase
    .from('essay_submissions')
    .select('*')
    .eq('id', submissionId)
    .single();

  if (error || !submission) {
    return new Response(
      JSON.stringify({ error: 'Submission not found' }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 404,
      }
    );
  }

  return new Response(
    JSON.stringify({
      success: true,
      data: {
        topic: submission.topic,
        category: submission.topic_category,
        word_count: submission.word_count,
        time_taken_seconds: submission.time_taken_seconds,
        scores: {
          thesis: submission.thesis_score,
          argument: submission.argument_score,
          evidence: submission.evidence_score,
          structure: submission.structure_score,
          language: submission.language_score,
          total: submission.total_score,
        },
        feedback: submission.feedback_json,
      },
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}
