# Requirements

## Functional Requirements

**FR1: Interactive 3D UPSC Syllabus Navigator**
- The system shall provide a 3D interactive tree visualization of the complete UPSC syllabus (Prelims GS1-4, Mains GS1-4, CSAT, Essay)
- Shall support zoomable nodes, syllabus filters, bookmarks, and progress rings per topic
- Shall display heatmap of user's time-spent and performance per node
- Shall render intro explainer videos for each node using Revideo with Manim-generated visual diagrams
- **Monetization:** Freemium (basic 2D navigator free, advanced 3D guided roadmap paid)
- **Complexity:** High

**FR2: Daily Current Affairs Video Newspaper**
- The system shall auto-generate daily 5-8 minute video summarizing UPSC-relevant national/international current affairs by 6 AM IST
- Shall segment by topics (Economy, Polity, IR, Environment) with visual maps and timelines
- Shall auto-generate 30-60 second Shorts for social media sharing
- Shall provide downloadable PDF summary and 5 MCQs
- Shall compile monthly PDF (100+ pages) of all daily updates
- **Monetization:** Daily CA subscription, micro-purchases for deep-dive videos
- **Complexity:** High

**FR3: Real-Time Doubt to Video Converter**
- The system shall convert user text doubts or screenshot images into 60-180 second explainer videos within 2 minutes
- Shall support multiple styles (concise, detailed, example-rich), voice selection, and speed control
- Shall output video, short notes, and mini-quiz with each response
- Shall use Manim for technical diagrams and Revideo for TTS assembly
- **Monetization:** Per-video charge or monthly unlimited cap
- **Complexity:** High

**FR4: 3-Hour Documentary-Style Lectures**
- The system shall generate long-form cinematic lectures (2-3 hours) with automatic chapter segmentation
- Shall include bookmarks, suggested readings, timestamps, and per-chapter quizzes
- Shall use Revideo to sequence chapters and Manim for complex sub-explanations
- **Monetization:** Premium course bundles, one-time purchases (₹99/lecture)
- **Complexity:** Very High

**FR5: 360° Immersive Geography/History Visualizations**
- The system shall produce 360°/panoramic video experiences for geography and history topics
- Shall support interactive hotspots, embedded quizzes, and VR headset compatibility
- Shall use Revideo for stitching and Manim for animated data overlays
- **Monetization:** Premium feature, marketing shorts
- **Complexity:** Very High

**FR6: 60-Second Topic Shorts**
- The system shall auto-create 60-second explainer videos for any UPSC topic
- Shall generate auto-thumbnails, SEO-friendly titles, and support scheduling to social accounts
- Shall output videos in multiple aspect ratios (16:9, 9:16, 1:1)
- **Monetization:** Marketing tool for paid subscriptions, packaged short bank
- **Complexity:** Medium

**FR7: Visual Memory Palace Videos**
- The system shall convert lists/facts into visual memory palace animations (rooms → facts)
- Shall support custom palace themes per student and spaced repetition integration
- Shall use Manim for 2D/3D object transitions and Revideo for compilation
- **Monetization:** One-off purchase or premium feature
- **Complexity:** High

**FR8: Ethical Case Study Roleplay Videos (GS4)**
- The system shall provide choose-your-path ethical dilemmas with branching video paths
- Shall grade decisions by ethical frameworks (utilitarian, deontological) with feedback video
- Shall use Revideo for branch video assembly and Manim for concept diagrams
- **Monetization:** Premium case packs, mentor review add-on
- **Complexity:** High

**FR9: Animated Math Problem Solver (CSAT/Economy)**
- The system shall provide step-by-step animated solutions for quantitative and graph problems
- Shall support typed problems or image upload (OCR)
- Shall output Manim animation clip, text solution, and downloadable slides
- **Monetization:** Per-solve credits or subscription bundle
- **Complexity:** High

**FR10: Static & Animated Notes Generator**
- The system shall generate notes at 3 levels (summary 100 words, detailed 250 words, comprehensive 500 words)
- Shall create Manim diagrams and 60-second video summaries
- Shall export as PDF, markdown with cross-links to related topics
- **Monetization:** Notes store, subscription for full notes set
- **Complexity:** Medium

**FR11: Animated Case Law, Committee & Amendment Explainer**
- The system shall visually map legal cases, amendments, committee timelines and relationships
- Shall provide timeline slider and interactive nodes linking to full text and videos
- Shall use Manim for legal relationship diagrams and Revideo for narrated video
- **Monetization:** Course modules (Polity pack)
- **Complexity:** Medium-High

**FR12: AI Study Schedule Builder**
- The system shall generate personalized adaptive schedules considering weak topics, tests, and time availability
- Shall support push notifications, Google Calendar sync, micro-goals, and streaks
- Shall output daily schedule with recommended video/note/quiz assignments
- Shall optionally generate daily briefing video via Revideo
- **Monetization:** Premium guided plans, coach add-ons
- **Complexity:** Medium

**FR13: Fully Automated PYQ Video Explanation Engine**
- The system shall ingest PYQ PDFs/images and generate model answers with animated explanations
- Shall auto-group by topic and assign difficulty tags
- Shall use Manim for diagrams/walkthroughs and Revideo for final video assembly
- **Monetization:** PYQ packs, pay-per-video
- **Complexity:** High

**FR14: 3D Interactive GS Map Atlas**
- The system shall provide layered interactive maps for geography, resources, demographics, disaster zones
- Shall support time slider for historical maps, data overlays, animated flows (rivers, migration)
- Shall export interactive 3D maps, images, and narrated video tours
- **Monetization:** Country/State packs, premium data layers
- **Complexity:** Very High

**FR15: AI Essay Trainer with Live Video Feedback**
- The system shall accept essays (up to 1000 words) and provide AI scoring with video walkthrough
- Shall use rubric-based scoring and model answer comparison
- Shall use Manim for argument structure visualization and Revideo for feedback video
- **Monetization:** Essay review credits, subscription
- **Complexity:** Medium

**FR16: Daily Answer Writing + AI Scoring + Video Feedback**
- The system shall provide daily Mains answer practice with instant AI scoring and video suggestions
- Shall support timed writing mode and comparison with topper answers
- Shall use Manim for diagrams in suggested answers and Revideo for feedback video
- **Monetization:** Daily practice subscription, per-evaluation credits
- **Complexity:** Medium

**FR17: GS4 Ethics Simulator (Advanced)**
- The system shall provide multi-stage ethical dilemmas with user decisions, scoring, and personality analysis
- Shall offer multi-path scenarios, behavior analytics, and recommended readings
- Shall use Manim for moral framework diagrams and Revideo for outcome rendering
- **Monetization:** Scenario packs, premium mentor reviews
- **Complexity:** High

**FR18: RAG-Based UPSC Search Engine**
- The system shall provide high-precision semantic search across curated UPSC knowledge base
- Shall support source filters, exact book & chapter references, and explainability boxes
- Shall output ranked hits with citations and AI-generated answer snippets
- Shall optionally create short Revideo explainer for complex queries
- **Monetization:** Premium search features (advanced filters, saved searches)
- **Complexity:** Medium

**FR19: AI Topic-to-Question Generator (Mains + Prelims)**
- The system shall auto-generate MCQs, Prelims questions, Mains prompts, case studies, and model answers from topics
- Shall support difficulty tags, distractor generation for MCQs, and auto-marking rubrics
- Shall optionally provide Revideo video for model answer explanation
- **Monetization:** Test packs, custom mock tests
- **Complexity:** Low-Medium

**FR20: Personalized AI Teaching Assistant**
- The system shall provide conversational tutor with chosen teacher style, voice, and tone control
- Shall retain user context, provide daily check-ins, progress nudges, and micro-assignments
- Shall generate motivational videos via Revideo and visual explanations via Manim
- **Monetization:** Tiered subscription (standard vs premium mentor)
- **Complexity:** Medium

**FR21: UPSC Mindmap Builder**
- The system shall auto-build mindmaps from topic text, book chapters, or user notes
- Shall support drag & drop editing, PNG/PDF export, and collaborative sharing
- Shall optionally create animated map walkthrough videos via Revideo
- **Monetization:** Premium export/large map limits
- **Complexity:** Medium

**FR22: Ultra-Detailed Syllabus Tracking Dashboard**
- The system shall provide master dashboard with completed topics, strength/weakness analysis, and estimated readiness
- Shall display competency index, time-on-topic, predicted Prelims score, and custom milestones
- Shall output CSV export and recommended study paths
- Shall generate weekly progress video briefings via Revideo
- **Monetization:** Analytics premium plan
- **Complexity:** Medium

**FR23: Smart Revision Booster**
- The system shall automatically select 5 weakest topics weekly and generate revision packages
- Shall include short video, 5 flashcards, and 10-minute quiz
- Shall implement spaced repetition algorithm with push reminders
- Shall use Revideo for revision videos and Manim for quick visuals
- **Monetization:** Add-on subscription, higher cadence paid tier
- **Complexity:** Medium

**FR24: 5-Hours Per Day Planner (Working Professional)**
- The system shall provide pre-built customizable daily plans optimized for limited study hours
- Shall support drag-to-reschedule, auto-adjust for missed sessions, and weekly summaries
- Shall optionally generate daily briefing video via Revideo
- **Monetization:** Paid plan, lifetime planner purchase
- **Complexity:** Low-Medium

**FR25: Book-to-Notes Converter**
- The system shall ingest PDF/epub/text chapters and output multi-level notes (Prelims/Mains versions)
- Shall auto-map chapters to syllabus nodes with citations
- Shall generate key facts MCQs, Manim diagrams, and 1-minute summary video
- **Monetization:** Per-chapter conversion credits, subscription
- **Complexity:** Medium

**FR26: Weekly Documentary (What's Happening in the World)**
- The system shall generate weekly 15-30 minute documentary-style analysis (Economy, Polity, IR, Environment)
- Shall include deep dives, AI-simulated expert interviews, maps, and graphs
- Shall use Manim for data charts and Revideo for documentary visuals
- **Monetization:** Premium weekly package
- **Complexity:** High

**FR27: Test Series Auto-Grader + Performance Graphs**
- The system shall provide full test platform auto-grading both objective and subjective answers
- Shall display historical comparison, strengths heatmap, and growth charts over time
- Shall optionally generate result walkthrough videos via Revideo
- **Monetization:** Test subscriptions, timed mocks
- **Complexity:** Medium

**FR28: Advanced User Monetization System**
- The system shall manage all monetization flows: subscriptions, per-video purchases, coupons, affiliate offers, institutional licensing
- Shall support promo codes, A/B price testing, and in-app purchases
- Shall provide invoices, entitlements, and revenue dashboard
- **Complexity:** Medium-High

**FR29: AI Voice Teacher (Customizable TTS)**
- The system shall provide customizable TTS voices with teaching styles (speed/clarity/charisma sliders)
- Shall support accent selection, celebrity-style voice presets, and fallback text transcripts
- Shall integrate TTS audio with Revideo video sync
- **Monetization:** Premium voice packs, custom voice extra charge
- **Complexity:** Medium

**FR30: Gamified Learning Experience (Lightweight)**
- The system shall provide 3D subject rooms with XP, badges, streaks, and collaborative study sessions
- Shall generate cinematic reward videos via Revideo and in-room mini-challenges via Manim
- **Monetization:** Cosmetic purchases, premium avatars, institutional packages
- **Complexity:** High

**FR31: Topic Difficulty Predictor (AI Prognosis)**
- The system shall predict topic difficulty and weight in upcoming exams based on historical PYQ data and news signals
- Shall provide confidence scores and recommended study weight
- Shall generate report videos via Revideo and trend visualization graphs via Manim
- **Monetization:** Premium analytics
- **Complexity:** Medium-High

**FR32: Smart Bookmark Engine**
- The system shall allow saving concepts with auto-linked notes, PYQs, visual explanations, and scheduled revisions
- Shall support auto-tagging, cross-links, and revision reminders
- Shall optionally generate on-demand Revideo quick explainer for bookmarks
- **Monetization:** Premium bookmark limits & sync
- **Complexity:** Low-Medium

**FR33: Concept Confidence Meter**
- The system shall display visual confidence meter per topic (red/yellow/green) based on quiz results, time spent, and spaced repetition
- Shall provide confidence delta alerts and suggested micro-actions
- Shall generate weekly confidence report videos via Revideo
- **Monetization:** Premium analytics, coach tie-ins
- **Complexity:** Low-Medium

**FR34: Live Interview Prep Studio (Flagship)**
- The system shall provide real-time interactive interview simulations with AI interviewer(s) using TTS
- Shall generate real-time visual aids (Manim diagrams, timelines, maps) as candidate answers
- Shall record sessions (audio/video + screen overlays) and generate instant Revideo debrief video (3-5 minutes)
- Shall optionally analyze body language (opt-in with explicit consent) providing improvement tips
- Shall support panel mode with peer/mentor reviews integrated into feedback
- Shall implement adaptive interview question bank with difficulty progression
- **User Flow:** Book slot → AI panel TTS → "Show Visual" button triggers Manim render → Auto-debrief video post-session
- **Monetization:** High-value premium (₹999/month or ₹2999 one-time), paid mentor review add-on
- **Privacy:** Explicit consent for recordings, secure storage, delete-on-demand
- **Complexity:** Very High (requires low-latency Manim microservice 2-6s, streaming compositing, real-time orchestration)

## Non-Functional Requirements

**NFR1: System Availability**
- The system shall maintain 95%+ uptime (max 36 hours downtime/month) with Sentry monitoring and alerting

**NFR2: Video Rendering Success Rate**
- Video rendering shall achieve ≥95% success rate with 3-attempt retry logic; failures escalated to manual review

**NFR3: Doubt Video Generation Latency**
- Doubt-to-video generation shall complete in <60 seconds for 60s videos (P95) and <120 seconds for 180s videos (P95)

**NFR4: RAG Search Performance**
- RAG semantic search queries shall return results in <500ms (P95) for top 10 results

**NFR5: Daily CA Video Delivery**
- Daily current affairs video shall be published by 6:00 AM IST with ≤5% failure rate requiring manual fallback

**NFR6: Concurrent User Capacity**
- The system shall handle 10,000 concurrent users without degradation (FCP <1.5s, LCP <2.5s)

**NFR7: AI Cost Per User**
- AI cost per user shall not exceed ₹200/month (LLM API + video rendering + infrastructure) for 67% gross margin

**NFR8: Vector Database Scale**
- Database shall support 1M+ knowledge chunks with vector search <500ms using pgvector ivfflat indexing

**NFR9: Caching Efficiency**
- The system shall achieve 70% cache hit rate for LLM API calls to control costs

**NFR10: Video Delivery Performance**
- Video storage via Cloudflare CDN shall achieve <1 second playback start latency globally

**NFR11: Mobile Responsiveness**
- The system shall be mobile-first responsive supporting Chrome 90+, Safari 14+ on iOS 14+

**NFR12: Form Validation Performance**
- All forms shall have client-side Zod validation with error display within 100ms

**NFR13: Accessibility Compliance**
- The system shall maintain WCAG 2.1 AA standards (keyboard navigation, screen readers, color contrast)

**NFR14: Rate Limiting**
- Edge Functions shall implement 100 requests/minute/user rate limiting to prevent abuse

**NFR15: Security Architecture**
- All external API calls shall be server-side only through Supabase Edge Functions; no client-side service URL exposure

**NFR16: Horizontal Scaling**
- Video rendering shall support horizontal scaling from 1 VPS (1K concurrent) to 10 VPS (10K concurrent)

**NFR17: Content Accuracy**
- Content accuracy shall be ≥99% validated via user feedback and quarterly SME audits of 100 random answers

**NFR18: Knowledge Base Capacity**
- The system shall support 50GB total PDF knowledge base (200+ standard UPSC books)

**NFR19: Payment Security**
- Payment processing shall be PCI-compliant via RevenueCat; no credit card data in application database

**NFR20: Refund Processing**
- 7-day money-back guarantee and pro-rated refunds shall process within 48 hours

**NFR21: Manim Render Optimization (FR34)**
- Manim microservice shall render small scenes in 2-6 seconds for real-time interview visual aids

**NFR22: RAG Confidence Threshold**
- All AI-generated content shall require ≥70% RAG confidence score; below threshold displays "Cannot answer with high confidence"

**NFR23: Source Citation Mandatory**
- Every AI answer shall cite source as "Based on [Book Name], Chapter X, Page Y"

**NFR24: Content Flagging SLA**
- User-reported incorrect information shall route to review queue within 24 hours with resolution tracking

**NFR25: Whitelisted Sources Only**
- Daily current affairs shall source only from approved domains: visionias.in, drishtiias.com, thehindu.com, pib.gov.in, forumias.com, insightsonindia.com, iasbaba.com, iasscore.in, nextias.com, *.gov.in

---
