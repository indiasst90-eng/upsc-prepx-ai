'use client';

import Link from 'next/link';
import { useAuth } from '@/app/providers/AuthProvider';
import { useEffect, useState } from 'react';
import { getSupabaseBrowserClient } from '@/lib/supabase/client';

interface UserStats {
  notesGenerated: number;
  mcqsAttempted: number;
  mockTests: number;
  studyStreak: number;
}

export default function DashboardPage() {
  const { user } = useAuth();
  const [stats, setStats] = useState<UserStats>({
    notesGenerated: 0,
    mcqsAttempted: 0,
    mockTests: 0,
    studyStreak: 0,
  });

  useEffect(() => {
    const fetchStats = async () => {
      if (!user) return;
      const supabase = getSupabaseBrowserClient();
      
      try {
        // Fetch user stats from multiple tables
        const [notesRes, mcqsRes, testsRes] = await Promise.all([
          supabase.from('comprehensive_notes').select('id', { count: 'exact' }).eq('user_id', user.id),
          supabase.from('mcq_attempts').select('id', { count: 'exact' }).eq('user_id', user.id),
          supabase.from('mock_test_attempts').select('id', { count: 'exact' }).eq('user_id', user.id),
        ]);

        setStats({
          notesGenerated: notesRes.count || 0,
          mcqsAttempted: mcqsRes.count || 0,
          mockTests: testsRes.count || 0,
          studyStreak: 0, // TODO: Implement streak tracking
        });
      } catch (error) {
        console.error('Error fetching stats:', error);
      }
    };

    fetchStats();
  }, [user]);

  const features = [
    { 
      href: '/notes', 
      icon: 'upload', 
      title: 'Upload Content', 
      subtitle: 'PDFs, Images & More',
      bgColor: 'bg-blue-500',
      iconBg: 'bg-blue-100',
      iconColor: 'text-blue-600'
    },
    { 
      href: '/notes', 
      icon: 'sparkles', 
      title: 'Generate Notes', 
      subtitle: 'AI-Powered Summaries',
      bgColor: 'bg-purple-500',
      iconBg: 'bg-purple-100',
      iconColor: 'text-purple-600'
    },
    { 
      href: '/practice', 
      icon: 'quiz', 
      title: 'Practice MCQs', 
      subtitle: 'Smart Questions',
      bgColor: 'bg-teal-500',
      iconBg: 'bg-teal-100',
      iconColor: 'text-teal-600'
    },
    { 
      href: '/news', 
      icon: 'newspaper', 
      title: 'Current Affairs', 
      subtitle: 'Daily Updates',
      bgColor: 'bg-green-500',
      iconBg: 'bg-green-100',
      iconColor: 'text-green-600'
    },
  ];

  const moreFeatures = [
    { href: '/videos', icon: 'play', title: 'Video Lectures', color: 'border-l-red-500' },
    { href: '/essay', icon: 'edit', title: 'Essay Writing', color: 'border-l-indigo-500' },
    { href: '/ethics', icon: 'heart', title: 'Ethics Cases', color: 'border-l-pink-500' },
    { href: '/interview', icon: 'mic', title: 'Interview Prep', color: 'border-l-orange-500' },
    { href: '/mindmap', icon: 'brain', title: 'Mind Maps', color: 'border-l-violet-500' },
    { href: '/flashcards', icon: 'cards', title: 'Flashcards', color: 'border-l-cyan-500' },
  ];

  return (
    <div className="space-y-8">
      {/* Your Progress Section */}
      <section>
        <h2 className="text-xl font-bold text-gray-900 mb-4">Your Progress</h2>
        <div className="stats-grid">
          {/* Notes Generated */}
          <div className="progress-card">
            <div className="progress-icon progress-icon-blue">
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
            </div>
            <p className="text-3xl font-bold text-gray-900">{stats.notesGenerated}</p>
            <p className="text-sm text-gray-500">Notes Generated</p>
          </div>

          {/* MCQs Attempted */}
          <div className="progress-card">
            <div className="progress-icon progress-icon-purple">
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <p className="text-3xl font-bold text-gray-900">{stats.mcqsAttempted}</p>
            <p className="text-sm text-gray-500">MCQs Attempted</p>
          </div>

          {/* Mock Tests */}
          <div className="progress-card">
            <div className="progress-icon progress-icon-teal">
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <p className="text-3xl font-bold text-gray-900">{stats.mockTests}</p>
            <p className="text-sm text-gray-500">Mock Tests</p>
          </div>

          {/* Study Streak */}
          <div className="progress-card">
            <div className="progress-icon progress-icon-orange">
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 18.657A8 8 0 016.343 7.343S7 9 9 10c0-2 .5-5 2.986-7C14 5 16.09 5.777 17.656 7.343A7.975 7.975 0 0120 13a7.975 7.975 0 01-2.343 5.657z" />
              </svg>
            </div>
            <p className="text-3xl font-bold text-gray-900">{stats.studyStreak} days</p>
            <p className="text-sm text-gray-500">Study Streak</p>
          </div>
        </div>
      </section>

      {/* Explore Features */}
      <section>
        <h2 className="text-xl font-bold text-gray-900 mb-4">Explore Features</h2>
        <div className="feature-grid">
          {features.map((feature, idx) => (
            <Link key={idx} href={feature.href} className="feature-card group">
              <div className={`w-12 h-12 rounded-xl ${feature.iconBg} flex items-center justify-center mb-3`}>
                {feature.icon === 'upload' && (
                  <svg className={`w-6 h-6 ${feature.iconColor}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
                  </svg>
                )}
                {feature.icon === 'sparkles' && (
                  <svg className={`w-6 h-6 ${feature.iconColor}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z" />
                  </svg>
                )}
                {feature.icon === 'quiz' && (
                  <svg className={`w-6 h-6 ${feature.iconColor}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                )}
                {feature.icon === 'newspaper' && (
                  <svg className={`w-6 h-6 ${feature.iconColor}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7 16h6M7 8h6v4H7V8z" />
                  </svg>
                )}
              </div>
              <h3 className="font-semibold text-gray-900 group-hover:text-blue-600 transition-colors">{feature.title}</h3>
              <p className="text-sm text-gray-500">{feature.subtitle}</p>
            </Link>
          ))}
        </div>
      </section>

      {/* More Features - Practice Modes Style */}
      <section>
        <h2 className="text-xl font-bold text-gray-900 mb-4">Practice Modes</h2>
        <div className="space-y-3">
          {moreFeatures.map((feature, idx) => (
            <Link key={idx} href={feature.href} className={`practice-mode-card ${feature.color} group`}>
              <div className="w-10 h-10 rounded-xl bg-gray-100 flex items-center justify-center">
                {feature.icon === 'play' && (
                  <svg className="w-5 h-5 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z" />
                  </svg>
                )}
                {feature.icon === 'edit' && (
                  <svg className="w-5 h-5 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                  </svg>
                )}
                {feature.icon === 'heart' && (
                  <svg className="w-5 h-5 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
                  </svg>
                )}
                {feature.icon === 'mic' && (
                  <svg className="w-5 h-5 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z" />
                  </svg>
                )}
                {feature.icon === 'brain' && (
                  <svg className="w-5 h-5 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                  </svg>
                )}
                {feature.icon === 'cards' && (
                  <svg className="w-5 h-5 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
                  </svg>
                )}
              </div>
              <div className="flex-1">
                <h3 className="font-medium text-gray-900 group-hover:text-blue-600 transition-colors">{feature.title}</h3>
              </div>
              <svg className="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
              </svg>
            </Link>
          ))}
        </div>
      </section>

      {/* Current Affairs Carousel */}
      <section>
        <h2 className="text-xl font-bold text-gray-900 mb-4">Discover Our Features</h2>
        <div className="feature-card-green p-6 rounded-2xl">
          <div className="flex items-center justify-center mb-4">
            <div className="w-16 h-16 bg-white/20 rounded-2xl flex items-center justify-center">
              <svg className="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7 16h6M7 8h6v4H7V8z" />
              </svg>
            </div>
          </div>
          <h3 className="text-xl font-bold text-center mb-2">Current Affairs</h3>
          <p className="text-center text-white/80 text-sm">Daily updates with UPSC-focused analysis</p>
        </div>

        {/* Dots indicator */}
        <div className="flex justify-center gap-2 mt-4">
          <div className="w-2 h-2 rounded-full bg-gray-300"></div>
          <div className="w-2 h-2 rounded-full bg-gray-300"></div>
          <div className="w-2 h-2 rounded-full bg-blue-500"></div>
          <div className="w-2 h-2 rounded-full bg-gray-300"></div>
        </div>
      </section>
    </div>
  );
}
