/**
 * RAG Search Filter
 *
 * Calls the Document Retriever service (port 8101) to perform semantic search
 * over the knowledge base using vector embeddings.
 *
 * Updated Dec 2025 to match actual API endpoints:
 * - POST /documents/search - Search documents
 * - POST /documents/add - Add document
 * - GET /documents - List documents
 * - GET /documents/{id} - Get document
 * - DELETE /documents/{id} - Delete document
 */

const RAG_SERVICE_URL = Deno.env.get('VPS_RAG_URL') || 'http://89.117.60.144:8101';
const REQUEST_TIMEOUT_MS = 5000;

export interface RAGSearchParams {
  query: string;
  topK?: number;
  filters?: Record<string, unknown>;
}

export interface RAGSearchResult {
  chunks: Array<{
    id: string;
    content: string;
    score: number;
    metadata?: Record<string, unknown>;
  }>;
  confidence: number;
  sources: string[];
}

export interface DocumentAddParams {
  docId: string;
  content: string;
  metadata?: Record<string, unknown>;
}

/**
 * Search documents using semantic search
 */
export async function ragSearchFilter(params: RAGSearchParams): Promise<RAGSearchResult> {
  const { query, topK = 10, filters } = params;

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);

  try {
    const response = await fetch(`${RAG_SERVICE_URL}/documents/search`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        query,
        top_k: topK,
        filters,
      }),
      signal: controller.signal,
    });

    clearTimeout(timeoutId);

    if (!response.ok) {
      const error = await response.text();
      console.error(`[RAG Filter] Error: ${response.status} - ${error}`);
      throw new Error(`RAG service error: ${response.status} - ${response.statusText}`);
    }

    const results = await response.json() as Array<{
      id: string;
      content: string;
      score?: number;
      metadata?: Record<string, unknown>;
    }>;

    // Transform results to expected format
    const chunks = results.map(r => ({
      id: r.id,
      content: r.content,
      score: r.score || 0,
      metadata: r.metadata,
    }));

    // Calculate confidence based on top result score
    const confidence = chunks.length > 0 && chunks[0].score > 0
      ? chunks[0].score
      : 0;

    // Extract unique sources
    const sources = [...new Set(
      chunks
        .map(c => c.metadata?.source as string)
        .filter(Boolean)
    )];

    return {
      chunks,
      confidence,
      sources,
    };
  } catch (error) {
    clearTimeout(timeoutId);

    if (error.name === 'AbortError') {
      throw new Error('RAG service request timed out');
    }
    throw error;
  }
}

/**
 * Add a document to the RAG index
 */
export async function addDocument(params: DocumentAddParams): Promise<{ status: string; docId: string }> {
  const { docId, content, metadata } = params;

  const url = new URL(`${RAG_SERVICE_URL}/documents/add`);
  url.searchParams.set('doc_id', docId);
  url.searchParams.set('content', content);

  const response = await fetch(url.toString(), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: metadata ? JSON.stringify(metadata) : undefined,
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Failed to add document: ${response.status} - ${error}`);
  }

  const result = await response.json();
  return {
    status: result.status,
    docId: result.doc_id,
  };
}

/**
 * List all documents in the RAG index
 */
export async function listDocuments(): Promise<{ count: number; documents: string[] }> {
  const response = await fetch(`${RAG_SERVICE_URL}/documents`);

  if (!response.ok) {
    throw new Error(`Failed to list documents: ${response.statusText}`);
  }

  return response.json();
}

/**
 * Get a specific document by ID
 */
export async function getDocument(docId: string): Promise<{
  id: string;
  content: string;
  metadata?: Record<string, unknown>;
}> {
  const response = await fetch(`${RAG_SERVICE_URL}/documents/${encodeURIComponent(docId)}`);

  if (!response.ok) {
    if (response.status === 404) {
      throw new Error(`Document not found: ${docId}`);
    }
    throw new Error(`Failed to get document: ${response.statusText}`);
  }

  return response.json();
}

/**
 * Delete a document from the RAG index
 */
export async function deleteDocument(docId: string): Promise<{ status: string }> {
  const response = await fetch(`${RAG_SERVICE_URL}/documents/${encodeURIComponent(docId)}`, {
    method: 'DELETE',
  });

  if (!response.ok) {
    throw new Error(`Failed to delete document: ${response.statusText}`);
  }

  return response.json();
}

/**
 * Check RAG service health
 */
export async function healthCheck(): Promise<{ status: string; service: string; port: number }> {
  const response = await fetch(`${RAG_SERVICE_URL}/health`);

  if (!response.ok) {
    throw new Error(`RAG service unhealthy: ${response.statusText}`);
  }

  return response.json();
}
