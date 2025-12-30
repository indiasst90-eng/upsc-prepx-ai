'use client';

import { useState, useEffect } from 'react';

interface AdPlacement {
  id: string;
  placement_id: string;
  name: string;
  location: string;
  ad_type: 'banner' | 'interstitial' | 'native' | 'rewarded';
  enabled: boolean;
  frequency: number;
}

interface AdProvider {
  id: string;
  provider_id: string;
  name: string;
  publisher_id: string;
  app_id: string;
  enabled: boolean;
}

interface AdConfig {
  id: string;
  global_enabled: boolean;
  hide_for_pro: boolean;
  ad_free_trial_days: number;
  min_screens_between_ads: number;
}

interface AdRevenue {
  date: string;
  impressions: number;
  clicks: number;
  revenue: number;
}

const API_BASE = process.env.NEXT_PUBLIC_WEB_URL || 'http://localhost:3000';

export default function AdsManagementPage() {
  const [placements, setPlacements] = useState<AdPlacement[]>([]);
  const [providers, setProviders] = useState<AdProvider[]>([]);
  const [config, setConfig] = useState<AdConfig>({
    id: '',
    global_enabled: true,
    hide_for_pro: true,
    ad_free_trial_days: 3,
    min_screens_between_ads: 5
  });
  const [revenue, setRevenue] = useState<AdRevenue[]>([]);
  const [activeTab, setActiveTab] = useState<'placements' | 'providers' | 'revenue' | 'settings'>('placements');
  const [saving, setSaving] = useState(false);
  const [loading, setLoading] = useState(true);
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  useEffect(() => {
    fetchSettings();
  }, []);

  const fetchSettings = async () => {
    try {
      const res = await fetch(`${API_BASE}/api/admin/ads-settings`);
      const data = await res.json();
      if (data.success) {
        setPlacements(data.placements || []);
        setProviders(data.providers || []);
        setConfig(data.config || config);
        setRevenue(data.revenue || []);
      }
    } catch (error) {
      console.error('Failed to fetch ads settings:', error);
    } finally {
      setLoading(false);
    }
  };

  const handlePlacementChange = (placement_id: string, field: string, value: unknown) => {
    setPlacements(prev => prev.map(p => 
      p.placement_id === placement_id ? { ...p, [field]: value } : p
    ));
  };

  const handleProviderChange = (provider_id: string, field: string, value: string | boolean) => {
    setProviders(prev => prev.map(p => 
      p.provider_id === provider_id ? { ...p, [field]: value } : p
    ));
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      const res = await fetch(`${API_BASE}/api/admin/ads-settings`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ config, placements, providers })
      });
      const data = await res.json();
      if (data.success) {
        setMessage({ type: 'success', text: 'Settings saved to database!' });
      } else {
        throw new Error(data.error);
      }
    } catch {
      setMessage({ type: 'error', text: 'Failed to save settings' });
    } finally {
      setSaving(false);
      setTimeout(() => setMessage(null), 3000);
    }
  };

  const totalRevenue = revenue.reduce((sum, r) => sum + Number(r.revenue || 0), 0);
  const totalImpressions = revenue.reduce((sum, r) => sum + (r.impressions || 0), 0);
  const totalClicks = revenue.reduce((sum, r) => sum + (r.clicks || 0), 0);
  const avgCTR = totalImpressions > 0 ? (totalClicks / totalImpressions * 100).toFixed(2) : '0.00';

  if (loading) {
    return (
      <div className="p-8 flex items-center justify-center min-h-screen">
        <div className="text-center">
          <div className="w-12 h-12 mx-auto mb-4 rounded-full border-4 border-green-500 border-t-transparent animate-spin"></div>
          <p className="text-gray-400">Loading Ads Configuration...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="p-8 min-h-screen">
      {/* Header - Apple Style */}
      <header className="mb-10">
        <div className="flex items-center gap-4 mb-3">
          <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-green-500 to-teal-600 flex items-center justify-center shadow-lg" style={{boxShadow: '0 8px 24px rgba(52, 199, 89, 0.4)'}}>
            <svg className="w-7 h-7 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 3.055A9.001 9.001 0 1020.945 13H11V3.055z M20.488 9H15V3.512A9.025 9.025 0 0120.488 9z" />
            </svg>
          </div>
          <div>
            <h1 className="text-3xl font-bold text-white tracking-tight">Ads Management</h1>
            <p className="text-gray-400 text-sm mt-1">Configure placements, providers, and track revenue</p>
          </div>
        </div>
      </header>

      {/* Toast Message */}
      {message && (
        <div 
          className={`mb-6 p-4 rounded-2xl backdrop-blur-xl ${message.type === 'success' ? 'bg-green-500/10 border border-green-500/30' : 'bg-red-500/10 border border-red-500/30'}`}
          style={{boxShadow: message.type === 'success' ? '0 4px 20px rgba(52, 199, 89, 0.2)' : '0 4px 20px rgba(255, 59, 48, 0.2)'}}
        >
          <div className="flex items-center gap-3">
            <div className={`w-6 h-6 rounded-full flex items-center justify-center ${message.type === 'success' ? 'bg-green-500/20' : 'bg-red-500/20'}`}>
              {message.type === 'success' ? '✓' : '✕'}
            </div>
            <span className={message.type === 'success' ? 'text-green-400' : 'text-red-400'}>{message.text}</span>
          </div>
        </div>
      )}

      {/* Global Toggle - Neumorphism Card */}
      <div 
        className="mb-8 p-5 rounded-2xl backdrop-blur-xl flex items-center justify-between"
        style={{
          background: config.global_enabled ? 'rgba(52, 199, 89, 0.08)' : 'rgba(30, 30, 50, 0.5)',
          boxShadow: '8px 8px 16px rgba(0, 0, 0, 0.4), -6px -6px 14px rgba(255, 255, 255, 0.02), inset 0 0 0 1px rgba(255, 255, 255, 0.05)'
        }}
      >
        <div>
          <h3 className="text-lg font-semibold text-white">Global Ads</h3>
          <p className="text-sm text-gray-400">Enable or disable all ads platform-wide</p>
        </div>
        <button
          onClick={() => setConfig(c => ({ ...c, global_enabled: !c.global_enabled }))}
          className={`relative w-16 h-9 rounded-full transition-all duration-300 ${config.global_enabled ? 'bg-green-500' : 'bg-slate-700'}`}
          style={{
            boxShadow: config.global_enabled 
              ? '0 0 16px rgba(52, 199, 89, 0.5), inset 2px 2px 4px rgba(0, 0, 0, 0.2)' 
              : 'inset 3px 3px 6px rgba(0, 0, 0, 0.4), inset -2px -2px 4px rgba(255, 255, 255, 0.02)'
          }}
        >
          <div 
            className={`absolute top-1.5 w-6 h-6 bg-white rounded-full transition-all duration-300 ${config.global_enabled ? 'left-8' : 'left-1.5'}`}
            style={{boxShadow: '0 2px 6px rgba(0, 0, 0, 0.3)'}}
          ></div>
        </button>
      </div>

      {/* Revenue Stats - Neumorphism Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-5 mb-10">
        {[
          { label: 'Weekly Revenue', value: `$${totalRevenue.toFixed(2)}`, color: 'green', icon: '💰' },
          { label: 'Impressions', value: totalImpressions.toLocaleString(), color: 'blue', icon: '👁️' },
          { label: 'Clicks', value: totalClicks.toLocaleString(), color: 'purple', icon: '👆' },
          { label: 'CTR', value: `${avgCTR}%`, color: 'orange', icon: '📊' },
        ].map((stat) => (
          <div 
            key={stat.label}
            className="relative p-5 rounded-2xl overflow-hidden"
            style={{
              background: `linear-gradient(135deg, rgba(${stat.color === 'green' ? '52, 199, 89' : stat.color === 'blue' ? '0, 122, 255' : stat.color === 'purple' ? '175, 82, 222' : '255, 149, 0'}, 0.12) 0%, rgba(30, 30, 50, 0.5) 100%)`,
              boxShadow: '8px 8px 20px rgba(0, 0, 0, 0.4), -4px -4px 12px rgba(255, 255, 255, 0.02), inset 0 0 0 1px rgba(255, 255, 255, 0.05)'
            }}
          >
            <div className={`absolute top-0 left-0 right-0 h-1 bg-${stat.color}-500`} style={{background: stat.color === 'green' ? '#34c759' : stat.color === 'blue' ? '#007aff' : stat.color === 'purple' ? '#af52de' : '#ff9500'}}></div>
            <div className="flex items-center justify-between">
              <div>
                <p className="text-gray-400 text-sm">{stat.label}</p>
                <p className={`text-2xl font-bold mt-1`} style={{color: stat.color === 'green' ? '#34c759' : stat.color === 'blue' ? '#007aff' : stat.color === 'purple' ? '#af52de' : '#ff9500'}}>{stat.value}</p>
              </div>
              <span className="text-3xl opacity-40">{stat.icon}</span>
            </div>
          </div>
        ))}
      </div>

      {/* Tabs - Apple Pill Style */}
      <div 
        className="inline-flex p-1.5 mb-8 rounded-2xl"
        style={{
          background: 'rgba(30, 30, 50, 0.6)',
          boxShadow: 'inset 4px 4px 8px rgba(0, 0, 0, 0.4), inset -2px -2px 6px rgba(255, 255, 255, 0.02)'
        }}
      >
        {(['placements', 'providers', 'revenue', 'settings'] as const).map((tab) => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={`px-5 py-2.5 rounded-xl font-medium text-sm transition-all duration-300 capitalize ${
              activeTab === tab 
                ? 'bg-gradient-to-r from-green-500 to-teal-500 text-white' 
                : 'text-gray-400 hover:text-white'
            }`}
            style={activeTab === tab ? {boxShadow: '0 4px 15px rgba(52, 199, 89, 0.4)'} : {}}
          >
            {tab === 'placements' ? 'Ad Placements' : tab}
          </button>
        ))}
      </div>

      {/* Placements Tab */}
      {activeTab === 'placements' && (
        <div className="space-y-4">
          {placements.map((placement) => (
            <div 
              key={placement.placement_id} 
              className="p-5 rounded-2xl backdrop-blur-xl transition-all duration-300"
              style={{
                background: placement.enabled ? 'rgba(52, 199, 89, 0.08)' : 'rgba(30, 30, 50, 0.4)',
                boxShadow: placement.enabled
                  ? '8px 8px 16px rgba(0, 0, 0, 0.4), -4px -4px 12px rgba(255, 255, 255, 0.02), 0 0 20px rgba(52, 199, 89, 0.1), inset 0 0 0 1px rgba(52, 199, 89, 0.15)'
                  : '8px 8px 16px rgba(0, 0, 0, 0.4), -4px -4px 12px rgba(255, 255, 255, 0.02), inset 0 0 0 1px rgba(255, 255, 255, 0.03)'
              }}
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-4">
                  <button
                    onClick={() => handlePlacementChange(placement.placement_id, 'enabled', !placement.enabled)}
                    className={`relative w-12 h-7 rounded-full transition-all duration-300 ${placement.enabled ? 'bg-green-500' : 'bg-slate-700'}`}
                    style={{boxShadow: placement.enabled ? '0 0 10px rgba(52, 199, 89, 0.4)' : 'inset 2px 2px 4px rgba(0, 0, 0, 0.3)'}}
                  >
                    <div className={`absolute top-1 w-5 h-5 bg-white rounded-full transition-all duration-300 ${placement.enabled ? 'left-6' : 'left-1'}`} style={{boxShadow: '0 2px 4px rgba(0, 0, 0, 0.2)'}}></div>
                  </button>
                  <div>
                    <h3 className="text-white font-medium">{placement.name}</h3>
                    <p className="text-sm text-gray-500">Location: {placement.location}</p>
                  </div>
                </div>
                <div className="flex items-center gap-4">
                  <span className={`px-3 py-1 text-xs font-semibold rounded-full border ${
                    placement.ad_type === 'banner' ? 'bg-blue-500/15 text-blue-400 border-blue-500/30' :
                    placement.ad_type === 'interstitial' ? 'bg-orange-500/15 text-orange-400 border-orange-500/30' :
                    placement.ad_type === 'native' ? 'bg-purple-500/15 text-purple-400 border-purple-500/30' :
                    'bg-green-500/15 text-green-400 border-green-500/30'
                  }`}>
                    {placement.ad_type}
                  </span>
                  <div className="flex items-center gap-2">
                    <span className="text-sm text-gray-500">Every</span>
                    <input
                      type="number"
                      min="1"
                      max="100"
                      value={placement.frequency}
                      onChange={(e) => handlePlacementChange(placement.placement_id, 'frequency', parseInt(e.target.value) || 1)}
                      className="w-16 px-3 py-1.5 rounded-xl text-center text-white"
                      style={{
                        background: 'rgba(20, 20, 35, 0.6)',
                        boxShadow: 'inset 2px 2px 4px rgba(0, 0, 0, 0.3)',
                        border: '1px solid rgba(255, 255, 255, 0.05)'
                      }}
                    />
                    <span className="text-sm text-gray-500">views</span>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Providers Tab */}
      {activeTab === 'providers' && (
        <div className="space-y-5">
          {providers.map((provider) => (
            <div 
              key={provider.provider_id}
              className="p-6 rounded-2xl backdrop-blur-xl"
              style={{
                background: provider.enabled ? 'rgba(0, 122, 255, 0.08)' : 'rgba(30, 30, 50, 0.4)',
                boxShadow: provider.enabled
                  ? '8px 8px 16px rgba(0, 0, 0, 0.4), -4px -4px 12px rgba(255, 255, 255, 0.02), 0 0 20px rgba(0, 122, 255, 0.1), inset 0 0 0 1px rgba(0, 122, 255, 0.15)'
                  : '8px 8px 16px rgba(0, 0, 0, 0.4), -4px -4px 12px rgba(255, 255, 255, 0.02), inset 0 0 0 1px rgba(255, 255, 255, 0.03)'
              }}
            >
              <div className="flex items-center justify-between mb-5">
                <div className="flex items-center gap-4">
                  <button
                    onClick={() => handleProviderChange(provider.provider_id, 'enabled', !provider.enabled)}
                    className={`relative w-14 h-8 rounded-full transition-all duration-300 ${provider.enabled ? 'bg-blue-500' : 'bg-slate-700'}`}
                    style={{boxShadow: provider.enabled ? '0 0 12px rgba(0, 122, 255, 0.4)' : 'inset 3px 3px 6px rgba(0, 0, 0, 0.4)'}}
                  >
                    <div className={`absolute top-1 w-6 h-6 bg-white rounded-full transition-all duration-300 ${provider.enabled ? 'left-7' : 'left-1'}`} style={{boxShadow: '0 2px 6px rgba(0, 0, 0, 0.3)'}}></div>
                  </button>
                  <h3 className="text-lg font-semibold text-white">{provider.name}</h3>
                  {provider.enabled && (
                    <span className="px-3 py-1 text-xs font-semibold rounded-full bg-blue-500/15 text-blue-400 border border-blue-500/30">Active</span>
                  )}
                </div>
              </div>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-medium text-gray-500 mb-2 uppercase tracking-wider">Publisher ID</label>
                  <input
                    type="text"
                    value={provider.publisher_id || ''}
                    onChange={(e) => handleProviderChange(provider.provider_id, 'publisher_id', e.target.value)}
                    className="w-full px-4 py-3 rounded-xl text-white placeholder-gray-600"
                    style={{
                      background: 'rgba(20, 20, 35, 0.6)',
                      boxShadow: 'inset 3px 3px 8px rgba(0, 0, 0, 0.4), inset -2px -2px 6px rgba(255, 255, 255, 0.02)',
                      border: '1px solid rgba(255, 255, 255, 0.05)'
                    }}
                    placeholder="pub-1234567890"
                  />
                </div>
                <div>
                  <label className="block text-xs font-medium text-gray-500 mb-2 uppercase tracking-wider">App ID</label>
                  <input
                    type="text"
                    value={provider.app_id || ''}
                    onChange={(e) => handleProviderChange(provider.provider_id, 'app_id', e.target.value)}
                    className="w-full px-4 py-3 rounded-xl text-white placeholder-gray-600"
                    style={{
                      background: 'rgba(20, 20, 35, 0.6)',
                      boxShadow: 'inset 3px 3px 8px rgba(0, 0, 0, 0.4), inset -2px -2px 6px rgba(255, 255, 255, 0.02)',
                      border: '1px solid rgba(255, 255, 255, 0.05)'
                    }}
                    placeholder="ca-app-pub-1234567890"
                  />
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Revenue Tab */}
      {activeTab === 'revenue' && (
        <div 
          className="rounded-2xl overflow-hidden"
          style={{
            background: 'rgba(30, 30, 50, 0.4)',
            boxShadow: '8px 8px 20px rgba(0, 0, 0, 0.4), -4px -4px 12px rgba(255, 255, 255, 0.02), inset 0 0 0 1px rgba(255, 255, 255, 0.04)'
          }}
        >
          <table className="w-full">
            <thead style={{background: 'rgba(20, 20, 35, 0.6)'}}>
              <tr>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-400 uppercase tracking-wider">Date</th>
                <th className="px-6 py-4 text-right text-xs font-semibold text-gray-400 uppercase tracking-wider">Impressions</th>
                <th className="px-6 py-4 text-right text-xs font-semibold text-gray-400 uppercase tracking-wider">Clicks</th>
                <th className="px-6 py-4 text-right text-xs font-semibold text-gray-400 uppercase tracking-wider">CTR</th>
                <th className="px-6 py-4 text-right text-xs font-semibold text-gray-400 uppercase tracking-wider">Revenue</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              {revenue.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-6 py-12 text-center text-gray-500">No revenue data yet</td>
                </tr>
              ) : revenue.map((row) => (
                <tr key={row.date} className="hover:bg-white/5 transition-colors">
                  <td className="px-6 py-4 text-white">{row.date}</td>
                  <td className="px-6 py-4 text-right text-gray-300">{row.impressions?.toLocaleString() || 0}</td>
                  <td className="px-6 py-4 text-right text-gray-300">{row.clicks?.toLocaleString() || 0}</td>
                  <td className="px-6 py-4 text-right text-gray-300">{row.impressions ? (row.clicks / row.impressions * 100).toFixed(2) : 0}%</td>
                  <td className="px-6 py-4 text-right text-green-400 font-semibold">${Number(row.revenue || 0).toFixed(2)}</td>
                </tr>
              ))}
            </tbody>
            {revenue.length > 0 && (
              <tfoot style={{background: 'rgba(20, 20, 35, 0.6)'}}>
                <tr>
                  <td className="px-6 py-4 text-white font-semibold">Total</td>
                  <td className="px-6 py-4 text-right text-white font-semibold">{totalImpressions.toLocaleString()}</td>
                  <td className="px-6 py-4 text-right text-white font-semibold">{totalClicks.toLocaleString()}</td>
                  <td className="px-6 py-4 text-right text-white font-semibold">{avgCTR}%</td>
                  <td className="px-6 py-4 text-right text-green-400 font-bold">${totalRevenue.toFixed(2)}</td>
                </tr>
              </tfoot>
            )}
          </table>
        </div>
      )}

      {/* Settings Tab */}
      {activeTab === 'settings' && (
        <div className="space-y-6">
          <div 
            className="p-6 rounded-2xl"
            style={{
              background: 'rgba(30, 30, 50, 0.4)',
              boxShadow: '8px 8px 16px rgba(0, 0, 0, 0.4), -4px -4px 12px rgba(255, 255, 255, 0.02), inset 0 0 0 1px rgba(255, 255, 255, 0.04)'
            }}
          >
            <h3 className="text-lg font-semibold text-white mb-5">Ad Behavior Settings</h3>
            
            <div className="space-y-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-white font-medium">Hide ads for Pro subscribers</p>
                  <p className="text-sm text-gray-500 mt-0.5">Pro users will not see any ads</p>
                </div>
                <button
                  onClick={() => setConfig(c => ({ ...c, hide_for_pro: !c.hide_for_pro }))}
                  className={`relative w-14 h-8 rounded-full transition-all duration-300 ${config.hide_for_pro ? 'bg-blue-500' : 'bg-slate-700'}`}
                  style={{boxShadow: config.hide_for_pro ? '0 0 10px rgba(0, 122, 255, 0.4)' : 'inset 2px 2px 4px rgba(0, 0, 0, 0.3)'}}
                >
                  <div className={`absolute top-1 w-6 h-6 bg-white rounded-full transition-all duration-300 ${config.hide_for_pro ? 'left-7' : 'left-1'}`} style={{boxShadow: '0 2px 4px rgba(0, 0, 0, 0.2)'}}></div>
                </button>
              </div>

              <div className="pt-5 border-t border-white/5">
                <p className="text-white font-medium mb-1">Ad-free Trial Period</p>
                <p className="text-sm text-gray-500 mb-3">New users won&apos;t see ads for this many days</p>
                <div className="flex items-center gap-3">
                  <input
                    type="number"
                    value={config.ad_free_trial_days}
                    onChange={(e) => setConfig(c => ({ ...c, ad_free_trial_days: parseInt(e.target.value) || 0 }))}
                    min={0}
                    max={30}
                    className="w-20 px-4 py-2.5 rounded-xl text-white text-center"
                    style={{
                      background: 'rgba(20, 20, 35, 0.6)',
                      boxShadow: 'inset 3px 3px 6px rgba(0, 0, 0, 0.4)',
                      border: '1px solid rgba(255, 255, 255, 0.05)'
                    }}
                  />
                  <span className="text-gray-400">days</span>
                </div>
              </div>

              <div className="pt-5 border-t border-white/5">
                <p className="text-white font-medium mb-1">Minimum Content Between Ads</p>
                <p className="text-sm text-gray-500 mb-3">Minimum pages/screens between interstitial ads</p>
                <div className="flex items-center gap-3">
                  <input
                    type="number"
                    value={config.min_screens_between_ads}
                    onChange={(e) => setConfig(c => ({ ...c, min_screens_between_ads: parseInt(e.target.value) || 1 }))}
                    min={1}
                    max={20}
                    className="w-20 px-4 py-2.5 rounded-xl text-white text-center"
                    style={{
                      background: 'rgba(20, 20, 35, 0.6)',
                      boxShadow: 'inset 3px 3px 6px rgba(0, 0, 0, 0.4)',
                      border: '1px solid rgba(255, 255, 255, 0.05)'
                    }}
                  />
                  <span className="text-gray-400">screens</span>
                </div>
              </div>
            </div>
          </div>

          {/* Danger Zone */}
          <div 
            className="p-6 rounded-2xl"
            style={{
              background: 'rgba(255, 59, 48, 0.06)',
              boxShadow: 'inset 0 0 0 1px rgba(255, 59, 48, 0.2)'
            }}
          >
            <h3 className="text-lg font-semibold text-red-400 mb-2">Danger Zone</h3>
            <p className="text-sm text-gray-400 mb-4">Clear all ad analytics data. This cannot be undone.</p>
            <button 
              className="px-5 py-2.5 rounded-xl font-medium transition-all duration-200"
              style={{
                background: 'rgba(255, 59, 48, 0.15)',
                color: '#ff3b30',
                border: '1px solid rgba(255, 59, 48, 0.3)',
                boxShadow: '0 2px 8px rgba(255, 59, 48, 0.15)'
              }}
              onMouseEnter={(e) => e.currentTarget.style.background = 'rgba(255, 59, 48, 0.25)'}
              onMouseLeave={(e) => e.currentTarget.style.background = 'rgba(255, 59, 48, 0.15)'}
            >
              Clear Analytics Data
            </button>
          </div>
        </div>
      )}

      {/* Save Button - Apple Style */}
      <div className="mt-10 flex justify-end">
        <button
          onClick={handleSave}
          disabled={saving}
          className="px-8 py-3.5 text-white font-semibold rounded-2xl transition-all duration-300 disabled:opacity-50"
          style={{
            background: 'linear-gradient(135deg, #34c759 0%, #30d158 100%)',
            boxShadow: saving ? 'none' : '0 6px 20px rgba(52, 199, 89, 0.4), 0 3px 8px rgba(0, 0, 0, 0.2)',
            transform: saving ? 'scale(0.98)' : 'scale(1)'
          }}
          onMouseEnter={(e) => {
            if (!saving) {
              e.currentTarget.style.transform = 'translateY(-2px)';
              e.currentTarget.style.boxShadow = '0 8px 25px rgba(52, 199, 89, 0.5), 0 4px 10px rgba(0, 0, 0, 0.25)';
            }
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.transform = 'scale(1)';
            e.currentTarget.style.boxShadow = '0 6px 20px rgba(52, 199, 89, 0.4), 0 3px 8px rgba(0, 0, 0, 0.2)';
          }}
        >
          {saving ? (
            <span className="flex items-center gap-2">
              <span className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></span>
              Saving...
            </span>
          ) : (
            'Save Ad Settings'
          )}
        </button>
      </div>
    </div>
  );
}
