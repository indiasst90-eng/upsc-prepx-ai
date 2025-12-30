# Epic 3: Video Generation Pipeline - Daily Current Affairs

**Epic Goal:**
Build the complete automated daily current affairs video newspaper pipeline that scrapes whitelisted UPSC-relevant news sources by 5 AM IST, generates script with topic segmentation (Economy, Polity, IR, Environment), renders 5-8 minute video with Manim diagrams and Revideo assembly, publishes video by 6 AM IST, and provides downloadable PDF summary with 5 MCQs. This epic establishes the core video generation infrastructure (Manim + Revideo pipeline) reused across all video features, achieving ≥95% on-time delivery rate with <5% failure requiring manual fallback.

## Story 3.1: Daily News Scraper - Source Integration

**As a** system administrator,
**I want** automated daily scraping of whitelisted UPSC news sources with deduplication and relevance filtering,
**so that** current affairs videos contain only high-quality, UPSC-relevant content from trusted sources.

### Acceptance Criteria

1. Edge Function scheduled via pg_cron: `daily_news_scraper` runs at 5:00 AM IST daily
2. Whitelisted sources scraped: visionias.in, drishtiias.com, thehindu.com, pib.gov.in, forumias.com, insightsonindia.com, iasbaba.com, iasscore.in (RSS feeds + API where available)
3. DuckDuckGo Search Service called for targeted queries: `POST http://89.117.60.144:8102/search` with domain filters
4. Article extraction: title, summary, body text, published date, source URL, category tags
5. Relevance filtering: LLM classifies each article (UPSC-relevant: yes/no, subjects: [Polity, Economy, etc.], papers: [GS1-4])
6. Deduplication: cosine similarity on embeddings, merge articles >90% similar
7. Articles saved to `daily_updates` table: status = 'pending_video', article_text, metadata
8. Rate limiting: max 5 requests/second per source, retry with exponential backoff on failure
9. Monitoring: log article counts, sources success/failure, total runtime (<30 minutes)
10. Fallback: if scraper fails, alert admin, use previous day's backup content

---

## Story 3.2: Daily CA Script Generator - Segmentation & Summarization

**As a** system,
**I want** to automatically generate a structured video script from scraped articles with topic segmentation and UPSC-specific insights,
**so that** daily current affairs videos are concise, exam-focused, and easy to follow.

### Acceptance Criteria

1. Edge Function: `generate_ca_script_pipe.ts` triggered after scraper completes (database trigger or cron at 5:15 AM)
2. Articles fetched from `daily_updates` where date = today and status = 'pending_video'
3. Topic segmentation: LLM groups articles into 4-6 segments (Economy, Polity, International Relations, Environment, Science & Tech, Social Issues)
4. Each segment: 60-120 seconds, max 3 articles per segment
5. Script structure: intro (15s) → segment 1 → segment 2 → ... → conclusion with MCQ preview (15s)
6. RAG integration: retrieve related knowledge chunks for context (e.g., article on Budget 2025 → fetch "Fiscal Policy" notes)
7. UPSC relevance markers: script highlights "Prelims relevance", "Mains angle", "Essay connection"
8. Script saved to `video_renders` table: content_type = 'daily_ca', script_json, status = 'pending_manim'
9. Total word count: 800-1200 words (5-8 minutes at 150 words/minute)
10. Quality check: if <3 UPSC-relevant articles found, flag for manual review

---

## Story 3.3: Manim Scene Generation - Visual Assets

**As a** video producer,
**I want** Manim to automatically generate animated diagrams, maps, and timelines for current affairs topics,
**so that** videos are visually engaging and aid comprehension of complex topics.

### Acceptance Criteria

1. Manim Scene Analyzer: LLM identifies visualizable elements in script (timelines, maps, bar charts, flowcharts, comparisons)
2. Scene specifications generated: JSON array with scene type, data, styling (max 8 scenes per video)
3. Scene types supported: timeline (events with dates), map (countries/regions highlighted), bar chart (statistics), flowchart (process steps), split screen (before/after comparison)
4. VPS Manim Renderer called: `POST http://89.117.60.144:5555/render` with scene JSON array
5. Each scene rendered as MP4 clip (1080p, 30fps, 5-15 seconds duration)
6. Scene caching: check `manim_scene_cache` table for identical scene specs, reuse if exists
7. Render parallelization: up to 4 scenes rendered simultaneously
8. Rendered clips uploaded to Supabase Storage: `videos/manim-scenes/{video_id}/{scene_index}.mp4`
9. Render time: <2 minutes for all scenes (P95)
10. Fallback: if Manim render fails, use static images or proceed without visual (log warning)

---

## Story 3.4: Revideo Video Assembly - Final Composition

**As a** video producer,
**I want** Revideo to assemble script, TTS audio, Manim scenes, and transitions into final daily CA video,
**so that** the complete video is rendered and ready for publishing by 6 AM IST.

### Acceptance Criteria

1. Edge Function: `assemble_ca_video_pipe.ts` triggered after Manim scenes complete
2. TTS audio generated: ElevenLabs API with default voice (configurable in settings), script text → audio MP3
3. Audio segments timed: map each script segment to audio timestamp
4. Revideo composition: `DailyCATemplate` React component receives props (script, audio_url, manim_scene_urls, topic_timestamps)
5. Video structure: title card (5s) → intro (audio + text overlay) → segments (audio + Manim scenes + captions) → outro (5s)
6. Transitions: smooth fade between segments, animated topic headers
7. Captions: auto-generated SRT from script, burned into video (accessibility)
8. VPS Video Orchestrator renders Revideo composition: `POST http://89.117.60.144:8103/render`
9. Final video uploaded to Supabase Storage: `videos/daily-ca/{YYYY-MM-DD}.mp4`, CDN URL generated
10. Render time: <5 minutes (P95), status updated to 'completed' in `video_renders` table

---

## Story 3.5: Daily CA Video Publishing & Notification

**As a** UPSC aspirant,
**I want** to receive notification when daily current affairs video is published by 6 AM,
**so that** I can watch it during my morning study routine.

### Acceptance Criteria

1. Video published automatically: `video_renders.status = 'published'`, `published_at = NOW()`
2. Video visible on dashboard: hero card "Today's Current Affairs" with thumbnail, duration, "Watch Now" button
3. Push notifications sent: all users with notifications enabled receive alert "Today's CA video is ready!"
4. Email digest (optional): users subscribed to email receive HTML email with video embed link
5. Social media auto-post (admin controlled): Twitter/X, LinkedIn posts with video link and key topics hashtags
6. Archive page: `/daily-ca` route lists all past videos in calendar view
7. Video metadata: view count, completion rate, average watch time tracked in `video_analytics` table
8. Thumbnail auto-generated: first frame of video or custom thumbnail from Manim title card
9. SEO optimization: video page has meta tags (title, description, OG image) for sharing
10. Monitoring: alert admin if video not published by 6:30 AM (grace period for delays)

---

## Story 3.6: Daily CA PDF Summary & MCQ Generation

**As a** UPSC aspirant,
**I want** a downloadable PDF summary of daily current affairs with 5 practice MCQs,
**so that** I can review in text format and test my understanding.

### Acceptance Criteria

1. PDF generated automatically after video publish: triggered by status change to 'published'
2. PDF structure: cover page (date, logo) → summary (topic-wise bullets, 2-3 pages) → MCQs (5 questions, 4 options each, answers at end)
3. Summary bullets: 3-5 key points per topic segment, includes "Prelims relevance" and "Mains angle" markers
4. MCQs auto-generated: LLM creates fact-based questions from article content, distractor options, difficulty = medium
5. Answer key: last page with explanations (1-2 lines per answer)
6. PDF formatting: consistent branding (colors, fonts, header/footer), A4 size, printable
7. PDF uploaded to Supabase Storage: `pdfs/daily-ca/{YYYY-MM-DD}.pdf`
8. Download button visible on video page and dashboard card
9. Monthly compilation: on 1st of month, auto-generate combined PDF of all previous month's daily PDFs (100+ pages)
10. Generation time: <30 seconds (P95), cached for repeated downloads

---

## Story 3.7: 60-Second Social Media Shorts Generator

**As a** marketing team member,
**I want** automatic generation of 60-second shorts from daily CA video for social media,
**so that** we can promote the platform and drive signups through viral content.

### Acceptance Criteria

1. Shorts extracted from main video: identify 2-3 high-impact segments (based on topic importance scores)
2. Each short: 45-60 seconds, self-contained (intro + content + CTA)
3. Aspect ratios: 16:9 (YouTube), 9:16 (Instagram Reels, TikTok), 1:1 (LinkedIn, Twitter)
4. Revideo compositions: `ShortTemplate` with vertical layout, large captions, branding watermark
5. Shorts saved to Supabase Storage: `videos/shorts/{date}-{segment}-{ratio}.mp4`
6. Admin dashboard: `/admin/shorts` page lists generated shorts with preview, download, schedule post buttons
7. Auto-thumbnails: extract frame at 3-second mark, add text overlay with topic name
8. Captions optimized: larger font size (readable on mobile), emoji markers for emphasis
9. CTA end card: "Full video link in bio" + QR code + app logo (5 seconds)
10. Generation time: <2 minutes for all 3 aspect ratios (P95)

---

## Story 3.8: Daily CA Cron Job & Error Handling

**As a** system administrator,
**I want** robust error handling and alerting for the daily CA pipeline,
**so that** failures are detected immediately and backup plans executed.

### Acceptance Criteria

1. pg_cron job scheduled: `0 5 * * *` (5 AM IST daily), job name = 'daily_ca_pipeline'
2. Pipeline stages logged: scraper → script → manim → remotion → publish, each with timestamp and status
3. Stage-level retries: if stage fails, retry 3 times with 2-minute delays
4. Graceful degradation: if Manim fails, proceed with static images; if TTS fails, use backup voice
5. Alert triggers: if video not published by 6:30 AM, send email + Slack alert to admin
6. Manual override: admin can trigger pipeline manually via `/admin/daily-ca/trigger` button
7. Logs viewable in admin dashboard: `/admin/daily-ca/logs` with filter by date, stage, status
8. Health check endpoint: `GET /api/daily-ca/status` returns latest video status and pipeline health
9. Rollback mechanism: if video has critical errors, admin can "unpublish" and fix, re-publish
10. SLA tracking: dashboard shows % of on-time deliveries (target ≥95%), downtime alerts if <90%

---

## Story 3.9: Daily CA Archive & Search

**As a** UPSC aspirant,
**I want** to browse and search past daily current affairs videos by date, topic, and subject,
**so that** I can revisit important news and revise before exams.

### Acceptance Criteria

1. Archive page: `/daily-ca/archive` with calendar view (month grid, dates with videos highlighted)
2. Click date opens video detail page: video player, PDF download, MCQ quiz, related articles links
3. Filter by subject: checkboxes (Economy, Polity, IR, Environment, etc.), applies to visible videos
4. Search bar: full-text search across video scripts and article text
5. Date range picker: select start and end dates, show matching videos
6. List view toggle: switch between calendar and list view (cards with thumbnails)
7. Pagination: 30 videos per page in list view
8. Bulk download: select multiple dates, download ZIP of PDFs or videos
9. Watchlist: users can star important videos, accessible from "My Watchlist"
10. Performance: archive page loads <2 seconds with 365 days of data

---

## Story 3.10: Monthly CA Compilation - Documentary Format

**As a** UPSC aspirant,
**I want** a monthly compiled documentary-style video (30-45 minutes) summarizing the month's key current affairs,
**so that** I can efficiently revise an entire month's content in one session.

### Acceptance Criteria

1. Monthly compilation triggered on 1st of each month: Edge Function `generate_monthly_compilation_pipe.ts`
2. Content aggregation: all daily CA videos from previous month analyzed for top 20 topics (by importance, repeat mentions)
3. Script generated: 30-45 minute narrative connecting topics chronologically and thematically
4. Documentary structure: intro (month overview) → weekly breakdowns → subject-wise deep dives → conclusion (key takeaways)
5. Manim visuals: monthly trend graphs, comparative timelines, topic relationship maps
6. TTS narration: professional documentary-style voice (slower pace, dramatic pauses)
7. Revideo assembly: `MonthlyCompilationTemplate` with chapter markers, smooth transitions, background music
8. Chapters embedded: video has 8-12 chapters (clickable in player)
9. PDF booklet: 100+ page comprehensive notes with all month's content, formatted for printing/binding
10. Publishing: available by 3rd of month, prominent banner on dashboard "January 2025 Compilation Ready!"

---
