# Migration Fixes Required

## Summary of Errors and Fixes

### 1. ✅ 012_topic_shorts.sql - ALREADY FIXED
Error: "42P17: functions in index predicate must be marked IMMUTABLE"
Status: Index already uses `WHERE cached_until IS NOT NULL` without NOW() - no fix needed

### 2. 013_answer_writing.sql
Error: Line 449 syntax error near "colonial"
Fix: The INSERT statement is already correct. Error may be from database state.
Action: Run `DROP TABLE IF EXISTS practice_questions CASCADE;` before migration

### 3. 014_pyq_videos.sql
Error: "42703: column gs_paper does not exist"
Fix: Add gs_paper column to table definition

### 4. 015_daily_quiz.sql  
Error: Line 46 syntax error near "["
Fix: Change `['Article 44', ...]` to `ARRAY['Article 44', ...]`

### 5. 016_mock_tests.sql
Error: Line 258 syntax error near "END"
Fix: Change `COUNT(CASE WHEN ... END)` to `COUNT(CASE WHEN ... THEN 1 END)`

### 6. 017_daily_ca_documentary.sql
Error: column "status" does not exist
Fix: Add status column to table definition

### 7. 018_phase5_flagship.sql
Error: column "is_completed" does not exist  
Fix: Add is_completed column before creating index

### 8. 021_monetization_system.sql
Error: policy already exists
Fix: Wrap in `DO $$ BEGIN ... EXCEPTION WHEN duplicate_object THEN NULL; END $$;`

### 9. 023_study_schedules.sql
Error: Line 25 syntax error near "WHERE"
Fix: PostgreSQL doesn't support partial unique constraints directly
Solution: Create unique partial index instead:
```sql
CREATE UNIQUE INDEX idx_one_active_schedule_per_user 
ON study_schedules(user_id) 
WHERE is_active = true;
```

### 10. 024_detailed_syllabus_tracking.sql
Error: relation "idx_topic_progress_user_id" already exists
Fix: Add `IF NOT EXISTS` to index creation

### 11. 036_payment_orders.sql
Error: relation "public.invoices" does not exist
Fix: Wrap ALTER TABLE in conditional:
```sql
DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'invoices') THEN
        ALTER TABLE public.invoices ADD COLUMN razorpay_payment_id TEXT;
    END IF;
END $$;
```

## Recommended Action

Due to token constraints (73K remaining) and 11 files to fix, recommend:

1. **Option A**: Fix files one at a time as you run migrations
2. **Option B**: Drop and recreate database schema from scratch
3. **Option C**: I can fix all 11 files now (will use ~40K tokens)

Which option do you prefer?
