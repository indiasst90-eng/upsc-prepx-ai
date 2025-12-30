'use client';

import Link from 'next/link';
import './globals.css';

// Metadata moved to head.tsx or page-level metadata

const navItems = [
  { href: '/', label: 'Dashboard', icon: 'M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6' },
  { href: '/knowledge-base', label: 'Knowledge Base', icon: 'M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253' },
  { href: '/queue/monitoring', label: 'Queue Monitor', icon: 'M4 6h16M4 10h16M4 14h16M4 18h16' },
  { href: '/ai-settings', label: 'AI Providers', icon: 'M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z' },
  { href: '/ads-management', label: 'Ads Management', icon: 'M11 3.055A9.001 9.001 0 1020.945 13H11V3.055z M20.488 9H15V3.512A9.025 9.025 0 0120.488 9z' },
  { href: '/system-status', label: 'System Status', icon: 'M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z' },
];

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="min-h-screen">
        <div className="flex min-h-screen">
          {/* Apple + Neumorphism Sidebar */}
          <aside 
            className="w-72 p-5 flex flex-col backdrop-blur-2xl"
            style={{
              background: 'linear-gradient(180deg, rgba(20, 20, 35, 0.95) 0%, rgba(15, 15, 25, 0.98) 100%)',
              borderRight: '1px solid rgba(255, 255, 255, 0.05)',
              boxShadow: '4px 0 24px rgba(0, 0, 0, 0.3)'
            }}
          >
            {/* Logo Area */}
            <div className="mb-10 px-2">
              <div className="flex items-center gap-3">
                <div 
                  className="w-10 h-10 rounded-xl flex items-center justify-center"
                  style={{
                    background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                    boxShadow: '0 4px 15px rgba(102, 126, 234, 0.4)'
                  }}
                >
                  <span className="text-white font-bold text-lg">U</span>
                </div>
                <div>
                  <h1 className="text-lg font-bold text-white tracking-tight">UPSC PrepX-AI</h1>
                  <p className="text-xs text-gray-500 -mt-0.5">Admin Panel</p>
                </div>
              </div>
            </div>

            {/* Navigation */}
            <nav className="space-y-2 flex-1">
              {navItems.map((item) => (
                <Link
                  key={item.href}
                  href={item.href}
                  className="flex items-center gap-3 px-4 py-3 rounded-xl text-gray-400 hover:text-white hover:bg-white/5 transition-all duration-200 group"
                >
                  <div 
                    className="w-9 h-9 rounded-xl flex items-center justify-center transition-all duration-200"
                    style={{
                      background: 'rgba(30, 30, 50, 0.5)',
                      boxShadow: '3px 3px 6px rgba(0, 0, 0, 0.3), -2px -2px 4px rgba(255, 255, 255, 0.02)'
                    }}
                  >
                    <svg className="w-5 h-5 text-gray-500 group-hover:text-blue-400 transition-colors" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d={item.icon} />
                    </svg>
                  </div>
                  <span className="font-medium text-sm">{item.label}</span>
                </Link>
              ))}
            </nav>

            {/* Footer */}
            <div 
              className="mt-4 p-4 rounded-xl"
              style={{
                background: 'rgba(20, 20, 35, 0.4)',
                boxShadow: 'inset 2px 2px 6px rgba(0, 0, 0, 0.3), inset -2px -2px 4px rgba(255, 255, 255, 0.02)'
              }}
            >
              <div className="flex items-center gap-2 mb-2">
                <div className="w-2 h-2 rounded-full bg-green-500 animate-pulse"></div>
                <span className="text-xs text-green-400 font-medium">System Online</span>
              </div>
              <div className="text-xs text-gray-600 space-y-0.5">
                <p>VPS: 89.117.60.144</p>
                <p>Supabase: Connected</p>
              </div>
            </div>
          </aside>

          {/* Main Content */}
          <main className="flex-1 overflow-auto">
            {children}
          </main>
        </div>
      </body>
    </html>
  );
}
