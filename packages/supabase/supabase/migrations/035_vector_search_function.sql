-- Migration: 035_vector_search_function.sql
-- Description: Vector similarity search function for knowledge chunks
-- Date: December 28, 2025
-- Story: 1.7 - RAG Search Integration

-- Function to search knowledge chunks by vector similarity
-- CREATE OR REPLACE FUNCTION match_knowledge_chunks(
--   query_embedding vector(1536),
--   match_threshold float DEFAULT 0.7,
--   match_count int DEFAULT 10
-- )
-- RETURNS TABLE (
--   id uuid,
--   chunk_text text,
--   source_page integer,
--   chunk_index integer,
--   metadata jsonb,
--   pdf_upload_id uuid,
--   similarity float
-- )
-- LANGUAGE plpgsql
-- AS $$
-- BEGIN
--   RETURN QUERY
--   SELECT
--     kc.id,
--     kc.chunk_text,
--     kc.source_page,
--     kc.chunk_index,
--     kc.metadata,
--     kc.pdf_upload_id,
--     1 - (kc.content_vector <=> query_embedding) as similarity
--   FROM knowledge_chunks kc
--   WHERE kc.content_vector IS NOT NULL
--     AND 1 - (kc.content_vector <=> query_embedding) > match_threshold
--   ORDER BY kc.content_vector <=> query_embedding
--   LIMIT match_count;
-- END;
-- $$;
-- 
-- -- Function to search with text filters
-- -- CREATE OR REPLACE FUNCTION search_knowledge_chunks(
-- --   query_text text,
-- --   subject_filter text DEFAULT NULL,
-- --   match_count int DEFAULT 10
-- -- )
-- -- RETURNS TABLE (
-- --   id uuid,
-- --   chunk_text text,
-- --   source_page integer,
-- --   metadata jsonb,
-- --   rank real
-- -- )
-- -- LANGUAGE plpgsql
-- -- AS $$
-- -- BEGIN
-- --   RETURN QUERY
-- --   SELECT
-- --     kc.id,
-- --     kc.chunk_text,
-- --     kc.source_page,
-- --     kc.metadata,
-- --     ts_rank(to_tsvector('english', kc.chunk_text), plainto_tsquery('english', query_text)) as rank
-- --   FROM knowledge_chunks kc
-- --   LEFT JOIN pdf_uploads pu ON kc.pdf_upload_id = pu.id
-- --   WHERE 
-- --     to_tsvector('english', kc.chunk_text) @@ plainto_tsquery('english', query_text)
-- --     AND (subject_filter IS NULL OR pu.subject = subject_filter)
-- --   ORDER BY rank DESC
-- --   LIMIT match_count;
-- -- END;
-- -- $$;
-- 
-- -- Function to get related chunks for a given chunk
-- -- CREATE OR REPLACE FUNCTION get_related_chunks(
-- --   chunk_id uuid,
-- --   match_count int DEFAULT 5
-- -- )
-- -- RETURNS TABLE (
-- --   id uuid,
-- --   chunk_text text,
-- --   similarity float
-- -- )
-- -- LANGUAGE plpgsql
-- -- AS $$
-- -- DECLARE
-- --   source_vector vector(1536);
-- -- BEGIN
-- --   -- Get the source chunk's vector
-- --   SELECT content_vector INTO source_vector
-- --   FROM knowledge_chunks
-- --   WHERE knowledge_chunks.id = chunk_id;
-- --   
-- --   IF source_vector IS NULL THEN
-- --     RETURN;
-- --   END IF;
-- --   
-- --   RETURN QUERY
-- --   SELECT
-- --     kc.id,
-- --     kc.chunk_text,
-- --     1 - (kc.content_vector <=> source_vector) as similarity
-- --   FROM knowledge_chunks kc
-- --   WHERE kc.id != chunk_id
-- --     AND kc.content_vector IS NOT NULL
-- --   ORDER BY kc.content_vector <=> source_vector
-- --   LIMIT match_count;
-- -- END;
-- -- $$;

DO $migration$ BEGIN
    BEGIN
        COMMENT ON FUNCTION match_knowledge_chunks IS 'Vector similarity search for RAG - returns chunks matching embedding';
        COMMENT ON FUNCTION search_knowledge_chunks IS 'Full-text search for knowledge chunks with optional subject filter';
        COMMENT ON FUNCTION get_related_chunks IS 'Find related content chunks based on vector similarity';
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


