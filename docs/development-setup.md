# Development Setup Guide

## Prerequisites

- Node.js 20+ (`node -v`)
- pnpm 8+ (`pnpm -v`)
- Git
- VS Code (recommended)

## Installation

```bash
# Clone repository
git clone <repository-url>
cd upsc-prepx-ai

# Install dependencies
pnpm install

# Copy environment variables
cp .env.example .env.local

# Start development servers
pnpm dev
```

## Development Servers

| App | URL | Port |
|-----|-----|------|
| Web App | http://localhost:3000 | 3000 |
| Admin App | http://localhost:3001 | 3001 |

## Available Commands

| Command | Description |
|---------|-------------|
| `pnpm install` | Install all dependencies |
| `pnpm dev` | Start development servers |
| `pnpm build` | Build all apps for production |
| `pnpm lint` | Run ESLint |
| `pnpm format` | Format code with Prettier |
| `pnpm test` | Run tests |

## Project Structure

```
upsc-prepx-ai/
├── apps/
│   ├── web/          # Student-facing app
│   └── admin/        # Admin dashboard
├── packages/
│   ├── supabase/     # Database types & client
│   ├── a4f/          # AI API client
│   └── utils/        # Shared utilities
└── docs/             # Documentation
```

## Troubleshooting

### Port Already in Use

```bash
# Find process using port
lsof -i :3000

# Kill process
kill <PID>
```

### TypeScript Errors

```bash
# Run type check
pnpm type-check
```

### Dependencies Not Resolving

```bash
# Clear pnpm cache and reinstall
rm -rf node_modules .pnpm-store
pnpm install
```
