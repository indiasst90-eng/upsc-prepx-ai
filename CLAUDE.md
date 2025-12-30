# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the **UPSC PrepX-AI** enterprise application specification - an AI-powered UPSC exam preparation platform with video generation, adaptive learning, and comprehensive study materials. The project uses the **BMAD (Business, Management, Architecture, Development)** methodology for structured software development.

## Key Architecture Components

### 1. Infrastructure Stack

**Backend: Supabase**
- PostgreSQL 15+ with pgvector extension for RAG (Retrieval Augmented Generation)
- Supabase Auth for JWT-based authentication
- Supabase Storage for media assets
- Edge Functions (Deno/TypeScript) for serverless compute

**Self-Hosted VPS Services (89.117.60.144)**

**Core Infrastructure:**
- Supabase Studio: `http://89.117.60.144:3000`
- Supabase API: `http://89.117.60.144:8001` (REST API for database access)
- Manim Renderer: `http://89.117.60.144:5000` (Mathematical animations)
- Revideo Renderer: `http://89.117.60.144:5001` (Video composition, Remotion alternative)
- Coolify Dashboard: `http://89.117.60.144:8000` (Deployment management)

**AI/ML Services:**
- Document Retriever (RAG Engine): `http://89.117.60.144:8101/retrieve`
- DuckDuckGo Search Services: `http://89.117.60.144:8102/search`
- Video Orchestrator: `http://89.117.60.144:8103/render`
- Notes Generator: `http://89.117.60.144:8104/generate_notes`

**AI Models (A4F Unified API):**
- Base URL: `https://api.a4f.co/v1`
- API Key: `ddc-a4f-12e06ff0184f41de8d3de7be4cd2e831`
- Primary LLM: `provider-3/llama-4-scout` (text, image, function calling)
- Fallback LLM: `provider-2/gpt-4.1` (activated on primary errors)
- Image Model: `provider-3/gemini-2.5-flash` (OCR, image understanding)
- Embeddings: `provider-5/text-embedding-ada-002` (1536-dim for RAG)
- TTS: `provider-5/tts-1` (video narration)
- STT: `provider-5/whisper-1` (voice transcription)
- Image Gen: `provider-4/imagen-4` (thumbnails, visuals)

**Supabase Credentials (Local Development):**
```bash
SUPABASE_URL=http://89.117.60.144:8001
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU
```

### 2. Core Development Pattern: Pipes/Filters/Actions

Every feature follows this pattern:
```
USER REQUEST → PIPE (Edge Function) → FILTER(s) → ACTION(s) → RESPONSE
```

- **Pipes**: Orchestrator Edge Functions in `pipes/<feature_slug>_pipe.ts`
- **Filters**: Validation/enrichment in `filters/<name>_filter.ts`
- **Actions**: Side effects (DB writes, external calls) in `actions/<name>_action.ts`

All external service calls MUST be made server-side through Edge Functions - never expose endpoints to client.

### 3. Knowledge Base System

The platform builds a comprehensive UPSC knowledge base from admin-uploaded PDFs:
- Standard books: Laxmikanth Polity, NCERT, Spectrum Modern India, etc.
- Vector embeddings stored in Supabase with pgvector
- Semantic chunking (max 1000 tokens, 200 token overlap)
- Mapped to complete UPSC syllabus taxonomy (GS1-4, CSAT, Essay)

Daily updates come ONLY from whitelisted sources:
- visionias.in, drishtiias.com, thehindu.com, pib.gov.in, forumias.com, iasgyan.in, pmfias.com, pwonlyias.com, byjus.com, insightsonindia.com

### 4. Video Generation Architecture

**Manim**: Mathematical/diagram animations (vector-based)
**Remotion**: Timeline-based video composition with React components

Combined workflow:
1. Generate script with visual markers
2. Create Manim scene specs for diagrams
3. Render Manim scenes via VPS service
4. Assemble final video with Remotion (TTS, transitions, compositing)

## BMAD Methodology

This project uses the BMAD framework with specialized agents:

### Agent System

**Core agents** (located in `.bmad-core/agents/`):
- `bmad-orchestrator.md`: Master coordinator, transforms into other agents
- `bmad-master.md`: Universal task executor
- `po.md`: Product Owner - requirements and user stories
- `architect.md`: System architecture and technical design
- `dev.md`: Development implementation
- `qa.md`: Quality assurance and testing
- `pm.md`: Project management
- `analyst.md`: Business analysis
- `sm.md`: Scrum Master
- `ux-expert.md`: UX/UI design

### Agent Activation

To activate an agent persona (when using BMAD tools):
1. Read the agent's `.md` file completely
2. Follow the YAML configuration's `activation-instructions`
3. Load dependencies ONLY when needed, not during activation
4. Commands always require `*` prefix (e.g., `*help`, `*task`)

### Key BMAD Resources

**Configuration**: `.bmad-core/core-config.yaml`
- Project structure (docs/, stories/, architecture/)
- Markdown exploder enabled
- PRD version v4, sharded in `docs/prd/`
- Architecture version v4, sharded in `docs/architecture/`

**Tasks** (`.bmad-core/tasks/`):
- `create-doc.md`: Document creation workflow
- `create-next-story.md`: User story generation
- `document-project.md`: Full project documentation
- `execute-checklist.md`: Checklist execution

**Templates** (`.bmad-core/templates/`):
- `prd-tmpl.yaml`: Product requirements
- `architecture-tmpl.yaml`: System architecture
- `story-tmpl.yaml`: User story format
- Frontend/fullstack architecture templates

**Workflows** (`.bmad-core/workflows/`):
- Greenfield: fullstack, service, UI
- Brownfield: fullstack, service, UI

## Critical Development Rules

### Security & Best Practices

1. **NO localStorage for auth** - Use Supabase Auth exclusively
2. **NO hardcoded API keys** - Use environment variables only
3. **ALL external calls via Edge Functions** - Never expose VPS endpoints to client
4. **Entitlement checks** on every premium feature request
5. **User-friendly terminology** - Hide technical terms:
   - "AI Animation Engine" instead of "Manim"
   - "Smart Video Creator" instead of "Remotion"
   - "Intelligent Search" instead of "RAG"

### Trial & Subscription Logic

- **Trial**: 7 days with FULL Pro access, no payment method required
- **After trial expiry**: Downgrade to Free tier (not blocked), premium features show upgrade prompts
- **Subscription plans**: Monthly ₹599, Quarterly ₹1499, Half-Yearly ₹2699, Annual ₹4999
- **Grace period**: 3 days after subscription expiry before downgrade to Free tier

### Database Schema

Key tables in PostgreSQL:
- `users`, `user_profiles`: User management
- `subscriptions`, `entitlements`: Access control via RevenueCat
- `syllabus_nodes`: Complete UPSC syllabus taxonomy
- `knowledge_chunks`: Vector-indexed content from PDFs
- `comprehensive_notes`, `daily_updates`: Study materials
- `video_renders`, `manim_scene_cache`: Video generation
- `jobs`, `job_logs`: Async task queue

## 35 Core Features

The platform includes 35 distinct features ranging from:
- Interactive 3D syllabus navigator
- Daily current affairs video newspaper
- Real-time doubt-to-video converter
- 3-hour documentary lectures
- AI essay trainer and answer writing practice
- PYQ video explanations
- Memory palace visualizations
- Ethics case study roleplay
- Live interview prep studio

Each feature has specific complexity ratings (Low/Medium/High/Very High) and monetization strategies detailed in `34 feature lists.md`.

## Working with This Codebase

### When Creating New Features

1. Check the feature specification in `UPSC COMPLETE ENTERPRISE BUILD SPECIFICATION v4.md`
2. Follow the Pipe → Filter → Action pattern
3. Implement entitlement checks first
4. Add to `feature_manifests` table
5. Create Edge Function in Supabase
6. Never pre-load resources - load at runtime only

### When Using BMAD Agents

1. Start with `bmad-orchestrator` for coordination
2. Transform to specialist agents with `*agent <name>`
3. Always use `*` prefix for commands
4. Load tasks/templates only when executing them
5. Follow numbered lists for user choices
6. Stay in character until `*exit`

### Frontend Development

- **Framework**: Next.js 14+ (App Router)
- **Styling**: Tailwind CSS
- **UI Components**: shadcn/ui
- **State**: React Query + Zustand
- **3D**: React Three Fiber
- **Design**: Neon Glass dark mode theme
- **Mobile-first**: All designs must be responsive

### Testing Strategy

- Unit tests for all filters and actions (mocked external calls)
- Integration tests for each pipe endpoint
- E2E tests for critical flows (signup → trial → subscription)
- Test database for database operations

## Environment Configuration

Required environment variables (never commit actual values):
- `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`
- VPS service URLs for document retrieval, search, rendering, notes generation
- `REVENUECAT_SECRET_API_KEY` for subscription management
- Social media API keys for auto-publishing
- Optional: `REDIS_URL`, `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`

## Common Pitfalls to Avoid

1. Don't scan filesystem or auto-discover during agent activation
2. Don't load KB (`bmad-kb.md`) unless `*kb` command is used
3. Don't skip user interaction in tasks marked with `elicit=true`
4. Don't expose technical implementation details to end users
5. Don't commit changes to BMAD core files without understanding the framework
6. Don't create documentation files proactively - only when explicitly requested

## Key Documentation Files

- `UPSC COMPLETE ENTERPRISE BUILD SPECIFICATION v4.md`: Complete system specification
- `34 feature lists.md`: All 35 features with complexity and monetization details
- `.bmad-core/user-guide.md`: BMAD framework user guide
- `.bmad-core/enhanced-ide-development-workflow.md`: IDE-specific workflows
- `.bmad-core/working-in-the-brownfield.md`: Brownfield development guide

## Quick Reference

**Create a new document**: `*create-doc <template-name>`
**Execute a checklist**: `*execute-checklist <checklist-name>`
**Switch agent**: `*agent <agent-id>`
**Get help**: `*help`
**Enable KB mode**: `*kb`
**List available tasks**: `*task`
