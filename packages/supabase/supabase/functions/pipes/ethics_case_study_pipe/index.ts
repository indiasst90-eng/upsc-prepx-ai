/**
 * Ethics Case Study Pipe - Interactive Scenarios
 *
 * Generates and evaluates ethics case studies based on UPSC GS Paper IV syllabus.
 * Features:
 * - Diverse dilemma scenarios (administrative, social, professional)
 * - Stakeholder analysis
 * - Rubric-based evaluation
 * - Principle identification
 * - Improvement suggestions
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from '@supabase/supabase-js';
import { corsHeaders } from '../_shared/cors.ts';

interface EthicsCaseRequest {
  action?: 'list' | 'get' | 'create' | 'submit' | 'generate';
  case_id?: string;
  attempt_id?: string;
  // For case generation
  topic?: string;
  difficulty?: 'easy' | 'medium' | 'hard';
  gs_paper?: 'GS Paper IV' | 'GS Paper II' | 'Essay';
  // For submission
  analysis?: {
    stakeholder_views?: string;
    core_issue?: string;
    resolution?: string;
    principles_applied?: string[];
  };
  self_assessment?: {
    confidence?: number;
    time_taken?: number;
  };
}

interface EthicsCase {
  id: string;
  title: string;
  scenario: string;
  background: string;
  stakeholders: { name: string; perspective: string }[];
  discussion_questions: string[];
  eval_criteria: { criterion: string; weight: number; description: string }[];
  difficulty: string;
  gs_paper: string;
  tags: string[];
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST' && req.method !== 'GET') {
    return new Response('Method not allowed', { status: 405 });
  }

  const startTime = Date.now();
  const supabaseAdmin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );

  try {
    // GET: List cases or get a specific case
    if (req.method === 'GET') {
      const url = new URL(req.url);
      const action = url.searchParams.get('action');
      const difficulty = url.searchParams.get('difficulty');
      const gs_paper = url.searchParams.get('gs_paper');

      // List available cases
      if (action === 'list') {
        let query = supabaseAdmin
          .from('ethics_case_studies')
          .select('id, title, scenario, difficulty, gs_paper, tags, avg_score, times_used')
          .eq('is_active', true);

        if (difficulty) query = query.eq('difficulty', difficulty);
        if (gs_paper) query = query.eq('gs_paper', gs_paper);

        const { data: cases, error } = await query.order('created_at', { ascending: false }).limit(50);

        if (error) throw error;

        return new Response(JSON.stringify({ success: true, data: cases }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      // Get user's attempts
      if (action === 'my_attempts') {
        const authHeader = req.headers.get('Authorization');
        if (!authHeader) {
          return new Response(JSON.stringify({ error: 'Unauthorized' }), {
            status: 401,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          });
        }

        const supabase = createClient(
          Deno.env.get('SUPABASE_URL')!,
          authHeader.replace('Bearer ', '')
        );

        const { data: { user } } = await supabase.auth.getUser();
        if (!user) throw new Error('User not found');

        const { data: attempts, error } = await supabase
          .from('ethics_attempts')
          .select('*, ethics_case_studies(*)')
          .eq('user_id', user.id)
          .order('created_at', { ascending: false });

        if (error) throw error;

        return new Response(JSON.stringify({ success: true, data: attempts }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      // Get a specific case
      const caseId = url.searchParams.get('case_id');
      if (caseId) {
        const { data: caseData, error } = await supabaseAdmin
          .from('ethics_case_studies')
          .select('*')
          .eq('id', caseId)
          .single();

        if (error) throw error;

        // Increment usage count
        await supabaseAdmin.rpc('increment_case_usage', { case_id: caseId });

        return new Response(JSON.stringify({ success: true, data: caseData }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      return new Response(JSON.stringify({ error: 'Invalid request' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // POST: Create, submit, or generate
    const body = await req.json() as EthicsCaseRequest;
    const { action, case_id, attempt_id, analysis, self_assessment, topic, difficulty = 'medium', gs_paper = 'GS Paper IV' } = body;

    const a4fKey = Deno.env.get('A4F_API_KEY');

    // Generate new case
    if (action === 'generate') {
      const newCase = await generateCase(a4fKey, topic, difficulty, gs_paper);

      // Save to database
      const { data: savedCase, error } = await supabaseAdmin
        .from('ethics_case_studies')
        .insert(newCase)
        .select()
        .single();

      if (error) throw error;

      return new Response(JSON.stringify({
        success: true,
        data: savedCase,
        processing_time_seconds: (Date.now() - startTime) / 1000,
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Submit analysis for evaluation
    if (action === 'submit' && case_id) {
      return await handleSubmission(supabaseAdmin, a4fKey, body, startTime);
    }

    // Start a new attempt
    if (action === 'create' && case_id) {
      return await startAttempt(supabaseAdmin, case_id, body, startTime);
    }

    return new Response(JSON.stringify({ error: 'Invalid action' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error) {
    return new Response(JSON.stringify({
      success: false,
      error: (error as Error).message,
      processing_time_seconds: (Date.now() - startTime) / 1000,
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});

/**
 * Generate a new ethics case study using AI
 */
async function generateCase(
  apiKey: string | undefined,
  topic: string | undefined,
  difficulty: string,
  gs_paper: string
): Promise<any> {
  const topicSuggestions = [
    'Corruption in government procurement',
    'Whistleblower protection vs national security',
    'Environmental conservation vs tribal rights',
    'Civic amenities in urban slums',
    'Police reform and accountability',
    'Medical ethics in resource allocation',
    'Corporate social responsibility conflicts',
    'Media freedom vs privacy',
    'Affirmative action in education',
    'Data privacy vs surveillance',
  ];

  const selectedTopic = topic || topicSuggestions[Math.floor(Math.random() * topicSuggestions.length)];

  if (apiKey) {
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
            content: `Create a UPSC-style ethics case study on the given topic.
Return JSON:
{
  "title": "Clear, concise title",
  "scenario": "Detailed 300-500 word scenario presenting the dilemma",
  "background": "50-100 word context and background",
  "stakeholders": [{"name": "Stakeholder 1", "perspective": "Their view"}],
  "discussion_questions": ["Question 1", "Question 2", "Question 3"],
  "eval_criteria": [
    {"criterion": "Issue Identification", "weight": 25, "description": "Identify the core ethical issue"},
    {"criterion": "Stakeholder Analysis", "weight": 25, "description": "Consider all perspectives"},
    {"criterion": "Value Conflict", "weight": 25, "description": "Identify conflicting values"},
    {"criterion": "Resolution", "weight": 25, "description": "Practical and ethical resolution"}
  ],
  "tags": ["tag1", "tag2", "tag3"],
  "difficulty": "${difficulty}",
  "gs_paper": "${gs_paper}"
}`,
          },
          {
            role: 'user',
            content: `Generate an ethics case study on: ${selectedTopic}`,
          },
        ],
        max_tokens: 2000,
        temperature: 0.7,
      }),
    });

    if (response.ok) {
      const data = await response.json();
      const content = data.choices?.[0]?.message?.content || '';
      const jsonMatch = content.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        return JSON.parse(jsonMatch[0]);
      }
    }
  }

  return generateDefaultCase(selectedTopic, difficulty, gs_paper);
}

/**
 * Generate default case without AI
 */
function generateDefaultCase(topic: string, difficulty: string, gs_paper: string): any {
  return {
    title: `Case Study: ${topic}`,
    scenario: `You are facing a challenging situation involving ${topic}. Multiple stakeholders are involved with competing interests. The situation requires balancing ethical principles with practical constraints.`,
    background: 'This case tests your ability to identify ethical dilemmas, analyze stakeholder perspectives, and propose balanced solutions while upholding constitutional values.',
    stakeholders: [
      { name: 'Primary Stakeholder', perspective: 'Seeking immediate resolution favoring their interests' },
      { name: 'Secondary Stakeholder', perspective: 'Concerned about long-term implications' },
      { name: 'Government/Institution', perspective: 'Need to balance governance with ethics' },
    ],
    discussion_questions: [
      `What is the core ethical issue in this case?`,
      `How would you balance competing stakeholder interests?`,
      `What values are in conflict here?`,
      `What would be your course of action and why?`,
    ],
    eval_criteria: [
      { criterion: 'Issue Identification', weight: 25, description: 'Identify the core ethical issue' },
      { criterion: 'Stakeholder Analysis', weight: 25, description: 'Consider all perspectives' },
      {criterion: 'Value Conflict', weight: 25, description: 'Identify conflicting values'},
      { criterion: 'Resolution', weight: 25, description: 'Practical and ethical resolution' },
    ],
    tags: [topic.toLowerCase().replace(/\s+/g, '_'), 'ethics', gs_paper.toLowerCase().replace(' ', '_')],
    difficulty,
    gs_paper,
  };
}

/**
 * Start a new attempt on a case
 */
async function startAttempt(
  supabaseAdmin: any,
  caseId: string,
  body: EthicsCaseRequest,
  startTime: number
) {
  const authHeader = req.headers?.get('Authorization');
  let userId = 'anonymous';

  if (authHeader) {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      authHeader.replace('Bearer ', '')
    );
    const { data: { user } } = await supabase.auth.getUser();
    if (user) userId = user.id;
  }

  // Get case details
  const { data: caseData, error: caseError } = await supabaseAdmin
    .from('ethics_case_studies')
    .select('*')
    .eq('id', caseId)
    .single();

  if (caseError) throw caseError;

  // Get attempt number
  const { count } = await supabaseAdmin
    .from('ethics_attempts')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', userId)
    .eq('case_id', caseId);

  // Create attempt record
  const { data: attempt, error: attemptError } = await supabaseAdmin
    .from('ethics_attempts')
    .insert({
      user_id: userId,
      case_id: caseId,
      attempt_number: (count || 0) + 1,
      started_at: new Date().toISOString(),
    })
    .select()
    .single();

  if (attemptError) throw attemptError;

  return new Response(JSON.stringify({
    success: true,
    data: {
      attempt_id: attempt.id,
      case: caseData,
      processing_time_seconds: (Date.now() - startTime) / 1000,
    },
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

/**
 * Handle submission and evaluation
 */
async function handleSubmission(
  supabaseAdmin: any,
  apiKey: string | undefined,
  body: EthicsCaseRequest,
  startTime: number
) {
  const { case_id, attempt_id, analysis, self_assessment } = body;

  // Get the case
  const { data: caseData, error: caseError } = await supabaseAdmin
    .from('ethics_case_studies')
    .select('*')
    .eq('id', case_id)
    .single();

  if (caseError) throw caseError;

  // Evaluate using AI
  const evaluation = apiKey
    ? await evaluateAnalysis(apiKey, analysis, caseData)
    : generateDefaultEvaluation(analysis, caseData);

  // Calculate score based on rubric
  const totalScore = Object.values(evaluation.rubric_scores as Record<string, number>)
    .reduce((sum, score, idx) => sum + score * (caseData.eval_criteria?.[idx]?.weight || 25) / 100, 0);

  // Update attempt
  const { data: updatedAttempt, error: updateError } = await supabaseAdmin
    .from('ethics_attempts')
    .update({
      analysis,
      self_assessment,
      ai_evaluation: evaluation,
      is_completed: true,
      completed_at: new Date().toISOString(),
    })
    .eq('id', attempt_id)
    .select()
    .single();

  if (updateError) throw updateError;

  // Add XP if user is authenticated
  const authHeader = req.headers?.get('Authorization');
  if (authHeader) {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      authHeader.replace('Bearer ', '')
    );
    const { data: { user } } = await supabase.auth.getUser();
    if (user) {
      // Award XP for completing case
      const xpAmount = Math.round(totalScore);
      await supabaseAdmin.rpc('add_xp', { p_user_id: user.id, p_xp_amount: xpAmount });
    }
  }

  return new Response(JSON.stringify({
    success: true,
    data: {
      attempt: updatedAttempt,
      evaluation: {
        total_score: totalScore,
        ...evaluation,
      },
      processing_time_seconds: (Date.now() - startTime) / 1000,
    },
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

/**
 * Evaluate user's analysis using AI
 */
async function evaluateAnalysis(
  apiKey: string,
  analysis: any,
  caseData: any
): Promise<any> {
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
          content: `Evaluate this ethics case study response.
Case: ${caseData.title}
Scenario: ${caseData.scenario.slice(0, 500)}

Evaluation Criteria (0-100 each):
${caseData.eval_criteria?.map((c: any) => `- ${c.criterion} (${c.weight}%): ${c.description}`).join('\n') || `
- Issue Identification (25%)
- Stakeholder Analysis (25%)
- Value Conflict (25%)
- Resolution (25%)
`}

Return JSON:
{
  "rubric_scores": {
    "issue_identification": 0-100,
    "stakeholder_analysis": 0-100,
    "value_conflict": 0-100,
    "resolution": 0-100
  },
  "overall_feedback": "General assessment",
  "strengths": ["Point 1", "Point 2"],
  "improvements": ["Area 1", "Area 2"],
  "principles_identified": ["Principle 1", "Principle 2"],
  "better_approach": "Suggested improvement"
}`,
        },
        {
          role: 'user',
          content: `User Analysis:
Stakeholder Views: ${analysis?.stakeholder_views || 'Not provided'}
Core Issue: ${analysis?.core_issue || 'Not provided'}
Resolution: ${analysis?.resolution || 'Not provided'}
Principles Applied: ${analysis?.principles_applied?.join(', ') || 'None identified'}

Evaluate this response:`,
        },
      ],
      max_tokens: 800,
      temperature: 0.5,
    }),
  });

  if (response.ok) {
    const data = await response.json();
    const content = data.choices?.[0]?.message?.content || '';
    const jsonMatch = content.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      return JSON.parse(jsonMatch[0]);
    }
  }

  return generateDefaultEvaluation(analysis, caseData);
}

/**
 * Generate default evaluation without AI
 */
function generateDefaultEvaluation(analysis: any, caseData: any): any {
  const hasStakeholder = analysis?.stakeholder_views && analysis.stakeholder_views.length > 50;
  const hasIssue = analysis?.core_issue && analysis.core_issue.length > 20;
  const hasResolution = analysis?.resolution && analysis.resolution.length > 50;
  const hasPrinciples = analysis?.principles_applied && analysis.principles_applied.length > 0;

  const rubricScores = {
    issue_identification: hasIssue ? 75 + Math.random() * 20 : 50,
    stakeholder_analysis: hasStakeholder ? 75 + Math.random() * 20 : 45,
    value_conflict: hasStakeholder ? 70 + Math.random() * 20 : 50,
    resolution: hasResolution ? 75 + Math.random() * 20 : 45,
  };

  return {
    rubric_scores: rubricScores,
    overall_feedback: hasStakeholder && hasIssue && hasResolution
      ? 'Good attempt at analyzing the ethical dilemma. Consider exploring more stakeholder perspectives.'
      : 'The analysis needs more depth. Try to identify all stakeholders and their conflicting interests.',
    strengths: [
      hasIssue ? 'Identified core issue' : null,
      hasResolution ? 'Proposed practical resolution' : null,
      hasPrinciples ? 'Applied ethical principles' : null,
    ].filter(Boolean),
    improvements: [
      !hasStakeholder ? 'Expand stakeholder analysis' : null,
      !hasIssue ? 'Deepen issue identification' : null,
      !hasPrinciples ? 'Apply more ethical frameworks' : null,
    ].filter(Boolean),
    principles_identified: analysis?.principles_applied || ['Integrity', 'Public Service'],
    better_approach: 'Consider the long-term implications and institutional impacts of your proposed solution.',
  };
}
