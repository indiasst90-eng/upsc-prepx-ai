# 🗺️ Path A: Full Implementation Plan

**Decision:** Build complete auth + subscription system before user features
**Timeline:** 1-2 weeks
**Current Progress:** Story 1.3 in deployment

---

## 📋 Complete Implementation Sequence

### **Week 1: Foundation (Stories 1.3, 1.2, 1.9)**

#### **Story 1.3: Database Schema** (Day 1 - IN PROGRESS)
**Status:** Migration created, deploying to VPS
**File:** `packages/supabase/supabase/migrations/001_core_schema.sql`

**Remaining Steps:**
1. Verify migration applied successfully
2. Check all 6 tables created: users, user_profiles, plans, subscriptions, entitlements, audit_logs
3. Verify 4 subscription plans seeded
4. Restart Supabase REST API to refresh schema cache
5. Test tables via API

**Verification Commands:**
```bash
# Check tables
ssh root@89.117.60.144 "docker exec supabase_db_my-project psql -U postgres -d postgres -c '\dt public.*'"

# Check plans seeded
curl "http://89.117.60.144:54321/rest/v1/plans?select=*" -H "apikey: ANON_KEY"

# Restart REST API
ssh root@89.117.60.144 "docker restart supabase_rest_my-project"
```

**Time:** 1-2 hours remaining

---

#### **Story 1.2: Authentication System** (Days 2-3)
**File:** `docs/stories/1.2.authentication-system-supabase-auth.md`
**Tasks:** 13 tasks

**Day 2: Auth Configuration & Pages (6-8 hours)**
1. Configure Supabase Auth providers (Google OAuth, Email, Phone)
2. Create Supabase client utilities
3. Create auth middleware
4. Create login page
5. Create signup page
6. Implement OAuth callback handler

**Day 3: Advanced Features & Testing (6-8 hours)**
7. Implement user profile auto-creation trigger
8. Email verification flow
9. Password reset flow
10. Session persistence
11. Logout functionality
12. Auth context provider
13. Loading and error states
14. Unit and E2E tests

**Key Files to Create:**
```
apps/web/src/lib/supabase/client.ts
apps/web/src/lib/supabase/server.ts
apps/web/src/app/providers/AuthProvider.tsx
apps/web/src/app/(auth)/login/page.tsx
apps/web/src/app/(auth)/signup/page.tsx
apps/web/src/app/(auth)/forgot-password/page.tsx
apps/web/src/app/(auth)/reset-password/page.tsx
apps/web/src/app/auth/callback/route.ts
middleware.ts
lib/validations/auth.ts
```

**Time:** 12-16 hours (2-3 days)

---

#### **Story 1.9: Trial & Subscription Logic** (Days 4-5)
**File:** `docs/stories/1.9.trial-subscription-logic.md`

**Day 4: Trial Logic (6-8 hours)**
1. Auto-create trial on signup (database trigger - already in 001_core_schema.sql)
2. Entitlement check function
3. Trial expiry detection
4. Trial countdown display
5. Post-trial downgrade logic

**Day 5: Subscription Management (6-8 hours)**
6. Email notifications (trial reminders)
7. Trial status display
8. Admin trial extension
9. Analytics tracking
10. Testing and validation

**Key Files to Create:**
```
packages/supabase/supabase/functions/filters/entitlement_filter.ts
apps/web/src/lib/entitlements.ts
apps/web/src/components/TrialBanner.tsx
apps/web/src/app/api/entitlements/check/route.ts
```

**Time:** 12-16 hours (2-3 days)

---

### **Week 2: User Features (Stories 4.1, 4.2, 4.5)**

#### **Story 4.1: Doubt Submission Interface** (Days 6-7)
**File:** `docs/stories/4.1.doubt-submission-interface-text-image-input.md`

**Implementation:**
1. Doubt submission page
2. Text input component (2000 char limit)
3. Image upload with OCR (A4F Vision API)
4. Voice recording with transcription (A4F Whisper)
5. Style selector (concise/detailed/example-rich)
6. Video length selector (60s/120s/180s)
7. Voice preference selector
8. Preview mode
9. Entitlement checks
10. Submit to queue API
11. Unit tests

**Key Files:**
```
apps/web/src/app/(dashboard)/ask-doubt/page.tsx
apps/web/src/components/doubt/TextInput.tsx
apps/web/src/components/doubt/ImageUploader.tsx
apps/web/src/components/doubt/VoiceRecorder.tsx
apps/web/src/components/doubt/StyleSelector.tsx
apps/web/src/app/api/doubts/create/route.ts
```

**Time:** 12-16 hours (2 days)

---

#### **Story 4.2: Doubt Processing Pipeline** (Day 8)
Connect doubt submission to queue worker

**Time:** 4-6 hours (1 day)

---

#### **Story 4.5: Video Response Interface** (Day 9)
Display generated videos to users

**Time:** 4-6 hours (1 day)

---

## 📊 Detailed Timeline

| Day | Story | Tasks | Hours | Cumulative |
|-----|-------|-------|-------|------------|
| 1 | 1.3 (remaining) | Database verification | 2 | 2h |
| 2 | 1.2 (part 1) | Auth config & pages | 8 | 10h |
| 3 | 1.2 (part 2) | Advanced auth features | 8 | 18h |
| 4 | 1.9 (part 1) | Trial logic | 8 | 26h |
| 5 | 1.9 (part 2) | Subscription mgmt | 8 | 34h |
| 6 | 4.1 (part 1) | Doubt form & inputs | 8 | 42h |
| 7 | 4.1 (part 2) | OCR/STT & submission | 8 | 50h |
| 8 | 4.2 | Processing pipeline | 6 | 56h |
| 9 | 4.5 | Video player | 6 | 62h |

**Total:** ~62 hours (~8-9 full work days)

---

## 🎯 Immediate Next Steps (When Migration Completes)

### Step 1: Verify Core Schema
```bash
# Check all tables created
ssh root@89.117.60.144 "docker exec supabase_db_my-project psql -U postgres -d postgres -c '\d public.users'"

# Check plans seeded
ssh root@89.117.60.144 "docker exec supabase_db_my-project psql -U postgres -d postgres -c 'SELECT * FROM public.plans;'"

# Restart REST API
ssh root@89.117.60.144 "docker restart supabase_rest_my-project"

# Test via API
curl "http://89.117.60.144:54321/rest/v1/plans?select=*" -H "apikey: ANON_KEY"
```

### Step 2: Update Story 1.3 Status
Mark all tasks complete in `docs/stories/1.3.database-schema-core-tables.md`

### Step 3: Start Story 1.2 (Authentication)
```
*agent dev
*develop-story docs/stories/1.2.authentication-system-supabase-auth.md
```

---

## 📁 Files Ready for Story 1.2

**Migration:** Already created (001_core_schema.sql)
**Story File:** docs/stories/1.2.authentication-system-supabase-auth.md
**Example Code:** All included in story (Auth Provider, Middleware, etc.)

---

## 🔧 Quick Commands Reference

**Check Migration Status:**
```bash
ssh root@89.117.60.144 "docker logs supabase_db_my-project 2>&1 | tail -20"
```

**Apply Migration Manually (if needed):**
```bash
ssh root@89.117.60.144 "docker exec supabase_db_my-project psql -U postgres -d postgres -f /tmp/core_schema.sql"
```

**Verify Tables:**
```bash
ssh root@89.117.60.144 "docker exec supabase_db_my-project psql -U postgres -d postgres -c '\dt public.*'"
```

---

## 📊 Progress Tracking

**Completed:**
- ✅ Phase 2: Queue Infrastructure
- ✅ Phase 3: Video Integration & Dashboard
- ⏳ Story 1.3: Core Schema (deploying)

**Next:**
- Story 1.2: Authentication (2-3 days)
- Story 1.9: Subscriptions (2-3 days)
- Story 4.1: Doubt Submission (2-3 days)

**Total Remaining:** ~1-2 weeks

---

**Status:** Migration deploying, ready to continue with auth implementation once complete.

**Current Task:** Waiting for `001_core_schema.sql` to finish deploying

Would you like me to:
1. **Wait and verify** the migration completed
2. **Continue in next session** (save state and resume later)
3. **Manually deploy** the migration via Supabase Studio