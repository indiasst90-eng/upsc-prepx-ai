-- Migration: 003_knowledge_base_tables.sql
-- Description: Knowledge base tables for RAG search system
-- Date: December 25, 2025
-- Story: 1.4 - Knowledge Base Tables

-- Enable pgvector extension for embeddings
CREATE EXTENSION IF NOT EXISTS vector;

-- Clean up any existing tables to ensure fresh start
DROP TABLE IF EXISTS public.knowledge_chunks CASCADE;
DROP TABLE IF EXISTS public.comprehensive_notes CASCADE;
DROP TABLE IF EXISTS public.pdf_uploads CASCADE;
DROP TABLE IF EXISTS public.syllabus_nodes CASCADE;
DROP TABLE IF EXISTS public.daily_updates CASCADE;

-- Add function cleanup if needed
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;

-- ============================================================================
-- SYLLABUS TAXONOMY
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.syllabus_nodes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  parent_id UUID ,
  level INTEGER NOT NULL CHECK (level BETWEEN 1 AND 5),
  path TEXT NOT NULL, -- Materialized path for tree queries
  description TEXT,
  syllabus_code TEXT, -- e.g., "GS1.1.1"
  paper TEXT CHECK (paper IN ('GS1', 'GS2', 'GS3', 'GS4', 'CSAT', 'Essay')),
  total_content_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_syllabus_parent ON public.syllabus_nodes(parent_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_syllabus_level ON public.syllabus_nodes(level);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_syllabus_path ON public.syllabus_nodes USING btree(path);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_syllabus_paper ON public.syllabus_nodes(paper);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_syllabus_slug ON public.syllabus_nodes(slug);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.syllabus_nodes ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Syllabus nodes are publicly readable"
  ON public.syllabus_nodes FOR SELECT
  TO anon, authenticated
  USING (true);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;


-- ============================================================================
-- PDF UPLOADS
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.pdf_uploads (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  filename TEXT NOT NULL,
  storage_path TEXT UNIQUE NOT NULL,
  subject TEXT,
  book_title TEXT,
  author TEXT,
  edition TEXT,
  upload_status TEXT NOT NULL DEFAULT 'pending' CHECK (upload_status IN ('pending', 'processing', 'completed', 'failed')),
  chunks_created INTEGER DEFAULT 0,
  processing_errors TEXT,
  uploaded_by UUID ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_pdf_uploads_status ON public.pdf_uploads(upload_status);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_pdf_uploads_subject ON public.pdf_uploads(subject);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_pdf_uploads_uploaded_by ON public.pdf_uploads(uploaded_by);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.pdf_uploads ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "PDF uploads readable by all authenticated users"
  ON public.pdf_uploads FOR SELECT
  TO authenticated
  USING (upload_status = 'completed');
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Admins can manage PDF uploads"
  ON public.pdf_uploads FOR ALL
  TO authenticated
  USING (auth.role() = 'service_role' OR auth.jwt() ->> 'email' LIKE '%@yourdomain.com');
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;


-- ============================================================================
-- KNOWLEDGE CHUNKS (Vector Embeddings)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.knowledge_chunks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pdf_upload_id UUID ,
  chunk_text TEXT NOT NULL,
  content_vector vector(1536), -- OpenAI ada-002 embeddings
  source_page INTEGER,
  chunk_index INTEGER,
  syllabus_node_ids UUID[] NOT NULL DEFAULT '{}',
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Vector similarity index (HNSW - works on empty tables, unlike IVFFlat)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_knowledge_chunks_vector') THEN
        DO $migration$ BEGIN
    BEGIN
        CREATE INDEX idx_knowledge_chunks_vector
        ON public.knowledge_chunks
        USING hnsw (content_vector vector_cosine_ops);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
    END IF;
EXCEPTION WHEN undefined_column THEN
    RAISE NOTICE 'content_vector column not yet available, skipping index';
END $$;

-- Full-text search index
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_knowledge_chunks_fts
  ON public.knowledge_chunks
  USING gin(to_tsvector('english', chunk_text));
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

-- Array index for syllabus mapping
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_knowledge_chunks_syllabus
  ON public.knowledge_chunks
  USING gin(syllabus_node_ids);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_knowledge_chunks_created ON public.knowledge_chunks(created_at DESC);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.knowledge_chunks ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Knowledge chunks are publicly readable"
  ON public.knowledge_chunks FOR SELECT
  TO anon, authenticated
  USING (true);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

-- ============================================================================
-- COMPREHENSIVE NOTES
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.comprehensive_notes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  topic TEXT NOT NULL,
  syllabus_node_id UUID ,
  summary TEXT, -- 100-word summary
  detailed_content TEXT, -- 250-word version
  comprehensive_content TEXT, -- 500-word version
  key_facts JSONB DEFAULT '[]',
  sources TEXT[] DEFAULT '{}', -- Source PDFs/URLs
  manim_diagram_url TEXT,
  video_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_comprehensive_notes_topic ON public.comprehensive_notes(topic);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_comprehensive_notes_syllabus ON public.comprehensive_notes(syllabus_node_id);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.comprehensive_notes ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Notes are publicly readable"
  ON public.comprehensive_notes FOR SELECT
  TO anon, authenticated
  USING (true);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;


-- ============================================================================
-- DAILY UPDATES (Current Affairs)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.daily_updates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  date DATE NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('national', 'international', 'economy', 'environment', 'science', 'polity', 'security')),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  source_url TEXT,
  importance TEXT CHECK (importance IN ('low', 'medium', 'high', 'critical')),
  syllabus_mappings UUID[] DEFAULT '{}',
  video_url TEXT,
  pdf_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_daily_updates_date ON public.daily_updates(date DESC);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_daily_updates_category ON public.daily_updates(category);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_daily_updates_importance ON public.daily_updates(importance);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;
DO $migration$ BEGIN
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_daily_updates_syllabus ON public.daily_updates USING gin(syllabus_mappings);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        ALTER TABLE public.daily_updates ENABLE ROW LEVEL SECURITY;
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Daily updates are publicly readable"
  ON public.daily_updates FOR SELECT
  TO anon, authenticated
  USING (true);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
    END;
END $migration$;

COMMENT ON TABLE public.syllabus_nodes IS 'UPSC syllabus taxonomy (GS1-4, CSAT, Essay) with hierarchical structure';
COMMENT ON TABLE public.pdf_uploads IS 'Uploaded UPSC reference books and study materials';
COMMENT ON TABLE public.knowledge_chunks IS 'Text chunks with vector embeddings for RAG search';
COMMENT ON TABLE public.comprehensive_notes IS 'AI-generated notes at multiple detail levels';
COMMENT ON TABLE public.daily_updates IS 'Daily current affairs updates mapped to syllabus';

COMMENT ON TABLE public.syllabus_nodes IS 'UPSC syllabus taxonomy (GS1-4, CSAT, Essay) with hierarchical structure';
COMMENT ON TABLE public.pdf_uploads IS 'Uploaded UPSC reference books and study materials';
COMMENT ON TABLE public.knowledge_chunks IS 'Text chunks with vector embeddings for RAG search';
COMMENT ON TABLE public.comprehensive_notes IS 'AI-generated notes at multiple detail levels';
COMMENT ON TABLE public.daily_updates IS 'Daily current affairs updates mapped to syllabus';
