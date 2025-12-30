# 🚀 Phase 3 Ready - Deployment Instructions

**Created:** December 24, 2025
**Status:** Ready to Begin
**Story:** 4.11 - Queue System Production Deployment & Video Service Integration

---

## 📋 Phase 3 Overview

**Objective:** Complete the video generation pipeline with admin monitoring and real video service integration.

**Previous Phase:** Phase 2 Complete ✅
- Database schema deployed
- Queue worker running
- Test job processed successfully

**This Phase:** Phase 3 - Production Integration
- Deploy admin monitoring dashboard
- Integrate Manim/Revideo/Orchestrator APIs
- End-to-end testing with real videos
- Production monitoring setup

---

## 📖 Story 4.11 Summary

**File:** `docs/stories/4.11.queue-system-production-deployment.md`

**Tasks:** 10 total (24-26 hours estimated)
1. Deploy Admin Dashboard (2h)
2. Integrate Manim API (3h)
3. Integrate Revideo API (3h)
4. Integrate Video Orchestrator (4h)
5. Remove Simulation Code (1h)
6. Enhanced Error Handling (2h)
7. Deploy Admin Dashboard (2h)
8. Add Authentication to Dashboard (1.5h)
9. End-to-End Integration Test (2h)
10. Update Documentation (1.5h)

**Acceptance Criteria:** 5 major criteria
- Admin dashboard deployed and accessible
- All 3 video services integrated
- E2E test passes with real video
- Monitoring and alerting configured
- Documentation complete

---

## 🎯 To Start Development

### Option 1: Activate Dev Agent (BMAD)

```bash
# From Claude Code or your IDE

# 1. Activate Dev Agent
*agent dev

# 2. Execute story
*develop-story docs/stories/4.11.queue-system-production-deployment.md
```

### Option 2: Manual Development

1. **Read the story file:**
   ```
   E:\BMAD method\BMAD 4\docs\stories\4.11.queue-system-production-deployment.md
   ```

2. **Start with Task 1:**
   - Review admin dashboard code
   - Deploy to Coolify/Vercel
   - Test dashboard access

3. **Follow task sequence:**
   - Complete each task sequentially
   - Mark checkboxes as you progress
   - Update Dev Agent Record section

---

## 📁 Key Files for Phase 3

### Files to Modify:
```
packages/queue-worker/index.js                    # Main integration work
apps/admin/src/app/queue/monitoring/page.tsx     # Add authentication
packages/queue-worker/README.md                   # Documentation
```

### Files to Create:
```
PHASE3-DEPLOYMENT-COMPLETE.md                     # Phase summary
test-e2e-integration.sh                           # Test script
apps/admin/Dockerfile                             # Dashboard container (optional)
```

### Files to Review:
```
DEVELOPMENT-STATE-CHECKPOINT.md                   # Current state
PHASE2-DEPLOYMENT-COMPLETE.md                     # Previous work
packages/queue-worker/index.js                    # Current worker code
```

---

## 🔧 Prerequisites Check

Before starting Phase 3, verify:

### VPS Services Status:
```bash
# Check all services are running
ssh root@89.117.60.144 "docker ps"

# Should see:
✅ queue-worker (from Phase 2)
✅ supabase_db_my-project
✅ supabase_rest_my-project
✅ supabase_edge_runtime_my-project
```

### Video Services Status:
```bash
# Test Manim API
curl http://89.117.60.144:5000/health

# Test Revideo API
curl http://89.117.60.144:5001/health

# Test Video Orchestrator
curl http://89.117.60.144:8103/health
```

### Database Status:
```bash
# Check queue tables
curl "http://89.117.60.144:54321/rest/v1/jobs?select=id&limit=1" \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"

# Expected: [] (empty array, not error)
```

---

## 🎓 Development Workflow

### Step-by-Step Guide:

**Day 1: Admin Dashboard (4-5 hours)**
1. Review existing dashboard code
2. Deploy to Coolify
3. Add authentication
4. Test functionality

**Day 2: Video Service Integration (8-10 hours)**
1. Integrate Manim API
2. Integrate Revideo API
3. Integrate Video Orchestrator
4. Test each service independently

**Day 3: Testing & Polish (6-8 hours)**
1. Remove simulation code
2. Enhanced error handling
3. End-to-end integration test
4. Fix any bugs found

**Day 4: Documentation & Deployment (3-4 hours)**
1. Update all documentation
2. Create Phase 3 completion doc
3. Update checkpoint file
4. Final verification

---

## 🧪 Testing Plan

### Unit Tests
```bash
# Test video API integration functions
npm test packages/queue-worker/index.test.js
```

### Integration Tests
```bash
# Run E2E test script
./test-e2e-integration.sh
```

### Manual Tests
1. Open admin dashboard
2. Create test job via UI
3. Watch queue in real-time
4. Verify video generation
5. Play generated video

---

## 📊 Success Criteria

Phase 3 is complete when:

- ✅ Admin dashboard accessible and functional
- ✅ All 3 video services integrated
- ✅ Real video generated (not simulated)
- ✅ E2E test passes 3 times in a row
- ✅ Worker runs 24 hours without crashes
- ✅ Documentation updated
- ✅ All story tasks checked off

---

## 🔐 Environment Variables Needed

For admin dashboard deployment:

```bash
# Admin Dashboard
NEXT_PUBLIC_SUPABASE_URL=http://89.117.60.144:54321
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0

# Queue Worker (already configured in Phase 2)
SUPABASE_URL=http://89.117.60.144:54321
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU
WORKER_INTERVAL_MS=60000
```

---

## 🚨 Troubleshooting

### If Video Services Don't Respond:
```bash
# Check if services are running
ssh root@89.117.60.144 "docker ps | grep -E 'manim|revideo|orchestrator'"

# Check service logs
ssh root@89.117.60.144 "docker logs <container-name>"

# Restart if needed
ssh root@89.117.60.144 "docker restart <container-name>"
```

### If Worker Can't Connect to APIs:
1. Check network connectivity from worker container
2. Verify API endpoints are correct
3. Check for firewall issues
4. Test with curl from worker container:
   ```bash
   docker exec queue-worker curl http://89.117.60.144:5000/health
   ```

### If Dashboard Won't Deploy:
1. Check build logs in Coolify
2. Verify environment variables set
3. Check Node.js version compatibility
4. Test local build first: `npm run build`

---

## 📞 Support Resources

**Documentation:**
- Story 4.11: `docs/stories/4.11.queue-system-production-deployment.md`
- Phase 2 Completion: `PHASE2-DEPLOYMENT-COMPLETE.md`
- Development Checkpoint: `DEVELOPMENT-STATE-CHECKPOINT.md`

**Code References:**
- Queue Worker: `packages/queue-worker/index.js`
- Admin Dashboard: `apps/admin/src/app/queue/monitoring/page.tsx`
- Database Migration: `packages/supabase/supabase/migrations/009_video_jobs.sql`

**VPS Access:**
```bash
ssh root@89.117.60.144
# Password: 772877mAmcIaS
```

---

## 🎯 Next Steps After Phase 3

Once Phase 3 is complete:

**Phase 4: User-Facing Features**
- Story 4.1: Doubt Submission Interface
- Story 4.2: Doubt Processing Pipeline
- Story 4.3: Manim Scene Generation
- Story 4.4: Remotion Assembly
- Story 4.5: Video Response Interface

**Timeline:** Each story ~1-2 weeks

---

## ✅ Phase 3 Readiness Checklist

Before starting development:

- [x] Phase 2 complete and verified
- [x] Story 4.11 created
- [x] VPS services running
- [x] Database migration deployed
- [x] Queue worker operational
- [x] Development checkpoint documented
- [ ] Video services tested (verify before starting)
- [ ] Admin dashboard code reviewed
- [ ] Development environment ready

---

**Status:** ✅ READY TO BEGIN PHASE 3

**Estimated Duration:** 3-4 days (24-26 hours)

**Next Action:** Activate Dev Agent and execute Story 4.11

---

*Document created by PM Agent (BMAD Framework)*
*Last Updated: December 24, 2025*
