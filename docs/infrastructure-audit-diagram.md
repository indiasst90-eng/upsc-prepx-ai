# VPS Infrastructure Diagram

**Audit Date:** December 23, 2025
**VPS IP:** 89.117.60.144
**Total Services:** 13 (All Operational ✅)

---

## Complete Infrastructure Map

```mermaid
graph TB
    subgraph Internet["🌐 Internet"]
        Client["Client Browser"]
        External["External APIs<br/>(A4F, RevenueCat)"]
    end

    subgraph VPS["🖥️ VPS Server (89.117.60.144)<br/>388GB Total / 372GB Free"]
        subgraph Core["Core Infrastructure"]
            Supabase_Studio["Supabase Studio<br/>:3000<br/>Database Admin UI"]
            Coolify["Coolify Dashboard<br/>:8000<br/>Container Orchestration"]
            Kong["Supabase Kong Gateway<br/>:54321<br/>REST API"]
            Supabase_DB["PostgreSQL 17<br/>with pgvector"]
        end

        subgraph Rendering["Video Rendering Services"]
            Manim["Manim Renderer<br/>:5000<br/>Math Animations"]
            Revideo["Revideo Renderer<br/>:5001<br/>Video Composition"]
        end

        subgraph AI_ML["AI/ML Services"]
            RAG["Document Retriever<br/>:8101<br/>RAG Engine"]
            Search["Search Proxy<br/>:8102<br/>DuckDuckGo"]
            Orchestrator["Video Orchestrator<br/>:8103<br/>Multi-Service Coordinator"]
            Notes["Notes Generator<br/>:8104<br/>AI Notes Synthesis"]
        end

        subgraph Monitoring["Monitoring Stack"]
            Grafana["Grafana<br/>:3001<br/>Dashboards"]
            Prometheus["Prometheus<br/>:9090<br/>Metrics DB"]
            NodeExporter["Node Exporter<br/>:9100<br/>System Metrics"]
            cAdvisor["cAdvisor<br/>:8085<br/>Container Metrics"]
        end
    end

    %% Client Connections
    Client -->|Port 3000| Supabase_Studio
    Client -->|Port 3001| Grafana
    Client -->|Port 8000| Coolify
    Client -->|Port 54321<br/>API Calls| Kong

    %% Kong to Database
    Kong -->|Internal| Supabase_DB

    %% AI/ML Service Interactions
    Orchestrator -->|Render Req| Manim
    Orchestrator -->|Compose Req| Revideo
    Notes -->|Vector Search| RAG
    RAG -->|Query| Supabase_DB
    Search -->|Web Scrape| Internet

    %% External API Calls
    Orchestrator -->|TTS/LLM| External
    Notes -->|LLM| External
    RAG -->|Embeddings| External

    %% Monitoring Flows
    NodeExporter -->|System Metrics| Prometheus
    cAdvisor -->|Container Metrics| Prometheus
    Prometheus -->|Query| Grafana

    %% Styling
    classDef operational fill:#10b981,stroke:#059669,color:#fff
    classDef monitoring fill:#3b82f6,stroke:#2563eb,color:#fff
    classDef rendering fill:#f59e0b,stroke:#d97706,color:#fff
    classDef ai fill:#8b5cf6,stroke:#7c3aed,color:#fff

    class Supabase_Studio,Coolify,Kong,Supabase_DB operational
    class Manim,Revideo rendering
    class RAG,Search,Orchestrator,Notes ai
    class Grafana,Prometheus,NodeExporter,cAdvisor monitoring
```

---

## Service Status Summary

### ✅ Operational (13/13 Services - 100%)

**Core Infrastructure (5 services)**
- Supabase Studio (3000) - 307 Redirect
- Coolify Dashboard (8000) - 302 Redirect
- Supabase Kong Gateway (54321) - 200 OK
- Manim Renderer (5000) - 200 OK
- Revideo Renderer (5001) - 200 OK

**AI/ML Services (4 services)**
- Document Retriever/RAG (8101) - 200 OK
- DuckDuckGo Search Proxy (8102) - 200 OK
- Video Orchestrator (8103) - 200 OK
- Notes Generator (8104) - 200 OK

**Monitoring Stack (4 services)**
- Grafana (3001) - 302 Redirect (Login: admin/admin123)
- Prometheus (9090) - 302 Redirect
- Node Exporter (9100) - 200 OK
- cAdvisor (8085) - 307 Redirect

---

## Network Topology

```
┌─────────────────────────────────────────────────────────────┐
│                     Public Internet                          │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
        ┌───────────────────────────────────┐
        │   VPS: 89.117.60.144              │
        │   Firewall: INACTIVE (Open)       │
        └───────────────────────────────────┘
                        │
        ┌───────────────┴───────────────┐
        │                               │
        ▼                               ▼
   [Docker Bridge Network]      [Host Network]
        │                               │
    19 Containers                  Coolify Proxy
                                   (Traefik :80, :443)
```

---

## Port Allocation Map

| Port Range | Service Type | Count |
|------------|--------------|-------|
| 3000-3001 | Admin UIs (Supabase Studio, Grafana) | 2 |
| 5000-5001 | Rendering Services (Manim, Revideo) | 2 |
| 8000-8104 | Infrastructure + AI/ML | 6 |
| 9090-9100 | Monitoring | 2 |
| 54321 | Supabase API Gateway | 1 |
| **Total** | | **13** |

---

## Resource Utilization

**Disk Space:**
- Total: 388 GB
- Used: 17 GB (4%)
- Available: 372 GB (96%)
- Docker Images: 11.7 GB (97% reclaimable)
- Docker Volumes: 276 MB

**Container Runtime:**
- Total Containers: 20
- Running: 20 (100%)
- Healthy: 19 (95%) - 1 without health check

---

## Key Findings from Audit

### ✅ Strengths
1. **All 13 services operational** (100% uptime during audit)
2. **Comprehensive monitoring stack** (Prometheus + Grafana + exporters)
3. **Adequate disk space** (372GB available, exceeds 100GB requirement)
4. **Modern Supabase stack** (PostgreSQL 17 with pgvector)
5. **Complete AI/ML pipeline** (RAG, orchestration, notes generation)

### ⚠️ Areas for Improvement
1. **No automated backups** (HIGH RISK)
   - No crontab entries found
   - No backup directory configured
   - Database volumes not backed up

2. **Firewall disabled** (MEDIUM RISK)
   - UFW inactive (all ports open)
   - Security relies on application-level auth only

3. **Port discrepancy** (DOCUMENTATION ERROR)
   - Supabase API documented as `:8001`, actually runs on `:54321` (Kong Gateway)
   - All documentation must be updated

4. **No alerting configured** (LOW RISK)
   - Prometheus/Grafana installed but alerts not set up
   - No uptime monitoring (Blackbox Exporter missing)

5. **Log rotation unclear** (LOW RISK)
   - Docker json-file driver in use
   - Rotation policy not explicitly configured

---

## Recommended Next Steps

1. **Implement automated backups** (Story 0.2 candidate)
   - Daily PostgreSQL dumps (both Supabase + Coolify DBs)
   - Weekly Docker volume backups
   - Remote backup storage (S3 or similar)

2. **Configure Grafana dashboards** (Story 0.14 candidate)
   - System resource dashboards
   - Container health dashboards
   - Service-specific metrics (RAG latency, video render times)

3. **Set up Prometheus alerting** (Story 0.14 candidate)
   - Disk space <20GB alert
   - Service downtime alert
   - High error rate alert

4. **Update all documentation** (Task 11, this story)
   - Correct Supabase API port (8001 → 54321)
   - Add monitoring stack endpoints
   - Document Grafana credentials

5. **Enable firewall with rule whitelisting** (Future epic - security hardening)
   - Allow only necessary ports
   - Implement rate limiting at proxy level
