-- Migration: 020_storage_buckets.sql
-- Description: Create storage buckets for PDF uploads and media
-- Story: 1.5 - PDF Upload Admin Interface
-- Date: December 27, 2025

-- ============================================================================
-- STORAGE BUCKETS
-- ============================================================================

-- Create bucket for knowledge base PDFs (if not exists)
DO $migration$ BEGIN
    BEGIN
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'knowledge-base-pdfs',
  'knowledge-base-pdfs',
  false,
  524288000, -- 500MB in bytes
  ARRAY['application/pdf']
)
ON CONFLICT (id) DO UPDATE SET
  file_size_limit = 524288000,
  allowed_mime_types = ARRAY['application/pdf'];
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Create bucket for video renders
DO $migration$ BEGIN
    BEGIN
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'video-renders',
  'video-renders',
  true,
  1073741824, -- 1GB in bytes
  ARRAY['video/mp4', 'video/webm']
)
ON CONFLICT (id) DO UPDATE SET
  file_size_limit = 1073741824;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- Create bucket for user uploads (avatars, answer images, etc.)
DO $migration$ BEGIN
    BEGIN
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'user-uploads',
  'user-uploads',
  false,
  10485760, -- 10MB in bytes
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
)
ON CONFLICT (id) DO UPDATE SET
  file_size_limit = 10485760;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================================================
-- RLS POLICIES FOR STORAGE
-- ============================================================================

-- knowledge-base-pdfs: Only admins can upload, no public read


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Admin can upload to knowledge-base-pdfs"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'knowledge-base-pdfs'
  AND EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE user_id = auth.uid() AND role = 'admin'
  )
);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;



DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Admin can read knowledge-base-pdfs"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'knowledge-base-pdfs'
  AND EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE user_id = auth.uid() AND role = 'admin'
  )
);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;



DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Admin can delete from knowledge-base-pdfs"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'knowledge-base-pdfs'
  AND EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE user_id = auth.uid() AND role = 'admin'
  )
);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- video-renders: Public read, admin write


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Public can read video-renders"
ON storage.objects FOR SELECT
TO anon, authenticated
USING (bucket_id = 'video-renders');
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;



DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Service role can manage video-renders"
ON storage.objects FOR ALL
TO service_role
USING (bucket_id = 'video-renders')
WITH CHECK (bucket_id = 'video-renders');
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- user-uploads: Users can manage their own uploads


DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can upload to user-uploads"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'user-uploads'
  AND (storage.foldername(name))[1] = auth.uid()::text
);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;



DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can read own user-uploads"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'user-uploads'
  AND (storage.foldername(name))[1] = auth.uid()::text
);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;



DO $migration$ BEGIN
    BEGIN
        CREATE POLICY "Users can delete own user-uploads"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'user-uploads'
  AND (storage.foldername(name))[1] = auth.uid()::text
);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
        WHEN insufficient_privilege THEN NULL;
        WHEN OTHERS THEN NULL;
    END;
END $migration$;

-- ============================================================================
-- COMMENTS
-- ============================================================================

-- COMMENT ON TABLE storage.buckets IS 'Supabase storage buckets for file uploads';
DO $migration$ BEGIN
    BEGIN
        COMMENT ON TABLE storage.buckets IS 'Supabase storage buckets for file uploads';
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;
END $migration$;


