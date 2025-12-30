# UPSC PrepX-AI Phase 2 Implementation Plan

**Date:** December 24, 2025
**Phase:** 2 - Advanced Features
**Objective:** Complete remaining features from original 34-feature list

---

## Phase 2 Features (Priority Order)

### Priority 1: Core Completion Features

| Feature | Original # | Complexity | Effort |
|---------|------------|------------|--------|
| Book-to-Notes Converter | #25 | Medium | 2 days |
| AI Teaching Assistant | #20 | Medium | 3 days |
| Smart Bookmark Engine | #32 | Low-Medium | 2 days |
| Concept Confidence Meter | #33 | Low-Medium | 2 days |
| Mindmap Builder | #21 | Medium | 3 days |

### Priority 2: Enhanced Features

| Feature | Original # | Complexity | Effort |
|---------|------------|------------|--------|
| Daily Planner | #24 | Low-Medium | 2 days |
| Smart Revision Booster | #23 | Medium | 3 days |
| Topic Difficulty Predictor | #31 | Medium-High | 3 days |

### Priority 3: Advanced Features (Later)

| Feature | Original # | Complexity | Effort |
|---------|------------|------------|--------|
| Case Law Explainer | #11 | Medium-High | 4 days |
| Manim Problem Solver | #9 | High | 5 days |
| 360° Geography Videos | #5 | Very High | 7 days |
| 3D Map Atlas | #14 | Very High | 7 days |

---

## Phase 2 Technical Architecture

### New Components to Create

```
apps/web/src/
├── components/
│   ├── TeachingAssistant.tsx      # AI chat interface
│   ├── BookmarkManager.tsx        # Save/bookmark system
│   ├── ConfidenceMeter.tsx        # Visual progress tracking
│   ├── MindmapViewer.tsx          # Mindmap display
│   ├── DailyPlanner.tsx           # Study schedule
│   └── RevisionScheduler.tsx      # Spaced repetition

├── contexts/
│   └── ChatContext.tsx            # Teaching assistant chat state

├── app/(dashboard)/
│   ├── bookmarks/page.tsx         # Bookmarks page NEW
│   ├── planner/page.tsx           # Daily planner NEW
│   └── mindmap/page.tsx           # Mindmap builder NEW

packages/supabase/supabase/functions/
├── pipes/
│   ├── book_to_notes_pipe/        # Enhanced PDF to notes
│   ├── chat_assistant_pipe/       # AI chat responses
│   ├── mindmap_pipe/              # Generate mindmaps
│   ├── bookmark_pipe/             # Bookmark management
│   ├── revision_pipe/             # Spaced repetition
│   └── confidence_pipe/           # Progress analysis
```

---

## Feature Specifications

### 1. Book-to-Notes Converter (#25)

**What it does:**
- Ingest PDF chapters (NCERT, standard books)
- Output multi-level notes (prelims/mains versions)
- Generate key facts, MCQs, summary video

**Sub-features:**
- Auto-map chapters to syllabus nodes
- Citations and references
- Multiple output formats (PDF, markdown)

**Implementation:**
```
Input: PDF file
Processing:
  1. Extract text (pdf-parse)
  2. Generate embeddings
  3. RAG query for context
  4. Generate notes (A4F)
  5. Generate MCQs
  6. Generate summary
Output: Notes PDF, MCQs, citations
```

### 2. AI Teaching Assistant (#20)

**What it does:**
- Conversational tutor
- Voice settings, tone control
- Daily check-ins, progress nudges

**Sub-features:**
- Chat interface
- Voice output (TTS)
- Context-aware responses
- Micro-assignments

**Implementation:**
```
Input: User message
Processing:
  1. Get user context (progress, weak topics)
  2. Generate response (A4F)
  3. Generate micro-assignment if relevant
  4. TTS audio output
Output: Text response + audio + assignment
```

### 3. Smart Bookmark Engine (#32)

**What it does:**
- Save any concept
- Auto-linked notes, PYQs, visual explanations
- Scheduled revisions

**Sub-features:**
- One-click bookmark
- Auto-tagging
- Cross-links to syllabus
- Revision reminders

**Implementation:**
```
Input: User action (bookmark concept)
Processing:
  1. Extract concept from current context
  2. Generate related links (RAG)
  3. Schedule revision (spaced repetition)
  4. Store in database
Output: Bookmark with links + revision schedule
```

### 4. Concept Confidence Meter (#33)

**What it does:**
- Visual confidence meter per topic
- Red/yellow/green indicators
- Suggested micro-actions

**Sub-features:**
- Quiz results integration
- Time-spent analysis
- Spaced repetition history
- Alert system

**Implementation:**
```
Input: Performance data
Processing:
  1. Calculate confidence score
  2. Compare with thresholds
  3. Generate action items
Output: Dashboard with meters + action plan
```

### 5. Mindmap Builder (#21)

**What it does:**
- Auto-build mindmaps from text
- Interactive nodes
- Export PNG/PDF

**Sub-features:**
- Text input
- Auto-layout
- Link to videos/questions
- Export options

**Implementation:**
```
Input: Text or topic
Processing:
  1. Extract key concepts (NLP)
  2. Build hierarchy
  3. Generate visual layout
  4. Add links to resources
Output: Interactive mindmap + export
```

---

## Database Extensions (Phase 2)

Add to migration `011_phase2_features.sql`:

```sql
-- Book conversions
CREATE TABLE IF NOT EXISTS book_conversions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  book_title TEXT,
  file_url TEXT,
  status TEXT DEFAULT 'pending',
  notes_output JSONB,
  mcqs_output JSONB,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Chat conversations
CREATE TABLE IF NOT EXISTS chat_conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  title TEXT,
  messages JSONB,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Bookmarks
CREATE TABLE IF NOT EXISTS user_bookmarks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  concept TEXT,
  related_notes JSONB,
  related_pyqs JSONB,
  revision_date TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Mindmaps
CREATE TABLE IF NOT EXISTS user_mindmaps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  topic TEXT,
  structure JSONB,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Revision schedules
CREATE TABLE IF NOT EXISTS revision_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  concept_id UUID,
  scheduled_date DATE,
  completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);
```

---

## API Endpoints (Phase 2)

```
POST /functions/v1/book_to_notes
  - Input: { file_url, level: 'basic|advanced' }
  - Output: { notes_id, pdf_url, mcqs }

POST /functions/v1/chat_assistant
  - Input: { message, conversation_id }
  - Output: { response, audio_url, assignment }

POST /functions/v1/generate_mindmap
  - Input: { text, topic }
  - Output: { mindmap_id, structure, image_url }

POST /functions/v1/bookmark
  - Input: { concept, context }
  - Output: { bookmark_id, related_resources }

POST /functions/v1/schedule_revision
  - Input: { concept, priority }
  - Output: { schedule_id, dates }

GET /functions/v1/confidence_scores
  - Output: { topics: [{ topic, score, actions }] }
```

---

## Success Criteria

### Phase 2 Completion Checklist

- [ ] Book-to-Notes Converter working
- [ ] AI Teaching Assistant chat interface
- [ ] Smart Bookmark Engine with revisions
- [ ] Concept Confidence Meter dashboard
- [ ] Mindmap Builder with export
- [ ] Daily Planner (optional)
- [ ] Smart Revision Scheduler (optional)

### Quality Gates

- [ ] All features use simplified language (10th class English)
- [ ] All features support Hindi toggle
- [ ] All features have error handling
- [ ] All features use RLS policies
- [ ] All features documented

---

## Timeline Estimate

| Week | Focus | Features |
|------|-------|----------|
| Week 1 | Core Features | Book-to-Notes, Teaching Assistant |
| Week 2 | User Features | Bookmarks, Confidence Meter |
| Week 3 | Visualization | Mindmap Builder |
| Week 4 | Testing & Polish | Bug fixes, integration |

---

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| A4F API rate limits | Implement caching, queue system |
| PDF parsing errors | Multiple fallback methods |
| Chat context length | Summarize old messages |
| Mindmap layout quality | Use established libraries (D3.js) |

---

**Phase 2 Plan Created:** December 24, 2025
**Total Features:** 5-8 (priority-based)
**Estimated Duration:** 2-4 weeks
