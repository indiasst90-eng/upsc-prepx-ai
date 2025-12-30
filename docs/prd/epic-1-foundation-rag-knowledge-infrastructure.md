# Epic 1: Foundation & RAG Knowledge Infrastructure

**CRITICAL DEPENDENCY:** This epic requires **Epic 0: Infrastructure Prerequisites** to be completed first. All VPS services, local development environment, and external integrations must be operational before starting Epic 1.

**Epic Goal:**
Establish the foundational technical infrastructure for UPSC AI Mentor, including project setup, authentication system, complete database schema, and RAG-powered knowledge base. By the end of this epic, the system shall have 200+ UPSC standard books ingested into a vector database with semantic search capability achieving <500ms query latency, enabling all future features to leverage accurate, syllabus-grounded content generation. This epic also delivers a functional health-check dashboard showing system status.

**Prerequisites from Epic 0:**
- ✅ VPS services operational (Supabase, Manim, Revideo, Document Retriever, etc.)
- ✅ A4F Unified API tested and integrated
- ✅ Local development environment configured
- ✅ CI/CD pipeline functional
- ✅ All external service integrations validated

## Story 1.1: Project Setup & Development Environment

**As a** developer,
**I want** a fully configured monorepo with Next.js frontend, Supabase backend, CI/CD pipeline, and local development environment,
**so that** the team can begin feature development with standardized tooling and automated quality checks.

### Acceptance Criteria

1. Turborepo monorepo initialized with `apps/web`, `apps/admin`, `packages/supabase`, `packages/ui`, `packages/config`, `packages/utils` structure
2. Next.js 14+ (App Router) configured in `apps/web` with TypeScript, Tailwind CSS, ESLint, Prettier
3. Supabase project created (cloud or self-hosted) with connection pooling enabled
4. GitHub repository initialized with branch protection rules (require PR approval, passing CI checks)
5. GitHub Actions CI/CD pipeline configured running on every PR: `lint`, `type-check`, `test`, `build`
6. Local development setup documented in `README.md` with commands: `npm install`, `npm run dev`, `npm run test`
7. Environment variables template (`.env.example`) created listing all required keys (SUPABASE_URL, SUPABASE_ANON_KEY, etc.)
8. Simple health-check route deployed: `GET /api/health` returns `{ status: "ok", timestamp: ISO8601 }`

---

## Story 1.2: Authentication System with Supabase Auth

**As a** UPSC aspirant,
**I want** to sign up and log in using Google OAuth, Email, or Phone,
**so that** I can access personalized study materials and track my progress securely.

### Acceptance Criteria

1. Supabase Auth configured with providers: Google OAuth, Email (magic link + password), Phone (OTP)
2. `/login` and `/signup` pages created with shadcn/ui forms and Zod validation
3. JWT-based session management with httpOnly cookies (no localStorage for auth tokens per Business Vision)
4. Auth middleware protects all authenticated routes (`/dashboard/*`, `/admin/*`)
5. User profile creation automatic on first login (creates `users` and `user_profiles` table entries)
6. Email verification required for email signups (Supabase Email Templates configured)
7. Password reset flow implemented with magic link
8. Session persistence across browser restarts
9. Logout functionality clears session and redirects to landing page
10. Auth state accessible via React Context for client components and server components

---

## Story 1.3: Database Schema - Core Tables

**As a** backend developer,
**I want** all core database tables created with proper relationships, indexes, and Row-Level Security policies,
**so that** the system can store users, subscriptions, content, and analytics securely.

### Acceptance Criteria

1. SQL migration file created: `001_core_schema.sql` with all tables from technical spec
2. Core tables created: `users`, `user_profiles`, `plans`, `subscriptions`, `entitlements`, `audit_logs`
3. Subscription plans seeded: Monthly (₹599), Quarterly (₹1499), Half-Yearly (₹2699), Annual (₹4999)
4. Foreign key relationships established with ON DELETE CASCADE where appropriate
5. Timestamp columns (`created_at`, `updated_at`) with automatic triggers
6. Indexes created on frequently queried columns: `users.email`, `subscriptions.user_id`, `subscriptions.status`
7. RLS policies enabled on all tables ensuring users access only their own data
8. Database migration applies successfully on fresh Supabase instance
9. Test data seeded for development: 5 sample users with varying subscription statuses
10. Supabase TypeScript types auto-generated: `npm run supabase:gen-types`

---

## Story 1.4: Database Schema - Knowledge Base Tables

**As a** backend developer,
**I want** knowledge base tables (`syllabus_nodes`, `pdf_uploads`, `knowledge_chunks`) with pgvector extension configured,
**so that** the system can store and query UPSC content using semantic vector search.

### Acceptance Criteria

1. pgvector extension enabled in Supabase: `CREATE EXTENSION vector;`
2. Tables created: `syllabus_nodes`, `pdf_uploads`, `knowledge_chunks`, `comprehensive_notes`, `daily_updates`
3. `knowledge_chunks.content_vector` column type: `vector(1536)` for OpenAI embeddings
4. Vector index created: `CREATE INDEX USING ivfflat (content_vector vector_cosine_ops) WITH (lists = 100);`
5. Full-text search index: `CREATE INDEX USING gin(to_tsvector('english', content));`
6. GIN index on array column: `CREATE INDEX USING gin(syllabus_nodes);`
7. Syllabus taxonomy pre-seeded with official UPSC structure (GS1-4, CSAT, Essay papers with ~1000 total topics)
8. Sample knowledge chunks inserted (100 chunks from test PDFs) for validation
9. Vector similarity search query tested: `SELECT * FROM knowledge_chunks ORDER BY content_vector <=> '[embedding]' LIMIT 10;` executes in <500ms
10. Cascade delete policies ensure cleanup when source PDFs are removed

---

## Story 1.5: PDF Ingestion Pipeline - Admin Upload Interface

**As an** admin,
**I want** to upload UPSC reference book PDFs through a web interface and monitor processing status,
**so that** the knowledge base expands with accurate source material for RAG retrieval.

### Acceptance Criteria

1. Admin dashboard route `/admin/knowledge-base` created with auth check (role = 'admin')
2. Drag-and-drop PDF upload zone (react-dropzone) accepting multiple files
3. File upload to Supabase Storage bucket: `knowledge-base-pdfs/` with public read access disabled
4. Metadata form for each upload: subject, book_title, author, edition, priority (1-100), syllabus_mapping (multi-select)
5. `pdf_uploads` table record created with status = 'pending' on successful upload
6. Upload progress indicator showing percentage complete
7. Processing status table displays: filename, upload_status (pending/processing/completed/failed), chunks_created, processing_errors
8. "Reprocess" button triggers manual re-ingestion for failed uploads
9. File size validation: Max 500MB per PDF, error message if exceeded
10. Admin can view list of all uploaded PDFs with filter by subject and status

---

## Story 1.6: PDF Processing Pipeline - Text Extraction & Chunking

**As a** background job processor,
**I want** to automatically extract text from uploaded PDFs, chunk semantically, and store in knowledge_chunks table,
**so that** the content is queryable via vector search for RAG retrieval.

### Acceptance Criteria

1. Edge Function created: `process_pdf_job` triggered by `pdf_uploads` INSERT via database trigger
2. PDF text extraction using `pdf-parse` library with OCR fallback for scanned pages (Tesseract.js)
3. Semantic chunking logic: max 1000 tokens per chunk, 200 token overlap between adjacent chunks
4. Chunk metadata extracted: source_file, source_page, subject, book_title
5. Syllabus node mapping: AI analyzes each chunk and assigns relevant `syllabus_node_id`s (array)
6. OpenAI Embeddings API called: `text-embedding-3-small` generates 1536-dim vectors
7. `knowledge_chunks` table bulk insert: all chunks with vectors, metadata
8. `pdf_uploads.upload_status` updated to 'completed' with `chunks_created` count
9. Error handling: failures logged to `pdf_uploads.processing_errors`, status = 'failed', admin notified
10. Processing time logged: average 100 chunks/minute, large PDFs (500+ pages) complete within 30 minutes

---

## Story 1.7: RAG Search Engine - Semantic Query Implementation

**As a** UPSC aspirant,
**I want** to search the knowledge base using natural language queries and receive ranked results with source citations,
**so that** I can quickly find accurate answers grounded in standard UPSC books.

### Acceptance Criteria

1. Edge Function created: `rag_search_pipe.ts` at endpoint `POST /api/search`
2. Request payload: `{ query: string, top_k: number, filters: { subjects, papers, source_types } }`
3. Query embedding generated via OpenAI API (same model as ingestion: text-embedding-3-small)
4. Vector similarity search executed: `ORDER BY content_vector <=> query_embedding LIMIT top_k`
5. Results include: content snippet (first 200 chars), full_content, score (cosine similarity 0-1), metadata (source_file, page, book_title, chapter)
6. Confidence score calculated: scores >0.75 = "High Confidence (XX%)", 0.60-0.75 = "Moderate (XX%)", <0.60 = "Low - Cross-check recommended"
7. If best result score <0.70, return: `{ insufficient_confidence: true, message: "Cannot answer with high confidence" }`
8. Source citation formatted: "Based on [Book Title], Chapter X, Page Y"
9. Response time <500ms (P95) for top 10 results
10. Filter support: filter by `subjects` (Polity, History, etc.), `papers` (GS1, GS2, etc.), `source_types` (NCERT, Standard Books)

---

## Story 1.8: RAG Search UI - Search Interface & Results Display

**As a** UPSC aspirant,
**I want** a Google-like search interface with instant results, confidence scores, and source citations,
**so that** I can trust the answers and verify information in standard books.

### Acceptance Criteria

1. Search page created at `/search` with prominent search bar (autofocus on load)
2. Search input with debounced API calls (300ms delay) for instant suggestions
3. Loading skeleton while results fetch (no spinners, use shimmer effect)
4. Results list displays: rank number, confidence badge (color-coded green/yellow/red), content snippet, book citation
5. Each result has "Expand" button showing full content in modal
6. Each result has "Explain More" button (queues video generation for Pro users, shows paywall for Free users)
7. Filter sidebar: checkboxes for subjects, papers, source types; apply button triggers new search
8. "Report Incorrect Information" link on each result opens feedback modal
9. Empty state when no results: "No confident matches found. Try rephrasing your query."
10. Search history saved (last 10 searches) for logged-in users, displayed as chips below search bar

---

## Story 1.9: Trial & Subscription Logic Implementation

**As a** UPSC aspirant,
**I want** to automatically receive a 7-day free trial with full Pro access upon signup,
**so that** I can evaluate all premium features before deciding to subscribe.

### Acceptance Criteria

1. On user signup, `subscriptions` table record created: `status = 'trial'`, `trial_started_at = NOW()`, `trial_expires_at = NOW() + 7 days`
2. Entitlement check function `checkEntitlement(user_id, feature_slug)` returns `{ allowed: true, reason: 'trial_active' }` if within trial period
3. Trial expiry checked on every premium feature request: if `NOW() > trial_expires_at`, return `{ allowed: false, show_paywall: true }`
4. Trial countdown displayed in dashboard header: "5 days left in trial"
5. Email notifications sent: Day 1 (welcome), Day 3 (tips), Day 5 (2 days left), Day 7 (trial ending today)
6. Post-trial: user downgraded to Free tier (not blocked), premium features show upgrade prompts
7. "Start Trial" CTA hidden if trial already used (one trial per user lifetime)
8. Trial status visible in user profile settings
9. Admin can manually extend trials: `UPDATE subscriptions SET trial_expires_at = NOW() + X days`
10. Analytics tracked: trial-to-paid conversion rate calculated daily

---

## Story 1.10: Health Check Dashboard & System Monitoring

**As a** developer,
**I want** a public health-check endpoint and internal system status dashboard,
**so that** I can monitor service availability, database connectivity, and VPS service health.

### Acceptance Criteria

1. Public endpoint `GET /api/health` returns: `{ status: "ok", timestamp, uptime_seconds, version }`
2. Admin-only endpoint `GET /api/admin/system-status` returns detailed metrics:
   - Database: connection status, active connections, slow queries count
   - VPS services: ping each service (doc retriever, video renderer, notes generator), response times
   - Storage: total used GB, videos count, PDFs count
   - Queue: pending jobs, failed jobs, average processing time
3. Dashboard page `/admin/system-status` displays metrics in cards with auto-refresh every 30s
4. Alerts configured: if any service response time >5s or returns error, send alert (email/Slack webhook)
5. Uptime tracking: log hourly checks, calculate 95%+ uptime over 30 days
6. Database query performance logged: slow queries (>1s) logged to monitoring table
7. Error rate graphs: display last 24 hours of errors by type (4xx, 5xx, service failures)
8. VPS disk space monitoring: alert if <10GB free space on video storage
9. Job queue backlog alert: if >1000 pending jobs, escalate to admin
10. All health checks have <5s timeout, fail gracefully if service unavailable

---
