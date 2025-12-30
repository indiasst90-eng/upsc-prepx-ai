# Technical Assumptions

## Repository Structure

**Monorepo (Turborepo)**

```
upsc-ai-mentor/
├── apps/
│   ├── web/                  # Next.js 14+ frontend (App Router)
│   └── admin/                # Admin dashboard (separate Next.js app)
├── packages/
│   ├── supabase/             # Edge Functions, migrations, RLS policies, types
│   ├── ui/                   # Shared React components (shadcn/ui wrappers)
│   ├── config/               # Shared configs (Tailwind, TypeScript, ESLint)
│   └── utils/                # Shared utilities (validation, formatting)
└── services/
    ├── video-renderer/       # Self-hosted Manim + Revideo service
    ├── rag-engine/           # Document retriever with pgvector
    └── notes-generator/      # Notes synthesis service
```

**Rationale:** Monorepo enables code sharing (UI components, types, utilities) between frontend and admin while maintaining separation. Turborepo provides fast incremental builds and caching.

## Service Architecture

**Hybrid: Serverless Edge Functions + Self-Hosted VPS**

**Serverless (Supabase Edge Functions - Deno Runtime):**
- All user-facing API endpoints (auth, search, CRUD operations)
- Orchestration logic (Pipes/Filters/Actions pattern)
- Webhook handlers (RevenueCat, video render callbacks)
- Scheduled jobs (daily current affairs trigger via pg_cron)

**Self-Hosted VPS (89.117.60.144 - Ubuntu 22.04, 16 vCPU, 64GB RAM):**
- **Video Renderer** (Port 5555): Manim + Revideo render service
- **Video Orchestrator** (Port 8103): Multi-scene assembly coordination
- **RAG Engine** (Port 8101): Document retriever with pgvector queries
- **Notes Generator** (Port 8104): LLM-powered notes synthesis
- **DuckDuckGo Search** (Port 8102): Whitelisted web search proxy

**Rationale:**
- Serverless scales automatically for API traffic, pay-per-use model
- Self-hosted VPS for compute-intensive tasks (video rendering requires GPU/CPU resources unsuitable for serverless)
- Cloudflare Tunnels expose VPS services securely (no public IP exposure)

## Pipes/Filters/Actions Pattern

**Core Backend Architecture (Inspired by Unix Philosophy):**

```typescript
// Example: Doubt-to-Video Feature
USER REQUEST → doubt_video_converter_pipe.ts
    ↓
FILTERS:
  → auth_filter.ts (verify JWT, check entitlements)
  → content_safety_filter.ts (block NSFW/harmful content)
  → ocr_filter.ts (extract text from images if needed)
  → rag_injector_filter.ts (retrieve relevant knowledge chunks)
    ↓
ACTIONS:
  → generate_script_action.ts (LLM synthesis)
  → render_video_action.ts (queue job to VPS)
  → store_result_action.ts (save to Supabase Storage)
    ↓
RESPONSE (immediate job_id + webhook callback when complete)
```

**Every feature follows this pattern:**
- **Pipe**: Orchestrator Edge Function (`pipes/<feature>_pipe.ts`)
- **Filters**: Validation, enrichment, security checks (`filters/<name>_filter.ts`)
- **Actions**: Side effects - DB writes, external API calls, job queue (`actions/<name>_action.ts`)

**Rationale:** Separation of concerns enables testing (mock external calls), reusability (same filter across features), and clarity (each file has single responsibility).

## Testing Requirements

**Full Testing Pyramid**

**Unit Tests (Jest + Vitest):**
- All filters with mocked dependencies
- All actions with mocked external services
- Utility functions (validation, formatting, calculations)
- React components (React Testing Library)
- Target coverage: 80%+ for critical paths

**Integration Tests (Playwright):**
- Each pipe endpoint with real database (Supabase test instance)
- Mock external services (VPS video renderer, LLM APIs)
- Test entitlement logic (trial, free, pro access checks)
- Database operations (CRUD, RLS policies, triggers)

**End-to-End Tests (Playwright):**
- Critical user journeys:
  1. Signup → Trial → Subscribe → Use Premium Feature
  2. Ask Doubt → Receive Video → Give Feedback
  3. Take Test → Get Results → Review Analytics
- Admin flows (upload PDF, monitor jobs, grant entitlements)

**Manual Testing:**
- Video quality review (Manim animations, TTS narration)
- Mobile device testing (iOS Safari, Android Chrome on real devices)
- Accessibility audit (keyboard navigation, screen reader compatibility)

**Rationale:** Full pyramid ensures reliability at all layers. Unit tests fast feedback during development, integration tests validate features, E2E tests prevent regression in user flows.

## Additional Technical Assumptions

### **Database & Storage**

- **Primary Database:** Supabase PostgreSQL 15+ with pgvector extension
- **Vector Embeddings:** OpenAI text-embedding-3-small (1536 dimensions)
- **Indexing:** ivfflat for vector search (100 lists), GIN for full-text search
- **Storage:** Supabase Storage for videos/PDFs, Cloudflare CDN for delivery
- **Caching:** Redis (optional for MVP, required for scale - ElastiCache)

### **Authentication & Security**

- **Auth:** Supabase Auth with JWT tokens, Google OAuth primary
- **Authorization:** Row-Level Security (RLS) policies on all tables
- **API Security:** Rate limiting (100 req/min/user), CORS whitelist, no API keys in client
- **Data Privacy:** GDPR-compliant, user data deletion on request, audit logs for admin actions
- **Payment Security:** RevenueCat handles PCI compliance, no credit cards in our DB

### **Deployment & DevOps**

- **Frontend:** Vercel (auto-deploy from `main` branch, preview deploys for PRs)
- **Backend:** Supabase Cloud (hosted PostgreSQL + Edge Functions + Storage)
- **VPS:** Self-managed Ubuntu 22.04 with Docker containers for each service
- **Monitoring:** Sentry (error tracking), Vercel Analytics (web vitals), Supabase metrics
- **CI/CD:** GitHub Actions (run tests, lint, type-check on every PR)
- **Secrets Management:** Supabase Secrets for Edge Function env vars, Vercel env vars for frontend

### **AI/LLM Providers**

**All AI Models via A4F Unified API:**
- **Base URL:** `https://api.a4f.co/v1`
- **API Key:** `ddc-a4f-12e06ff0184f41de8d3de7be4cd2e831` (one key for all models)

**Model Configuration:**

1. **Primary LLM (Text, Image, Function Calling):**
   - **Model ID:** `provider-3/llama-4-scout`
   - **Use Cases:** Complex queries, answer generation, script writing, code generation

2. **Secondary LLM (Fallback):**
   - **Model ID:** `provider-2/gpt-4.1`
   - **Use Cases:** Activated when primary model errors or unavailable
   - **Fallback Logic:** If primary returns error 3 times consecutively, switch to secondary for 10 minutes

3. **Image Understanding Model:**
   - **Model ID:** `provider-3/gemini-2.5-flash`
   - **Use Cases:** Image-based doubt OCR, screenshot analysis, diagram understanding

4. **Embeddings Model:**
   - **Model ID:** `provider-5/text-embedding-ada-002`
   - **Use Cases:** RAG vector embeddings (1536 dimensions), semantic search

5. **Text-to-Speech (TTS):**
   - **Model ID:** `provider-5/tts-1`
   - **Use Cases:** Video narration, AI interviewer voice

6. **Speech-to-Text (STT):**
   - **Model ID:** `provider-5/whisper-1`
   - **Use Cases:** Voice doubt input, interview audio transcription

7. **Image Generation:**
   - **Model ID:** `provider-4/imagen-4`
   - **Use Cases:** Custom thumbnails, diagram backgrounds, visual assets

**Cost Control:**
- Aggressive prompt caching (70% target hit rate)
- Use primary model (cheaper) for most queries
- Fallback to secondary only on errors
- Monitor per-model costs weekly

### **External Service URLs (VPS - 89.117.60.144)**

**Core Services:**
- **Supabase Studio:** `http://89.117.60.144:3000`
- **Supabase API:** `http://89.117.60.144:8001` ⚠️ CHANGED from 8000
- **Manim Renderer:** `http://89.117.60.144:5000`
- **Revideo Renderer:** `http://89.117.60.144:5001` (Revideo alternative)
- **Coolify Dashboard:** `http://89.117.60.144:8000`

**Additional Services:**
- **Document Retriever (RAG):** `http://89.117.60.144:8101/retrieve`
- **DuckDuckGo Search:** `http://89.117.60.144:8102/search`
- **Video Orchestrator:** `http://89.117.60.144:8103/render`
- **Notes Generator:** `http://89.117.60.144:8104/generate_notes`

**Supabase Credentials (Local Development):**
```bash
# Client API Key (ANON role)
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0

# Service Role Key (Full admin access)
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU

# Supabase URL
SUPABASE_URL=http://89.117.60.144:8001
```

**Example Usage:**
```bash
# Client request (ANON key)
curl 'http://89.117.60.144:8001/rest/v1/users' \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"

# Server request (SERVICE_ROLE key)
curl 'http://89.117.60.144:8001/rest/v1/users' \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"
```

**Critical Security:**
- All VPS URLs called ONLY from Edge Functions (server-side)
- NEVER expose service URLs or API keys to client
- Use ANON key for client requests, SERVICE_ROLE key for admin operations only

### **Performance Optimizations**

- **React Server Components:** Use RSC for initial page loads (faster FCP/LCP)
- **Image Optimization:** Next.js Image component with WebP/AVIF, lazy loading
- **Code Splitting:** Dynamic imports for heavy components (3D syllabus, video player)
- **Bundle Size:** Analyze with `@next/bundle-analyzer`, target <300KB initial JS
- **Database Query Optimization:** Indexed columns, avoid N+1 queries, use connection pooling
- **CDN Strategy:** Cloudflare CDN for video delivery (edge caching), Vercel Edge for static assets

---
