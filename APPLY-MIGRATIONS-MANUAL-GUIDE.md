# 🗄️ Apply Migrations 013-019 - Manual Guide

**Following BMAD Methodology**
**Required for:** Completing build and enabling all dashboard features

---

## 🎯 Why This is Needed

Your web app build is failing because these database tables don't exist yet:
- `answer_submissions`
- `essay_submissions`
- `practice_questions`
- `quiz_attempts`
- `mock_tests`
- `study_sessions`
- And 10+ more tables

**The migration files exist** in `packages/supabase/supabase/migrations/` but haven't been applied to your VPS database yet.

---

## 📋 Step-by-Step Instructions

### Step 1: Open Supabase Studio

1. Open your browser
2. Navigate to: **http://89.117.60.144:3000**
3. Log in if prompted

### Step 2: Go to SQL Editor

1. Click "SQL Editor" in the left sidebar
2. Click "New Query" button

### Step 3: Apply Migration 013

1. Open file: `packages\supabase\supabase\migrations\013_answer_writing.sql`
2. Select ALL content (Ctrl+A)
3. Copy (Ctrl+C)
4. Go back to Supabase Studio SQL Editor
5. Paste the SQL (Ctrl+V)
6. Click "RUN" button (bottom right)
7. Wait for success message
8. **Expected result:** "Answer writing migration completed successfully"

### Step 4: Apply Migration 014

1. Open file: `packages\supabase\supabase\migrations\014_pyq_videos.sql`
2. Copy ALL content
3. Paste in SQL Editor (you can use same tab or create new query)
4. Click "RUN"
5. Verify success

### Step 5: Apply Migrations 015-019

Repeat Step 4 for each migration:
- `015_daily_quiz.sql`
- `016_mock_tests.sql`
- `017_daily_ca_documentary.sql`
- `018_phase5_flagship.sql`
- `019_auth_profile_trigger.sql`

---

## ✅ Verification

After applying all migrations, verify tables exist:

**Test in Supabase Studio:**
1. Go to "Table Editor" (left sidebar)
2. You should see these NEW tables:
   - answer_submissions
   - essay_submissions
   - practice_questions
   - quiz_attempts
   - quiz_answers
   - mock_tests
   - study_sessions
   - daily_questions
   - answer_evaluations

**Test via API:**
```bash
curl "http://89.117.60.144:54321/rest/v1/answer_submissions?limit=1" \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
```

**Expected:** `[]` (empty array, not 404 error)

---

## 🔄 After Migrations Applied

Once all migrations are applied successfully, tell me:

**"Migrations applied"**

Then I will:
1. ✅ Regenerate TypeScript types from your VPS database
2. ✅ Complete the web app build
3. ✅ Continue with next sequential story implementation

---

## 🆘 Troubleshooting

**If migration fails with "already exists" error:**
- ✅ This is OK! It means the table was already created
- Continue with next migration

**If migration fails with other error:**
- Copy the error message
- Tell me the error
- I'll help fix it

**If you can't access Supabase Studio:**
- Verify VPS is running: http://89.117.60.144:3000
- Check if Docker container is up: `ssh root@89.117.60.144 "docker ps | grep supabase"`

---

**Following BMAD:** This is Story continuation work - migrations must be applied before frontend build can succeed.

**Ready when you are!** ✅
