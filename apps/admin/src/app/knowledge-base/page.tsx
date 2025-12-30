'use client';

import { useState, useCallback, useEffect } from 'react';
import { createClient } from '@/lib/supabase/client';
import { useDropzone } from 'react-dropzone';
import { format } from 'date-fns';

// Match database schema from 003_knowledge_base_tables.sql
interface PdfUpload {
  id: string;
  filename: string;
  storage_path: string;
  subject: string | null;
  book_title: string | null;
  author: string | null;
  edition: string | null;
  upload_status: 'pending' | 'processing' | 'completed' | 'failed';
  chunks_created: number;
  processing_errors: string | null;
  uploaded_by: string | null;
  created_at: string;
  updated_at: string;
}

interface SyllabusNode {
  id: string;
  name: string;
  slug: string;
  paper: string;
}

const SUBJECTS = [
  'Polity',
  'History',
  'Geography',
  'Economy',
  'Environment',
  'Science & Technology',
  'International Relations',
  'Ethics',
  'Current Affairs',
  'CSAT',
  'Essay',
];

export default function KnowledgeBasePage() {
  const supabase = createClient();

  const [uploads, setUploads] = useState<PdfUpload[]>([]);
  const [syllabusNodes, setSyllabusNodes] = useState<SyllabusNode[]>([]);
  const [isUploading, setIsUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [selectedFiles, setSelectedFiles] = useState<File[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filterSubject, setFilterSubject] = useState<string>('');
  const [filterStatus, setFilterStatus] = useState<string>('');
  const [searchQuery, setSearchQuery] = useState<string>('');

  const [metadata, setMetadata] = useState({
    subject: '',
    book_title: '',
    author: '',
    edition: '',
    syllabus_node_ids: [] as string[],
  });

  // Fetch uploads from database
  const fetchUploads = useCallback(async () => {
    setIsLoading(true);
    setError(null);

    try {
      let query = supabase
        .from('pdf_uploads')
        .select('*')
        .order('created_at', { ascending: false });

      if (filterSubject) {
        query = query.eq('subject', filterSubject);
      }
      if (filterStatus) {
        query = query.eq('upload_status', filterStatus);
      }
      if (searchQuery) {
        query = query.ilike('filename', `%${searchQuery}%`);
      }

      const { data, error: fetchError } = await query;

      if (fetchError) {
        throw fetchError;
      }

      setUploads(data as PdfUpload[]);
    } catch (err) {
      console.error('Error fetching uploads:', err);
      setError('Failed to fetch uploads. Please try again.');
    } finally {
      setIsLoading(false);
    }
  }, [supabase, filterSubject, filterStatus, searchQuery]);

  // Fetch syllabus nodes for mapping
  const fetchSyllabusNodes = useCallback(async () => {
    try {
      const { data, error: fetchError } = await supabase
        .from('syllabus_nodes')
        .select('id, name, slug, paper')
        .order('paper', { ascending: true });

      if (fetchError) {
        console.error('Error fetching syllabus nodes:', fetchError);
        return;
      }

      setSyllabusNodes(data as SyllabusNode[]);
    } catch (err) {
      console.error('Error fetching syllabus nodes:', err);
    }
  }, [supabase]);

  // Initial fetch
  useEffect(() => {
    fetchUploads();
    fetchSyllabusNodes();
  }, [fetchUploads, fetchSyllabusNodes]);

  // Auto-refresh every 30 seconds
  useEffect(() => {
    const interval = setInterval(() => {
      fetchUploads();
    }, 30000);
    return () => clearInterval(interval);
  }, [fetchUploads]);

  const onDrop = useCallback((acceptedFiles: File[], rejectedFiles: any[]) => {
    if (rejectedFiles.length > 0) {
      const errors = rejectedFiles.map(f => {
        if (f.errors[0]?.code === 'file-too-large') {
          return `${f.file.name}: File is too large (max 500MB)`;
        }
        if (f.errors[0]?.code === 'file-invalid-type') {
          return `${f.file.name}: Only PDF files are allowed`;
        }
        return `${f.file.name}: ${f.errors[0]?.message}`;
      });
      setError(errors.join('\n'));
      return;
    }
    setSelectedFiles(acceptedFiles);
    setError(null);
  }, []);

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: { 'application/pdf': ['.pdf'] },
    maxSize: 500 * 1024 * 1024, // 500MB
    multiple: true,
  });

  const handleUpload = async () => {
    if (selectedFiles.length === 0) {
      setError('Please select at least one PDF file');
      return;
    }
    if (!metadata.subject) {
      setError('Please select a subject');
      return;
    }

    setIsUploading(true);
    setUploadProgress(0);
    setError(null);

    const totalFiles = selectedFiles.length;
    let successCount = 0;
    let failedFiles: string[] = [];

    for (let i = 0; i < totalFiles; i++) {
      const file = selectedFiles[i];
      const progressBase = (i / totalFiles) * 100;
      setUploadProgress(Math.round(progressBase + 10));

      try {
        // Generate unique storage path
        const timestamp = Date.now();
        const safeName = file.name.replace(/[^a-zA-Z0-9.-]/g, '_');
        const storagePath = `uploads/${timestamp}-${safeName}`;

        // Upload to Supabase Storage
        setUploadProgress(Math.round(progressBase + 30));
        const { error: uploadError } = await supabase.storage
          .from('knowledge-base-pdfs')
          .upload(storagePath, file, {
            cacheControl: '3600',
            upsert: false,
          });

        if (uploadError) {
          // If bucket doesn't exist, create it (admin only)
          if (uploadError.message.includes('Bucket not found')) {
            throw new Error('Storage bucket not configured. Please contact administrator.');
          }
          throw uploadError;
        }

        // Create database record
        setUploadProgress(Math.round(progressBase + 70));
        const { error: dbError } = await supabase
          .from('pdf_uploads')
          .insert({
            filename: file.name,
            storage_path: storagePath,
            subject: metadata.subject,
            book_title: metadata.book_title || null,
            author: metadata.author || null,
            edition: metadata.edition || null,
            upload_status: 'pending',
            chunks_created: 0,
          });

        if (dbError) {
          // Cleanup uploaded file if DB insert fails
          await supabase.storage.from('knowledge-base-pdfs').remove([storagePath]);
          throw dbError;
        }

        successCount++;
        setUploadProgress(Math.round(((i + 1) / totalFiles) * 100));
      } catch (err: any) {
        console.error(`Upload failed for ${file.name}:`, err);
        failedFiles.push(`${file.name}: ${err.message || 'Unknown error'}`);
      }
    }

    setIsUploading(false);
    setSelectedFiles([]);

    if (failedFiles.length > 0) {
      setError(`${successCount}/${totalFiles} files uploaded successfully.\nFailed:\n${failedFiles.join('\n')}`);
    } else {
      setError(null);
    }

    // Reset metadata
    setMetadata({
      subject: '',
      book_title: '',
      author: '',
      edition: '',
      syllabus_node_ids: [],
    });

    fetchUploads();
  };

  const handleReprocess = async (uploadId: string) => {
    if (!confirm('Are you sure you want to reprocess this PDF?')) {
      return;
    }

    try {
      // Update status to pending
      const { error: updateError } = await supabase
        .from('pdf_uploads')
        .update({
          upload_status: 'pending',
          processing_errors: null,
        })
        .eq('id', uploadId);

      if (updateError) {
        throw updateError;
      }

      // TODO: Trigger processing via Edge Function (Story 1.6)
      // await supabase.functions.invoke('process_pdf_pipe', {
      //   body: { pdf_upload_id: uploadId },
      // });

      fetchUploads();
    } catch (err: any) {
      console.error('Reprocess failed:', err);
      setError(`Failed to reprocess: ${err.message}`);
    }
  };

  const handleDelete = async (upload: PdfUpload) => {
    if (!confirm(`Are you sure you want to delete "${upload.filename}"?`)) {
      return;
    }

    try {
      // Delete from storage
      const { error: storageError } = await supabase.storage
        .from('knowledge-base-pdfs')
        .remove([upload.storage_path]);

      if (storageError) {
        console.warn('Storage delete failed:', storageError);
      }

      // Delete from database
      const { error: dbError } = await supabase
        .from('pdf_uploads')
        .delete()
        .eq('id', upload.id);

      if (dbError) {
        throw dbError;
      }

      fetchUploads();
    } catch (err: any) {
      console.error('Delete failed:', err);
      setError(`Failed to delete: ${err.message}`);
    }
  };

  const getStatusBadge = (status: string) => {
    const styles: Record<string, string> = {
      pending: 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30',
      processing: 'bg-blue-500/20 text-blue-400 border-blue-500/30 animate-pulse',
      completed: 'bg-green-500/20 text-green-400 border-green-500/30',
      failed: 'bg-red-500/20 text-red-400 border-red-500/30',
    };
    return styles[status] || styles.pending;
  };

  const formatFileSize = (bytes: number) => {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  };

  return (
    <div className="min-h-screen bg-slate-900 p-6">
      <header className="mb-8">
        <h1 className="text-3xl font-bold text-white mb-2">Knowledge Base Management</h1>
        <p className="text-gray-400">Upload and manage PDF documents for the RAG knowledge base</p>
      </header>

      {/* Error Display */}
      {error && (
        <div className="mb-6 p-4 bg-red-500/10 border border-red-500/30 rounded-xl text-red-400 whitespace-pre-line">
          {error}
          <button
            onClick={() => setError(null)}
            className="ml-4 text-red-300 hover:text-red-100"
          >
            Dismiss
          </button>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Upload Section */}
        <div className="lg:col-span-1">
          <div className="bg-slate-800/50 border border-white/10 p-6 rounded-xl">
            <h2 className="text-xl font-bold text-white mb-4">Upload PDFs</h2>

            {/* Dropzone */}
            <div
              {...getRootProps()}
              className={`border-2 border-dashed rounded-xl p-8 text-center cursor-pointer transition-all ${
                isDragActive
                  ? 'border-blue-500 bg-blue-500/10'
                  : 'border-white/20 hover:border-blue-500/50'
              }`}
            >
              <input {...getInputProps()} />
              <svg className="w-12 h-12 mx-auto mb-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
              </svg>
              {isDragActive ? (
                <p className="text-blue-400">Drop files here...</p>
              ) : (
                <>
                  <p className="text-gray-300 mb-2">Drag & drop PDFs here</p>
                  <p className="text-sm text-gray-500">or click to browse</p>
                  <p className="text-xs text-gray-600 mt-2">Max 500MB per file</p>
                </>
              )}
            </div>

            {/* Selected Files */}
            {selectedFiles.length > 0 && (
              <div className="mt-4 p-3 bg-slate-700/50 rounded-lg">
                <p className="text-sm text-gray-400 mb-2">{selectedFiles.length} file(s) selected:</p>
                <ul className="space-y-1 max-h-32 overflow-y-auto">
                  {selectedFiles.map((file, i) => (
                    <li key={i} className="text-sm text-gray-300 flex justify-between">
                      <span className="truncate mr-2">{file.name}</span>
                      <span className="text-gray-500">{formatFileSize(file.size)}</span>
                    </li>
                  ))}
                </ul>
              </div>
            )}

            {/* Metadata Form */}
            <div className="mt-6 space-y-4">
              <div>
                <label className="block text-sm text-gray-400 mb-1">Subject *</label>
                <select
                  value={metadata.subject}
                  onChange={(e) => setMetadata({ ...metadata, subject: e.target.value })}
                  className="w-full px-4 py-2 bg-slate-700/50 border border-white/10 rounded-lg text-white focus:border-blue-500 focus:outline-none"
                >
                  <option value="">Select subject...</option>
                  {SUBJECTS.map((subject) => (
                    <option key={subject} value={subject}>{subject}</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm text-gray-400 mb-1">Book Title</label>
                <input
                  type="text"
                  value={metadata.book_title}
                  onChange={(e) => setMetadata({ ...metadata, book_title: e.target.value })}
                  placeholder="e.g., Indian Polity"
                  className="w-full px-4 py-2 bg-slate-700/50 border border-white/10 rounded-lg text-white focus:border-blue-500 focus:outline-none"
                />
              </div>

              <div>
                <label className="block text-sm text-gray-400 mb-1">Author</label>
                <input
                  type="text"
                  value={metadata.author}
                  onChange={(e) => setMetadata({ ...metadata, author: e.target.value })}
                  placeholder="e.g., M. Laxmikanth"
                  className="w-full px-4 py-2 bg-slate-700/50 border border-white/10 rounded-lg text-white focus:border-blue-500 focus:outline-none"
                />
              </div>

              <div>
                <label className="block text-sm text-gray-400 mb-1">Edition</label>
                <input
                  type="text"
                  value={metadata.edition}
                  onChange={(e) => setMetadata({ ...metadata, edition: e.target.value })}
                  placeholder="e.g., 6th Edition (2023)"
                  className="w-full px-4 py-2 bg-slate-700/50 border border-white/10 rounded-lg text-white focus:border-blue-500 focus:outline-none"
                />
              </div>

              {/* Upload Progress */}
              {isUploading && (
                <div className="mt-4">
                  <div className="flex justify-between text-sm text-gray-400 mb-1">
                    <span>Uploading...</span>
                    <span>{uploadProgress}%</span>
                  </div>
                  <div className="w-full bg-slate-700 rounded-full h-2">
                    <div
                      className="bg-blue-500 h-2 rounded-full transition-all duration-300"
                      style={{ width: `${uploadProgress}%` }}
                    />
                  </div>
                </div>
              )}

              <button
                onClick={handleUpload}
                disabled={isUploading || selectedFiles.length === 0}
                className="w-full py-3 px-4 bg-blue-600 hover:bg-blue-700 disabled:bg-slate-600 disabled:cursor-not-allowed text-white font-medium rounded-lg transition-colors"
              >
                {isUploading ? `Uploading... ${uploadProgress}%` : 'Upload PDFs'}
              </button>
            </div>
          </div>

          {/* Stats Card */}
          <div className="mt-6 bg-slate-800/50 border border-white/10 p-6 rounded-xl">
            <h3 className="text-lg font-semibold text-white mb-4">Statistics</h3>
            <div className="space-y-3">
              <div className="flex justify-between">
                <span className="text-gray-400">Total Documents</span>
                <span className="text-white font-medium">{uploads.length}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-400">Completed</span>
                <span className="text-green-400 font-medium">
                  {uploads.filter(u => u.upload_status === 'completed').length}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-400">Processing</span>
                <span className="text-blue-400 font-medium">
                  {uploads.filter(u => u.upload_status === 'processing').length}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-400">Pending</span>
                <span className="text-yellow-400 font-medium">
                  {uploads.filter(u => u.upload_status === 'pending').length}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-400">Failed</span>
                <span className="text-red-400 font-medium">
                  {uploads.filter(u => u.upload_status === 'failed').length}
                </span>
              </div>
              <div className="flex justify-between pt-3 border-t border-white/10">
                <span className="text-gray-400">Total Chunks</span>
                <span className="text-white font-medium">
                  {uploads.reduce((sum, u) => sum + (u.chunks_created || 0), 0).toLocaleString()}
                </span>
              </div>
            </div>
          </div>
        </div>

        {/* Uploads Table */}
        <div className="lg:col-span-2">
          <div className="bg-slate-800/50 border border-white/10 p-6 rounded-xl">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6">
              <h2 className="text-xl font-bold text-white">Uploaded Documents</h2>

              <div className="flex flex-wrap gap-3">
                {/* Search */}
                <input
                  type="text"
                  placeholder="Search filename..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="px-3 py-2 bg-slate-700/50 border border-white/10 rounded-lg text-white text-sm focus:border-blue-500 focus:outline-none"
                />

                {/* Filter by Subject */}
                <select
                  value={filterSubject}
                  onChange={(e) => setFilterSubject(e.target.value)}
                  className="px-3 py-2 bg-slate-700/50 border border-white/10 rounded-lg text-white text-sm focus:border-blue-500 focus:outline-none"
                >
                  <option value="">All Subjects</option>
                  {SUBJECTS.map((subject) => (
                    <option key={subject} value={subject}>{subject}</option>
                  ))}
                </select>

                {/* Filter by Status */}
                <select
                  value={filterStatus}
                  onChange={(e) => setFilterStatus(e.target.value)}
                  className="px-3 py-2 bg-slate-700/50 border border-white/10 rounded-lg text-white text-sm focus:border-blue-500 focus:outline-none"
                >
                  <option value="">All Status</option>
                  <option value="pending">Pending</option>
                  <option value="processing">Processing</option>
                  <option value="completed">Completed</option>
                  <option value="failed">Failed</option>
                </select>

                {/* Refresh Button */}
                <button
                  onClick={fetchUploads}
                  disabled={isLoading}
                  className="px-4 py-2 text-sm text-blue-400 hover:bg-blue-500/10 rounded-lg transition-colors disabled:opacity-50"
                >
                  {isLoading ? 'Loading...' : 'Refresh'}
                </button>
              </div>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="text-left text-sm text-gray-400 border-b border-white/10">
                    <th className="pb-3 pr-4">Filename</th>
                    <th className="pb-3 pr-4">Subject</th>
                    <th className="pb-3 pr-4">Author</th>
                    <th className="pb-3 pr-4">Status</th>
                    <th className="pb-3 pr-4">Chunks</th>
                    <th className="pb-3 pr-4">Uploaded</th>
                    <th className="pb-3">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {uploads.map((upload) => (
                    <tr key={upload.id} className="border-b border-white/5 hover:bg-white/5">
                      <td className="py-3 pr-4">
                        <div className="text-white truncate max-w-[200px]" title={upload.filename}>
                          {upload.filename}
                        </div>
                        {upload.book_title && (
                          <div className="text-xs text-gray-500 truncate">{upload.book_title}</div>
                        )}
                      </td>
                      <td className="py-3 pr-4 text-gray-300">{upload.subject || '-'}</td>
                      <td className="py-3 pr-4 text-gray-300">{upload.author || '-'}</td>
                      <td className="py-3 pr-4">
                        <span className={`px-2 py-1 rounded-full text-xs border ${getStatusBadge(upload.upload_status)}`}>
                          {upload.upload_status}
                        </span>
                        {upload.processing_errors && (
                          <div className="text-xs text-red-400 mt-1 truncate max-w-[120px]" title={upload.processing_errors}>
                            {upload.processing_errors}
                          </div>
                        )}
                      </td>
                      <td className="py-3 pr-4 text-gray-300">
                        {upload.chunks_created > 0 ? upload.chunks_created.toLocaleString() : '-'}
                      </td>
                      <td className="py-3 pr-4 text-gray-400 text-sm">
                        {format(new Date(upload.created_at), 'MMM d, yyyy HH:mm')}
                      </td>
                      <td className="py-3">
                        <div className="flex gap-2">
                          {upload.upload_status === 'failed' && (
                            <button
                              onClick={() => handleReprocess(upload.id)}
                              className="px-3 py-1 text-xs text-blue-400 hover:bg-blue-500/10 rounded transition-colors"
                            >
                              Reprocess
                            </button>
                          )}
                          <button
                            onClick={() => handleDelete(upload)}
                            className="px-3 py-1 text-xs text-red-400 hover:bg-red-500/10 rounded transition-colors"
                          >
                            Delete
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>

              {isLoading && uploads.length === 0 && (
                <div className="text-center py-12 text-gray-400">
                  <div className="animate-spin w-8 h-8 border-2 border-blue-500 border-t-transparent rounded-full mx-auto mb-4" />
                  Loading documents...
                </div>
              )}

              {!isLoading && uploads.length === 0 && (
                <div className="text-center py-12 text-gray-400">
                  <svg className="w-16 h-16 mx-auto mb-4 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                  </svg>
                  <p>No documents uploaded yet</p>
                  <p className="text-sm mt-2">Upload PDFs using the form on the left</p>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
