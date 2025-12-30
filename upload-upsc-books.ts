/**
 * UPSC Books Bulk Upload Script
 * 
 * Uploads all PDFs from E:\UPSC MATERIAL to Supabase storage
 * and creates database records for processing.
 * 
 * Directory Structure Expected:
 * E:\UPSC MATERIAL\
 * ├── GS1\ (History, Geography, Heritage)
 * ├── GS2\ (Polity, Governance, IR)
 * ├── GS3\ (Economy, Environment, S&T)
 * ├── GS4\ (Ethics)
 * ├── CSAT\
 * └── syllabus\
 * 
 * Usage: npx ts-node --esm upload-upsc-books.ts
 */

import * as fs from 'fs';
import * as path from 'path';
import { createClient } from '@supabase/supabase-js';

// Configuration
const UPSC_MATERIAL_PATH = 'E:\\UPSC MATERIAL';
const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL || 'http://89.117.60.144:54321';
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU';
const STORAGE_BUCKET = 'knowledge-base-pdfs';

// Subject mapping based on directory names
const SUBJECT_MAPPING: Record<string, string> = {
  'gs1': 'History & Geography',
  'gs2': 'Polity & Governance',
  'gs3': 'Economy & Environment',
  'gs4': 'Ethics',
  'csat': 'CSAT',
  'syllabus': 'Syllabus',
  'history': 'History',
  'geography': 'Geography',
  'polity': 'Polity',
  'economy': 'Economy',
  'environment': 'Environment',
  'ethics': 'Ethics',
  'science': 'Science & Technology',
  'ir': 'International Relations',
  'security': 'Security',
};

// Initialize Supabase client
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

interface UploadResult {
  filename: string;
  status: 'success' | 'failed' | 'skipped';
  message?: string;
  uploadId?: string;
}

// Get subject from directory path
function getSubjectFromPath(filePath: string): string {
  const normalizedPath = filePath.toLowerCase().replace(/\\/g, '/');
  
  for (const [key, subject] of Object.entries(SUBJECT_MAPPING)) {
    if (normalizedPath.includes(`/${key}/`) || normalizedPath.includes(`/${key}\\`)) {
      return subject;
    }
  }
  
  return 'General Studies';
}

// Extract book title from filename
function extractBookTitle(filename: string): string {
  return filename
    .replace(/\.pdf$/i, '')
    .replace(/[_-]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

// Find all PDF files in a directory recursively
function findPDFFiles(dir: string): string[] {
  const pdfFiles: string[] = [];
  
  try {
    const items = fs.readdirSync(dir);
    
    for (const item of items) {
      const fullPath = path.join(dir, item);
      const stat = fs.statSync(fullPath);
      
      if (stat.isDirectory()) {
        pdfFiles.push(...findPDFFiles(fullPath));
      } else if (item.toLowerCase().endsWith('.pdf')) {
        pdfFiles.push(fullPath);
      }
    }
  } catch (error) {
    console.error(`Error reading directory ${dir}:`, error);
  }
  
  return pdfFiles;
}

// Upload a single PDF file
async function uploadPDF(filePath: string): Promise<UploadResult> {
  const filename = path.basename(filePath);
  
  try {
    // Check if file already uploaded
    const { data: existing } = await supabase
      .from('pdf_uploads')
      .select('id')
      .eq('filename', filename)
      .single();
    
    if (existing) {
      return {
        filename,
        status: 'skipped',
        message: 'Already uploaded',
        uploadId: existing.id,
      };
    }
    
    // Read file
    const fileBuffer = fs.readFileSync(filePath);
    const fileSizeMB = fileBuffer.length / (1024 * 1024);
    
    console.log(`Uploading: ${filename} (${fileSizeMB.toFixed(2)} MB)`);
    
    // Generate storage path
    const timestamp = Date.now();
    const safeName = filename.replace(/[^a-zA-Z0-9.-]/g, '_');
    const storagePath = `uploads/${timestamp}-${safeName}`;
    
    // Upload to storage
    const { error: uploadError } = await supabase.storage
      .from(STORAGE_BUCKET)
      .upload(storagePath, fileBuffer, {
        cacheControl: '3600',
        contentType: 'application/pdf',
        upsert: false,
      });
    
    if (uploadError) {
      throw new Error(`Storage upload failed: ${uploadError.message}`);
    }
    
    // Get subject and metadata
    const subject = getSubjectFromPath(filePath);
    const bookTitle = extractBookTitle(filename);
    
    // Create database record
    const { data: insertData, error: dbError } = await supabase
      .from('pdf_uploads')
      .insert({
        filename,
        storage_path: storagePath,
        subject,
        book_title: bookTitle,
        upload_status: 'pending',
        chunks_created: 0,
      })
      .select('id')
      .single();
    
    if (dbError) {
      // Cleanup storage if DB insert fails
      await supabase.storage.from(STORAGE_BUCKET).remove([storagePath]);
      throw new Error(`Database insert failed: ${dbError.message}`);
    }
    
    return {
      filename,
      status: 'success',
      message: `Uploaded to ${storagePath}`,
      uploadId: insertData.id,
    };
    
  } catch (error) {
    return {
      filename,
      status: 'failed',
      message: error instanceof Error ? error.message : 'Unknown error',
    };
  }
}

// Trigger processing for pending uploads
async function triggerProcessing(): Promise<void> {
  console.log('\nTriggering PDF processing...');
  
  try {
    const response = await fetch(`${process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000'}/api/knowledge-base/process`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({}),
    });
    
    if (response.ok) {
      const result = await response.json();
      console.log(`Processing triggered: ${result.processed || 0} PDFs queued`);
    } else {
      console.warn('Failed to trigger processing:', await response.text());
    }
  } catch (error) {
    console.warn('Could not trigger processing (API may not be running):', error);
    console.log('Run the processing manually: POST /api/knowledge-base/process');
  }
}

// Main function
async function main() {
  console.log('='.repeat(60));
  console.log('UPSC Books Bulk Upload Script');
  console.log('='.repeat(60));
  console.log(`Source: ${UPSC_MATERIAL_PATH}`);
  console.log(`Target: ${SUPABASE_URL}`);
  console.log('');
  
  // Check if source directory exists
  if (!fs.existsSync(UPSC_MATERIAL_PATH)) {
    console.error(`ERROR: Directory not found: ${UPSC_MATERIAL_PATH}`);
    console.log('Please ensure the UPSC MATERIAL folder exists.');
    process.exit(1);
  }
  
  // Ensure storage bucket exists
  console.log('Checking storage bucket...');
  const { data: buckets } = await supabase.storage.listBuckets();
  const bucketExists = buckets?.some(b => b.name === STORAGE_BUCKET);
  
  if (!bucketExists) {
    console.log('Creating storage bucket...');
    const { error: bucketError } = await supabase.storage.createBucket(STORAGE_BUCKET, {
      public: false,
      fileSizeLimit: 500 * 1024 * 1024, // 500MB
    });
    
    if (bucketError) {
      console.error('Failed to create bucket:', bucketError.message);
      console.log('Please create the bucket manually in Supabase Studio.');
    }
  }
  
  // Find all PDF files
  console.log('Scanning for PDF files...');
  const pdfFiles = findPDFFiles(UPSC_MATERIAL_PATH);
  console.log(`Found ${pdfFiles.length} PDF files\n`);
  
  if (pdfFiles.length === 0) {
    console.log('No PDF files found. Exiting.');
    process.exit(0);
  }
  
  // Upload each file
  const results: UploadResult[] = [];
  let successCount = 0;
  let failedCount = 0;
  let skippedCount = 0;
  
  for (let i = 0; i < pdfFiles.length; i++) {
    const filePath = pdfFiles[i];
    console.log(`[${i + 1}/${pdfFiles.length}] Processing...`);
    
    const result = await uploadPDF(filePath);
    results.push(result);
    
    if (result.status === 'success') {
      successCount++;
      console.log(`  ✓ SUCCESS: ${result.filename}`);
    } else if (result.status === 'skipped') {
      skippedCount++;
      console.log(`  ○ SKIPPED: ${result.filename} (${result.message})`);
    } else {
      failedCount++;
      console.log(`  ✗ FAILED: ${result.filename} - ${result.message}`);
    }
  }
  
  // Summary
  console.log('\n' + '='.repeat(60));
  console.log('UPLOAD SUMMARY');
  console.log('='.repeat(60));
  console.log(`Total files:  ${pdfFiles.length}`);
  console.log(`Success:      ${successCount}`);
  console.log(`Skipped:      ${skippedCount}`);
  console.log(`Failed:       ${failedCount}`);
  
  // Save results to file
  const resultsFile = path.join(process.cwd(), `upload-results-${Date.now()}.json`);
  fs.writeFileSync(resultsFile, JSON.stringify(results, null, 2));
  console.log(`\nResults saved to: ${resultsFile}`);
  
  // Trigger processing if any new uploads
  if (successCount > 0) {
    await triggerProcessing();
  }
  
  console.log('\nDone!');
}

// Run
main().catch(console.error);
