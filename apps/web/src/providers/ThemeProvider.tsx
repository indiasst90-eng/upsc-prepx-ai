'use client';

/**
 * ThemeProvider - Dynamic Background Management System
 * 
 * This component manages AI-driven visual theme updates without affecting layout.
 * Background images and decorative elements are updated dynamically via CSS variables.
 */

import React, { createContext, useContext, useEffect, useState, ReactNode } from 'react';
import { getSupabaseBrowserClient } from '@/lib/supabase/client';

interface ThemeConfig {
  primaryBackground: string;
  heroBackground: string;
  sectionBackground: string;
  overlayBackground: string;
  lastUpdated: string;
}

interface ThemeContextType {
  theme: ThemeConfig;
  refreshTheme: () => Promise<void>;
  isLoading: boolean;
}

const defaultTheme: ThemeConfig = {
  primaryBackground: 'linear-gradient(180deg, hsl(222, 84%, 4.9%) 0%, hsl(217, 32%, 12%) 100%)',
  heroBackground: 'radial-gradient(ellipse at top, hsl(217, 91%, 20%) 0%, transparent 50%)',
  sectionBackground: 'linear-gradient(135deg, hsl(217, 32%, 10%) 0%, hsl(222, 84%, 4.9%) 100%)',
  overlayBackground: 'linear-gradient(180deg, transparent 0%, hsl(222, 84%, 4.9%) 100%)',
  lastUpdated: new Date().toISOString()
};

const ThemeContext = createContext<ThemeContextType | undefined>(undefined);

export function useTheme() {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error('useTheme must be used within ThemeProvider');
  }
  return context;
}

interface ThemeProviderProps {
  children: ReactNode;
}

export function ThemeProvider({ children }: ThemeProviderProps) {
  const [theme, setTheme] = useState<ThemeConfig>(defaultTheme);
  const [isLoading, setIsLoading] = useState(false);
  const supabase = getSupabaseBrowserClient();

  // Fetch theme from database or external source
  const fetchTheme = async (): Promise<ThemeConfig> => {
    try {
      // Query theme configuration from database
      const { data, error } = await supabase
        .from('system_config')
        .select('config_value')
        .eq('config_key', 'theme_backgrounds')
        .single() as { data: { config_value: Partial<ThemeConfig> } | null; error: Error | null };

      if (error) {
        console.warn('Theme fetch failed, using default:', error.message);
        return defaultTheme;
      }

      if (data && data.config_value) {
        return {
          ...defaultTheme,
          ...data.config_value,
          lastUpdated: new Date().toISOString()
        };
      }

      return defaultTheme;
    } catch (err) {
      console.error('Error fetching theme:', err);
      return defaultTheme;
    }
  };

  // Apply theme to CSS variables
  const applyTheme = (themeConfig: ThemeConfig) => {
    if (typeof window === 'undefined') return;

    const root = document.documentElement;
    root.style.setProperty('--bg-dynamic-primary', themeConfig.primaryBackground);
    root.style.setProperty('--bg-dynamic-hero', themeConfig.heroBackground);
    root.style.setProperty('--bg-dynamic-section', themeConfig.sectionBackground);
    root.style.setProperty('--bg-dynamic-overlay', themeConfig.overlayBackground);
  };

  // Refresh theme manually
  const refreshTheme = async () => {
    setIsLoading(true);
    try {
      const newTheme = await fetchTheme();
      setTheme(newTheme);
      applyTheme(newTheme);
    } finally {
      setIsLoading(false);
    }
  };

  // Initial theme load
  useEffect(() => {
    const loadTheme = async () => {
      setIsLoading(true);
      try {
        const initialTheme = await fetchTheme();
        setTheme(initialTheme);
        applyTheme(initialTheme);
      } finally {
        setIsLoading(false);
      }
    };

    loadTheme();
  }, []);

  // Subscribe to theme updates (real-time)
  useEffect(() => {
    const channel = supabase
      .channel('theme-updates')
      .on(
        'postgres_changes',
        {
          event: 'UPDATE',
          schema: 'public',
          table: 'system_config',
          filter: 'config_key=eq.theme_backgrounds'
        },
        async (payload) => {
          console.log('Theme update received:', payload);
          await refreshTheme();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  // Apply theme on mount and updates
  useEffect(() => {
    applyTheme(theme);
  }, [theme]);

  return (
    <ThemeContext.Provider value={{ theme, refreshTheme, isLoading }}>
      {children}
    </ThemeContext.Provider>
  );
}

/**
 * DynamicBackground Component
 * 
 * Use this component to create background layers that respond to theme updates
 * without affecting the structural layout.
 */

interface DynamicBackgroundProps {
  variant?: 'primary' | 'hero' | 'section' | 'overlay';
  className?: string;
  children?: ReactNode;
}

export function DynamicBackground({ 
  variant = 'primary', 
  className = '',
  children 
}: DynamicBackgroundProps) {
  const varMap = {
    primary: '--bg-dynamic-primary',
    hero: '--bg-dynamic-hero',
    section: '--bg-dynamic-section',
    overlay: '--bg-dynamic-overlay'
  };

  return (
    <div 
      className={`absolute inset-0 -z-10 ${className}`}
      style={{ background: `var(${varMap[variant]})` }}
    >
      {children}
    </div>
  );
}
