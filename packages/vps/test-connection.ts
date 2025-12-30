/**
 * VPS Services Connection Test Script
 *
 * Tests connectivity to all VPS services on 89.117.60.144
 * Run with: npx ts-node packages/vps/test-connection.ts
 */

import { getEnv } from '../config';

interface ServiceTest {
  name: string;
  url: string;
  port: number;
  expectedPath?: string;
}

const services: ServiceTest[] = [
  { name: 'Manim Renderer', url: getEnv().VPS_MANIM_URL, port: 5000 },
  { name: 'Revideo Renderer', url: getEnv().VPS_REVIDEO_URL, port: 5001 },
  { name: 'Document Retriever (RAG)', url: getEnv().VPS_RAG_URL, port: 8101 },
  { name: 'Video Orchestrator', url: getEnv().VPS_ORCHESTRATOR_URL, port: 8103 },
  { name: 'Notes Generator', url: getEnv().VPS_NOTES_URL, port: 8104 },
];

async function testService(service: ServiceTest): Promise<{
  name: string;
  status: 'online' | 'offline' | 'error';
  latency?: number;
  error?: string;
  details?: unknown;
}> {
  const startTime = Date.now();

  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 10000); // 10s timeout

    const response = await fetch(service.url, {
      method: 'GET',
      signal: controller.signal,
    });

    clearTimeout(timeout);
    const latency = Date.now() - startTime;

    if (response.ok) {
      let details: unknown;
      try {
        details = await response.json().catch(() => ({ message: 'No JSON response' }));
      } catch {
        details = { message: 'Service responded but no JSON body' };
      }

      return {
        name: service.name,
        status: 'online',
        latency,
        details,
      };
    }

    return {
      name: service.name,
      status: 'error',
      latency,
      error: `HTTP ${response.status}: ${response.statusText}`,
    };
  } catch (error) {
    const latency = Date.now() - startTime;
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';

    // Check common connection issues
    let friendlyError = errorMessage;
    if (errorMessage.includes('ECONNREFUSED')) {
      friendlyError = `Connection refused - service not running on port ${service.port}`;
    } else if (errorMessage.includes('ETIMEDOUT')) {
      friendlyError = 'Connection timed out - service may be overloaded or unreachable';
    } else if (errorMessage.includes('ENOTFOUND')) {
      friendlyError = 'Host not found - DNS resolution failed';
    }

    return {
      name: service.name,
      status: 'offline',
      latency,
      error: friendlyError,
    };
  }
}

async function runTests(): Promise<void> {
  console.log('='.repeat(60));
  console.log('VPS Services Connection Test');
  console.log('Host: 89.117.60.144');
  console.log('='.repeat(60));
  console.log('');

  const results = await Promise.all(services.map(testService));

  let onlineCount = 0;
  let offlineCount = 0;
  let errorCount = 0;

  for (const result of results) {
    const icon = result.status === 'online' ? '✓' : result.status === 'offline' ? '✗' : '!';
    const color = result.status === 'online' ? 'green' : result.status === 'offline' ? 'red' : 'yellow';

    console.log(`${icon} ${result.name}`);
    console.log(`  URL: ${result.url}`);
    console.log(`  Status: ${result.status.toUpperCase()}`);
    console.log(`  Latency: ${result.latency ? `${result.latency}ms` : 'N/A'}`);

    if (result.error) {
      console.log(`  Error: ${result.error}`);
    } else if (result.details) {
      console.log(`  Details: ${JSON.stringify(result.details, null, 2)}`);
    }

    console.log('');

    if (result.status === 'online') onlineCount++;
    else if (result.status === 'offline') offlineCount++;
    else errorCount++;
  }

  console.log('='.repeat(60));
  console.log('Summary:');
  console.log(`  Online:  ${onlineCount}/${services.length}`);
  console.log(`  Offline: ${offlineCount}/${services.length}`);
  console.log(`  Errors:  ${errorCount}/${services.length}`);
  console.log('='.repeat(60));

  if (offlineCount > 0) {
    console.log('\nTroubleshooting steps:');
    console.log('1. Check if Coolify services are running');
    console.log('2. Verify firewall rules allow connections to required ports');
    console.log('3. Check service logs: docker logs <service-name>');
    console.log('4. Verify IP address 89.117.60.144 is correct');
  }
}

runTests().catch(console.error);
