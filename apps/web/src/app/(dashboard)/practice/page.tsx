'use client';

import { useState, useEffect } from 'react';
import { getSupabaseBrowserClient } from '@/lib/supabase/client';

interface PracticeQuestion {
  id: string;
  question: string;
  year: number;
  paper: string;
  difficulty: 'easy' | 'medium' | 'hard';
  marks: number;
  topic: string;
  tags: string[];
  estimatedTime: number; // minutes
  wordLimit: number;
  type: 'pyq' | 'current_affairs' | 'case_study';
}

const TABS = ['GS1', 'GS2', 'GS3', 'GS4', 'Essay'];
const SUB_TABS = ['Practice', 'Analysis', 'Progress'];
const QUESTION_TYPES = ['All', 'PYQ', 'Current Affairs', 'Case Studies'];
const YEARS = ['All Years', '2024', '2023', '2022', '2021', '2020'];

// Demo questions matching reference
const demoQuestions: PracticeQuestion[] = [
  {
    id: '1',
    question: 'Discuss the impact of climate change on the monsoon patterns in India and its implications for agriculture and water resources.',
    year: 2024,
    paper: 'GS1',
    difficulty: 'medium',
    marks: 15,
    topic: 'Geography',
    tags: ['Climate Change', 'Monsoon', 'Agriculture'],
    estimatedTime: 20,
    wordLimit: 250,
    type: 'pyq',
  },
  {
    id: '2',
    question: 'Examine the factors responsible for the location of primary, secondary, and tertiary sector industries in various parts of the world.',
    year: 2024,
    paper: 'GS1',
    difficulty: 'hard',
    marks: 20,
    topic: 'Geography',
    tags: ['Industries', 'Economic Geography'],
    estimatedTime: 25,
    wordLimit: 300,
    type: 'pyq',
  },
  {
    id: '3',
    question: 'Analyze the role of Indian Diaspora in shaping India\'s foreign policy in the 21st century.',
    year: 2023,
    paper: 'GS1',
    difficulty: 'medium',
    marks: 15,
    topic: 'International Relations',
    tags: ['Diaspora', 'Foreign Policy'],
    estimatedTime: 20,
    wordLimit: 250,
    type: 'pyq',
  },
  {
    id: '4',
    question: 'Discuss the recent developments in India-Middle East-Europe Economic Corridor (IMEC) and its strategic significance.',
    year: 2024,
    paper: 'GS2',
    difficulty: 'medium',
    marks: 15,
    topic: 'International Relations',
    tags: ['IMEC', 'Connectivity', 'Strategic'],
    estimatedTime: 20,
    wordLimit: 250,
    type: 'current_affairs',
  },
];

export default function PracticePage() {
  const [selectedTab, setSelectedTab] = useState('GS1');
  const [selectedSubTab, setSelectedSubTab] = useState('Practice');
  const [selectedType, setSelectedType] = useState('All');
  const [selectedYear, setSelectedYear] = useState('All Years');
  const [questions, setQuestions] = useState<PracticeQuestion[]>(demoQuestions);

  // Filter questions based on selections
  const filteredQuestions = questions.filter(q => {
    if (selectedTab !== 'Essay' && q.paper !== selectedTab) return false;
    if (selectedType !== 'All') {
      if (selectedType === 'PYQ' && q.type !== 'pyq') return false;
      if (selectedType === 'Current Affairs' && q.type !== 'current_affairs') return false;
      if (selectedType === 'Case Studies' && q.type !== 'case_study') return false;
    }
    if (selectedYear !== 'All Years' && q.year.toString() !== selectedYear) return false;
    return true;
  });

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-slate-800 text-white px-6 py-8 -mx-6 -mt-6 mb-6 lg:-mx-6 lg:-mt-6">
        <h1 className="text-2xl font-bold text-center mb-1">Answer Writing Coach</h1>
        <p className="text-gray-400 text-center text-sm">AI-Powered UPSC Mains Practice</p>
        
        {/* Paper Tabs */}
        <div className="flex justify-center gap-2 mt-6">
          {TABS.map((tab) => (
            <button
              key={tab}
              onClick={() => setSelectedTab(tab)}
              className={`px-4 py-2 rounded-full text-sm font-medium transition-all ${
                selectedTab === tab
                  ? 'bg-green-500 text-white'
                  : 'bg-slate-700 text-gray-300 hover:bg-slate-600'
              }`}
            >
              {tab}
            </button>
          ))}
        </div>
      </div>

      {/* Sub Tabs */}
      <div className="flex border-b border-gray-200 mb-6">
        {SUB_TABS.map((tab) => (
          <button
            key={tab}
            onClick={() => setSelectedSubTab(tab)}
            className={`flex-1 py-3 text-sm font-medium transition-all border-b-2 ${
              selectedSubTab === tab
                ? 'text-green-600 border-green-500'
                : 'text-gray-500 border-transparent hover:text-gray-700'
            }`}
          >
            <div className="flex items-center justify-center gap-2">
              {tab === 'Practice' && (
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
                </svg>
              )}
              {tab === 'Analysis' && (
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                </svg>
              )}
              {tab === 'Progress' && (
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
                </svg>
              )}
              {tab}
            </div>
          </button>
        ))}
      </div>

      {selectedSubTab === 'Practice' && (
        <>
          {/* Practice Questions Header */}
          <div className="flex items-center gap-2 mb-4">
            <div className="w-6 h-6 bg-gradient-to-br from-green-400 to-green-600 rounded flex items-center justify-center">
              <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
            </div>
            <h2 className="text-lg font-bold text-gray-900">Practice Questions</h2>
          </div>

          {/* Question Type Filter Chips */}
          <div className="flex flex-wrap gap-2 mb-4">
            {QUESTION_TYPES.map((type) => (
              <button
                key={type}
                onClick={() => setSelectedType(type)}
                className={`px-4 py-2 rounded-full text-sm font-medium transition-all ${
                  selectedType === type
                    ? 'bg-green-500 text-white'
                    : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                }`}
              >
                {type}
              </button>
            ))}
          </div>

          {/* Year Filter Pills */}
          <div className="mb-6">
            <span className="text-sm text-gray-500 mr-3">Year:</span>
            <div className="inline-flex flex-wrap gap-2">
              {YEARS.map((year) => (
                <button
                  key={year}
                  onClick={() => setSelectedYear(year)}
                  className={`px-4 py-1.5 rounded-full text-sm font-medium transition-all ${
                    selectedYear === year
                      ? 'bg-amber-400 text-gray-900'
                      : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                  }`}
                >
                  {year}
                </button>
              ))}
            </div>
          </div>

          {/* Questions List */}
          <div className="space-y-4">
            {filteredQuestions.length > 0 ? (
              filteredQuestions.map((question) => (
                <div key={question.id} className="question-card">
                  {/* Year and Difficulty */}
                  <div className="flex items-center justify-between mb-3">
                    <div className="flex items-center gap-2">
                      <svg className="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
                      </svg>
                      <span className="text-sm font-medium text-gray-700">{question.year}</span>
                      <span className={`badge-${question.difficulty}`}>
                        {question.difficulty.toUpperCase()}
                      </span>
                    </div>
                    <span className="text-blue-600 font-semibold">{question.marks} marks</span>
                  </div>

                  {/* Question Text */}
                  <p className="text-gray-900 mb-4 leading-relaxed">{question.question}</p>

                  {/* Tags */}
                  <div className="flex flex-wrap gap-2 mb-4">
                    {question.tags.map((tag, idx) => (
                      <span key={idx} className="filter-chip">
                        {tag}
                      </span>
                    ))}
                  </div>

                  {/* Meta Info */}
                  <div className="flex items-center gap-6 text-sm text-gray-500">
                    <div className="flex items-center gap-1">
                      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                      </svg>
                      <span>{question.estimatedTime} min</span>
                    </div>
                    <div className="flex items-center gap-1">
                      <span className="font-medium">Tr</span>
                      <span>{question.wordLimit} words</span>
                    </div>
                  </div>
                </div>
              ))
            ) : (
              <div className="text-center py-12">
                <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
                  <svg className="w-8 h-8 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                  </svg>
                </div>
                <h3 className="text-lg font-medium text-gray-900 mb-1">No questions found</h3>
                <p className="text-gray-500">Try adjusting your filters</p>
              </div>
            )}
          </div>
        </>
      )}

      {selectedSubTab === 'Analysis' && (
        <div className="text-center py-12">
          <div className="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <svg className="w-8 h-8 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
            </svg>
          </div>
          <h3 className="text-lg font-medium text-gray-900 mb-1">Answer Analysis</h3>
          <p className="text-gray-500 mb-4">Get AI-powered feedback on your answers</p>
          <button className="btn-primary">Start Analysis</button>
        </div>
      )}

      {selectedSubTab === 'Progress' && (
        <div className="space-y-6">
          {/* Progress Stats */}
          <div className="card p-6">
            <h3 className="font-bold text-gray-900 mb-4">Your Progress</h3>
            <div className="grid grid-cols-3 gap-4 text-center">
              <div>
                <p className="text-3xl font-bold text-blue-600">0</p>
                <p className="text-sm text-gray-500">MCQs Attempted</p>
              </div>
              <div>
                <p className="text-3xl font-bold text-green-600">0%</p>
                <p className="text-sm text-gray-500">Overall Accuracy</p>
              </div>
              <div>
                <p className="text-3xl font-bold text-purple-600">0</p>
                <p className="text-sm text-gray-500">Question Banks</p>
              </div>
            </div>
          </div>

          {/* Practice Modes */}
          <div>
            <h3 className="font-bold text-gray-900 mb-4">Practice Modes</h3>
            <div className="space-y-3">
              <div className="practice-mode-card border-l-emerald-500">
                <div className="w-10 h-10 rounded-xl bg-emerald-100 flex items-center justify-center">
                  <svg className="w-5 h-5 text-emerald-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
                  </svg>
                </div>
                <div className="flex-1">
                  <h4 className="font-medium text-gray-900">Topic-wise Practice</h4>
                  <p className="text-sm text-gray-500">Focus on specific subjects or chapters</p>
                </div>
                <svg className="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                </svg>
              </div>

              <div className="practice-mode-card border-l-blue-500">
                <div className="w-10 h-10 rounded-xl bg-blue-100 flex items-center justify-center">
                  <svg className="w-5 h-5 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                  </svg>
                </div>
                <div className="flex-1">
                  <h4 className="font-medium text-gray-900">Mixed Practice</h4>
                  <p className="text-sm text-gray-500">Random questions from all topics</p>
                </div>
                <svg className="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                </svg>
              </div>

              <div className="practice-mode-card border-l-amber-500">
                <div className="w-10 h-10 rounded-xl bg-amber-100 flex items-center justify-center">
                  <svg className="w-5 h-5 text-amber-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                </div>
                <div className="flex-1">
                  <h4 className="font-medium text-gray-900">Timed Practice</h4>
                  <p className="text-sm text-gray-500">Prelims simulation mode</p>
                </div>
                <svg className="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                </svg>
              </div>

              <div className="practice-mode-card border-l-purple-500">
                <div className="w-10 h-10 rounded-xl bg-purple-100 flex items-center justify-center">
                  <svg className="w-5 h-5 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
                  </svg>
                </div>
                <div className="flex-1">
                  <h4 className="font-medium text-gray-900">Adaptive Mode</h4>
                  <p className="text-sm text-gray-500">AI adjusts difficulty based on performance</p>
                </div>
                <svg className="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                </svg>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
