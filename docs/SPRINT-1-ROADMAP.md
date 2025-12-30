# Sprint 1 Roadmap: Epic 0 - Infrastructure Prerequisites

**Sprint Duration:** 10 working days (December 23, 2025 - January 3, 2026)
**Sprint Goal:** Validate and configure all VPS services, external APIs, and local development environment to ensure ZERO environment blockers before Epic 1 begins.
**Sprint Type:** Foundation Sprint (infrastructure setup)
**Scrum Master:** Bob

---

## Sprint Planning Summary

### Sprint Objective

By the end of this sprint, the team shall have:
- ✅ Verified VPS infrastructure (9 services operational)
- ✅ Tested all external API integrations (A4F Unified API, RevenueCat)
- ✅ Configured local development environment (Next.js + Supabase)
- ✅ Established CI/CD pipeline (GitHub Actions)
- ✅ Created integration testing framework
- ✅ Documented all findings and configurations

**Success Metric:** All 14 stories in Epic 0 completed with acceptance criteria met.

---

## Story Sequencing (Dependency-Driven)

### **Critical Path (Must Complete Sequentially):**

**Day 1:**
1. **Story 0.1: VPS Infrastructure Audit** (4-6 hours)
   - **Why First:** Must verify services exist before testing them
   - **Blocks:** All other stories depend on knowing VPS configuration
   - **Output:** Infrastructure inventory, service catalog

**Day 1-2:**
2. **Story 0.2: Supabase Local Development Setup** (6-8 hours)
   - **Dependency:** 0.1 (need Supabase URL/keys from audit)
   - **Why Critical:** Blocks all database work
   - **Output:** Local .env.local configured, connection verified

3. **Story 0.3: A4F Unified API Integration** (4-6 hours)
   - **Dependency:** None (external API)
   - **Why Critical:** Blocks all AI features (embeddings, LLM, TTS)
   - **Output:** All 7 models tested, fallback logic verified

### **Parallel Work (Can Execute Concurrently After Day 1):**

**Day 2-3:** _(After 0.1 completes, run these in parallel)_

4. **Story 0.4: Document Retriever (RAG Engine)** (6-8 hours)
   - **Dependency:** 0.1 (VPS audit), 0.2 (Supabase), 0.3 (A4F embeddings)
   - **Output:** RAG service tested, Edge Function wrapper created

5. **Story 0.5: Manim Renderer** (4-6 hours)
   - **Dependency:** 0.1 (VPS audit)
   - **Output:** Scene rendering tested, latency benchmarked

6. **Story 0.6: Revideo Renderer** (4-6 hours)
   - **Dependency:** 0.1 (VPS audit), 0.5 (Manim outputs)
   - **Output:** Video composition tested, TTS integration verified

7. **Story 0.7: DuckDuckGo Search Proxy** (3-4 hours)
   - **Dependency:** 0.1 (VPS audit)
   - **Output:** Search service tested, whitelisting verified

**Day 3:**

8. **Story 0.8: Video Orchestrator** (6-8 hours)
   - **Dependency:** 0.5 (Manim), 0.6 (Revideo), 0.3 (A4F TTS)
   - **Output:** Multi-step video workflow tested, job queue validated

9. **Story 0.9: Notes Generator** (4-6 hours)
   - **Dependency:** 0.4 (RAG Engine), 0.3 (A4F LLM)
   - **Output:** Notes synthesis tested, three-level output verified

10. **Story 0.10: Coolify Dashboard Access** (2-3 hours)
    - **Dependency:** 0.1 (VPS audit)
    - **Output:** Dashboard access verified, deployment workflow documented

### **Local Development Setup (Independent Track):**

**Day 4:** _(Can start Day 2, parallel to VPS testing)_

11. **Story 0.11: Full Stack Local Development** (8-10 hours)
    - **Dependency:** 0.2 (Supabase config)
    - **Output:** Turborepo monorepo initialized, Next.js apps configured

12. **Story 0.12: Git Repository & CI/CD Pipeline** (4-6 hours)
    - **Dependency:** 0.11 (project structure)
    - **Output:** GitHub repo created, CI pipeline functional

13. **Story 0.13: Environment Variables & Secrets** (3-4 hours)
    - **Dependency:** 0.2, 0.3 (all credentials known)
    - **Output:** .env.example complete, secrets documented

**Day 5:**

14. **Story 0.14: Integration Testing Framework** (6-8 hours)
    - **Dependency:** 0.2-0.9 (all services tested), 0.11 (project setup)
    - **Output:** Playwright configured, service mocks created, example E2E test

---

## Daily Sprint Schedule

### **Day 1 (Dec 23): Foundation Verification**

**Morning (4 hours):**
- Story 0.1: VPS Infrastructure Audit
- Output: Service catalog, health check results

**Afternoon (4 hours):**
- Story 0.2: Supabase Local Setup (partial)
- Story 0.3: A4F API Testing (start)

**End of Day Standup:**
- VPS services cataloged? (Yes/No)
- Blockers: Any services unreachable?

---

### **Day 2 (Dec 24): Service Integration Begins**

**Morning (4 hours):**
- Complete Story 0.2 (Supabase)
- Complete Story 0.3 (A4F API)
- Start Story 0.11 (Local Dev Setup)

**Afternoon (4 hours):**
- Parallel execution:
  - Team Member A: Story 0.4 (RAG Engine)
  - Team Member B: Story 0.5 (Manim)
  - Team Member C: Story 0.7 (Search Proxy)

**End of Day Standup:**
- Supabase connection working? (Blocker if no)
- A4F API all 7 models tested? (Blocker if no)
- How many VPS services tested? (Target: 3+)

---

### **Day 3 (Dec 25): Video Pipeline Testing**

**All Day (8 hours):**
- Complete Story 0.6 (Revideo)
- Complete Story 0.8 (Video Orchestrator)
- Complete Story 0.9 (Notes Generator)
- Complete Story 0.10 (Coolify Access)

**Critical Milestone:** Video pipeline end-to-end test (Manim → TTS → Revideo → Storage)

**End of Day Standup:**
- Can we render a test video? (Blocker if no)
- Video orchestration workflow clear? (Clarify if no)

---

### **Day 4 (Dec 26): Local Development Environment**

**All Day (8 hours):**
- Complete Story 0.11 (Full Stack Setup)
- Complete Story 0.12 (Git & CI/CD)
- Complete Story 0.13 (Environment Variables)

**Critical Milestone:** `pnpm dev` starts all apps successfully

**End of Day Standup:**
- Monorepo builds without errors? (Blocker if no)
- CI pipeline passing? (Fix if no)

---

### **Day 5 (Dec 27): Testing Framework**

**All Day (8 hours):**
- Complete Story 0.14 (Integration Testing)
- Write 1-2 example E2E tests

---

### **Days 6-9 (Dec 30 - Jan 2): Buffer & Refinement**

**Purpose:** Handle unexpected blockers, technical debt, documentation polish
**Activities:**
- Address any incomplete stories from Days 1-5
- Refine integration tests
- Update infrastructure documentation
- Team knowledge transfer sessions

---

### **Day 10 (Jan 3): Sprint Closure**

**Morning (4 hours):**
- Final validation: All 14 stories complete
- Run full test suite

**Afternoon (4 hours):**
- Sprint Review: Demo all working services
- Sprint Retrospective: Document issues, lessons learned
- Epic 0 Closure: Mark epic as "Complete"

**Sprint Definition of Done Checklist:**
- [ ] All 14 stories marked "Done"
- [ ] All acceptance criteria met (140 total ACs)
- [ ] Documentation updated (infrastructure-reference.md)
- [ ] Local dev environment functional (all devs can run `pnpm dev`)
- [ ] CI/CD pipeline passing (lint, type-check, build)
- [ ] No critical blockers identified for Epic 1

---

## Risk Management

### High-Risk Stories (Potential Sprint Blockers)

| Story | Risk | Mitigation |
|-------|------|------------|
| **0.1 VPS Audit** | VPS inaccessible or services down | Escalate to infrastructure team immediately, have backup VPS plan |
| **0.2 Supabase Setup** | Connection failures, auth errors | Test with both ANON and SERVICE_ROLE keys, check firewall rules |
| **0.3 A4F API** | Quota exceeded, API key invalid | Verify key with A4F support, have backup OpenAI key ready |
| **0.6 Revideo** | Video rendering fails, codec errors | Test with simple scene first, verify FFmpeg installed on VPS |
| **0.8 Orchestrator** | Multi-service coordination complex | Start with 2-step workflow (Manim → Storage), add complexity incrementally |

### Blocker Protocol

**If ANY story blocked for >4 hours:**
1. SM (Bob) escalates to team
2. Identify: Missing dependency? Architecture gap? External issue?
3. Options:
   - **De-scope:** Remove blocker AC, defer to Epic 1
   - **Pivot:** Work on parallel story while resolving
   - **Escalate:** Involve infrastructure team, A4F support, etc.

**Sprint Failure Condition:**
- If >3 stories remain blocked by end of Day 5 → Activate buffer days (6-9) for resolution
- If still blocked by Day 9 → Epic 0 scope reduced OR sprint extended

---

## Definition of Done (Sprint Level)

Epic 0 is "Done" when:
- ✅ All 14 stories have status = "Done"
- ✅ All 140 acceptance criteria validated
- ✅ Infrastructure documentation complete and accurate
- ✅ Local development environment tested by 2+ team members
- ✅ CI/CD pipeline passing on `main` branch
- ✅ No critical blockers identified for Epic 1
- ✅ PO acceptance obtained (Sarah validates Epic 0 completion)

**Sprint Review Attendees:**
- Product Owner (Sarah)
- Architect (Winston)
- Scrum Master (Bob)
- Dev Team
- Optional: QA (Quinn)

---

## Velocity Tracking (For Future Sprints)

**Sprint 1 Baseline Metrics:**
- Total Story Points: N/A (first sprint, no baseline)
- Total Stories: 14
- Total ACs: 140
- Estimated Hours: 70-90 hours
- Team Size: Assuming 1-2 developers

**Velocity Calculation (Post-Sprint):**
- Completed Stories / Sprint Duration = Stories per day
- Completed ACs / Sprint Duration = ACs per day
- Use for Sprint 2 planning (Epic 1)

---

**Sprint 1 Status:** Ready to Begin
**Next Action:** Dev Agent implements Story 0.1

