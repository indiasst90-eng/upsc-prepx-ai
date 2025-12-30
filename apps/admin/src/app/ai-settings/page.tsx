'use client';

import { useState, useEffect } from 'react';

interface AIProvider {
  id: string;
  provider_id: string;
  name: string;
  base_url: string;
  api_key_encrypted?: string;
  auth_type: 'bearer' | 'api-key' | 'basic' | 'custom';
  custom_headers?: Record<string, string>;
  is_active: boolean;
  is_custom: boolean;
  description?: string;
  display_order: number;
}

interface AIModel {
  id: string;
  model_id: string;
  name: string;
  model_type: 'llm' | 'tts' | 'stt' | 'embeddings' | 'image';
  provider_id: string;
  model_name: string;
  is_primary: boolean;
  is_fallback: boolean;
}

const API_BASE = process.env.NEXT_PUBLIC_WEB_URL || 'http://localhost:3000';

export default function AISettingsPage() {
  const [providers, setProviders] = useState<AIProvider[]>([]);
  const [models, setModels] = useState<AIModel[]>([]);
  const [activeTab, setActiveTab] = useState<'providers' | 'models'>('providers');
  const [saving, setSaving] = useState(false);
  const [loading, setLoading] = useState(true);
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  // Load settings from API
  useEffect(() => {
    fetchSettings();
  }, []);

  const fetchSettings = async () => {
    try {
      const res = await fetch(`${API_BASE}/api/admin/ai-settings`);
      const data = await res.json();
      if (data.success) {
        setProviders(data.providers || []);
        setModels(data.models || []);
      }
    } catch (error) {
      console.error('Failed to fetch settings:', error);
      setMessage({ type: 'error', text: 'Failed to load settings from server' });
    } finally {
      setLoading(false);
    }
  };

  const handleProviderChange = (provider_id: string, field: string, value: string | boolean) => {
    setProviders(prev => prev.map(p => 
      p.provider_id === provider_id ? { ...p, [field]: value } : p
    ));
  };

  const handleModelChange = (model_id: string, field: string, value: string | boolean) => {
    setModels(prev => prev.map(m => 
      m.model_id === model_id ? { ...m, [field]: value } : m
    ));
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      const res = await fetch(`${API_BASE}/api/admin/ai-settings`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ providers, models })
      });
      const data = await res.json();
      if (data.success) {
        setMessage({ type: 'success', text: 'Settings saved to database!' });
      } else {
        throw new Error(data.error);
      }
    } catch (error) {
      setMessage({ type: 'error', text: 'Failed to save settings' });
    } finally {
      setSaving(false);
      setTimeout(() => setMessage(null), 3000);
    }
  };

  const testProvider = async (provider: AIProvider) => {
    if (!provider.api_key_encrypted) {
      setMessage({ type: 'error', text: `No API key set for ${provider.name}` });
      setTimeout(() => setMessage(null), 3000);
      return;
    }
    
    try {
      const response = await fetch(`${provider.base_url}/models`, {
        headers: { 'Authorization': `Bearer ${provider.api_key_encrypted}` }
      });
      if (response.ok) {
        setMessage({ type: 'success', text: `${provider.name} connection successful!` });
      } else {
        setMessage({ type: 'error', text: `${provider.name} connection failed: ${response.status}` });
      }
    } catch {
      setMessage({ type: 'error', text: `${provider.name} connection failed` });
    }
    setTimeout(() => setMessage(null), 3000);
  };

  if (loading) {
    return (
      <div className="p-8 flex items-center justify-center min-h-screen">
        <div className="text-center">
          <div className="w-12 h-12 mx-auto mb-4 rounded-full border-4 border-blue-500 border-t-transparent animate-spin"></div>
          <p className="text-gray-400">Loading AI Configuration...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="p-8 min-h-screen">
      {/* Header - Apple Style */}
      <header className="mb-10">
        <div className="flex items-center gap-4 mb-3">
          <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center shadow-lg" style={{boxShadow: '0 8px 24px rgba(102, 126, 234, 0.4)'}}>
            <svg className="w-7 h-7 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
            </svg>
          </div>
          <div>
            <h1 className="text-3xl font-bold text-white tracking-tight">AI Configuration</h1>
            <p className="text-gray-400 text-sm mt-1">Manage AI providers and model assignments</p>
          </div>
        </div>
      </header>

      {/* Toast Message - Neumorphism */}
      {message && (
        <div 
          className={`mb-6 p-4 rounded-2xl backdrop-blur-xl ${
            message.type === 'success' 
              ? 'bg-green-500/10 border border-green-500/30' 
              : 'bg-red-500/10 border border-red-500/30'
          }`}
          style={{
            boxShadow: message.type === 'success' 
              ? '0 4px 20px rgba(52, 199, 89, 0.2), inset 0 0 0 1px rgba(52, 199, 89, 0.1)' 
              : '0 4px 20px rgba(255, 59, 48, 0.2), inset 0 0 0 1px rgba(255, 59, 48, 0.1)'
          }}
        >
          <div className="flex items-center gap-3">
            <div className={`w-6 h-6 rounded-full flex items-center justify-center ${message.type === 'success' ? 'bg-green-500/20' : 'bg-red-500/20'}`}>
              {message.type === 'success' ? '✓' : '✕'}
            </div>
            <span className={message.type === 'success' ? 'text-green-400' : 'text-red-400'}>{message.text}</span>
          </div>
        </div>
      )}

      {/* Tabs - Apple Pill Style */}
      <div 
        className="inline-flex p-1.5 mb-8 rounded-2xl"
        style={{
          background: 'rgba(30, 30, 50, 0.6)',
          boxShadow: 'inset 4px 4px 8px rgba(0, 0, 0, 0.4), inset -2px -2px 6px rgba(255, 255, 255, 0.02)'
        }}
      >
        <button
          onClick={() => setActiveTab('providers')}
          className={`px-6 py-2.5 rounded-xl font-medium text-sm transition-all duration-300 ${
            activeTab === 'providers' 
              ? 'bg-gradient-to-r from-blue-500 to-purple-500 text-white shadow-lg' 
              : 'text-gray-400 hover:text-white'
          }`}
          style={activeTab === 'providers' ? {boxShadow: '0 4px 15px rgba(102, 126, 234, 0.4)'} : {}}
        >
          AI Providers
        </button>
        <button
          onClick={() => setActiveTab('models')}
          className={`px-6 py-2.5 rounded-xl font-medium text-sm transition-all duration-300 ${
            activeTab === 'models' 
              ? 'bg-gradient-to-r from-blue-500 to-purple-500 text-white shadow-lg' 
              : 'text-gray-400 hover:text-white'
          }`}
          style={activeTab === 'models' ? {boxShadow: '0 4px 15px rgba(102, 126, 234, 0.4)'} : {}}
        >
          Model Configuration
        </button>
      </div>

      {/* Providers Tab - Neumorphism Cards */}
      {activeTab === 'providers' && (
        <div className="space-y-5">
          {providers.map((provider) => (
            <div 
              key={provider.provider_id} 
              className={`p-6 rounded-2xl backdrop-blur-xl transition-all duration-300 ${
                provider.is_active 
                  ? 'bg-slate-800/50' 
                  : 'bg-slate-900/40'
              }`}
              style={{
                boxShadow: provider.is_active
                  ? '8px 8px 20px rgba(0, 0, 0, 0.4), -6px -6px 16px rgba(255, 255, 255, 0.02), 0 0 20px rgba(102, 126, 234, 0.15), inset 0 0 0 1px rgba(102, 126, 234, 0.2)'
                  : '8px 8px 16px rgba(0, 0, 0, 0.4), -6px -6px 14px rgba(255, 255, 255, 0.02), inset 0 0 0 1px rgba(255, 255, 255, 0.03)'
              }}
            >
              {/* Provider Header */}
              <div className="flex items-center justify-between mb-5">
                <div className="flex items-center gap-4">
                  {/* Apple-style Toggle */}
                  <button
                    onClick={() => handleProviderChange(provider.provider_id, 'is_active', !provider.is_active)}
                    className={`relative w-14 h-8 rounded-full transition-all duration-300 ${
                      provider.is_active ? 'bg-green-500' : 'bg-slate-700'
                    }`}
                    style={{
                      boxShadow: provider.is_active 
                        ? '0 0 12px rgba(52, 199, 89, 0.4), inset 2px 2px 4px rgba(0, 0, 0, 0.2)' 
                        : 'inset 3px 3px 6px rgba(0, 0, 0, 0.4), inset -2px -2px 4px rgba(255, 255, 255, 0.02)'
                    }}
                  >
                    <div 
                      className={`absolute top-1 w-6 h-6 bg-white rounded-full transition-all duration-300 ${
                        provider.is_active ? 'left-7' : 'left-1'
                      }`}
                      style={{boxShadow: '0 2px 6px rgba(0, 0, 0, 0.3)'}}
                    ></div>
                  </button>
                  
                  <div>
                    {provider.is_custom ? (
                      <input
                        type="text"
                        value={provider.name}
                        onChange={(e) => handleProviderChange(provider.provider_id, 'name', e.target.value)}
                        className="text-lg font-semibold text-white bg-transparent border-b-2 border-dashed border-purple-500/40 focus:border-purple-500 focus:outline-none pb-1"
                        placeholder="Custom Provider Name"
                      />
                    ) : (
                      <h3 className="text-lg font-semibold text-white">{provider.name}</h3>
                    )}
                    {provider.description && <p className="text-xs text-gray-500 mt-0.5">{provider.description}</p>}
                  </div>

                  {/* Badges */}
                  <div className="flex gap-2">
                    {provider.is_active && (
                      <span className="px-3 py-1 text-xs font-semibold rounded-full bg-green-500/15 text-green-400 border border-green-500/30">
                        Active
                      </span>
                    )}
                    {provider.is_custom && (
                      <span className="px-3 py-1 text-xs font-semibold rounded-full bg-purple-500/15 text-purple-400 border border-purple-500/30">
                        Custom
                      </span>
                    )}
                  </div>
                </div>
                
                <button
                  onClick={() => testProvider(provider)}
                  className="px-4 py-2 text-sm font-medium rounded-xl transition-all duration-200"
                  style={{
                    background: 'rgba(50, 50, 70, 0.6)',
                    boxShadow: '4px 4px 10px rgba(0, 0, 0, 0.3), -3px -3px 8px rgba(255, 255, 255, 0.02), inset 0 0 0 1px rgba(255, 255, 255, 0.05)',
                    color: '#9ca3af'
                  }}
                  onMouseEnter={(e) => e.currentTarget.style.color = '#fff'}
                  onMouseLeave={(e) => e.currentTarget.style.color = '#9ca3af'}
                >
                  Test Connection
                </button>
              </div>
              
              {/* Provider Fields */}
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                <div className="md:col-span-2">
                  <label className="block text-xs font-medium text-gray-500 mb-2 uppercase tracking-wider">Base URL</label>
                  <input
                    type="text"
                    value={provider.base_url}
                    onChange={(e) => handleProviderChange(provider.provider_id, 'base_url', e.target.value)}
                    className="w-full px-4 py-3 rounded-xl text-white placeholder-gray-600 transition-all duration-200"
                    style={{
                      background: 'rgba(20, 20, 35, 0.6)',
                      boxShadow: 'inset 3px 3px 8px rgba(0, 0, 0, 0.4), inset -2px -2px 6px rgba(255, 255, 255, 0.02)',
                      border: '1px solid rgba(255, 255, 255, 0.05)'
                    }}
                    onFocus={(e) => {
                      e.target.style.borderColor = 'rgba(0, 122, 255, 0.5)';
                      e.target.style.boxShadow = 'inset 3px 3px 8px rgba(0, 0, 0, 0.4), inset -2px -2px 6px rgba(255, 255, 255, 0.02), 0 0 0 3px rgba(0, 122, 255, 0.15)';
                    }}
                    onBlur={(e) => {
                      e.target.style.borderColor = 'rgba(255, 255, 255, 0.05)';
                      e.target.style.boxShadow = 'inset 3px 3px 8px rgba(0, 0, 0, 0.4), inset -2px -2px 6px rgba(255, 255, 255, 0.02)';
                    }}
                    placeholder="https://api.provider.com/v1"
                  />
                </div>
                <div>
                  <label className="block text-xs font-medium text-gray-500 mb-2 uppercase tracking-wider">API Key</label>
                  <input
                    type="password"
                    value={provider.api_key_encrypted || ''}
                    onChange={(e) => handleProviderChange(provider.provider_id, 'api_key_encrypted', e.target.value)}
                    className="w-full px-4 py-3 rounded-xl text-white placeholder-gray-600"
                    style={{
                      background: 'rgba(20, 20, 35, 0.6)',
                      boxShadow: 'inset 3px 3px 8px rgba(0, 0, 0, 0.4), inset -2px -2px 6px rgba(255, 255, 255, 0.02)',
                      border: '1px solid rgba(255, 255, 255, 0.05)'
                    }}
                    placeholder="sk-..."
                  />
                </div>
                <div>
                  <label className="block text-xs font-medium text-gray-500 mb-2 uppercase tracking-wider">Auth Type</label>
                  <select
                    value={provider.auth_type || 'bearer'}
                    onChange={(e) => handleProviderChange(provider.provider_id, 'auth_type', e.target.value)}
                    className="w-full px-4 py-3 rounded-xl text-white appearance-none cursor-pointer"
                    style={{
                      background: 'rgba(20, 20, 35, 0.6)',
                      boxShadow: 'inset 3px 3px 8px rgba(0, 0, 0, 0.4), inset -2px -2px 6px rgba(255, 255, 255, 0.02)',
                      border: '1px solid rgba(255, 255, 255, 0.05)'
                    }}
                  >
                    <option value="bearer">Bearer Token</option>
                    <option value="api-key">API Key Header</option>
                    <option value="basic">Basic Auth</option>
                    <option value="custom">Custom Headers</option>
                  </select>
                </div>
              </div>
              
              {/* Custom Headers */}
              {(provider.is_custom || provider.auth_type === 'custom') && (
                <div className="mt-4">
                  <label className="block text-xs font-medium text-gray-500 mb-2 uppercase tracking-wider">Custom Headers (JSON)</label>
                  <textarea
                    value={provider.custom_headers ? JSON.stringify(provider.custom_headers) : ''}
                    onChange={(e) => {
                      try {
                        const parsed = JSON.parse(e.target.value);
                        handleProviderChange(provider.provider_id, 'custom_headers', parsed);
                      } catch {}
                    }}
                    className="w-full px-4 py-3 rounded-xl text-white font-mono text-sm placeholder-gray-600"
                    style={{
                      background: 'rgba(20, 20, 35, 0.6)',
                      boxShadow: 'inset 3px 3px 8px rgba(0, 0, 0, 0.4), inset -2px -2px 6px rgba(255, 255, 255, 0.02)',
                      border: '1px solid rgba(255, 255, 255, 0.05)'
                    }}
                    placeholder='{"X-Custom-Header": "value"}'
                    rows={2}
                  />
                </div>
              )}
            </div>
          ))}
        </div>
      )}

      {/* Models Tab - Neumorphism Cards */}
      {activeTab === 'models' && (
        <div className="space-y-4">
          {models.map((model) => (
            <div 
              key={model.model_id} 
              className="p-6 rounded-2xl backdrop-blur-xl"
              style={{
                background: 'rgba(30, 30, 50, 0.5)',
                boxShadow: '8px 8px 16px rgba(0, 0, 0, 0.4), -6px -6px 14px rgba(255, 255, 255, 0.02), inset 0 0 0 1px rgba(255, 255, 255, 0.04)'
              }}
            >
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-3">
                  <h3 className="text-lg font-semibold text-white">{model.name}</h3>
                  <span className={`px-3 py-1 text-xs font-semibold rounded-full border ${
                    model.model_type === 'llm' ? 'bg-blue-500/15 text-blue-400 border-blue-500/30' :
                    model.model_type === 'tts' ? 'bg-green-500/15 text-green-400 border-green-500/30' :
                    model.model_type === 'stt' ? 'bg-purple-500/15 text-purple-400 border-purple-500/30' :
                    model.model_type === 'embeddings' ? 'bg-orange-500/15 text-orange-400 border-orange-500/30' :
                    'bg-pink-500/15 text-pink-400 border-pink-500/30'
                  }`}>
                    {model.model_type.toUpperCase()}
                  </span>
                  {model.is_primary && <span className="px-3 py-1 text-xs font-semibold rounded-full bg-green-500/15 text-green-400 border border-green-500/30">Primary</span>}
                  {model.is_fallback && <span className="px-3 py-1 text-xs font-semibold rounded-full bg-yellow-500/15 text-yellow-400 border border-yellow-500/30">Fallback</span>}
                </div>
              </div>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-medium text-gray-500 mb-2 uppercase tracking-wider">Provider</label>
                  <select
                    value={model.provider_id}
                    onChange={(e) => handleModelChange(model.model_id, 'provider_id', e.target.value)}
                    className="w-full px-4 py-3 rounded-xl text-white appearance-none cursor-pointer"
                    style={{
                      background: 'rgba(20, 20, 35, 0.6)',
                      boxShadow: 'inset 3px 3px 8px rgba(0, 0, 0, 0.4), inset -2px -2px 6px rgba(255, 255, 255, 0.02)',
                      border: '1px solid rgba(255, 255, 255, 0.05)'
                    }}
                  >
                    {providers.filter(p => p.is_active).map(p => (
                      <option key={p.provider_id} value={p.provider_id}>{p.name}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-medium text-gray-500 mb-2 uppercase tracking-wider">Model ID</label>
                  <input
                    type="text"
                    value={model.model_name}
                    onChange={(e) => handleModelChange(model.model_id, 'model_name', e.target.value)}
                    className="w-full px-4 py-3 rounded-xl text-white placeholder-gray-600"
                    style={{
                      background: 'rgba(20, 20, 35, 0.6)',
                      boxShadow: 'inset 3px 3px 8px rgba(0, 0, 0, 0.4), inset -2px -2px 6px rgba(255, 255, 255, 0.02)',
                      border: '1px solid rgba(255, 255, 255, 0.05)'
                    }}
                    placeholder="gpt-4, claude-3, etc."
                  />
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Save Button - Apple Style */}
      <div className="mt-10 flex justify-end">
        <button
          onClick={handleSave}
          disabled={saving}
          className="px-8 py-3.5 text-white font-semibold rounded-2xl transition-all duration-300 disabled:opacity-50"
          style={{
            background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
            boxShadow: saving 
              ? 'none' 
              : '0 6px 20px rgba(102, 126, 234, 0.4), 0 3px 8px rgba(0, 0, 0, 0.2)',
            transform: saving ? 'scale(0.98)' : 'scale(1)'
          }}
          onMouseEnter={(e) => {
            if (!saving) {
              e.currentTarget.style.transform = 'translateY(-2px)';
              e.currentTarget.style.boxShadow = '0 8px 25px rgba(102, 126, 234, 0.5), 0 4px 10px rgba(0, 0, 0, 0.25)';
            }
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.transform = 'scale(1)';
            e.currentTarget.style.boxShadow = '0 6px 20px rgba(102, 126, 234, 0.4), 0 3px 8px rgba(0, 0, 0, 0.2)';
          }}
        >
          {saving ? (
            <span className="flex items-center gap-2">
              <span className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></span>
              Saving...
            </span>
          ) : (
            'Save Configuration'
          )}
        </button>
      </div>

      {/* Providers Info - Neumorphism */}
      <div 
        className="mt-12 p-6 rounded-2xl"
        style={{
          background: 'rgba(25, 25, 40, 0.4)',
          boxShadow: 'inset 4px 4px 10px rgba(0, 0, 0, 0.3), inset -3px -3px 8px rgba(255, 255, 255, 0.02)'
        }}
      >
        <h3 className="text-lg font-semibold text-white mb-4">Supported Providers</h3>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-5">
          {[
            { name: 'A4F Unified', desc: 'All-in-one API gateway' },
            { name: 'OpenAI', desc: 'GPT-4, DALL-E, Whisper' },
            { name: 'Anthropic', desc: 'Claude 3.5, Claude 3' },
            { name: 'Google AI', desc: 'Gemini Pro, Gemini Flash' },
            { name: 'Groq', desc: 'Fast Llama, Mixtral' },
            { name: 'Together AI', desc: 'Open models at scale' },
            { name: 'DeepSeek', desc: 'Code & reasoning' },
            { name: 'Ollama', desc: 'Local LLM hosting' },
          ].map((p, i) => (
            <div key={i} className="p-3 rounded-xl" style={{background: 'rgba(255, 255, 255, 0.02)'}}>
              <p className="text-white font-medium text-sm">{p.name}</p>
              <p className="text-gray-500 text-xs mt-0.5">{p.desc}</p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
