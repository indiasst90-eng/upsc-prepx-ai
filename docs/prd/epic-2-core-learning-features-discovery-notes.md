# Epic 2: Core Learning Features - Discovery & Notes

**Epic Goal:**
Deliver the core learning discovery experience through interactive 3D syllabus navigation, multi-level notes generation, and RAG-powered search, enabling students to explore the entire UPSC syllabus, generate comprehensive study materials, and search accurately across curated knowledge base with source citations. By the end of this epic, users shall have complete syllabus visibility with progress tracking, AI-generated notes at 3 depth levels (100/250/500 words), and Google-like search with confidence scoring—all leveraging the RAG infrastructure from Epic 1.

## Story 2.1: Interactive 3D Syllabus Navigator - UI Implementation

**As a** UPSC aspirant,
**I want** to explore the complete UPSC syllabus (GS1-4, CSAT, Essay) in a visual 3D tree with zoomable nodes and progress rings,
**so that** I can understand the syllabus structure, navigate to topics, and track my learning progress visually.

### Acceptance Criteria

1. 3D visualization implemented using React Three Fiber with syllabus tree hierarchy (Papers → Sections → Topics → Sub-topics)
2. Nodes display: topic name, icon, progress ring (0-100%), confidence color (red/yellow/green)
3. Click node opens topic detail modal: description, related notes/videos/PYQs, "Start Learning" button
4. Sidebar filters: checkboxes for papers (GS1, GS2, GS3, GS4, CSAT, Essay), subjects (Polity, History, Geography, etc.)
5. Search bar filters visible nodes: type "Polity" highlights matching nodes
6. Zoom controls: mouse scroll, pinch-to-zoom on mobile, reset button
7. Bookmark functionality: star icon on each node, "My Bookmarks" filter shows starred nodes
8. Performance: 60fps rendering with 1000+ nodes, lazy load sub-nodes on expand
9. 2D fallback view for older devices (toggle in settings)
10. Progress data fetched from `user_progress` table, updates real-time when user completes content

---

## Story 2.2: Syllabus Navigator - Progress Tracking & Analytics

**As a** UPSC aspirant,
**I want** the syllabus navigator to display my study time, quiz scores, and completion status per topic,
**so that** I can identify weak areas and prioritize my study plan.

### Acceptance Criteria

1. Node tooltip on hover shows: time spent (hours:minutes), last studied date, quiz average score
2. Heatmap color coding: green (80%+ completion), yellow (40-79%), red (<40%), gray (not started)
3. Progress ring animates when updated (smooth transition, confetti on 100% completion)
4. "My Progress" sidebar panel: total syllabus completion %, subjects breakdown bar chart, weakest 5 topics list
5. Filter by progress: "Not Started", "In Progress", "Completed", "Needs Revision"
6. Export progress report as CSV: columns (topic, completion%, time_spent, confidence_score)
7. Database queries optimized: single query fetches all progress for current user's syllabus view (<300ms)
8. Real-time updates: WebSocket or polling refreshes progress every 30s while dashboard open
9. Goal-setting feature: user sets target completion date, dashboard shows "on track" or "behind schedule"
10. Mobile-optimized: simplified heatmap view, swipe gestures to navigate tree

---

## Story 2.3: Notes Generator - Multi-Level Text Synthesis

**As a** UPSC aspirant,
**I want** to generate notes at 3 levels (summary, detailed, comprehensive) for any syllabus topic,
**so that** I can study according to my depth requirement and time availability.

### Acceptance Criteria

1. "Generate Notes" button on every syllabus topic detail modal
2. User selects level: Summary (100 words), Detailed (250 words), Comprehensive (500 words)
3. Edge Function: `generate_notes_pipe.ts` calls Notes Generator VPS service (`http://89.117.60.144:8104/generate_notes`)
4. RAG retrieval: fetch top 5 knowledge chunks matching topic from `knowledge_chunks` table
5. LLM synthesis: GPT-4 Turbo generates notes grounded in RAG chunks with citations
6. Notes include: key points (bullets), definitions, examples, UPSC relevance, related topics (cross-links)
7. Source citations appended: "Sources: [Book Title], Chapter X; [NCERT Class Y], Unit Z"
8. Notes saved to `comprehensive_notes` table with metadata: topic_id, level, content, created_at
9. Generation time <10 seconds for summary, <20 seconds for comprehensive (P95)
10. Error handling: if confidence <70%, display warning "Limited source material available for this topic"

---

## Story 2.4: Notes Generator - Manim Diagram Integration

**As a** UPSC aspirant,
**I want** AI-generated notes to include visual diagrams and flowcharts,
**so that** I can understand complex concepts through visual explanations alongside text.

### Acceptance Criteria

1. Notes Generator analyzes content and identifies visualizable elements (timelines, processes, hierarchies, comparisons)
2. Manim scene specifications generated: JSON schema with scene type (timeline, flowchart, hierarchy, cycle), elements, colors
3. VPS Manim Renderer called: `POST http://89.117.60.144:5555/render` with scene JSON
4. Diagram rendered as PNG (for notes) and MP4 (for video shorts)
5. Diagrams embedded in notes at relevant positions (after key points)
6. Notes PDF export includes diagrams with proper layout
7. Diagram caching: identical scene specs reuse cached renders (check `manim_scene_cache` table)
8. Fallback: if Manim render fails, notes proceed without diagram, log warning
9. User can click diagram in notes to open fullscreen viewer with zoom/pan
10. Mobile-optimized: diagrams scale responsively, SVG format preferred for crisp rendering

---

## Story 2.5: Notes Generator - 60-Second Video Summary

**As a** UPSC aspirant,
**I want** each note to have an optional 60-second animated video summary,
**so that** I can quickly revise topics through video before reading full notes.

### Acceptance Criteria

1. "Generate Video Summary" checkbox on notes generation form (Pro users only)
2. Video script generated from comprehensive notes: extract 3-4 key points, 150-200 words
3. Manim scenes generated for 1-2 critical visuals (reuse from notes diagrams if available)
4. TTS audio generated: ElevenLabs API with selected voice (user preference from profile)
5. Revideo composition: `NotesSummaryTemplate` assembles script, TTS, Manim clips, transitions
6. Video rendered via VPS Video Orchestrator: `http://89.117.60.144:8103/render`
7. Video uploaded to Supabase Storage: `videos/notes-summaries/{note_id}.mp4`
8. Render time <60 seconds (P95), job queued with priority "high"
9. Video player embedded in notes view: autoplay on note open, controls (pause, speed, seek)
10. Video linked to note record: `comprehensive_notes.summary_video_url` column updated

---

## Story 2.6: Notes Library - Organization & Export

**As a** UPSC aspirant,
**I want** a centralized notes library where I can browse, search, and export all my generated notes,
**so that** I can organize my study materials and access them offline.

### Acceptance Criteria

1. Notes Library page: `/notes` route with grid view of note cards
2. Card displays: topic title, level badge, thumbnail (first diagram or placeholder), created date, "View" button
3. Filters: subject dropdown, paper dropdown, level checkboxes, date range picker
4. Search bar: full-text search across note content using PostgreSQL `tsvector`
5. Sorting: by date (newest/oldest), topic (alphabetical), level (summary first)
6. Pagination: 20 notes per page, infinite scroll on mobile
7. Bulk actions: select multiple notes, bulk export as ZIP (all PDFs), bulk delete
8. Individual note export: PDF download button generates PDF with proper formatting (headings, bullets, diagrams)
9. Markdown export: download as `.md` file with cross-links preserved as markdown links
10. Offline access (PWA): downloaded notes cached for offline viewing, sync indicator shows cached status

---

## Story 2.7: RAG Search - Advanced Features & Filters

**As a** UPSC aspirant,
**I want** advanced search capabilities with filters by subject, paper, book, and date range,
**so that** I can find precise information from specific sources quickly.

### Acceptance Criteria

1. Advanced filters panel (collapsible sidebar on search page)
2. Subject filter: multi-select checkboxes (Polity, History, Geography, Economy, Science, Ethics, Essay, CSAT)
3. Paper filter: multi-select (GS1, GS2, GS3, GS4, CSAT, Essay)
4. Source type filter: NCERT, Standard Books, Government Reports, Daily Updates
5. Book filter: dropdown populated from `pdf_uploads.book_title` (distinct values)
6. Date range filter: content updated between start and end dates
7. Search within results: second search bar filters already fetched results client-side
8. Save search: "Save this search" button stores query + filters to `saved_searches` table
9. Saved searches accessible from dropdown: "My Saved Searches" with quick-apply buttons
10. Filter state persisted in URL query params: shareable search URLs, back button works correctly

---

## Story 2.8: RAG Search - Video Explanation Generation

**As a** Pro UPSC aspirant,
**I want** to generate on-demand video explanations for complex search results,
**so that** I can understand difficult topics through visual narration instead of just reading.

### Acceptance Criteria

1. "Explain with Video" button on each search result (Pro badge displayed, Free users see upgrade prompt)
2. Entitlement check: verify user subscription status, block if Free tier
3. Click button opens modal: "Generating video explanation... This will take ~60 seconds"
4. Script generated from search result content + related chunks (expand context to 1000 words)
5. Manim scenes generated for key concepts (max 2-3 visuals per video)
6. TTS narration with selected voice, video assembled via Revideo
7. Job queued to VPS Video Orchestrator with priority "medium", job_id returned to client
8. Client polls job status: `GET /api/jobs/{job_id}` every 5 seconds until status = 'completed'
9. Video player loads when ready, thumbnail preview while processing
10. Video saved to user's library: linked in `user_videos` table, accessible from dashboard "My Videos" section

---

## Story 2.9: Notes Export - PDF Formatting & Branding

**As a** UPSC aspirant,
**I want** exported note PDFs to be professionally formatted with branding, page numbers, and table of contents,
**so that** I can print and bind them as physical study material.

### Acceptance Criteria

1. PDF generation using `@react-pdf/renderer` library (server-side in Edge Function)
2. Cover page: UPSC AI Mentor logo, note title, topic name, generation date, user name
3. Table of contents: auto-generated from note headings (H1, H2), clickable links to sections
4. Page layout: A4 size, 1-inch margins, header (topic name), footer (page number, "upsc-ai-mentor.com")
5. Typography: Inter font (body), Satoshi font (headings), 12pt body text, 16pt headings
6. Diagrams: high-resolution PNG embedded at full width, captions below
7. Citations section: all sources listed at end with hyperlinks
8. Watermark (optional): "Generated by UPSC AI Mentor" in footer (Pro users can disable)
9. Export options: single note PDF, bulk export (ZIP of multiple PDFs), combined PDF (all notes in one file)
10. Generation time <5 seconds per note, download starts automatically, progress bar shown for bulk exports

---

## Story 2.10: Daily Notes vs. Permanent Notes - Categorization

**As a** UPSC aspirant,
**I want** my notes categorized into permanent study notes and daily current affairs notes,
**so that** I can separate static syllabus content from dynamic daily updates.

### Acceptance Criteria

1. Notes categorized in database: `comprehensive_notes.note_type` enum ('syllabus', 'daily_update', 'user_custom')
2. Notes Library tabs: "Syllabus Notes", "Daily Updates", "My Custom Notes"
3. Daily update notes auto-generated from daily current affairs: linked to `daily_updates` table entries
4. Daily notes display date badge: "Updated: 23 Dec 2025", auto-archive after 90 days
5. Syllabus notes linked to syllabus_nodes: display syllabus path breadcrumb (GS2 → Polity → Indian Constitution)
6. Custom notes: user can create blank notes manually, free-form editor (rich text)
7. Filter by note type: checkboxes apply to visible notes
8. Search respects note type: option to "Search only syllabus notes" or "Search only daily updates"
9. Archived daily notes accessible via "Archives" section, not shown in main library by default
10. Bulk operations respect categories: can bulk-export only daily updates or only syllabus notes

---
