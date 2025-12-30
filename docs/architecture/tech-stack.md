# Tech Stack

**Version:** 1.0
**Last Updated:** December 23, 2025
**Source:** Extracted from `docs/architecture.md` Section 3

---

## Technology Stack Table

| Category | Technology | Version | Purpose | Rationale |
|----------|-----------|---------|---------|-----------|
| **Frontend Language** | TypeScript | 5.3+ | Type-safe JavaScript for frontend | Industry standard, catches 70% of bugs at compile time |
| **Frontend Framework** | Next.js | 14.2+ | React framework with App Router | RSC for optimal performance, built-in routing, SEO-friendly |
| **UI Component Library** | shadcn/ui | Latest | Accessible React components | Copy-paste components, Radix UI primitives (WCAG 2.1 AA) |
| **State Management** | Zustand | 4.5+ | Lightweight global state | 1KB size, simpler than Redux, TypeScript-first |
| **Backend Language** | TypeScript | 5.3+ | Type-safe JavaScript for Edge Functions | Same language as frontend = code sharing |
| **Backend Framework** | Supabase Edge Functions | Latest (Deno 1.40+) | Serverless functions on Deno | Built-in Supabase client, no cold starts (<50ms) |
| **API Style** | REST (Custom Pipes) | N/A | HTTP endpoints following Pipes pattern | Simple, cacheable, stateless, each pipe = one Edge Function |
| **Database** | PostgreSQL | 15+ | Relational database with pgvector | ACID compliance, pgvector for RAG, RLS for security |
| **Cache** | Redis (Optional for MVP) | 7+ | In-memory cache for LLM responses | 70% cache hit rate target, not required for initial launch |
| **File Storage** | Supabase Storage | Latest | Videos, PDFs, images | S3-compatible, built-in CDN, RLS policies |
| **Authentication** | Supabase Auth | Latest | JWT + OAuth providers | Google OAuth primary, httpOnly cookies |
| **Frontend Testing** | Vitest + React Testing Library | Vitest 1.2+, RTL 14+ | Unit tests for components/hooks | Faster than Jest, native ESM |
| **Backend Testing** | Deno Test | Built-in Deno | Unit tests for Edge Functions | Native to Deno runtime, no setup needed |
| **E2E Testing** | Playwright | 1.40+ | End-to-end browser tests | Multi-browser, auto-wait, video recording |
| **Build Tool** | Turborepo | 2.0+ | Monorepo task runner | Incremental builds, remote caching |
| **Bundler** | Next.js (Turbopack) | Built-in Next.js 14+ | Frontend bundler | Zero-config, Rust-based (faster than Webpack) |
| **IaC Tool** | Coolify | Self-hosted | VPS container orchestration | Open-source Vercel alternative for VPS |
| **CI/CD** | GitHub Actions | Latest | Continuous integration | Free for public repos, integrates with Vercel/Supabase |
| **Monitoring** | Sentry | Latest | Error tracking | Real-time error alerts, source maps |
| **Logging** | Supabase Logs + Axiom | Latest | Centralized logging | Supabase logs for Edge Functions, Axiom for VPS |
| **CSS Framework** | Tailwind CSS | 3.4+ | Utility-first CSS | Rapid prototyping, dark mode support |
| **ORM/Query Builder** | Supabase Client | Latest | Type-safe database queries | Auto-generated TypeScript types |
| **Payments** | RevenueCat | Latest | Subscription management | Multi-platform, handles trials, PCI compliant |
| **Video Rendering** | Manim Community + Revideo | Manim CE v0.18+, Revideo Latest | Math animations + video composition | Manim for diagrams, Revideo for timeline assembly |
| **AI Models** | A4F Unified API | N/A | LLM, TTS, STT, embeddings, image gen | 7 models via one API key, cost-effective |
| **Search** | pgvector + DuckDuckGo | pgvector 0.6+, DDG proxy :8102 | Semantic search + web scraping | pgvector for RAG (<500ms), DDG for current affairs |

---

## Platform Configuration

**Selected Platform:**
- **Platform:** Vercel + Supabase Cloud + Self-Hosted VPS
- **Key Services:**
  - **Vercel:** Next.js hosting, Edge Functions, Analytics
  - **Supabase:** PostgreSQL (pgvector), Auth, Storage, Edge Functions (Deno)
  - **VPS (89.117.60.144):** Manim (port 5000), Revideo (5001), Document Retriever (8101), Video Orchestrator (8103), Notes Generator (8104), DuckDuckGo Search (8102), Coolify (8000)
  - **A4F Unified API:** All 7 AI models (LLM, TTS, STT, embeddings, image gen)
- **Deployment Regions:**
  - **Frontend:** Vercel Edge Network (global CDN)
  - **Database:** Supabase Asia-Pacific region (Mumbai for India proximity)
  - **VPS:** Single region (current: 89.117.60.144 location TBD)

**Rationale:**
- Vercel's Next.js optimization delivers <1.5s FCP (PRD requirement)
- Supabase provides PostgreSQL + pgvector for RAG with <500ms queries
- VPS gives full control over Manim/Revideo rendering without serverless timeout limits
- Combined cost: ~₹200/user/month target achievable

---

## External Service Configuration

### A4F Unified API (AI Models)

- **Base URL:** `https://api.a4f.co/v1`
- **API Key:** `ddc-a4f-12e06ff0184f41de8d3de7be4cd2e831`
- **Models:**
  - Primary LLM: `provider-3/llama-4-scout` (text, image, function calling)
  - Fallback LLM: `provider-2/gpt-4.1` (activated on primary errors)
  - Image Model: `provider-3/gemini-2.5-flash` (OCR, image understanding)
  - Embeddings: `provider-5/text-embedding-ada-002` (1536-dim for RAG)
  - TTS: `provider-5/tts-1` (video narration)
  - STT: `provider-5/whisper-1` (voice transcription)
  - Image Gen: `provider-4/imagen-4` (thumbnails, visuals)

### VPS Services (89.117.60.144)

All services run in Docker containers managed by Coolify:

| Service | Port | Purpose |
|---------|------|---------|
| Supabase Studio | 3000 | Database management UI |
| Supabase API | 8001 | PostgreSQL REST API |
| Manim Renderer | 5000 | Mathematical animations |
| Revideo Renderer | 5001 | Video composition |
| Coolify Dashboard | 8000 | Deployment management |
| Document Retriever | 8101 | RAG Engine |
| DuckDuckGo Search | 8102 | Web scraping proxy |
| Video Orchestrator | 8103 | Video workflow coordination |
| Notes Generator | 8104 | AI-powered note synthesis |

---

## Architectural Patterns

- **Jamstack Architecture:** Static-first with serverless APIs - _Rationale:_ Next.js App Router with RSC provides optimal FCP (<1.5s)
- **Pipes/Filters/Actions Pattern:** Request orchestration through Edge Functions - _Rationale:_ Specified in PRD, enables testability and reusability
- **Hybrid Compute Model:** Serverless + dedicated servers - _Rationale:_ Cost-optimized workload distribution
- **Domain-Driven Design (Lite):** Organize by business domains - _Rationale:_ Simplifies Epic → Code mapping
- **Repository Pattern:** Abstract data access - _Rationale:_ Testing and migration flexibility
- **Backend-for-Frontend (BFF):** Edge Functions as API gateway - _Rationale:_ Context-specific endpoints reduce over-fetching
- **Event-Driven Async Processing:** Job queue for long-running tasks - _Rationale:_ Prevents timeout errors, improves UX

---

## Key Technology Decisions

### Why Next.js 14 App Router?
- React Server Components for optimal FCP (<1.5s target)
- Built-in routing and file-based structure
- SEO-friendly for marketing pages
- Vercel deployment optimization

### Why Supabase?
- PostgreSQL with pgvector extension (RAG native)
- Built-in Auth with JWT + OAuth
- Row-Level Security (RLS) for access control
- Edge Functions on Deno (fast cold starts)
- Storage with CDN integration

### Why Self-Hosted VPS?
- Video rendering requires GPU/CPU intensive compute
- Manim and Revideo need long-running processes (>10 minutes)
- Serverless timeout limits (typically 10-60s) insufficient
- Cost optimization: dedicated server cheaper than serverless for heavy compute

### Why Turborepo Monorepo?
- Share code between web/admin apps
- Shared UI components (`packages/ui`)
- Type-safe API contracts
- Incremental builds with caching
- Single deployment pipeline

### Why TypeScript Full-Stack?
- End-to-end type safety (frontend + Edge Functions)
- Catch 70% of bugs at compile time
- Better IDE support and refactoring
- Shared types between client/server
