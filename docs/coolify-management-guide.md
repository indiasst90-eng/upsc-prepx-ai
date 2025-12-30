# Coolify Dashboard Management Guide

## Overview

Coolify is the container orchestration platform managing all VPS services on `89.117.60.144:8000`.

## Access

- **URL:** http://89.117.60.144:8000
- **Credentials:** Contact infrastructure team

## Services Managed

| Service | Port | Container | Status |
|---------|------|-----------|--------|
| Supabase Studio | 3000 | supabase-studio | Running |
| Kong Gateway | 54321 | supabase-kong | Running |
| Supabase DB | 5432 | supabase-db | Running |
| Supabase Storage | 5000 | supabase-storage | Running |
| Manim Renderer | 5000 | manim-api | Running |
| Revideo Renderer | 5001 | revideo-api | Running |
| RAG Engine | 8101 | rag-engine | Running |
| Search Proxy | 8102 | search-proxy | Running |
| Video Orchestrator | 8103 | orchestrator-api | Running |
| Notes Generator | 8104 | notes-api | Running |
| Coolify Dashboard | 8000 | coolify | Running |
| Grafana | 3001 | grafana | Running |
| Prometheus | 9090 | prometheus | Running |

## Common Operations

### Restarting a Service

1. Navigate to Services → [Service Name]
2. Click "Restart" button
3. Monitor logs for errors

### Viewing Logs

1. Click on service
2. Navigate to "Logs" tab
3. Use filters: ERROR, WARN, INFO

### Environment Variables

1. Go to service configuration
2. View/edit Environment Variables
3. Values are masked for security
4. Restart service after changes

### Deployment

1. Build new Docker image
2. Push to registry
3. Update service configuration
4. Deploy with zero-downtime option

## Troubleshooting

### Service Won't Start

1. Check logs for errors
2. Verify environment variables
3. Check disk space: `df -h`
4. Check memory: `free -m`

### High Resource Usage

1. Navigate to Monitoring tab
2. Identify resource-heavy services
3. Consider scaling or optimization
