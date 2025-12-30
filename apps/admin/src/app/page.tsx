'use client';

import Link from 'next/link';

export default function AdminDashboard() {
  const stats = [
    { label: 'Total Users', value: '1,247', change: '+12% this week', color: 'blue', icon: '👥' },
    { label: 'Active Subscriptions', value: '892', change: '71.5% conversion', color: 'green', icon: '✨' },
    { label: 'Videos Generated', value: '3,456', change: 'This month', color: 'purple', icon: '🎬' },
    { label: 'Queue Pending', value: '23', change: 'Avg wait: 5 min', color: 'orange', icon: '⏳' },
  ];

  const quickActions = [
    { href: '/queue/monitoring', title: 'Queue Monitor', desc: 'View and manage video generation queue', color: 'blue', icon: '📊' },
    { href: '/knowledge-base', title: 'Upload Content', desc: 'Add PDFs and study materials to knowledge base', color: 'purple', icon: '📚' },
    { href: '/ai-settings', title: 'AI Providers', desc: 'Configure AI models and providers', color: 'indigo', icon: '🤖' },
    { href: '/ads-management', title: 'Ads Management', desc: 'Configure ad placements and revenue', color: 'green', icon: '💰' },
    { href: '/system-status', title: 'System Status', desc: 'Monitor VPS and service health', color: 'teal', icon: '🔒' },
    { href: '#', title: 'User Analytics', desc: 'View user engagement and learning metrics', color: 'pink', icon: '📈' },
  ];

  return (
    <div className="p-8 min-h-screen">
      {/* Header - Apple Style */}
      <header className="mb-10">
        <div className="flex items-center gap-4 mb-3">
          <div 
            className="w-14 h-14 rounded-2xl flex items-center justify-center"
            style={{
              background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
              boxShadow: '0 8px 24px rgba(102, 126, 234, 0.4)'
            }}
          >
            <span className="text-2xl">🏠</span>
          </div>
          <div>
            <h1 className="text-3xl font-bold text-white tracking-tight">Admin Dashboard</h1>
            <p className="text-gray-400 text-sm mt-1">Monitor and manage your UPSC PrepX-AI platform</p>
          </div>
        </div>
      </header>

      {/* Stats Grid - Neumorphism Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5 mb-10">
        {stats.map((stat, i) => (
          <div 
            key={i}
            className="relative p-6 rounded-2xl overflow-hidden"
            style={{
              background: `linear-gradient(135deg, rgba(${
                stat.color === 'blue' ? '0, 122, 255' : 
                stat.color === 'green' ? '52, 199, 89' : 
                stat.color === 'purple' ? '175, 82, 222' : 
                '255, 149, 0'
              }, 0.1) 0%, rgba(30, 30, 50, 0.5) 100%)`,
              boxShadow: '8px 8px 20px rgba(0, 0, 0, 0.4), -4px -4px 12px rgba(255, 255, 255, 0.02), inset 0 0 0 1px rgba(255, 255, 255, 0.05)'
            }}
          >
            <div 
              className="absolute top-0 left-0 right-0 h-1"
              style={{
                background: stat.color === 'blue' ? '#007aff' : 
                           stat.color === 'green' ? '#34c759' : 
                           stat.color === 'purple' ? '#af52de' : 
                           '#ff9500'
              }}
            ></div>
            <div className="flex items-start justify-between">
              <div>
                <p className="text-gray-400 text-sm mb-2">{stat.label}</p>
                <p 
                  className="text-3xl font-bold"
                  style={{
                    color: stat.color === 'blue' ? '#007aff' : 
                           stat.color === 'green' ? '#34c759' : 
                           stat.color === 'purple' ? '#af52de' : 
                           '#ff9500'
                  }}
                >
                  {stat.value}
                </p>
                <p className={`text-sm mt-2 ${stat.change.includes('+') ? 'text-green-400' : 'text-gray-500'}`}>
                  {stat.change}
                </p>
              </div>
              <span className="text-3xl opacity-40">{stat.icon}</span>
            </div>
          </div>
        ))}
      </div>

      {/* Quick Actions - Apple Style Cards */}
      <h2 className="text-xl font-semibold text-white mb-5">Quick Actions</h2>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        {quickActions.map((action, i) => (
          <Link 
            key={i}
            href={action.href}
            className="group p-6 rounded-2xl transition-all duration-300 hover:-translate-y-1"
            style={{
              background: 'rgba(30, 30, 50, 0.4)',
              boxShadow: '8px 8px 16px rgba(0, 0, 0, 0.4), -4px -4px 12px rgba(255, 255, 255, 0.02), inset 0 0 0 1px rgba(255, 255, 255, 0.04)',
            }}
          >
            <div className="flex items-start gap-4">
              <div 
                className="w-12 h-12 rounded-xl flex items-center justify-center text-2xl"
                style={{
                  background: `linear-gradient(135deg, ${
                    action.color === 'blue' ? 'rgba(0, 122, 255, 0.2)' : 
                    action.color === 'green' ? 'rgba(52, 199, 89, 0.2)' : 
                    action.color === 'purple' ? 'rgba(175, 82, 222, 0.2)' : 
                    action.color === 'indigo' ? 'rgba(88, 86, 214, 0.2)' :
                    action.color === 'teal' ? 'rgba(90, 200, 250, 0.2)' :
                    'rgba(255, 45, 85, 0.2)'
                  } 0%, rgba(30, 30, 50, 0.3) 100%)`,
                  boxShadow: '3px 3px 8px rgba(0, 0, 0, 0.3), -2px -2px 6px rgba(255, 255, 255, 0.02)'
                }}
              >
                {action.icon}
              </div>
              <div className="flex-1">
                <h3 
                  className="text-lg font-semibold mb-1 transition-colors group-hover:text-white"
                  style={{
                    color: action.color === 'blue' ? '#007aff' : 
                           action.color === 'green' ? '#34c759' : 
                           action.color === 'purple' ? '#af52de' : 
                           action.color === 'indigo' ? '#5856d6' :
                           action.color === 'teal' ? '#5ac8fa' :
                           '#ff2d55'
                  }}
                >
                  {action.title}
                </h3>
                <p className="text-gray-500 text-sm">{action.desc}</p>
              </div>
            </div>
          </Link>
        ))}
      </div>

      {/* System Health */}
      <div className="mt-10">
        <h2 className="text-xl font-semibold text-white mb-5">System Health</h2>
        <div 
          className="p-6 rounded-2xl"
          style={{
            background: 'rgba(30, 30, 50, 0.4)',
            boxShadow: '8px 8px 16px rgba(0, 0, 0, 0.4), -4px -4px 12px rgba(255, 255, 255, 0.02), inset 0 0 0 1px rgba(255, 255, 255, 0.04)'
          }}
        >
          <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
            {[
              { name: 'VPS Server', status: 'Online', ip: '89.117.60.144' },
              { name: 'Supabase', status: 'Connected', ip: 'Cloud' },
              { name: 'Manim Renderer', status: 'Online', ip: 'Port 5000' },
              { name: 'RAG Service', status: 'Online', ip: 'Port 8101' },
            ].map((service, i) => (
              <div key={i} className="flex items-center gap-3">
                <div 
                  className="w-3 h-3 rounded-full animate-pulse"
                  style={{ backgroundColor: '#34c759', boxShadow: '0 0 8px rgba(52, 199, 89, 0.5)' }}
                ></div>
                <div>
                  <p className="text-white font-medium text-sm">{service.name}</p>
                  <p className="text-gray-500 text-xs">{service.ip}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
