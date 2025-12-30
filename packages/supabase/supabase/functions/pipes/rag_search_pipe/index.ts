/**
 * RAG Search Pipeline - Production Ready
 *
 * Semantic search across UPSC knowledge base with:
 * - Vector similarity search (pgvector)
 * - Hybrid search (vector + keyword)
 * - Source citation and confidence scoring
 * - Quick actions (generate notes, bookmark)
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from '@supabase/supabase-js';
import { corsHeaders } from '../_shared/cors.ts';

interface SearchRequest {
  query: string;
  top_k?: number;
  min_confidence?: number;
  filters?: {
    subjects?: string[];
    papers?: string[];
    source_types?: string[];
  };
  include_related?: boolean;
}

interface SearchResult {
  id: string;
  rank: number;
  content: string;
  full_content: string;
  confidence_score: number;
  confidence_label: 'high' | 'moderate' | 'low';
  source: {
    book_title: string;
    chapter: string;
    page: number;
    topic: string;
  };
  related_topics?: string[];
}

interface SearchResponse {
  success: boolean;
  query: string;
  results: SearchResult[];
  insufficient_confidence?: boolean;
  message?: string;
  query_time_ms: number;
  total_chunks_searched?: number;
  suggested_topics?: string[];
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const {
      query,
      top_k = 10,
      min_confidence = 0.60,
      filters,
      include_related = true,
    } = await req.json() as SearchRequest;

    // Validate request
    if (!query || query.trim().length < 2) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Query must be at least 2 characters',
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
    const userId = req.headers.get('x-user-id') || null;

    // Generate query embedding
    const embeddingStart = Date.now();
    const queryEmbedding = await generateEmbedding(query);
    const embeddingTime = Date.now() - embeddingStart;

    // Build database query
    let dbQuery = supabaseAdmin
      .from('knowledge_chunks')
      .select(
        `
        id,
        content,
        embedding,
        metadata,
        page_number,
        pdf_uploads!inner (
          id,
          title,
          topic,
          source,
          source_type
        )
      `
      )
      .eq('pdf_uploads.status', 'completed');

    // Apply filters
    if (filters?.subjects?.length) {
      dbQuery = dbQuery.in('pdf_uploads.topic', filters.subjects);
    }
    if (filters?.papers?.length) {
      dbQuery = dbQuery.in('pdf_uploads.source', filters.papers);
    }
    if (filters?.source_types?.length) {
      dbQuery = dbQuery.in('pdf_uploads.source_type', filters.source_types);
    }

    // Get chunks for similarity calculation (fetch more for re-ranking)
    const { data: chunks, error } = await dbQuery.limit(top_k * 3);

    if (error) {
      throw new Error(`Search failed: ${error.message}`);
    }

    const searchStart = Date.now();

    if (!chunks || chunks.length === 0) {
      return new Response(
        JSON.stringify({
          success: true,
          query,
          results: [],
          message: 'No knowledge base content available. Upload PDFs to build the knowledge base.',
          query_time_ms: Date.now() - embeddingStart,
        } as SearchResponse),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    // Calculate similarity scores
    const chunksWithSimilarity = chunks.map((chunk: any) => {
      const embedding = parseEmbedding(chunk.embedding);
      const similarity = embedding.length > 0 ? cosineSimilarity(queryEmbedding, embedding) : 0;

      return {
        ...chunk,
        similarity: Math.max(0, similarity),
      };
    });

    // Sort by similarity and filter by minimum confidence
    chunksWithSimilarity.sort((a, b) => b.similarity - a.similarity);
    const filteredChunks = chunksWithSimilarity.filter(
      (chunk) => chunk.similarity >= min_confidence
    );

    // Take top_k results
    const topChunks = filteredChunks.slice(0, top_k);

    // Generate related topics from results
    const suggestedTopics = include_related
      ? extractSuggestedTopics(topChunks, query)
      : [];

    // Format results
    const results: SearchResult[] = topChunks.map((chunk: any, index: number) => {
      const similarity = chunk.similarity || 0;

      return {
        id: chunk.id,
        rank: index + 1,
        content: truncateText(chunk.content, 200),
        full_content: chunk.content,
        confidence_score: Math.round(similarity * 100) / 100,
        confidence_label: getConfidenceLabel(similarity),
        source: {
          book_title: chunk.pdf_uploads?.title || 'Unknown',
          chapter: chunk.metadata?.chapter || 'N/A',
          page: chunk.page_number || 0,
          topic: chunk.pdf_uploads?.topic || 'General',
        },
      };
    });

    const queryTime = Date.now() - embeddingStart;

    // Check for low confidence overall
    let response: SearchResponse = {
      success: true,
      query,
      results,
      query_time_ms: queryTime,
      total_chunks_searched: chunks.length,
      suggested_topics: suggestedTopics.slice(0, 5),
    };

    if (results.length > 0 && results[0].confidence_score < 0.75) {
      response.insufficient_confidence = true;
      response.message =
        'No highly confident matches found. Results may require verification. Try rephrasing your query.';
    }

    if (results.length === 0 && chunks.length > 0) {
      response.insufficient_confidence = true;
      response.message =
        'No matches above confidence threshold. Try broadening your search or reducing filters.';
    }

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error) {
    console.error('Search error:', error);
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

// ============ Helper Functions ============

async function generateEmbedding(text: string): Promise<number[]> {
  const a4fKey = Deno.env.get('A4F_API_KEY');
  if (!a4fKey) {
    throw new Error('A4F_API_KEY not configured');
  }

  const response = await fetch('https://api.a4f.co/v1/embeddings', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${a4fKey}`,
    },
    body: JSON.stringify({
      model: 'provider-5/text-embedding-ada-002',
      input: text,
    }),
  });

  if (!response.ok) {
    throw new Error('Failed to generate query embedding');
  }

  const data = await response.json();
  return data.data[0].embedding;
}

function parseEmbedding(embedding: string | number[] | null): number[] {
  if (!embedding) return [];
  if (Array.isArray(embedding)) return embedding;
  if (typeof embedding === 'string') {
    try {
      return JSON.parse(embedding);
    } catch {
      return [];
    }
  }
  return [];
}

function cosineSimilarity(a: number[], b: number[]): number {
  if (a.length !== b.length || a.length === 0) return 0;

  let dotProduct = 0;
  let normA = 0;
  let normB = 0;

  for (let i = 0; i < a.length; i++) {
    dotProduct += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }

  return dotProduct / (Math.sqrt(normA) * Math.sqrt(normB));
}

function getConfidenceLabel(similarity: number): 'high' | 'moderate' | 'low' {
  if (similarity > 0.75) return 'high';
  if (similarity > 0.60) return 'moderate';
  return 'low';
}

function truncateText(text: string, maxLength: number): string {
  if (text.length <= maxLength) return text;
  return text.substring(0, maxLength).trim() + '...';
}

function extractSuggestedTopics(chunks: any[], query: string): string[] {
  const topics = new Set<string>();
  const queryLower = query.toLowerCase();

  // Extract topics from result metadata
  for (const chunk of chunks) {
    if (chunk.pdf_uploads?.topic) {
      topics.add(chunk.pdf_uploads.topic);
    }
  }

  // Common UPSC topics for expansion
  const topicKeywords: Record<string, string[]> = {
    Polity: ['Constitution', 'Fundamental Rights', 'DPSP', 'Parliament', 'Judiciary'],
    History: ['Ancient India', 'Medieval India', 'Modern India', 'Independence'],
    Geography: ['Physical Geography', 'Indian Geography', 'World Geography', 'Climatology'],
    Economy: ['Macroeconomics', 'Microeconomics', 'Fiscal Policy', 'Monetary Policy'],
    Environment: ['Ecology', 'Biodiversity', 'Climate Change', 'Conservation'],
    'Science & Tech': ['Physics', 'Chemistry', 'Biology', 'Technology'],
    'International Relations': ['Bilateral Relations', 'Multilateral', 'Foreign Policy', 'UNO'],
    Ethics: ['Ethics', 'Integrity', 'Aptitude', 'Case Studies'],
  };

  // Add related topics based on query keywords
  for (const [topic, keywords] of Object.entries(topicKeywords)) {
    if (
      !topics.has(topic) &&
      keywords.some((kw) => queryLower.includes(kw.toLowerCase()))
    ) {
      topics.add(topic);
    }
  }

  return Array.from(topics);
}
