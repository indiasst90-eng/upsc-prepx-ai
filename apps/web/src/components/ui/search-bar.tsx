'use client';

/**
 * SearchBar Component - Glassmorphic search with neon focus states
 * Following Apple/Stripe design aesthetics
 */

import * as React from 'react';
import { Search, X, Loader2 } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { cn } from '@/lib/utils';

export interface SearchBarProps extends Omit<React.InputHTMLAttributes<HTMLInputElement>, 'onChange'> {
  onSearch?: (query: string) => void;
  onChange?: (value: string) => void;
  onClear?: () => void;
  isLoading?: boolean;
  suggestions?: string[];
  variant?: 'default' | 'compact';
}

const SearchBar = React.forwardRef<HTMLInputElement, SearchBarProps>(
  ({ 
    className, 
    onSearch, 
    onChange,
    onClear,
    isLoading = false,
    suggestions = [],
    variant = 'default',
    value: controlledValue,
    ...props 
  }, ref) => {
    const [value, setValue] = React.useState(controlledValue || '');
    const [isFocused, setIsFocused] = React.useState(false);
    const [showSuggestions, setShowSuggestions] = React.useState(false);
    const localRef = React.useRef<HTMLInputElement>(null);
    const inputRef = localRef as React.MutableRefObject<HTMLInputElement | null>;

    // Sync controlled value
    React.useEffect(() => {
      if (controlledValue !== undefined) {
        setValue(controlledValue);
      }
    }, [controlledValue]);

    const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
      const newValue = e.target.value;
      setValue(newValue);
      onChange?.(newValue);
      setShowSuggestions(true);
    };

    const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
      if (e.key === 'Enter') {
        e.preventDefault();
        onSearch?.(value as string);
        setShowSuggestions(false);
      }
      if (e.key === 'Escape') {
        setShowSuggestions(false);
        inputRef.current?.blur();
      }
    };

    const handleClear = () => {
      setValue('');
      onChange?.('');
      onClear?.();
      setShowSuggestions(false);
      inputRef.current?.focus();
    };

    const handleSuggestionClick = (suggestion: string) => {
      setValue(suggestion);
      onChange?.(suggestion);
      onSearch?.(suggestion);
      setShowSuggestions(false);
    };

    const isCompact = variant === 'compact';

    return (
      <div className={cn('relative w-full', className)}>
        {/* Search Container */}
        <motion.div
          className={cn(
            'relative w-full transition-all duration-200',
            // Glassmorphic base
            'bg-white/5 backdrop-blur-[24px]',
            'border border-white/10',
            'rounded-2xl',
            'shadow-[0_4px_20px_rgba(0,0,0,0.2)]',
            // Focus state with neon glow
            isFocused && [
              'bg-white/8',
              'border-[var(--neon-blue)]',
              'shadow-[0_0_20px_rgba(0,243,255,0.2),0_4px_20px_rgba(0,0,0,0.2)]',
            ],
            isCompact ? 'h-12' : 'h-14'
          )}
          animate={{
            scale: isFocused ? 1.01 : 1,
          }}
          transition={{ duration: 0.2 }}
        >
          {/* Search Icon */}
          <div className={cn(
            'absolute left-4 top-1/2 -translate-y-1/2',
            'text-muted-foreground transition-colors duration-200',
            isFocused && 'text-[var(--neon-blue)]'
          )}>
            {isLoading ? (
              <Loader2 className={cn('animate-spin', isCompact ? 'h-4 w-4' : 'h-5 w-5')} />
            ) : (
              <Search className={isCompact ? 'h-4 w-4' : 'h-5 w-5'} />
            )}
          </div>

          {/* Input Field */}
          <input
            ref={(node) => {
              // Assign to internal ref
              (inputRef as React.MutableRefObject<HTMLInputElement | null>).current = node;
              // Forward external ref
              if (typeof ref === 'function') ref(node);
              else if (ref) (ref as React.MutableRefObject<HTMLInputElement | null>).current = node;
            }}
            type="text"
            value={value}
            onChange={handleChange}
            onKeyDown={handleKeyDown}
            onFocus={() => {
              setIsFocused(true);
              if (suggestions.length > 0 && value) setShowSuggestions(true);
            }}
            onBlur={() => {
              setIsFocused(false);
              // Delay to allow suggestion click
              setTimeout(() => setShowSuggestions(false), 200);
            }}
            className={cn(
              'w-full bg-transparent',
              'text-foreground placeholder:text-muted-foreground',
              'focus:outline-none',
              'transition-all duration-200',
              isCompact ? 'text-sm px-12 py-3' : 'text-base px-14 py-4',
              // Clear button space
              value && (isCompact ? 'pr-10' : 'pr-12')
            )}
            {...props}
          />

          {/* Clear Button */}
          <AnimatePresence>
            {value && (
              <motion.button
                initial={{ opacity: 0, scale: 0.8 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 0.8 }}
                transition={{ duration: 0.15 }}
                onClick={handleClear}
                type="button"
                className={cn(
                  'absolute right-4 top-1/2 -translate-y-1/2',
                  'text-muted-foreground hover:text-foreground',
                  'transition-colors duration-200',
                  'rounded-full p-1',
                  'hover:bg-white/10'
                )}
              >
                <X className={isCompact ? 'h-4 w-4' : 'h-5 w-5'} />
              </motion.button>
            )}
          </AnimatePresence>
        </motion.div>

        {/* Suggestions Dropdown */}
        <AnimatePresence>
          {showSuggestions && suggestions.length > 0 && value && (
            <motion.div
              initial={{ opacity: 0, y: -10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -10 }}
              transition={{ duration: 0.2 }}
              className={cn(
                'absolute top-full left-0 right-0 mt-2 z-50',
                'bg-white/5 backdrop-blur-[24px]',
                'border border-white/10',
                'rounded-2xl',
                'shadow-[0_8px_30px_rgba(0,0,0,0.3)]',
                'overflow-hidden'
              )}
            >
              <div className="py-2 max-h-64 overflow-y-auto">
                {suggestions
                  .filter((s) => s.toLowerCase().includes((value as string).toLowerCase()))
                  .slice(0, 8)
                  .map((suggestion, index) => (
                    <button
                      key={index}
                      onClick={() => handleSuggestionClick(suggestion)}
                      className={cn(
                        'w-full px-4 py-3 text-left',
                        'text-sm text-foreground',
                        'hover:bg-white/10',
                        'transition-colors duration-150',
                        'flex items-center gap-3'
                      )}
                    >
                      <Search className="h-4 w-4 text-muted-foreground flex-shrink-0" />
                      <span className="truncate">{suggestion}</span>
                    </button>
                  ))}
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    );
  }
);

SearchBar.displayName = 'SearchBar';

export { SearchBar };
