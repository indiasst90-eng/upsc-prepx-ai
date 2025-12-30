# Build Order Review & Dependency Analysis

**Created:** December 23, 2025
**Scrum Master:** Bob
**Purpose:** Enforce strict sequencing, identify risks, prevent phase-skipping

---

## Executive Summary

**Build Philosophy:** A slow, controlled build beats a fast, chaotic one.

**Total Features:** 34 features across 17 epics (Epic 0-16)
**Build Duration:** 26 weeks (6 months) for all features, 19 weeks (4.5 months) for MVP
**Current Status:** Sprint 1 ready to begin (Epic 0)

**Critical Finding:** The default PRD epic order (Epic 1 → 2 → 3 → 4...) **VIOLATES dependency sequencing**. This document establishes the enforced build order based on technical dependencies.

---

## Dependency Analysis (Why Order Matters)

### ❌ **WRONG Build Order (By Epic Number)**

Epic 1 → Epic 2 → Epic 3 → Epic 4 → Epic 5...

**Problems:**
- Epic 3 (Daily CA Video) comes before Epic 4 (Topic Shorts)
  - **Issue:** Daily CA is 5-8 min (complex), Topic Shorts are 60s (simple)
  - **Risk:** Building complex before simple = higher failure risk

- Epic 13 (Interview Studio) comes late but requires early validation
  - **Issue:** Real-time latency (2-6s Manim) needs early testing
  - **Risk:** Discover latency issues in Week 20 (too late to fix architecture)

- Epic 5 (Monetization) comes after Epic 4 (Doubt Converter)
  - **Issue:** Doubt Converter is premium, needs entitlement checks
  - **Risk:** Build premium feature before access control = rework

### ✅ **CORRECT Build Order (By Dependency)**

**Phase 1:** C0 → C1 → C2 → C3 (Foundation)
**Phase 2:** C4 → C1-Extended (Daily Usage)
**Phase 3:** C5 (Practice, depends on C2 + C3)
**Phase 4:** C6 (Long Videos, depends on C4 proven)
**Phase 5:** C7 (Flagship, depends on C6 maturity)

**Rationale:**
- Simple before complex (60s videos before 3-hour documentaries)
- Foundation before features (RAG before notes, notes before practice)
- Access control before premium features (monetization before doubt converter)
- Proven systems before flagship (video pipeline mature before real-time interview)

---

## Critical Dependency Chains

### **Chain 1: RAG → Notes → Practice**

```
Epic 1 (RAG Search) → Epic 2 (Notes Generation) → Epic 7-8 (Practice & Evaluation)
```

**Why This Order:**
- **RAG First:** Provides grounding for all AI-generated content
- **Notes Second:** Proves RAG + LLM integration, simpler than practice
- **Practice Third:** Answer scoring requires notes as reference material

**Blocker if Reversed:**
- Building practice before notes = no reference material for scoring
- Building notes before RAG = hallucinated content (99% accuracy impossible)

---

### **Chain 2: Infrastructure → Auth → Monetization → Premium Features**

```
Epic 0 (Infrastructure) → Epic 1.1-1.2 (Auth) → Epic 5 (Monetization) → Epic 4, 7-8, 13 (Premium)
```

**Why This Order:**
- **Infrastructure First:** Without VPS, nothing works
- **Auth Second:** Users need accounts before subscriptions
- **Monetization Third:** Entitlement checks before premium features
- **Premium Features Last:** Requires working access control

**Blocker if Reversed:**
- Building premium features before monetization = free access to everything (revenue loss)
- Building monetization before auth = no user accounts to charge

---

### **Chain 3: Video Short → Video Medium → Video Long → Video Real-time**

```
Epic 4 (60s Shorts) → Epic 4 (2-3 min Doubts) → Epic 3 (5-8 min Daily CA) → Epic 10 (3 hour Docs) → Epic 13 (Real-time Interview)
```

**Why This Order:**
- **Complexity Progression:** 60s → 3 min → 8 min → 3 hours → real-time
- **Risk Management:** Fail fast on simple (60s) before investing in complex (3 hours)
- **Cost Learning:** Understand costs at small scale before large scale
- **Latency Validation:** Prove 2-6s Manim latency on simple before attempting real-time

**Blocker if Reversed:**
- Building 3-hour documentary before 60s short = waste time on complex if simple doesn't work
- Building real-time interview before proving 2-6s latency = architecture failure discovered too late

---

## Epic Reordering (Enforced by SM)

### **Original PRD Epic Order:**

Epic 1 → Epic 2 → Epic 3 → Epic 4 → Epic 5 → Epic 6 → ... → Epic 16

### **SM Enforced Build Order (By Cluster):**

1. **Epic 0** (Infrastructure) - Week 1
2. **Epic 1** (Stories 1.1-1.8) - Week 1-2
3. **Epic 2** (Stories 2.1-2.4) - Week 2-3
4. **Epic 5** (Stories 5.1-5.5) - Week 3-4
5. **Epic 4** (Stories 4.4-4.5, Topic Shorts only) - Week 5-6
6. **Epic 1** (Stories 1.9-1.10) - Week 7
7. **Epic 6** (Stories 6.1-6.3) - Week 7-8
8. **Epic 7** (Stories 7.1-7.4) - Week 9-10
9. **Epic 8** (Stories 8.1-8.3) - Week 10-11
10. **Epic 2** (Stories 2.5-2.7, Syllabus Navigator) - Week 11-12
11. **Epic 3** (Daily CA, Stories 3.1-3.5) - Week 13-14
12. **Epic 10** (Documentary, Stories 10.1-10.2) - Week 15-16
13. **Epic 9** (Advanced Tools, Stories 9.1-9.3) - Week 16-17
14. **Epic 4** (Stories 4.1-4.3, Doubt Converter full) - Week 17-18
15. **Epic 13** (Interview Studio) - Week 19-20
16. **Epic 12** (Ethics & Interview Prep) - Week 21-22
17. **Epic 15** (Immersive Experiences) - Week 22-23
18. **Epic 14** (Gamification) - Week 24-25
19. **Epic 11, 16** (Specialized features) - Week 26+

**Key Changes from PRD Order:**
- Epic 5 (Monetization) moved from position 5 to position 4 (before video features)
- Epic 4 split: Topic Shorts (Week 5-6) vs Doubt Converter (Week 17-18)
- Epic 3 moved from position 3 to position 11 (after short videos proven)
- Epic 13 moved from position 13 to position 15 (after video pipeline mature)

---

## Feature Blocking Matrix

**This matrix shows which features BLOCK others:**

| Feature (Epic.Story) | Blocks | Reason |
|----------------------|--------|--------|
| **Epic 0 (All)** | All other epics | Infrastructure foundation |
| **Epic 1.2 (Auth)** | All protected features | Need user accounts |
| **Epic 1.4 (pgvector)** | Epic 1.7 (RAG), Epic 2 (Notes), Epic 4 (Doubt) | Vector search required |
| **Epic 1.7 (RAG Search)** | Epic 2 (Notes), Epic 4 (Doubt), Epic 7-8 (Practice) | Context retrieval required |
| **Epic 5.3 (Entitlements)** | Epic 4 (Doubt), Epic 7-8 (Practice), Epic 13 (Interview) | Access control required |
| **Epic 4.4 (Topic Shorts)** | Epic 3 (Daily CA), Epic 10 (Documentary) | Prove simple before complex |
| **Epic 3 (Daily CA)** | Epic 13 (Interview - real-time) | Prove scheduled jobs before real-time |
| **Epic 2.1 (Notes)** | Epic 7-8 (Practice scoring) | Reference material for AI grading |

**Blocking Count:**
- Epic 0 blocks: 16 epics (everything)
- Epic 1 blocks: 12 epics (most features)
- Epic 5 blocks: 8 epics (all premium)
- Epic 4 blocks: 4 epics (video pipeline)
- Epic 2 blocks: 2 epics (practice features)

---

## Risk Assessment by Phase

### Phase 1 Risks (Foundation)

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| VPS services unreachable | Medium | CRITICAL | Story 0.1 catches early, have backup VPS plan |
| A4F API quota exceeded | Low | HIGH | Test with small volume first, monitor usage daily |
| pgvector performance issues | Medium | HIGH | Benchmark with 100K chunks in Story 1.4, optimize indexes |
| RevenueCat integration complex | Medium | MEDIUM | Start with test mode, defer live payments to Week 4 |
| Manim rendering slow (>6s) | High | HIGH | Test in Story 0.5, may need GPU upgrade or caching |

**Highest Risk:** Manim latency >6s makes real-time interview impossible (Epic 13 blocked)

### Phase 2 Risks (Daily Usage)

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| 60s video costs >₹30 | Medium | HIGH | Aggressive Manim scene caching, limit LLM calls |
| Video rendering failures (>5%) | Medium | MEDIUM | Retry logic (3 attempts), fallback to static content |
| Bookmark sync conflicts | Low | LOW | Use Supabase real-time, last-write-wins strategy |

### Phase 3 Risks (Practice)

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| AI scoring inaccurate (<80%) | High | CRITICAL | Extensive SME validation, tuning, possible model upgrade |
| Video feedback generation slow (>60s) | Medium | MEDIUM | Pre-render common feedback templates, cache |

### Phase 4 Risks (Scale)

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Daily CA misses 6 AM deadline | Medium | HIGH | 10-min buffer (publish by 5:50 AM), fallback content ready |
| 3-hour documentary rendering timeout | High | MEDIUM | Break into 20-min segments, stitch separately |
| Cost explosion (>₹500/daily CA) | Low | HIGH | Monitor first 7 days closely, optimize aggressively |

### Phase 5 Risks (Flagship)

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Real-time latency >2s (unusable) | High | CRITICAL | Early prototype in Phase 2, GPU optimization, caching |
| 360° immersive rendering too complex | Medium | MEDIUM | Defer if blocking, not core to MVP |

---

## Sprint Capacity Planning

**Assumptions:**
- **Team Size:** 1-2 developers (AI-assisted via Claude Code)
- **Sprint Duration:** 10-14 days (10 for simple epics, 14 for complex)
- **Daily Capacity:** 6-8 productive hours per dev

**Sprint 1 (Epic 0):**
- Stories: 14
- Total ACs: 140
- Estimated Hours: 70-90 hours
- Team: 1-2 devs
- Duration: 5 days (short sprint for setup)

**Sprint 2 (Epic 1, C1):**
- Stories: 8
- Total ACs: 80
- Estimated Hours: 80-100 hours
- Duration: 10 days

**Sprint 3 (Epic 2, C2):**
- Stories: 4
- Total ACs: 40
- Estimated Hours: 40-50 hours
- Duration: 10 days (buffer for testing)

**Velocity Tracking:**
- After Sprint 1: Calculate actual hours per AC
- Adjust Sprint 2-3 estimates based on Sprint 1 actuals
- By Sprint 4: Reliable velocity metric for future planning

---

## Definition of Done (Cluster Level)

A cluster is "Done" and stable when:

✅ **All stories completed** with status = "Done"
✅ **All ACs validated** by PO (Sarah)
✅ **Architecture patterns followed** (no violations requiring refactor)
✅ **QA validation passed** (Quinn reviews and approves)
✅ **Cost impact measured** (actual cost vs budget documented)
✅ **Feature gating correct** (free/premium access working)
✅ **Performance targets met** (latency, success rate, uptime)
✅ **No critical bugs** (showstoppers fixed before marking complete)
✅ **Documentation updated** (README, architecture, infrastructure-ref)
✅ **Monitoring in place** (errors logged, alerts configured)

**If ANY criterion fails:** Cluster is NOT stable → Do NOT proceed to next cluster

---

## Phase-Skipping Prevention

### SM Will STOP Work If:

❌ **Dev starts Epic 3 before Epic 4 proven**
- Action: Stop sprint, revert to Epic 4, validate short videos first

❌ **Dev adds features not in PRD**
- Action: Remove code, escalate to PO for approval

❌ **Dev bypasses entitlement checks**
- Action: Block merge, require entitlement filter added

❌ **Dev uses different tech than architecture**
- Action: Revert code, escalate to Architect (Winston) for approval

❌ **PO changes scope mid-sprint**
- Action: Halt sprint, renegotiate sprint goal, possibly cancel sprint

### SM Will ALLOW Flexibility On:

✅ **Internal refactoring** (if doesn't change API contracts)
✅ **Performance optimizations** (if maintains behavior)
✅ **Test additions** (more tests always welcome)
✅ **Documentation improvements** (better clarity)
✅ **Bug fixes** (even if not in sprint plan)

---

## Go/No-Go Decision Points

### Sprint 1 Go/No-Go (After Day 3)

**Decision Point:** December 26, 2025 (Day 3 of 5)

**Go Criteria:**
- ✅ VPS infrastructure audit complete (Story 0.1 Done)
- ✅ At least 6/9 VPS services responding to health checks
- ✅ Supabase connection working (Story 0.2 Done)
- ✅ A4F API tested (at least 4/7 models working)

**No-Go Triggers:**
- ❌ VPS completely inaccessible → STOP, escalate to infrastructure team
- ❌ Supabase connection failing → STOP, investigate network/firewall
- ❌ A4F API key invalid → STOP, contact A4F support

**If No-Go:** Extend sprint by 2 days OR reduce Epic 0 scope (defer non-critical stories to Sprint 2)

### Phase 1 Go/No-Go (After Week 4)

**Decision Point:** End of Sprint 4 (Week 4)

**Go Criteria:**
- ✅ All C0, C1, C2, C3 clusters stable
- ✅ 10 alpha users tested platform (signup, search, notes, trial)
- ✅ Search latency <500ms validated
- ✅ Cost per user <₹50/month achieved
- ✅ Zero critical bugs in foundation

**No-Go Triggers:**
- ❌ Search accuracy <90% → STOP, improve RAG before proceeding
- ❌ Cost >₹100/user → STOP, optimize before scaling
- ❌ Critical bugs in auth or subscriptions → STOP, fix foundation

**If No-Go:** Add Sprint 4.5 (hardening sprint), do NOT proceed to Phase 2 until stable

---

## Blocker Escalation Matrix

| Blocker Type | SM Action | Escalate To | Timeframe |
|--------------|-----------|-------------|-----------|
| **Missing PO Clarity** | Document ambiguity | Sarah (PO) | Immediate |
| **Architecture Conflict** | Stop work, review docs | Winston (Architect) | Same day |
| **Cost Explosion** | Measure impact | Sarah (PO) + Winston | Same day |
| **External Service Down** | Document, find workaround | Infrastructure team | 4 hours |
| **Scope Creep** | Reject changes | Sarah (PO) for approval | Immediate |
| **Technical Blocker** | Research, prototype | Winston (Architect) or Dev team | 1-2 days |

**Escalation Rule:** If blocker unresolved in timeframe → Halt sprint, call emergency meeting

---

## Cluster Stability Checklist

### C0: Infrastructure Foundation

- [ ] All 14 stories in Epic 0 marked "Done"
- [ ] All 9 VPS services health checks passing
- [ ] Local `pnpm dev` starts all apps without errors
- [ ] CI pipeline passing (lint, type-check, build)
- [ ] Integration test framework has 2+ example tests passing
- [ ] No infrastructure issues identified

**Gate Keeper:** Bob (SM) validates all checkboxes before declaring "C0 Stable"

### C1: Knowledge & RAG Core

- [ ] All 8 stories (1.1-1.8) marked "Done"
- [ ] Users can signup with Google/Email/Phone
- [ ] PDFs can be uploaded and automatically chunked
- [ ] RAG search returns results in <500ms (P95)
- [ ] Search confidence scores working (high/moderate/low)
- [ ] Search accuracy >95% (validated with 50 test queries)
- [ ] No critical auth or database issues

**Gate Keeper:** Sarah (PO) validates search quality

### C2: Notes & Content Generation

- [ ] All 4 stories (2.1-2.4) marked "Done"
- [ ] Notes generate for any syllabus topic
- [ ] Three levels (summary, detailed, comprehensive) all accurate
- [ ] RAG sources properly cited
- [ ] PDF/Markdown export working
- [ ] Notes quality validated by SME (5 sample topics reviewed)

**Gate Keeper:** Sarah (PO) + SME validate content accuracy

### C3: Monetization Infrastructure

- [ ] All 5 stories (5.1-5.5) marked "Done"
- [ ] 7-day trial auto-granted on signup
- [ ] Trial expiry downgrade works correctly
- [ ] Entitlement checks block free users
- [ ] Subscription plans purchasable (test mode)
- [ ] RevenueCat webhook handler tested

**Gate Keeper:** Bob (SM) + QA (Quinn) validate trial/subscription flows with 10 test accounts

### C4: Video Generation (Short)

- [ ] 60s topic videos render in <60s (P95)
- [ ] Video quality acceptable (1080p, clear audio)
- [ ] Costs <₹30/video validated
- [ ] 95%+ success rate (5% retries acceptable)
- [ ] Social media publishing tested (dry run)

**Gate Keeper:** Bob (SM) reviews 20 sample videos, validates cost data

### C5: Practice & Evaluation

- [ ] Answer writing submissions scored in <30s
- [ ] AI scoring accuracy >90% (correlation with SME scores)
- [ ] Video feedback generated correctly
- [ ] Test series handles 100+ concurrent users
- [ ] PYQ explanations accurate

**Gate Keeper:** Sarah (PO) + SME validate scoring quality

### C6: Video Generation (Long)

- [ ] Daily CA video publishes at 6:00 AM IST (30-day track record)
- [ ] ≤5% failure rate (≤1-2 failures per month)
- [ ] 3-hour documentaries render successfully (2+ completed)
- [ ] Cost per daily CA <₹500
- [ ] Content accuracy >99% (weekly SME spot checks)

**Gate Keeper:** Bob (SM) reviews 30-day operational data

### C7: Flagship & Real-time

- [ ] Real-time interview latency <500ms
- [ ] Manim renders in 2-6s during interview
- [ ] 100+ users completed interview sessions
- [ ] 360° immersive videos render
- [ ] Gamification drives engagement (analytics show +20% retention)

**Gate Keeper:** Sarah (PO) validates flagship features justify premium pricing

---

## Build Order Summary (Visual)

**Timeline:**

```
Weeks 1-4:   [C0] [C1] [C2] [C3] ← PHASE 1: Foundation
Weeks 5-8:   [C4] [C1-Ext] ← PHASE 2: Daily Usage
Weeks 9-12:  [C5] ← PHASE 3: Practice
Weeks 13-16: [C6] ← PHASE 4: Scale
Weeks 17-26: [C7] ← PHASE 5: Flagship
```

**Dependency Flow:**

```
C0 (Infra) →
  ├→ C1 (RAG) →
  │    ├→ C2 (Notes) → C5 (Practice)
  │    ├→ C4 (Video Short) → C6 (Video Long) → C7 (Flagship)
  │    └→ C1-Ext (Bookmarks, Dashboards)
  └→ C3 (Monetization) → C5 (Practice)
```

---

## Enforcement Actions (SM Responsibilities)

### What SM Will Do to Enforce Order:

1. **Block premature story creation**
   - If Dev requests Story 3.1 before Story 4.4 complete → DENY
   - Redirect to correct next story per roadmap

2. **Reject scope changes mid-sprint**
   - If PO adds AC during sprint → DEFER to next sprint

3. **Halt work on architecture violations**
   - If Dev bypasses Pipes/Filters/Actions → STOP, refactor required

4. **Escalate cost overruns**
   - If feature exceeds budget by >50% → HALT, escalate to PO + Architect

5. **Enforce Definition of Done**
   - If story marked "Done" without QA validation → REVERT to "Review"

### What SM Will NOT Do:

❌ Change feature scope (PO decides)
❌ Override architecture decisions (Architect decides)
❌ Skip testing (QA decides readiness)
❌ Rush sprints to hit arbitrary dates

---

## Retrospective Focus Areas (Per Phase)

### Phase 1 Retrospective Topics

- **Velocity:** Did we estimate accurately? (Story points vs actuals)
- **Blockers:** How many blockers encountered? Resolution time?
- **Architecture:** Were patterns clear? Any confusion?
- **Quality:** Bug count? Escaped to production?
- **Process:** Did strict sequencing help or hinder?

### Phase 2 Retrospective Topics

- **Cost:** Actual vs estimated per video? Optimizations needed?
- **User Feedback:** Alpha users finding features useful? (NPS)
- **Video Quality:** Rendering failures? Audio sync issues?
- **Engagement:** Are bookmarks and dashboards driving daily usage?

### Phase 3 Retrospective Topics

- **Accuracy:** AI scoring correlation with SME scores? (Target: >90%)
- **Performance:** Scoring latency acceptable? (<30s target)
- **User Value:** Are users improving measurably? (test score progression)

### Phase 4 Retrospective Topics

- **Reliability:** Daily CA publish success rate? (Target: ≥95%)
- **Scale:** Platform handling 1000+ users? Performance degradation?
- **Cost Control:** Still under ₹200/user/month? (Critical threshold)

### Phase 5 Retrospective Topics

- **Real-time:** Latency acceptable for interview? (<500ms)
- **Premium Value:** Do flagship features justify ₹999/month? (user surveys)
- **Differentiation:** Is platform unique vs competitors? (market positioning)

---

**Roadmap Status:** Enforced
**Next Sprint:** Sprint 1 (Epic 0, 5 days)
**Current Phase:** Phase 1 (Foundation)
**Current Cluster:** C0 (Infrastructure Foundation)

**SM Bob's Commitment:** I will block any attempt to skip phases, rush features, or bypass dependencies. Stability over velocity. Always.

