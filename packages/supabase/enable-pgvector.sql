-- Run this in Supabase SQL Editor (supabase.com/dashboard -> SQL Editor)
-- This enables the pgvector extension which is pre-installed in Supabase

-- Enable the vector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Verify it's installed
SELECT * FROM pg_extension WHERE extname = 'vector';

-- Test that vector type works
SELECT '[1,2,3]'::vector;
