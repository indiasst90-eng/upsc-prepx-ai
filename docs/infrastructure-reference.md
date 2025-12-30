# UPSC AI Mentor - Infrastructure Reference

**Updated:** December 23, 2025 (Infrastructure Audit Completed)
**VPS IP:** 89.117.60.144
**Total Services:** 13 (All Operational ✅)

---

## ✅ Infrastructure Audit Results (December 23, 2025)

**Audit Status:** COMPLETE
**Services Validated:** 13/13 (100%)
**Disk Space:** 372GB available (96% free)
**Critical Issues:** 1 (No automated backups)
**Documentation Errors Fixed:** 1 (Supabase API port corrected)

**See full audit:** [`docs/infrastructure-audit-diagram.md`](./infrastructure-audit-diagram.md)

---

## Service Endpoints

### Core Infrastructure (5 Services)

| Service | URL | Port | Status | Purpose |
|---------|-----|------|--------|---------|
| **Supabase Studio** | http://89.117.60.144:3000 | 3000 | ✅ 307 | Database management UI |
| **Supabase API (Kong)** | http://89.117.60.144:54321 | 54321 | ✅ 200 | PostgreSQL REST API ⚠️ **CORRECTED: Was documented as :8001** |
| **Manim Renderer** | http://89.117.60.144:5000 | 5000 | ✅ 200 | Mathematical animation rendering |
| **Revideo Renderer** | http://89.117.60.144:5001 | 5001 | ✅ 200 | Video composition (Remotion alternative) |
| **Coolify** | http://89.117.60.144:8000 | 8000 | ✅ 302 | Deployment & container management |

### AI/ML Services (4 Services)

| Service | URL | Port | Status | Purpose |
|---------|-----|------|--------|---------|
| **RAG Document Retriever** | http://89.117.60.144:8101/retrieve | 8101 | ✅ 200 | Vector search over knowledge base |
| **DuckDuckGo Search** | http://89.117.60.144:8102/search | 8102 | ✅ 200 | Web search proxy |
| **DuckDuckGo UPSC Search** | http://89.117.60.144:8102/search/upsc | 8102 | ✅ 200 | Filtered UPSC sources only |
| **Video Orchestrator** | http://89.117.60.144:8103/render | 8103 | ✅ 200 | Multi-scene video assembly |
| **Notes Generator** | http://89.117.60.144:8104/generate_notes | 8104 | ✅ 200 | LLM-powered notes synthesis |

### Monitoring Stack (4 Services)

| Service | URL | Port | Status | Purpose |
|---------|-----|------|--------|---------|
| **Grafana** | http://89.117.60.144:3001 | 3001 | ✅ 302 | Visualization dashboards (Login: admin/admin123) |
| **Prometheus** | http://89.117.60.144:9090 | 9090 | ✅ 302 | Metrics collection & time-series DB |
| **Node Exporter** | http://89.117.60.144:9100 | 9100 | ✅ 200 | System metrics (CPU, RAM, disk) |
| **cAdvisor** | http://89.117.60.144:8085 | 8085 | ✅ 307 | Docker container metrics |

---

## AI Model Configuration (A4F Unified API)

**Provider:** A4F (All-in-One API for multiple AI providers)
**Base URL:** `https://api.a4f.co/v1`
**API Key:** `ddc-a4f-12e06ff0184f41de8d3de7be4cd2e831`

### Model Inventory

| Model Type | Model ID | Provider | Use Cases |
|------------|----------|----------|-----------|
| **Primary LLM** | `provider-3/llama-4-scout` | Llama 4 | Text generation, function calling, image understanding |
| **Fallback LLM** | `provider-2/gpt-4.1` | OpenAI | Activated on primary errors (3 consecutive failures) |
| **Image Understanding** | `provider-3/gemini-2.5-flash` | Google | OCR, screenshot analysis, diagram parsing |
| **Embeddings** | `provider-5/text-embedding-ada-002` | OpenAI | RAG vector search (1536 dimensions) |
| **Text-to-Speech** | `provider-5/tts-1` | OpenAI | Video narration, AI interviewer voice |
| **Speech-to-Text** | `provider-5/whisper-1` | OpenAI | Voice doubt transcription |
| **Image Generation** | `provider-4/imagen-4` | Google | Thumbnails, visual assets |

### Fallback Strategy

**Automatic Model Switching:**
```javascript
// Pseudo-code for LLM fallback
if (primaryModel.consecutiveErrors >= 3) {
  switchToModel(FALLBACK_LLM);
  setTimeout(() => resetToPrimary(), 10 * 60 * 1000); // 10 minutes
}
```

**Fallback Scenarios:**
- Primary LLM errors → Secondary LLM (GPT-4.1)
- TTS fails → Fallback to text-only response
- Manim rendering fails → Proceed with text/static images
- Image Gen fails → Use placeholder thumbnails

---

## Supabase Authentication

### API Keys

**Client-Side (ANON Role):**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0
```

**Server-Side (SERVICE_ROLE - Full Admin):**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU
```

### Example Requests

**Client Request (Browser/Frontend):**
```bash
curl 'http://89.117.60.144:54321/rest/v1/users' \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
```

**Server Request (Edge Functions):**
```bash
curl 'http://89.117.60.144:54321/rest/v1/users' \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"
```

---

## Security Rules

### CRITICAL: Server-Side Only

**✅ ALLOWED (Edge Functions only):**
- Call VPS services (Manim, Revideo, RAG, Notes Generator)
- Use SERVICE_ROLE key for admin operations
- Access A4F API with API key

**❌ FORBIDDEN (Never in client/frontend):**
- Expose VPS service URLs in JavaScript bundles
- Include SERVICE_ROLE key in client code
- Call VPS services directly from browser
- Hardcode A4F API key in frontend

### Row-Level Security (RLS)

**All tables MUST have RLS enabled:**
- Users can only access their own data
- Admins can access all data (role check)
- Public read for syllabus_nodes, knowledge_chunks (read-only)

---

## API Request Patterns

### A4F Model Request Template

**Text Generation (Primary LLM):**
```bash
curl https://api.a4f.co/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ddc-a4f-12e06ff0184f41de8d3de7be4cd2e831" \
  -d '{
    "model": "provider-3/llama-4-scout",
    "messages": [{"role": "user", "content": "Explain Article 21"}],
    "max_tokens": 500
  }'
```

**Embeddings (for RAG):**
```bash
curl https://api.a4f.co/v1/embeddings \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ddc-a4f-12e06ff0184f41de8d3de7be4cd2e831" \
  -d '{
    "model": "provider-5/text-embedding-ada-002",
    "input": "Fundamental Rights in Indian Constitution"
  }'
```

**Text-to-Speech:**
```bash
curl https://api.a4f.co/v1/audio/speech \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ddc-a4f-12e06ff0184f41de8d3de7be4cd2e831" \
  -d '{
    "model": "provider-5/tts-1",
    "input": "Welcome to UPSC AI Mentor",
    "voice": "alloy"
  }' \
  --output speech.mp3
```

**Speech-to-Text:**
```bash
curl https://api.a4f.co/v1/audio/transcriptions \
  -H "Authorization: Bearer ddc-a4f-12e06ff0184f41de8d3de7be4cd2e831" \
  -F "file=@audio.mp3" \
  -F "model=provider-5/whisper-1"
```

**Image Understanding:**
```bash
curl https://api.a4f.co/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ddc-a4f-12e06ff0184f41de8d3de7be4cd2e831" \
  -d '{
    "model": "provider-3/gemini-2.5-flash",
    "messages": [{
      "role": "user",
      "content": [
        {"type": "text", "text": "What UPSC topic is in this image?"},
        {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64,..."}}
      ]
    }]
  }'
```

---

## VPS Service Request Patterns

### RAG Document Retriever

**Endpoint:** `GET http://89.117.60.144:8101/retrieve`

**Query Parameters:**
- `query` (string): Natural language search query
- `top_k` (number): Number of results (default: 10)
- `filters` (JSON): Subject, paper, source filters

**Response:**
```json
{
  "results": [
    {
      "content": "Text chunk from knowledge base...",
      "score": 0.92,
      "metadata": {
        "source_file": "Laxmikanth_Polity.pdf",
        "page": 45,
        "topic": "fundamental-rights",
        "chapter": "Part III"
      }
    }
  ]
}
```

### Manim Renderer

**Endpoint:** `POST http://89.117.60.144:5000/render`

**Request Body:**
```json
{
  "renderer": "manim",
  "scene_config": {
    "scene_class": "TimelineScene",
    "scene_args": {
      "events": [
        {"date": "1950", "text": "Constitution adopted"},
        {"date": "1976", "text": "42nd Amendment"}
      ],
      "style": "dark",
      "animation_speed": "normal"
    }
  },
  "output_format": "mp4",
  "quality": "high",
  "transparent_background": false
}
```

**Response:**
```json
{
  "status": "rendering",
  "job_id": "uuid-here",
  "estimated_time": 45,
  "preview_url": "http://.../preview.jpg"
}
```

### Revideo Renderer

**Endpoint:** `POST http://89.117.60.144:5001/render`

**Request Body:**
```json
{
  "renderer": "revideo",
  "composition_id": "ExplainerCard",
  "input_props": {
    "title": "Fundamental Rights",
    "bullet_points": ["Right to Equality", "Right to Freedom"],
    "voiceover_url": "https://..."
  },
  "codec": "h264",
  "duration_frames": 900,
  "fps": 30
}
```

---

## Environment Variable Priorities

### Required for MVP (Cannot Run Without):
1. ✅ `SUPABASE_URL`
2. ✅ `SUPABASE_ANON_KEY`
3. ✅ `SUPABASE_SERVICE_ROLE_KEY`
4. ✅ `A4F_API_KEY`
5. ✅ `MANIM_API_URL`
6. ✅ `REVIDEO_API_URL`
7. ✅ `RAG_DOCUMENT_RETRIEVER_URL`
8. ✅ `RAZORPAY_KEY_ID` (for payments)

### Optional (Can Defer):
- Redis (caching - improves performance but not required for MVP)
- Social media tokens (Feature 35 - admin tool, not MVP)
- External CDN (Supabase Storage sufficient for MVP)
- Sentry (monitoring - nice-to-have but not blocking)

---

## Cost Estimates (Based on A4F Pricing)

**Per-User Monthly Cost Breakdown:**

| Component | Monthly Usage (Est.) | Cost/User | Notes |
|-----------|---------------------|-----------|-------|
| **Primary LLM** (Llama-4-Scout) | 500K tokens | ₹50 | Doubt answers, scripts |
| **Embeddings** (Ada-002) | 100K tokens | ₹10 | RAG search queries |
| **TTS** (provider-5/tts-1) | 20K characters | ₹30 | Video narration |
| **STT** (Whisper) | 2 hours audio | ₹10 | Voice doubts |
| **Image Understanding** (Gemini-2.5-Flash) | 50 images | ₹20 | Screenshot OCR |
| **Image Generation** (Imagen-4) | 10 images | ₹15 | Thumbnails |
| **Video Rendering** (Manim+Revideo) | 20 videos | ₹50 | Compute cost |
| **Infrastructure** (Supabase, Storage) | - | ₹15 | Database, CDN |
| **TOTAL** | - | **₹200** | Target max per user |

**Optimization Strategies:**
- 70% cache hit rate reduces LLM cost to ₹15/user
- Pre-render common topics reduces Manim cost to ₹30/user
- Use cheaper primary model (Llama-4) instead of GPT-4 saves 60%

---

## Whitelisted Current Affairs Sources

**ONLY these domains allowed for daily updates:**

1. visionias.in (Value Added Material)
2. drishtiias.com (Daily Editorials, Monthly Compilations)
3. thehindu.com (Editorial Analysis)
4. pib.gov.in (Government Press Releases)
5. forumias.com (Fact Sheets)
6. insightsonindia.com (Daily Compilations)
7. iasbaba.com (Current Affairs Analysis)
8. iasscore.in (Contemporary Issues)
9. nextias.com (Yojana & Kurukshetra Magazine Summaries)
10. *.gov.in (All government official sites)

**Forbidden Sources:**
- Social media (Twitter, Facebook, Reddit)
- Blogs and opinion sites (unless established UPSC educators)
- Wikipedia (can reference for context, not primary source)
- News aggregators without original reporting

---

## Quick Setup Guide

### 1. Environment Setup

```bash
# Copy template
cp docs/.env.example .env.local

# Verify Supabase connection
curl http://89.117.60.144:54321/rest/v1/ \
  -H "apikey: YOUR_ANON_KEY"

# Should return OpenAPI spec (HTTP 200)
```

### 2. Test VPS Services

```bash
# Test Manim renderer
curl -X POST http://89.117.60.144:5000/health
# Expected: {"status": "ok", "renderer": "manim"}

# Test RAG retriever
curl "http://89.117.60.144:8101/retrieve?query=fundamental+rights&top_k=5"
# Expected: {"results": [...]}

# Test Notes Generator
curl -X POST http://89.117.60.144:8104/generate_notes \
  -H "Content-Type: application/json" \
  -d '{"topic": "Article 21", "levels": ["summary"]}'
# Expected: {"notes": {...}}
```

### 3. Test A4F API

```bash
# Test embeddings
curl https://api.a4f.co/v1/embeddings \
  -H "Authorization: Bearer ddc-a4f-12e06ff0184f41de8d3de7be4cd2e831" \
  -H "Content-Type: application/json" \
  -d '{"model": "provider-5/text-embedding-ada-002", "input": "test"}'

# Expected: {"object": "list", "data": [{"embedding": [...]}]}
```

---

## Troubleshooting

### Common Issues

**Issue:** "Connection refused to Supabase API"
- **Fix:** Use port **54321** (Kong Gateway), not 8001 or 8000
- **Verify:** `curl http://89.117.60.144:54321/rest/v1/` -H "apikey: ANON_KEY"

**Issue:** "A4F API returns 401 Unauthorized"
- **Fix:** Check API key is correct: `ddc-a4f-12e06ff0184f41de8d3de7be4cd2e831`
- **Verify:** Check Authorization header format: `Bearer <key>`

**Issue:** "Manim rendering times out"
- **Fix:** Check Manim service is running: `curl http://89.117.60.144:5000/health`
- **Increase:** Timeout to 300 seconds for complex scenes

**Issue:** "RAG returns empty results"
- **Fix:** Ensure knowledge base is populated (check `knowledge_chunks` table has data)
- **Verify:** `SELECT COUNT(*) FROM knowledge_chunks;` should return >100

---

## Monitoring Checklist

**Daily Health Checks:**
- [ ] Supabase API responding (port 54321)
- [ ] Manim renderer active (port 5000)
- [ ] Revideo renderer active (port 5001)
- [ ] RAG service returning results (port 8101)
- [ ] Monitoring stack operational (Grafana 3001, Prometheus 9090)
- [ ] A4F API quota not exceeded
- [ ] Daily CA video published by 6 AM IST

**Weekly Reviews:**
- [ ] AI cost per user <₹200/month
- [ ] Cache hit rate ≥70%
- [ ] Video render success rate ≥95%
- [ ] Content accuracy <1% error rate
- [ ] Trial-to-paid conversion ≥15%

---

**Document Version:** 2.0 (Post-Audit)
**Last Updated:** December 23, 2025
**Audit Completed:** December 23, 2025 (Story 0.1)
**Maintained By:** PM Agent + DevOps Team

---

## Backup & Disaster Recovery

⚠️ **CRITICAL FINDING (December 23, 2025 Audit):**

**No automated backups currently configured.**

### Recommended Backup Strategy (To Be Implemented)

**Daily Backups:**
- PostgreSQL databases (Supabase + Coolify)
- Docker volumes (knowledge embeddings, uploaded PDFs)
- Configuration files (.env, docker-compose.yml)

**Weekly Backups:**
- Full system snapshot (VPS image)
- Docker images (custom services)

**Retention Policy:**
- Daily: Keep 7 days
- Weekly: Keep 4 weeks
- Monthly: Keep 12 months

**Storage Location:**
- Primary: VPS local storage (100GB allocated)
- Secondary: Cloud backup (S3 or equivalent)

**Recovery SLA:**
- Database: <15 minutes RTO, <1 hour RPO
- Full system: <2 hours RTO, <24 hours RPO

**Implementation Priority:** HIGH (Story 0.2 candidate)
