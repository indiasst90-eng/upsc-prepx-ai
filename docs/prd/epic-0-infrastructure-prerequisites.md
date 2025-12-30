# Epic 0: Infrastructure Prerequisites & VPS Validation

**Epic Goal:**
Establish and validate all infrastructure prerequisites before feature development begins. By the end of this epic, all VPS services shall be operational and tested, development environments shall be fully configured, external service integrations shall be validated, and the team shall have a stable foundation for implementing Epic 1. This epic ensures zero blockers during feature development by front-loading all environment setup, service validation, and integration testing.

**Priority:** CRITICAL - Must complete before Epic 1
**Estimated Duration:** 3-5 days
**Dependencies:** None (this is the foundation)

---

## Story 0.1: VPS Infrastructure Audit & Documentation

**As a** DevOps engineer,
**I want** to audit and document the current VPS infrastructure configuration,
**so that** the team has accurate information about available services, ports, and authentication methods.

### Acceptance Criteria

1. VPS access verified: SSH connection to 89.117.60.144 successful with provided credentials
2. All services cataloged: document running Docker containers, ports, service versions
3. Service health check: verify each service responds to test requests (ports 3000, 5000, 5001, 8000, 8001, 8101-8104)
4. Disk space audit: verify >100GB free space for video storage and database
5. Network configuration documented: firewall rules, open ports, Coolify tunnel setup
6. Supabase connection verified: test connection from local machine to `http://89.117.60.144:8001`
7. Service authentication documented: API keys, tokens, or authentication methods for each service
8. Backup strategy documented: current backup schedule (if any), recovery procedures
9. Monitoring setup documented: existing logging, alerting, or monitoring tools
10. Infrastructure diagram created: visual map of services, ports, dependencies

**Risk Level:** HIGH (if VPS is misconfigured, entire project blocked)

---

## Story 0.2: Supabase Local Development Setup

**As a** developer,
**I want** a fully configured local Supabase connection,
**so that** I can develop and test database operations without affecting production.

### Acceptance Criteria

1. Supabase CLI installed: `supabase --version` returns valid version
2. Local `.env.local` created with VPS Supabase credentials:
   - `SUPABASE_URL=http://89.117.60.144:8001`
   - `SUPABASE_ANON_KEY=[from documentation]`
   - `SUPABASE_SERVICE_ROLE_KEY=[from documentation]`
3. Connection test: simple query executes successfully using Supabase client library
4. Authentication test: test user signup/login flow using Supabase Auth
5. Database test: create test table, insert record, query record, delete record
6. RLS test: verify Row-Level Security policies work as expected
7. Storage test: upload test file to Supabase Storage, retrieve file, delete file
8. Edge Function test: deploy and invoke simple "Hello World" Edge Function
9. Real-time test: subscribe to database changes, verify events received
10. Documentation updated: troubleshooting guide for common connection issues

**Dependencies:** Story 0.1 completed
**Risk Level:** HIGH (blocks all database and auth work)

---

## Story 0.3: A4F Unified API Integration & Testing

**As a** developer,
**I want** the A4F Unified API fully configured and tested,
**so that** I can use all 7 AI models without authentication or quota issues.

### Acceptance Criteria

1. API key verified: `ddc-a4f-12e06ff0184f41de8d3de7be4cd2e831` works with base URL `https://api.a4f.co/v1`
2. **Primary LLM test** (`provider-3/llama-4-scout`):
   - Send test prompt: "Explain UPSC syllabus structure"
   - Response received in <5s with valid JSON
3. **Secondary LLM test** (`provider-2/gpt-4.1`):
   - Verify fallback mechanism works when primary errors
   - Test with intentional error trigger
4. **Image model test** (`provider-3/gemini-2.5-flash`):
   - Upload test image with text
   - Verify OCR extraction accuracy
5. **Embeddings test** (`provider-5/text-embedding-ada-002`):
   - Generate embeddings for sample text
   - Verify 1536-dimension vector returned
6. **TTS test** (`provider-5/tts-1`):
   - Generate audio for sample text
   - Verify MP3/WAV output quality
7. **STT test** (`provider-5/whisper-1`):
   - Transcribe sample audio file
   - Verify transcription accuracy
8. **Image generation test** (`provider-4/imagen-4`):
   - Generate test thumbnail with prompt
   - Verify image quality and format
9. Rate limiting tested: verify 100 req/min limit handling
10. Cost monitoring setup: log token usage for all requests

**Dependencies:** None (external API)
**Risk Level:** CRITICAL (blocks all AI features)

---

## Story 0.4: VPS Service Integration - Document Retriever (RAG Engine)

**As a** developer,
**I want** the Document Retriever service (port 8101) tested and integrated,
**so that** I can use RAG-based knowledge retrieval in features.

### Acceptance Criteria

1. Service endpoint verified: `http://89.117.60.144:8101/retrieve` responds to GET /health
2. Test document upload: upload sample PDF via API
3. Retrieval test: query uploaded document with test question
4. Response format validated: JSON with fields `{ chunks: [], confidence: float, sources: [] }`
5. Latency test: 10 test queries complete in <500ms P95
6. Error handling test: test with invalid queries, verify graceful errors
7. Concurrent load test: 50 simultaneous requests handled successfully
8. Integration with Supabase: verify service can read from `knowledge_chunks` table
9. Authentication test: verify service requires valid API key or token
10. Edge Function wrapper created: `rag_search_filter.ts` calls Document Retriever service

**Dependencies:** Story 0.1, 0.2 completed
**Risk Level:** HIGH (blocks all RAG features)

---

## Story 0.5: VPS Service Integration - Manim Renderer

**As a** developer,
**I want** the Manim Renderer service (port 5000) tested and integrated,
**so that** I can generate mathematical animations for videos.

### Acceptance Criteria

1. Service endpoint verified: `http://89.117.60.144:5000` responds to GET /health
2. Simple scene test: render basic "Hello Manim" animation scene
3. Complex scene test: render graph with axes, equations, transformations
4. Scene spec format documented: JSON structure for scene definitions
5. Render latency test: simple scenes complete in 2-6s, complex scenes in 10-30s
6. Output format verified: MP4 video with transparent background option
7. Error handling test: invalid scene specs return clear error messages
8. Queue test: multiple render requests queued properly (no blocking)
9. Disk space monitoring: verify rendered files cleaned up after processing
10. Edge Function wrapper created: `render_manim_action.ts` calls Manim service

**Dependencies:** Story 0.1 completed
**Risk Level:** HIGH (blocks all video features with diagrams)

---

## Story 0.6: VPS Service Integration - Revideo Renderer

**As a** developer,
**I want** the Revideo Renderer service (port 5001) tested and integrated,
**so that** I can compose final videos with TTS, scenes, and transitions.

### Acceptance Criteria

1. Service endpoint verified: `http://89.117.60.144:5001` responds to GET /health
2. Simple composition test: combine 2 video clips with fade transition
3. TTS integration test: render video with A4F TTS audio narration
4. Manim integration test: compose video using Manim scene output + TTS
5. Timeline spec format documented: JSON structure for video composition
6. Render latency test: 60s video completes in <60s, 180s video in <120s
7. Output quality verified: 1080p MP4, 30fps, H.264 codec
8. Multiple aspect ratios tested: 16:9, 9:16, 1:1 all render correctly
9. Error handling test: missing assets return clear error messages
10. Edge Function wrapper created: `render_video_action.ts` calls Revideo service

**Dependencies:** Story 0.1, 0.5 completed
**Risk Level:** CRITICAL (blocks all video generation features)

---

## Story 0.7: VPS Service Integration - DuckDuckGo Search Proxy

**As a** developer,
**I want** the DuckDuckGo Search service (port 8102) tested and integrated,
**so that** I can fetch current affairs from whitelisted sources.

### Acceptance Criteria

1. Service endpoint verified: `http://89.117.60.144:8102/search` responds to GET /health
2. Search test: query "UPSC current affairs" returns results
3. Whitelisting verified: only results from approved domains returned (visionias.in, drishtiias.com, etc.)
4. Response format validated: JSON with fields `{ results: [], metadata: {} }`
5. Pagination tested: retrieve multiple pages of results
6. Rate limiting tested: verify service respects search engine limits
7. Error handling test: network failures handled gracefully with retries
8. Date filtering test: filter results by date range (last 7 days, last 30 days)
9. Deduplication test: verify duplicate URLs are filtered
10. Edge Function wrapper created: `fetch_current_affairs_action.ts` calls search service

**Dependencies:** Story 0.1 completed
**Risk Level:** MEDIUM (only blocks current affairs features)

---

## Story 0.8: VPS Service Integration - Video Orchestrator

**As a** developer,
**I want** the Video Orchestrator service (port 8103) tested and integrated,
**so that** I can coordinate multi-step video generation workflows.

### Acceptance Criteria

1. Service endpoint verified: `http://89.117.60.144:8103/render` responds to GET /health
2. Job submission test: submit video job, receive job_id
3. Job status polling test: check job status via GET /jobs/{job_id}
4. Callback webhook test: verify service calls webhook on completion
5. Multi-scene workflow test: orchestrate Manim render → TTS → Revideo composition
6. Error recovery test: failed steps retry with exponential backoff
7. Job queue management: verify FIFO processing, priority queue support
8. Concurrent job limit: verify max 10 jobs processed simultaneously
9. Job timeout handling: long-running jobs timeout after 10 minutes
10. Edge Function wrapper created: `video_orchestrator_pipe.ts` submits jobs

**Dependencies:** Story 0.5, 0.6 completed
**Risk Level:** HIGH (blocks all automated video workflows)

---

## Story 0.9: VPS Service Integration - Notes Generator

**As a** developer,
**I want** the Notes Generator service (port 8104) tested and integrated,
**so that** I can synthesize comprehensive notes from source material.

### Acceptance Criteria

1. Service endpoint verified: `http://89.117.60.144:8104/generate_notes` responds to GET /health
2. Note generation test: provide topic, receive summary/detailed/comprehensive notes
3. RAG integration test: verify service uses Document Retriever for grounding
4. Output format validated: JSON with `{ summary: string, detailed: string, comprehensive: string }`
5. Syllabus mapping test: notes automatically tagged with relevant syllabus nodes
6. Latency test: notes generation completes in <30s for typical topic
7. Error handling test: insufficient source material returns clear error
8. Batch processing test: generate notes for multiple topics in queue
9. Citation tracking: verify notes include source references
10. Edge Function wrapper created: `generate_notes_action.ts` calls Notes Generator

**Dependencies:** Story 0.1, 0.4 completed
**Risk Level:** MEDIUM (blocks notes generation features)

---

## Story 0.10: Coolify Dashboard Access & Configuration

**As a** DevOps engineer,
**I want** full access to Coolify dashboard (port 8000) and deployment workflows,
**so that** I can manage containerized services and deployments.

### Acceptance Criteria

1. Coolify dashboard accessible: `http://89.117.60.144:8000` loads successfully
2. Authentication verified: admin credentials work for login
3. All services visible: 8 services shown in dashboard (Supabase, Manim, Revideo, etc.)
4. Service logs accessible: view logs for each running service
5. Service restart tested: restart single service without affecting others
6. Resource monitoring: view CPU, RAM, disk usage per service
7. Deployment workflow documented: how to deploy new service versions
8. Environment variables management: verify secure storage and injection
9. Backup/restore tested: create service backup, test restore process
10. Team access configured: add additional team members with appropriate roles

**Dependencies:** Story 0.1 completed
**Risk Level:** MEDIUM (blocks deployment management)

---

## Story 0.11: Local Development Environment - Full Stack Setup

**As a** developer,
**I want** a complete local development environment with all tools and dependencies,
**so that** I can develop features without manual setup steps.

### Acceptance Criteria

1. Node.js 20+ installed and verified: `node -v` returns 20.x.x
2. pnpm installed: `pnpm -v` returns latest version
3. Turborepo installed: `turbo -v` returns latest version
4. Next.js project initialized: `npx create-turbo@latest` creates monorepo structure
5. Directory structure created: `apps/web`, `apps/admin`, `packages/supabase`, `packages/ui`, etc.
6. TypeScript configured: `tsconfig.json` in all packages
7. Tailwind CSS configured: `tailwind.config.ts` with custom theme
8. ESLint + Prettier configured: `npm run lint` passes, code auto-formats
9. Supabase client package created: `@upsc-ai/supabase` with types and utilities
10. Development server runs: `pnpm dev` starts all apps successfully

**Dependencies:** None (local setup)
**Risk Level:** HIGH (blocks all frontend development)

---

## Story 0.12: Git Repository & CI/CD Pipeline Setup

**As a** developer,
**I want** a Git repository with automated CI/CD pipeline,
**so that** code changes are tested and validated automatically.

### Acceptance Criteria

1. GitHub repository created: `upsc-ai-mentor` repo initialized
2. Branch protection rules: `main` requires PR approval, passing CI
3. `.gitignore` configured: exclude `node_modules`, `.env.local`, `dist`, etc.
4. GitHub Actions workflow created: `.github/workflows/ci.yml`
5. CI pipeline stages: lint → type-check → test → build
6. Lint stage: run ESLint on all packages
7. Type-check stage: run `tsc --noEmit` in all packages
8. Test stage: run Jest/Vitest unit tests with coverage report
9. Build stage: build Next.js apps with `turbo build`
10. Status badges added: CI status badge in README.md

**Dependencies:** Story 0.11 completed
**Risk Level:** MEDIUM (delays code quality enforcement)

---

## Story 0.13: Environment Variables & Secrets Management

**As a** developer,
**I want** secure environment variable management across local and production,
**so that** API keys and secrets are never exposed in code.

### Acceptance Criteria

1. `.env.example` template created with all required variables (30+ variables)
2. Local `.env.local` file created (git-ignored) with actual values
3. Supabase Secrets configured: all Edge Function secrets added via Supabase dashboard
4. Vercel environment variables: all frontend secrets added to Vercel project
5. Environment validation: startup script checks for missing required variables
6. Type-safe env access: `@upsc-ai/config` package provides typed env object
7. Separate environments: `development`, `staging`, `production` configs
8. Secret rotation documented: procedures for updating API keys
9. No secrets in code: ESLint rule blocks hardcoded secrets
10. Documentation updated: `docs/infrastructure-reference.md` lists all required env vars

**Dependencies:** Story 0.11 completed
**Risk Level:** CRITICAL (security risk if misconfigured)

---

## Story 0.14: Integration Testing Framework Setup

**As a** QA engineer,
**I want** an integration testing framework with VPS service mocks,
**so that** I can test features end-to-end without manual service calls.

### Acceptance Criteria

1. Playwright installed and configured: `npx playwright install`
2. Test environment setup: Supabase test database created
3. Service mocks created: Mock servers for all VPS services (8101-8104, 5000, 5001)
4. Mock data seeded: Test users, syllabus nodes, sample PDFs in test database
5. Test utilities created: Helper functions for auth, database reset, API calls
6. Example E2E test: User signup → login → perform search → logout
7. CI integration: Integration tests run in GitHub Actions after unit tests
8. Test isolation: Each test resets database to clean state
9. Debugging support: Playwright traces and screenshots on failure
10. Documentation: `docs/testing-guide.md` explains how to write integration tests

**Dependencies:** Story 0.2, 0.3, 0.4-0.9 completed
**Risk Level:** MEDIUM (delays testing, but not blocking for initial development)

---

## Epic 0 Completion Criteria

All 14 stories completed with acceptance criteria met:
- ✅ VPS infrastructure audited and documented
- ✅ All 8 VPS services tested and integrated
- ✅ Local development environment fully configured
- ✅ CI/CD pipeline operational
- ✅ Secrets management implemented
- ✅ Integration testing framework ready

**Upon completion, developers can begin Epic 1 with ZERO environment blockers.**

---

## Risk Mitigation

**High-Risk Items (Must address immediately):**
1. VPS access issues → Verify SSH access and credentials before starting
2. A4F API quota limits → Test rate limiting and implement fallback
3. Supabase connection failures → Have backup connection strings ready

**Medium-Risk Items (Monitor during epic):**
1. Service latency spikes → Implement timeouts and retry logic
2. Disk space exhaustion → Set up alerts at 80% capacity
3. Cost overruns → Monitor A4F token usage daily

---

**Estimated Timeline:** 3-5 working days for full team
**Critical Path:** Story 0.1 → 0.2 → 0.3 (VPS + DB + AI API) must complete first
**Parallel Work:** Stories 0.4-0.9 (service integrations) can run in parallel after 0.1
**Final Steps:** Stories 0.11-0.14 (local dev setup) can overlap with service testing

