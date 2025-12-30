# SM Agent Output - UPSC PrepX-AI Build Sprint

## Project Context
- **Project**: UPSC PrepX-AI - AI-Powered UPSC Exam Preparation Platform
- **Specification Document**: `UPSC COMPLETE ENTERPRISE BUILD SPECIFICATION v4.md`
- **Target**: 35 Features across 5 Phases
- **Methodology**: BMAD (Business, Management, Architecture, Development)

---

## Sprint 1: Foundation Core

### Epic F1: Authentication & User Management
**Priority**: P0 (Must Have)
**Dependencies**: None

#### Stories:
1. [F1.1] User Registration & Login
   - Email/Phone authentication via Supabase Auth
   - Profile creation with UPSC preparation details
   - Onboarding flow (target exam, optional subject, preparation stage)

2. [F1.2] Subscription Management
   - Trial logic (1-day full access)
   - Subscription tiers (Monthly ₹599, Quarterly ₹1499, Half-Yearly ₹2699, Annual ₹4999)
   - RevenueCat integration
   - Entitlement checks

3. [F1.3] User Profile & Preferences
   - Study preferences (hours/day, weak areas)
   - Voice preferences for video content
   - Notification settings

### Epic F2: Knowledge Base System
**Priority**: P0 (Must Have)
**Dependencies**: F1

#### Stories:
1. [F2.1] PDF Upload & Processing
   - Admin PDF upload interface
   - Text extraction with OCR
   - Semantic chunking (1000 tokens, 200 overlap)

2. [F2.2] Syllabus Taxonomy Seeding
   - GS1, GS2, GS3, GS4, CSAT, Essay syllabus nodes
   - Subject categorization
   - Topic hierarchy

3. [F2.3] Vector Embeddings
   - Generate embeddings for chunks
   - pgvector index setup
   - Similarity search function

4. [F2.4] RAG Query Engine
   - Query knowledge base
   - Filter by subject/paper
   - Return chunks with citations

### Epic F3: Core Infrastructure
**Priority**: P0 (Must Have)
**Dependencies**: F1, F2

#### Stories:
1. [F3.1] Database Schema
   - All tables from Section 2.3 of specification
   - RLS policies
   - Helper functions

2. [F3.2] Edge Functions Framework
   - Pipe/Filter/Action pattern
   - CORS headers
   - Auth middleware

3. [F3.3] Storage Configuration
   - Videos bucket
   - Thumbnails bucket
   - Notes/PDFs bucket
   - Storage policies

4. [F3.4] Job Queue System
   - Jobs table
   - Job processing logic
   - Retry mechanism

---

## Sprint 2: Daily Engagement

### Epic F4: Doubt to Video Converter
**Priority**: P1 (Should Have)
**Dependencies**: F1, F2, F3

#### Stories:
1. [F4.1] Input Processing
   - Text input
   - Image upload with OCR
   - Content validation

2. [F4.2] Knowledge Retrieval
   - Query RAG engine
   - Web supplement search
   - Context assembly

3. [F4.3] Script Generation
   - LLM-based explanation
   - Visual markers insertion
   - Style options (concise/detailed)

4. [F4.4] Video Assembly
   - Manim diagram specs
   - Remotion composition
   - TTS narration
   - Final render

5. [F4.5] Frontend Interface
   - Doubt input card
   - Progress indicator
   - Video player
   - Supporting materials

### Epic F5: Quiz System
**Priority**: P1 (Should Have)
**Dependencies**: F2

#### Stories:
1. [F5.1] MCQ Generator
   - Topic-based question generation
   - Answer options
   - Explanation generation

2. [F5.2] Quiz Interface
   - Question display
   - Timer
   - Submit & score

3. [F5.3] Result Analysis
   - Score calculation
   - Topic-wise performance
   - Improvement suggestions

### Epic F6: Smart Bookmarks
**Priority**: P1 (Should Have)
**Dependencies**: F2

#### Stories:
1. [F6.1] Bookmark Creation
   - Save from notes/videos/questions
   - Tags and notes
   - Link to source

2. [F6.2] Spaced Repetition
   - SM-2 algorithm
   - Revision schedule
   - Due date tracking

3. [F6.3] Revision Interface
   - Flashcard view
   - Self-assessment
   - Progress tracking

### Epic F7: Video Library
**Priority**: P1 (Should Have)
**Dependencies**: F3

#### Stories:
1. [F7.1] Video Player
   - Custom player with HLS
   - Chapters/navigation
   - Transcript display

2. [F7.2] Progress Tracking
   - Watch history
   - Resume playback
   - Completion percentage

3. [F7.3] Topic Shorts Generator
   - 60-second topic explainers
   - Multiple aspect ratios
   - Social sharing

---

## Sprint 3: Practice & Assessment

### Epic F8: Answer Writing Practice
**Priority**: P1 (Should Have)
**Dependencies**: F2, F5

#### Stories:
1. [F8.1] Question Display
   - Daily mains question
   - Timer
   - Rich text editor

2. [F8.2] AI Evaluation
   - Rubric-based scoring (Content 40%, Structure 30%, Language 20%, Examples 10%)
   - Model answer comparison
   - Improvement tips

3. [F8.3] Video Feedback
   - Remotion-generated feedback video
   - Weakness explanation
   - Suggested revisions

### Epic F9: Essay Trainer
**Priority**: P2 (Could Have)
**Dependencies**: F2, F8

#### Stories:
1. [F9.1] Essay Submission
   - Topic selection
   - Word count tracking
   - Structure guidance

2. [F9.2] Essay Evaluation
   - Scoring dimensions
   - Feedback generation
   - Improvement roadmap

### Epic F10: PYQ Video Engine
**Priority**: P2 (Could Have)
**Dependencies**: F2, F4

#### Stories:
1. [F10.1] PYQ Upload
   - Image/text upload
   - Year/subject tagging

2. [F10.2] Video Explanation
   - Question analysis
   - Model answer video
   - Key concepts

### Epic F11: Confidence Meter
**Priority**: P2 (Could Have)
**Dependencies**: F2, F5, F6

#### Stories:
1. [F11.1] Confidence Calculation
   - Quiz performance
   - Study time
   - Revision count

2. [F11.2] Calibration
   - Self-assessment vs actual
   - Bias detection
   - Adjustment suggestions

---

## Sprint 4: Scale & Automation

### Epic F12: Daily CA Video Newspaper
**Priority**: P1 (Should Have)
**Dependencies**: F2, F3

#### Stories:
1. [F12.1] News Scraping
   - DuckDuckGo UPSC search
   - Source whitelisting
   - Article extraction

2. [F12.2] Relevance Scoring
   - Syllabus mapping
   - Topic categorization
   - Priority ranking

3. [F12.3] Daily Script Generation
   - Topic grouping
   - Narration script
   - Visual cues

4. [F12.4] Video Assembly
   - 5-8 minute video
   - Multiple formats
   - Auto-publish

5. [F12.5] PDF Summary
   - Key points extraction
   - MCQ generation
   - Downloadable PDF

### Epic F13: Documentary Lectures
**Priority**: P2 (Could Have)
**Dependencies**: F2, F4

#### Stories:
1. [F13.1] Topic Research
   - Knowledge retrieval
   - Web enhancement
   - Chapter structure

2. [F13.2] Long-form Script
   - 3-hour content
   - Chapter segmentation
   - Visual specifications

3. [F13.3] Parallel Rendering
   - Chapter-wise renders
   - Assembly pipeline
   - Quality check

### Epic F14: Auto-Publishing
**Priority**: P3 (Nice to Have)
**Dependencies**: F12, F13

#### Stories:
1. [F14.1] Platform Integration
   - YouTube API
   - Instagram API
   - Twitter API

2. [F14.2] Content Adaptation
   - Format conversion
   - Thumbnail generation
   - Description optimization

3. [F14.3] Scheduling
   - Optimal timing
   - A/B testing
   - Analytics

---

## Sprint 5: Flagship Features

### Epic F15: Interview Studio
**Priority**: P2 (Could Have)
**Dependencies**: F1, F2

#### Stories:
1. [F15.1] Session Management
   - Session types (general, DAF-based, current affairs)
   - Round management
   - Timing tracking

2. [F15.2] Question Generation
   - DAF-based questions
   - Follow-up generation
   - Difficulty scaling

3. [F15.3] Real-time Evaluation
   - Rubric scoring
   - Feedback generation
   - Improvement roadmap

4. [F15.4] Recording & Review
   - Session recording
   - Playback interface
   - Debrief video

### Epic F16: Ethics Case Studies
**Priority**: P2 (Could Have)
**Dependencies**: F2

#### Stories:
1. [F16.1] Case Generation
   - Dilemma scenarios
   - Stakeholder analysis
   - Evaluation criteria

2. [F16.2] Interactive Interface
   - Scenario display
   - User analysis input
   - Evaluation

### Epic F17: Gamification
**Priority**: P2 (Could Have)
**Dependencies**: F1

#### Stories:
1. [F17.1] XP System
   - XP earning (study time, quiz scores, content creation)
   - Level progression
   - XP display

2. [F17.2] Streak Tracking
   - Daily activity
   - Streak bonuses
   - Recovery options

3. [F17.3] Badges & Achievements
   - Badge definitions
   - Earning criteria
   - Badge display

4. [F17.4] Leaderboards
   - Weekly/monthly rankings
   - Category leaderboards
   - Social comparison

### Epic F18: Certificates
**Priority**: P3 (Nice to Have)
**Dependencies**: F17

#### Stories:
1. [F18.1] Certificate Generation
   - Template system
   - Dynamic content
   - Unique编号

2. [F18.2] Verification
   - Verification codes
   - Public verify page
   - Share functionality

### Epic F19: Community
**Priority**: P3 (Nice to Have)
**Dependencies**: F1

#### Stories:
1. [F19.1] Discussion Forums
   - Forum categories
   - Thread management
   - Moderation

2. [F19.2] Q&A System
   - Question posting
   - Answers and votes
   - Accepted answers

---

## Dependency Graph

```
Sprint 1 (Foundation)
├── F1: Auth & Subscriptions ──┬──► F2: Knowledge Base ──┬──► F3: Infrastructure
│                              │                         │
│                              │                         └──► Sprint 2
│                              │
│                              └──► Sprint 2 & Beyond

Sprint 2 (Daily Engagement)
├── F4: Doubt►Video ───────────────► F10: PYQ Engine
│
├── F5: Quiz System ──────────────► F8: Answer Writing
│    │                               │
│    └──► F6: Bookmarks ───────────► F11: Confidence Meter
│
└── F7: Video Library

Sprint 3 (Practice)
├── F8: Answer Writing ──► F9: Essay Trainer
│
├── F10: PYQ Engine ──────► F4: Doubt►Video
│
└── F11: Confidence Meter

Sprint 4 (Automation)
├── F12: Daily CA ────────► F14: Auto-Publishing
│
└── F13: Documentary

Sprint 5 (Flagship)
├── F15: Interview Studio
├── F16: Ethics Cases
├── F17: Gamification ────► F18: Certificates
│
└── F19: Community
```

---

## Implementation Order (Recommended)

1. **Foundation First**: F1, F2, F3 (Sprint 1)
2. **Core User Value**: F4, F5 (Sprint 2)
3. **Practice & Assessment**: F8, F11 (Sprint 3)
4. **Scalability**: F12 (Sprint 4)
5. **Engagement**: F15, F17 (Sprint 5)

---

## Technical Stack Summary

### Backend
- **Runtime**: Deno (Edge Functions)
- **Database**: PostgreSQL 15+ with pgvector
- **Auth**: Supabase Auth (JWT)
- **Storage**: Supabase Storage

### Frontend
- **Framework**: Next.js 14+ (App Router)
- **Styling**: Tailwind CSS + shadcn/ui
- **State**: React Query + Zustand
- **3D**: React Three Fiber

### Video
- **Animation**: Manim
- **Composition**: Remotion
- **TTS/STT**: A4F API

### External Services
- **RAG Engine**: 89.117.60.144:8101
- **Search**: 89.117.60.144:8102
- **Notes Gen**: 89.117.60.144:8104
- **Renderer**: 89.117.60.144:5555

---

## Dev Agent Tasks

### Task 1: Foundation Setup
```
*task create-fullstack
Features: F1, F2, F3
Template: fullstack
Output: pipes/, filters/, actions/, migrations/
```

### Task 2: Daily Engagement
```
*task create-fullstack
Features: F4, F5, F6, F7
Template: fullstack
Output: pipes/, actions/, pages/
```

### Task 3: Practice & Assessment
```
*task create-fullstack
Features: F8, F9, F10, F11
Template: fullstack
Output: pipes/, actions/, pages/
```

### Task 4: Automation Pipeline
```
*task create-fullstack
Features: F12, F13, F14
Template: fullstack
Output: cron-jobs/, pipes/, actions/
```

### Task 5: Flagship Features
```
*task create-fullstack
Features: F15, F16, F17, F18, F19
Template: fullstack
Output: pipes/, actions/, pages/
```

---

## Key Implementation Notes

### Pipe/Filter/Action Pattern
All features MUST follow:
```
PIPE → FILTERS → ACTIONS → RESPONSE
```

### Entitlement Checks
Every pipe must:
1. Verify auth
2. Check subscription/trial status
3. Block if expired

### Caching Strategy
- Redis for syllabus trees (1 hour TTL)
- Knowledge chunks indexed with pgvector
- Rendered videos cached

### Mobile First
All UIs must be responsive from the start.

---

## Ready for Dev Agent

The Dev Agent should now:
1. Review this document
2. Read `UPSC COMPLETE ENTERPRISE BUILD SPECIFICATION v4.md`
3. Check existing code in `packages/supabase/` and `apps/web/`
4. Begin implementation with Task 1 (Foundation)

---

*Generated by SM Agent - Sprint Planning Complete*
*BMAD Methodology v4.44.3*
