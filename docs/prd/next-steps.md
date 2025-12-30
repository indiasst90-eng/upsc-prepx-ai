# Next Steps

## Architect Prompt

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

## UX Expert Prompt

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

