# COMPLETE ENTERPRISE BUILD SPECIFICATION v4.0

## FOR IDE AI APP BUILDERS: SINGLE MASTER PROMPT

---

```
================================================================================
UPSC PrepX-AI - ENTERPRISE APPLICATION BUILD SPECIFICATION
================================================================================

PROJECT IDENTITY
----------------
App Name: UPSC PrepX-AI
Tagline: "AI-Powered UPSC Preparation Platform"
Description: Enterprise-grade exam preparation platform with AI-generated video
content, comprehensive study notes, adaptive learning, and real-time current
affairs integration.

================================================================================
SECTION 1: INFRASTRUCTURE & SERVICES
================================================================================

1.1 PRIMARY BACKEND: SUPABASE
-----------------------------
Instance URL: https://supabase.aimasteryedu.in
Database: PostgreSQL 15+ with pgvector extension
Auth: Supabase Auth (JWT-based, supports Google/Email/Phone)
Storage: Supabase Storage (videos, PDFs, thumbnails, assets)
Edge Functions: Deno runtime (TypeScript)
Realtime: Supabase Realtime for live updates

1.2 SELF-HOSTED VPS SERVICES (89.117.60.144)
--------------------------------------------
All video rendering and AI processing runs on self-hosted VPS.

Service 1: Document Retriever (RAG Engine)
  URL: http://89.117.60.144:8101/retrieve
  Method: GET
  Query Params: ?query=string&top_k=number&filters=json
  Purpose: Vector search across ingested PDF knowledge base
  Response Format:
  {
    "results": [
      {
        "content": "text chunk from knowledge base",
        "score": 0.95,
        "metadata": {
          "source_file": "Laxmikanth_Polity.pdf",
          "page": 45,
          "topic": "fundamental-rights",
          "chapter": "Part III"
        }
      }
    ]
  }

Service 2: DuckDuckGo General Search
  URL: http://89.117.60.144:8102/search
  Method: POST
  Headers: { "Content-Type": "application/json" }
  Body: { "query": "string", "max_results": 10 }
  Response Format:
  {
    "results": [
      { "title": "...", "snippet": "...", "url": "..." }
    ]
  }

Service 3: DuckDuckGo UPSC-Filtered Search
  URL: http://89.117.60.144:8102/search/upsc
  Method: POST
  Headers: { "Content-Type": "application/json" }
  Body: {
    "query": "current affairs topic",
    "allowed_domains": ["visionias.in", "drishtiias.com", "thehindu.com", 
                        "pib.gov.in", "forumias.com", "iasgyan.in", 
                        "pmfias.com", "pwonlyias.com", "byjus.com"],
    "date_range": "last_7_days"
  }
  Response Format:
  {
    "results": [
      {
        "title": "Article Title",
        "url": "https://...",
        "snippet": "...",
        "published_date": "2024-12-01",
        "domain": "visionias.in"
      }
    ]
  }

Service 4: Video Orchestrator (Multi-Scene Assembly)
  URL: http://89.117.60.144:8103/render
  Method: POST
  Headers: { "Content-Type": "application/json" }
  Purpose: Coordinate multi-scene video rendering and assembly
  Body: {
    "job_id": "uuid",
    "scenes": [
      {
        "type": "manim",
        "scene_spec": { "scene_class": "...", "args": {...} },
        "duration": 10
      },
      {
        "type": "remotion",
        "composition": "TitleCard",
        "props": { "title": "...", "subtitle": "..." }
      }
    ],
    "output_format": "mp4",
    "resolution": "1920x1080",
    "fps": 30,
    "audio_tracks": [
      { "path": "voiceover.mp3", "volume": 1.0 },
      { "path": "background.mp3", "volume": 0.2 }
    ]
  }
  Response Format:
  {
    "status": "queued",
    "job_id": "uuid",
    "estimated_time": 120,
    "webhook_url": "https://supabase.../webhooks/render-complete"
  }

Service 5: Manim + Remotion Renderer (Individual Scenes)
  URL: http://89.117.60.144:5555/render
  Method: POST
  Headers: { "Content-Type": "application/json" }
  Purpose: Render individual Manim animations or Remotion compositions
  Body (for Manim):
  {
    "renderer": "manim",
    "scene_config": {
      "scene_class": "TimelineScene",
      "scene_args": {
        "events": [...],
        "style": "dark",
        "animation_speed": "normal"
      }
    },
    "output_format": "mp4",
    "quality": "high",
    "transparent_background": false
  }
  Body (for Remotion):
  {
    "renderer": "remotion",
    "composition_id": "ExplainerCard",
    "input_props": {
      "title": "Fundamental Rights",
      "bullet_points": ["Point 1", "Point 2"],
      "voiceover_url": "https://..."
    },
    "codec": "h264",
    "duration_frames": 900
  }
  Response Format:
  {
    "status": "rendering",
    "job_id": "uuid",
    "estimated_time": 45,
    "preview_url": "http://...preview.jpg"
  }

Service 6: Notes Generator (RAG + LLM Synthesis)
  URL: http://89.117.60.144:8104/generate_notes
  Method: POST
  Headers: { "Content-Type": "application/json" }
  Purpose: Generate structured notes from knowledge base + web sources
  Body: {
    "topic": "article-21-right-to-life",
    "syllabus_node_id": "uuid",
    "sources": {
      "knowledge_base": true,
      "web_allowed": ["visionias.in", "drishtiias.com"],
      "web_query": "Article 21 recent Supreme Court judgments"
    },
    "output_format": "structured_json",
    "note_levels": {
      "summary": true,
      "detailed": true,
      "comprehensive": true
    },
    "include_diagrams": true,
    "include_mcqs": 5,
    "include_mains_questions": 3
  }
  Response Format:
  {
    "job_id": "uuid",
    "notes": {
      "summary": "150 word summary...",
      "detailed": "600 word markdown...",
      "comprehensive": "2000+ word markdown..."
    },
    "diagrams": [
      { "type": "flowchart", "manim_spec": {...}, "status": "queued" }
    ],
    "mcqs": [...],
    "mains_questions": [...],
    "sources_cited": [...]
  }

1.3 THIRD-PARTY API INTEGRATIONS
--------------------------------
RevenueCat (Subscription Management):
  ENV: REVENUECAT_SECRET_API_KEY
  Purpose: Handle all subscription purchases and entitlements

Google Services:
  ENV: GOOGLE_API_KEY
  ENV: GOOGLE_OAUTH_CLIENT_ID
  Purpose: Google Sign-In, YouTube Data API

Meta (Facebook/Instagram):
  ENV: META_ADS_TOKEN
  Purpose: Auto-publish shorts to Instagram/Facebook

YouTube:
  ENV: YOUTUBE_API_KEY
  Purpose: Auto-publish shorts to YouTube

Twitter/X:
  ENV: TWITTER_API_KEY
  Purpose: Auto-publish content to Twitter

1.4 WHITELISTED UPSC SOURCES (For Daily Updates)
------------------------------------------------
These are the ONLY domains allowed for web content retrieval:
- visionias.in (Primary - Value Added Notes)
- drishtiias.com (Current Affairs, Monthly Compilations)
- thehindu.com (Editorial Analysis)
- pib.gov.in (Government Press Releases)
- forumias.com (Answer Writing, Current Affairs)
- iasgyan.in (Subject Notes)
- pmfias.com (Geography, Environment)
- pwonlyias.com (Test Series, Notes)
- byjus.com (NCERT-based content)
- insightsonindia.com (Daily Compilations)
- *.gov.in (All government websites)

================================================================================
SECTION 2: KNOWLEDGE DATABASE CREATION (CRITICAL - BUILD PHASE)
================================================================================

2.1 OVERVIEW
------------
During app installation/build, the system MUST create a comprehensive knowledge
base from admin-uploaded PDF files. This is the CANONICAL source for all notes.
Daily updates come ONLY from whitelisted web sources.

2.2 PDF INGESTION PIPELINE
--------------------------

Step 1: Admin Upload Interface
------------------------------
Admin uploads standard UPSC reference books via dashboard:
POST /api/admin/knowledge/upload
Content-Type: multipart/form-data

Expected PDF uploads include:
- Indian Polity by M. Laxmikanth
- NCERT Books (Class 6-12: History, Geography, Science, Economics)
- Spectrum Modern India
- Ramesh Singh Indian Economy
- Shankar IAS Environment
- Certificate Physical Geography by Goh Cheng Leong
- World History by Norman Lowe
- Ethics books (Lexicon, etc.)

Metadata per file:
{
  "subject": "Polity|History|Geography|Economy|Environment|Ethics|Essay|CSAT",
  "book_title": "Indian Polity by Laxmikanth",
  "author": "M. Laxmikanth",
  "edition": "7th Edition 2024",
  "priority": 100,
  "syllabus_mapping": ["GS2", "Prelims"]
}

Step 2: Processing Pipeline
---------------------------
For each uploaded PDF:
1. Extract text (with OCR fallback for scanned pages)
2. Semantic chunking (max 1000 tokens, 200 token overlap)
3. Map chunks to UPSC syllabus taxonomy
4. Generate embeddings (OpenAI text-embedding-3-small or local model)
5. Store in Supabase with vector index

Step 3: Syllabus Taxonomy
-------------------------
Complete UPSC syllabus must be pre-seeded:
- GS1: Indian Heritage, History, Geography
- GS2: Polity, Governance, International Relations
- GS3: Economy, Science & Tech, Environment, Disaster Management
- GS4: Ethics, Integrity, Aptitude
- CSAT: Comprehension, Math, Reasoning
- Essay: Various themes
- Optional Subjects (configurable)

2.3 DATABASE SCHEMA
-------------------

-- Core User Tables
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE,
  phone TEXT,
  full_name TEXT,
  avatar_url TEXT,
  role TEXT DEFAULT 'user' CHECK (role IN ('user', 'moderator', 'admin')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE user_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  target_exam TEXT DEFAULT 'UPSC CSE',
  target_year INT,
  optional_subject TEXT,
  preparation_stage TEXT CHECK (preparation_stage IN 
    ('beginner', 'intermediate', 'advanced', 'revision')),
  study_hours_per_day INT DEFAULT 6,
  strengths TEXT[],
  weaknesses TEXT[],
  onboarding_completed BOOLEAN DEFAULT FALSE,
  preferences JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Subscription & Entitlements
CREATE TABLE plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  price_inr INT NOT NULL,
  duration_days INT NOT NULL,
  features JSONB DEFAULT '[]',
  active BOOLEAN DEFAULT TRUE
);

-- Seed plans
INSERT INTO plans (name, slug, price_inr, duration_days) VALUES
  ('Monthly', 'monthly', 599, 30),
  ('Quarterly', 'quarterly', 1199, 90),
  ('Half-Yearly', 'half-yearly', 2399, 180),
  ('Annual', 'annual', 4799, 365);

CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  plan_id UUID REFERENCES plans(id),
  status TEXT DEFAULT 'trial' CHECK (status IN 
    ('trial', 'active', 'expired', 'cancelled', 'grace_period')),
  trial_started_at TIMESTAMPTZ DEFAULT NOW(),
  trial_expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '1 day',
  subscription_started_at TIMESTAMPTZ,
  subscription_expires_at TIMESTAMPTZ,
  revenuecat_customer_id TEXT,
  revenuecat_entitlement_id TEXT,
  payment_provider TEXT,
  auto_renew BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE entitlements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  feature_slug TEXT NOT NULL,
  granted_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  source TEXT CHECK (source IN ('trial', 'subscription', 'admin_grant', 'promo')),
  UNIQUE(user_id, feature_slug)
);

-- Knowledge Base Tables
CREATE TABLE syllabus_nodes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT UNIQUE NOT NULL,
  parent_id UUID REFERENCES syllabus_nodes(id),
  title TEXT NOT NULL,
  description TEXT,
  exam_type TEXT NOT NULL CHECK (exam_type IN ('Prelims', 'Mains', 'Both')),
  subject TEXT NOT NULL,
  paper TEXT,
  level INT DEFAULT 1,
  weightage INT,
  keywords TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE pdf_uploads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  filename TEXT NOT NULL,
  original_name TEXT NOT NULL,
  file_size_mb DECIMAL(10,2),
  subject TEXT NOT NULL,
  book_title TEXT,
  author TEXT,
  edition TEXT,
  priority INT DEFAULT 50,
  metadata JSONB DEFAULT '{}',
  upload_status TEXT DEFAULT 'pending' CHECK (upload_status IN 
    ('pending', 'processing', 'completed', 'failed')),
  chunks_created INT DEFAULT 0,
  processing_errors TEXT[],
  uploaded_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE knowledge_chunks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content TEXT NOT NULL,
  content_vector vector(1536) NOT NULL,
  source_file TEXT NOT NULL,
  source_page INT,
  subject TEXT NOT NULL,
  syllabus_nodes UUID[] NOT NULL,
  chunk_metadata JSONB DEFAULT '{}',
  quality_score DECIMAL(3,2) DEFAULT 1.0,
  key_terms TEXT[],
  active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_knowledge_chunks_vector 
ON knowledge_chunks 
USING ivfflat (content_vector vector_cosine_ops)
WITH (lists = 100);

CREATE INDEX idx_knowledge_chunks_fts 
ON knowledge_chunks 
USING gin(to_tsvector('english', content));

CREATE INDEX idx_knowledge_chunks_syllabus 
ON knowledge_chunks USING gin(syllabus_nodes);

-- Notes System Tables
CREATE TABLE comprehensive_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  topic_slug TEXT NOT NULL UNIQUE,
  syllabus_node_id UUID REFERENCES syllabus_nodes(id),
  title TEXT NOT NULL,
  summary TEXT,
  detailed_content TEXT,
  comprehensive_content TEXT,
  source_chunks UUID[] NOT NULL,
  diagrams JSONB DEFAULT '[]',
  mcqs JSONB DEFAULT '[]',
  mains_questions JSONB DEFAULT '[]',
  pyq_references TEXT[],
  last_updated TIMESTAMPTZ DEFAULT NOW(),
  next_update_due DATE,
  version INT DEFAULT 1,
  published BOOLEAN DEFAULT FALSE,
  created_by UUID REFERENCES users(id),
  approved_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE daily_updates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  comprehensive_note_id UUID REFERENCES comprehensive_notes(id) ON DELETE CASCADE,
  update_date DATE NOT NULL,
  title TEXT NOT NULL,
  summary TEXT NOT NULL,
  content TEXT,
  source_url TEXT NOT NULL,
  source_domain TEXT NOT NULL,
  relevance_score DECIMAL(3,2),
  approved BOOLEAN DEFAULT FALSE,
  approved_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(comprehensive_note_id, update_date, source_url)
);

CREATE TABLE monthly_compendia (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  month INT NOT NULL,
  year INT NOT NULL,
  title TEXT,
  pdf_url TEXT,
  file_size_mb DECIMAL(10,2),
  total_notes INT,
  total_updates INT,
  subjects_covered TEXT[],
  generated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(month, year)
);

-- Video & Render Tables
CREATE TABLE video_renders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  feature_slug TEXT NOT NULL,
  render_type TEXT NOT NULL,
  input_payload JSONB NOT NULL,
  scenes JSONB NOT NULL,
  total_duration_sec INT,
  resolution TEXT DEFAULT '1920x1080',
  video_url TEXT,
  thumbnail_url TEXT,
  captions_url TEXT,
  transcript TEXT,
  status TEXT DEFAULT 'queued' CHECK (status IN 
    ('queued', 'processing', 'rendering', 'completed', 'failed')),
  progress_percent INT DEFAULT 0,
  error_message TEXT,
  render_time_sec INT,
  retry_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

CREATE TABLE manim_scene_cache (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scene_hash TEXT UNIQUE NOT NULL,
  scene_config JSONB NOT NULL,
  video_url TEXT NOT NULL,
  duration_sec INT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  access_count INT DEFAULT 0,
  last_accessed TIMESTAMPTZ DEFAULT NOW()
);

-- Job Queue
CREATE TABLE jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_type TEXT NOT NULL,
  feature_slug TEXT,
  user_id UUID REFERENCES users(id),
  priority INT DEFAULT 50,
  payload JSONB NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN 
    ('pending', 'processing', 'completed', 'failed', 'cancelled')),
  result JSONB,
  error TEXT,
  attempts INT DEFAULT 0,
  max_attempts INT DEFAULT 3,
  next_attempt_at TIMESTAMPTZ DEFAULT NOW(),
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE job_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id UUID REFERENCES jobs(id) ON DELETE CASCADE,
  level TEXT CHECK (level IN ('info', 'warn', 'error')),
  message TEXT NOT NULL,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Feature Manifests
CREATE TABLE feature_manifests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  description TEXT,
  category TEXT,
  pipe_function TEXT NOT NULL,
  filter_functions TEXT[],
  action_functions TEXT[],
  uses_manim BOOLEAN DEFAULT FALSE,
  uses_remotion BOOLEAN DEFAULT FALSE,
  uses_video_render BOOLEAN DEFAULT FALSE,
  entitlement_required TEXT DEFAULT 'pro',
  allowed_sources TEXT[],
  config JSONB DEFAULT '{}',
  enabled BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- AI Provider Configuration
CREATE TABLE ai_providers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  provider_type TEXT CHECK (provider_type IN 
    ('openai', 'anthropic', 'google', 'azure', 'local', 'custom')),
  endpoint_url TEXT,
  env_key_name TEXT NOT NULL,
  models JSONB DEFAULT '[]',
  supported_features TEXT[],
  cost_per_1k_tokens DECIMAL(10,4),
  rate_limit_rpm INT,
  enabled BOOLEAN DEFAULT TRUE,
  priority INT DEFAULT 50,
  config JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User Progress & Analytics
CREATE TABLE user_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  syllabus_node_id UUID REFERENCES syllabus_nodes(id),
  completion_percent INT DEFAULT 0,
  confidence_score DECIMAL(3,2) DEFAULT 0,
  time_spent_minutes INT DEFAULT 0,
  notes_read INT DEFAULT 0,
  videos_watched INT DEFAULT 0,
  quizzes_attempted INT DEFAULT 0,
  quizzes_passed INT DEFAULT 0,
  last_activity_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, syllabus_node_id)
);

CREATE TABLE quiz_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  quiz_type TEXT CHECK (quiz_type IN ('mcq', 'mains', 'pyq', 'daily')),
  topic_slug TEXT,
  syllabus_node_id UUID REFERENCES syllabus_nodes(id),
  questions JSONB NOT NULL,
  answers JSONB NOT NULL,
  score DECIMAL(5,2),
  time_taken_sec INT,
  feedback JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ads & Social Publishing
CREATE TABLE ads_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ad_type TEXT CHECK (ad_type IN ('short', 'promo', 'feature_highlight')),
  title TEXT NOT NULL,
  script TEXT,
  visual_spec JSONB,
  platforms TEXT[] DEFAULT ARRAY['youtube', 'instagram', 'facebook', 'twitter'],
  scheduled_at TIMESTAMPTZ,
  status TEXT DEFAULT 'draft' CHECK (status IN 
    ('draft', 'rendering', 'ready', 'publishing', 'published', 'failed')),
  video_url TEXT,
  published_urls JSONB DEFAULT '{}',
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE ad_publish_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ads_queue_id UUID REFERENCES ads_queue(id) ON DELETE CASCADE,
  platform TEXT NOT NULL,
  status TEXT CHECK (status IN ('pending', 'success', 'failed')),
  platform_post_id TEXT,
  error_message TEXT,
  response_data JSONB,
  published_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Bookmarks & Study Materials
CREATE TABLE bookmarks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  item_type TEXT CHECK (item_type IN 
    ('note', 'video', 'question', 'topic', 'pyq')),
  item_id UUID NOT NULL,
  item_title TEXT NOT NULL,
  tags TEXT[],
  notes TEXT,
  revision_due DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Audit Logs
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  action TEXT NOT NULL,
  resource_type TEXT,
  resource_id UUID,
  old_values JSONB,
  new_values JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

================================================================================
SECTION 3: ALL 35 FEATURES (DETAILED SPECIFICATIONS)
================================================================================

NOTE FOR IDE BUILDER: Each feature below has a specific purpose, inputs, outputs,
and technical requirements. The public-facing UI should use user-friendly names
(shown in display_name) and HIDE technical implementation details like "Manim"
or "Remotion". Replace with terms like "AI Animation Engine" or "Smart Video
Creator" in user-visible text.

--------------------------------------------------------------------------------
FEATURE 1: Interactive 3D Syllabus Navigator
--------------------------------------------------------------------------------
{
  "feature_id": 1,
  "slug": "interactive-3d-syllabus-navigator",
  "display_name": "Smart Syllabus Explorer",
  "public_description": "Navigate the entire UPSC syllabus in an interactive 
    visual map. Track your progress, identify weak areas, and access study 
    materials for any topic with a single click.",
  "category": "Navigation & Planning",
  "complexity": "High",
  
  "what_it_does": [
    "3D interactive tree visualization of complete UPSC syllabus (Prelims + Mains)",
    "Clickable nodes that open lessons, videos, notes, PYQs, and quizzes",
    "Real-time progress tracking with color-coded completion status",
    "Heat map showing time spent and performance per topic",
    "Recommended study paths based on user's weak areas"
  ],
  
  "inputs": {
    "user_id": "UUID - logged in user",
    "view_mode": "tree | flat | timeline",
    "filter": {
      "papers": ["GS1", "GS2", "GS3", "GS4", "CSAT", "Essay"],
      "completion_status": "all | completed | in_progress | not_started",
      "priority": "high | medium | low | all"
    }
  },
  
  "outputs": {
    "syllabus_tree": "Hierarchical JSON with progress data",
    "deep_links": "URLs to topic-specific study pages",
    "recommendations": "Array of suggested next topics",
    "analytics": {
      "total_topics": "number",
      "completed": "number",
      "in_progress": "number",
      "weak_areas": "array of topic IDs"
    }
  },
  
  "frontend": {
    "page": "SyllabusExplorerPage.tsx",
    "component": "SyllabusTree3D.tsx",
    "library": "React Three Fiber (@react-three/fiber)",
    "interactions": "Click, zoom, pan, filter, search"
  },
  
  "backend": {
    "pipe": "syllabus_navigator_pipe.ts",
    "filters": ["auth_filter.ts", "progress_aggregator_filter.ts"],
    "actions": ["fetch_syllabus_tree_action.ts", "update_progress_action.ts"],
    "endpoints": [
      "GET /api/syllabus/tree",
      "GET /api/syllabus/node/:id",
      "POST /api/syllabus/progress"
    ]
  },
  
  "uses_manim": false,
  "uses_remotion": true,
  "uses_video_render": false,
  
  "video_generation": {
    "intro_videos": "Remotion generates brief intro videos for each major node",
    "purpose": "Visual preview of topic before user clicks through"
  },
  
  "entitlement": {
    "free_tier": "Basic 2D tree view, limited filtering",
    "pro_tier": "Full 3D view, advanced analytics, guided roadmaps"
  },
  
  "monetization": ["Premium feature unlock", "Guided roadmap add-on"],
  
  "implementation_notes": [
    "Use react-three-fiber for 3D visualization",
    "Pre-compute progress aggregations nightly",
    "Cache syllabus tree in Redis (TTL: 1 hour)",
    "Progress updates trigger real-time UI refresh"
  ]
}

--------------------------------------------------------------------------------
FEATURE 2: Daily Current Affairs Video Newspaper
--------------------------------------------------------------------------------
{
  "feature_id": 2,
  "slug": "daily-current-affairs-video",
  "display_name": "Daily News Digest",
  "public_description": "Wake up to a fresh 5-8 minute video summary of 
    UPSC-relevant current affairs every morning. Includes visual maps, 
    timelines, and key points for quick revision.",
  "category": "Current Affairs",
  "complexity": "High",
  
  "what_it_does": [
    "Auto-generates 5-8 minute daily video summarizing national/international news",
    "Segments by topic: Economy, Polity, International Relations, Environment",
    "Visual maps and animated timelines for complex events",
    "Auto-generated 30-60s Shorts for social media sharing",
    "Downloadable PDF summary with key points",
    "5 MCQs for quick self-assessment"
  ],
  
  "scheduler": {
    "cron": "0 2 * * *",
    "timezone": "Asia/Kolkata",
    "notes": "Runs at 2 AM IST daily; video ready by 6 AM"
  },
  
  "inputs": {
    "automated": true,
    "sources": {
      "rss_feeds": ["curated UPSC news feeds"],
      "allowed_domains": [
        "visionias.in", "drishtiias.com", "thehindu.com", 
        "pib.gov.in", "forumias.com"
      ],
      "date_range": "last_24_hours"
    }
  },
  
  "pipeline": {
    "step_1": {
      "name": "Fetch Articles",
      "tool": "duckduckgo_upsc_search",
      "url": "http://89.117.60.144:8102/search/upsc",
      "params": { "date_range": "last_24_hours", "max_results": 30 }
    },
    "step_2": {
      "name": "RAG Enhancement",
      "tool": "doc_retriever",
      "url": "http://89.117.60.144:8101/retrieve",
      "purpose": "Add context from knowledge base"
    },
    "step_3": {
      "name": "Rank by Relevance",
      "logic": "Score articles by syllabus relevance, recency, impact"
    },
    "step_4": {
      "name": "Generate Script",
      "tool": "LLM",
      "output": "Narration script with timestamps and visual cues [VISUAL 1..N]"
    },
    "step_5": {
      "name": "Create Visual Specs",
      "output": "Manim scene_spec JSON for timelines, maps, graphs"
    },
    "step_6": {
      "name": "Render Visuals",
      "tool": "manim_renderer",
      "url": "http://89.117.60.144:5555/render"
    },
    "step_7": {
      "name": "Assemble Video",
      "tool": "video_orchestrator",
      "url": "http://89.117.60.144:8103/render"
    },
    "step_8": {
      "name": "Generate Supporting Materials",
      "tool": "notes_generator",
      "url": "http://89.117.60.144:8104/generate_notes",
      "output": "PDF summary, MCQs, transcript"
    },
    "step_9": {
      "name": "Upload to Storage",
      "destination": "Supabase Storage > videos/daily-ca/"
    }
  },
  
  "outputs": {
    "full_video": {
      "duration": "5-8 minutes",
      "format": "mp4",
      "resolution": "1920x1080"
    },
    "short_video": {
      "duration": "30-60 seconds",
      "format": "mp4",
      "aspect_ratio": "9:16"
    },
    "transcript": "Full text transcript",
    "pdf_summary": "2-3 page PDF with key points",
    "mcqs": "5 questions with answers",
    "thumbnails": ["16:9", "1:1", "9:16"]
  },
  
  "frontend": {
    "page": "DailyDigestPage.tsx",
    "component": "DailyDigestCard.tsx",
    "features": ["Video player", "Transcript view", "Download options", "Quiz modal"]
  },
  
  "backend": {
    "pipe": "daily_ca_builder_pipe.ts",
    "filters": ["source_validator_filter.ts", "relevance_scorer_filter.ts"],
    "actions": [
      "fetch_news_action.ts",
      "generate_script_action.ts", 
      "render_visuals_action.ts",
      "assemble_video_action.ts"
    ]
  },
  
  "uses_manim": true,
  "uses_remotion": true,
  "uses_video_render": true,
  
  "entitlement": {
    "free_tier": "45-second preview",
    "pro_tier": "Full video, PDF, MCQs, archive access"
  },
  
  "monetization": [
    "Daily subscription",
    "Sponsor slots in video",
    "Per-episode purchase for non-subscribers"
  ],
  
  "caching": {
    "use_redis": true,
    "cache_daily_result": true,
    "ttl_seconds": 86400
  }
}

--------------------------------------------------------------------------------
FEATURE 3: Real-Time Doubt to Video Converter
--------------------------------------------------------------------------------
{
  "feature_id": 3,
  "slug": "doubt-to-video-converter",
  "display_name": "Instant Video Answers",
  "public_description": "Type or upload a screenshot of any doubt and get a 
    personalized video explanation within minutes. Includes visual diagrams 
    and practice questions.",
  "category": "Learning & Doubts",
  "complexity": "High",
  
  "what_it_does": [
    "Convert typed questions into 60-180 second explainer videos",
    "Support screenshot/image upload with OCR extraction",
    "Multiple explanation styles: concise, detailed, example-rich",
    "AI-generated visual diagrams for complex concepts",
    "Short notes and mini-quiz included with each response"
  ],
  
  "inputs": {
    "doubt_text": "string (optional if image provided)",
    "doubt_image": "base64 or file upload (optional)",
    "style": "concise | detailed | example_rich",
    "voice_preference": "male | female | neutral",
    "user_id": "UUID"
  },
  
  "pipeline": {
    "step_1": {
      "name": "Input Processing",
      "logic": "If image: OCR extraction; Normalize doubt text"
    },
    "step_2": {
      "name": "Knowledge Retrieval",
      "tool": "doc_retriever",
      "url": "http://89.117.60.144:8101/retrieve",
      "params": { "query": "doubt_text", "top_k": 8 }
    },
    "step_3": {
      "name": "Web Supplement",
      "tool": "duckduckgo_upsc_search",
      "condition": "If KB results insufficient"
    },
    "step_4": {
      "name": "Generate Explanation Script",
      "tool": "LLM",
      "output": "Narration script with visual markers"
    },
    "step_5": {
      "name": "Create Diagram Specs",
      "output": "Manim scene_spec for diagrams/graphs"
    },
    "step_6": {
      "name": "Render Video",
      "tools": ["http://89.117.60.144:5555/render", "http://89.117.60.144:8103/render"]
    },
    "step_7": {
      "name": "Generate Supporting Content",
      "output": "Short notes, 3 MCQs, transcript"
    }
  },
  
  "outputs": {
    "video": {
      "duration": "60-180 seconds",
      "format": "mp4",
      "resolution": "1280x720"
    },
    "preview_script": "Text preview (immediate)",
    "thumbnail": "Video thumbnail",
    "short_notes": "200-word summary",
    "mini_quiz": "3 MCQs",
    "transcript": "Full text",
    "captions": "VTT file"
  },
  
  "response_modes": {
    "immediate": {
      "returns": ["preview_script", "estimated_time", "job_id"],
      "latency": "< 5 seconds"
    },
    "async": {
      "returns": ["full video and all assets"],
      "delivery": "WebSocket notification or polling"
    }
  },
  
  "frontend": {
    "page": "AskDoubtPage.tsx",
    "component": "DoubtInputCard.tsx",
    "features": ["Text input", "Image upload", "Style selector", "Progress indicator"]
  },
  
  "backend": {
    "pipe": "doubt_video_converter_pipe.ts",
    "filters": ["ocr_filter.ts", "content_safety_filter.ts", "syllabus_mapper_filter.ts"],
    "actions": ["generate_explanation_action.ts", "render_doubt_video_action.ts"]
  },
  
  "uses_manim": true,
  "uses_remotion": true,
  "uses_video_render": true,
  
  "entitlement": {
    "free_tier": "30-second preview only",
    "pro_tier": "Full video, unlimited requests"
  },
  
  "monetization": [
    "Per-video charge (5 credits)",
    "Monthly credit bundle",
    "Unlimited Pro plan"
  ],
  
  "caching": {
    "cache_by": "sha256(normalized_doubt_text + style)",
    "ttl_seconds": 604800,
    "skip_cache_if": "user requests fresh explanation"
  }
}

--------------------------------------------------------------------------------
FEATURE 4: 3-Hour Documentary-Style Lectures
--------------------------------------------------------------------------------
{
  "feature_id": 4,
  "slug": "documentary-lectures",
  "display_name": "Deep Dive Courses",
  "public_description": "Comprehensive 3-hour cinematic lectures on major 
    topics. Chaptered for easy navigation with timestamps, quizzes, and 
    suggested readings.",
  "category": "Courses",
  "complexity": "Very High",
  
  "what_it_does": [
    "Generate long-form cinematic lectures (2-3 hours)",
    "Automatic chapter segmentation with timestamps",
    "In-video bookmarks and suggested readings",
    "Per-chapter quizzes and revision points",
    "Professional narration with B-roll footage"
  ],
  
  "inputs": {
    "topic": "string - main topic",
    "depth": "shallow | medium | deep",
    "chapters_override": "optional array of chapter titles",
    "include_case_studies": "boolean",
    "include_pyqs": "boolean"
  },
  
  "pipeline": {
    "step_1": "Topic research via doc_retriever and web search",
    "step_2": "Auto-generate chapter structure (10-15 chapters)",
    "step_3": "Per-chapter script generation",
    "step_4": "Parallel rendering of chapter visuals (Manim + Remotion)",
    "step_5": "TTS narration generation",
    "step_6": "Chapter video assembly",
    "step_7": "Full video composition with transitions",
    "step_8": "Generate timestamps, transcript, reading list PDF"
  },
  
  "outputs": {
    "full_video": { "duration": "180 minutes", "format": "mp4" },
    "chapter_videos": "Individual chapter clips",
    "timestamps": "JSON with chapter markers",
    "transcript": "Full text",
    "reading_list_pdf": "Suggested books and sources",
    "chapter_quizzes": "Quiz per chapter"
  },
  
  "uses_manim": true,
  "uses_remotion": true,
  "uses_video_render": true,
  
  "entitlement": { "min_tier": "Pro" },
  "monetization": ["One-time purchase", "Course bundle", "Certification add-on"]
}

--------------------------------------------------------------------------------
FEATURE 5: 360� Immersive Geography/History Visualizations
--------------------------------------------------------------------------------
{
  "feature_id": 5,
  "slug": "immersive-360-visualization",
  "display_name": "Virtual Field Trips",
  "public_description": "Experience river basins, historical battlefields, 
    and geographical features in immersive 360� videos with interactive 
    hotspots and quizzes.",
  "category": "Geography & History",
  "complexity": "Very High",
  
  "what_it_does": [
    "360�/panoramic video experiences for geography and history",
    "Interactive hotspots with additional information",
    "Embedded quizzes at key points",
    "Timeline scrubber for historical events",
    "VR headset compatible"
  ],
  
  "uses_manim": true,
  "uses_remotion": true,
  "uses_threejs": true,
  "uses_video_render": true,
  
  "entitlement": { "min_tier": "Pro" },
  "monetization": ["Premium modules", "Institution packages"]
}

--------------------------------------------------------------------------------
FEATURE 6: 60-Second Topic Shorts
--------------------------------------------------------------------------------
{
  "feature_id": 6,
  "slug": "topic-60-seconds",
  "display_name": "Quick Revision Shorts",
  "public_description": "Get any UPSC topic explained in 60 seconds. Perfect 
    for quick revision and social sharing.",
  "category": "Quick Learning",
  "complexity": "Medium",
  
  "what_it_does": [
    "60-second explainer videos for any topic",
    "Auto-generated thumbnails optimized for social media",
    "SEO-friendly titles and descriptions",
    "One-tap social sharing"
  ],
  
  "inputs": { "topic": "string" },
  
  "outputs": {
    "video": { "duration": "60 seconds", "aspect_ratios": ["16:9", "9:16", "1:1"] },
    "transcript": "string",
    "thumbnail": "3 variants"
  },
  
  "uses_manim": true,
  "uses_remotion": true,
  
  "entitlement": {
    "free_tier": "15-second preview",
    "pro_tier": "Full shorts, bulk download"
  }
}

--------------------------------------------------------------------------------
FEATURE 7: Visual Memory Palace
--------------------------------------------------------------------------------
{
  "feature_id": 7,
  "slug": "memory-palace",
  "display_name": "Memory Mastery",
  "public_description": "Convert lists and facts into memorable visual 
    journeys through animated palace rooms. Proven memory technique made easy.",
  "category": "Memory & Revision",
  "complexity": "High",
  
  "what_it_does": [
    "Transform facts/lists into animated memory palace",
    "Custom palace themes per user",
    "Spaced repetition integration for review",
    "Interactive walkthrough mode"
  ],
  
  "inputs": {
    "facts": "array of strings",
    "palace_theme": "default | historical | modern",
    "user_id": "UUID"
  },
  
  "uses_manim": true,
  "uses_remotion": true,
  
  "entitlement": { "min_tier": "Basic" }
}

--------------------------------------------------------------------------------
FEATURE 8: Ethics Case Study Roleplay (GS4)
--------------------------------------------------------------------------------
{
  "feature_id": 8,
  "slug": "ethics-roleplay",
  "display_name": "Ethics Simulator",
  "public_description": "Practice ethical decision-making with realistic 
    scenarios. Make choices and see the consequences unfold through video.",
  "category": "Ethics Paper",
  "complexity": "High",
  
  "what_it_does": [
    "Interactive ethical dilemma scenarios",
    "Branching video paths based on user choices",
    "Scoring based on ethical frameworks (utilitarian, deontological)",
    "Detailed feedback video after completion"
  ],
  
  "uses_manim": true,
  "uses_remotion": true,
  
  "entitlement": { "min_tier": "Pro" },
  "monetization": ["Premium case packs", "Mentor review add-on"]
}

--------------------------------------------------------------------------------
FEATURE 9: Animated Math Problem Solver (CSAT/Economy)
--------------------------------------------------------------------------------
{
  "feature_id": 9,
  "slug": "math-problem-solver",
  "display_name": "Step-by-Step Solver",
  "public_description": "Watch any math problem get solved step-by-step 
    with animated visualizations. Perfect for CSAT and Economics graphs.",
  "category": "CSAT & Economics",
  "complexity": "High",
  
  "what_it_does": [
    "Step-by-step animated solutions",
    "Support for typed problems or image upload (OCR)",
    "Algebraic steps with dynamic highlighting",
    "Graph drawing and explanation"
  ],
  
  "inputs": {
    "problem_text": "string (optional)",
    "problem_image": "base64 (optional)"
  },
  
  "uses_manim": true,
  "uses_remotion": true,
  
  "entitlement": { "pay_per_solve": true, "bundle_credits": true }
}

--------------------------------------------------------------------------------
FEATURE 10: Static & Animated Notes Generator
--------------------------------------------------------------------------------
{
  "feature_id": 10,
  "slug": "notes-generator",
  "display_name": "Smart Notes Creator",
  "public_description": "Generate comprehensive study notes at three depth 
    levels. Includes visual diagrams and a quick revision video.",
  "category": "Notes & Study Material",
  "complexity": "Medium",
  
  "what_it_does": [
    "Generate notes in 3 levels: 100/250/500 words",
    "Auto-generated visual diagrams",
    "60-second video summary",
    "Export as PDF, markdown",
    "Cross-linked to related topics"
  ],
  
  "inputs": {
    "topic": "string or syllabus_node_id",
    "depth_levels": ["summary", "detailed", "comprehensive"],
    "include_diagrams": "boolean",
    "include_video": "boolean"
  },
  
  "pipeline": {
    "step_1": {
      "name": "Knowledge Retrieval",
      "tool": "doc_retriever",
      "url": "http://89.117.60.144:8101/retrieve"
    },
    "step_2": {
      "name": "Web Enhancement",
      "tool": "duckduckgo_upsc_search",
      "condition": "If topic has recent developments"
    },
    "step_3": {
      "name": "Generate Notes",
      "tool": "notes_generator",
      "url": "http://89.117.60.144:8104/generate_notes"
    },
    "step_4": {
      "name": "Create Diagrams",
      "tool": "manim_renderer",
      "url": "http://89.117.60.144:5555/render"
    }
  },
  
  "outputs": {
    "notes": {
      "summary": "100-150 words",
      "detailed": "400-600 words",
      "comprehensive": "1500-2500 words"
    },
    "diagrams": "Array of visual assets",
    "video_summary": "60-second clip",
    "pdf": "Formatted PDF document",
    "mcqs": "5 practice questions"
  },
  
  "uses_manim": true,
  "uses_remotion": true,
  
  "entitlement": {
    "free_tier": "Summary only",
    "pro_tier": "All levels, diagrams, video, PDF"
  }
}

--------------------------------------------------------------------------------
FEATURE 11: Case Law & Amendment Explainer
--------------------------------------------------------------------------------
{
  "feature_id": 11,
  "slug": "legal-explainer",
  "display_name": "Supreme Court & Amendments",
  "public_description": "Visual timelines and explanations of landmark cases, 
    constitutional amendments, and committee recommendations.",
  "category": "Polity",
  "complexity": "Medium-High",
  
  "uses_manim": true,
  "uses_remotion": true,
  "entitlement": { "min_tier": "Basic" }
}

--------------------------------------------------------------------------------
FEATURE 12: AI Study Schedule Builder
--------------------------------------------------------------------------------
{
  "feature_id": 12,
  "slug": "ai-schedule-builder",
  "display_name": "Personal Study Planner",
  "public_description": "Get a personalized daily study schedule adapted 
    to your weak topics, available time, and exam date.",
  "category": "Planning",
  "complexity": "Medium",
  
  "what_it_does": [
    "Personalized daily schedules based on user profile",
    "Adaptive based on progress and performance",
    "Calendar sync (Google Calendar)",
    "Push notification reminders",
    "Weekly summary with adjustments"
  ],
  
  "inputs": {
    "user_id": "UUID",
    "exam_date": "date",
    "hours_per_day": "number",
    "weak_topics": "array (auto-detected or manual)",
    "preferences": {
      "study_style": "intensive | balanced | relaxed",
      "morning_person": "boolean"
    }
  },
  
  "outputs": {
    "daily_schedule": "JSON with time blocks and topics",
    "linked_resources": "Videos, notes, quizzes for each block",
    "calendar_ics": "Importable calendar file"
  },
  
  "uses_remotion": true,
  "entitlement": { "min_tier": "Free" }
}

--------------------------------------------------------------------------------
FEATURE 13: PYQ Video Explanation Engine
--------------------------------------------------------------------------------
{
  "feature_id": 13,
  "slug": "pyq-video-engine",
  "display_name": "Previous Year Solutions",
  "public_description": "Upload any PYQ paper and get video explanations 
    for each question with model answers.",
  "category": "Practice",
  "complexity": "High",
  
  "uses_manim": true,
  "uses_remotion": true,
  "entitlement": { "min_tier": "Pro" }
}

--------------------------------------------------------------------------------
FEATURE 14: 3D Interactive Map Atlas
--------------------------------------------------------------------------------
{
  "feature_id": 14,
  "slug": "3d-map-atlas",
  "display_name": "Living Geography Atlas",
  "public_description": "Explore India and World geography with interactive 
    3D maps. See resource distribution, climate patterns, and more.",
  "category": "Geography",
  "complexity": "Very High",
  
  "uses_manim": true,
  "uses_remotion": true,
  "uses_threejs": true,
  "entitlement": { "min_tier": "Pro" }
}

--------------------------------------------------------------------------------
FEATURE 15: AI Essay Trainer with Video Feedback
--------------------------------------------------------------------------------
{
  "feature_id": 15,
  "slug": "essay-trainer",
  "display_name": "Essay Mastery Coach",
  "public_description": "Submit your essays and get AI scoring with a 
    personalized video walkthrough of improvements.",
  "category": "Essay Paper",
  "complexity": "Medium",
  
  "uses_manim": true,
  "uses_remotion": true,
  "entitlement": { "min_tier": "Basic" }
}

--------------------------------------------------------------------------------
FEATURE 16: Daily Answer Writing Practice
--------------------------------------------------------------------------------
{
  "feature_id": 16,
  "slug": "daily-answer-practice",
  "display_name": "Daily Mains Practice",
  "public_description": "Practice one answer daily with instant AI scoring 
    and video feedback. Compare with model answers.",
  "category": "Mains Practice",
  "complexity": "Medium",
  
  "uses_manim": true,
  "uses_remotion": true,
  "entitlement": { "min_tier": "Basic" }
}

--------------------------------------------------------------------------------
FEATURE 17: GS4 Ethics Simulator (Advanced)
--------------------------------------------------------------------------------
{
  "feature_id": 17,
  "slug": "gs4-ethics-simulator",
  "display_name": "Ethics Deep Practice",
  "public_description": "Multi-stage ethical scenarios with personality 
    analysis and detailed improvement plans.",
  "category": "Ethics Paper",
  "complexity": "High",
  
  "uses_manim": true,
  "uses_remotion": true,
  "entitlement": { "min_tier": "Pro" }
}

--------------------------------------------------------------------------------
FEATURE 18: RAG-Powered UPSC Search
--------------------------------------------------------------------------------
{
  "feature_id": 18,
  "slug": "upsc-search-engine",
  "display_name": "Smart Search",
  "public_description": "Search across our entire knowledge base with 
    AI-powered relevance ranking and source citations.",
  "category": "Search & Discovery",
  "complexity": "Medium",
  
  "what_it_does": [
    "High-precision search across all ingested PDFs",
    "Filter by subject, paper, topic",
    "Source citations with book/page references",
    "AI-generated answer snippets"
  ],
  
  "inputs": {
    "query": "string",
    "filters": {
      "subjects": ["Polity", "History"],
      "papers": ["GS1", "GS2"],
      "source_types": ["NCERT", "Standard Books", "Notes"]
    }
  },
  
  "pipeline": {
    "step_1": {
      "name": "Vector Search",
      "tool": "doc_retriever",
      "url": "http://89.117.60.144:8101/retrieve"
    },
    "step_2": {
      "name": "Optional Web Search",
      "tool": "duckduckgo_upsc_search"
    },
    "step_3": {
      "name": "Result Synthesis",
      "output": "Ranked results with citations"
    }
  },
  
  "outputs": {
    "results": "Array of search hits",
    "ai_summary": "AI-generated answer",
    "citations": "Source references"
  },
  
  "uses_manim": false,
  "uses_remotion": false,
  "entitlement": { "min_tier": "Basic" }
}

--------------------------------------------------------------------------------
FEATURE 19: Topic-to-Question Generator
--------------------------------------------------------------------------------
{
  "feature_id": 19,
  "slug": "question-generator",
  "display_name": "Practice Question Bank",
  "public_description": "Auto-generate MCQs and Mains questions for any 
    topic with model answers.",
  "category": "Practice",
  "complexity": "Low-Medium",
  
  "uses_manim": false,
  "uses_remotion": false,
  "entitlement": { "min_tier": "Basic" }
}

--------------------------------------------------------------------------------
FEATURE 20: Personalized AI Teaching Assistant
--------------------------------------------------------------------------------
{
  "feature_id": 20,
  "slug": "ai-tutor",
  "display_name": "Your AI Mentor",
  "public_description": "A conversational tutor that remembers your progress, 
    adapts to your learning style, and provides personalized guidance.",
  "category": "Mentorship",
  "complexity": "Medium",
  
  "uses_remotion": true,
  "entitlement": { "min_tier": "Basic" }
}

--------------------------------------------------------------------------------
FEATURE 21: UPSC Mindmap Builder
--------------------------------------------------------------------------------
{
  "feature_id": 21,
  "slug": "mindmap-builder",
  "display_name": "Visual Mind Maps",
  "public_description": "Auto-generate interactive mindmaps from any topic 
    or upload. Export as PDF or share with peers.",
  "category": "Study Tools",
  "complexity": "Medium",
  
  "uses_remotion": true,
  "entitlement": { "min_tier": "Basic" }
}

--------------------------------------------------------------------------------
FEATURE 22: Syllabus Tracking Dashboard
--------------------------------------------------------------------------------
{
  "feature_id": 22,
  "slug": "progress-dashboard",
  "display_name": "Progress Tracker",
  "public_description": "Comprehensive dashboard showing topic completion, 
    strength/weakness analysis, and predicted exam readiness.",
  "category": "Analytics",
  "complexity": "Medium",
  
  "uses_manim": true,
  "uses_remotion": true,
  "entitlement": { "min_tier": "Basic" }
}

--------------------------------------------------------------------------------
FEATURE 23: Smart Revision Booster
--------------------------------------------------------------------------------
{
  "feature_id": 23,
  "slug": "revision-booster",
  "display_name": "Revision Packs",
  "public_description": "Auto-select your 5 weakest topics and get a 
    revision package: short video, flashcards, and quick quiz.",
  "category": "Revision",
  "complexity": "Medium",
  
  "uses_manim": true,
  "uses_remotion": true,
  "entitlement": { "min_tier": "Basic" }
}

--------------------------------------------------------------------------------
FEATURE 24: 5-Hours Per Day Planner
--------------------------------------------------------------------------------
{
  "feature_id": 24,
  "slug": "5hour-planner",
  "display_name": "Working Professional Plan",
  "public_description": "Optimized study plan for aspirants limited to 
    5 hours daily. Includes auto-adjustment for missed sessions.",
  "category": "Planning",
  "complexity": "Low-Medium",
  
  "uses_remotion": true,
  "entitlement": { "min_tier": "Free" }
}

--------------------------------------------------------------------------------
FEATURE 25: Book-to-Notes Converter
--------------------------------------------------------------------------------
{
  "feature_id": 25,
  "slug": "book-to-notes",
  "display_name": "Book Summarizer",
  "public_description": "Upload any chapter and get multi-level notes, 
    key facts MCQs, visual diagrams, and a 1-minute summary video.",
  "category": "Notes",
  "complexity": "Medium",
  
  "uses_manim": true,
  "uses_remotion": true,
  "entitlement": { "min_tier": "Pro" }
}

--------------------------------------------------------------------------------
FEATURE 26: Weekly Documentary
--------------------------------------------------------------------------------
{
  "feature_id": 26,
  "slug": "weekly-documentary",
  "display_name": "Week in Review",
  "public_description": "15-30 minute documentary-style weekly analysis 
    covering Economy, Polity, IR, and Environment.",
  "category": "Current Affairs",
  "complexity": "High",
  
  "scheduler": {
    "cron": "0 0 * * 0",
    "notes": "Every Sunday at midnight"
  },
  
  "uses_manim": true,
  "uses_remotion": true,
  "entitlement": { "min_tier": "Pro" }
}

--------------------------------------------------------------------------------
FEATURE 27: Test Series Auto-Grader
--------------------------------------------------------------------------------
{
  "feature_id": 27,
  "slug": "test-grader",
  "display_name": "AI Test Evaluation",
  "public_description": "Full mock test platform with auto-grading for 
    both objective and subjective answers. Detailed analytics.",
  "category": "Practice",
  "complexity": "Medium",
  
  "uses_remotion": true,
  "entitlement": { "min_tier": "Basic" }
}

--------------------------------------------------------------------------------
FEATURE 28: Monetization System (Internal)
--------------------------------------------------------------------------------
{
  "feature_id": 28,
  "slug": "monetization-system",
  "display_name": "Billing & Subscriptions",
  "public_description": "Manage your subscription, view invoices, and 
    apply promo codes.",
  "category": "Account",
  "complexity": "Medium-High",
  
  "implementation": {
    "payment_provider": "RevenueCat",
    "plans": [
      { "name": "Monthly", "price_inr": 599, "days": 30 },
      { "name": "Quarterly", "price_inr": 1199, "days": 90 },
      { "name": "Half-Yearly", "price_inr": 2399, "days": 180 },
      { "name": "Annual", "price_inr": 4799, "days": 365 }
    ],
    "trial": {
      "duration_days": 1,
      "full_access": true,
      "requires_payment_method": false
    }
  },
  
  "admin_features": [
    "Revenue dashboard",
    "Coupon management",
    "Affiliate tracking",
    "Refund processing"
  ]
}

--------------------------------------------------------------------------------
FEATURE 29: AI Voice Teacher
--------------------------------------------------------------------------------
{
  "feature_id": 29,
  "slug": "voice-teacher",
  "display_name": "Voice Customization",
  "public_description": "Choose your preferred teaching voice style 
    for all video content.",
  "category": "Settings",
  "complexity": "Medium",
  
  "uses_remotion": true,
  "entitlement": { "min_tier": "Basic" }
}

--------------------------------------------------------------------------------
FEATURE 30: Gamified Learning Experience
--------------------------------------------------------------------------------
{
  "feature_id": 30,
  "slug": "gamified-learning",
  "display_name": "Study Rewards",
  "public_description": "Earn XP, unlock badges, and compete on 
    leaderboards as you study.",
  "category": "Engagement",
  "complexity": "High",
  
  "uses_manim": true,
  "uses_remotion": true,
  "entitlement": { "min_tier": "Basic" }
}

--------------------------------------------------------------------------------
FEATURE 31: Topic Difficulty Predictor
--------------------------------------------------------------------------------
{
  "feature_id": 31,
  "slug": "difficulty-predictor",
  "display_name": "Exam Trend Analysis",
  "public_description": "AI predictions of topic difficulty and likelihood 
    of appearing in upcoming exams based on historical patterns.",
  "category": "Analytics",
  "complexity": "Medium-High",
  
  "uses_manim": true,
  "uses_remotion": true,
  "entitlement": { "min_tier": "Basic" }
}

--------------------------------------------------------------------------------
FEATURE 32: Smart Bookmark Engine
--------------------------------------------------------------------------------
{
  "feature_id": 32,
  "slug": "smart-bookmarks",
  "display_name": "Smart Bookmarks",
  "public_description": "Save any concept with auto-linked notes, videos, 
    and scheduled revision reminders.",
  "category": "Study Tools",
  "complexity": "Low-Medium",
  
  "uses_remotion": true,
  "entitlement": { "min_tier": "Free" }
}

--------------------------------------------------------------------------------
FEATURE 33: Concept Confidence Meter
--------------------------------------------------------------------------------
{
  "feature_id": 33,
  "slug": "confidence-meter",
  "display_name": "Readiness Score",
  "public_description": "Visual confidence meter for each topic based on 
    your quiz results and study time.",
  "category": "Analytics",
  "complexity": "Low-Medium",
  
  "uses_manim": true,
  "uses_remotion": true,
  "entitlement": { "min_tier": "Free" }
}

--------------------------------------------------------------------------------
FEATURE 34: Live Interview Prep Studio
--------------------------------------------------------------------------------
{
  "feature_id": 34,
  "slug": "interview-studio",
  "display_name": "Interview Simulator",
  "public_description": "Practice UPSC interviews with AI panelists. 
    Real-time visual aids, recording, and detailed debrief video.",
  "category": "Interview Prep",
  "complexity": "Very High",
  
  "what_it_does": [
    "Live AI-powered mock interviews",
    "Real-time visual aids (Manim diagrams) during answers",
    "Full session recording",
    "Instant Remotion-generated debrief video",
    "Optional body language analysis (with consent)",
    "Peer/mentor panel mode"
  ],
  
  "uses_manim": true,
  "uses_remotion": true,
  "uses_webrtc": true,
  
  "entitlement": {
    "min_tier": "Pro",
    "pay_per_mock": true
  },
  
  "monetization": [
    "Per-mock fee",
    "Monthly mock bundle",
    "Mentor review add-on"
  ]
}

--------------------------------------------------------------------------------
FEATURE 35: Auto Social Media Publisher
--------------------------------------------------------------------------------
{
  "feature_id": 35,
  "slug": "auto-ads-publisher",
  "display_name": "Content Auto-Publisher",
  "public_description": "Admin-only: Auto-generate and publish promotional 
    shorts to YouTube, Instagram, Facebook, and Twitter.",
  "category": "Marketing (Admin)",
  "complexity": "High",
  
  "what_it_does": [
    "Auto-generate 15-60s promotional videos",
    "Multi-platform publishing (YouTube, Instagram, Facebook, X)",
    "A/B testing for titles and thumbnails",
    "Sponsor slot insertion",
    "Daily scheduling"
  ],
  
  "uses_manim": true,
  "uses_remotion": true,
  
  "social_apis": {
    "youtube": "YouTube Data API v3",
    "instagram": "Instagram Content Publishing API",
    "facebook": "Facebook Graph API",
    "twitter": "Twitter API v2"
  },
  
  "admin_only": true,
  "entitlement": { "admin_only": true }
}

================================================================================
SECTION 4: SUBSCRIPTION & TRIAL LOGIC
================================================================================

4.1 TRIAL SYSTEM
----------------
- Duration: 1 day (24 hours) from account creation
- Access: FULL premium access during trial
- No payment method required to start trial
- After trial expires: ALL premium features blocked
- User sees: Paywall with subscription options

4.2 SUBSCRIPTION PLANS
----------------------
Plan Name     | Price (INR) | Duration | RevenueCat Product ID
--------------+-------------+----------+----------------------
Monthly       | ?599        | 30 days  | upsc_monthly_599
Quarterly     | ?1,199      | 90 days  | upsc_quarterly_1199
Half-Yearly   | ?2,399      | 180 days | upsc_halfyearly_2399
Annual        | ?4,799      | 365 days | upsc_annual_4799

4.3 ENTITLEMENT CHECK LOGIC (PSEUDO-CODE)
-----------------------------------------
function checkEntitlement(user_id, feature_slug):
  subscription = getActiveSubscription(user_id)
  feature = getFeatureManifest(feature_slug)
  
  // Check trial
  if subscription.status == 'trial':
    if NOW() < subscription.trial_expires_at:
      return { allowed: true, reason: 'trial_active' }
    else:
      return { allowed: false, reason: 'trial_expired', show_paywall: true }
  
  // Check active subscription
  if subscription.status == 'active':
    if NOW() < subscription.subscription_expires_at:
      return { allowed: true, reason: 'subscription_active' }
    else:
      // Grace period check
      if NOW() < subscription.subscription_expires_at + 3_days:
        return { allowed: true, reason: 'grace_period', show_renewal_prompt: true }
      else:
        updateSubscriptionStatus(user_id, 'expired')
        return { allowed: false, reason: 'subscription_expired', show_paywall: true }
  
  // Free tier check
  if feature.entitlement_required == 'free':
    return { allowed: true, reason: 'free_feature' }
  
  return { allowed: false, reason: 'no_subscription', show_paywall: true }

4.4 REVENUECAT WEBHOOK HANDLER
------------------------------
Endpoint: POST /api/webhooks/revenuecat

Events to handle:
- INITIAL_PURCHASE: Create/activate subscription
- RENEWAL: Extend subscription_expires_at
- CANCELLATION: Set auto_renew = false
- EXPIRATION: Update status to 'expired'
- BILLING_ISSUE: Update status to 'grace_period'

================================================================================
SECTION 5: ADMIN PANEL REQUIREMENTS
================================================================================

5.1 ADMIN DASHBOARD SECTIONS
----------------------------

1. Overview Dashboard
   - Total users, active subscribers, trial users
   - Revenue metrics (daily, weekly, monthly)
   - Feature usage analytics
   - Error rate and job queue status

2. User Management
   - User list with search, filter, sort
   - View/edit user profile
   - Grant/revoke entitlements
   - Subscription management
   - View user activity log

3. Subscription Management
   - Active subscriptions list
   - Revenue reports by plan
   - Coupon code management
   - Refund processing

4. Knowledge Base Management
   - Upload new PDFs
   - View processing status
   - Reprocess chunks
   - Syllabus node management
   - View/edit comprehensive notes
   - Approve daily updates

5. Video & Render Management
   - Job queue monitoring
   - Render status and logs
   - Re-trigger failed renders
   - Video asset management

6. AI Provider Configuration
   - Add/edit AI providers
   - Set provider priorities
   - Model configuration
   - Cost tracking
   - Rate limit settings

   Supported providers:
   - OpenAI (GPT-4, GPT-3.5)
   - Anthropic (Claude)
   - Google (Gemini)
   - Azure OpenAI
   - Local/Custom models

7. Social Publishing (Feature 35)
   - Ad queue management
   - Platform OAuth tokens
   - Publishing schedule
   - Analytics per post

8. Current Affairs Management
   - View daily update queue
   - Approve/reject updates
   - Source whitelist management
   - Manual article addition

9. System Configuration
   - Environment variables (masked)
   - Feature flags
   - Rate limits
   - Cache management
   - Backup status

10. Audit Logs
    - All admin actions logged
    - User activity logs
    - Security events

5.2 ADMIN AUTHENTICATION
------------------------
- Supabase Auth with role = 'admin'
- JWT validation on all admin endpoints
- IP whitelist option
- 2FA recommended

================================================================================
SECTION 6: FRONTEND REQUIREMENTS
================================================================================

6.1 TECHNOLOGY STACK
--------------------
- Framework: Next.js 14+ (App Router)
- Styling: Tailwind CSS
- UI Components: shadcn/ui
- State: React Query + Zustand
- 3D: React Three Fiber
- Video Player: Custom with HLS support
- Charts: Recharts or Chart.js
- Forms: React Hook Form + Zod

6.2 DESIGN SYSTEM
-----------------
- Theme: Neon Glass (dark mode primary)
- Colors: 
  - Primary: Blue gradients (#3B82F6 to #1D4ED8)
  - Secondary: Purple accents (#8B5CF6)
  - Background: Dark slate (#0F172A)
  - Glass effects: Frosted glass with blur
- Typography: Inter / Satoshi
- Animations: Framer Motion

6.3 KEY PAGES
-------------
Public:
- Landing page (marketing)
- Login / Sign up
- Pricing page
- About / Contact

Authenticated (Dashboard):
- Home / Dashboard
- Syllabus Explorer (Feature 1)
- Daily Digest (Feature 2)
- Ask Doubt (Feature 3)
- Courses (Feature 4)
- Notes Library (Feature 10)
- Search (Feature 18)
- Practice (Features 13, 19, 27)
- Progress (Feature 22)
- Settings / Profile
- Subscription / Billing

Admin:
- Admin Dashboard
- User Management
- Content Management
- System Settings

6.4 UI GUIDELINES FOR IDE BUILDER
---------------------------------
- Hide all technical terms from users (no "Manim", "Remotion", "RAG")
- Use friendly alternatives:
  - "AI Animation Engine" instead of "Manim"
  - "Smart Video Creator" instead of "Remotion"
  - "Intelligent Search" instead of "RAG"
- Show loading states for all async operations
- Use skeleton loaders, not spinners
- All forms have validation feedback
- Toast notifications for actions
- Mobile-responsive design (mobile-first)

================================================================================
SECTION 7: BACKEND ARCHITECTURE (PIPES/FILTERS/ACTIONS)
================================================================================

7.1 PATTERN OVERVIEW
--------------------
Every feature follows this pattern:

USER REQUEST
    ?
PIPE (Orchestrator Edge Function)
    ?
FILTER(s) (Validation, enrichment, security checks)
    ?
ACTION(s) (Side effects: DB writes, external calls, job queue)
    ?
RESPONSE (Immediate + async job ID if applicable)

7.2 PIPE STRUCTURE
------------------
// pipes/<feature_slug>_pipe.ts

import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from '@supabase/supabase-js'

serve(async (req) => {
  // 1. Auth & init
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY)
  const authHeader = req.headers.get('Authorization')
  const { data: { user } } = await supabase.auth.getUser(authHeader?.split(' ')[1])
  
  if (!user) {
    return Response.json({ error: 'Unauthorized' }, { status: 401 })
  }
  
  // 2. Entitlement check
  const entitlement = await checkEntitlement(user.id, 'feature-slug')
  if (!entitlement.allowed) {
    return Response.json({ 
      error: 'Subscription required',
      reason: entitlement.reason,
      show_paywall: true 
    }, { status: 403 })
  }
  
  // 3. Parse input
  const payload = await req.json()
  
  // 4. Run filters
  const filtered = await runFilters(payload, [
    'content_safety_filter',
    'syllabus_mapper_filter',
    'rag_injector_filter'
  ])
  
  if (!filtered.ok) {
    return Response.json({ error: filtered.error }, { status: 400 })
  }
  
  // 5. Execute actions
  const result = await executeAction('generate_content_action', filtered.payload)
  
  // 6. Return response
  return Response.json(result)
})

7.3 FILTER TEMPLATE
-------------------
// filters/<name>_filter.ts

export async function filter(payload: any, ctx: FilterContext): Promise<FilterResult> {
  // Validation logic
  // Enrichment logic
  // Return transformed payload or error
  
  return {
    ok: true,
    payload: transformedPayload,
    metadata: { ... }
  }
}

7.4 ACTION TEMPLATE
-------------------
// actions/<name>_action.ts

export async function action(payload: any, ctx: ActionContext): Promise<ActionResult> {
  // Perform side effects:
  // - Database writes
  // - External API calls
  // - Job queue insertion
  // - Storage uploads
  
  return {
    success: true,
    data: { ... },
    job_id: 'uuid' // if async
  }
}

7.5 EXTERNAL SERVICE CALLS
--------------------------
All external calls must be made through Edge Functions (server-side):

// Document Retriever
async function queryKnowledgeBase(query: string, topK: number = 10) {
  const response = await fetch(
    `${Deno.env.get('DOC_RETRIEVER_URL')}/retrieve?query=${encodeURIComponent(query)}&top_k=${topK}`
  )
  return response.json()
}

// DuckDuckGo UPSC Search
async function searchUPSCSources(query: string, domains: string[] = []) {
  const response = await fetch(Deno.env.get('DDG_UPSC_SEARCH_URL'), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      query,
      allowed_domains: domains,
      date_range: 'last_7_days'
    })
  })
  return response.json()
}

// Video Renderer
async function renderVideo(sceneSpec: object) {
  const response = await fetch(Deno.env.get('MANIM_RENDERER_URL'), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(sceneSpec)
  })
  return response.json()
}

// Notes Generator
async function generateNotes(topic: string, options: object) {
  const response = await fetch(Deno.env.get('NOTES_GENERATOR_URL'), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ topic, ...options })
  })
  return response.json()
}

================================================================================
SECTION 8: ENVIRONMENT VARIABLES
================================================================================

# Supabase
SUPABASE_URL=https://supabase.aimasteryedu.in
SUPABASE_ANON_KEY=<your-anon-key>
SUPABASE_SERVICE_ROLE_KEY=<your-service-role-key>

# Self-Hosted Services (VPS)
DOC_RETRIEVER_URL=http://89.117.60.144:8101/retrieve
DDG_SEARCH_URL=http://89.117.60.144:8102/search
DDG_UPSC_SEARCH_URL=http://89.117.60.144:8102/search/upsc
VIDEO_ORCHESTRATOR_URL=http://89.117.60.144:8103/render
MANIM_RENDERER_URL=http://89.117.60.144:5555/render
NOTES_GENERATOR_URL=http://89.117.60.144:8104/generate_notes

# RevenueCat
REVENUECAT_SECRET_API_KEY=<your-revenuecat-key>

# Google
GOOGLE_API_KEY=<your-google-api-key>
GOOGLE_OAUTH_CLIENT_ID=<your-oauth-client-id>

# Social Media
META_ADS_TOKEN=<your-meta-token>
YOUTUBE_API_KEY=<your-youtube-key>
TWITTER_API_KEY=<your-twitter-key>

# Storage / CDN
CDN_S3_KEY=<your-s3-key>
CDN_S3_SECRET=<your-s3-secret>
CDN_BUCKET=<your-bucket-name>

# Optional
REDIS_URL=<redis-url-for-caching>
OPENAI_API_KEY=<if-using-openai>
ANTHROPIC_API_KEY=<if-using-claude>

================================================================================
SECTION 9: TESTING REQUIREMENTS
================================================================================

9.1 UNIT TESTS
--------------
- All filters must have unit tests
- All actions must have unit tests with mocked external calls
- Database operations must be tested with test database

9.2 INTEGRATION TESTS
---------------------
- Each pipe endpoint must have integration tests
- Mock all external services (renderer, search, notes generator)
- Test entitlement logic thoroughly

9.3 E2E TESTS
-------------
- User signup ? trial ? subscription flow
- Core feature flows (doubt to video, daily digest)
- Admin panel operations

================================================================================
SECTION 10: DEPLOYMENT CHECKLIST
================================================================================

? Create Supabase project / self-hosted instance
? Run all SQL migrations in order
? Create storage buckets (videos, notes, thumbnails, assets)
? Configure storage policies (public/private)
? Deploy all Edge Functions
? Set environment variables in Supabase Secrets
? Configure RevenueCat webhooks
? Set up cron jobs for scheduled features
? Seed syllabus taxonomy data
? Upload initial PDF knowledge base
? Process PDFs and create knowledge chunks
? Test all core flows
? Configure admin user
? Set up monitoring and alerts
? Configure CDN for video delivery
? SSL certificate verification

================================================================================
SECTION 11: CRITICAL REMINDERS FOR IDE BUILDER
================================================================================

1. NO localStorage for AUTH - Use Supabase Auth exclusively
2. NO hardcoded API keys - Use environment variables
3. ALL external calls via Edge Functions - Never expose endpoints to client
4. TRIAL LOGIC is non-negotiable - 1 day, then full block
5. KNOWLEDGE BASE from PDFs - Not web scraping for core content
6. DAILY UPDATES from whitelisted sources ONLY
7. USER-FRIENDLY LABELS - Hide technical terms (Manim, Remotion, RAG)
8. MOBILE-FIRST design
9. ENTITLEMENT CHECKS on every premium feature
10. AUDIT LOGGING for security-sensitive operations

================================================================================
END OF MASTER SPECIFICATION
================================================================================

When you receive command: generate pipelines: supabase-upsc
Output the full Antigravity package with all:
- SQL migrations
- Edge Functions (pipes, filters, actions, webhooks)
- Storage configuration
- README with deployment steps
- .env.example
- Test files
```

---

## HOW TO USE THIS PROMPT

Copy the entire content above (from `================` to `================`) and paste it into your IDE AI App Builder (Cursor, Windsurf, Lovable, Bolt, etc.) as the initial context/system prompt.

Then issue the command:

```
generate pipelines: supabase-upsc
```

The IDE AI will generate all the necessary code artifacts following this specification exactly.

---

**Key improvements in this consolidated version:**

1. **Single, complete document** - No truncation or missing sections
2. **Clear structure** - 11 numbered sections covering everything
3. **All 35 features detailed** - Each with inputs, outputs, pipeline steps
4. **Complete database schema** - All tables with proper relationships
5. **Subscription logic** - Clear trial ? paid flow with pseudo-code
6. **Admin panel requirements** - All necessary sections specified
7. **VPS service URLs** - All endpoints documented with request/response formats
8. **UI guidelines** - User-friendly terminology mappings
9. **Environment variables** - Complete list with placeholders
10. **Deployment checklist** - Step-by-step verification

**UPDATED SERVICE ENDPOINTS (December 23, 2025):**

Core Infrastructure (VPS: 89.117.60.144):
- Supabase Studio:    http://89.117.60.144:3000
- Supabase API:       http://89.117.60.144:8001 (CHANGED from 8000)
- Manim Renderer:     http://89.117.60.144:5000
- Revideo Renderer:   http://89.117.60.144:5001
- Coolify Dashboard:  http://89.117.60.144:8000

AI Models (A4F Unified API):
- Base URL: https://api.a4f.co/v1
- API Key: ddc-a4f-12e06ff0184f41de8d3de7be4cd2e831
- Primary LLM: provider-3/llama-4-scout
- Fallback LLM: provider-2/gpt-4.1
- Image Model: provider-3/gemini-2.5-flash
- Embeddings: provider-5/text-embedding-ada-002
- TTS: provider-5/tts-1
- STT: provider-5/whisper-1
- Image Gen: provider-4/imagen-4
