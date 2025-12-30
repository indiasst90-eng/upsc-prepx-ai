# Epic 4: On-Demand Video Learning - Doubt Converter & Topic Shorts

**Epic Goal:**
Enable real-time doubt-to-video conversion and 60-second topic shorts generation, providing on-demand personalized video explanations for any UPSC topic or user question within 60-120 seconds. This epic leverages the video pipeline from Epic 3 but optimizes for speed with shorter videos, cached components, and priority queuing. By the end of this epic, Pro users can convert text/image doubts into 60-180 second explainer videos and generate instant 60s shorts for any syllabus topic, establishing the platform's core differentiation of on-demand visual learning.

## Story 4.1: Doubt Submission Interface - Text & Image Input

**As a** UPSC aspirant,
**I want** to submit doubts via text, voice, or screenshot image,
**so that** I can get video explanations for any question regardless of input format.

### Acceptance Criteria

1. Doubt submission page: `/ask-doubt` with prominent input area (autofocus on load)
2. Input methods: text area (2000 char limit), image upload (drag-drop or camera), voice recording (60s max, browser MediaRecorder API)
3. Image upload: accept PNG, JPG, PDF; max 10MB; preview thumbnail displayed
4. OCR processing: if image uploaded, extract text using Tesseract.js (client-side) or Cloud Vision API (server-side)
5. Voice transcription: audio sent to Whisper API (OpenAI) for speech-to-text
6. Style selector: radio buttons (Concise, Detailed, Example-Rich), default = Detailed
7. Video length selector: 60s, 120s, 180s (Pro users only for 180s)
8. Voice preference: dropdown (male/female, accent options), uses user's profile default
9. Preview mode: show extracted text from image/voice before submission, allow edits
10. Entitlement check: Free users limited to 3 doubts/day, Trial/Pro unlimited, show usage counter

---

## Story 4.2: Doubt Processing Pipeline - Script Generation

**As a** system,
**I want** to analyze doubt input using RAG retrieval and generate a structured video script,
**so that** video explanations are accurate, grounded in UPSC sources, and appropriately detailed.

### Acceptance Criteria

1. Edge Function: `doubt_video_converter_pipe.ts` at endpoint `POST /api/doubts/create`
2. Request payload: `{ doubt_text, style, length, voice, user_id }`
3. Content safety filter: check for NSFW/harmful content, block if flagged
4. RAG retrieval: query `knowledge_chunks` with doubt text, fetch top 5 relevant chunks (confidence >0.70)
5. If confidence <0.70, return warning modal: "Limited source material. Video may not be fully accurate. Proceed?"
6. Script generation: LLM synthesizes answer from RAG chunks, structured as intro → explanation → example → conclusion
7. Script length calibrated: 150 words for 60s, 300 words for 120s, 450 words for 180s
8. Style variations applied: Concise (bullets, minimal examples), Detailed (full explanations), Example-Rich (2-3 case studies)
9. Script saved to `video_renders` table: content_type = 'doubt_video', script_json, status = 'pending_manim'
10. Job ID returned to client: `{ job_id, estimated_time: 60 }`, client polls status

---

## Story 4.3: Doubt Video - Manim Scene Generation (Optimized)

**As a** video producer,
**I want** Manim to generate diagrams for doubts within 15-20 seconds,
**so that** total video generation stays under 60 seconds for user satisfaction.

### Acceptance Criteria

1. Manim scene specs generated: max 2 scenes per doubt video (complexity constraint)
2. Scene types prioritized for speed: simple diagrams (2D shapes, arrows), text animations, timeline (if applicable)
3. Cache-first strategy: check `manim_scene_cache` for similar scene specs (fuzzy match with 80% similarity)
4. If cache hit, reuse scene; if cache miss, render new scene
5. VPS Manim Renderer optimized: use pre-warmed render workers, priority queue for doubt videos
6. Render time target: <15 seconds per scene (P95)
7. Parallel rendering: both scenes render simultaneously if 2 scenes needed
8. Fallback: if render exceeds 20s, skip Manim scene and use text-only video (inform user)
9. Rendered clips uploaded to Supabase Storage: `videos/manim-scenes/doubts/{job_id}/{scene_index}.mp4`
10. Status updated: `video_renders.status = 'pending_revideo'`

---

## Story 4.4: Doubt Video - Revideo Assembly (Optimized)

**As a** video producer,
**I want** Revideo to assemble doubt videos within 30-40 seconds,
**so that** users receive video explanations in under 60 seconds total.

### Acceptance Criteria

1. TTS audio generated: ElevenLabs API with user's selected voice, script → MP3
2. Audio generation time: <10 seconds (use Turbo models)
3. Revideo composition: `DoubtVideoTemplate` receives props (script, audio_url, manim_scene_urls, style)
4. Template variations: Concise (minimal transitions, fast pace), Detailed (slower pace, pauses), Example-Rich (more visuals)
5. Captions: auto-generated from script, burned into video
6. Branding: small logo watermark, end card with "Ask more doubts on UPSC AI Mentor" (3s)
7. VPS Video Orchestrator: priority queue for doubt videos (higher priority than daily CA)
8. Render time target: <30 seconds (P95)
9. Video uploaded to Supabase Storage: `videos/doubts/{job_id}.mp4`
10. Status updated: `video_renders.status = 'completed'`, notification sent to client

---

## Story 4.5: Doubt Video - Response Interface & Player

**As a** UPSC aspirant,
**I want** to see my doubt video as soon as it's ready with options to download, share, and provide feedback,
**so that** I can immediately learn from the explanation and revisit it later.

### Acceptance Criteria

1. Client polls job status: `GET /api/jobs/{job_id}` every 3 seconds while status = 'processing'
2. Progress indicator: animated progress bar with stages (Analyzing → Generating Script → Creating Visuals → Assembling Video)
3. Video player loads when status = 'completed': autoplay enabled, controls (pause, speed 0.5x-2x, seek, fullscreen)
4. Below video: collapsible transcript, source citations ("Based on Laxmikanth Polity, Chapter 5"), related topics links
5. Action buttons: Download video, Share link (generates shareable URL), Report issue, Ask follow-up
6. Feedback: thumbs up/down, optional comment box ("Was this helpful?"), sentiment saved for analytics
7. Short notes: auto-generated bullet summary (5-7 points) displayed alongside video
8. Mini-quiz: 3 MCQs based on doubt topic, instant feedback on answers
9. Video saved to user's history: accessible from "My Doubts" page (ordered by recent)
10. Performance: video starts playing within 1s of status = 'completed'

---

## Story 4.6: 60-Second Topic Shorts - On-Demand Generation

**As a** UPSC aspirant,
**I want** to generate 60-second explainer videos for any syllabus topic instantly,
**so that** I can quickly understand concepts without reading long notes.

### Acceptance Criteria

1. "Generate Short" button on every syllabus node detail modal and notes page
2. Click button opens confirmation modal: "Generate 60s video for [Topic Name]? (Uses 1 credit)" (Free users see upgrade prompt)
3. Edge Function: `generate_topic_short_pipe.ts` at `POST /api/shorts/create`
4. Script generated from topic notes (if exists) or RAG retrieval (if no notes)
5. Script structure: hook (5s) → definition (10s) → key points (35s) → UPSC relevance (10s)
6. Manim scene: 1 simple visual (definition diagram or process flowchart)
7. TTS audio: upbeat voice, faster pace (165 words/minute vs 150 standard)
8. Revideo composition: `TopicShortTemplate` with dynamic text overlays, emoji markers, energetic transitions
9. Video rendered in 16:9, 9:16, 1:1 aspect ratios simultaneously
10. Generation time: <45 seconds (P95), status polling same as doubts

---

## Story 4.7: Topic Shorts - Social Sharing & Viral Features

**As a** UPSC aspirant,
**I want** to share topic shorts on social media with branded watermark and call-to-action,
**so that** I can help peers and promote the platform organically.

### Acceptance Criteria

1. Share button on short video player: opens modal with social network icons (WhatsApp, Twitter, LinkedIn, Instagram, Telegram)
2. Watermark embedded: "Generated by UPSC AI Mentor - upsc-ai-mentor.com" in corner (subtle, non-intrusive)
3. End card (last 5 seconds): CTA "Want full explanation? Link in bio" + QR code + logo
4. Shareable link generated: `https://upsc-ai-mentor.com/shorts/{short_id}` (public, no login required for viewing)
5. Link preview: video thumbnail, title "Learn [Topic] in 60s", description with hashtags
6. WhatsApp share: direct video file sent (compressed to <5MB), fallback to link if larger
7. Instagram format: 9:16 ratio optimized for Reels, caption auto-populated with hashtags
8. Twitter/X: video uploaded directly via API (with user permission), tweet text includes topic + hashtags
9. Download options: download video file (watermarked), download thumbnail (for custom posts)
10. Analytics tracked: shares count, views via shareable link, conversion to signups (UTM tracking)

---

## Story 4.8: Doubt & Short Credits System

**As a** product manager,
**I want** a credit-based system for doubt videos and topic shorts to monetize and manage usage,
**so that** we can sustain AI costs while offering fair access to users.

### Acceptance Criteria

1. Credit allocation: Free (3 doubts/day, 2 shorts/day), Trial (unlimited), Pro Monthly (unlimited), Pro Annual (unlimited + priority queue)
2. Credits reset: daily at midnight IST for Free users
3. Credit counter displayed: header badge "3 doubts left today", updated real-time after each use
4. Purchase credits: Free users can buy credit packs (10 doubts = ₹99, 50 doubts = ₹399), payment via Razorpay
5. Credits table: `user_credits` with columns (user_id, credit_type, balance, expires_at)
6. Credit deduction: atomic transaction (check balance → deduct → create video job), rollback if job fails
7. Usage analytics: admin dashboard shows credits usage per user, most common doubt topics, conversion to Pro
8. Upgrade prompts: when Free user exhausts credits, show modal "Upgrade to Pro for unlimited doubts + faster generation"
9. Refund policy: if video generation fails after credit deducted, refund credit automatically
10. Expiry: purchased credits valid for 90 days, expiring credits flagged in user dashboard

---

## Story 4.9: Doubt Video Queue Management & Prioritization

**As a** system administrator,
**I want** intelligent queue management prioritizing Pro users and optimizing resource utilization,
**so that** we deliver the best experience to paying users while maintaining fairness.

### Acceptance Criteria

1. Job queue table: `jobs` with columns (job_id, user_id, job_type, priority, status, created_at, started_at, completed_at)
2. Priority levels: Critical (admin manual), High (Pro Annual), Medium (Pro Monthly, Trial), Low (Free)
3. Queue processor: picks jobs by priority (high first), then FIFO within same priority
4. Concurrency limits: max 10 doubt videos rendering simultaneously, max 5 topic shorts
5. If queue exceeds 50 pending jobs, throttle Free user submissions (show "High demand, try again in 5 min")
6. Estimated wait time calculated: based on queue position and average render time, displayed to user
7. Job timeout: if job processing exceeds 5 minutes, mark as failed, alert admin, refund credits
8. Dead letter queue: failed jobs moved to separate table for manual review and retry
9. Monitoring dashboard: `/admin/video-queue` shows real-time queue status, success/fail rates, bottlenecks
10. Auto-scaling: if queue consistently >30 jobs, trigger alert to provision additional VPS render workers

---

## Story 4.10: Doubt History & Follow-Up Questions

**As a** UPSC aspirant,
**I want** to view my doubt history and ask follow-up questions linked to previous doubts,
**so that** I can build on my understanding and track my learning journey.

### Acceptance Criteria

1. My Doubts page: `/my-doubts` lists all past doubts with filters (date, subject, status)
2. Card displays: doubt text (truncated), topic, video thumbnail, created date, status badge
3. Click card opens detailed view: full doubt text, video player, transcript, notes, quiz results
4. Follow-up button: opens new doubt submission form with context pre-filled ("Following up on: [previous doubt]")
5. Thread view: if follow-up exists, display as threaded conversation (parent doubt → child doubts)
6. Search doubts: full-text search across all doubt text and transcripts
7. Bookmark doubts: star icon to mark important doubts, filter by bookmarked
8. Export history: download CSV with all doubts, topics, dates, video links
9. Delete doubts: user can delete individual doubts (video deleted from storage, credits not refunded)
10. Analytics: personal stats shown (total doubts asked, topics covered, most asked subjects)

---
