# Project Brief: UPSC PrepX-AI

## Executive Summary

**UPSC PrepX-AI** is an enterprise-grade AI-powered UPSC exam preparation platform that leverages automated video generation, adaptive learning, and comprehensive RAG-based knowledge systems to revolutionize civil services preparation. The platform addresses the critical need for personalized, high-quality, and affordable UPSC preparation by combining AI-generated video content (via Manim mathematical animations and Revideo video composition), real-time current affairs integration, and a comprehensive knowledge base built from standard UPSC textbooks.

**Primary Problem:** UPSC aspirants face fragmented learning resources, expensive coaching institutes (?2-3 lakhs/year), lack of personalized guidance, and difficulty keeping up with daily current affairs in exam-relevant formats.

**Target Market:** 5-7 lakh annual UPSC aspirants in India, particularly working professionals and students in Tier 2/3 cities who cannot access premium coaching.

**Key Value Proposition:** AI-generated video explanations on-demand, daily current affairs video newspaper, comprehensive notes from standard books, and personalized study planning at ?599/month (vs ?15,000-25,000/month for traditional coaching).

---

## Problem Statement

### Current State and Pain Points

UPSC Civil Services Examination preparation currently suffers from multiple critical challenges:

1. **Cost Barrier:** Premium coaching institutes charge ?2-3 lakhs annually, excluding 70-80% of aspirants from quality guidance
2. **Geographic Limitation:** Top coaching centers concentrate in Delhi, Prayagraj, and major metros, forcing students to relocate
3. **Static Content:** Traditional video courses become outdated within months as current affairs and syllabus evolve
4. **Fragmented Resources:** Students must navigate 15+ books, 10+ websites, and multiple test series without cohesive integration
5. **One-Size-Fits-All:** Coaching batches of 100+ students receive identical content regardless of individual weak areas
6. **Current Affairs Overload:** Students struggle to filter UPSC-relevant news from general media and consolidate it into exam-ready notes
7. **Doubt Resolution Lag:** Batch coaching provides limited individual attention; online forums take 24-48 hours for responses
8. **Interview Preparation Gap:** Most institutes provide minimal mock interviews (2-3 sessions), insufficient for personality test preparation

### Impact (Quantified)

- **Market Size:** 5-7 lakh UPSC aspirants annually, with 60% attempting for 2+ years
- **Financial Burden:** Average aspirant spends ?4-5 lakhs over 2 years (coaching + books + tests)
- **Success Rate:** Only 0.1% (1000/1,000,000) clear UPSC annually, partly due to resource inequality
- **Time Waste:** 40% of study time spent searching for resources and organizing notes rather than actual learning

### Why Existing Solutions Fall Short

**Offline Coaching:**
- High cost (?2-3L/year)
- Fixed schedules incompatible with working professionals
- No personalization for weak topics
- Limited interview prep

**Online Courses (Unacademy, BYJU'S):**
- Pre-recorded lectures become outdated
- No real-time doubt resolution
- Minimal AI adaptation to individual progress
- Current affairs updates are PDF-based, not video summaries

**YouTube Free Content:**
- Fragmented and inconsistent quality
- No structured syllabus coverage tracking
- No practice tests or personalized feedback
- Lacks comprehensive note-taking system

**Existing AI Tools (ChatGPT):**
- Lack UPSC-specific knowledge base (no Laxmikanth Polity, NCERT integration)
- Cannot generate video explanations with visual diagrams
- No spaced repetition or progress tracking
- Cannot create personalized study schedules based on exam date

### Urgency and Importance

- **2024-2025 Exam Cycle:** UPSC Prelims 2025 scheduled for May; aspirants starting preparation NOW
- **Post-COVID Shift:** 70% of students now prefer hybrid/online learning (KPMG Education Report 2023)
- **AI Adoption Window:** First-mover advantage in AI-powered UPSC coaching before competitors build similar capabilities
- **Revenue Opportunity:** ?5,000 crore UPSC coaching market growing at 12% CAGR

---

## Proposed Solution

### Core Concept and Approach

UPSC PrepX-AI is an **AI-native adaptive learning platform** that combines:

1. **RAG-Powered Knowledge Base:** Ingest all standard UPSC books (Laxmikanth, NCERT, Spectrum, etc.) into a vector database (Supabase pgvector) for semantic search and context-aware answer generation

2. **Automated Video Generation Engine:**
   - **Manim:** Mathematical/diagram animations for complex visualizations (timelines, graphs, maps, constitutional diagrams)
   - **Revideo:** React-based video composition engine for assembling scenes, TTS narration, and final rendering
   - **Video Orchestrator:** Self-hosted service coordinating multi-scene video assembly

3. **35 Specialized Features** organized into:
   - **Daily Content:** Auto-generated current affairs video newspaper (5-8 min daily)
   - **On-Demand Learning:** Real-time doubt-to-video converter (60-180 sec explanations)
   - **Deep Study:** 3-hour documentary lectures, comprehensive notes, PYQ video explanations
   - **Practice:** AI essay trainer, daily answer writing with video feedback, test series auto-grader
   - **Planning:** AI study schedule builder, progress dashboard, weakness identification
   - **Interview Prep:** Live interview simulator with real-time visual aids and instant video debrief

4. **Adaptive Intelligence:**
   - Track user performance per topic
   - Auto-identify weak areas
   - Generate personalized revision packages
   - Adjust study schedule based on missed sessions and progress

5. **Whitelisted Current Affairs Sources:** Only UPSC-relevant domains (visionias.in, drishtiias.com, thehindu.com, pib.gov.in, etc.)

### Key Differentiators

| Feature | UPSC PrepX-AI | Traditional Coaching | Other Online Platforms |
|---------|---------------|---------------------|----------------------|
| **Cost** | ?599-4799/year | ?2-3L/year | ?15,000-50,000/year |
| **Video Generation** | On-demand AI videos for ANY doubt | Pre-recorded only | Pre-recorded only |
| **Current Affairs** | Daily 5-8 min video + PDF | Weekly PDFs | Monthly PDFs |
| **Personalization** | AI-driven per-topic adaptation | Batch teaching | Limited quiz-based |
| **Knowledge Base** | Complete UPSC book corpus via RAG | Separate books | Partial coverage |
| **Interview Prep** | Unlimited AI mocks + real-time visuals | 2-3 live mocks | None or basic |
| **3D Syllabus Navigator** | Interactive tree with progress tracking | Printed syllabus | Static webpage |
| **Answer Evaluation** | AI scoring + video feedback | Manual (slow) | Auto MCQ only |

### Why This Solution Will Succeed

1. **Technology Moat:** Manim + Revideo + RAG combination is difficult to replicate; requires video rendering infrastructure and UPSC-specific knowledge curation
2. **Content Freshness:** Auto-generation ensures daily current affairs without manual video production teams
3. **Accessibility:** Mobile-first design with offline video download for students in low-bandwidth areas
4. **Pricing Disruption:** 10x cheaper than coaching with comparable quality, targeting the 70% "priced-out" segment
5. **Data Flywheel:** More users ? more usage data ? better AI models ? improved personalization ? higher retention
6. **Scalability:** Automated video generation scales infinitely; one infrastructure serves 100K+ users without linear cost increase

### High-Level Vision

**Year 1:** Dominate AI-powered UPSC preparation with 50,000 paid subscribers
**Year 2:** Expand to state PSC exams (MPPSC, UPPSC, etc.) and banking/SSC preparation
**Year 3:** White-label enterprise solution for coaching institutes and government training academies

---

## Target Users

### Primary User Segment: Serious UPSC Aspirants (Working Professionals)

**Demographics:**
- Age: 24-30 years
- Education: Graduates/postgraduates from Tier 1/2 colleges
- Employment: Working professionals attempting UPSC while employed (60% of aspirants)
- Location: Tier 2/3 cities (Jaipur, Lucknow, Pune, Hyderabad) and rural areas
- Income: ?3-8 LPA household income

**Current Behaviors:**
- Study 4-6 hours daily (early morning 5-7 AM, evening 8-11 PM)
- Rely on YouTube + PDF notes + 1-2 coaching test series
- Spend ?500-1000/month on study materials
- Struggle to maintain consistency due to work commitments

**Pain Points:**
- Cannot afford/relocate for Delhi coaching
- Need quick doubt resolution during limited study hours
- Difficulty tracking syllabus completion across 10+ books
- Current affairs overwhelming (100+ news items daily, unsure which are UPSC-relevant)
- Lack personalized guidance on weak topics

**Goals:**
- Clear Prelims in first/second attempt
- Build strong conceptual foundation for Mains
- Practice answer writing daily (but no one to evaluate)
- Stay updated on current affairs without information overload
- Optimize study time for maximum efficiency

**Use Case:** Rajesh, 27, software engineer in Pune, wakes at 5 AM to study before work. Uses UPSC PrepX-AI to watch 5-minute daily current affairs video during breakfast, gets real-time video explanation for doubts during evening study, and practices answer writing with AI feedback before bed.

---

### Secondary User Segment: Full-Time Students (First-Time Aspirants)

**Demographics:**
- Age: 21-25 years
- Education: Final year graduates or recently graduated
- Employment: Unemployed, fully dedicated to UPSC preparation
- Location: Metro cities with access to libraries and study groups
- Income: ?1-4 LPA family income

**Current Behaviors:**
- Study 8-12 hours daily in library or home
- Attend local coaching for some papers (Polity, History)
- Spend ?10,000-30,000/year on coaching + test series
- Active in online study groups and Telegram channels

**Pain Points:**
- Need structured syllabus coverage (feeling lost in vast syllabus)
- Require daily accountability and progress tracking
- Want interview preparation but institutes charge ?50,000+ separately
- Comparing themselves with peers, seek gamification/leaderboards

**Goals:**
- Complete entire syllabus in 12 months before first attempt
- Score 95+ in Prelims (cutoff typically 90-92)
- Build writing skills for Mains (most critical differentiator)
- Ace personality test interview

**Use Case:** Priya, 23, BA graduate in Bhopal, uses UPSC PrepX-AI's 3D syllabus navigator to track completion of 100+ topics, generates comprehensive notes from standard books, practices daily with AI essay trainer, and does 2-3 mock interviews weekly.

---

## Goals & Success Metrics

### Business Objectives

- **User Acquisition:** Achieve 10,000 trial signups in first 3 months post-launch (via YouTube shorts, Instagram reels)
- **Conversion Rate:** Convert 15% of trial users to paid subscriptions (?599 monthly plan)
- **Revenue Target:** ?50 lakhs MRR by Month 6, ?2 crore MRR by Month 12
- **Retention Rate:** Maintain 70%+ monthly retention (UPSC prep cycle is 12-18 months)
- **CAC Payback:** Achieve CAC payback in < 3 months (target CAC ?1,500 via organic + paid ads)
- **Viral Coefficient:** 0.3+ (every user brings 0.3 new users via referrals and social sharing of AI-generated shorts)

### User Success Metrics

- **Engagement:** Daily Active Users (DAU) / Monthly Active Users (MAU) > 0.4 (indicating daily usage habit)
- **Content Consumption:** Average 30+ minutes per session, 5+ days per week
- **Feature Adoption:**
  - 80% users watch daily current affairs video
  - 60% users ask 5+ doubts per week (doubt-to-video converter)
  - 40% users complete weekly answer writing practice
- **Learning Outcomes:**
  - 70% users complete 50%+ syllabus within 6 months
  - 25% users clear UPSC Prelims (vs 2% national average)
- **NPS Score:** 50+ (indicating strong word-of-mouth potential)

### Key Performance Indicators (KPIs)

- **Trial-to-Paid Conversion:** 15% conversion from 1-day free trial to paid monthly subscription
- **Churn Rate:** < 10% monthly churn (most churn occurs after exam results in August)
- **Average Revenue Per User (ARPU):** ?800/month (accounting for quarterly/annual plans)
- **Video Generation Latency:** < 60 seconds for 60-second doubt videos; < 5 minutes for 5-minute current affairs video
- **Video Render Success Rate:** > 95% (< 5% jobs fail and require retry)
- **Knowledge Base Coverage:** 100% of standard UPSC syllabus topics mapped to knowledge chunks
- **Daily Current Affairs Freshness:** Published by 6 AM IST every day without fail
- **Interview Mock Completion Rate:** 50% of Pro users complete 5+ mock interviews before exam

---

## MVP Scope

### Core Features (Must Have)

- **Feature 1: Interactive 3D Syllabus Navigator**
  - **Description:** 3D tree visualization of complete UPSC syllabus (GS1-4, CSAT, Essay) with clickable nodes, progress rings, and heat map showing time spent per topic
  - **Rationale:** Solves the "where do I start?" problem; gives users visual confidence that syllabus is manageable
  - **MVP Scope:** Basic 2D tree view (defer 3D to post-MVP), manual progress marking, deep-links to notes/videos

- **Feature 2: Daily Current Affairs Video Newspaper**
  - **Description:** Auto-generated 5-8 minute video summarizing top UPSC-relevant news (Economy, Polity, IR, Environment) with Manim-animated maps/timelines, released by 6 AM daily
  - **Rationale:** Core differentiator; highest user demand feature per market research
  - **MVP Scope:** 5-minute video only (defer 30-60s shorts to post-MVP), PDF summary, 5 MCQs, manual fallback if auto-generation fails

- **Feature 3: Real-Time Doubt to Video Converter**
  - **Description:** User types/uploads screenshot of doubt ? AI generates 60-180 second explainer video with Manim diagrams within 2 minutes
  - **Rationale:** Unique value prop vs competitors; addresses working professionals' need for quick doubt resolution
  - **MVP Scope:** Text input only (defer image OCR to post-MVP), concise style only, 60-second videos, limit 10 doubts/day for free tier

- **Feature 10: Static & Animated Notes Generator**
  - **Description:** Generate multi-level notes (summary 150 words, detailed 600 words, comprehensive 2000 words) with Manim diagrams and 60-second video summary
  - **Rationale:** Replaces need for buying separate note-making courses
  - **MVP Scope:** Summary + detailed levels only (defer comprehensive to post-MVP), 5 diagrams max per topic, PDF export only

- **Feature 18: RAG-Powered UPSC Search Engine**
  - **Description:** Semantic search across ingested UPSC books (Laxmikanth, NCERT, Spectrum, etc.) with source citations (book name, page number)
  - **Rationale:** Foundational infrastructure for all other features; critical for answer accuracy
  - **MVP Scope:** Top 10 results, basic filters (subject, paper), AI-generated snippet answer

- **Feature 12: AI Study Schedule Builder**
  - **Description:** Personalized daily schedule based on exam date, available study hours, and weak topics
  - **Rationale:** Solves "overwhelmed by syllabus" problem; drives daily engagement
  - **MVP Scope:** Basic schedule generation, no adaptive adjustments (defer to post-MVP), manual topic priority setting

- **Feature 28: Monetization System**
  - **Description:** 1-day free trial with full access ? paywall for premium features ? subscription plans (monthly ?599, quarterly ?1199, half-yearly ?2399, annual ?4799)
  - **Rationale:** Revenue requirement
  - **MVP Scope:** RevenueCat integration, 4 pricing plans, coupon codes, basic admin dashboard for revenue tracking

- **Feature 22: Syllabus Tracking Dashboard**
  - **Description:** Progress dashboard showing topic completion %, strength/weakness heat map, time spent per subject
  - **Rationale:** Gamification + accountability; increases retention
  - **MVP Scope:** Basic completion tracking, weekly summary email (defer real-time push notifications to post-MVP)

### Out of Scope for MVP

- Feature 4: 3-Hour Documentary Lectures (very high complexity; defer to Month 3)
- Feature 5: 360° Immersive Visualizations (very high complexity; defer to Month 6)
- Feature 6: 60-Second Shorts (defer to Month 2 for marketing)
- Feature 7: Memory Palace (niche feature; wait for user demand signal)
- Feature 8 & 17: Ethics Roleplay Simulator (high complexity; defer to Month 4)
- Feature 9: Animated Math Solver (defer until CSAT user base grows)
- Feature 13: PYQ Video Explanation (requires large PYQ database; defer to Month 3)
- Feature 14: 3D Interactive Map Atlas (very high complexity; defer to Month 6)
- Feature 15 & 16: Essay/Answer Writing AI Trainer (defer to Month 3 after NLP fine-tuning)
- Feature 34: Live Interview Prep Studio (flagship feature but very high complexity; defer to Month 4)
- Feature 35: Auto Social Media Publisher (admin feature; defer to Month 2)
- Mobile apps (iOS/Android native) - MVP is mobile-responsive web app only
- Offline video download - streaming only in MVP
- Peer study rooms / collaborative features
- Mentor marketplace

### MVP Success Criteria

**MVP is considered successful if, within 90 days of launch:**

1. **Acquisition:** 5,000+ trial signups (via YouTube shorts, Instagram, Telegram UPSC groups)
2. **Activation:** 60%+ of trial users watch at least 1 daily current affairs video
3. **Conversion:** 10%+ trial-to-paid conversion (500 paying subscribers)
4. **Retention:** 65%+ monthly retention for paid users
5. **Technical:** 95%+ video render success rate, < 2 minute average doubt video generation time
6. **Revenue:** ?3 lakhs MRR (500 users × ?599 average)
7. **Feedback:** NPS score > 40, < 10% support tickets related to video quality issues

**Key Validation Signals:**
- Users are sharing AI-generated videos on WhatsApp groups (organic viral loops)
- Users are requesting post-MVP features (indicates product-market fit)
- Users are upgrading from monthly to annual plans (indicates long-term commitment)
- Competitors are attempting to copy our features (indicates differentiation)

---

## Post-MVP Vision

### Phase 2 Features (Months 4-6)

1. **Feature 6: 60-Second Topic Shorts** - Enable users to generate and share shorts on social media, driving organic growth
2. **Feature 13: PYQ Video Explanation Engine** - Upload any PYQ paper, get video solutions for all questions
3. **Feature 15 & 16: AI Essay/Answer Writing Trainer** - Upload essay/answer ? get AI scoring + video feedback with improvement suggestions
4. **Feature 34: Live Interview Prep Studio** - Real-time AI mock interviews with Manim visual aids and instant video debrief
5. **Mobile Apps (iOS/Android)** - Native apps with offline video download and push notifications
6. **Collaborative Study Rooms** - Live video sessions where users study together and share doubts

### Long-Term Vision (1-2 Years)

**Product Evolution:**
- Expand to **State PSC exams** (MPPSC, UPPSC, BPSC, TSPSC) - 15 lakh+ annual aspirants
- Add **Banking & SSC** preparation modules - 50 lakh+ annual aspirants
- Launch **Mentor Marketplace** where human UPSC toppers offer 1-on-1 coaching at ?500-1000/hour
- Build **B2B White-Label Platform** for coaching institutes to add AI features to their offerings

**Technology Advancements:**
- Train custom LLM fine-tuned on UPSC Mains answer books (2010-2024)
- Upgrade to GPT-4 Turbo / Claude Opus for higher quality explanations
- Implement real-time collaborative video annotations during study sessions
- Launch VR-compatible 360° history/geography experiences

**Geographic Expansion:**
- Expand to regional languages (Hindi, Telugu, Tamil, Marathi) for state PSC exams
- Partner with state governments for subsidized access to rural students
- International expansion: Civil service exams in Bangladesh, Sri Lanka, Nepal

**Revenue Diversification:**
- **Institutional Sales:** Sell bulk licenses to universities and coaching institutes at ?500/seat/year
- **Advertising:** Sponsor slots in daily current affairs videos (UPSC-relevant brands like newspapers, exam apps)
- **Content Licensing:** License our AI-generated videos to other EdTech platforms

### Expansion Opportunities

1. **Adjacent Verticals:**
   - **GATE/ESE Engineering** - Apply same video generation tech to technical subjects
   - **NEET/JEE Medical** - Biology animations via Manim
   - **Corporate Training** - Compliance, soft skills via AI video generation

2. **Strategic Partnerships:**
   - **The Hindu Newspaper** - Integrate their editorial analysis directly into daily current affairs video
   - **Drishti IAS / Vision IAS** - White-label our AI features for their students
   - **Coursera / Udemy** - Distribute courses on global platforms

3. **International Markets:**
   - **UK Civil Service Exam** - Adapt platform for UK syllabus
   - **ASEAN Civil Services** - Localize for Singapore, Malaysia, Indonesia
   - **African Civil Services** - Partner with governments for capacity building

4. **Technology Licensing:**
   - License our **Manim + Revideo video generation pipeline** to other EdTech companies
   - Offer **RAG-as-a-Service** for education companies wanting to build knowledge bases

---

## Technical Considerations

### Platform Requirements

- **Target Platforms:** Progressive Web App (PWA) for mobile-first experience; desktop web app for admin panel
- **Browser/OS Support:**
  - Mobile: Chrome 90+, Safari 14+ (iOS 14+)
  - Desktop: Chrome, Firefox, Edge (last 2 versions)
  - No IE11 support
- **Performance Requirements:**
  - First Contentful Paint (FCP): < 1.5 seconds
  - Largest Contentful Paint (LCP): < 2.5 seconds
  - Video playback start: < 1 second on 4G connection
  - Search results: < 500ms latency
  - Video render queue: Process 100 jobs concurrently

### Technology Preferences

**Frontend:**
- **Framework:** Next.js 14+ (App Router) with React Server Components
- **Styling:** Tailwind CSS + shadcn/ui components
- **State Management:** React Query (server state) + Zustand (client state)
- **3D Graphics:** React Three Fiber (@react-three/fiber) for syllabus navigator
- **Video Player:** Custom player with HLS.js for adaptive streaming
- **Forms:** React Hook Form + Zod validation
- **Animations:** Framer Motion

**Backend:**
- **Framework:** Supabase Edge Functions (Deno runtime, TypeScript)
- **Architecture:** Pipes/Filters/Actions pattern (see Section 7 of spec)
- **Auth:** Supabase Auth (JWT-based, Google/Email/Phone OAuth)
- **Database:** PostgreSQL 15+ with pgvector extension for RAG
- **Storage:** Supabase Storage (videos, PDFs, thumbnails)
- **Realtime:** Supabase Realtime for live progress updates
- **Caching:** Redis (optional for MVP, required for scale)

**Database:**
- **Primary:** Supabase PostgreSQL with pgvector
- **Vector Search:** pgvector with ivfflat index (1536-dimensional embeddings)
- **Full-Text Search:** PostgreSQL GIN indexes on tsvector columns
- **Schema:** 20+ tables (users, subscriptions, knowledge_chunks, video_renders, jobs, etc.)

**Hosting/Infrastructure:**
- **Supabase:** Hosted Supabase Cloud or self-hosted (Supabase API: https://interior-adapted-wishing-families.trycloudflare.com)
- **VPS (89.117.60.144):** Self-hosted services:
  - Document Retriever (RAG): http://89.117.60.144:8101/retrieve
  - DuckDuckGo Search: http://89.117.60.144:8102/search
  - Video Orchestrator: http://89.117.60.144:8103/render
  - Manim + Revideo Renderer: http://89.117.60.144:5555/render
  - Notes Generator: http://89.117.60.144:8104/generate_notes
- **CDN:** Cloudflare for video delivery (reduce latency, DDoS protection)
- **Monitoring:** Sentry (error tracking) + Vercel Analytics (web vitals)

### Architecture Considerations

**Repository Structure:**
```
upsc-prepx-ai/
├── apps/
│   ├── web/              # Next.js frontend
│   └── admin/            # Admin dashboard
├── packages/
│   ├── supabase/         # Edge Functions, migrations, types
│   ├── ui/               # Shared React components
│   └── config/           # Shared configs (Tailwind, TS)
├── services/
│   ├── video-renderer/   # Manim + Revideo render service
│   ├── rag-engine/       # Document retriever
│   └── notes-generator/  # Notes synthesis service
└── docs/
    ├── prd.md
    └── architecture.md
```

**Service Architecture:**
- **Monorepo:** Turborepo for managing frontend + backend
- **Edge Functions:** Deployed to Supabase Edge (serverless Deno)
- **Video Rendering:** Self-hosted VPS (89.117.60.144) due to compute intensity
- **Job Queue:** PostgreSQL-based queue (jobs table) with cron workers for async processing

**Integration Requirements:**
- **RevenueCat:** Subscription management and payment processing (webhook: POST /api/webhooks/revenuecat)
- **Google OAuth:** User authentication
- **YouTube/Instagram/Facebook/Twitter APIs:** Auto-publish shorts (Feature 35)
- **DuckDuckGo Search API:** UPSC-filtered news retrieval
- **OpenAI / Anthropic / Google Gemini:** LLM providers for text generation
- **TTS Provider:** ElevenLabs or Google Cloud TTS for narration

**Security/Compliance:**
- **Authentication:** JWT-based with Supabase Auth; no localStorage for tokens (use httpOnly cookies)
- **Authorization:** Row-level security (RLS) policies in Supabase for all tables
- **Data Privacy:** GDPR-compliant; users can delete accounts and all data
- **Payment Security:** RevenueCat handles PCI compliance; no credit card data stored in our DB
- **Content Moderation:** Content safety filter for user-submitted doubts (block NSFW/harmful content)
- **Rate Limiting:** 100 requests/minute per user on Edge Functions to prevent abuse
- **Audit Logging:** All admin actions logged in audit_logs table

---

## Constraints & Assumptions

### Constraints

**Budget:**
- **Development:** ?15 lakhs (6 months runway for 2 full-stack engineers + 1 PM)
- **Infrastructure:** ?50,000/month (Supabase + VPS + CDN + LLM API costs)
- **Marketing:** ?5 lakhs (first 3 months, primarily YouTube/Instagram ads and influencer partnerships)
- **Total Pre-Revenue Spend:** ?25 lakhs (break-even at 4,000 paid subscribers)

**Timeline:**
- **MVP Development:** 8 weeks (2 months)
- **Alpha Testing:** 2 weeks (50 users, closed beta)
- **Beta Launch:** 4 weeks (1,000 users, public beta with waitlist)
- **Public Launch:** Week 14 (start paid marketing)

**Resources:**
- **Team:** 2 full-stack engineers (React + TypeScript + Supabase), 1 PM/Designer, 1 UPSC subject matter expert (part-time content reviewer)
- **Hardware:** 1 dedicated VPS (16 vCPU, 64GB RAM) for video rendering
- **AI Credits:** ?1.5 lakhs/month OpenAI API budget (estimated for 5,000 users generating 50,000 videos/month)

**Technical:**
- **Video Rendering Capacity:** Max 1,000 concurrent renders on current VPS; scale horizontally to 5 VPS servers if demand exceeds
- **Knowledge Base Size:** 50 GB total for all PDF ingestion (200+ standard books)
- **Latency:** VPS is in India (low latency for domestic users), but no global CDN initially (defer international expansion)
- **Vendor Lock-In:** Supabase is partially open-source (self-hostable if needed), but migration would take 2-3 months

### Key Assumptions

- UPSC syllabus will remain 80% stable for next 2 years (historical trend)
- OpenAI / Anthropic API pricing will not increase > 20% in next 12 months
- Manim render time will average 30 seconds per 60-second video (validated in PoC)
- Users will accept 1-2 minute delay for doubt video generation (async workflow)
- 15% trial-to-paid conversion is achievable based on competitor benchmarks (Unacademy reports 12-18%)
- Daily current affairs video can be fully automated with 95% accuracy (5% manual review)
- Users will trust AI-generated content if citations to standard books are provided
- YouTube/Instagram algorithm will favor UPSC-related shorts (education is promoted content category)
- RevenueCat webhook reliability is 99%+ (critical for entitlement checks)
- Aspirants will pay ?599/month if value is 10x better than free YouTube content

---

## Risks & Open Questions

### Key Risks

- **Risk: Video Render Failures**
  - **Description:** Manim/Revideo rendering fails due to malformed scene specs or OOM errors
  - **Impact:** Users don't get videos, leading to churn and negative reviews
  - **Mitigation:** Implement retry logic (3 attempts), fallback to text-only explanations, queue prioritization for premium users, pre-render common topics

- **Risk: LLM Hallucinations / Factual Errors**
  - **Description:** AI generates incorrect UPSC content (wrong dates, facts, concepts)
  - **Impact:** Users fail exams due to wrong information, reputational damage, legal liability
  - **Mitigation:** RAG architecture ensures grounding in standard books, confidence scores for answers, human review for high-stakes content (current affairs), user feedback flagging system, disclaimer ("AI-generated, verify with standard books")

- **Risk: Cost Overruns (LLM API Costs)**
  - **Description:** OpenAI API costs spiral beyond ?1.5L/month budget as user base grows
  - **Impact:** Negative unit economics, force pricing increase
  - **Mitigation:** Implement aggressive caching (70% cache hit rate target), use cheaper models (GPT-3.5 Turbo for simple queries, GPT-4 only for complex), explore local LLM deployment (Llama 3 on GPU), pass costs to users via freemium limits

- **Risk: Copyright Issues with PDF Ingestion**
  - **Description:** Publishers of NCERT, Laxmikanth, Spectrum sue for unauthorized use
  - **Impact:** Forced to remove knowledge base, legal fees
  - **Mitigation:** Fair use defense (education, transformative use), purchase institutional licenses where possible, use public domain books (pre-1923), get legal opinion before launch

- **Risk: Low Trial-to-Paid Conversion**
  - **Description:** 1-day trial insufficient to demonstrate value; users churn after trial
  - **Impact:** Miss revenue targets
  - **Mitigation:** Extend trial to 7 days if conversion < 10%, onboarding flow that showcases all features on Day 1, email drip campaign during trial, exit survey for churned users

- **Risk: Dependency on Single VPS Provider**
  - **Description:** VPS goes down, all video rendering stops
  - **Impact:** Loss of revenue, user churn
  - **Mitigation:** Set up failover VPS in different data center, implement queue-based architecture so renders resume after downtime, SLA monitoring and alerting

### Open Questions

- Should we allow users to edit AI-generated notes/videos, or keep them read-only?
- Should we support regional languages (Hindi) in MVP, or defer to Phase 2?
- Should free tier users get any video features (e.g., 1 doubt video/day), or paywall everything except articles?
- Should we build our own TTS system, or use ElevenLabs (more expensive but better quality)?
- Should we display "AI-generated content" watermarks on all videos for transparency?
- Should we allow users to download videos for offline viewing, or streaming-only to prevent piracy?
- Should we implement social features (peer study rooms, forums), or focus purely on individual learning?
- Should we charge extra for interview prep (Feature 34), or include in Pro subscription?

### Areas Needing Further Research

- **User Research:** Conduct 20 user interviews with UPSC aspirants to validate feature prioritization
- **Market Research:** Analyze competitor pricing (Unacademy, BYJU'S) and feature comparison
- **Technical Feasibility:** Stress test Manim renderer to determine max concurrent capacity on single VPS
- **Legal Research:** Consult IP lawyer on fair use of UPSC books and copyright implications
- **Content Research:** Identify top 200 most-asked UPSC topics for pre-rendering videos (reduce on-demand latency)
- **SEO Research:** Keyword analysis for organic traffic (e.g., "UPSC daily current affairs 2025")
- **Partnership Research:** Reach out to UPSC coaching institutes for potential white-label deals

---

## Appendices

### A. Research Summary

**Market Research Findings:**
- UPSC coaching market size: ?5,000 crore (KPMG Education Report 2023)
- Online penetration: 35% in 2024, projected to reach 60% by 2027
- Average coaching fee: ?1.8 lakhs/year (offline), ?30,000/year (online)
- Key competitors: Unacademy (largest, 40% market share), BYJU'S Exam Prep, Drishti IAS, Vision IAS
- User willingness to pay: 70% of survey respondents willing to pay ?500-1000/month for AI-powered features

**Competitive Analysis:**

| Platform | Pricing | AI Features | Video Generation | RAG Search | Personalization |
|----------|---------|-------------|-----------------|-----------|-----------------|
| **Unacademy** | ?10,000-50,000/year | None | Pre-recorded only | No | Quiz-based |
| **BYJU'S** | ?15,000-40,000/year | None | Pre-recorded + some animated | No | Basic |
| **Vision IAS** | ?2 lakhs/year | None | Pre-recorded lectures | No | None |
| **UPSC PrepX-AI** | ?599-4799/year | **On-demand videos** | **Manim + Revideo** | **Yes** | **AI-driven** |

**User Interview Insights (10 interviews):**
- 9/10 users said "daily current affairs video" is most valuable feature
- 7/10 users frustrated with slow doubt resolution (24-48 hour lag in forums)
- 8/10 users willing to pay ?599/month if quality matches paid coaching
- 5/10 users concerned about AI accuracy ("will it make mistakes?")
- 6/10 users prefer video explanations over text notes

### B. Stakeholder Input

**UPSC Topper Feedback (Rank 25, 2023):**
- "If this existed when I was preparing, I would have saved ?2 lakhs and 6 months. The current affairs video feature alone would have cut my daily news reading from 3 hours to 30 minutes."

**Coaching Institute Director:**
- "AI-powered doubt resolution is the future. We spend 40% of teaching time answering repetitive doubts. If AI can handle that, teachers can focus on high-value mentorship."

**Investor Feedback (Angel Investor in EdTech):**
- "Strong unit economics. CAC of ?1,500 with LTV of ?6,000 (10-month retention) is impressive. Biggest risk is content quality - one viral incident of wrong information could kill the brand."

### C. References

- UPSC Official Syllabus: https://www.upsc.gov.in/examinations/syllabus
- KPMG India Education Report 2023: https://assets.kpmg.com/content/dam/kpmg/in/pdf/2023/08/online-education-in-india-2023.pdf
- Competitor Analysis: Unacademy (https://unacademy.com), BYJU'S (https://byjusexamprep.com)
- Manim Documentation: https://docs.manim.community/
- Revideo Documentation: https://www.remotion.dev/docs/
- Supabase Documentation: https://supabase.com/docs
- RevenueCat Documentation: https://www.revenuecat.com/docs/
- UPSC Content Sources: Vision IAS (https://visionias.in/), Drishti IAS (https://drishtiias.com/), The Hindu (https://thehindu.com/), PIB (https://pib.gov.in/)

---

## Next Steps

### Immediate Actions

1. **Week 1-2: Project Setup & Architecture**
   - Set up Turborepo monorepo with Next.js + Supabase
   - Deploy Supabase instance (self-hosted on Cloudflare Tunnel)
   - Set up VPS (89.117.60.144) with Manim + Revideo render services
   - Create database schema (run migrations from spec)
   - Set up CI/CD pipeline (GitHub Actions → Vercel for frontend, Supabase CLI for backend)

2. **Week 3-4: Core Infrastructure**
   - Implement Pipes/Filters/Actions pattern for Edge Functions
   - Build RAG engine (ingest 5 sample PDFs: Laxmikanth Ch1, NCERT History Ch1)
   - Integrate OpenAI API for embeddings + text generation
   - Build video rendering queue (Manim PoC: render timeline animation, Revideo PoC: assemble 30s video)

3. **Week 5-6: MVP Features**
   - Feature 2: Daily Current Affairs Video (build automated pipeline)
   - Feature 3: Doubt to Video Converter (text input → video output)
   - Feature 18: RAG Search (semantic search + citation display)
   - Feature 10: Notes Generator (summary + detailed levels)

4. **Week 7-8: User Experience & Monetization**
   - Feature 1: Syllabus Navigator (2D tree view, progress tracking)
   - Feature 12: Study Schedule Builder (basic schedule generation)
   - Feature 22: Progress Dashboard (completion %, weekly summary)
   - Feature 28: RevenueCat integration, paywall implementation, trial logic

5. **Week 9-10: Alpha Testing**
   - Recruit 50 alpha testers (UPSC aspirants from Telegram groups)
   - Fix critical bugs, optimize video render latency
   - Collect qualitative feedback on feature prioritization
   - Iterate on UI/UX based on user session recordings (Hotjar)

6. **Week 11-12: Beta Launch Prep**
   - Build landing page + waitlist form
   - Create 10 demo videos (YouTube shorts) showcasing features
   - Set up analytics (Mixpanel for funnel tracking, Sentry for errors)
   - Legal review (terms of service, privacy policy, refund policy)
   - Security audit (OWASP Top 10 checks)

7. **Week 13-14: Public Beta Launch**
   - Launch to 1,000 beta users (waitlist + paid Instagram ads)
   - Monitor technical metrics (video render success rate, API latency)
   - A/B test pricing (is ?599 optimal, or should we try ?499?)
   - Collect NPS scores, iterate based on feedback

8. **Week 15+: Scale & Iterate**
   - Achieve 10,000 trial signups
   - Hit 1,500 paid subscribers (break-even)
   - Plan Phase 2 feature rollout (60-second shorts, PYQ videos, essay trainer)

### PM Handoff

This Project Brief provides the full context for **UPSC PrepX-AI**. Please start in **PRD Generation Mode**, review the brief thoroughly to work with the user to create the PRD section by section as the template indicates, asking for any necessary clarification or suggesting improvements.

**Key Focus Areas for PRD:**
1. **Feature 2 (Daily Current Affairs)** and **Feature 3 (Doubt Converter)** are core MVP features - prioritize detailed functional specs
2. **Subscription Logic** (1-day trial → paywall) is critical - ensure clear state machine diagrams
3. **Video Rendering Architecture** (Manim + Revideo) is complex - include sequence diagrams for job queue
4. **RAG System** (PDF ingestion → semantic chunking → vector search) needs detailed data flow
5. **Admin Panel** requirements for managing knowledge base, users, and video jobs

**Technical Artifacts Needed for Development:**
- Complete database schema SQL (already in spec, validate completeness)
- Edge Function templates (Pipes/Filters/Actions) with error handling patterns
- Manim scene spec JSON schema examples
- Revideo composition structure and props interfaces
- RevenueCat webhook event handling logic

Let's build the PRD section by section, starting with the Executive Summary and moving through Epics and Stories systematically. Are you ready to begin?
