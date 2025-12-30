# UPSC AI Mentor Product Requirements Document (PRD)

**Version:** 1.0
**Date:** December 23, 2025
**Status:** Draft
**Owner:** PM Agent (John)

---

## Goals and Background Context

### Goals

**Desired Outcomes if PRD is Successfully Delivered:**

1. **Launch MVP within 14 weeks** (8 weeks dev + 2 weeks alpha + 4 weeks beta) with 8 core features operational
2. **Achieve 10,000 trial signups** within 90 days of public launch through organic and paid marketing
3. **Convert 15% of trial users to paid subscriptions** (1,500 paying subscribers at Month 3)
4. **Maintain 95%+ video render success rate** and <60 second doubt video generation time
5. **Deliver measurable learning outcomes:** 70% of users complete 50%+ syllabus within 6 months, 25% clear UPSC Prelims
6. **Establish technical moat** through RAG-powered knowledge base (200+ UPSC books ingested) and Manim+Revideo video pipeline
7. **Validate unit economics:** Achieve <₹200 AI cost per user/month with ₹599 ARPU
8. **Build trust through accuracy:** Maintain <1% error rate with RAG grounding and human review for high-stakes content

### Background Context

UPSC Civil Services preparation currently suffers from fragmentation (15+ books, 10+ websites), high costs (₹2-3 lakh coaching fees), and lack of personalization. The 5-7 lakh annual UPSC aspirants face geographic barriers (coaching concentrated in metros), static pre-recorded content that becomes outdated, and minimal individual attention in batch coaching. Existing online platforms (Unacademy, BYJU'S) offer pre-recorded lectures without real-time doubt resolution or AI-powered personalization.

UPSC AI Mentor solves this by combining three technological pillars: (1) **RAG-based knowledge system** grounding all content in standard UPSC books (Laxmikanth, NCERT, Spectrum) to prevent hallucinations, (2) **Automated video generation** using Manim (mathematical/diagram animations) and Revideo (video composition) for on-demand explainer videos, and (3) **Adaptive intelligence** tracking per-topic performance to personalize study schedules and revision packages. The platform serves all three UPSC stages—Prelims (objective), Mains (descriptive answer writing), and Interview (mock simulations)—at ₹599/month (vs ₹15,000-50,000/year for competitors), making quality preparation accessible to Tier 2/3 city aspirants and working professionals who cannot relocate for coaching.

### Change Log

| Date | Version | Description | Author |
|------|---------|-------------|--------|
| 2025-12-23 | 1.0 | Initial PRD created from Project Brief and Business Vision | PM Agent (John) |

---

## Requirements

### Functional Requirements

**FR1: Interactive 3D UPSC Syllabus Navigator**
- The system shall provide a 3D interactive tree visualization of the complete UPSC syllabus (Prelims GS1-4, Mains GS1-4, CSAT, Essay)
- Shall support zoomable nodes, syllabus filters, bookmarks, and progress rings per topic
- Shall display heatmap of user's time-spent and performance per node
- Shall render intro explainer videos for each node using Revideo with Manim-generated visual diagrams
- **Monetization:** Freemium (basic 2D navigator free, advanced 3D guided roadmap paid)
- **Complexity:** High

**FR2: Daily Current Affairs Video Newspaper**
- The system shall auto-generate daily 5-8 minute video summarizing UPSC-relevant national/international current affairs by 6 AM IST
- Shall segment by topics (Economy, Polity, IR, Environment) with visual maps and timelines
- Shall auto-generate 30-60 second Shorts for social media sharing
- Shall provide downloadable PDF summary and 5 MCQs
- Shall compile monthly PDF (100+ pages) of all daily updates
- **Monetization:** Daily CA subscription, micro-purchases for deep-dive videos
- **Complexity:** High

**FR3: Real-Time Doubt to Video Converter**
- The system shall convert user text doubts or screenshot images into 60-180 second explainer videos within 2 minutes
- Shall support multiple styles (concise, detailed, example-rich), voice selection, and speed control
- Shall output video, short notes, and mini-quiz with each response
- Shall use Manim for technical diagrams and Revideo for TTS assembly
- **Monetization:** Per-video charge or monthly unlimited cap
- **Complexity:** High

**FR4: 3-Hour Documentary-Style Lectures**
- The system shall generate long-form cinematic lectures (2-3 hours) with automatic chapter segmentation
- Shall include bookmarks, suggested readings, timestamps, and per-chapter quizzes
- Shall use Revideo to sequence chapters and Manim for complex sub-explanations
- **Monetization:** Premium course bundles, one-time purchases (₹99/lecture)
- **Complexity:** Very High

**FR5: 360° Immersive Geography/History Visualizations**
- The system shall produce 360°/panoramic video experiences for geography and history topics
- Shall support interactive hotspots, embedded quizzes, and VR headset compatibility
- Shall use Revideo for stitching and Manim for animated data overlays
- **Monetization:** Premium feature, marketing shorts
- **Complexity:** Very High

**FR6: 60-Second Topic Shorts**
- The system shall auto-create 60-second explainer videos for any UPSC topic
- Shall generate auto-thumbnails, SEO-friendly titles, and support scheduling to social accounts
- Shall output videos in multiple aspect ratios (16:9, 9:16, 1:1)
- **Monetization:** Marketing tool for paid subscriptions, packaged short bank
- **Complexity:** Medium

**FR7: Visual Memory Palace Videos**
- The system shall convert lists/facts into visual memory palace animations (rooms → facts)
- Shall support custom palace themes per student and spaced repetition integration
- Shall use Manim for 2D/3D object transitions and Revideo for compilation
- **Monetization:** One-off purchase or premium feature
- **Complexity:** High

**FR8: Ethical Case Study Roleplay Videos (GS4)**
- The system shall provide choose-your-path ethical dilemmas with branching video paths
- Shall grade decisions by ethical frameworks (utilitarian, deontological) with feedback video
- Shall use Revideo for branch video assembly and Manim for concept diagrams
- **Monetization:** Premium case packs, mentor review add-on
- **Complexity:** High

**FR9: Animated Math Problem Solver (CSAT/Economy)**
- The system shall provide step-by-step animated solutions for quantitative and graph problems
- Shall support typed problems or image upload (OCR)
- Shall output Manim animation clip, text solution, and downloadable slides
- **Monetization:** Per-solve credits or subscription bundle
- **Complexity:** High

**FR10: Static & Animated Notes Generator**
- The system shall generate notes at 3 levels (summary 100 words, detailed 250 words, comprehensive 500 words)
- Shall create Manim diagrams and 60-second video summaries
- Shall export as PDF, markdown with cross-links to related topics
- **Monetization:** Notes store, subscription for full notes set
- **Complexity:** Medium

**FR11: Animated Case Law, Committee & Amendment Explainer**
- The system shall visually map legal cases, amendments, committee timelines and relationships
- Shall provide timeline slider and interactive nodes linking to full text and videos
- Shall use Manim for legal relationship diagrams and Revideo for narrated video
- **Monetization:** Course modules (Polity pack)
- **Complexity:** Medium-High

**FR12: AI Study Schedule Builder**
- The system shall generate personalized adaptive schedules considering weak topics, tests, and time availability
- Shall support push notifications, Google Calendar sync, micro-goals, and streaks
- Shall output daily schedule with recommended video/note/quiz assignments
- Shall optionally generate daily briefing video via Revideo
- **Monetization:** Premium guided plans, coach add-ons
- **Complexity:** Medium

**FR13: Fully Automated PYQ Video Explanation Engine**
- The system shall ingest PYQ PDFs/images and generate model answers with animated explanations
- Shall auto-group by topic and assign difficulty tags
- Shall use Manim for diagrams/walkthroughs and Revideo for final video assembly
- **Monetization:** PYQ packs, pay-per-video
- **Complexity:** High

**FR14: 3D Interactive GS Map Atlas**
- The system shall provide layered interactive maps for geography, resources, demographics, disaster zones
- Shall support time slider for historical maps, data overlays, animated flows (rivers, migration)
- Shall export interactive 3D maps, images, and narrated video tours
- **Monetization:** Country/State packs, premium data layers
- **Complexity:** Very High

**FR15: AI Essay Trainer with Live Video Feedback**
- The system shall accept essays (up to 1000 words) and provide AI scoring with video walkthrough
- Shall use rubric-based scoring and model answer comparison
- Shall use Manim for argument structure visualization and Revideo for feedback video
- **Monetization:** Essay review credits, subscription
- **Complexity:** Medium

**FR16: Daily Answer Writing + AI Scoring + Video Feedback**
- The system shall provide daily Mains answer practice with instant AI scoring and video suggestions
- Shall support timed writing mode and comparison with topper answers
- Shall use Manim for diagrams in suggested answers and Revideo for feedback video
- **Monetization:** Daily practice subscription, per-evaluation credits
- **Complexity:** Medium

**FR17: GS4 Ethics Simulator (Advanced)**
- The system shall provide multi-stage ethical dilemmas with user decisions, scoring, and personality analysis
- Shall offer multi-path scenarios, behavior analytics, and recommended readings
- Shall use Manim for moral framework diagrams and Revideo for outcome rendering
- **Monetization:** Scenario packs, premium mentor reviews
- **Complexity:** High

**FR18: RAG-Based UPSC Search Engine**
- The system shall provide high-precision semantic search across curated UPSC knowledge base
- Shall support source filters, exact book & chapter references, and explainability boxes
- Shall output ranked hits with citations and AI-generated answer snippets
- Shall optionally create short Revideo explainer for complex queries
- **Monetization:** Premium search features (advanced filters, saved searches)
- **Complexity:** Medium

**FR19: AI Topic-to-Question Generator (Mains + Prelims)**
- The system shall auto-generate MCQs, Prelims questions, Mains prompts, case studies, and model answers from topics
- Shall support difficulty tags, distractor generation for MCQs, and auto-marking rubrics
- Shall optionally provide Revideo video for model answer explanation
- **Monetization:** Test packs, custom mock tests
- **Complexity:** Low-Medium

**FR20: Personalized AI Teaching Assistant**
- The system shall provide conversational tutor with chosen teacher style, voice, and tone control
- Shall retain user context, provide daily check-ins, progress nudges, and micro-assignments
- Shall generate motivational videos via Revideo and visual explanations via Manim
- **Monetization:** Tiered subscription (standard vs premium mentor)
- **Complexity:** Medium

**FR21: UPSC Mindmap Builder**
- The system shall auto-build mindmaps from topic text, book chapters, or user notes
- Shall support drag & drop editing, PNG/PDF export, and collaborative sharing
- Shall optionally create animated map walkthrough videos via Revideo
- **Monetization:** Premium export/large map limits
- **Complexity:** Medium

**FR22: Ultra-Detailed Syllabus Tracking Dashboard**
- The system shall provide master dashboard with completed topics, strength/weakness analysis, and estimated readiness
- Shall display competency index, time-on-topic, predicted Prelims score, and custom milestones
- Shall output CSV export and recommended study paths
- Shall generate weekly progress video briefings via Revideo
- **Monetization:** Analytics premium plan
- **Complexity:** Medium

**FR23: Smart Revision Booster**
- The system shall automatically select 5 weakest topics weekly and generate revision packages
- Shall include short video, 5 flashcards, and 10-minute quiz
- Shall implement spaced repetition algorithm with push reminders
- Shall use Revideo for revision videos and Manim for quick visuals
- **Monetization:** Add-on subscription, higher cadence paid tier
- **Complexity:** Medium

**FR24: 5-Hours Per Day Planner (Working Professional)**
- The system shall provide pre-built customizable daily plans optimized for limited study hours
- Shall support drag-to-reschedule, auto-adjust for missed sessions, and weekly summaries
- Shall optionally generate daily briefing video via Revideo
- **Monetization:** Paid plan, lifetime planner purchase
- **Complexity:** Low-Medium

**FR25: Book-to-Notes Converter**
- The system shall ingest PDF/epub/text chapters and output multi-level notes (Prelims/Mains versions)
- Shall auto-map chapters to syllabus nodes with citations
- Shall generate key facts MCQs, Manim diagrams, and 1-minute summary video
- **Monetization:** Per-chapter conversion credits, subscription
- **Complexity:** Medium

**FR26: Weekly Documentary (What's Happening in the World)**
- The system shall generate weekly 15-30 minute documentary-style analysis (Economy, Polity, IR, Environment)
- Shall include deep dives, AI-simulated expert interviews, maps, and graphs
- Shall use Manim for data charts and Revideo for documentary visuals
- **Monetization:** Premium weekly package
- **Complexity:** High

**FR27: Test Series Auto-Grader + Performance Graphs**
- The system shall provide full test platform auto-grading both objective and subjective answers
- Shall display historical comparison, strengths heatmap, and growth charts over time
- Shall optionally generate result walkthrough videos via Revideo
- **Monetization:** Test subscriptions, timed mocks
- **Complexity:** Medium

**FR28: Advanced User Monetization System**
- The system shall manage all monetization flows: subscriptions, per-video purchases, coupons, affiliate offers, institutional licensing
- Shall support promo codes, A/B price testing, and in-app purchases
- Shall provide invoices, entitlements, and revenue dashboard
- **Complexity:** Medium-High

**FR29: AI Voice Teacher (Customizable TTS)**
- The system shall provide customizable TTS voices with teaching styles (speed/clarity/charisma sliders)
- Shall support accent selection, celebrity-style voice presets, and fallback text transcripts
- Shall integrate TTS audio with Revideo video sync
- **Monetization:** Premium voice packs, custom voice extra charge
- **Complexity:** Medium

**FR30: Gamified Learning Experience (Lightweight)**
- The system shall provide 3D subject rooms with XP, badges, streaks, and collaborative study sessions
- Shall generate cinematic reward videos via Revideo and in-room mini-challenges via Manim
- **Monetization:** Cosmetic purchases, premium avatars, institutional packages
- **Complexity:** High

**FR31: Topic Difficulty Predictor (AI Prognosis)**
- The system shall predict topic difficulty and weight in upcoming exams based on historical PYQ data and news signals
- Shall provide confidence scores and recommended study weight
- Shall generate report videos via Revideo and trend visualization graphs via Manim
- **Monetization:** Premium analytics
- **Complexity:** Medium-High

**FR32: Smart Bookmark Engine**
- The system shall allow saving concepts with auto-linked notes, PYQs, visual explanations, and scheduled revisions
- Shall support auto-tagging, cross-links, and revision reminders
- Shall optionally generate on-demand Revideo quick explainer for bookmarks
- **Monetization:** Premium bookmark limits & sync
- **Complexity:** Low-Medium

**FR33: Concept Confidence Meter**
- The system shall display visual confidence meter per topic (red/yellow/green) based on quiz results, time spent, and spaced repetition
- Shall provide confidence delta alerts and suggested micro-actions
- Shall generate weekly confidence report videos via Revideo
- **Monetization:** Premium analytics, coach tie-ins
- **Complexity:** Low-Medium

**FR34: Live Interview Prep Studio (Flagship)**
- The system shall provide real-time interactive interview simulations with AI interviewer(s) using TTS
- Shall generate real-time visual aids (Manim diagrams, timelines, maps) as candidate answers
- Shall record sessions (audio/video + screen overlays) and generate instant Revideo debrief video (3-5 minutes)
- Shall optionally analyze body language (opt-in with explicit consent) providing improvement tips
- Shall support panel mode with peer/mentor reviews integrated into feedback
- Shall implement adaptive interview question bank with difficulty progression
- **User Flow:** Book slot → AI panel TTS → "Show Visual" button triggers Manim render → Auto-debrief video post-session
- **Monetization:** High-value premium (₹999/month or ₹2999 one-time), paid mentor review add-on
- **Privacy:** Explicit consent for recordings, secure storage, delete-on-demand
- **Complexity:** Very High (requires low-latency Manim microservice 2-6s, streaming compositing, real-time orchestration)

### Non-Functional Requirements

**NFR1: System Availability**
- The system shall maintain 95%+ uptime (max 36 hours downtime/month) with Sentry monitoring and alerting

**NFR2: Video Rendering Success Rate**
- Video rendering shall achieve ≥95% success rate with 3-attempt retry logic; failures escalated to manual review

**NFR3: Doubt Video Generation Latency**
- Doubt-to-video generation shall complete in <60 seconds for 60s videos (P95) and <120 seconds for 180s videos (P95)

**NFR4: RAG Search Performance**
- RAG semantic search queries shall return results in <500ms (P95) for top 10 results

**NFR5: Daily CA Video Delivery**
- Daily current affairs video shall be published by 6:00 AM IST with ≤5% failure rate requiring manual fallback

**NFR6: Concurrent User Capacity**
- The system shall handle 10,000 concurrent users without degradation (FCP <1.5s, LCP <2.5s)

**NFR7: AI Cost Per User**
- AI cost per user shall not exceed ₹200/month (LLM API + video rendering + infrastructure) for 67% gross margin

**NFR8: Vector Database Scale**
- Database shall support 1M+ knowledge chunks with vector search <500ms using pgvector ivfflat indexing

**NFR9: Caching Efficiency**
- The system shall achieve 70% cache hit rate for LLM API calls to control costs

**NFR10: Video Delivery Performance**
- Video storage via Cloudflare CDN shall achieve <1 second playback start latency globally

**NFR11: Mobile Responsiveness**
- The system shall be mobile-first responsive supporting Chrome 90+, Safari 14+ on iOS 14+

**NFR12: Form Validation Performance**
- All forms shall have client-side Zod validation with error display within 100ms

**NFR13: Accessibility Compliance**
- The system shall maintain WCAG 2.1 AA standards (keyboard navigation, screen readers, color contrast)

**NFR14: Rate Limiting**
- Edge Functions shall implement 100 requests/minute/user rate limiting to prevent abuse

**NFR15: Security Architecture**
- All external API calls shall be server-side only through Supabase Edge Functions; no client-side service URL exposure

**NFR16: Horizontal Scaling**
- Video rendering shall support horizontal scaling from 1 VPS (1K concurrent) to 10 VPS (10K concurrent)

**NFR17: Content Accuracy**
- Content accuracy shall be ≥99% validated via user feedback and quarterly SME audits of 100 random answers

**NFR18: Knowledge Base Capacity**
- The system shall support 50GB total PDF knowledge base (200+ standard UPSC books)

**NFR19: Payment Security**
- Payment processing shall be PCI-compliant via RevenueCat; no credit card data in application database

**NFR20: Refund Processing**
- 7-day money-back guarantee and pro-rated refunds shall process within 48 hours

**NFR21: Manim Render Optimization (FR34)**
- Manim microservice shall render small scenes in 2-6 seconds for real-time interview visual aids

**NFR22: RAG Confidence Threshold**
- All AI-generated content shall require ≥70% RAG confidence score; below threshold displays "Cannot answer with high confidence"

**NFR23: Source Citation Mandatory**
- Every AI answer shall cite source as "Based on [Book Name], Chapter X, Page Y"

**NFR24: Content Flagging SLA**
- User-reported incorrect information shall route to review queue within 24 hours with resolution tracking

**NFR25: Whitelisted Sources Only**
- Daily current affairs shall source only from approved domains: visionias.in, drishtiias.com, thehindu.com, pib.gov.in, forumias.com, insightsonindia.com, iasbaba.com, iasscore.in, nextias.com, *.gov.in

---

## User Interface Design Goals

### Overall UX Vision

**"Neon Glass Dark Mode" - Mobile-First, Distraction-Free Learning Interface**

UPSC AI Mentor shall provide a premium, modern interface that feels like a personal AI tutor in your pocket. The design philosophy centers on **"learning-first, not entertainment-first"** - every UI element must serve educational outcomes, not engagement metrics. The interface uses a dark theme with frosted glass effects, neon blue/purple accents, and smooth Framer Motion animations to create a professional yet inviting study environment. Students should feel they're using cutting-edge technology while never being distracted from actual learning.

### Key Interaction Paradigms

1. **Progressive Disclosure:** Complex features (like 34 total features) are organized into clear categories (Study, Practice, Review, Insights) with simple entry points
2. **Lazy Loading & Async Patterns:** Videos and content load on-demand; users see immediate text responses while videos render in background
3. **Confidence Transparency:** Every AI-generated answer displays confidence score and source citations prominently
4. **Mobile-First Video Player:** Custom HLS player optimized for 4G/5G with quality adaptation, speed controls, and offline download (Pro only)
5. **No Dark Patterns:** No infinite scroll, no manipulative notifications post-10 PM, no competitive leaderboards creating anxiety
6. **Accessibility by Default:** Keyboard navigation, screen reader support, high-contrast mode toggle built into every component

### Core Screens and Views

**Public Screens:**
1. **Landing Page** - Marketing hero with feature showcase, pricing comparison table, testimonials from UPSC toppers
2. **Pricing Page** - 4 subscription plans with feature comparison matrix, trial CTA prominent
3. **Login/Signup** - Google OAuth primary, Email/Phone secondary, clean minimalist form

**Authenticated Dashboard:**
4. **Home Dashboard** - Personalized greeting, today's current affairs card, quick access tiles (Ask Doubt, Continue Learning, Take Test), progress ring showing overall syllabus completion
5. **Syllabus Navigator** - 2D/3D tree visualization (React Three Fiber), sidebar filters (GS1-4, CSAT, Essay), node click opens topic detail modal
6. **Daily Current Affairs Page** - Video player top, transcript below, 5 MCQs collapsed accordion, PDF download button, archive calendar
7. **Ask Doubt Page** - Text input with mic icon, image upload zone, style selector (concise/detailed/example-rich), response shows text preview immediately then video when ready
8. **Notes Library** - Grid view of topic cards with thumbnails, filter by subject/paper, search bar, each note has 3-level depth toggle
9. **Search Results Page** - Google-like results list, each result shows confidence score, book citation, snippet, "Explain more" button generates video
10. **Practice Hub** - Tabs for Answer Writing, Essay Practice, Test Series, PYQ Bank; each shows progress stats
11. **Progress Dashboard** - Hero metric cards (syllabus completion %, confidence score, study streak), charts (time-on-topic bar graph, strength/weakness heat map), predicted readiness gauge
12. **Settings/Profile** - Account details, subscription management, voice preferences, notification settings, accessibility toggles

**Admin Panel:**
13. **Admin Dashboard** - Revenue metrics, user stats, error rate graphs, job queue status
14. **User Management** - Searchable user list, subscription status, entitlement grants
15. **Knowledge Base Upload** - Drag-drop PDF zone, processing status table, reprocess button
16. **Video Render Monitor** - Job queue table with status, logs, retry buttons

### Accessibility

**Target: WCAG 2.1 AA Compliance**

- All interactive elements keyboard accessible (Tab navigation, Enter/Space activation)
- Screen reader announcements for dynamic content (video render complete, answer evaluated)
- Color contrast ratio ≥4.5:1 for normal text, ≥3:1 for large text
- Focus indicators visible on all focusable elements
- Alternative text for all images, diagrams, video thumbnails
- Captions/transcripts for all videos (VTT format)
- High-contrast mode toggle in settings (switches to white backgrounds, black text)

### Branding

**Visual Identity:**
- **Color Palette:**
  - Primary: Neon Blue (#3B82F6 to #1D4ED8 gradient)
  - Secondary: Purple Accent (#8B5CF6)
  - Background: Dark Slate (#0F172A)
  - Glass Effects: Frosted glass with backdrop-blur-md
- **Typography:**
  - Headings: Satoshi (modern, geometric)
  - Body: Inter (readable, clean)
- **Animations:** Framer Motion for page transitions, button interactions, skeleton loaders
- **Design System:** shadcn/ui components with custom dark theme overrides

### Target Platforms

**Primary: Web Responsive (Mobile-First)**
- Progressive Web App (PWA) with offline capabilities
- Install prompt for "Add to Home Screen" on mobile
- Responsive breakpoints: Mobile (<640px), Tablet (640-1024px), Desktop (>1024px)

**Future (Post-MVP):**
- Native iOS app (Swift UI)
- Native Android app (Kotlin/Jetpack Compose)
- Desktop apps (Electron) for offline study

---

## Technical Assumptions

### Repository Structure

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

### Service Architecture

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

### Pipes/Filters/Actions Pattern

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

### Testing Requirements

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

### Additional Technical Assumptions

#### **Database & Storage**

- **Primary Database:** Supabase PostgreSQL 15+ with pgvector extension
- **Vector Embeddings:** OpenAI text-embedding-3-small (1536 dimensions)
- **Indexing:** ivfflat for vector search (100 lists), GIN for full-text search
- **Storage:** Supabase Storage for videos/PDFs, Cloudflare CDN for delivery
- **Caching:** Redis (optional for MVP, required for scale - ElastiCache)

#### **Authentication & Security**

- **Auth:** Supabase Auth with JWT tokens, Google OAuth primary
- **Authorization:** Row-Level Security (RLS) policies on all tables
- **API Security:** Rate limiting (100 req/min/user), CORS whitelist, no API keys in client
- **Data Privacy:** GDPR-compliant, user data deletion on request, audit logs for admin actions
- **Payment Security:** RevenueCat handles PCI compliance, no credit cards in our DB

#### **Deployment & DevOps**

- **Frontend:** Vercel (auto-deploy from `main` branch, preview deploys for PRs)
- **Backend:** Supabase Cloud (hosted PostgreSQL + Edge Functions + Storage)
- **VPS:** Self-managed Ubuntu 22.04 with Docker containers for each service
- **Monitoring:** Sentry (error tracking), Vercel Analytics (web vitals), Supabase metrics
- **CI/CD:** GitHub Actions (run tests, lint, type-check on every PR)
- **Secrets Management:** Supabase Secrets for Edge Function env vars, Vercel env vars for frontend

#### **AI/LLM Providers**

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

#### **External Service URLs (VPS - 89.117.60.144)**

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

#### **Performance Optimizations**

- **React Server Components:** Use RSC for initial page loads (faster FCP/LCP)
- **Image Optimization:** Next.js Image component with WebP/AVIF, lazy loading
- **Code Splitting:** Dynamic imports for heavy components (3D syllabus, video player)
- **Bundle Size:** Analyze with `@next/bundle-analyzer`, target <300KB initial JS
- **Database Query Optimization:** Indexed columns, avoid N+1 queries, use connection pooling
- **CDN Strategy:** Cloudflare CDN for video delivery (edge caching), Vercel Edge for static assets

---

## Epic List

### Epic 1: Foundation & RAG Knowledge Infrastructure
**Goal:** Establish project setup, authentication, database schema, and RAG-powered knowledge base by ingesting standard UPSC books into vector database, enabling accurate semantic search and content grounding for all AI features.

### Epic 2: Core Learning Features - Discovery & Notes
**Goal:** Deliver syllabus navigation, RAG search engine, and multi-level notes generation to enable students to discover, search, and consume foundational study materials across the entire UPSC syllabus.

### Epic 3: Video Generation Pipeline - Daily Current Affairs
**Goal:** Build automated daily current affairs video newspaper with Manim+Revideo rendering pipeline, delivering 5-8 minute videos by 6 AM IST with PDF summaries and MCQs.

### Epic 4: On-Demand Video Learning - Doubt Converter & Topic Shorts
**Goal:** Enable real-time doubt-to-video conversion and 60-second topic shorts generation, providing on-demand personalized video explanations for any UPSC topic or user question.

### Epic 5: Monetization & Subscription System
**Goal:** Implement trial logic, RevenueCat integration, entitlement checks, subscription plans, and admin dashboard for revenue management, enabling sustainable business operations.

### Epic 6: Progress Tracking & Personalization
**Goal:** Build syllabus tracking dashboard, AI study schedule builder, confidence meter, and smart revision booster to provide personalized adaptive learning paths based on user performance.

### Epic 7: Practice & Evaluation - Answer Writing & Essays
**Goal:** Deliver daily answer writing practice, AI essay trainer, and test series auto-grader with video feedback, enabling students to practice Mains descriptive answers with instant AI scoring.

### Epic 8: Practice & Evaluation - PYQs & Question Bank
**Goal:** Build PYQ video explanation engine, topic-to-question generator, and comprehensive test series platform for unlimited practice with model answers and performance analytics.

### Epic 9: Advanced Learning Tools - Mindmaps, Bookmarks & Assistants
**Goal:** Provide UPSC mindmap builder, smart bookmark engine, and personalized AI teaching assistant for enhanced study organization and conversational learning support.

### Epic 10: Deep Learning Assets - Documentary Lectures & Weekly Analysis
**Goal:** Generate 3-hour documentary-style lectures and weekly current affairs documentaries for deep conceptual understanding and comprehensive topic coverage.

### Epic 11: Specialized Learning - Math Solver, Memory Palace & Maps
**Goal:** Build animated math problem solver (CSAT/Economy), visual memory palace videos, and 3D interactive map atlas for specialized learning needs in quantitative and visual subjects.

### Epic 12: Ethics & Interview Preparation
**Goal:** Deliver GS4 ethics simulators (basic roleplay + advanced multi-stage), case law explainer, and comprehensive interview prep tools to prepare students for Ethics paper and personality test.

### Epic 13: Flagship Interview Prep Studio (Real-Time AI Interviews)
**Goal:** Build live interview prep studio with real-time AI interviewers, Manim visual aids during answers, instant video debrief, and optional body language analysis—the platform's premium flagship feature.

### Epic 14: Gamification & Engagement - XP, Analytics & Predictions
**Goal:** Implement lightweight gamified learning (XP, badges, streaks), topic difficulty predictor, and advanced analytics to drive engagement while maintaining learning-first principles.

### Epic 15: Premium Media & Immersive Experiences
**Goal:** Deliver 360° immersive geography/history visualizations and enhanced video capabilities for premium users seeking cinematic learning experiences.

### Epic 16: Voice Customization & Social Publishing
**Goal:** Build AI voice teacher customization (TTS styles, accents) and auto social media publisher (admin tool) for personalized narration and marketing automation.

---

## Epic 1: Foundation & RAG Knowledge Infrastructure

**Epic Goal:**
Establish the foundational technical infrastructure for UPSC AI Mentor, including project setup, authentication system, complete database schema, and RAG-powered knowledge base. By the end of this epic, the system shall have 200+ UPSC standard books ingested into a vector database with semantic search capability achieving <500ms query latency, enabling all future features to leverage accurate, syllabus-grounded content generation. This epic also delivers a functional health-check dashboard showing system status.

### Story 1.1: Project Setup & Development Environment

**As a** developer,
**I want** a fully configured monorepo with Next.js frontend, Supabase backend, CI/CD pipeline, and local development environment,
**so that** the team can begin feature development with standardized tooling and automated quality checks.

#### Acceptance Criteria

1. Turborepo monorepo initialized with `apps/web`, `apps/admin`, `packages/supabase`, `packages/ui`, `packages/config`, `packages/utils` structure
2. Next.js 14+ (App Router) configured in `apps/web` with TypeScript, Tailwind CSS, ESLint, Prettier
3. Supabase project created (cloud or self-hosted) with connection pooling enabled
4. GitHub repository initialized with branch protection rules (require PR approval, passing CI checks)
5. GitHub Actions CI/CD pipeline configured running on every PR: `lint`, `type-check`, `test`, `build`
6. Local development setup documented in `README.md` with commands: `npm install`, `npm run dev`, `npm run test`
7. Environment variables template (`.env.example`) created listing all required keys (SUPABASE_URL, SUPABASE_ANON_KEY, etc.)
8. Simple health-check route deployed: `GET /api/health` returns `{ status: "ok", timestamp: ISO8601 }`

---

### Story 1.2: Authentication System with Supabase Auth

**As a** UPSC aspirant,
**I want** to sign up and log in using Google OAuth, Email, or Phone,
**so that** I can access personalized study materials and track my progress securely.

#### Acceptance Criteria

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

### Story 1.3: Database Schema - Core Tables

**As a** backend developer,
**I want** all core database tables created with proper relationships, indexes, and Row-Level Security policies,
**so that** the system can store users, subscriptions, content, and analytics securely.

#### Acceptance Criteria

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

### Story 1.4: Database Schema - Knowledge Base Tables

**As a** backend developer,
**I want** knowledge base tables (`syllabus_nodes`, `pdf_uploads`, `knowledge_chunks`) with pgvector extension configured,
**so that** the system can store and query UPSC content using semantic vector search.

#### Acceptance Criteria

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

### Story 1.5: PDF Ingestion Pipeline - Admin Upload Interface

**As an** admin,
**I want** to upload UPSC reference book PDFs through a web interface and monitor processing status,
**so that** the knowledge base expands with accurate source material for RAG retrieval.

#### Acceptance Criteria

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

### Story 1.6: PDF Processing Pipeline - Text Extraction & Chunking

**As a** background job processor,
**I want** to automatically extract text from uploaded PDFs, chunk semantically, and store in knowledge_chunks table,
**so that** the content is queryable via vector search for RAG retrieval.

#### Acceptance Criteria

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

### Story 1.7: RAG Search Engine - Semantic Query Implementation

**As a** UPSC aspirant,
**I want** to search the knowledge base using natural language queries and receive ranked results with source citations,
**so that** I can quickly find accurate answers grounded in standard UPSC books.

#### Acceptance Criteria

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

### Story 1.8: RAG Search UI - Search Interface & Results Display

**As a** UPSC aspirant,
**I want** a Google-like search interface with instant results, confidence scores, and source citations,
**so that** I can trust the answers and verify information in standard books.

#### Acceptance Criteria

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

### Story 1.9: Trial & Subscription Logic Implementation

**As a** UPSC aspirant,
**I want** to automatically receive a 7-day free trial with full Pro access upon signup,
**so that** I can evaluate all premium features before deciding to subscribe.

#### Acceptance Criteria

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

### Story 1.10: Health Check Dashboard & System Monitoring

**As a** developer,
**I want** a public health-check endpoint and internal system status dashboard,
**so that** I can monitor service availability, database connectivity, and VPS service health.

#### Acceptance Criteria

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

## Epic 2: Core Learning Features - Discovery & Notes

**Epic Goal:**
Deliver the core learning discovery experience through interactive 3D syllabus navigation, multi-level notes generation, and RAG-powered search, enabling students to explore the entire UPSC syllabus, generate comprehensive study materials, and search accurately across curated knowledge base with source citations. By the end of this epic, users shall have complete syllabus visibility with progress tracking, AI-generated notes at 3 depth levels (100/250/500 words), and Google-like search with confidence scoring—all leveraging the RAG infrastructure from Epic 1.

### Story 2.1: Interactive 3D Syllabus Navigator - UI Implementation

**As a** UPSC aspirant,
**I want** to explore the complete UPSC syllabus (GS1-4, CSAT, Essay) in a visual 3D tree with zoomable nodes and progress rings,
**so that** I can understand the syllabus structure, navigate to topics, and track my learning progress visually.

#### Acceptance Criteria

1. 3D visualization implemented using React Three Fiber with syllabus tree hierarchy (Papers → Sections → Topics → Sub-topics)
2. Nodes display: topic name, icon, progress ring (0-100%), confidence color (red/yellow/green)
3. Click node opens topic detail modal: description, related notes/videos/PYQs, "Start Learning" button
4. Sidebar filters: checkboxes for papers (GS1, GS2, GS3, GS4, CSAT, Essay), subjects (Polity, History, Geography, etc.)
5. Search bar filters visible nodes: type "Polity" highlights matching nodes
6. Zoom controls: mouse scroll, pinch-to-zoom on mobile, reset button
7. Bookmark functionality: star icon on each node, "My Bookmarks" filter shows starred nodes
8. Performance: 60fps rendering with 1000+ nodes, lazy load sub-nodes on expand
9. 2D fallback view for older devices (toggle in settings)
10. Progress data fetched from `user_progress` table, updates real-time when user completes content

---

### Story 2.2: Syllabus Navigator - Progress Tracking & Analytics

**As a** UPSC aspirant,
**I want** the syllabus navigator to display my study time, quiz scores, and completion status per topic,
**so that** I can identify weak areas and prioritize my study plan.

#### Acceptance Criteria

1. Node tooltip on hover shows: time spent (hours:minutes), last studied date, quiz average score
2. Heatmap color coding: green (80%+ completion), yellow (40-79%), red (<40%), gray (not started)
3. Progress ring animates when updated (smooth transition, confetti on 100% completion)
4. "My Progress" sidebar panel: total syllabus completion %, subjects breakdown bar chart, weakest 5 topics list
5. Filter by progress: "Not Started", "In Progress", "Completed", "Needs Revision"
6. Export progress report as CSV: columns (topic, completion%, time_spent, confidence_score)
7. Database queries optimized: single query fetches all progress for current user's syllabus view (<300ms)
8. Real-time updates: WebSocket or polling refreshes progress every 30s while dashboard open
9. Goal-setting feature: user sets target completion date, dashboard shows "on track" or "behind schedule"
10. Mobile-optimized: simplified heatmap view, swipe gestures to navigate tree

---

### Story 2.3: Notes Generator - Multi-Level Text Synthesis

**As a** UPSC aspirant,
**I want** to generate notes at 3 levels (summary, detailed, comprehensive) for any syllabus topic,
**so that** I can study according to my depth requirement and time availability.

#### Acceptance Criteria

1. "Generate Notes" button on every syllabus topic detail modal
2. User selects level: Summary (100 words), Detailed (250 words), Comprehensive (500 words)
3. Edge Function: `generate_notes_pipe.ts` calls Notes Generator VPS service (`http://89.117.60.144:8104/generate_notes`)
4. RAG retrieval: fetch top 5 knowledge chunks matching topic from `knowledge_chunks` table
5. LLM synthesis: GPT-4 Turbo generates notes grounded in RAG chunks with citations
6. Notes include: key points (bullets), definitions, examples, UPSC relevance, related topics (cross-links)
7. Source citations appended: "Sources: [Book Title], Chapter X; [NCERT Class Y], Unit Z"
8. Notes saved to `comprehensive_notes` table with metadata: topic_id, level, content, created_at
9. Generation time <10 seconds for summary, <20 seconds for comprehensive (P95)
10. Error handling: if confidence <70%, display warning "Limited source material available for this topic"

---

### Story 2.4: Notes Generator - Manim Diagram Integration

**As a** UPSC aspirant,
**I want** AI-generated notes to include visual diagrams and flowcharts,
**so that** I can understand complex concepts through visual explanations alongside text.

#### Acceptance Criteria

1. Notes Generator analyzes content and identifies visualizable elements (timelines, processes, hierarchies, comparisons)
2. Manim scene specifications generated: JSON schema with scene type (timeline, flowchart, hierarchy, cycle), elements, colors
3. VPS Manim Renderer called: `POST http://89.117.60.144:5555/render` with scene JSON
4. Diagram rendered as PNG (for notes) and MP4 (for video shorts)
5. Diagrams embedded in notes at relevant positions (after key points)
6. Notes PDF export includes diagrams with proper layout
7. Diagram caching: identical scene specs reuse cached renders (check `manim_scene_cache` table)
8. Fallback: if Manim render fails, notes proceed without diagram, log warning
9. User can click diagram in notes to open fullscreen viewer with zoom/pan
10. Mobile-optimized: diagrams scale responsively, SVG format preferred for crisp rendering

---

### Story 2.5: Notes Generator - 60-Second Video Summary

**As a** UPSC aspirant,
**I want** each note to have an optional 60-second animated video summary,
**so that** I can quickly revise topics through video before reading full notes.

#### Acceptance Criteria

1. "Generate Video Summary" checkbox on notes generation form (Pro users only)
2. Video script generated from comprehensive notes: extract 3-4 key points, 150-200 words
3. Manim scenes generated for 1-2 critical visuals (reuse from notes diagrams if available)
4. TTS audio generated: ElevenLabs API with selected voice (user preference from profile)
5. Revideo composition: `NotesSummaryTemplate` assembles script, TTS, Manim clips, transitions
6. Video rendered via VPS Video Orchestrator: `http://89.117.60.144:8103/render`
7. Video uploaded to Supabase Storage: `videos/notes-summaries/{note_id}.mp4`
8. Render time <60 seconds (P95), job queued with priority "high"
9. Video player embedded in notes view: autoplay on note open, controls (pause, speed, seek)
10. Video linked to note record: `comprehensive_notes.summary_video_url` column updated

---

### Story 2.6: Notes Library - Organization & Export

**As a** UPSC aspirant,
**I want** a centralized notes library where I can browse, search, and export all my generated notes,
**so that** I can organize my study materials and access them offline.

#### Acceptance Criteria

1. Notes Library page: `/notes` route with grid view of note cards
2. Card displays: topic title, level badge, thumbnail (first diagram or placeholder), created date, "View" button
3. Filters: subject dropdown, paper dropdown, level checkboxes, date range picker
4. Search bar: full-text search across note content using PostgreSQL `tsvector`
5. Sorting: by date (newest/oldest), topic (alphabetical), level (summary first)
6. Pagination: 20 notes per page, infinite scroll on mobile
7. Bulk actions: select multiple notes, bulk export as ZIP (all PDFs), bulk delete
8. Individual note export: PDF download button generates PDF with proper formatting (headings, bullets, diagrams)
9. Markdown export: download as `.md` file with cross-links preserved as markdown links
10. Offline access (PWA): downloaded notes cached for offline viewing, sync indicator shows cached status

---

### Story 2.7: RAG Search - Advanced Features & Filters

**As a** UPSC aspirant,
**I want** advanced search capabilities with filters by subject, paper, book, and date range,
**so that** I can find precise information from specific sources quickly.

#### Acceptance Criteria

1. Advanced filters panel (collapsible sidebar on search page)
2. Subject filter: multi-select checkboxes (Polity, History, Geography, Economy, Science, Ethics, Essay, CSAT)
3. Paper filter: multi-select (GS1, GS2, GS3, GS4, CSAT, Essay)
4. Source type filter: NCERT, Standard Books, Government Reports, Daily Updates
5. Book filter: dropdown populated from `pdf_uploads.book_title` (distinct values)
6. Date range filter: content updated between start and end dates
7. Search within results: second search bar filters already fetched results client-side
8. Save search: "Save this search" button stores query + filters to `saved_searches` table
9. Saved searches accessible from dropdown: "My Saved Searches" with quick-apply buttons
10. Filter state persisted in URL query params: shareable search URLs, back button works correctly

---

### Story 2.8: RAG Search - Video Explanation Generation

**As a** Pro UPSC aspirant,
**I want** to generate on-demand video explanations for complex search results,
**so that** I can understand difficult topics through visual narration instead of just reading.

#### Acceptance Criteria

1. "Explain with Video" button on each search result (Pro badge displayed, Free users see upgrade prompt)
2. Entitlement check: verify user subscription status, block if Free tier
3. Click button opens modal: "Generating video explanation... This will take ~60 seconds"
4. Script generated from search result content + related chunks (expand context to 1000 words)
5. Manim scenes generated for key concepts (max 2-3 visuals per video)
6. TTS narration with selected voice, video assembled via Revideo
7. Job queued to VPS Video Orchestrator with priority "medium", job_id returned to client
8. Client polls job status: `GET /api/jobs/{job_id}` every 5 seconds until status = 'completed'
9. Video player loads when ready, thumbnail preview while processing
10. Video saved to user's library: linked in `user_videos` table, accessible from dashboard "My Videos" section

---

### Story 2.9: Notes Export - PDF Formatting & Branding

**As a** UPSC aspirant,
**I want** exported note PDFs to be professionally formatted with branding, page numbers, and table of contents,
**so that** I can print and bind them as physical study material.

#### Acceptance Criteria

1. PDF generation using `@react-pdf/renderer` library (server-side in Edge Function)
2. Cover page: UPSC AI Mentor logo, note title, topic name, generation date, user name
3. Table of contents: auto-generated from note headings (H1, H2), clickable links to sections
4. Page layout: A4 size, 1-inch margins, header (topic name), footer (page number, "upsc-ai-mentor.com")
5. Typography: Inter font (body), Satoshi font (headings), 12pt body text, 16pt headings
6. Diagrams: high-resolution PNG embedded at full width, captions below
7. Citations section: all sources listed at end with hyperlinks
8. Watermark (optional): "Generated by UPSC AI Mentor" in footer (Pro users can disable)
9. Export options: single note PDF, bulk export (ZIP of multiple PDFs), combined PDF (all notes in one file)
10. Generation time <5 seconds per note, download starts automatically, progress bar shown for bulk exports

---

### Story 2.10: Daily Notes vs. Permanent Notes - Categorization

**As a** UPSC aspirant,
**I want** my notes categorized into permanent study notes and daily current affairs notes,
**so that** I can separate static syllabus content from dynamic daily updates.

#### Acceptance Criteria

1. Notes categorized in database: `comprehensive_notes.note_type` enum ('syllabus', 'daily_update', 'user_custom')
2. Notes Library tabs: "Syllabus Notes", "Daily Updates", "My Custom Notes"
3. Daily update notes auto-generated from daily current affairs: linked to `daily_updates` table entries
4. Daily notes display date badge: "Updated: 23 Dec 2025", auto-archive after 90 days
5. Syllabus notes linked to syllabus_nodes: display syllabus path breadcrumb (GS2 → Polity → Indian Constitution)
6. Custom notes: user can create blank notes manually, free-form editor (rich text)
7. Filter by note type: checkboxes apply to visible notes
8. Search respects note type: option to "Search only syllabus notes" or "Search only daily updates"
9. Archived daily notes accessible via "Archives" section, not shown in main library by default
10. Bulk operations respect categories: can bulk-export only daily updates or only syllabus notes

---

## Epic 3: Video Generation Pipeline - Daily Current Affairs

**Epic Goal:**
Build the complete automated daily current affairs video newspaper pipeline that scrapes whitelisted UPSC-relevant news sources by 5 AM IST, generates script with topic segmentation (Economy, Polity, IR, Environment), renders 5-8 minute video with Manim diagrams and Revideo assembly, publishes video by 6 AM IST, and provides downloadable PDF summary with 5 MCQs. This epic establishes the core video generation infrastructure (Manim + Revideo pipeline) reused across all video features, achieving ≥95% on-time delivery rate with <5% failure requiring manual fallback.

### Story 3.1: Daily News Scraper - Source Integration

**As a** system administrator,
**I want** automated daily scraping of whitelisted UPSC news sources with deduplication and relevance filtering,
**so that** current affairs videos contain only high-quality, UPSC-relevant content from trusted sources.

#### Acceptance Criteria

1. Edge Function scheduled via pg_cron: `daily_news_scraper` runs at 5:00 AM IST daily
2. Whitelisted sources scraped: visionias.in, drishtiias.com, thehindu.com, pib.gov.in, forumias.com, insightsonindia.com, iasbaba.com, iasscore.in (RSS feeds + API where available)
3. DuckDuckGo Search Service called for targeted queries: `POST http://89.117.60.144:8102/search` with domain filters
4. Article extraction: title, summary, body text, published date, source URL, category tags
5. Relevance filtering: LLM classifies each article (UPSC-relevant: yes/no, subjects: [Polity, Economy, etc.], papers: [GS1-4])
6. Deduplication: cosine similarity on embeddings, merge articles >90% similar
7. Articles saved to `daily_updates` table: status = 'pending_video', article_text, metadata
8. Rate limiting: max 5 requests/second per source, retry with exponential backoff on failure
9. Monitoring: log article counts, sources success/failure, total runtime (<30 minutes)
10. Fallback: if scraper fails, alert admin, use previous day's backup content

---

### Story 3.2: Daily CA Script Generator - Segmentation & Summarization

**As a** system,
**I want** to automatically generate a structured video script from scraped articles with topic segmentation and UPSC-specific insights,
**so that** daily current affairs videos are concise, exam-focused, and easy to follow.

#### Acceptance Criteria

1. Edge Function: `generate_ca_script_pipe.ts` triggered after scraper completes (database trigger or cron at 5:15 AM)
2. Articles fetched from `daily_updates` where date = today and status = 'pending_video'
3. Topic segmentation: LLM groups articles into 4-6 segments (Economy, Polity, International Relations, Environment, Science & Tech, Social Issues)
4. Each segment: 60-120 seconds, max 3 articles per segment
5. Script structure: intro (15s) → segment 1 → segment 2 → ... → conclusion with MCQ preview (15s)
6. RAG integration: retrieve related knowledge chunks for context (e.g., article on Budget 2025 → fetch "Fiscal Policy" notes)
7. UPSC relevance markers: script highlights "Prelims relevance", "Mains angle", "Essay connection"
8. Script saved to `video_renders` table: content_type = 'daily_ca', script_json, status = 'pending_manim'
9. Total word count: 800-1200 words (5-8 minutes at 150 words/minute)
10. Quality check: if <3 UPSC-relevant articles found, flag for manual review

---

### Story 3.3: Manim Scene Generation - Visual Assets

**As a** video producer,
**I want** Manim to automatically generate animated diagrams, maps, and timelines for current affairs topics,
**so that** videos are visually engaging and aid comprehension of complex topics.

#### Acceptance Criteria

1. Manim Scene Analyzer: LLM identifies visualizable elements in script (timelines, maps, bar charts, flowcharts, comparisons)
2. Scene specifications generated: JSON array with scene type, data, styling (max 8 scenes per video)
3. Scene types supported: timeline (events with dates), map (countries/regions highlighted), bar chart (statistics), flowchart (process steps), split screen (before/after comparison)
4. VPS Manim Renderer called: `POST http://89.117.60.144:5555/render` with scene JSON array
5. Each scene rendered as MP4 clip (1080p, 30fps, 5-15 seconds duration)
6. Scene caching: check `manim_scene_cache` table for identical scene specs, reuse if exists
7. Render parallelization: up to 4 scenes rendered simultaneously
8. Rendered clips uploaded to Supabase Storage: `videos/manim-scenes/{video_id}/{scene_index}.mp4`
9. Render time: <2 minutes for all scenes (P95)
10. Fallback: if Manim render fails, use static images or proceed without visual (log warning)

---

### Story 3.4: Revideo Video Assembly - Final Composition

**As a** video producer,
**I want** Revideo to assemble script, TTS audio, Manim scenes, and transitions into final daily CA video,
**so that** the complete video is rendered and ready for publishing by 6 AM IST.

#### Acceptance Criteria

1. Edge Function: `assemble_ca_video_pipe.ts` triggered after Manim scenes complete
2. TTS audio generated: ElevenLabs API with default voice (configurable in settings), script text → audio MP3
3. Audio segments timed: map each script segment to audio timestamp
4. Revideo composition: `DailyCATemplate` React component receives props (script, audio_url, manim_scene_urls, topic_timestamps)
5. Video structure: title card (5s) → intro (audio + text overlay) → segments (audio + Manim scenes + captions) → outro (5s)
6. Transitions: smooth fade between segments, animated topic headers
7. Captions: auto-generated SRT from script, burned into video (accessibility)
8. VPS Video Orchestrator renders Revideo composition: `POST http://89.117.60.144:8103/render`
9. Final video uploaded to Supabase Storage: `videos/daily-ca/{YYYY-MM-DD}.mp4`, CDN URL generated
10. Render time: <5 minutes (P95), status updated to 'completed' in `video_renders` table

---

### Story 3.5: Daily CA Video Publishing & Notification

**As a** UPSC aspirant,
**I want** to receive notification when daily current affairs video is published by 6 AM,
**so that** I can watch it during my morning study routine.

#### Acceptance Criteria

1. Video published automatically: `video_renders.status = 'published'`, `published_at = NOW()`
2. Video visible on dashboard: hero card "Today's Current Affairs" with thumbnail, duration, "Watch Now" button
3. Push notifications sent: all users with notifications enabled receive alert "Today's CA video is ready!"
4. Email digest (optional): users subscribed to email receive HTML email with video embed link
5. Social media auto-post (admin controlled): Twitter/X, LinkedIn posts with video link and key topics hashtags
6. Archive page: `/daily-ca` route lists all past videos in calendar view
7. Video metadata: view count, completion rate, average watch time tracked in `video_analytics` table
8. Thumbnail auto-generated: first frame of video or custom thumbnail from Manim title card
9. SEO optimization: video page has meta tags (title, description, OG image) for sharing
10. Monitoring: alert admin if video not published by 6:30 AM (grace period for delays)

---

### Story 3.6: Daily CA PDF Summary & MCQ Generation

**As a** UPSC aspirant,
**I want** a downloadable PDF summary of daily current affairs with 5 practice MCQs,
**so that** I can review in text format and test my understanding.

#### Acceptance Criteria

1. PDF generated automatically after video publish: triggered by status change to 'published'
2. PDF structure: cover page (date, logo) → summary (topic-wise bullets, 2-3 pages) → MCQs (5 questions, 4 options each, answers at end)
3. Summary bullets: 3-5 key points per topic segment, includes "Prelims relevance" and "Mains angle" markers
4. MCQs auto-generated: LLM creates fact-based questions from article content, distractor options, difficulty = medium
5. Answer key: last page with explanations (1-2 lines per answer)
6. PDF formatting: consistent branding (colors, fonts, header/footer), A4 size, printable
7. PDF uploaded to Supabase Storage: `pdfs/daily-ca/{YYYY-MM-DD}.pdf`
8. Download button visible on video page and dashboard card
9. Monthly compilation: on 1st of month, auto-generate combined PDF of all previous month's daily PDFs (100+ pages)
10. Generation time: <30 seconds (P95), cached for repeated downloads

---

### Story 3.7: 60-Second Social Media Shorts Generator

**As a** marketing team member,
**I want** automatic generation of 60-second shorts from daily CA video for social media,
**so that** we can promote the platform and drive signups through viral content.

#### Acceptance Criteria

1. Shorts extracted from main video: identify 2-3 high-impact segments (based on topic importance scores)
2. Each short: 45-60 seconds, self-contained (intro + content + CTA)
3. Aspect ratios: 16:9 (YouTube), 9:16 (Instagram Reels, TikTok), 1:1 (LinkedIn, Twitter)
4. Revideo compositions: `ShortTemplate` with vertical layout, large captions, branding watermark
5. Shorts saved to Supabase Storage: `videos/shorts/{date}-{segment}-{ratio}.mp4`
6. Admin dashboard: `/admin/shorts` page lists generated shorts with preview, download, schedule post buttons
7. Auto-thumbnails: extract frame at 3-second mark, add text overlay with topic name
8. Captions optimized: larger font size (readable on mobile), emoji markers for emphasis
9. CTA end card: "Full video link in bio" + QR code + app logo (5 seconds)
10. Generation time: <2 minutes for all 3 aspect ratios (P95)

---

### Story 3.8: Daily CA Cron Job & Error Handling

**As a** system administrator,
**I want** robust error handling and alerting for the daily CA pipeline,
**so that** failures are detected immediately and backup plans executed.

#### Acceptance Criteria

1. pg_cron job scheduled: `0 5 * * *` (5 AM IST daily), job name = 'daily_ca_pipeline'
2. Pipeline stages logged: scraper → script → manim → remotion → publish, each with timestamp and status
3. Stage-level retries: if stage fails, retry 3 times with 2-minute delays
4. Graceful degradation: if Manim fails, proceed with static images; if TTS fails, use backup voice
5. Alert triggers: if video not published by 6:30 AM, send email + Slack alert to admin
6. Manual override: admin can trigger pipeline manually via `/admin/daily-ca/trigger` button
7. Logs viewable in admin dashboard: `/admin/daily-ca/logs` with filter by date, stage, status
8. Health check endpoint: `GET /api/daily-ca/status` returns latest video status and pipeline health
9. Rollback mechanism: if video has critical errors, admin can "unpublish" and fix, re-publish
10. SLA tracking: dashboard shows % of on-time deliveries (target ≥95%), downtime alerts if <90%

---

### Story 3.9: Daily CA Archive & Search

**As a** UPSC aspirant,
**I want** to browse and search past daily current affairs videos by date, topic, and subject,
**so that** I can revisit important news and revise before exams.

#### Acceptance Criteria

1. Archive page: `/daily-ca/archive` with calendar view (month grid, dates with videos highlighted)
2. Click date opens video detail page: video player, PDF download, MCQ quiz, related articles links
3. Filter by subject: checkboxes (Economy, Polity, IR, Environment, etc.), applies to visible videos
4. Search bar: full-text search across video scripts and article text
5. Date range picker: select start and end dates, show matching videos
6. List view toggle: switch between calendar and list view (cards with thumbnails)
7. Pagination: 30 videos per page in list view
8. Bulk download: select multiple dates, download ZIP of PDFs or videos
9. Watchlist: users can star important videos, accessible from "My Watchlist"
10. Performance: archive page loads <2 seconds with 365 days of data

---

### Story 3.10: Monthly CA Compilation - Documentary Format

**As a** UPSC aspirant,
**I want** a monthly compiled documentary-style video (30-45 minutes) summarizing the month's key current affairs,
**so that** I can efficiently revise an entire month's content in one session.

#### Acceptance Criteria

1. Monthly compilation triggered on 1st of each month: Edge Function `generate_monthly_compilation_pipe.ts`
2. Content aggregation: all daily CA videos from previous month analyzed for top 20 topics (by importance, repeat mentions)
3. Script generated: 30-45 minute narrative connecting topics chronologically and thematically
4. Documentary structure: intro (month overview) → weekly breakdowns → subject-wise deep dives → conclusion (key takeaways)
5. Manim visuals: monthly trend graphs, comparative timelines, topic relationship maps
6. TTS narration: professional documentary-style voice (slower pace, dramatic pauses)
7. Revideo assembly: `MonthlyCompilationTemplate` with chapter markers, smooth transitions, background music
8. Chapters embedded: video has 8-12 chapters (clickable in player)
9. PDF booklet: 100+ page comprehensive notes with all month's content, formatted for printing/binding
10. Publishing: available by 3rd of month, prominent banner on dashboard "January 2025 Compilation Ready!"

---

## Epic 4: On-Demand Video Learning - Doubt Converter & Topic Shorts

**Epic Goal:**
Enable real-time doubt-to-video conversion and 60-second topic shorts generation, providing on-demand personalized video explanations for any UPSC topic or user question within 60-120 seconds. This epic leverages the video pipeline from Epic 3 but optimizes for speed with shorter videos, cached components, and priority queuing. By the end of this epic, Pro users can convert text/image doubts into 60-180 second explainer videos and generate instant 60s shorts for any syllabus topic, establishing the platform's core differentiation of on-demand visual learning.

### Story 4.1: Doubt Submission Interface - Text & Image Input

**As a** UPSC aspirant,
**I want** to submit doubts via text, voice, or screenshot image,
**so that** I can get video explanations for any question regardless of input format.

#### Acceptance Criteria

1. Doubt submission page: `/ask-doubt` with prominent input area (autofocus on load)
2. Input methods: text area (2000 char limit), image upload (drag-drop or camera), voice recording (60s max, browser MediaRecorder API)
3. Image upload: accept PNG, JPG, PDF; max 10MB; preview thumbnail displayed
4. OCR processing: if image uploaded, extract text using Tesseract.js (client-side) or Cloud Vision API (server-side)
5. Voice transcription: audio sent to Whisper API (OpenAI) for speech-to-text
6. Style selector: radio buttons (Concise, Detailed, Example-Rich), default = Detailed
7. Video length selector: 60s, 120s, 180s (Pro users only for 180s)
8. Voice preference: dropdown (male/female, accent options), uses user's profile default
9. Preview mode: show extracted text from image/voice before submission, allow edits
10. Entitlement check: Free users limited to 3 doubts/day, Trial/Pro unlimited, show usage counter

---

### Story 4.2: Doubt Processing Pipeline - Script Generation

**As a** system,
**I want** to analyze doubt input using RAG retrieval and generate a structured video script,
**so that** video explanations are accurate, grounded in UPSC sources, and appropriately detailed.

#### Acceptance Criteria

1. Edge Function: `doubt_video_converter_pipe.ts` at endpoint `POST /api/doubts/create`
2. Request payload: `{ doubt_text, style, length, voice, user_id }`
3. Content safety filter: check for NSFW/harmful content, block if flagged
4. RAG retrieval: query `knowledge_chunks` with doubt text, fetch top 5 relevant chunks (confidence >0.70)
5. If confidence <0.70, return warning modal: "Limited source material. Video may not be fully accurate. Proceed?"
6. Script generation: LLM synthesizes answer from RAG chunks, structured as intro → explanation → example → conclusion
7. Script length calibrated: 150 words for 60s, 300 words for 120s, 450 words for 180s
8. Style variations applied: Concise (bullets, minimal examples), Detailed (full explanations), Example-Rich (2-3 case studies)
9. Script saved to `video_renders` table: content_type = 'doubt_video', script_json, status = 'pending_manim'
10. Job ID returned to client: `{ job_id, estimated_time: 60 }`, client polls status

---

### Story 4.3: Doubt Video - Manim Scene Generation (Optimized)

**As a** video producer,
**I want** Manim to generate diagrams for doubts within 15-20 seconds,
**so that** total video generation stays under 60 seconds for user satisfaction.

#### Acceptance Criteria

1. Manim scene specs generated: max 2 scenes per doubt video (complexity constraint)
2. Scene types prioritized for speed: simple diagrams (2D shapes, arrows), text animations, timeline (if applicable)
3. Cache-first strategy: check `manim_scene_cache` for similar scene specs (fuzzy match with 80% similarity)
4. If cache hit, reuse scene; if cache miss, render new scene
5. VPS Manim Renderer optimized: use pre-warmed render workers, priority queue for doubt videos
6. Render time target: <15 seconds per scene (P95)
7. Parallel rendering: both scenes render simultaneously if 2 scenes needed
8. Fallback: if render exceeds 20s, skip Manim scene and use text-only video (inform user)
9. Rendered clips uploaded to Supabase Storage: `videos/manim-scenes/doubts/{job_id}/{scene_index}.mp4`
10. Status updated: `video_renders.status = 'pending_remotion'`

---

### Story 4.4: Doubt Video - Revideo Assembly (Optimized)

**As a** video producer,
**I want** Revideo to assemble doubt videos within 30-40 seconds,
**so that** users receive video explanations in under 60 seconds total.

#### Acceptance Criteria

1. TTS audio generated: ElevenLabs API with user's selected voice, script → MP3
2. Audio generation time: <10 seconds (use Turbo models)
3. Revideo composition: `DoubtVideoTemplate` receives props (script, audio_url, manim_scene_urls, style)
4. Template variations: Concise (minimal transitions, fast pace), Detailed (slower pace, pauses), Example-Rich (more visuals)
5. Captions: auto-generated from script, burned into video
6. Branding: small logo watermark, end card with "Ask more doubts on UPSC AI Mentor" (3s)
7. VPS Video Orchestrator: priority queue for doubt videos (higher priority than daily CA)
8. Render time target: <30 seconds (P95)
9. Video uploaded to Supabase Storage: `videos/doubts/{job_id}.mp4`
10. Status updated: `video_renders.status = 'completed'`, notification sent to client

---

### Story 4.5: Doubt Video - Response Interface & Player

**As a** UPSC aspirant,
**I want** to see my doubt video as soon as it's ready with options to download, share, and provide feedback,
**so that** I can immediately learn from the explanation and revisit it later.

#### Acceptance Criteria

1. Client polls job status: `GET /api/jobs/{job_id}` every 3 seconds while status = 'processing'
2. Progress indicator: animated progress bar with stages (Analyzing → Generating Script → Creating Visuals → Assembling Video)
3. Video player loads when status = 'completed': autoplay enabled, controls (pause, speed 0.5x-2x, seek, fullscreen)
4. Below video: collapsible transcript, source citations ("Based on Laxmikanth Polity, Chapter 5"), related topics links
5. Action buttons: Download video, Share link (generates shareable URL), Report issue, Ask follow-up
6. Feedback: thumbs up/down, optional comment box ("Was this helpful?"), sentiment saved for analytics
7. Short notes: auto-generated bullet summary (5-7 points) displayed alongside video
8. Mini-quiz: 3 MCQs based on doubt topic, instant feedback on answers
9. Video saved to user's history: accessible from "My Doubts" page (ordered by recent)
10. Performance: video starts playing within 1s of status = 'completed'

---

### Story 4.6: 60-Second Topic Shorts - On-Demand Generation

**As a** UPSC aspirant,
**I want** to generate 60-second explainer videos for any syllabus topic instantly,
**so that** I can quickly understand concepts without reading long notes.

#### Acceptance Criteria

1. "Generate Short" button on every syllabus node detail modal and notes page
2. Click button opens confirmation modal: "Generate 60s video for [Topic Name]? (Uses 1 credit)" (Free users see upgrade prompt)
3. Edge Function: `generate_topic_short_pipe.ts` at `POST /api/shorts/create`
4. Script generated from topic notes (if exists) or RAG retrieval (if no notes)
5. Script structure: hook (5s) → definition (10s) → key points (35s) → UPSC relevance (10s)
6. Manim scene: 1 simple visual (definition diagram or process flowchart)
7. TTS audio: upbeat voice, faster pace (165 words/minute vs 150 standard)
8. Revideo composition: `TopicShortTemplate` with dynamic text overlays, emoji markers, energetic transitions
9. Video rendered in 16:9, 9:16, 1:1 aspect ratios simultaneously
10. Generation time: <45 seconds (P95), status polling same as doubts

---

### Story 4.7: Topic Shorts - Social Sharing & Viral Features

**As a** UPSC aspirant,
**I want** to share topic shorts on social media with branded watermark and call-to-action,
**so that** I can help peers and promote the platform organically.

#### Acceptance Criteria

1. Share button on short video player: opens modal with social network icons (WhatsApp, Twitter, LinkedIn, Instagram, Telegram)
2. Watermark embedded: "Generated by UPSC AI Mentor - upsc-ai-mentor.com" in corner (subtle, non-intrusive)
3. End card (last 5 seconds): CTA "Want full explanation? Link in bio" + QR code + logo
4. Shareable link generated: `https://upsc-ai-mentor.com/shorts/{short_id}` (public, no login required for viewing)
5. Link preview: video thumbnail, title "Learn [Topic] in 60s", description with hashtags
6. WhatsApp share: direct video file sent (compressed to <5MB), fallback to link if larger
7. Instagram format: 9:16 ratio optimized for Reels, caption auto-populated with hashtags
8. Twitter/X: video uploaded directly via API (with user permission), tweet text includes topic + hashtags
9. Download options: download video file (watermarked), download thumbnail (for custom posts)
10. Analytics tracked: shares count, views via shareable link, conversion to signups (UTM tracking)

---

### Story 4.8: Doubt & Short Credits System

**As a** product manager,
**I want** a credit-based system for doubt videos and topic shorts to monetize and manage usage,
**so that** we can sustain AI costs while offering fair access to users.

#### Acceptance Criteria

1. Credit allocation: Free (3 doubts/day, 2 shorts/day), Trial (unlimited), Pro Monthly (unlimited), Pro Annual (unlimited + priority queue)
2. Credits reset: daily at midnight IST for Free users
3. Credit counter displayed: header badge "3 doubts left today", updated real-time after each use
4. Purchase credits: Free users can buy credit packs (10 doubts = ₹99, 50 doubts = ₹399), payment via Razorpay
5. Credits table: `user_credits` with columns (user_id, credit_type, balance, expires_at)
6. Credit deduction: atomic transaction (check balance → deduct → create video job), rollback if job fails
7. Usage analytics: admin dashboard shows credits usage per user, most common doubt topics, conversion to Pro
8. Upgrade prompts: when Free user exhausts credits, show modal "Upgrade to Pro for unlimited doubts + faster generation"
9. Refund policy: if video generation fails after credit deducted, refund credit automatically
10. Expiry: purchased credits valid for 90 days, expiring credits flagged in user dashboard

---

### Story 4.9: Doubt Video Queue Management & Prioritization

**As a** system administrator,
**I want** intelligent queue management prioritizing Pro users and optimizing resource utilization,
**so that** we deliver the best experience to paying users while maintaining fairness.

#### Acceptance Criteria

1. Job queue table: `jobs` with columns (job_id, user_id, job_type, priority, status, created_at, started_at, completed_at)
2. Priority levels: Critical (admin manual), High (Pro Annual), Medium (Pro Monthly, Trial), Low (Free)
3. Queue processor: picks jobs by priority (high first), then FIFO within same priority
4. Concurrency limits: max 10 doubt videos rendering simultaneously, max 5 topic shorts
5. If queue exceeds 50 pending jobs, throttle Free user submissions (show "High demand, try again in 5 min")
6. Estimated wait time calculated: based on queue position and average render time, displayed to user
7. Job timeout: if job processing exceeds 5 minutes, mark as failed, alert admin, refund credits
8. Dead letter queue: failed jobs moved to separate table for manual review and retry
9. Monitoring dashboard: `/admin/video-queue` shows real-time queue status, success/fail rates, bottlenecks
10. Auto-scaling: if queue consistently >30 jobs, trigger alert to provision additional VPS render workers

---

### Story 4.10: Doubt History & Follow-Up Questions

**As a** UPSC aspirant,
**I want** to view my doubt history and ask follow-up questions linked to previous doubts,
**so that** I can build on my understanding and track my learning journey.

#### Acceptance Criteria

1. My Doubts page: `/my-doubts` lists all past doubts with filters (date, subject, status)
2. Card displays: doubt text (truncated), topic, video thumbnail, created date, status badge
3. Click card opens detailed view: full doubt text, video player, transcript, notes, quiz results
4. Follow-up button: opens new doubt submission form with context pre-filled ("Following up on: [previous doubt]")
5. Thread view: if follow-up exists, display as threaded conversation (parent doubt → child doubts)
6. Search doubts: full-text search across all doubt text and transcripts
7. Bookmark doubts: star icon to mark important doubts, filter by bookmarked
8. Export history: download CSV with all doubts, topics, dates, video links
9. Delete doubts: user can delete individual doubts (video deleted from storage, credits not refunded)
10. Analytics: personal stats shown (total doubts asked, topics covered, most asked subjects)

---

## Epic 5: Monetization & Subscription System

**Epic Goal:**
Implement comprehensive monetization infrastructure including trial logic (7 days full access), RevenueCat integration for subscription management (Monthly ₹599, Quarterly ₹1499, Half-Yearly ₹2699, Annual ₹4999), entitlement checks on all premium features, Razorpay payment gateway, coupon system, and admin revenue dashboard. By the end of this epic, the platform shall have fully functional payment flows, trial-to-paid conversion tracking, and granular entitlement enforcement ensuring sustainable revenue generation while maintaining excellent user experience during trial and post-purchase.

### Story 5.1: RevenueCat Integration - Setup & Configuration

**As a** backend developer,
**I want** RevenueCat SDK integrated for subscription management across web and future mobile apps,
**so that** we have unified subscription state and cross-platform entitlement management.

#### Acceptance Criteria

1. RevenueCat project created: app configured for Web, iOS (future), Android (future)
2. Product IDs created in RevenueCat: `pro_monthly`, `pro_quarterly`, `pro_half_yearly`, `pro_annual`
3. Entitlements configured: `pro_access` (grants access to all premium features)
4. RevenueCat Web SDK installed: `@revenuecat/purchases-js` in frontend
5. Backend integration: RevenueCat webhook endpoint `POST /api/webhooks/revenuecat` handles events (purchase, renewal, cancellation, expiry)
6. Supabase RLS policies: `subscriptions` table enforces user can only read own subscription
7. Sync job: on webhook event, update `subscriptions` table (status, plan, expires_at, revenuecat_id)
8. Environment variables: `REVENUECAT_API_KEY`, `REVENUECAT_WEBHOOK_SECRET` configured in Supabase Secrets
9. Test mode: sandbox environment for testing purchases without real payments
10. Documentation: internal docs for adding new products and entitlements

---

### Story 5.2: Payment Gateway Integration - Razorpay

**As a** UPSC aspirant,
**I want** to subscribe to Pro plans using UPI, cards, or net banking through a secure payment gateway,
**so that** I can unlock premium features with confidence.

#### Acceptance Criteria

1. Razorpay account created: API keys obtained (test and live modes)
2. Razorpay Checkout integrated: `razorpay-web-sdk` in frontend for payment modal
3. Payment flow: user selects plan → clicks "Subscribe" → Razorpay modal opens → payment completed → subscription activated
4. Subscription plans created in Razorpay: Monthly, Quarterly, Half-Yearly, Annual with auto-debit (optional for user)
5. Payment confirmation webhook: `POST /api/webhooks/razorpay` verifies signature, creates subscription record
6. Transaction logging: all payments logged to `payment_transactions` table (txn_id, user_id, amount, status, gateway_response)
7. Failed payment handling: if payment fails, show error message, log to database, email user with retry link
8. PCI compliance: no card data stored in our database, all handled by Razorpay
9. Invoice generation: on successful payment, generate invoice PDF (company details, transaction ID, amount, GST if applicable)
10. Test payments: use Razorpay test cards for QA validation before production

---

### Story 5.3: Trial Logic - Automatic Activation & Expiry

**As a** UPSC aspirant,
**I want** a 7-day free trial with full Pro access automatically activated on signup,
**so that** I can evaluate all premium features before committing to a subscription.

#### Acceptance Criteria

1. On user signup: database trigger creates subscription record (status = 'trial', trial_started_at = NOW(), trial_expires_at = NOW() + INTERVAL '7 days')
2. Entitlement function: `checkEntitlement(user_id, feature_slug)` returns true if NOW() <= trial_expires_at
3. Trial status badge: displayed in header "Trial: 5 days left", changes to "Trial ending today" on last day
4. Email notifications: Day 1 (welcome + trial info), Day 3 (tips + feature highlights), Day 5 (2 days left + upgrade CTA), Day 7 (trial ends today + upgrade prompt)
5. Post-trial experience: on expiry, user not blocked from app, but premium features show upgrade modal
6. One trial per user: check by email and phone, prevent trial abuse (multiple signups)
7. Trial extension: admin can manually extend trial via admin panel (e.g., +3 days for user request)
8. Analytics: trial-to-paid conversion tracked (metric: % of trial users who subscribe within 7 days + 7 days post-trial)
9. Dashboard countdown: visual progress bar showing trial days remaining
10. Grace period: if user subscribes on Day 7 (last day), subscription starts immediately, no gap

---

### Story 5.4: Entitlement Checks - Feature-Level Enforcement

**As a** product manager,
**I want** granular entitlement checks on every premium feature to enforce access control,
**so that** only authorized users (Trial, Pro) can use paid features while maintaining excellent UX.

#### Acceptance Criteria

1. Feature manifest table: `feature_manifests` with columns (feature_slug, name, tier, description)
2. Tiers defined: Free, Trial, Pro Monthly, Pro Annual (some features exclusive to Annual)
3. Entitlement check function: `checkEntitlement(user_id, feature_slug)` queries `subscriptions` + `feature_manifests`
4. Returns object: `{ allowed: boolean, reason: string, show_paywall: boolean, upgrade_cta: string }`
5. Client-side: every premium feature button/page checks entitlement before rendering
6. Server-side: Edge Functions enforce entitlement before processing (e.g., doubt video creation checks entitlement first)
7. Paywall modal: shown when allowed = false, displays reason, plan comparison, "Upgrade Now" button
8. Soft paywalls: Free users see premium features grayed out with "Pro" badge, click shows upgrade modal
9. Hard blocks: API returns 403 Forbidden if entitlement check fails server-side
10. Cache entitlements: client caches entitlement state for 5 minutes, refreshes on page load or subscription change

---

### Story 5.5: Subscription Management - User Dashboard

**As a** UPSC aspirant,
**I want** to view my current subscription, billing history, and manage renewals from my profile,
**so that** I can control my subscription and access invoices.

#### Acceptance Criteria

1. Subscription page: `/settings/subscription` with current plan card (plan name, price, next billing date, status)
2. Plan details: features included (list with checkmarks), usage stats (doubts used, videos generated)
3. Billing history: table with columns (date, amount, invoice, status), download invoice button (PDF)
4. Manage subscription: "Change Plan" button (upgrade/downgrade options), "Cancel Subscription" button
5. Change plan flow: user selects new plan → confirmation modal → prorated calculation shown → confirm → updated immediately
6. Cancel flow: confirmation modal with retention offer ("Get 20% off next month if you stay") → if proceed, subscription cancels at period end (not immediately)
7. Renewal toggle: user can enable/disable auto-renewal (for Razorpay subscriptions with auto-debit)
8. Payment method: display saved payment method (last 4 digits), "Update Payment Method" button redirects to Razorpay
9. Subscription status: Active (green), Cancelled (yellow), Expired (red), Trial (blue)
10. Support link: "Having issues? Contact support" opens chat or email form

---

### Story 5.6: Pricing Page - Plan Comparison & CTA

**As a** UPSC aspirant,
**I want** a clear pricing page comparing all plans with features and benefits,
**so that** I can make an informed decision on which plan to purchase.

#### Acceptance Criteria

1. Pricing page: `/pricing` with 4-column plan comparison table
2. Plans displayed: Free, Pro Monthly (₹599), Pro Quarterly (₹1499, save 16%), Pro Annual (₹4999, save 30%)
3. Features listed: row per feature (RAG Search, Doubt Videos, Topic Shorts, Daily CA, Documentary Lectures, etc.), checkmarks/crosses per plan
4. Highlight recommended plan: Pro Monthly with "Most Popular" badge, visual emphasis (shadow, color)
5. CTA buttons: "Start Free Trial" (Free), "Subscribe Now" (paid plans), click opens payment modal
6. Billing toggle: switch between Monthly/Annual view, prices update dynamically
7. Money-back guarantee: "7-day money-back guarantee" badge on all paid plans
8. Testimonials: 3-4 user testimonials with photos, names, exam ranks below pricing table
9. FAQs section: collapsible accordion with 8-10 common questions (What's included? Can I cancel? Refund policy?)
10. Comparison calculator: "How much will you save?" slider shows savings for Annual vs Monthly over 12 months

---

### Story 5.7: Coupon & Discount System

**As a** marketing manager,
**I want** a coupon system for promotional discounts and affiliate offers,
**so that** we can run campaigns and partner with influencers for user acquisition.

#### Acceptance Criteria

1. Coupons table: `coupons` with columns (code, discount_type, discount_value, max_uses, used_count, expires_at, applicable_plans, active)
2. Discount types: percentage (10%, 20%, 50%), flat (₹100 off), free trial extension (+7 days)
3. Coupon creation: admin panel `/admin/coupons` with form to create coupons, set restrictions
4. Coupon validation: API endpoint `POST /api/coupons/validate` checks code, returns discount amount, expiry, restrictions
5. Apply coupon flow: payment modal has "Have a coupon?" field → user enters code → validate → price updates with discount shown
6. Restrictions: per-user limit (1 use per user), plan restrictions (only for Annual), first-time user only
7. Coupon analytics: admin dashboard shows coupon usage (code, uses, revenue generated, conversion rate)
8. Affiliate coupons: special codes for influencers, track referrals, calculate commission (10% of revenue)
9. Auto-apply: if user lands via affiliate link with `?coupon=XYZ`, auto-fill coupon code at checkout
10. Expiry handling: expired coupons show error "This coupon has expired", invalid codes show "Invalid coupon code"

---

### Story 5.8: Revenue Dashboard - Admin Analytics

**As a** business owner,
**I want** a comprehensive revenue dashboard showing MRR, ARR, churn, LTV, and cohort analysis,
**so that** I can track business health and make data-driven decisions.

#### Acceptance Criteria

1. Revenue dashboard: `/admin/revenue` with key metric cards (MRR, ARR, Active Subscriptions, Churn Rate, Trial-to-Paid %)
2. MRR calculation: sum of all active monthly recurring revenue (normalize quarterly/annual to monthly)
3. ARR calculation: MRR * 12
4. Churn rate: % of subscribers who cancelled in last 30 days
5. Lifetime Value (LTV): average revenue per user over their subscription lifetime
6. Growth chart: line graph showing MRR trend over last 12 months
7. Plan distribution: pie chart showing % of users on each plan (Free, Trial, Monthly, Annual)
8. Cohort analysis: table showing retention by signup month (e.g., Jan 2025 cohort: Month 0: 100%, Month 1: 85%, Month 2: 70%)
9. Revenue by source: breakdown by acquisition channel (organic, paid ads, affiliates)
10. Export data: download CSV with all transaction data, filtered by date range

---

### Story 5.9: Refund Processing & Money-Back Guarantee

**As a** UPSC aspirant,
**I want** a hassle-free refund process within 7 days if I'm not satisfied,
**so that** I can try the platform risk-free.

#### Acceptance Criteria

1. Refund policy: 7-day money-back guarantee from subscription start date (no questions asked)
2. Refund request: user clicks "Request Refund" on subscription page → confirmation modal → reason dropdown (optional)
3. API endpoint: `POST /api/refunds/request` creates refund record (user_id, subscription_id, amount, reason, status = 'pending')
4. Admin review: refunds appear in `/admin/refunds` queue, admin can approve/reject
5. Approval: if approved, Razorpay refund API called, amount credited to user's original payment method
6. Refund timeline: processed within 48 hours (business hours), user notified via email
7. Post-refund: subscription immediately cancelled, user downgraded to Free tier
8. Partial refunds: pro-rated refunds for mid-cycle cancellations (e.g., cancel on Day 15 of Monthly plan → refund 50%)
9. Refund limits: max 1 refund per user per year (prevent abuse)
10. Analytics: refund rate tracked (target <5%), reasons analyzed for product improvements

---

### Story 5.10: Institutional Licensing - Bulk Subscriptions

**As an** coaching institute owner,
**I want** to purchase bulk subscriptions for my students at discounted rates,
**so that** I can provide UPSC AI Mentor access as part of my coaching program.

#### Acceptance Criteria

1. Institutional plan: custom pricing for 50+ users (e.g., ₹300/user/month for 100 users = ₹30,000/month)
2. Admin panel: `/admin/institutions` to create institution accounts, assign licenses
3. License allocation: institution admin can invite students via email, assign licenses
4. Student activation: invited student receives email with activation link, creates account, license auto-applied
5. License management: institution admin dashboard shows licenses (total, assigned, available), usage analytics per student
6. Billing: single invoice for institution, monthly or annual payment, auto-renewal optional
7. Custom branding (optional): white-label option for large institutions (logo, colors, domain)
8. Reporting: institution admin sees aggregate analytics (students active, videos generated, topics covered, test scores)
9. License transfer: if student leaves, institution can revoke license and reassign to new student
10. Contract management: legal agreements, invoicing, support escalation handled via dedicated account manager

---

## Epics 6-16: Summary Structure

**Note to Development Team:** Epics 1-5 contain full story details for MVP implementation (Foundation, Core Learning, Daily CA Video, Doubt Converter, Monetization). Epics 6-16 below represent Post-MVP features and will be expanded into full user stories during the PO sharding process. Each epic summary includes scope, key features, and estimated story count.

---

## Epic 6: Progress Tracking & Personalization

**Epic Goal:** Build adaptive study schedule builder, comprehensive progress dashboard, smart revision booster, and confidence meter to provide personalized learning paths based on user performance data, enabling students to optimize study time and focus on weak areas.

**Features Included:**
- FR12: AI Study Schedule Builder (adaptive schedules with calendar sync)
- FR22: Ultra-Detailed Syllabus Tracking Dashboard (completion %, time tracking, analytics)
- FR23: Smart Revision Booster (auto-selects 5 weakest topics weekly)
- FR33: Concept Confidence Meter (visual confidence scoring per topic)

**Estimated Stories:** 8-10 stories covering schedule generation algorithms, progress aggregation, revision package creation, confidence scoring models, and dashboard UI/UX.

**Key Technical Requirements:**
- Real-time progress updates via Supabase Realtime
- Spaced repetition algorithm implementation
- Google Calendar API integration
- Weekly video briefings via Revideo

---

## Epic 7: Practice & Evaluation - Answer Writing & Essays

**Epic Goal:** Deliver AI-powered Mains practice tools including daily answer writing with instant scoring, essay trainer with structure analysis, and comprehensive test series platform, enabling students to practice descriptive writing with video feedback and model answer comparisons.

**Features Included:**
- FR15: AI Essay Trainer with Live Video Feedback (1000-word essays, rubric scoring)
- FR16: Daily Answer Writing + AI Scoring (150-250 word Mains answers, timed mode)
- FR27: Test Series Auto-Grader + Performance Graphs (full-length mocks, analytics)

**Estimated Stories:** 10-12 stories covering answer evaluation AI, rubric engines, video feedback generation, model answer database, timed exam interfaces, and performance analytics.

**Key Technical Requirements:**
- NLP for answer evaluation (structure, content, keywords, examples)
- Manim for structure visualization diagrams
- Topper answer database integration
- Performance trend graphing

---

## Epic 8: Practice & Evaluation - PYQs & Question Bank

**Epic Goal:** Build fully automated PYQ video explanation engine and AI question generator to provide unlimited practice questions with model answers, enabling students to master exam patterns and self-assess across all topics.

**Features Included:**
- FR13: Fully Automated PYQ Video Explanation Engine (ingest PDFs, generate video solutions)
- FR19: AI Topic-to-Question Generator (MCQs, Mains questions, auto-marking)

**Estimated Stories:** 8-10 stories covering PYQ PDF ingestion, question extraction, video solution generation, question bank creation, difficulty tagging, and practice interfaces.

**Key Technical Requirements:**
- OCR for PYQ PDF extraction
- Question classification (Prelims/Mains, subject, difficulty)
- Distractor generation for MCQs
- Answer key validation

---

## Epic 9: Advanced Learning Tools - Mindmaps, Bookmarks & Assistants

**Epic Goal:** Provide advanced study organization tools including AI mindmap builder, smart bookmark engine with cross-linking, and personalized conversational teaching assistant to enhance study efficiency and retention.

**Features Included:**
- FR20: Personalized AI Teaching Assistant (conversational tutor, context retention)
- FR21: UPSC Mindmap Builder (auto-generate from text, interactive editing)
- FR32: Smart Bookmark Engine (auto-linked notes/PYQs, revision scheduling)

**Estimated Stories:** 8-10 stories covering chatbot conversation flow, mindmap generation algorithms, bookmark auto-tagging, cross-linking logic, and collaborative features.

**Key Technical Requirements:**
- Conversation state management (multi-turn context)
- Graph visualization for mindmaps
- Spaced repetition for bookmark revisions
- Motivational video generation via Revideo

---

## Epic 10: Deep Learning Assets - Documentary Lectures & Weekly Analysis

**Epic Goal:** Generate 3-hour documentary-style lectures and weekly 15-30 minute analysis videos for comprehensive topic coverage and current affairs synthesis, catering to serious aspirants seeking Netflix-quality educational content.

**Features Included:**
- FR4: 3-Hour Documentary-Style Lectures (chaptered, with reading lists)
- FR26: Weekly Documentary (15-30 min current affairs synthesis)

**Estimated Stories:** 10-12 stories covering documentary script generation, multi-chapter assembly, B-roll integration, professional narration, and chapter-based quizzes.

**Key Technical Requirements:**
- Long-form script generation (5000+ words)
- Chapter segmentation algorithms
- Professional TTS voices (documentary style)
- Background music integration
- Revideo long-form templates

---

## Epic 11: Specialized Learning - Math Solver, Memory Palace & Maps

**Epic Goal:** Build specialized tools for quantitative subjects (CSAT/Economy), memory techniques (visual palace animations), and interactive geography (3D map atlas) to serve specific learning styles and subject requirements.

**Features Included:**
- FR9: Animated Math Problem Solver (step-by-step solutions, CSAT/Economy)
- FR7: Visual Memory Palace Videos (facts → animated rooms)
- FR14: 3D Interactive GS Map Atlas (geography data layers, time slider)

**Estimated Stories:** 10-12 stories covering math equation parsing, step-by-step Manim animations, memory palace templates, 3D map rendering with React Three Fiber, and historical map data integration.

**Key Technical Requirements:**
- Math equation parser (LaTeX, handwriting OCR)
- Manim math animation scenes
- Memory palace theming system
- GeoJSON data processing
- React Three Fiber 3D maps

---

## Epic 12: Ethics & Interview Preparation

**Epic Goal:** Deliver GS4 Ethics paper preparation tools including branching case study roleplay, advanced multi-stage simulator, and animated case law explainer to build ethical reasoning skills and polity knowledge for both Mains and Interview stages.

**Features Included:**
- FR8: Ethical Case Study Roleplay Videos (choose-your-path scenarios)
- FR17: GS4 Ethics Simulator Advanced (multi-stage, personality analysis)
- FR11: Animated Case Law, Committee & Amendment Explainer (legal timelines)

**Estimated Stories:** 8-10 stories covering scenario branching logic, ethical framework scoring, personality analysis, case law database, timeline visualizations, and interactive decision trees.

**Key Technical Requirements:**
- Branching video paths (Revideo multi-composition)
- Ethical framework evaluation logic
- Case law/amendment database
- Timeline visualization via Manim
- Interactive decision UI

---

## Epic 13: Flagship Interview Prep Studio (Real-Time AI Interviews)

**Epic Goal:** Build the platform's flagship premium feature - live interview prep studio with real-time AI interviewers, Manim visual aids appearing during answers, instant video debrief, optional body language analysis, and panel mode for peer/mentor reviews. This is the highest complexity epic requiring low-latency Manim rendering (2-6s), WebRTC integration, and sophisticated orchestration.

**Features Included:**
- FR34: Live Interview Prep Studio (complete real-time simulation)

**Estimated Stories:** 12-15 stories covering AI interviewer TTS, real-time Manim micro-renders, WebRTC video/audio, session recording, debrief video generation, body language analysis (opt-in), panel mode, question bank, adaptive difficulty, and privacy/consent workflows.

**Key Technical Requirements:**
- WebRTC for real-time audio/video
- Low-latency Manim service (2-6s renders)
- Real-time compositing/streaming
- TTS streaming for AI interviewer
- Session recording and storage
- Revideo debrief generation
- OpenCV/MediaPipe for body language (optional)
- Explicit consent workflows
- Delete-on-demand privacy controls

---

## Epic 14: Gamification & Engagement - XP, Analytics & Predictions

**Epic Goal:** Implement lightweight gamification (XP, badges, streaks) and AI-powered topic difficulty predictor to drive engagement while maintaining learning-first principles, avoiding competitive anxiety per Business Vision guardrails.

**Features Included:**
- FR30: Gamified Learning Experience (XP, badges, streaks, 3D subject rooms)
- FR31: Topic Difficulty Predictor (historical PYQ analysis, difficulty scoring)

**Estimated Stories:** 6-8 stories covering XP/badge systems, achievement tracking, 3D room navigation, PYQ trend analysis, difficulty prediction models, and analytics dashboards.

**Key Technical Requirements:**
- Achievement/badge system design
- React Three Fiber for 3D rooms
- Historical PYQ data analysis
- Prediction model training
- Revideo reward videos

**Business Guardrails:**
- No competitive leaderboards (self-comparison only)
- No anxiety-inducing notifications
- Respect study-rest balance

---

## Epic 15: Premium Media & Immersive Experiences

**Epic Goal:** Deliver 360° immersive geography/history visualizations with interactive hotspots and VR compatibility for premium users seeking cinematic learning experiences.

**Features Included:**
- FR5: 360° Immersive Geography/History Visualizations (VR-compatible, interactive hotspots)

**Estimated Stories:** 6-8 stories covering 360° video stitching, hotspot interaction logic, VR headset compatibility, panoramic scene rendering, and embedded quiz integration.

**Key Technical Requirements:**
- 360° video processing
- Hotspot coordinate mapping
- WebXR for VR compatibility
- Panoramic Manim scenes
- Interactive video overlays

---

## Epic 16: Voice Customization & Social Publishing

**Epic Goal:** Build AI voice teacher customization allowing users to choose TTS styles/accents and auto social media publisher for marketing automation, completing the platform's personalization and growth capabilities.

**Features Included:**
- FR29: AI Voice Teacher (TTS customization, voice styles, accents)
- Feature 35: Auto Social Media Publisher (admin tool for YouTube/Instagram/Facebook/Twitter posting)

**Estimated Stories:** 6-8 stories covering voice profile system, TTS provider integrations, voice preview, social platform OAuth, auto-posting scheduler, thumbnail generation, and analytics tracking.

**Key Technical Requirements:**
- Multiple TTS provider integration (ElevenLabs, Google Cloud TTS)
- Voice profile storage
- Social media APIs (YouTube, Instagram, Facebook, Twitter)
- OAuth token management
- Posting scheduler (cron jobs)
- Platform-specific formatting

---

## Next Steps

### Architect Prompt

**To the Architect Agent:**

You are now responsible for creating the complete technical architecture document for **UPSC AI Mentor** based on this PRD.

**Your priorities:**

1. **System Architecture:** Design the Pipes/Filters/Actions pattern implementation across all 34 features, defining clear boundaries between Edge Functions (serverless) and VPS services (self-hosted)

2. **Database Architecture:** Expand the schema with all required tables beyond core (video_renders, manim_scene_cache, jobs, job_logs, feature_manifests, quiz_attempts, bookmarks, etc.), define indexes for performance, and RLS policies for security

3. **Video Rendering Architecture:** Design the complete Manim + Revideo pipeline with job queue management, caching strategies (70% hit rate target), retry logic, and horizontal scaling approach (1 VPS → 10 VPS)

4. **RAG Architecture:** Detail the knowledge base ingestion pipeline (PDF → text extraction → semantic chunking → embeddings → pgvector), query optimization for <500ms latency, and confidence scoring algorithms

5. **API Design:** Define all Edge Function endpoints with request/response schemas, error handling patterns, rate limiting, and authentication/authorization flows

6. **Deployment Architecture:** Specify Vercel (frontend), Supabase Cloud (backend), VPS configuration (Docker containers), Cloudflare Tunnels, CDN strategy, and monitoring setup

**Critical Constraints from Business Vision:**
- 95%+ accuracy requirement (RAG grounding mandatory)
- <₹200 AI cost per user/month
- 70% cache hit rate for cost control
- All external API calls server-side only
- UPSC syllabus adherence (zero drift)

**Reference Documents:**
- This PRD for functional requirements
- Business Vision Document for guardrails
- Technical Specification v4 for VPS service endpoints

Please create `docs/architecture.md` following the BMAD architecture template.

---

### UX Expert Prompt

**To the UX Expert Agent:**

You are now responsible for creating the complete UX specification for **UPSC AI Mentor** based on this PRD.

**Your priorities:**

1. **Design System:** Define the complete Neon Glass dark mode theme (colors, typography, spacing, shadows, glass effects) with Tailwind configuration and shadcn/ui component customizations

2. **Core Screens:** Create detailed wireframes and component breakdowns for the 16 critical screens listed in UI Goals section, ensuring mobile-first responsive design

3. **Video Player UX:** Design custom video player interface optimized for educational content (chapter markers, playback speed, transcript sync, notes panel, quiz overlays)

4. **Learning-First Interactions:** Define interaction patterns that prioritize learning over engagement (no dark patterns, respectful notifications, positive progress framing)

5. **Accessibility Spec:** Detail WCAG 2.1 AA compliance implementation (keyboard nav, screen reader support, color contrast, focus management)

6. **Component Library:** Create reusable component specs (buttons, cards, modals, forms) following atomic design principles

**Critical UX Principles from Business Vision:**
- Mobile-first (70% users on mobile)
- Distraction-free (no infinite scroll, no anxiety-inducing metrics)
- Confidence transparency (show AI confidence scores, source citations)
- Positive framing (progress shown as achievements, not deficits)

**Reference Documents:**
- This PRD for screen requirements
- Business Vision for UX guardrails
- Competitor analysis (avoid Unacademy/BYJU'S patterns)

Please create `docs/ux-spec.md` following the BMAD front-end spec template.

---

**PRD Status:** COMPLETE (Epics 1-5 detailed, Epics 6-16 summarized)
**Next Action:** PO Agent to shard this PRD into individual epic files in `docs/prd/` directory
**Ready for:** Architecture creation by Architect Agent

