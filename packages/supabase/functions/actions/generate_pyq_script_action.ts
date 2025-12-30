// Story 8.4: Generate PYQ video explanation script (FULL PRODUCTION)
// Action: generate_pyq_script_action
// AC 2-5: Complete script generation with visual markers and Manim scene specs

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

interface ScriptSection {
  type: 'intro' | 'analysis' | 'concepts' | 'mistakes' | 'tips';
  narration: string;
  duration_seconds: number;
  visual_markers?: string[];
  manim_scene_specs?: any[];
}

interface ManimSceneSpec {
  scene_type: 'concept_map' | 'timeline' | 'flowchart' | 'diagram';
  data: any;
  duration: number;
}

// AC 5: Generate Manim scene specs based on question type
function generateManimScenes(question: any, section: ScriptSection): ManimSceneSpec[] {
  const scenes: ManimSceneSpec[] = [];
  
  // Historical questions get timelines
  if (question.subject?.toLowerCase().includes('history') && section.type === 'concepts') {
    scenes.push({
      scene_type: 'timeline',
      data: {
        events: extractHistoricalEvents(question.text, section.narration),
        title: 'Historical Timeline',
      },
      duration: 10,
    });
  }
  
  // Polity/Governance questions get flowcharts
  if ((question.subject?.toLowerCase().includes('polity') || 
       question.subject?.toLowerCase().includes('governance')) && 
      section.type === 'analysis') {
    scenes.push({
      scene_type: 'flowchart',
      data: {
        nodes: extractProcessSteps(section.narration),
        title: 'Process Flow',
      },
      duration: 12,
    });
  }
  
  // Abstract concepts get concept maps
  if (section.type === 'concepts' && section.visual_markers?.includes('[DIAGRAM]')) {
    scenes.push({
      scene_type: 'concept_map',
      data: {
        central_concept: question.topic || question.subject,
        related_concepts: extractConcepts(section.narration),
      },
      duration: 15,
    });
  }
  
  return scenes;
}

function extractHistoricalEvents(questionText: string, narration: string): any[] {
  // Extract years and events from text
  const yearRegex = /\b(\d{4})\b/g;
  const years = [...questionText.matchAll(yearRegex), ...narration.matchAll(yearRegex)]
    .map(m => m[1])
    .filter((v, i, a) => a.indexOf(v) === i);
  
  return years.map(year => ({ year, event: `Event in ${year}` }));
}

function extractProcessSteps(narration: string): any[] {
  // Extract numbered steps or sequential items
  const steps = narration.split(/\d+\.\s+/).filter(s => s.trim());
  return steps.slice(0, 5).map((step, i) => ({
    id: i + 1,
    label: step.substring(0, 50) + '...',
  }));
}

function extractConcepts(narration: string): string[] {
  // Extract key terms (capitalized words, technical terms)
  const words = narration.split(/\s+/);
  const concepts = words
    .filter(w => /^[A-Z][a-z]+/.test(w) && w.length > 4)
    .filter((v, i, a) => a.indexOf(v) === i)
    .slice(0, 6);
  return concepts;
}

export async function generatePyqScript(questionId: string, supabaseClient: any) {
  try {
    // AC 3: Fetch question and model answer from DB
    const { data: question, error: qError } = await supabaseClient
      .from('pyq_questions')
      .select('*, pyq_model_answers(*)')
      .eq('id', questionId)
      .single();

    if (qError) throw new Error(`Database error: ${qError.message}`);
    if (!question) throw new Error('Question not found');

    const modelAnswer = question.pyq_model_answers?.[0];
    if (!modelAnswer) throw new Error('Model answer not found for this question');

    // AC 2: Generate 5-section script structure
    const prompt = `Generate a comprehensive 3-5 minute video explanation script for this UPSC PYQ.

Question Details:
- Text: ${question.text}
- Year: ${question.year}
- Paper: ${question.paper_type}
- Subject: ${question.subject}
- Marks: ${question.marks}
- Difficulty: ${question.difficulty}

Model Answer:
${modelAnswer.answer_text}

Create a structured script with EXACTLY 5 sections:

1. INTRO (30 seconds):
   - Welcome and question overview
   - Why this question is important
   - What we'll cover

2. ANALYSIS (60 seconds):
   - Break down what the question is asking
   - Identify key terms and requirements
   - Understand the examiner's intent

3. CONCEPTS (90 seconds):
   - Core concepts needed to answer
   - Background knowledge required
   - Interconnections between concepts
   - Add [DIAGRAM] marker where visual aids help

4. MISTAKES (60 seconds):
   - Common errors students make
   - Misconceptions to avoid
   - What NOT to write

5. TIPS (30 seconds):
   - Exam strategy for similar questions
   - Time management tips
   - How to structure your answer

For each section:
- Write engaging, conversational narration
- Include visual markers: [DIAGRAM], [TIMELINE], [MAP], [FLOWCHART] where appropriate
- Keep language simple and clear
- Use examples where helpful

Return ONLY valid JSON (no markdown, no extra text):
{
  "sections": [
    {
      "type": "intro",
      "narration": "...",
      "duration_seconds": 30,
      "visual_markers": []
    },
    {
      "type": "analysis",
      "narration": "...",
      "duration_seconds": 60,
      "visual_markers": ["[DIAGRAM]"]
    },
    {
      "type": "concepts",
      "narration": "...",
      "duration_seconds": 90,
      "visual_markers": ["[TIMELINE]", "[MAP]"]
    },
    {
      "type": "mistakes",
      "narration": "...",
      "duration_seconds": 60,
      "visual_markers": []
    },
    {
      "type": "tips",
      "narration": "...",
      "duration_seconds": 30,
      "visual_markers": []
    }
  ]
}`;

    // AC 3: Call A4F LLM with retry logic
    let attempts = 0;
    let scriptData: any = null;
    
    while (attempts < 3 && !scriptData) {
      attempts++;
      
      try {
        const response = await fetch('https://api.a4f.co/v1/chat/completions', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${Deno.env.get('A4F_API_KEY')}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            model: 'provider-3/llama-4-scout',
            messages: [{ role: 'user', content: prompt }],
            temperature: 0.7,
            max_tokens: 2000,
          }),
        });

        if (!response.ok) {
          throw new Error(`A4F API error: ${response.status} ${response.statusText}`);
        }

        const result = await response.json();
        const scriptText = result.choices[0]?.message?.content;
        
        if (!scriptText) {
          throw new Error('Empty response from A4F API');
        }
        
        // Parse JSON from response (handle markdown code blocks)
        const jsonMatch = scriptText.match(/```json\s*([\s\S]*?)```/) || 
                         scriptText.match(/```\s*([\s\S]*?)```/) ||
                         scriptText.match(/\{[\s\S]*\}/);
        
        if (!jsonMatch) {
          throw new Error('No JSON found in response');
        }
        
        scriptData = JSON.parse(jsonMatch[1] || jsonMatch[0]);
        
        // Validate script structure
        if (!scriptData.sections || !Array.isArray(scriptData.sections)) {
          throw new Error('Invalid script structure: missing sections array');
        }
        
        if (scriptData.sections.length !== 5) {
          throw new Error(`Invalid script structure: expected 5 sections, got ${scriptData.sections.length}`);
        }
        
        // Validate each section
        const requiredTypes = ['intro', 'analysis', 'concepts', 'mistakes', 'tips'];
        const sectionTypes = scriptData.sections.map((s: any) => s.type);
        
        for (const type of requiredTypes) {
          if (!sectionTypes.includes(type)) {
            throw new Error(`Missing required section: ${type}`);
          }
        }
        
      } catch (error) {
        console.error(`Script generation attempt ${attempts} failed:`, error);
        if (attempts >= 3) throw error;
        await new Promise(resolve => setTimeout(resolve, 1000 * attempts));
      }
    }
    
    if (!scriptData) {
      throw new Error('Failed to generate script after 3 attempts');
    }

    // AC 5: Generate Manim scene specs for each section
    const sectionsWithScenes = scriptData.sections.map((section: ScriptSection) => {
      const manimScenes = generateManimScenes(question, section);
      return {
        ...section,
        manim_scene_specs: manimScenes.length > 0 ? manimScenes : undefined,
      };
    });

    return {
      script_text: JSON.stringify({ sections: sectionsWithScenes }, null, 2),
      sections: sectionsWithScenes,
      question_metadata: {
        question_id: questionId,
        year: question.year,
        paper_type: question.paper_type,
        subject: question.subject,
        marks: question.marks,
      },
    };
    
  } catch (error) {
    console.error('Error in generatePyqScript:', error);
    throw new Error(`Script generation failed: ${error.message}`);
  }
}
