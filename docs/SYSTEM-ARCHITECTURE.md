# Video Queue Management - System Architecture

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER REQUESTS                            │
│  (Doubt Videos, Topic Shorts, Daily CA)                         │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    JOB SUBMISSION API                            │
│  - Validate request                                              │
│  - Assign priority (high/medium/low)                            │
│  - Insert into jobs table                                        │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                      JOBS TABLE (Queue)                          │
│  ┌──────────┬──────────┬──────────┬──────────┐                 │
│  │ Priority │  Status  │ Position │ Payload  │                 │
│  ├──────────┼──────────┼──────────┼──────────┤                 │
│  │   HIGH   │  queued  │    1     │   {...}  │ ← Doubt         │
│  │   HIGH   │  queued  │    2     │   {...}  │ ← Doubt         │
│  │  MEDIUM  │  queued  │    3     │   {...}  │ ← Topic Short   │
│  │   LOW    │  queued  │    4     │   {...}  │ ← Daily CA      │
│  └──────────┴──────────┴──────────┴──────────┘                 │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│              VIDEO QUEUE WORKER (Cron: */1 * * * *)             │
│                                                                  │
│  ┌────────────────────────────────────────────────────┐        │
│  │  1. Check Timeouts                                  │        │
│  │     - Find jobs running > 10 minutes                │        │
│  │     - Retry or fail based on retry_count            │        │
│  └────────────────────────────────────────────────────┘        │
│                         │                                        │
│  ┌────────────────────────────────────────────────────┐        │
│  │  2. Check Concurrency Limits                        │        │
│  │     - Max 10 total renders                          │        │
│  │     - Max 4 Manim renders                           │        │
│  │     - Peak hour scaling (1.5x)                      │        │
│  └────────────────────────────────────────────────────┘        │
│                         │                                        │
│  ┌────────────────────────────────────────────────────┐        │
│  │  3. Dequeue Next Job (FIFO within priority)        │        │
│  │     - Order by: priority ASC, created_at ASC        │        │
│  │     - Update status to 'processing'                 │        │
│  └────────────────────────────────────────────────────┘        │
│                         │                                        │
│  ┌────────────────────────────────────────────────────┐        │
│  │  4. Process Video Job                               │        │
│  │     - Call appropriate pipe (doubt/topic/daily_ca)  │        │
│  │     - Monitor progress                              │        │
│  │     - Handle errors                                 │        │
│  └────────────────────────────────────────────────────┘        │
│                         │                                        │
│  ┌────────────────────────────────────────────────────┐        │
│  │  5. Update Job Status                               │        │
│  │     - Success: status = 'completed'                 │        │
│  │     - Failure: retry or mark as 'failed'            │        │
│  └────────────────────────────────────────────────────┘        │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    VIDEO GENERATION PIPES                        │
│  ┌──────────────────┬──────────────────┬──────────────────┐    │
│  │ Doubt Video Pipe │ Topic Short Pipe │ Daily CA Pipe    │    │
│  │  - Script Gen    │  - Script Gen    │  - Script Gen    │    │
│  │  - Manim Render  │  - Manim Render  │  - Manim Render  │    │
│  │  - Video Compose │  - Video Compose │  - Video Compose │    │
│  └──────────────────┴──────────────────┴──────────────────┘    │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                      COMPLETED VIDEOS                            │
│  - Stored in database                                            │
│  - Delivered to users                                            │
│  - Analytics tracked                                             │
└─────────────────────────────────────────────────────────────────┘
```

---

## Database Schema

```
┌─────────────────────────────────────────────────────────────────┐
│                         jobs TABLE                               │
├─────────────────────────────────────────────────────────────────┤
│ id                UUID PRIMARY KEY                               │
│ job_type          TEXT ('doubt', 'topic_short', 'daily_ca')     │
│ priority          TEXT ('high', 'medium', 'low')                 │
│ status            TEXT ('queued', 'processing', 'completed',     │
│                        'failed', 'cancelled')                    │
│ payload           JSONB (job-specific data)                      │
│ queue_position    INTEGER (auto-calculated)                      │
│ retry_count       INTEGER DEFAULT 0                              │
│ max_retries       INTEGER DEFAULT 3                              │
│ error_message     TEXT                                           │
│ started_at        TIMESTAMPTZ                                    │
│ completed_at      TIMESTAMPTZ                                    │
│ created_at        TIMESTAMPTZ DEFAULT NOW()                      │
│ updated_at        TIMESTAMPTZ DEFAULT NOW()                      │
│ user_id           UUID REFERENCES auth.users(id)                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                   job_queue_config TABLE                         │
├─────────────────────────────────────────────────────────────────┤
│ id                        UUID PRIMARY KEY                       │
│ max_concurrent_renders    INTEGER DEFAULT 10                     │
│ max_manim_renders         INTEGER DEFAULT 4                      │
│ job_timeout_minutes       INTEGER DEFAULT 10                     │
│ retry_interval_minutes    INTEGER DEFAULT 5                      │
│ peak_hour_start           TIME DEFAULT '06:00'                   │
│ peak_hour_end             TIME DEFAULT '21:00'                   │
│ peak_worker_multiplier    DECIMAL DEFAULT 1.5                    │
│ created_at                TIMESTAMPTZ DEFAULT NOW()              │
│ updated_at                TIMESTAMPTZ DEFAULT NOW()              │
└─────────────────────────────────────────────────────────────────┘
```

---

## Queue Processing Flow

```
START
  │
  ▼
┌─────────────────────┐
│ Cron Trigger        │ Every 1 minute
│ (*/1 * * * *)       │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Check Timeouts      │
│ - Find stuck jobs   │
│ - Retry or fail     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Check Concurrency   │
│ - Count processing  │
│ - Check limits      │
└──────────┬──────────┘
           │
           ▼
      ┌────────┐
      │ Limits │
      │ OK?    │
      └───┬────┘
          │
    NO ◄──┴──► YES
    │           │
    ▼           ▼
┌────────┐  ┌─────────────────────┐
│ Wait   │  │ Dequeue Next Job    │
│ & Exit │  │ - Priority order    │
└────────┘  │ - FIFO within level │
            └──────────┬──────────┘
                       │
                       ▼
            ┌─────────────────────┐
            │ Update Status       │
            │ status = processing │
            │ started_at = NOW()  │
            └──────────┬──────────┘
                       │
                       ▼
            ┌─────────────────────┐
            │ Call Video Pipe     │
            │ - doubt_video_pipe  │
            │ - topic_short_pipe  │
            │ - daily_ca_pipe     │
            └──────────┬──────────┘
                       │
                  ┌────┴────┐
                  │ Success?│
                  └────┬────┘
                       │
                 YES ◄─┴─► NO
                 │         │
                 ▼         ▼
      ┌─────────────┐  ┌──────────────┐
      │ Mark        │  │ Retry Count  │
      │ Completed   │  │ < Max?       │
      └─────────────┘  └──────┬───────┘
                              │
                        YES ◄─┴─► NO
                        │         │
                        ▼         ▼
                 ┌──────────┐  ┌──────────┐
                 │ Requeue  │  │ Mark     │
                 │ for      │  │ Failed   │
                 │ Retry    │  │          │
                 └──────────┘  └──────────┘
                        │         │
                        └────┬────┘
                             │
                             ▼
                          END
```

---

## Priority Queue Visualization

```
HIGH PRIORITY (Doubt Videos)
┌────────────────────────────────────────┐
│ Job 1 │ Job 2 │ Job 3 │ ...           │ ← Processed First
└────────────────────────────────────────┘
         ▲
         │ FIFO within priority
         │

MEDIUM PRIORITY (Topic Shorts)
┌────────────────────────────────────────┐
│ Job 4 │ Job 5 │ Job 6 │ ...           │ ← Processed Second
└────────────────────────────────────────┘
         ▲
         │ FIFO within priority
         │

LOW PRIORITY (Daily CA)
┌────────────────────────────────────────┐
│ Job 7 │ Job 8 │ Job 9 │ ...           │ ← Processed Last
└────────────────────────────────────────┘
         ▲
         │ FIFO within priority
```

---

## Concurrency Management

```
┌─────────────────────────────────────────────────────────────┐
│              CONCURRENT RENDER SLOTS                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Total Slots: 10                                            │
│  ┌────┬────┬────┬────┬────┬────┬────┬────┬────┬────┐      │
│  │ 1  │ 2  │ 3  │ 4  │ 5  │ 6  │ 7  │ 8  │ 9  │ 10 │      │
│  └────┴────┴────┴────┴────┴────┴────┴────┴────┴────┘      │
│                                                              │
│  Manim Slots: 4 (subset of total)                          │
│  ┌────┬────┬────┬────┐                                     │
│  │ 1  │ 2  │ 3  │ 4  │                                     │
│  └────┴────┴────┴────┘                                     │
│                                                              │
│  Peak Hours (6-9 AM, 8-11 PM): 15 slots (1.5x)            │
│  ┌────┬────┬────┬────┬────┬────┬────┬────┬────┬────┬────┬────┬────┬────┬────┐
│  │ 1  │ 2  │ 3  │ 4  │ 5  │ 6  │ 7  │ 8  │ 9  │ 10 │ 11 │ 12 │ 13 │ 14 │ 15 │
│  └────┴────┴────┴────┴────┴────┴────┴────┴────┴────┴────┴────┴────┴────┴────┘
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Retry Logic Flow

```
Job Fails
   │
   ▼
┌──────────────┐
│ retry_count  │
│ < max_retries│
│ (3)?         │
└──────┬───────┘
       │
  YES ◄┴► NO
  │        │
  ▼        ▼
┌────────────┐  ┌────────────┐
│ Increment  │  │ Mark as    │
│ retry_count│  │ FAILED     │
│            │  │            │
│ Set status │  │ Notify     │
│ = 'queued' │  │ User       │
│            │  │            │
│ Wait 5 min │  └────────────┘
│ (backoff)  │
└──────┬─────┘
       │
       ▼
┌────────────┐
│ Retry Job  │
└────────────┘

Retry Attempts:
1st: Wait 5 minutes
2nd: Wait 5 minutes
3rd: Wait 5 minutes
4th: FAIL (max retries exceeded)
```

---

## Monitoring Dashboard Layout

```
┌─────────────────────────────────────────────────────────────────┐
│                  VIDEO QUEUE MONITORING                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│  │ Queued   │  │Processing│  │Completed │  │ Failed   │       │
│  │    15    │  │    3     │  │   142    │  │    2     │       │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘       │
│                                                                  │
│  Queue by Priority                                              │
│  ┌────────────────────────────────────────────────────┐        │
│  │ High Priority    ████████████░░░░░░░░░░░░  8 jobs  │        │
│  │ Medium Priority  ████████░░░░░░░░░░░░░░░░  5 jobs  │        │
│  │ Low Priority     ████░░░░░░░░░░░░░░░░░░░░  2 jobs  │        │
│  └────────────────────────────────────────────────────┘        │
│                                                                  │
│  Average Wait Time: 4.2 minutes                                 │
│                                                                  │
│  Recent Jobs                                                    │
│  ┌────────────────────────────────────────────────────────┐   │
│  │ ID      │ Type  │ Priority │ Status     │ Queue Pos   │   │
│  ├────────────────────────────────────────────────────────┤   │
│  │ abc123  │ doubt │ high     │ processing │ -           │   │
│  │ def456  │ topic │ medium   │ queued     │ 3           │   │
│  │ ghi789  │ daily │ low      │ queued     │ 4           │   │
│  └────────────────────────────────────────────────────────┘   │
│                                                                  │
│  [Auto-refresh: 5 seconds]                                      │
└─────────────────────────────────────────────────────────────────┘
```

---

## Component Interaction

```
┌──────────────┐
│   User App   │
└──────┬───────┘
       │ Submit Job
       ▼
┌──────────────┐      ┌──────────────┐
│  Supabase    │◄────►│  PostgreSQL  │
│  REST API    │      │  Database    │
└──────┬───────┘      └──────────────┘
       │                      ▲
       │                      │
       ▼                      │
┌──────────────┐             │
│ Queue Worker │─────────────┘
│ (Edge Func)  │   Read/Write Jobs
└──────┬───────┘
       │ Call Pipes
       ▼
┌──────────────┐
│ Video Pipes  │
│ - Doubt      │
│ - Topic      │
│ - Daily CA   │
└──────┬───────┘
       │ Generate
       ▼
┌──────────────┐
│ Video Output │
└──────────────┘
```

---

## File Structure

```
packages/supabase/supabase/
├── migrations/
│   └── 009_video_jobs.sql ..................... Database schema
├── functions/
│   ├── shared/
│   │   └── queue-utils.ts ..................... Utility functions
│   ├── workers/
│   │   └── video-queue-worker/
│   │       ├── index.ts ....................... Main worker
│   │       ├── index.test.ts .................. Unit tests
│   │       ├── README.md ...................... Documentation
│   │       └── deno.json ...................... Config
│   └── actions/
│       └── queue_management_action.ts ......... API actions

apps/admin/src/app/queue/monitoring/
└── page.tsx ................................... Dashboard UI
```

---

## Deployment Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    VPS: 89.117.60.144                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────────────────────────────────────────────────┐        │
│  │ PostgreSQL (Port 5432)                              │        │
│  │ - jobs table                                        │        │
│  │ - job_queue_config table                            │        │
│  └────────────────────────────────────────────────────┘        │
│                         ▲                                        │
│                         │                                        │
│  ┌────────────────────────────────────────────────────┐        │
│  │ Supabase (Port 54321)                               │        │
│  │ - REST API                                          │        │
│  │ - Edge Functions                                    │        │
│  │   └── video-queue-worker (Cron: */1 * * * *)       │        │
│  └────────────────────────────────────────────────────┘        │
│                         ▲                                        │
│                         │                                        │
│  ┌────────────────────────────────────────────────────┐        │
│  │ Admin Dashboard (Port 8000)                         │        │
│  │ - Queue monitoring UI                               │        │
│  │ - Real-time statistics                              │        │
│  └────────────────────────────────────────────────────┘        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

This architecture provides a robust, scalable, and maintainable video generation queue management system with comprehensive monitoring and error handling capabilities.
