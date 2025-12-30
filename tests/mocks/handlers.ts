/**
 * Mock Handlers for VPS Services
 */

import { http, HttpResponse } from 'msw';

// Manim Renderer Mock
http.post('http://89.117.60.144:5000/render', () => {
  return HttpResponse.json({
    sceneId: 'mock-scene-123',
    status: 'completed',
    outputUrl: '/mock-videos/scene-123.mp4',
  });
});

// Revideo Renderer Mock
http.post('http://89.117.60.144:5001/render', () => {
  return HttpResponse.json({
    renderId: 'mock-render-456',
    status: 'queued',
    outputUrl: null,
  });
});

// RAG Engine Mock
http.post('http://89.117.60.144:8101/retrieve', () => {
  return HttpResponse.json({
    chunks: [
      { content: 'Mock RAG result 1 about Indian history', score: 0.95, metadata: { source_file: 'test.pdf', page: 1, topic: 'history' } },
      { content: 'Mock RAG result 2 about medieval period', score: 0.87, metadata: { source_file: 'test2.pdf', page: 5, topic: 'history' } },
    ],
    confidence: 0.91,
    sources: ['test.pdf', 'test2.pdf'],
  });
});

// Video Orchestrator Mock
http.post('http://89.117.60.144:8103/render', () => {
  return HttpResponse.json({
    jobId: 'mock-job-789',
    status: 'queued',
    progress: 0,
  });
});

// Notes Generator Mock
http.post('http://89.117.60.144:8104/generate_notes', () => {
  return HttpResponse.json({
    notesId: 'mock-notes-101',
    status: 'completed',
    content: 'Mock generated notes content...',
    sections: [
      { title: 'Introduction', content: 'Introduction text...', keyPoints: ['Point 1', 'Point 2'] },
    ],
  });
});

// Health check mocks
http.get('http://89.117.60.144:5000/health', () => HttpResponse.json({ status: 'ok' }));
http.get('http://89.117.60.144:5001/health', () => HttpResponse.json({ status: 'ok' }));
http.get('http://89.117.60.144:8101/health', () => HttpResponse.json({ status: 'ok' }));
http.get('http://89.117.60.144:8102/health', () => HttpResponse.json({ status: 'ok' }));
http.get('http://89.117.60.144:8103/health', () => HttpResponse.json({ status: 'ok' }));
http.get('http://89.117.60.144:8104/health', () => HttpResponse.json({ status: 'ok' }));
