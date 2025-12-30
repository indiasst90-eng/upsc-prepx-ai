'use client';

/**
 * Story 8.1: PYQ Admin Upload Dashboard
 * AC 1-10: Full admin interface for uploading, processing, and managing PYQs
 */

import { useState, useEffect, useCallback } from 'react';

type PaperType = 'Prelims' | 'Mains_GS1' | 'Mains_GS2' | 'Mains_GS3' | 'Mains_GS4' | 'Essay';
type Status = 'pending' | 'processing' | 'completed' | 'failed';

interface PYQPaper {
  id: string;
  year: number;
  paper_type: PaperType;
  file_url: string;
  status: Status;
  progress: number;
  question_count?: number;
  created_at: string;
}

const PAPER_TYPES: { value: PaperType; label: string }[] = [
  { value: 'Prelims', label: 'Prelims (Paper I & II)' },
  { value: 'Mains_GS1', label: 'Mains - GS Paper I' },
  { value: 'Mains_GS2', label: 'Mains - GS Paper II' },
  { value: 'Mains_GS3', label: 'Mains - GS Paper III' },
  { value: 'Mains_GS4', label: 'Mains - GS Paper IV (Ethics)' },
  { value: 'Essay', label: 'Essay Paper' },
];

const YEARS = Array.from({ length: 30 }, (_, i) => 2024 - i);

export default function AdminPYQsPage() {
  // Upload State
  const [uploading, setUploading] = useState(false);
  const [files, setFiles] = useState<File[]>([]);
  const [year, setYear] = useState<number>(2024);
  const [paperType, setPaperType] = useState<PaperType>('Prelims');
  const [uploadProgress, setUploadProgress] = useState(0);
  
  // Papers State
  const [papers, setPapers] = useState<PYQPaper[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedPaper, setSelectedPaper] = useState<PYQPaper | null>(null);
  
  // Filters
  const [filterYear, setFilterYear] = useState<number | ''>('');
  const [filterType, setFilterType] = useState<PaperType | ''>('');
  const [filterStatus, setFilterStatus] = useState<Status | ''>('');

  // Fetch papers
  const fetchPapers = useCallback(async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams();
      if (filterYear) params.append('year', String(filterYear));
      if (filterType) params.append('paper_type', filterType);
      if (filterStatus) params.append('status', filterStatus);
      
      const res = await fetch(`/api/pyqs/papers?${params}`);
      const data = await res.json();
      if (data.success) {
        setPapers(data.papers || []);
      }
    } catch (err) {
      console.error('Failed to fetch papers:', err);
    } finally {
      setLoading(false);
    }
  }, [filterYear, filterType, filterStatus]);

  useEffect(() => {
    fetchPapers();
  }, [fetchPapers]);

  // Handle file upload
  const handleUpload = async (e: React.FormEvent) => {
    e.preventDefault();
    if (files.length === 0) return;
    
    setUploading(true);
    setUploadProgress(0);

    for (let i = 0; i < files.length; i++) {
      const file = files[i];
      const formData = new FormData();
      formData.append('file', file);
      formData.append('year', String(year));
      formData.append('paper_type', paperType);

      try {
        const res = await fetch('/api/pyqs/upload', {
          method: 'POST',
          body: formData
        });
        
        if (!res.ok) {
          const error = await res.json();
          alert(`Failed to upload ${file.name}: ${error.error || 'Unknown error'}`);
        }
      } catch (err) {
        console.error(`Upload error for ${file.name}:`, err);
      }
      
      setUploadProgress(Math.round(((i + 1) / files.length) * 100));
    }

    setUploading(false);
    setFiles([]);
    setUploadProgress(0);
    fetchPapers();
  };

  // Trigger OCR Processing
  const triggerOCR = async (paperId: string) => {
    try {
      const res = await fetch('/api/pyqs/ocr', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ paper_id: paperId })
      });
      
      if (res.ok) {
        alert('OCR processing started!');
        fetchPapers();
      } else {
        const error = await res.json();
        alert(`OCR failed: ${error.error}`);
      }
    } catch (err) {
      console.error('OCR trigger error:', err);
    }
  };

  // Generate model answers
  const generateModelAnswers = async (paperId: string) => {
    try {
      const res = await fetch('/api/pyqs/model-answers', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ paper_id: paperId })
      });
      
      if (res.ok) {
        const data = await res.json();
        alert(`Generated ${data.count || 0} model answers!`);
      } else {
        const error = await res.json();
        alert(`Model answer generation failed: ${error.error}`);
      }
    } catch (err) {
      console.error('Model answer generation error:', err);
    }
  };

  // Delete paper
  const deletePaper = async (paperId: string) => {
    if (!confirm('Are you sure you want to delete this paper and all its questions?')) return;
    
    try {
      const res = await fetch(`/api/pyqs/papers?id=${paperId}`, {
        method: 'DELETE'
      });
      
      if (res.ok) {
        fetchPapers();
        setSelectedPaper(null);
      }
    } catch (err) {
      console.error('Delete error:', err);
    }
  };

  const getStatusBadge = (status: Status) => {
    const styles: Record<Status, string> = {
      pending: 'bg-yellow-100 text-yellow-800',
      processing: 'bg-blue-100 text-blue-800',
      completed: 'bg-green-100 text-green-800',
      failed: 'bg-red-100 text-red-800',
    };
    return <span className={`px-2 py-1 rounded text-xs font-medium ${styles[status]}`}>{status}</span>;
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 py-8">
        {/* Header */}
        <header className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">PYQ Management Dashboard</h1>
          <p className="text-gray-600 mt-2">Upload, process, and manage Previous Year Questions</p>
        </header>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Upload Section */}
          <div className="lg:col-span-1">
            <div className="bg-white rounded-xl shadow-sm border p-6">
              <h2 className="text-lg font-semibold mb-4">Upload New PYQ</h2>
              
              <form onSubmit={handleUpload} className="space-y-4">
                {/* Year Selection */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Exam Year</label>
                  <select
                    value={year}
                    onChange={(e) => setYear(Number(e.target.value))}
                    className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                  >
                    {YEARS.map(y => <option key={y} value={y}>{y}</option>)}
                  </select>
                </div>

                {/* Paper Type */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Paper Type</label>
                  <select
                    value={paperType}
                    onChange={(e) => setPaperType(e.target.value as PaperType)}
                    className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                  >
                    {PAPER_TYPES.map(pt => <option key={pt.value} value={pt.value}>{pt.label}</option>)}
                  </select>
                </div>

                {/* File Upload */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">PDF Files</label>
                  <div className="border-2 border-dashed border-gray-300 rounded-lg p-4 text-center hover:border-blue-500 transition-colors">
                    <input
                      type="file"
                      accept=".pdf"
                      multiple
                      onChange={(e) => setFiles(Array.from(e.target.files || []))}
                      className="hidden"
                      id="file-upload"
                    />
                    <label htmlFor="file-upload" className="cursor-pointer">
                      <svg className="w-8 h-8 mx-auto text-gray-400 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
                      </svg>
                      <p className="text-sm text-gray-600">Click to upload PDFs</p>
                      <p className="text-xs text-gray-400 mt-1">Max 10 files, 50MB each</p>
                    </label>
                  </div>
                </div>

                {/* Selected Files */}
                {files.length > 0 && (
                  <div className="bg-gray-50 rounded-lg p-3">
                    <p className="text-sm font-medium text-gray-700 mb-2">Selected ({files.length}):</p>
                    <ul className="text-sm text-gray-600 space-y-1">
                      {files.map((f, i) => (
                        <li key={i} className="flex items-center gap-2">
                          <svg className="w-4 h-4 text-red-500" fill="currentColor" viewBox="0 0 20 20">
                            <path fillRule="evenodd" d="M4 4a2 2 0 012-2h4.586A2 2 0 0112 2.586L15.414 6A2 2 0 0116 7.414V16a2 2 0 01-2 2H6a2 2 0 01-2-2V4z" clipRule="evenodd" />
                          </svg>
                          {f.name}
                        </li>
                      ))}
                    </ul>
                  </div>
                )}

                {/* Upload Progress */}
                {uploading && uploadProgress > 0 && (
                  <div>
                    <div className="bg-gray-200 rounded-full h-2">
                      <div className="bg-blue-600 h-2 rounded-full transition-all" style={{ width: `${uploadProgress}%` }} />
                    </div>
                    <p className="text-xs text-gray-600 mt-1 text-center">{uploadProgress}% complete</p>
                  </div>
                )}

                <button
                  type="submit"
                  disabled={uploading || files.length === 0}
                  className="w-full bg-blue-600 text-white py-2.5 rounded-lg font-medium hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed transition-colors"
                >
                  {uploading ? 'Uploading...' : 'Upload & Process'}
                </button>
              </form>
            </div>

            {/* Quick Actions */}
            <div className="bg-white rounded-xl shadow-sm border p-6 mt-6">
              <h2 className="text-lg font-semibold mb-4">Quick Actions</h2>
              <div className="space-y-3">
                <button
                  onClick={() => fetch('/api/pyqs/ocr', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ process_all: true }) })}
                  className="w-full bg-purple-600 text-white py-2 rounded-lg text-sm font-medium hover:bg-purple-700 transition-colors"
                >
                  Process All Pending OCR
                </button>
                <button
                  onClick={() => fetch('/api/pyqs/model-answers', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ generate_all: true }) })}
                  className="w-full bg-green-600 text-white py-2 rounded-lg text-sm font-medium hover:bg-green-700 transition-colors"
                >
                  Generate All Model Answers
                </button>
              </div>
            </div>
          </div>

          {/* Papers List */}
          <div className="lg:col-span-2">
            <div className="bg-white rounded-xl shadow-sm border">
              {/* Filters */}
              <div className="border-b p-4">
                <div className="flex flex-wrap gap-3">
                  <select
                    value={filterYear}
                    onChange={(e) => setFilterYear(e.target.value ? Number(e.target.value) : '')}
                    className="border rounded-lg px-3 py-2 text-sm"
                  >
                    <option value="">All Years</option>
                    {YEARS.slice(0, 15).map(y => <option key={y} value={y}>{y}</option>)}
                  </select>
                  <select
                    value={filterType}
                    onChange={(e) => setFilterType(e.target.value as PaperType | '')}
                    className="border rounded-lg px-3 py-2 text-sm"
                  >
                    <option value="">All Types</option>
                    {PAPER_TYPES.map(pt => <option key={pt.value} value={pt.value}>{pt.label}</option>)}
                  </select>
                  <select
                    value={filterStatus}
                    onChange={(e) => setFilterStatus(e.target.value as Status | '')}
                    className="border rounded-lg px-3 py-2 text-sm"
                  >
                    <option value="">All Status</option>
                    <option value="pending">Pending</option>
                    <option value="processing">Processing</option>
                    <option value="completed">Completed</option>
                    <option value="failed">Failed</option>
                  </select>
                  <button onClick={fetchPapers} className="text-sm text-blue-600 hover:underline">Refresh</button>
                </div>
              </div>

              {/* Papers Table */}
              <div className="overflow-x-auto">
                {loading ? (
                  <div className="p-12 text-center">
                    <div className="animate-spin w-8 h-8 border-2 border-blue-600 border-t-transparent rounded-full mx-auto mb-4"></div>
                    <p className="text-gray-600">Loading papers...</p>
                  </div>
                ) : papers.length === 0 ? (
                  <div className="p-12 text-center">
                    <svg className="w-16 h-16 mx-auto text-gray-300 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                    </svg>
                    <h3 className="text-lg font-medium text-gray-900 mb-1">No papers found</h3>
                    <p className="text-gray-600">Upload your first PYQ paper to get started</p>
                  </div>
                ) : (
                  <table className="w-full">
                    <thead className="bg-gray-50">
                      <tr>
                        <th className="text-left px-4 py-3 text-sm font-medium text-gray-600">Year</th>
                        <th className="text-left px-4 py-3 text-sm font-medium text-gray-600">Paper Type</th>
                        <th className="text-left px-4 py-3 text-sm font-medium text-gray-600">Status</th>
                        <th className="text-left px-4 py-3 text-sm font-medium text-gray-600">Questions</th>
                        <th className="text-left px-4 py-3 text-sm font-medium text-gray-600">Actions</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y">
                      {papers.map((paper) => (
                        <tr key={paper.id} className="hover:bg-gray-50">
                          <td className="px-4 py-3 text-sm font-medium text-gray-900">{paper.year}</td>
                          <td className="px-4 py-3 text-sm text-gray-600">
                            {PAPER_TYPES.find(pt => pt.value === paper.paper_type)?.label || paper.paper_type}
                          </td>
                          <td className="px-4 py-3">
                            <div className="flex items-center gap-2">
                              {getStatusBadge(paper.status)}
                              {paper.status === 'processing' && (
                                <span className="text-xs text-gray-500">{paper.progress}%</span>
                              )}
                            </div>
                          </td>
                          <td className="px-4 py-3 text-sm text-gray-600">
                            {paper.question_count || 0}
                          </td>
                          <td className="px-4 py-3">
                            <div className="flex items-center gap-2">
                              {paper.status === 'pending' && (
                                <button
                                  onClick={() => triggerOCR(paper.id)}
                                  className="text-xs bg-purple-100 text-purple-700 px-2 py-1 rounded hover:bg-purple-200"
                                >
                                  Run OCR
                                </button>
                              )}
                              {paper.status === 'completed' && (
                                <button
                                  onClick={() => generateModelAnswers(paper.id)}
                                  className="text-xs bg-green-100 text-green-700 px-2 py-1 rounded hover:bg-green-200"
                                >
                                  Gen Answers
                                </button>
                              )}
                              <a
                                href={paper.file_url}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="text-xs text-blue-600 hover:underline"
                              >
                                View PDF
                              </a>
                              <button
                                onClick={() => deletePaper(paper.id)}
                                className="text-xs text-red-600 hover:underline"
                              >
                                Delete
                              </button>
                            </div>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
