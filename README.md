# UPSC PrepX-AI

Enterprise AI-powered UPSC exam preparation platform with video generation, adaptive learning, and comprehensive study materials.

## Overview

UPSC PrepX-AI is a comprehensive platform that transforms UPSC exam preparation through:
- **AI Video Generation**: Daily current affairs videos, doubt resolution, notes summaries
- **RAG-Powered Knowledge Base**: Semantic search across NCERT, Laxmikanth, and standard texts
- **Adaptive Learning**: Personalized study schedules and spaced repetition
- **Interactive Tools**: 3D syllabus navigator, mind maps, ethics simulations

## Tech Stack

| Component | Technology |
|-----------|------------|
| Frontend | Next.js 14 (App Router), React 18, Tailwind CSS |
| Backend | Supabase (PostgreSQL + Edge Functions) |
| AI Models | A4F Unified API (Llama-4, GPT-4.1, Gemini, Ada-002, Whisper, TTS, Imagen) |
| Video Rendering | Manim (math animations), Revideo (video composition) |
| Database | PostgreSQL 15+ with pgvector for RAG |
| Monorepo | Turborepo with pnpm workspaces |

## Project Structure

```
upsc-prepx-ai/
├── apps/
│   ├── web/          # Main student-facing application (port 3000)
│   └── admin/        # Admin dashboard (port 3001)
├── packages/
│   ├── supabase/     # Supabase client and type definitions
│   ├── a4f/          # A4F Unified API client
│   └── utils/        # Shared utility functions
├── docs/
│   ├── stories/      # User stories (122 stories)
│   ├── prd/          # Product requirements documents
│   └── architecture/ # Technical architecture docs
└── .bmad-core/       # BMAD methodology framework
```

## Getting Started

### Prerequisites

- Node.js 20+
- pnpm 8+
- Git

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd upsc-prepx-ai

# Install dependencies
pnpm install

# Copy environment variables
cp .env.example .env.local

# Start development servers
pnpm dev
```

This starts:
- Web app: http://localhost:3000
- Admin app: http://localhost:3001

### Available Commands

| Command | Description |
|---------|-------------|
| `pnpm install` | Install all dependencies |
| `pnpm dev` | Start development servers |
| `pnpm build` | Build all applications |
| `pnpm lint` | Run ESLint |
| `pnpm format` | Format code with Prettier |
| `pnpm test` | Run tests |

## Environment Variables

See `.env.example` for all required variables. Key variables:

```env
# Supabase
NEXT_PUBLIC_SUPABASE_URL=http://89.117.60.144:54321
NEXT_PUBLIC_SUPABASE_ANON_KEY=...
SUPABASE_SERVICE_ROLE_KEY=...

# A4F Unified API
A4F_API_KEY=ddc-a4f-12e06ff0184f41de8d3de7be4cd2e831
A4F_BASE_URL=https://api.a4f.co/v1

# VPS Services
VPS_RAG_URL=http://89.117.60.144:8101
VPS_MANIM_URL=http://89.117.60.144:5000
VPS_REVIDEO_URL=http://89.117.60.144:5001
VPS_ORCHESTRATOR_URL=http://89.117.60.144:8103
VPS_NOTES_URL=http://89.117.60.144:8104
```

## Infrastructure

The platform uses a hybrid serverless + VPS architecture:

| Service | URL | Purpose |
|---------|-----|---------|
| Supabase Studio | http://89.117.60.144:3000 | Database admin UI |
| Supabase API | http://89.117.60.144:54321 | REST API (Kong Gateway) |
| Manim Renderer | http://89.117.60.144:5000 | Math animations |
| Revideo Renderer | http://89.117.60.144:5001 | Video composition |
| RAG Engine | http://89.117.60.144:8101 | Vector search |
| Video Orchestrator | http://89.117.60.144:8103 | Multi-service coordination |
| Notes Generator | http://89.117.60.144:8104 | AI notes synthesis |

## Architecture

This project follows the **BMAD (Business, Management, Architecture, Development)** methodology with the Pipe/Filter/Action pattern:

```
USER REQUEST → PIPE (Edge Function) → FILTER(s) → ACTION(s) → RESPONSE
```

- **Pipes**: Orchestrator Edge Functions in `supabase/functions/pipes/`
- **Filters**: Validation/enrichment in `supabase/functions/filters/`
- **Actions**: Side effects in `supabase/functions/actions/`

## Development

### Adding New Features

1. Create a user story in `docs/stories/`
2. Follow the Pipe/Filter/Action pattern
3. Add entitlement checks for premium features
4. Create Edge Function in `supabase/functions/`

### Coding Standards

- TypeScript strict mode
- ESLint + Prettier for formatting
- Component naming: PascalCase
- File naming: camelCase for utilities, PascalCase for components
- No `any` types (use `unknown`)

### Testing

- Unit tests for utilities and filters
- Integration tests for each pipe endpoint
- E2E tests for critical flows

## Documentation

- **PRD**: `docs/prd/` - Product requirements by epic
- **Stories**: `docs/stories/` - 122 user stories across 16 epics
- **Architecture**: `docs/architecture/` - Technical design documents
- **BMAD Guide**: `.bmad-core/user-guide.md` - Framework documentation

## License

Proprietary - All rights reserved

## Credits

Built with the BMAD methodology for structured enterprise software development.
