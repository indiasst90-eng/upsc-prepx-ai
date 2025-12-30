# Admin Dashboard - Manual Deployment Guide

**Date:** December 24, 2025
**Location:** `apps/admin/`
**Target:** http://89.117.60.144:3002

---

## Why Manual Deployment?

The automated deployment scripts encountered issues with file uploads and Docker builds. The simplest approach is to manually deploy the dashboard.

---

## Option 1: Deploy via Coolify (Easiest)

1. **Open Coolify:** http://89.117.60.144:8000

2. **Create New Resource:**
   - Click "New Resource"
   - Select "Docker Compose" or "Dockerfile"

3. **Configure Service:**
   - **Name:** admin-dashboard
   - **Port:** 3002
   - **Dockerfile:** Use `Dockerfile.simple` from `apps/admin/`

4. **Set Environment Variables:**
   ```
   NEXT_PUBLIC_SUPABASE_URL=http://89.117.60.144:54321
   NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0
   ```

5. **Deploy**

6. **Access:** http://89.117.60.144:3002/queue/monitoring

---

## Option 2: Deploy via SSH + Docker

### Step 1: SSH into VPS

```bash
ssh root@89.117.60.144
# Password: 772877mAmcIaS
```

### Step 2: Create directory and upload files manually

```bash
mkdir -p /opt/admin-dashboard
cd /opt/admin-dashboard
```

Then use WinSCP, FileZilla, or manual file creation to upload these files from `E:\BMAD method\BMAD 4\apps\admin\`:

Required files:
```
src/ (entire directory)
package.json
tsconfig.json
next.config.js
Dockerfile.simple
.env.local
```

### Step 3: Build Docker Image

```bash
cd /opt/admin-dashboard
docker build -f Dockerfile.simple -t admin-dashboard:latest .
```

### Step 4: Run Container

```bash
docker run -d \
  --name admin-dashboard \
  --restart always \
  -p 3002:3000 \
  -e NEXT_PUBLIC_SUPABASE_URL=http://89.117.60.144:54321 \
  -e NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0 \
  admin-dashboard:latest
```

### Step 5: Verify

```bash
# Check container
docker ps | grep admin-dashboard

# Check logs
docker logs admin-dashboard

# Test endpoint
curl -I http://localhost:3002
```

---

## Option 3: Deploy to Vercel (Cloud)

If VPS deployment is problematic, deploy to Vercel:

### Step 1: Push to GitHub

```bash
cd "E:\BMAD method\BMAD 4"
git add apps/admin
git commit -m "Add admin dashboard"
git push
```

### Step 2: Import to Vercel

1. Go to https://vercel.com
2. Click "Add New Project"
3. Import your GitHub repository
4. Select `apps/admin` as root directory
5. Set environment variables:
   ```
   NEXT_PUBLIC_SUPABASE_URL=http://89.117.60.144:54321
   NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0
   ```
6. Deploy

---

## Verification

Once deployed, verify:

1. **Dashboard loads:** http://89.117.60.144:3002 (or Vercel URL)
2. **Queue monitoring works:** http://89.117.60.144:3002/queue/monitoring
3. **Stats display correctly**
4. **Job list shows recent jobs**
5. **Auto-refresh works** (every 5 seconds)

---

## Troubleshooting

### Build Fails

**Error:** `Cannot read file '/tsconfig.json'`

**Fix:** Ensure all files are uploaded:
- package.json
- tsconfig.json
- next.config.js
- src/ directory (complete)

### Dashboard Shows Errors

**Error:** "Could not find table 'jobs'"

**Fix:** Restart Supabase REST API:
```bash
docker restart supabase_rest_my-project
```

### Cannot Connect to Supabase

**Error:** Network errors

**Fix:** Check environment variables are set correctly in container

---

**Status:** Ready for manual deployment via Coolify or SSH

**Estimated Time:** 15-30 minutes manual deployment

**Priority:** Medium (nice-to-have, not blocking for Phase 4)
