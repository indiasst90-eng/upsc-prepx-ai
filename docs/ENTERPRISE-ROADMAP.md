# UPSC PrepX-AI: Enterprise Development Roadmap

**Version:** 4.0
**Created:** December 26, 2025
**Status:** In Progress - Phase 1
**Scrum Master:** Dev Agent (BMAD)

---

## Executive Summary

This document provides a **sequential, enterprise-grade development roadmap** for building the UPSC PrepX-AI platform. The roadmap follows BMAD methodology with strict dependency management, phase gates, and measurable milestones.

**Current State Assessment:**
- Infrastructure: ~70% complete (VPS services validated, A4F integrated)
- Auth System: ~90% complete (Supabase Auth working)
- RAG Core: ~50% complete (DB schema done, search pipe in progress)
- Monetization: ~60% complete (Trial logic, entitlements working)
- Video Pipeline: ~40% complete (Doubt→Video flow implemented)
- Frontend: ~40% complete (19 routes, core components)

---

## Development Phases (Sequential)

### PHASE 1: Foundation Core
**Duration:** 2-3 weeks | **Goal:** Core infrastructure stable, users can signup and search

| Order | Feature | Status | Stories | Days |
|-------|---------|--------|---------|------|
| 1.1 | Infrastructure Hardening | In Progress | 14 | 3 |
| 1.2 | Authentication Complete | ~90% | 3 | 1 |
| 1.3 | RAG Search Production | ~40% | 4 | 4 |
| 1.4 | Notes Generator Production | ~30% | 4 | 3 |
| 1.5 | Monetization Complete | ~60% | 5 | 3 |

**Phase 1 Gate Criteria:**
- [ ] Users signup/login with email + Google OAuth
- [ ] RAG search returns results <500ms with citations
- [ ] Notes generate at 3 levels (summary/detailed/comprehensive)
- [ ] 7-day trial auto-grants on signup
- [ ] Entitlement checks block unauthorized access
- [ ] No critical bugs in core flows

---

### PHASE 2: Daily Engagement
**Duration:** 2-3 weeks | **Goal:** Users return daily for short-form content

| Order | Feature | Status | Stories | Days |
|-------|---------|--------|---------|------|
| 2.1 | 60-Second Topic Shorts | 0% | 2 | 5 |
| 2.2 | Smart Bookmarks | 0% | 2 | 3 |
| 2.3 | Progress Dashboard | 10% | 3 | 4 |
| 2.4 | Doubt→Video v1 Complete | 60% | 2 | 3 |

**Phase 2 Gate Criteria:**
- [ ] 60s videos render <60s, 95% success rate
- [ ] Users can bookmark and schedule revisions
- [ ] Dashboard shows progress and weak areas
- [ ] Doubt video complete flow working
- [ ] Cost: <₹30/video validated

---

### PHASE 3: Practice & Assessment
**Duration:** 3-4 weeks | **Goal:** Deliberate practice with AI evaluation

| Order | Feature | Status | Stories | Days |
|-------|---------|--------|---------|------|
| 3.1 | Answer Writing + Scoring | 0% | 3 | 5 |
| 3.2 | Essay Trainer | 0% | 2 | 4 |
| 3.3 | PYQ Video Explanations | 10% | 3 | 5 |
| 3.4 | Test Series + Auto-grader | 0% | 3 | 5 |

**Phase 3 Gate Criteria:**
- [ ] AI scoring returns <30s, >90% accuracy
- [ ] Essay trainer provides video feedback
- [ ] PYQ explanations generate with diagrams
- [ ] Test series supports 100+ concurrent users
- [ ] 100 beta users complete practice loop

---

### PHASE 4: Scale & Automation
**Duration:** 3-4 weeks | **Goal:** Automated daily content, long-form learning

| Order | Feature | Status | Stories | Days |
|-------|---------|--------|---------|------|
| 4.1 | Daily CA Video Pipeline | 10% | 5 | 7 |
| 4.2 | Documentary Lectures | 0% | 2 | 5 |
| 4.3 | Book-to-Notes Converter | 20% | 2 | 4 |
| 4.4 | Advanced RAG Features | 0% | 3 | 4 |

**Phase 4 Gate Criteria:**
- [ ] Daily CA publishes at 6:00 AM IST, ≤5% failure
- [ ] 3-hour documentaries render successfully
- [ ] Book chapters convert to notes automatically
- [ ] Cost controls: <₹200/user/month
- [ ] 1000+ concurrent users supported

---

### PHASE 5: Flagship Features
**Duration:** 4-6 weeks | **Goal:** Premium differentiating features

| Order | Feature | Status | Stories | Days |
|-------|---------|--------|---------|------|
| 5.1 | Interview Prep Studio | 0% | 5 | 10 |
| 5.2 | Ethics Simulator | 0% | 3 | 5 |
| 5.3 | Memory Palace Videos | 0% | 2 | 4 |
| 5.4 | Gamification | 0% | 3 | 5 |

**Phase 5 Gate Criteria:**
- [ ] Real-time interview <500ms latency
- [ ] Manim generates visuals during interview (2-6s)
- [ ] Ethics case studies with scoring
- [ ] Gamification drives engagement
- [ ] All 34 features operational

---

## Detailed Implementation Plan

### PHASE 1: Foundation Core (Days 1-21)

#### 1.1 Infrastructure Hardening (Days 1-3)

**Goal:** Verify all services, fix gaps, establish monitoring

**Day 1: Service Validation**
```
Task 1.1.1: Verify all VPS services health
- Manim Renderer (5000)
- Revideo Renderer (5001)
- Document Retriever (8101)
- DuckDuckGo Search (8102)
- Video Orchestrator (8103)
- Notes Generator (8104)
- Supabase (8001)

Output: Service health report
```

**Day 2: Integration Testing**
```
Task 1.1.2: Test A4F API all models
- LLM (llama-4-scout, gpt-4.1 fallback)
- Embeddings (text-embedding-ada-002)
- TTS (tts-1)
- STT (whisper-1)
- Image (imagen-4, gemini-2.5-flash)

Output: Model latency/cost report
```

**Day 3: CI/CD & Monitoring**
```
Task 1.1.3: Establish CI pipeline
- GitHub Actions workflow
- Lint + Type-check + Build
- Integration test suite
- Error tracking (Sentry DSN)

Output: Passing CI pipeline
```

**Acceptance Criteria:**
- [ ] All 6 VPS services respond to health checks
- [ ] A4F API all 7 models working
- [ ] `pnpm build` succeeds without errors
- [ ] Monitoring dashboard active

---

#### 1.2 Authentication Complete (Day 4)

**Goal:** Fix gaps, add missing auth flows

**Current State:** ~90% complete
- [x] Email/password signup/login
- [x] Google OAuth
- [x] Password reset flow
- [ ] Phone OTP (missing)
- [ ] Session management improvements
- [ ] Security headers audit

**Tasks:**
```
Task 1.2.1: Add phone OTP authentication
- Integrate Supabase phone auth
- Add phone input to signup
- Verify OTP flow

Task 1.2.2: Security audit
- Add CSP headers
- Secure cookie settings
- RLS policy verification
```

**Acceptance Criteria:**
- [ ] Phone OTP login working
- [ ] Security headers passing audit
- [ ] All auth flows tested E2E
- [ ] No critical vulnerabilities

---

#### 1.3 RAG Search Production (Days 5-8)

**Goal:** Complete RAG pipeline, make search production-ready

**Current State:** ~40% complete
- [x] Database schema (syllabus_nodes, knowledge_chunks)
- [x] pgvector extension enabled
- [x] PDF upload table (pdf_uploads)
- [ ] process_pdf_pipe (partial - needs real PDF extraction)
- [ ] rag_search_pipe (started)
- [ ] Search UI (basic)

**Tasks:**

**Day 5: PDF Processing Pipeline**
```
Task 1.3.1: Implement real PDF text extraction
- Replace placeholder in process_pdf_pipe
- Use pdf-parse or pdf.js for extraction
- Handle scanned PDFs with OCR fallback

Task 1.3.2: Improve chunking algorithm
- Semantic chunking (paragraph-aware)
- Max 1000 tokens, 200 overlap
- Preserve context boundaries
```

**Day 6: Search Pipe Implementation**
```
Task 1.3.3: Complete rag_search_pipe
- Query embedding generation
- Vector similarity search (pgvector)
- Result reranking
- Source citation extraction

Task 1.3.4: Add hybrid search (keyword + vector)
- BM25 for keyword matching
- Combine with vector scores
- Fallback for edge cases
```

**Day 7: Search UI & Experience**
```
Task 1.3.5: Build production search UI
- Real-time search suggestions
- Result cards with citations
- Filters (GS1-4, Essay, CSAT)
- Related topics suggestions

Task 1.3.6: Performance optimization
- Query caching (Redis)
- Connection pooling
- <500ms latency target
```

**Day 8: Testing & Documentation**
```
Task 1.3.7: Search quality testing
- 50 test queries across all topics
- Accuracy validation
- Latency benchmarks

Task 1.3.8: Documentation
- API documentation
- Search usage guide
- Troubleshooting guide
```

**Acceptance Criteria:**
- [ ] PDF upload → chunk → embed → search E2E working
- [ ] Search returns results <500ms
- [ ] Citations include source chapter/page
- [ ] Search UI polished and responsive
- [ ] 95% accuracy on test queries

---

#### 1.4 Notes Generator Production (Days 9-11)

**Goal:** Complete notes generation, add export features

**Current State:** ~30% complete
- [x] notes_generation_pipe skeleton
- [x] 3-level output structure (summary/detailed/comprehensive)
- [ ] Integration with RAG for context
- [ ] PDF export
- [ ] Markdown export
- [ ] Notes UI

**Tasks:**

**Day 9: Backend Completion**
```
Task 1.4.1: Complete notes_generation_pipe
- RAG context retrieval for topic
- LLM prompt optimization (3 levels)
- Citation injection
- Error handling & retries

Task 1.4.2: Add streaming response
- Real-time token streaming
- Progress indicator
- Timeout handling
```

**Day 10: Export Functionality**
```
Task 1.4.3: PDF export
- Generate PDF from notes
- Proper formatting (headings, lists)
- Source citation appendix
- Download tracking

Task 1.4.4: Markdown export
- Clean markdown output
- Frontmatter metadata
- Image embedding support
```

**Day 11: UI & Integration**
```
Task 1.4.5: Build notes viewing UI
- Tabbed view (3 levels)
- Copy to clipboard
- Share functionality
- Related topics links

Task 1.4.6: Integration with search
- "Generate notes" button on search results
- Quick notes from syllabus node
- Notes history tracking
```

**Acceptance Criteria:**
- [ ] Notes generate for any syllabus topic
- [ ] All 3 levels populated correctly
- [ ] Citations from RAG sources
- [ ] PDF/Markdown export working
- [ ] Generation time <30s

---

#### 1.5 Monetization Complete (Days 12-14)

**Goal:** Complete trial logic, add payment integration

**Current State:** ~60% complete
- [x] 7-day trial auto-grant on signup
- [x] Entitlement checking system
- [x] Usage tracking (3 doubts/day free)
- [x] Trial countdown banner
- [ ] Payment gateway integration (pending)
- [ ] Subscription management UI
- [ ] RevenueCat webhook handler

**Tasks:**

**Day 12: Payment Integration**
```
Task 1.5.1: Integrate payment gateway
- Razorpay or Stripe India
- Subscription purchase flow
- Payment webhook handler
- Invoice generation

Task 1.5.2: RevenueCat integration
- Webhook for subscription events
- Entitlement sync
- Cancellation handling
- Refund processing
```

**Day 13: Subscription Management**
```
Task 1.5.3: Build subscription UI
- Pricing page (4 plans)
- Current plan display
- Upgrade/downgrade flow
- Payment method management

Task 1.5.4: Billing dashboard
- Subscription history
- Payment methods
- Invoice download
- Auto-renewal toggle
```

**Day 14: Trial Expiry & Grace Period**
```
Task 1.5.5: Complete trial expiry flow
- 3-day grace period implementation
- Grace period banner
- Grace period expiry downgrade
- Feature access notification

Task 1.5.6: Churn prevention
- Expiry reminder notifications
- Upgrade prompts
- Win-back campaigns
```

**Acceptance Criteria:**
- [ ] Users can purchase subscription
- [ ] Trial → Paid transition smooth
- [ ] Grace period working correctly
- [ ] Entitlement checks accurate
- [ ] Billing dashboard functional

---

### PHASE 1 COMPLETION CHECKLIST

Before proceeding to Phase 2, verify:

**Core Functionality:**
- [ ] Signup/Login works (email, phone, Google)
- [ ] RAG search returns results <500ms
- [ ] Notes generate at 3 levels
- [ ] PDF export works
- [ ] Trial auto-grants on signup
- [ ] Entitlement checks work

**Technical Quality:**
- [ ] No critical bugs
- [ ] 95%+ uptime on services
- [ ] CI pipeline passing
- [ ] Error tracking active
- [ ] Documentation complete

**Business Validation:**
- [ ] PO demos completed
- [ ] 10 alpha users tested
- [ ] User feedback incorporated
- [ ] Cost per user tracked
- [ ] No security vulnerabilities

**Sign-off Required:**
- [ ] Product Owner: Sarah
- [ ] Architect: Winston
- [ ] QA: Quinn

---

## Next Steps

### Immediate Action (Today)
```
1. Run infrastructure health check
2. Verify all VPS services responding
3. Test A4F API key validity
4. Identify gaps in current implementation
```

### This Week
```
Days 1-3: Infrastructure hardening
Days 4-5: Auth completion + phone OTP
Days 6-8: RAG search production
```

### Next Week
```
Days 9-11: Notes generator
Days 12-14: Monetization completion
```

---

## Risk Register

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| VPS services unstable | Medium | High | Fallback services, queue-based retries |
| A4F API rate limits | Medium | High | Caching, rate limiting, graceful degradation |
| RAG accuracy <95% | Low | High | Prompt engineering, corpus expansion |
| Payment gateway issues | Low | High | Test mode validation, support contracts |
| Cost overruns | Medium | Medium | Per-feature cost tracking, caps |

---

## Success Metrics

### Phase 1 Targets
- **Technical:** All 5 core features production-ready
- **User:** 10 alpha users signup, search, generate notes
- **Business:** Cost <₹50/user/month
- **Quality:** 95%+ uptime, <500ms search latency

### KPI Dashboard
| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| Signup conversion | 50% | - | 🔴 |
| Search success rate | 99% | - | 🔴 |
| Notes generation success | 98% | - | 🔴 |
| Trial → Paid conversion | 10% | - | 🔴 |
| Cost per user/month | <₹50 | - | 🔴 |

---

## Appendices

### A. Service URLs (VPS 89.117.60.144)
- Supabase API: `:8001`
- Supabase Studio: `:3000`
- Manim Renderer: `:5000`
- Revideo Renderer: `:5001`
- Document Retriever: `:8101`
- DuckDuckGo Search: `:8102`
- Video Orchestrator: `:8103`
- Notes Generator: `:8104`
- Coolify Dashboard: `:8000`

### B. Environment Variables Required
```
# Supabase
NEXT_PUBLIC_SUPABASE_URL
NEXT_PUBLIC_SUPABASE_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY

# A4F
A4F_API_KEY
A4F_BASE_URL

# VPS
VPS_MANIM_URL
VPS_REVIDEO_URL
VPS_RAG_URL
VPS_SEARCH_URL
VPS_ORCHESTRATOR_URL
VPS_NOTES_URL

# RevenueCat
REVENUECAT_PUBLIC_KEY
REVENUECAT_SECRET_API_KEY

# Payment
RAZORPAY_KEY_ID
RAZORPAY_KEY_SECRET
```

### C. Database Schema (Core Tables)
- `users` - User accounts
- `user_profiles` - Extended user data
- `subscriptions` - Subscription status
- `entitlements` - Feature access limits
- `pdf_uploads` - PDF file tracking
- `knowledge_chunks` - Vector-indexed content
- `syllabus_nodes` - UPSC syllabus taxonomy
- `jobs` - Video generation queue
- `audit_logs` - System audit trail

---

**Document Owner:** Dev Agent (BMAD)
**Last Updated:** December 26, 2025
**Next Review:** Phase 1 Gate Review
