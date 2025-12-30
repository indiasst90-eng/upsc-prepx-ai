/**
 * @upsc-prepx-ai/config Jest/Vitest tests
 */

import { describe, it, expect, vi } from 'vitest';

// Mock environment
const mockEnv = {
  NEXT_PUBLIC_SUPABASE_URL: 'http://localhost:54321',
  NEXT_PUBLIC_SUPABASE_ANON_KEY: 'test-anon-key',
  SUPABASE_SERVICE_ROLE_KEY: 'test-service-role-key',
  A4F_API_KEY: 'ddc-a4f-test-key',
  A4F_BASE_URL: 'https://api.a4f.co/v1',
  VPS_MANIM_URL: 'http://localhost:5000',
  VPS_REVIDEO_URL: 'http://localhost:5001',
  VPS_RAG_URL: 'http://localhost:8101',
  VPS_SEARCH_URL: 'http://localhost:8102',
  VPS_ORCHESTRATOR_URL: 'http://localhost:8103',
  VPS_NOTES_URL: 'http://localhost:8104',
  NODE_ENV: 'development',
  NEXT_PUBLIC_APP_URL: 'http://localhost:3000',
  NEXT_PUBLIC_ADMIN_URL: 'http://localhost:3001',
  ENABLE_DEBUG_MODE: false,
};

describe('Environment Validation', () => {
  beforeEach(() => {
    vi.resetModules();
    // Clear any cached env
    process.env = { ...mockEnv };
  });

  it('should parse valid environment variables', async () => {
    const { getEnv } = await import('./index.ts');
    const env = getEnv();
    expect(env.NEXT_PUBLIC_SUPABASE_URL).toBe('http://localhost:54321');
    expect(env.A4F_API_KEY).toStartWith('ddc-a4f-');
  });

  it('should reject invalid API key format', async () => {
    process.env.A4F_API_KEY = 'invalid-key';
    const { getEnv } = await import('./index.ts');
    expect(() => getEnv()).toThrow();
  });

  it('should reject invalid URL format', async () => {
    process.env.NEXT_PUBLIC_SUPABASE_URL = 'not-a-url';
    const { getEnv } = await import('./index.ts');
    expect(() => getEnv()).toThrow();
  });

  it('should use default values for optional variables', async () => {
    const { getEnv } = await import('./index.ts');
    const env = getEnv();
    expect(env.TRIAL_DURATION_DAYS).toBe(7);
    expect(env.ENABLE_DEBUG_MODE).toBe(false);
  });
});

// Custom matcher
expect.extend({
  toStartWith(received: string, expected: string) {
    const pass = received.startsWith(expected);
    return {
      pass,
      message: () =>
        pass
          ? `expected ${received} not to start with ${expected}`
          : `expected ${received} to start with ${expected}`,
    };
  },
});

declare module 'vitest' {
  interface Assertion<T = any> {
    toStartWith(expected: string): T;
  }
}
