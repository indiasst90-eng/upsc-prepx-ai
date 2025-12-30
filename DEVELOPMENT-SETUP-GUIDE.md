# UPSC PrepX-AI - Development Setup Guide

## Step-by-Step Guide to Run Frontend & Backend

---

## Prerequisites (Install First)

### 1. Install Node.js 20+
```bash
# Download from: https://nodejs.org/
# Choose LTS version (20.x or higher)
# Verify installation:
node --version  # Should show v20.x.x
npm --version   # Should show 10.x.x
```

### 2. Install pnpm (Package Manager)
```powershell
# Run in PowerShell as Administrator
npm install -g pnpm

# Verify:
pnpm --version  # Should show 8.x.x or higher
```

### 3. Install Git (if not installed)
```bash
# Download from: https://git-scm.com/download/win
```

---

## Step 1: Clone/Navigate to Project

```powershell
# Navigate to your project folder
cd "E:\BMAD method\BMAD 4"
```

---

## Step 2: Install Dependencies

```powershell
# Install all packages for the entire monorepo
pnpm install
```

**Expected output:** Downloads ~500MB of packages (first time only)

---

## Step 3: Setup Environment Variables

### Create `.env.local` file in root:
```powershell
# Copy the example file
Copy-Item .env.example .env.local
```

### Edit `.env.local` with your values:
```env
# Supabase (VPS)
NEXT_PUBLIC_SUPABASE_URL=http://89.117.60.144:54321
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU

# A4F AI API
A4F_API_KEY=ddc-a4f-12e06ff0184f41de8d3de7be4cd2e831
A4F_BASE_URL=https://api.a4f.co/v1

# VPS Services
VPS_MANIM_URL=http://89.117.60.144:5000
VPS_REVIDEO_URL=http://89.117.60.144:5001
VPS_RAG_URL=http://89.117.60.144:8101
VPS_SEARCH_URL=http://89.117.60.144:8102
VPS_ORCHESTRATOR_URL=http://89.117.60.144:8103
VPS_NOTES_URL=http://89.117.60.144:8104
VPS_CRAWL4AI_URL=http://89.117.60.144:8105

# App URLs
NODE_ENV=development
NEXT_PUBLIC_APP_URL=http://localhost:3000
NEXT_PUBLIC_ADMIN_URL=http://localhost:3001
```

### Also create `.env.local` in apps:
```powershell
# Copy to web app
Copy-Item .env.local "apps\web\.env.local"

# Copy to admin app
Copy-Item .env.local "apps\admin\.env.local"
```

---

## Step 4: Run Development Servers

### Option A: Run Everything Together (Recommended)
```powershell
# This starts all apps and packages in dev mode
pnpm dev
```

**What happens:**
- Web App starts at: http://localhost:3000
- Admin Dashboard starts at: http://localhost:3001
- All packages are watched for changes

---

### Option B: Run Apps Separately

**Terminal 1 - Web App (Main Frontend):**
```powershell
cd "E:\BMAD method\BMAD 4\apps\web"
pnpm dev
```
**Opens at:** http://localhost:3000

**Terminal 2 - Admin Dashboard:**
```powershell
cd "E:\BMAD method\BMAD 4\apps\admin"
pnpm dev
```
**Opens at:** http://localhost:3001

---

## Step 5: Open in Browser

| App | URL | Description |
|-----|-----|-------------|
| **Web App** | http://localhost:3000 | Main student-facing app |
| **Admin Dashboard** | http://localhost:3001 | Admin panel for content management |

---

## Step 6: Build for Production

### Build All:
```powershell
pnpm build
```

**Expected output:**
```
@upsc-prepx-ai/web:build: ✓ Compiled successfully
@upsc-prepx-ai/admin:build: ✓ Compiled successfully
Tasks: 4 successful, 4 total
```

### Run Production Build Locally:
```powershell
# Web app
cd apps/web
pnpm start

# Admin (new terminal)
cd apps/admin
pnpm start
```

---

## Project Structure Explained

```
E:\BMAD method\BMAD 4\
│
├── apps/
│   ├── web/                 ← Main Frontend (Next.js)
│   │   ├── src/
│   │   │   ├── app/         ← Pages (78 pages)
│   │   │   │   ├── (auth)/  ← Login, signup pages
│   │   │   │   ├── (dashboard)/ ← All feature pages
│   │   │   │   └── api/     ← Backend APIs (89 routes)
│   │   │   ├── components/  ← UI components
│   │   │   ├── lib/         ← Utilities
│   │   │   └── hooks/       ← React hooks
│   │   └── package.json
│   │
│   └── admin/               ← Admin Dashboard (Next.js)
│       └── src/app/
│           ├── knowledge-base/  ← Upload PDFs
│           ├── pyqs/            ← Manage PYQs
│           └── queue/           ← Monitor jobs
│
├── packages/
│   ├── a4f/                 ← AI API client
│   ├── config/              ← Environment config
│   ├── crawl4ai/            ← Web crawler client
│   ├── razorpay/            ← Payment integration
│   ├── revenuecat/          ← Subscription management
│   ├── supabase/            ← Database & migrations
│   ├── utils/               ← Shared utilities
│   └── vps/                 ← VPS services client
│
├── .env.example             ← Environment template
├── package.json             ← Root package config
├── pnpm-workspace.yaml      ← Monorepo config
└── turbo.json               ← Build orchestration
```

---

## Common Commands Reference

| Command | What it does |
|---------|--------------|
| `pnpm install` | Install all dependencies |
| `pnpm dev` | Start development servers |
| `pnpm build` | Build production bundles |
| `pnpm lint` | Check code quality |
| `pnpm test` | Run tests |
| `pnpm test:e2e` | Run end-to-end tests |

---

## Troubleshooting

### Issue: "Module not found"
```powershell
# Delete node_modules and reinstall
Remove-Item -Recurse -Force node_modules
Remove-Item pnpm-lock.yaml
pnpm install
```

### Issue: Port already in use
```powershell
# Find process using port 3000
netstat -ano | findstr :3000

# Kill it (replace PID with actual number)
taskkill /PID <PID> /F
```

### Issue: Build errors
```powershell
# Clear Turbo cache and rebuild
Remove-Item -Recurse -Force .turbo
pnpm build
```

### Issue: Environment variables not loading
- Ensure `.env.local` exists in root AND in `apps/web/` AND `apps/admin/`
- Restart the dev server after changing env vars

---

## Backend Services (Already on VPS)

Your backend services are running on VPS `89.117.60.144`:

| Service | Port | Status |
|---------|------|--------|
| Supabase Studio | 3000 | Running |
| Supabase API | 54321 | Running |
| Manim Renderer | 5000 | Running |
| Revideo Renderer | 5001 | Running |
| RAG Engine | 8101 | Running |
| Search Proxy | 8102 | Running |
| Video Orchestrator | 8103 | Running |
| Notes Generator | 8104 | Running |
| crawl4ai | 8105 | Running |

**Note:** These are already deployed. Your local Next.js app connects to them via the VPS URLs in `.env.local`.

---

## Quick Start Summary

```powershell
# 1. Open PowerShell and navigate to project
cd "E:\BMAD method\BMAD 4"

# 2. Install dependencies (first time only)
pnpm install

# 3. Create environment file (first time only)
Copy-Item .env.example .env.local
Copy-Item .env.local "apps\web\.env.local"
Copy-Item .env.local "apps\admin\.env.local"

# 4. Start development
pnpm dev

# 5. Open browser
# Web App: http://localhost:3000
# Admin: http://localhost:3001
```

---

## Next Steps After Setup

1. **Login to Admin Dashboard** → Upload UPSC books to Knowledge Base
2. **Upload PYQs** → Add past year questions
3. **Test Features** → Try daily CA, doubt converter, notes generator
4. **Customize UI** → Modify `tailwind.config.js` and `globals.css`

---

**You're ready to develop!** 🚀
