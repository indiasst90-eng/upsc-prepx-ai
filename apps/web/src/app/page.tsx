'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { getSupabaseBrowserClient } from '@/lib/supabase/client';
import { motion } from 'framer-motion';
import { BookOpen, Brain, Video, FileText, Target, Users, Star, ChevronRight, Shield, Zap, Award } from 'lucide-react';

const features = [
  {
    icon: Brain,
    title: 'AI-Powered Notes',
    description: 'Generate comprehensive study notes from any UPSC topic using advanced AI',
    color: 'from-blue-500 to-cyan-500',
  },
  {
    icon: Video,
    title: 'Video Explanations',
    description: 'Auto-generated video explanations for complex topics and PYQs',
    color: 'from-purple-500 to-pink-500',
  },
  {
    icon: Target,
    title: 'Practice MCQs',
    description: '10,000+ questions with detailed explanations and performance analytics',
    color: 'from-orange-500 to-red-500',
  },
  {
    icon: FileText,
    title: 'Answer Writing',
    description: 'AI evaluation of your answers with detailed feedback and scoring',
    color: 'from-green-500 to-emerald-500',
  },
];

const stats = [
  { value: '50K+', label: 'Active Users' },
  { value: '10K+', label: 'Questions' },
  { value: '500+', label: 'Video Lessons' },
  { value: '98%', label: 'Satisfaction Rate' },
];

export default function LandingPage() {
  const router = useRouter();
  const [isLoading, setIsLoading] = useState(true);
  const [isAuthenticated, setIsAuthenticated] = useState(false);

  useEffect(() => {
    const checkAuth = async () => {
      const supabase = getSupabaseBrowserClient();
      const { data: { session } } = await supabase.auth.getSession();
      
      if (session) {
        setIsAuthenticated(true);
        // Redirect authenticated users to dashboard
        router.push('/syllabus');
      } else {
        setIsLoading(false);
      }
    };

    checkAuth();
  }, [router]);

  if (isLoading && !isAuthenticated) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-slate-950">
        <div className="w-12 h-12 border-2 border-blue-500 border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  if (isAuthenticated) {
    return null; // Will redirect
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-slate-950 via-slate-900 to-slate-950">
      {/* Navigation */}
      <nav className="fixed top-0 w-full z-50 bg-slate-950/80 backdrop-blur-xl border-b border-white/5">
        <div className="max-w-7xl mx-auto px-6 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center">
              <BookOpen className="w-5 h-5 text-white" />
            </div>
            <span className="text-xl font-bold text-white">UPSC PrepX-AI</span>
          </div>
          
          <div className="flex items-center gap-4">
            <Link 
              href="/login" 
              className="px-4 py-2 text-gray-300 hover:text-white transition-colors"
            >
              Sign In
            </Link>
            <Link 
              href="/signup" 
              className="px-6 py-2.5 bg-gradient-to-r from-blue-600 to-purple-600 text-white rounded-lg font-medium hover:from-blue-700 hover:to-purple-700 transition-all"
            >
              Start Free Trial
            </Link>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="pt-32 pb-20 px-6">
        <div className="max-w-7xl mx-auto text-center">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
          >
            <div className="inline-flex items-center gap-2 px-4 py-2 bg-blue-500/10 border border-blue-500/20 rounded-full text-blue-400 text-sm mb-8">
              <Zap className="w-4 h-4" />
              <span>AI-Powered UPSC Preparation Platform</span>
            </div>
            
            <h1 className="text-5xl md:text-7xl font-bold text-white mb-6 leading-tight">
              Ace Your UPSC Journey
              <br />
              <span className="bg-gradient-to-r from-blue-400 via-purple-400 to-pink-400 bg-clip-text text-transparent">
                With AI Intelligence
              </span>
            </h1>
            
            <p className="text-xl text-gray-400 max-w-2xl mx-auto mb-10">
              The most advanced AI-powered platform for UPSC Civil Services preparation. 
              Generate notes, practice questions, and get personalized feedback.
            </p>
            
            <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
              <Link 
                href="/signup" 
                className="flex items-center gap-2 px-8 py-4 bg-gradient-to-r from-blue-600 to-purple-600 text-white rounded-xl font-semibold text-lg hover:from-blue-700 hover:to-purple-700 transition-all shadow-lg shadow-blue-500/25"
              >
                Start 1-Day Free Trial
                <ChevronRight className="w-5 h-5" />
              </Link>
              <Link 
                href="/pricing" 
                className="flex items-center gap-2 px-8 py-4 border border-white/20 text-white rounded-xl font-semibold text-lg hover:bg-white/5 transition-all"
              >
                View Plans
              </Link>
            </div>
          </motion.div>
          
          {/* Stats */}
          <motion.div
            initial={{ opacity: 0, y: 40 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.3 }}
            className="grid grid-cols-2 md:grid-cols-4 gap-8 mt-20 pt-10 border-t border-white/5"
          >
            {stats.map((stat, index) => (
              <div key={index} className="text-center">
                <div className="text-3xl md:text-4xl font-bold text-white mb-2">{stat.value}</div>
                <div className="text-gray-400">{stat.label}</div>
              </div>
            ))}
          </motion.div>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-20 px-6 bg-slate-900/50">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-3xl md:text-4xl font-bold text-white mb-4">
              Everything You Need to Crack UPSC
            </h2>
            <p className="text-gray-400 max-w-2xl mx-auto">
              Comprehensive tools and AI-powered features designed specifically for UPSC aspirants
            </p>
          </div>
          
          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
            {features.map((feature, index) => (
              <motion.div
                key={index}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, delay: index * 0.1 }}
                className="p-6 bg-slate-800/50 border border-white/5 rounded-2xl hover:border-white/10 transition-all group"
              >
                <div className={`w-12 h-12 rounded-xl bg-gradient-to-br ${feature.color} flex items-center justify-center mb-4 group-hover:scale-110 transition-transform`}>
                  <feature.icon className="w-6 h-6 text-white" />
                </div>
                <h3 className="text-xl font-semibold text-white mb-2">{feature.title}</h3>
                <p className="text-gray-400">{feature.description}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Trust Section */}
      <section className="py-20 px-6">
        <div className="max-w-7xl mx-auto">
          <div className="grid md:grid-cols-3 gap-8">
            <div className="flex items-start gap-4 p-6 bg-slate-800/30 rounded-2xl border border-white/5">
              <div className="w-12 h-12 rounded-xl bg-green-500/10 flex items-center justify-center flex-shrink-0">
                <Shield className="w-6 h-6 text-green-400" />
              </div>
              <div>
                <h3 className="text-lg font-semibold text-white mb-2">Enterprise Security</h3>
                <p className="text-gray-400 text-sm">Bank-grade encryption and secure data storage for your information</p>
              </div>
            </div>
            
            <div className="flex items-start gap-4 p-6 bg-slate-800/30 rounded-2xl border border-white/5">
              <div className="w-12 h-12 rounded-xl bg-blue-500/10 flex items-center justify-center flex-shrink-0">
                <Users className="w-6 h-6 text-blue-400" />
              </div>
              <div>
                <h3 className="text-lg font-semibold text-white mb-2">Expert Support</h3>
                <p className="text-gray-400 text-sm">24/7 support from UPSC experts and AI assistants</p>
              </div>
            </div>
            
            <div className="flex items-start gap-4 p-6 bg-slate-800/30 rounded-2xl border border-white/5">
              <div className="w-12 h-12 rounded-xl bg-purple-500/10 flex items-center justify-center flex-shrink-0">
                <Award className="w-6 h-6 text-purple-400" />
              </div>
              <div>
                <h3 className="text-lg font-semibold text-white mb-2">Proven Results</h3>
                <p className="text-gray-400 text-sm">Join thousands of successful candidates who cleared UPSC with us</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-20 px-6">
        <div className="max-w-4xl mx-auto text-center">
          <div className="p-12 bg-gradient-to-br from-blue-600/20 to-purple-600/20 border border-white/10 rounded-3xl">
            <h2 className="text-3xl md:text-4xl font-bold text-white mb-4">
              Ready to Start Your UPSC Journey?
            </h2>
            <p className="text-gray-300 mb-8 max-w-xl mx-auto">
              Get 1 day of free premium access. No credit card required.
            </p>
            <Link 
              href="/signup" 
              className="inline-flex items-center gap-2 px-8 py-4 bg-white text-slate-900 rounded-xl font-semibold text-lg hover:bg-gray-100 transition-all"
            >
              Create Free Account
              <ChevronRight className="w-5 h-5" />
            </Link>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-12 px-6 border-t border-white/5">
        <div className="max-w-7xl mx-auto flex flex-col md:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center">
              <BookOpen className="w-4 h-4 text-white" />
            </div>
            <span className="text-gray-400">© 2025 UPSC PrepX-AI. All rights reserved.</span>
          </div>
          
          <div className="flex items-center gap-6 text-gray-400 text-sm">
            <Link href="/pricing" className="hover:text-white transition-colors">Pricing</Link>
            <Link href="/login" className="hover:text-white transition-colors">Sign In</Link>
            <Link href="/signup" className="hover:text-white transition-colors">Sign Up</Link>
          </div>
        </div>
      </footer>
    </div>
  );
}
