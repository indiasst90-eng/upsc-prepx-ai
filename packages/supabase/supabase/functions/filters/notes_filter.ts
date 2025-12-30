/**
 * Notes Generation Filter
 *
 * Calls the Notes Generator service (port 8104) to synthesize comprehensive
 * notes from RAG search results and topic specifications.
 */

const NOTES_SERVICE_URL = process.env.VPS_NOTES_URL || 'http://89.117.60.144:8104';

export interface NotesGenerationParams {
  topic: string;
  subtopics?: string[];
  level: 'basic' | 'intermediate' | 'advanced';
  format: 'bullet' | 'paragraph' | 'mixed';
  includeDiagrams?: boolean;
  includeExamples?: boolean;
  targetLength?: number; // words
}

export interface NotesGenerationResult {
  notesId: string;
  status: 'queued' | 'generating' | 'completed' | 'failed';
  content?: string;
  sections?: Array<{
    title: string;
    content: string;
    keyPoints: string[];
  }>;
  diagrams?: Array<{
    description: string;
    manimSceneUrl?: string;
  }>;
  error?: string;
  estimatedTime?: number;
}

export async function notesGenerationFilter(
  params: NotesGenerationParams
): Promise<NotesGenerationResult> {
  const response = await fetch(`${NOTES_SERVICE_URL}/generate_notes`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
    },
    body: JSON.stringify(params),
  });

  if (!response.ok) {
    const error = await response.text();
    console.error(`[Notes Filter] Error: ${response.status} - ${error}`);
    throw new Error(`Notes generator error: ${response.statusText}`);
  }

  return response.json();
}

export async function getNotesStatus(notesId: string): Promise<NotesGenerationResult> {
  const response = await fetch(`${NOTES_SERVICE_URL}/status/${notesId}`, {
    headers: {
      'Authorization': `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
    },
  });

  if (!response.ok) {
    throw new Error(`Status check failed: ${response.statusText}`);
  }

  return response.json();
}

export async function exportNotes(
  notesId: string,
  format: 'pdf' | 'markdown' | 'docx'
): Promise<Buffer> {
  const response = await fetch(`${NOTES_SERVICE_URL}/export/${notesId}?format=${format}`, {
    headers: {
      'Authorization': `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
    },
  });

  if (!response.ok) {
    throw new Error(`Export failed: ${response.statusText}`);
  }

  return Buffer.from(await response.arrayBuffer());
}
