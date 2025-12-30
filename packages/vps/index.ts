/**
 * VPS Services Client
 *
 * Connects to self-hosted services on VPS (89.117.60.144):
 * - Manim Renderer (port 5000): Mathematical animations
 * - Revideo Renderer (port 5001): Video composition
 * - Document Retriever (port 8101): RAG engine
 * - Video Orchestrator (port 8103): Video rendering coordination
 * - Notes Generator (port 8104): AI notes generation
 * - Crawl4AI (port 8105): Current affairs web crawler
 */

import { getEnv } from '../config';

// Type definitions for service responses
export interface ManimRenderRequest {
  script: string;
  output_format: 'mp4' | 'gif' | 'webm';
  quality: 'low' | 'medium' | 'high';
  width?: number;
  height?: number;
  fps?: number;
}

export interface ManimRenderResponse {
  success: boolean;
  render_id: string;
  output_url?: string;
  error?: string;
  processing_time_seconds?: number;
}

export interface RevideoRenderRequest {
  project: {
    template: 'explainer' | 'news' | 'tutorial' | 'custom';
    scenes: RevideoScene[];
    width?: number;
    height?: number;
    fps?: number;
  };
  audio?: {
    voiceover?: string;
    background_music?: string;
  };
}

export interface RevideoScene {
  id: string;
  type: 'manim' | 'image' | 'text' | 'video';
  duration_seconds: number;
  content: Record<string, unknown>;
  transitions?: Record<string, unknown>;
}

export interface RevideoRenderResponse {
  success: boolean;
  render_id: string;
  output_url?: string;
  thumbnail_url?: string;
  error?: string;
  processing_time_seconds?: number;
}

export interface NotesGenerationRequest {
  topic: string;
  level: 'basic' | 'intermediate' | 'advanced';
  format: 'markdown' | 'html' | 'mixed';
  include_diagrams: boolean;
  include_examples: boolean;
  word_count?: number;
}

export interface NotesGenerationResponse {
  success: boolean;
  notes_id: string;
  title: string;
  content: string;
  word_count: number;
  reading_time_minutes: number;
  error?: string;
}

export interface VideoOrchestratorRequest {
  type: 'daily_news' | 'doubt_video' | 'explanation' | 'documentary';
  script: string;
  visuals: VisualSpec[];
  audio: AudioSpec;
  settings?: {
    width?: number;
    height?: number;
    fps?: number;
    quality?: string;
  };
}

export interface VisualSpec {
  type: 'manim_diagram' | 'stock_footage' | 'text_overlay' | 'image';
  spec: Record<string, unknown>;
  duration_seconds: number;
  start_time_seconds: number;
}

export interface AudioSpec {
  voice: 'male' | 'female';
  language: string;
  speed: number;
}

export interface VideoOrchestratorResponse {
  success: boolean;
  render_id: string;
  status: 'queued' | 'processing' | 'completed' | 'failed';
  estimated_completion_seconds?: number;
  output_url?: string;
  error?: string;
}

// Document Retriever types - Updated based on actual API (Dec 2025)
export interface DocumentAddRequest {
  doc_id: string;
  content: string;
  metadata?: Record<string, unknown>;
}

export interface DocumentSearchRequest {
  query: string;
  top_k?: number;
  filters?: Record<string, unknown>;
}

export interface DocumentSearchResult {
  id: string;
  content: string;
  metadata?: Record<string, unknown>;
  score?: number;
}

export interface DocumentListResponse {
  count: number;
  documents: string[];
}

export interface Document {
  id: string;
  content: string;
  metadata?: Record<string, unknown>;
}

// Legacy interface for backward compatibility
export interface DocumentRetrieveRequest {
  query: string;
  top_k?: number;
  filters?: {
    subjects?: string[];
    papers?: string[];
    source_types?: string[];
  };
}

export interface DocumentRetrieveResponse {
  results: {
    id: string;
    content: string;
    source: {
      title: string;
      chapter: string;
      page: number;
    };
    relevance_score: number;
  }[];
  insufficient_confidence?: boolean;
}

// Base VPS client
class VPSClient {
  private baseUrl: string;

  constructor(baseUrl: string) {
    this.baseUrl = baseUrl;
  }

  protected async request<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<T> {
    const url = `${this.baseUrl}${endpoint}`;

    const response = await fetch(url, {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        ...options.headers,
      },
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`VPS request failed: ${response.status} - ${error}`);
    }

    return response.json();
  }
}

// Manim Service Client
export class ManimService extends VPSClient {
  constructor() {
    super(getEnv().VPS_MANIM_URL);
  }

  async render(request: ManimRenderRequest): Promise<ManimRenderResponse> {
    return this.request<ManimRenderResponse>('/render', {
      method: 'POST',
      body: JSON.stringify(request),
    });
  }

  async getStatus(renderId: string): Promise<{ status: string; progress: number }> {
    return this.request(`/status/${renderId}`);
  }

  async cancelRender(renderId: string): Promise<{ success: boolean }> {
    return this.request(`/cancel/${renderId}`, { method: 'POST' });
  }
}

// Revideo Service Client
export class RevideoService extends VPSClient {
  constructor() {
    super(getEnv().VPS_REVIDEO_URL);
  }

  async render(request: RevideoRenderRequest): Promise<RevideoRenderResponse> {
    return this.request<RevideoRenderResponse>('/render', {
      method: 'POST',
      body: JSON.stringify(request),
    });
  }

  async getStatus(renderId: string): Promise<{ status: string; progress: number }> {
    return this.request(`/status/${renderId}`);
  }

  async listTemplates(): Promise<{ templates: string[] }> {
    return this.request('/templates');
  }
}

// Notes Generator Service Client
export class NotesService extends VPSClient {
  constructor() {
    super(getEnv().VPS_NOTES_URL);
  }

  async generate(request: NotesGenerationRequest): Promise<NotesGenerationResponse> {
    return this.request<NotesGenerationResponse>('/generate_notes', {
      method: 'POST',
      body: JSON.stringify(request),
    });
  }

  async getStatus(notesId: string): Promise<{ status: string }> {
    return this.request(`/status/${notesId}`);
  }
}

// Video Orchestrator Service Client
export class VideoOrchestratorService extends VPSClient {
  constructor() {
    super(getEnv().VPS_ORCHESTRATOR_URL);
  }

  async render(request: VideoOrchestratorRequest): Promise<VideoOrchestratorResponse> {
    return this.request<VideoOrchestratorResponse>('/render', {
      method: 'POST',
      body: JSON.stringify(request),
    });
  }

  async getStatus(renderId: string): Promise<VideoOrchestratorResponse> {
    return this.request(`/status/${renderId}`);
  }

  async cancelRender(renderId: string): Promise<{ success: boolean }> {
    return this.request(`/cancel/${renderId}`, { method: 'POST' });
  }
}

// Document Retriever Service Client - Updated based on actual API (Dec 2025)
export class DocumentRetrieverService extends VPSClient {
  constructor() {
    super(getEnv().VPS_RAG_URL);
  }

  // Health check
  async health(): Promise<{ status: string; service: string; port: number }> {
    return this.request('/health');
  }

  // Add document
  async addDocument(docId: string, content: string, metadata?: Record<string, unknown>): Promise<{ status: string; doc_id: string }> {
    const params = new URLSearchParams({
      doc_id: docId,
      content: content,
    });
    return this.request(`/documents/add?${params.toString()}`, {
      method: 'POST',
      body: metadata ? JSON.stringify(metadata) : undefined,
    });
  }

  // List all documents
  async listDocuments(): Promise<DocumentListResponse> {
    return this.request('/documents');
  }

  // Get specific document
  async getDocument(docId: string): Promise<Document> {
    return this.request(`/documents/${encodeURIComponent(docId)}`);
  }

  // Delete document
  async deleteDocument(docId: string): Promise<{ status: string }> {
    return this.request(`/documents/${encodeURIComponent(docId)}`, {
      method: 'DELETE',
    });
  }

  // Search documents (semantic search)
  async search(request: DocumentSearchRequest): Promise<DocumentSearchResult[]> {
    return this.request<DocumentSearchResult[]>('/documents/search', {
      method: 'POST',
      body: JSON.stringify(request),
    });
  }

  // Legacy retrieve method (wraps search for backward compatibility)
  async retrieve(request: DocumentRetrieveRequest): Promise<DocumentRetrieveResponse> {
    const results = await this.search({
      query: request.query,
      top_k: request.top_k,
      filters: request.filters,
    });

    return {
      results: results.map(r => ({
        id: r.id,
        content: r.content,
        source: {
          title: r.metadata?.source as string || 'Unknown',
          chapter: r.metadata?.chapter as string || 'Unknown',
          page: r.metadata?.page as number || 0,
        },
        relevance_score: r.score || 0,
      })),
      insufficient_confidence: results.length === 0,
    };
  }
}

// Crawl4AI types
export interface Crawl4AIRequest {
  url: string;
  extract_links?: boolean;
}

export interface Crawl4AIResponse {
  url: string;
  title: string;
  content: string;
  success: boolean;
  error?: string;
}

export interface Crawl4AIHealthResponse {
  status: string;
  service: string;
  allowed_domains: string[];
}

// Crawl4AI Service Client
export class Crawl4AIService extends VPSClient {
  constructor() {
    super(getEnv().VPS_CRAWL4AI_URL || 'http://89.117.60.144:8105');
  }

  // Health check
  async health(): Promise<Crawl4AIHealthResponse> {
    return this.request('/health');
  }

  // Crawl a URL
  async crawl(url: string, extractLinks = false): Promise<Crawl4AIResponse> {
    return this.request<Crawl4AIResponse>('/crawl', {
      method: 'POST',
      body: JSON.stringify({ url, extract_links: extractLinks }),
    });
  }

  // Batch crawl multiple URLs
  async batchCrawl(urls: string[]): Promise<{ results: Crawl4AIResponse[]; total: number }> {
    return this.request('/batch', {
      method: 'POST',
      body: JSON.stringify(urls),
    });
  }

  // List allowed domains
  async listDomains(): Promise<{ domains: string[] }> {
    return this.request('/domains');
  }

  // Convenience methods for specific sources
  async crawlDrishtiIAS(topic: string): Promise<Crawl4AIResponse> {
    return this.crawl(`https://www.drishtiias.com/?s=${encodeURIComponent(topic)}`);
  }

  async crawlPIB(search: string): Promise<Crawl4AIResponse> {
    return this.crawl(`https://pib.gov.in/AllRelease.aspx?search=${encodeURIComponent(search)}`);
  }

  async crawlInsightsOnIndia(topic: string): Promise<Crawl4AIResponse> {
    return this.crawl(`https://www.insightsonindia.com/?s=${encodeURIComponent(topic)}`);
  }
}

// Export singleton instances
export const manimService = new ManimService();
export const revideoService = new RevideoService();
export const notesService = new NotesService();
export const videoOrchestratorService = new VideoOrchestratorService();
export const documentRetrieverService = new DocumentRetrieverService();
export const crawl4aiService = new Crawl4AIService();
