// Story 8.7: Distractor Generation Action
// AC 1-9: Generate and validate MCQ distractors
// Note: This file runs in Deno Edge Functions environment

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const denoEnv = (globalThis as any).Deno?.env;
const A4F_BASE_URL = denoEnv?.get?.('A4F_BASE_URL') || process.env.A4F_BASE_URL || 'https://api.a4f.co/v1';
const A4F_API_KEY = denoEnv?.get?.('A4F_API_KEY') || process.env.A4F_API_KEY;
const PRIMARY_MODEL = 'provider-3/llama-4-scout';

interface DistractorRequest {
  question_text: string;
  correct_answer: string;
  topic?: string;
  difficulty?: string;
  question_id?: string;
  question_source?: 'generated' | 'pyq';
}

interface Distractor {
  text: string;
  type: 'common_mistake' | 'partial_truth' | 'related_concept' | 'factual_error';
  explanation: string;
}

interface DistractorResult {
  success: boolean;
  distractors?: Distractor[];
  options?: {
    letter: string;
    text: string;
    is_correct: boolean;
    explanation: string;
    distractor_type: string | null;
  }[];
  correct_answer?: string;
  error?: string;
  metadata?: {
    latency_ms: number;
    tokens_used: number;
  };
}

// Shuffle array using Fisher-Yates algorithm (AC 6)
function shuffleArray<T>(array: T[]): T[] {
  const shuffled = [...array];
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
  }
  return shuffled;
}

// Validate distractor (AC 5)
function isValidDistractor(distractor: string, correctAnswer: string, existing: string[]): boolean {
  // Check minimum length
  if (distractor.length < 5) return false;
  
  // Check not matching correct answer
  if (distractor.toLowerCase().trim() === correctAnswer.toLowerCase().trim()) return false;
  
  // Check not duplicate
  for (const e of existing) {
    if (distractor.toLowerCase().trim() === e.toLowerCase().trim()) return false;
  }
  
  // Check for obviously wrong patterns
  if (/impossible|never possible|always wrong/i.test(distractor)) return false;
  
  return true;
}

export async function generateDistractors(request: DistractorRequest): Promise<DistractorResult> {
  const startTime = Date.now();
  
  try {
    if (!A4F_API_KEY) {
      return { success: false, error: 'A4F API key not configured' };
    }

    const { question_text, correct_answer, topic, difficulty } = request;

    // Build AI prompt (AC 4)
    const prompt = `You are an expert UPSC question setter. Generate 3 plausible but INCORRECT options (distractors) for this MCQ.

QUESTION: ${question_text}
CORRECT ANSWER: ${correct_answer}
TOPIC: ${topic || 'General UPSC'}
DIFFICULTY: ${difficulty || 'medium'}

REQUIREMENTS:
1. Each distractor must be FACTUALLY INCORRECT but conceptually related
2. Include common misconceptions from UPSC exam patterns
3. Use distractor types: partial_truth, related_concept, common_mistake, factual_error
4. For each, explain why it's wrong (2-3 sentences)

Return ONLY valid JSON:
{
  "distractors": [
    {"text": "...", "type": "...", "explanation": "..."},
    {"text": "...", "type": "...", "explanation": "..."},
    {"text": "...", "type": "...", "explanation": "..."}
  ]
}`;

    const response = await fetch(`${A4F_BASE_URL}/chat/completions`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${A4F_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: PRIMARY_MODEL,
        messages: [{ role: 'user', content: prompt }],
        temperature: 0.7,
        max_tokens: 1500,
      }),
    });

    if (!response.ok) {
      return { success: false, error: 'AI generation failed' };
    }

    const result = await response.json();
    const content = result.choices?.[0]?.message?.content || '';
    const tokensUsed = result.usage?.total_tokens || 0;

    // Parse response
    let data: any;
    try {
      const jsonMatch = content.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        data = JSON.parse(jsonMatch[0]);
      } else {
        throw new Error('No JSON found');
      }
    } catch {
      return { success: false, error: 'Failed to parse AI response' };
    }

    // Validate distractors (AC 5)
    const validDistractors: Distractor[] = [];
    const seenTexts: string[] = [correct_answer];

    for (const d of data.distractors || []) {
      if (isValidDistractor(d.text, correct_answer, seenTexts)) {
        validDistractors.push({
          text: d.text,
          type: d.type || 'related_concept',
          explanation: d.explanation || '',
        });
        seenTexts.push(d.text);
      }
    }

    if (validDistractors.length < 3) {
      return { 
        success: false, 
        error: 'Could not generate enough valid distractors',
        distractors: validDistractors 
      };
    }

    // Build and shuffle options (AC 6)
    const allOptions = [
      { letter: 'A', text: correct_answer, is_correct: true, explanation: 'This is the correct answer.', distractor_type: null },
      { letter: 'B', text: validDistractors[0].text, is_correct: false, explanation: validDistractors[0].explanation, distractor_type: validDistractors[0].type },
      { letter: 'C', text: validDistractors[1].text, is_correct: false, explanation: validDistractors[1].explanation, distractor_type: validDistractors[1].type },
      { letter: 'D', text: validDistractors[2].text, is_correct: false, explanation: validDistractors[2].explanation, distractor_type: validDistractors[2].type },
    ];

    const shuffled = shuffleArray(allOptions);
    const shuffledWithLetters = shuffled.map((opt, idx) => ({
      ...opt,
      letter: String.fromCharCode(65 + idx),
    }));

    const newCorrectLetter = shuffledWithLetters.find(o => o.is_correct)?.letter || 'A';

    return {
      success: true,
      distractors: validDistractors,
      options: shuffledWithLetters,
      correct_answer: newCorrectLetter,
      metadata: {
        latency_ms: Date.now() - startTime,
        tokens_used: tokensUsed,
      },
    };

  } catch (error) {
    console.error('[Story 8.7] Distractor generation error:', error);
    return { success: false, error: 'Internal error during generation' };
  }
}

export default generateDistractors;
