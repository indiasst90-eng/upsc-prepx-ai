# Quick Deployment Guide - UPSC PrepX Frontend

## Prerequisites Checklist
- [x] VPS Access: 89.117.60.144 (root/772877mAmcIaS)
- [x] Coolify installed and running
- [x] Code pushed to Git repository
- [x] Environment variables ready

## 1. Web App Deployment (15 minutes)

### Step 1: Access Coolify Dashboard
```
https://89.117.60.144:8000
# Login with Coolify credentials
```

### Step 2: Create New Project
1. Click "New Project"
2. Name: "UPSC PrepX Web"
3. Select Git Source
4. Connect repository: Your Git URL
5. Branch: main/master

### Step 3: Configure Build
1. Build Pack: Dockerfile
2. Dockerfile Path: `apps/web/Dockerfile.optimized`
3. Base Directory: `/` (root of monorepo)
4. Port: 3000

### Step 4: Environment Variables
Add these in Coolify:
```env
# Supabase
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
SUPABASE_SERVICE_ROLE_KEY=your_service_key

# AI Provider
A4F_API_KEY=your_a4f_key

# App Config
NEXT_PUBLIC_APP_URL=https://your-domain.com
NODE_ENV=production
```

### Step 5: Enable HTTPS
1. Go to Domains tab
2. Add your domain or use Coolify subdomain
3. Enable "Force HTTPS"
4. Enable "Let's Encrypt SSL"
5. Wait for certificate provisioning (2-3 minutes)

### Step 6: Deploy
1. Click "Deploy" button
2. Monitor build logs
3. Wait for deployment (5-10 minutes)
4. Verify deployment status: "Running"

### Step 7: Verify Deployment
Open browser and check:
- ✅ https://your-domain.com (user app)
- ✅ https://your-domain.com/admin (admin panel)
- ✅ Green padlock (SSL valid)
- ✅ No console errors
- ✅ Login works

## 2. Admin Panel Deployment (Same process)

### Option A: Same Domain
Admin panel is at `/admin` route (already done in Step 1)

### Option B: Separate Subdomain (Recommended)
1. Create new Coolify project: "UPSC PrepX Admin"
2. Use same repository
3. Build Pack: Dockerfile
4. Dockerfile Path: `apps/admin/Dockerfile.coolify`
5. Port: 3000
6. Domain: admin.your-domain.com
7. Add environment variables
8. Enable HTTPS
9. Deploy

### Admin Access Verification
```
URL: https://your-domain.com/admin
Username: root
Password: 772877mAmcIaS (VPS root password)
```

**IMPORTANT:** On first login:
1. System will force password change
2. Set strong new password
3. Enable MFA (recommended)
4. Update DEPLOYMENT_CREDENTIALS.md with new password

## 3. Mobile App Build (30 minutes)

### Step 1: Install EAS CLI (if not installed)
```bash
npm install -g eas-cli
```

### Step 2: Login to Expo
```bash
eas login
# Use your Expo account
```

### Step 3: Configure Build
```bash
cd apps/mobile
eas build:configure
```

### Step 4: Build APK for Testing
```bash
# Preview build (for internal testing)
eas build --platform android --profile preview

# This will:
# 1. Upload code to Expo servers
# 2. Build APK in cloud
# 3. Provide download link
```

### Step 5: Download and Install
1. Copy build URL from terminal
2. Open on Android device browser
3. Download APK
4. Enable "Install from Unknown Sources"
5. Install app
6. Test functionality

### Step 6: Production Build (when ready)
```bash
# For Google Play Store
eas build --platform android --profile production

# This creates an App Bundle (.aab)
# Upload to Google Play Console
```

## 4. Deployment Verification Checklist

### Web Application
- [ ] User app accessible via public HTTPS URL
- [ ] Admin panel accessible at /admin route
- [ ] HTTPS certificate valid (green padlock in browser)
- [ ] Environment variables loaded correctly (test features, don't check values)
- [ ] Database connection successful (signup/login works)
- [ ] AI features functional (try generating content)
- [ ] Static assets served correctly (images, fonts load)
- [ ] No console errors on primary pages (check browser console)
- [ ] Responsive design works (test mobile, tablet, desktop views)
- [ ] Admin login works with provided credentials
- [ ] Admin features isolated (not visible in user panel navigation)

### Security Verification
- [ ] No secrets visible in client-side code (check Network tab, sources)
- [ ] HTTPS enforced on all routes (try HTTP, should redirect)
- [ ] Admin panel requires authentication (logout and try accessing)
- [ ] Session management working (logout works, timeout after inactivity)
- [ ] Rate limiting active on sensitive endpoints
- [ ] CORS configured correctly (no CORS errors)
- [ ] Security headers present (check Response Headers)

### Mobile Application
- [ ] APK installs successfully on test device
- [ ] App launches without crashes
- [ ] Backend connectivity established (can login)
- [ ] User authentication works
- [ ] Primary features functional (dashboard, search, tools)
- [ ] Offline mode works (where applicable)
- [ ] Push notifications received (if implemented)
- [ ] App handles network errors gracefully
- [ ] No performance issues (smooth scrolling, animations)

## 5. Troubleshooting

### Build Fails
**Problem:** Docker build fails in Coolify
**Solution:**
1. Check build logs for specific error
2. Verify Dockerfile path is correct
3. Ensure all package.json files are committed
4. Check pnpm-lock.yaml is in repository

### SSL Certificate Not Provisioning
**Problem:** HTTPS not working
**Solution:**
1. Ensure domain DNS points to VPS IP (89.117.60.144)
2. Wait 5-10 minutes for DNS propagation
3. Check Coolify SSL logs
4. Try manual certificate refresh in Coolify

### Environment Variables Not Loading
**Problem:** Features not working (blank pages, errors)
**Solution:**
1. Check Coolify environment variables tab
2. Ensure no typos in variable names
3. Restart application after adding variables
4. Check application logs for "undefined" errors

### Admin Panel Not Accessible
**Problem:** /admin returns 404
**Solution:**
1. Verify admin routes exist in apps/admin/src/app
2. Check middleware.ts for admin route protection
3. Ensure admin build is deployed
4. Check Coolify routing configuration

### Mobile Build Fails
**Problem:** EAS build fails
**Solution:**
1. Check eas.json syntax
2. Ensure all dependencies are in package.json
3. Check Expo SDK version compatibility
4. Review build logs from Expo dashboard

## 6. Post-Deployment Tasks

### Immediate (Day 1)
1. ✅ Verify all checklist items above
2. ✅ Change admin password (force on first login)
3. ✅ Set up monitoring (Coolify built-in)
4. ✅ Test critical user flows
5. ✅ Document public URLs

### Week 1
1. Monitor error logs
2. Check performance metrics
3. Gather user feedback
4. Test on multiple devices
5. Verify backup systems

### Ongoing
1. Weekly security updates
2. Monitor SSL certificate expiry
3. Review application logs
4. Performance optimization
5. User analytics review

## 7. Rollback Procedure

If deployment fails or issues arise:

### Web App Rollback
1. Go to Coolify dashboard
2. Select project
3. Go to "Deployments" tab
4. Click "Rollback" on previous working version
5. Confirm rollback
6. Monitor for successful restart

### Mobile App Rollback
1. Keep previous APK version
2. Redistribute previous version if needed
3. For Play Store: Use release management to rollback

## 8. URLs and Access

After deployment, document:

```
# Production URLs
User App: https://_________.com
Admin Panel: https://_________.com/admin

# Admin Credentials
Username: root
Initial Password: <VPS root password>
New Password: <set on first login>

# VPS Access
IP: 89.117.60.144
SSH User: root
SSH Password: 772877mAmcIaS

# Coolify Dashboard
URL: https://89.117.60.144:8000
```

## 9. Monitoring and Health Checks

### Automated Health Checks
Coolify performs automatic health checks:
- Endpoint: /api/health
- Interval: 30 seconds
- Timeout: 5 seconds
- Retries: 3

### Manual Health Checks
Run these periodically:
```bash
# Web app health
curl https://your-domain.com/api/health

# Admin panel health
curl https://your-domain.com/admin

# SSL certificate check
openssl s_client -connect your-domain.com:443 -servername your-domain.com
```

### Performance Monitoring
Use browser DevTools:
1. Open Network tab
2. Refresh page
3. Check:
   - Total page load time (< 3s)
   - Number of requests (< 50)
   - Total size (< 2MB)
4. Use Lighthouse for detailed analysis

## 10. Support and Escalation

### Common Issues and Fixes

**Issue:** "Connection refused"
**Fix:** Check if application is running in Coolify dashboard

**Issue:** "502 Bad Gateway"
**Fix:** Application crashed, check logs and restart

**Issue:** "Database connection error"
**Fix:** Verify SUPABASE_URL and keys in environment variables

**Issue:** "Module not found"
**Fix:** Rebuild with `pnpm install` in Dockerfile

### Getting Help
1. Check Coolify documentation
2. Review application logs
3. Check GitHub repository issues
4. Contact VPS provider for infrastructure issues

---

**Deployment Prepared By:** AI Assistant  
**Date:** December 31, 2025  
**Estimated Total Deployment Time:** 45-60 minutes  
**Difficulty Level:** Intermediate

**NEXT ACTION:** Follow Step 1 to begin web app deployment to Coolify.
