/**
 * A4F Unified API Client
 *
 * Provides access to all AI models through the A4F (All-in-One API) service:
 * Base URL: https://api.a4f.co/v1
 * API Key: ddc-a4f-12e06ff0184f41de8d3de7be4cd2e831
 *
 * - Primary LLM: provider-3/llama-4-scout (text, image, function calling)
 * - Fallback LLM: provider-2/gpt-4.1 (fallback when primary fails)
 * - Image Understanding: provider-3/gemini-2.5-flash (image tasks)
 * - Embeddings: provider-5/qwen3-embedding-8b
 * - TTS: provider-5/tts-1
 * - STT: provider-5/whisper-1
 * - Image Generation: provider-4/imagen-4
 */

// Configuration
const A4F_BASE_URL = process.env.A4F_BASE_URL || 'https://api.a4f.co/v1';
const A4F_API_KEY = process.env.A4F_API_KEY;

// Model IDs - Updated based on user specifications (Dec 2025)
export const MODELS = {
  // Chat/Completion Models
  PRIMARY_LLM: 'provider-3/llama-4-scout',      // Main model for text, image, function calling
  FALLBACK_LLM: 'provider-2/gpt-4.1',           // Secondary model when primary fails
  IMAGE_UNDERSTANDING: 'provider-3/gemini-2.5-flash', // For handling image tasks

  // Embeddings Model
  EMBEDDINGS: 'provider-5/qwen3-embedding-8b',  // For RAG vector search

  // Audio Models
  TTS: 'provider-5/tts-1',                      // Text-to-speech
  STT: 'provider-5/whisper-1',                  // Speech-to-text transcription

  // Image Generation Models
  IMAGE_GEN: 'provider-4/imagen-4',             // Image generation
} as const;

// Types
export type MessageContent = 
  | string 
  | Array<
      | { type: 'text'; text: string }
      | { type: 'image_url'; image_url: { url: string } }
    >;

export interface LLMMessage {
  role: 'system' | 'user' | 'assistant' | 'function';
  content: MessageContent;
  name?: string;
}

export interface LLMResponse {
  id: string;
  object: string;
  created: number;
  model: string;
  choices: Array<{
    index: number;
    message: LLMMessage;
    finish_reason: string;
  }>;
  usage: {
    prompt_tokens: number;
    completion_tokens: number;
    total_tokens: number;
  };
}

export interface EmbeddingResponse {
  object: string;
  data: Array<{
    object: string;
    embedding: number[];
    index: number;
  }>;
  model: string;
  usage: {
    prompt_tokens: number;
    total_tokens: number;
  };
}

export interface SpeechResponse {
  object: string;
  model: string;
  created: number;
  audio: Buffer;
}

export interface TranscriptionResponse {
  text: string;
  duration: number;
  language: string;
}

export interface ImageGenerationResponse {
  created: number;
  data: Array<{
    url: string;
    revised_prompt: string;
  }>;
}

// Rate Limiter
class RateLimiter {
  private requests: number[] = [];
  private maxPerMinute = 100;

  async throttle(): Promise<void> {
    const now = Date.now();
    this.requests = this.requests.filter(t => now - t < 60000);

    if (this.requests.length >= this.maxPerMinute) {
      const waitTime = 60000 - (now - this.requests[0]);
      await new Promise(resolve => setTimeout(resolve, waitTime));
    }

    this.requests.push(now);
  }
}

// Cost Tracker
class CostTracker {
  private totalTokens = 0;
  private requestCount = 0;
  private modelUsage: Record<string, number> = {};

  logRequest(model: string, tokens: number): void {
    this.totalTokens += tokens;
    this.requestCount++;
    this.modelUsage[model] = (this.modelUsage[model] || 0) + tokens;
  }

  getStats(): { totalTokens: number; requestCount: number; modelUsage: Record<string, number> } {
    return {
      totalTokens: this.totalTokens,
      requestCount: this.requestCount,
      modelUsage: { ...this.modelUsage },
    };
  }

  estimateCost(tokens: number = this.totalTokens): number {
    // Rough cost estimate: ₹0.10 per 1K tokens
    return (tokens / 1000) * 0.10;
  }
}

// A4F Client Class
export class A4FClient {
  private apiKey: string;
  private baseUrl: string;
  private rateLimiter: RateLimiter;
  private costTracker: CostTracker;
  private fallbackModel: string = MODELS.FALLBACK_LLM;
  private consecutiveErrors: number = 0;
  private maxConsecutiveErrors = 3;

  constructor() {
    this.apiKey = A4F_API_KEY || '';
    this.baseUrl = A4F_BASE_URL;
    this.rateLimiter = new RateLimiter();
    this.costTracker = new CostTracker();

    if (!this.apiKey) {
      console.warn('[A4F] API key not configured. Set A4F_API_KEY environment variable.');
    }
  }

  private async request<T>(endpoint: string, body: any): Promise<T> {
    if (!this.apiKey) {
      throw new Error('A4F API key not configured');
    }

    await this.rateLimiter.throttle();

    const response = await fetch(`${this.baseUrl}${endpoint}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${this.apiKey}`,
      },
      body: JSON.stringify(body),
    });

    if (!response.ok) {
      const error = await response.text();
      console.error(`[A4F] API error: ${response.status} - ${error}`);
      throw new Error(`A4F API error: ${response.status} - ${error}`);
    }

    return response.json() as Promise<T>;
  }

  // LLM Methods
  async chatCompletion(
    messages: LLMMessage[],
    options: {
      model?: string;
      maxTokens?: number;
      temperature?: number;
      useFallback?: boolean;
    } = {}
  ): Promise<LLMResponse> {
    const model = options.model || MODELS.PRIMARY_LLM;

    try {
      const response = await this.request<LLMResponse>('/chat/completions', {
        model,
        messages,
        max_tokens: options.maxTokens || 1000,
        temperature: options.temperature || 0.7,
      });

      this.costTracker.logRequest(model, response.usage.total_tokens);
      this.consecutiveErrors = 0;
      return response;
    } catch (error) {
      this.consecutiveErrors++;

      // Fallback to secondary model
      if (options.useFallback !== false && this.consecutiveErrors >= this.maxConsecutiveErrors) {
        console.warn(`[A4F] Primary model failed ${this.maxConsecutiveErrors} times, switching to fallback`);
        this.consecutiveErrors = 0;
        return this.chatCompletion(messages, { ...options, model: this.fallbackModel, useFallback: false });
      }

      throw error;
    }
  }

  async generateText(prompt: string, maxTokens?: number): Promise<string> {
    const response = await this.chatCompletion([
      { role: 'user', content: prompt },
    ], { maxTokens });

    const content = response.choices[0]?.message?.content;
    return typeof content === 'string' ? content : '';
  }

  // Embeddings
  async generateEmbeddings(input: string | string[]): Promise<EmbeddingResponse> {
    const response = await this.request<EmbeddingResponse>('/embeddings', {
      model: MODELS.EMBEDDINGS,
      input,
    });

    this.costTracker.logRequest(MODELS.EMBEDDINGS, response.usage.total_tokens);
    return response;
  }

  async embedText(text: string): Promise<number[]> {
    const response = await this.generateEmbeddings(text);
    return response.data[0]?.embedding || [];
  }

  async embedTexts(texts: string[]): Promise<number[][]> {
    const response = await this.generateEmbeddings(texts);
    return response.data.map(d => d.embedding);
  }

  // Text-to-Speech
  async textToSpeech(
    text: string,
    options: {
      voice?: string;
      model?: string;
    } = {}
  ): Promise<Buffer> {
    const voice = options.voice || 'alloy';

    const response = await fetch(`${this.baseUrl}/audio/speech`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: options.model || MODELS.TTS,  // Uses provider-5/tts-1
        input: text,
        voice,
      }),
    });

    if (!response.ok) {
      throw new Error(`TTS error: ${response.status}`);
    }

    return Buffer.from(await response.arrayBuffer());
  }

  // Speech-to-Text
  async speechToText(audioBuffer: Buffer, filename: string = 'audio.mp3'): Promise<TranscriptionResponse> {
    const formData = new FormData();
    formData.append('file', new Blob([audioBuffer]), filename);
    formData.append('model', MODELS.STT);

    const response = await fetch(`${this.baseUrl}/audio/transcriptions`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.apiKey}`,
      },
      body: formData,
    });

    if (!response.ok) {
      throw new Error(`STT error: ${response.status}`);
    }

    return response.json() as Promise<TranscriptionResponse>;
  }

  // Image Generation
  async generateImage(
    prompt: string,
    options: {
      n?: number;
      size?: string;
    } = {}
  ): Promise<ImageGenerationResponse> {
    const response = await this.request<ImageGenerationResponse>('/images/generations', {
      model: MODELS.IMAGE_GEN,
      prompt,
      n: options.n || 1,
      size: options.size || '1024x1024',
    });

    return response;
  }

  // Image Understanding (OCR, analysis)
  async analyzeImage(
    imageUrl: string,
    prompt: string
  ): Promise<string> {
    const response = await this.chatCompletion([
      {
        role: 'user',
        content: [
          { type: 'text', text: prompt },
          { type: 'image_url', image_url: { url: imageUrl } },
        ],
      },
    ], { model: MODELS.IMAGE_UNDERSTANDING });

    const content = response.choices[0]?.message?.content;
    return typeof content === 'string' ? content : '';
  }

  // Cost and Stats
  getCostStats() {
    return this.costTracker.getStats();
  }

  getEstimatedCost() {
    return this.costTracker.estimateCost();
  }
}

// Export singleton instance
export const a4fClient = new A4FClient();

// Helper functions
export async function llmRequest(prompt: string, maxTokens?: number): Promise<string> {
  return a4fClient.generateText(prompt, maxTokens);
}

export async function generateEmbeddings(texts: string | string[]): Promise<number[] | number[][]> {
  if (typeof texts === 'string') {
    return a4fClient.embedText(texts);
  }
  return a4fClient.embedTexts(texts);
}

export async function generateSpeech(text: string, voice?: string): Promise<Buffer> {
  return a4fClient.textToSpeech(text, { voice });
}

export async function transcribeSpeech(audioBuffer: Buffer): Promise<string> {
  const result = await a4fClient.speechToText(audioBuffer);
  return result.text;
}

export async function generateImage(prompt: string): Promise<string> {
  const response = await a4fClient.generateImage(prompt);
  return response.data[0]?.url || '';
}
