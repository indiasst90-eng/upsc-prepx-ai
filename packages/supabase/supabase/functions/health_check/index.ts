/**
 * Health Check Pipeline
 *
 * Comprehensive health monitoring for all services:
 * - Supabase database
 * - All VPS services (Manim, Revideo, RAG, Orchestrator, Notes)
 * - A4F API
 *
 * Used by admin dashboard and automated monitoring.
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from '@supabase/supabase-js';
import { corsHeaders } from '../_shared/cors.ts';

interface ServiceHealth {
  name: string;
  status: 'healthy' | 'degraded' | 'unhealthy';
  latency_ms?: number;
  error?: string;
  details?: Record<string, unknown>;
}

interface HealthCheckResponse {
  success: boolean;
  timestamp: string;
  overall_status: 'healthy' | 'degraded' | 'unhealthy';
  services: {
    database: ServiceHealth;
    supabase: ServiceHealth;
    manim: ServiceHealth;
    revideo: ServiceHealth;
    rag: ServiceHealth;
    orchestrator: ServiceHealth;
    notes: ServiceHealth;
    a4f: ServiceHealth;
  };
  summary: {
    total: number;
    healthy: number;
    degraded: number;
    unhealthy: number;
    avg_latency_ms: number;
  };
  check_duration_ms: number;
  version: string;
}

// Service URLs from environment
const getServiceUrls = () => ({
  SUPABASE_URL: Deno.env.get('NEXT_PUBLIC_SUPABASE_URL') || 'http://89.117.60.144:8001',
  SUPABASE_ANON_KEY: Deno.env.get('NEXT_PUBLIC_SUPABASE_ANON_KEY') || '',
  SUPABASE_SERVICE_KEY: Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || Deno.env.get('NEXT_PUBLIC_SUPABASE_ANON_KEY') || '',
  A4F_BASE_URL: Deno.env.get('A4F_BASE_URL') || 'https://api.a4f.co/v1',
  A4F_API_KEY: Deno.env.get('A4F_API_KEY') || '',
  VPS_MANIM_URL: Deno.env.get('VPS_MANIM_URL') || 'http://89.117.60.144:5000',
  VPS_REVIDEO_URL: Deno.env.get('VPS_REVIDEO_URL') || 'http://89.117.60.144:5001',
  VPS_RAG_URL: Deno.env.get('VPS_RAG_URL') || 'http://89.117.60.144:8101',
  VPS_ORCHESTRATOR_URL: Deno.env.get('VPS_ORCHESTRATOR_URL') || 'http://89.117.60.144:8103',
  VPS_NOTES_URL: Deno.env.get('VPS_NOTES_URL') || 'http://89.117.60.144:8104',
});

const TIMEOUT_MS = 10000;

async function checkSupabase(env: ReturnType<typeof getServiceUrls>): Promise<ServiceHealth> {
  const start = Date.now();
  try {
    const supabase = createClient(env.SUPABASE_URL, env.SUPABASE_ANON_KEY);

    const { data, error } = await supabase.from('users').select('count').single();

    if (error && error.code !== 'PGRST116') {
      throw error;
    }

    return {
      name: 'Supabase',
      status: 'healthy',
      latency_ms: Date.now() - start,
      details: { connected: true },
    };
  } catch (error) {
    return {
      name: 'Supabase',
      status: 'unhealthy',
      latency_ms: Date.now() - start,
      error: error instanceof Error ? error.message : 'Unknown error',
    };
  }
}

async function checkDatabase(env: ReturnType<typeof getServiceUrls>): Promise<ServiceHealth> {
  const start = Date.now();
  try {
    const supabase = createClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_KEY);

    const { error } = await supabase
      .from('syllabus_nodes')
      .select('id')
      .limit(1)
      .maybeSingle();

    if (error && error.code !== 'PGRST116') {
      throw error;
    }

    return {
      name: 'PostgreSQL',
      status: 'healthy',
      latency_ms: Date.now() - start,
      details: { responsive: true },
    };
  } catch (error) {
    return {
      name: 'PostgreSQL',
      status: 'unhealthy',
      latency_ms: Date.now() - start,
      error: error instanceof Error ? error.message : 'Unknown error',
    };
  }
}

async function checkVPSService(name: string, url: string): Promise<ServiceHealth> {
  const start = Date.now();
  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), TIMEOUT_MS);

    const response = await fetch(url, {
      method: 'GET',
      signal: controller.signal,
    });

    clearTimeout(timeoutId);

    if (response.ok) {
      let details: Record<string, unknown> = { status: 'responding', http_status: response.status };
      try {
        details = await response.json().catch(() => details);
      } catch {
        // Ignore JSON parse errors
      }

      return {
        name,
        status: 'healthy',
        latency_ms: Date.now() - start,
        details,
      };
    }

    return {
      name,
      status: 'degraded',
      latency_ms: Date.now() - start,
      error: `HTTP ${response.status}: ${response.statusText}`,
    };
  } catch (error) {
    let errorMessage = error instanceof Error ? error.message : 'Unknown error';

    if (error instanceof Error && error.name === 'AbortError') {
      errorMessage = 'Request timed out';
    }

    return {
      name,
      status: 'unhealthy',
      latency_ms: Date.now() - start,
      error: errorMessage,
    };
  }
}

async function checkA4F(env: ReturnType<typeof getServiceUrls>): Promise<ServiceHealth> {
  const start = Date.now();
  try {
    if (!env.A4F_API_KEY) {
      return {
        name: 'A4F API',
        status: 'unhealthy',
        latency_ms: Date.now() - start,
        error: 'API key not configured',
      };
    }

    const response = await fetch(`${env.A4F_BASE_URL}/models`, {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${env.A4F_API_KEY}`,
        'Content-Type': 'application/json',
      },
    });

    if (response.ok) {
      return {
        name: 'A4F API',
        status: 'healthy',
        latency_ms: Date.now() - start,
        details: { models_endpoint: 'accessible' },
      };
    }

    return {
      name: 'A4F API',
      status: 'degraded',
      latency_ms: Date.now() - start,
      error: `HTTP ${response.status}: ${response.statusText}`,
    };
  } catch (error) {
    return {
      name: 'A4F API',
      status: 'unhealthy',
      latency_ms: Date.now() - start,
      error: error instanceof Error ? error.message : 'Unknown error',
    };
  }
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const startTime = Date.now();
  const env = getServiceUrls();

  // Run all health checks in parallel
  const [supabase, database, manim, revideo, rag, orchestrator, notes, a4f] =
    await Promise.all([
      checkSupabase(env),
      checkDatabase(env),
      checkVPSService('Manim Renderer', env.VPS_MANIM_URL),
      checkVPSService('Revideo Renderer', env.VPS_REVIDEO_URL),
      checkVPSService('Document Retriever', env.VPS_RAG_URL),
      checkVPSService('Video Orchestrator', env.VPS_ORCHESTRATOR_URL),
      checkVPSService('Notes Generator', env.VPS_NOTES_URL),
      checkA4F(env),
    ]);

  // Calculate summary
  const services = [supabase, database, manim, revideo, rag, orchestrator, notes, a4f];
  const healthy = services.filter(s => s.status === 'healthy').length;
  const degraded = services.filter(s => s.status === 'degraded').length;
  const unhealthy = services.filter(s => s.status === 'unhealthy').length;

  const totalLatency = services
    .filter(s => s.latency_ms)
    .reduce((sum, s) => sum + (s.latency_ms || 0), 0);
  const avgLatency = healthy > 0 ? Math.round(totalLatency / healthy) : 0;

  // Determine overall status
  let overallStatus: 'healthy' | 'degraded' | 'unhealthy';
  if (unhealthy > 0) {
    overallStatus = 'unhealthy';
  } else if (degraded > 0) {
    overallStatus = 'degraded';
  } else {
    overallStatus = 'healthy';
  }

  const response: HealthCheckResponse = {
    success: true,
    timestamp: new Date().toISOString(),
    overall_status: overallStatus,
    services: {
      database,
      supabase,
      manim,
      revideo,
      rag,
      orchestrator,
      notes,
      a4f,
    },
    summary: {
      total: services.length,
      healthy,
      degraded,
      unhealthy,
      avg_latency_ms: avgLatency,
    },
    check_duration_ms: Date.now() - startTime,
    version: '1.0.0',
  };

  const statusCode = overallStatus === 'healthy' ? 200 : overallStatus === 'degraded' ? 200 : 503;

  return new Response(JSON.stringify(response, null, 2), {
    status: statusCode,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
});
