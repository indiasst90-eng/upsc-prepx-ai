# Coding Standards

**Version:** 1.0
**Last Updated:** December 23, 2025
**Source:** Extracted from `docs/architecture.md` Section 16

---

## TypeScript Standards

### Type Safety

**Strict Mode:** Always enabled in `tsconfig.json`

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true
  }
}
```

**Type Annotations:**
- Always explicitly type function parameters
- Always explicitly type function return types
- Use `unknown` instead of `any` when type is truly unknown
- Prefer `interface` for object shapes, `type` for unions/intersections

**Examples:**

```typescript
// ✅ GOOD
function calculateTotal(items: CartItem[]): number {
  return items.reduce((sum, item) => sum + item.price, 0)
}

// ❌ BAD
function calculateTotal(items) {
  return items.reduce((sum, item) => sum + item.price, 0)
}

// ✅ GOOD - Interface for object shape
interface User {
  id: string
  email: string
  name: string
}

// ✅ GOOD - Type for union
type Status = 'pending' | 'in_progress' | 'completed' | 'failed'

// ❌ BAD - Using 'any'
function processData(data: any): any {
  return data.value
}

// ✅ GOOD - Using 'unknown' with type guard
function processData(data: unknown): string {
  if (typeof data === 'object' && data !== null && 'value' in data) {
    return String(data.value)
  }
  throw new Error('Invalid data format')
}
```

### Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| **Variables** | camelCase | `const userName = 'John'` |
| **Constants** | UPPER_SNAKE_CASE | `const MAX_RETRIES = 3` |
| **Functions** | camelCase | `function formatDate() {}` |
| **Classes** | PascalCase | `class UserService {}` |
| **Interfaces** | PascalCase, no `I` prefix | `interface User {}` |
| **Types** | PascalCase | `type Status = 'pending'` |
| **Enums** | PascalCase | `enum VideoStatus {}` |
| **React Components** | PascalCase | `function SearchBar() {}` |
| **Custom Hooks** | camelCase, `use` prefix | `function useAuth() {}` |
| **Files (Components)** | PascalCase | `SearchBar.tsx` |
| **Files (Utilities)** | camelCase | `formatDate.ts` |
| **Edge Functions** | snake_case | `doubt_video_converter_pipe` |

---

## React Standards

### Component Structure

**Functional Components Only:** No class components

```typescript
// ✅ GOOD - Functional component with TypeScript
interface SearchBarProps {
  onSearch: (query: string) => void
  placeholder?: string
}

export function SearchBar({ onSearch, placeholder = 'Search...' }: SearchBarProps) {
  const [query, setQuery] = useState('')

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault()
    onSearch(query)
  }

  return (
    <form onSubmit={handleSubmit}>
      <input
        type="text"
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        placeholder={placeholder}
      />
      <button type="submit">Search</button>
    </form>
  )
}
```

### Props and State

**Props:**
- Always define explicit prop types with `interface` or `type`
- Use destructuring in function parameters
- Provide default values for optional props

**State:**
- Use `useState` for component state
- Use Zustand for global state
- Use React Query for server state

```typescript
// ✅ GOOD - Explicit prop types
interface VideoPlayerProps {
  videoId: string
  autoplay?: boolean
  onEnded?: () => void
}

export function VideoPlayer({
  videoId,
  autoplay = false,
  onEnded
}: VideoPlayerProps) {
  const [isPlaying, setIsPlaying] = useState(autoplay)

  return <video src={`/videos/${videoId}`} />
}

// ✅ GOOD - Zustand store for global state
interface AuthState {
  user: User | null
  login: (email: string, password: string) => Promise<void>
  logout: () => void
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  login: async (email, password) => {
    const user = await supabase.auth.signInWithPassword({ email, password })
    set({ user: user.data.user })
  },
  logout: () => set({ user: null })
}))
```

### Hooks

**Custom Hooks:**
- Always start with `use` prefix
- Extract complex logic into custom hooks
- Return object with named properties (not arrays for more than 2 values)

```typescript
// ✅ GOOD - Custom hook with object return
interface UseVideoRenderResult {
  isRendering: boolean
  progress: number
  error: Error | null
  startRender: (scriptId: string) => Promise<void>
}

export function useVideoRender(): UseVideoRenderResult {
  const [isRendering, setIsRendering] = useState(false)
  const [progress, setProgress] = useState(0)
  const [error, setError] = useState<Error | null>(null)

  const startRender = async (scriptId: string) => {
    setIsRendering(true)
    setError(null)
    try {
      await api.renderVideo(scriptId, (progress) => setProgress(progress))
    } catch (err) {
      setError(err as Error)
    } finally {
      setIsRendering(false)
    }
  }

  return { isRendering, progress, error, startRender }
}
```

---

## Supabase Edge Functions Standards

### Pipes/Filters/Actions Pattern

**Pipe Structure:**

```typescript
// pipes/doubt_video_converter_pipe/index.ts

import { authFilter } from '../filters/auth_filter.ts'
import { entitlementCheckFilter } from '../filters/entitlement_check_filter.ts'
import { ragInjectorFilter } from '../filters/rag_injector_filter.ts'
import { generateScriptAction } from '../actions/generate_script_action.ts'
import { renderVideoAction } from '../actions/render_video_action.ts'

export async function doubtVideoConverterPipe(req: Request): Promise<Response> {
  try {
    // STEP 1: Apply filters (validation/enrichment)
    const authContext = await authFilter(req)
    const entitlementContext = await entitlementCheckFilter(authContext, 'doubt_video_converter')
    const enrichedContext = await ragInjectorFilter(entitlementContext)

    // STEP 2: Execute actions (side effects)
    const script = await generateScriptAction(enrichedContext)
    const videoJob = await renderVideoAction(script)

    // STEP 3: Return response
    return new Response(JSON.stringify({ jobId: videoJob.id }), {
      status: 202,
      headers: { 'Content-Type': 'application/json' }
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    })
  }
}
```

**Filter Structure:**

```typescript
// filters/auth_filter.ts

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

export async function authFilter(req: Request): Promise<AuthContext> {
  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    throw new Error('Missing Authorization header')
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } }
  )

  const { data: { user }, error } = await supabase.auth.getUser()
  if (error || !user) {
    throw new Error('Invalid authentication token')
  }

  return { user, request: req }
}
```

**Action Structure:**

```typescript
// actions/render_video_action.ts

export async function renderVideoAction(script: VideoScript): Promise<VideoJob> {
  const response = await fetch(`${Deno.env.get('VPS_ORCHESTRATOR_URL')}/render`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ script })
  })

  if (!response.ok) {
    throw new Error(`Video render failed: ${response.statusText}`)
  }

  const job = await response.json()
  return job
}
```

### Error Handling

**Unified Error Format:**

```typescript
interface ApiError {
  error: {
    code: string
    message: string
    details?: unknown
  }
}

function createErrorResponse(code: string, message: string, status: number): Response {
  const error: ApiError = {
    error: { code, message }
  }
  return new Response(JSON.stringify(error), {
    status,
    headers: { 'Content-Type': 'application/json' }
  })
}

// Usage
if (!user) {
  return createErrorResponse('AUTH_REQUIRED', 'Authentication required', 401)
}
```

**Standard Error Codes:**
- `AUTH_REQUIRED`: Missing authentication (401)
- `AUTH_INVALID`: Invalid token (401)
- `PERMISSION_DENIED`: Insufficient permissions (403)
- `ENTITLEMENT_EXCEEDED`: Quota exceeded (403)
- `RESOURCE_NOT_FOUND`: Resource not found (404)
- `VALIDATION_ERROR`: Invalid input (400)
- `RATE_LIMIT_EXCEEDED`: Too many requests (429)
- `INTERNAL_ERROR`: Server error (500)

---

## Database Standards

### Query Patterns

**Use Supabase Client (Not Raw SQL):**

```typescript
// ✅ GOOD - Supabase client with type safety
const { data, error } = await supabase
  .from('video_renders')
  .select('*')
  .eq('user_id', userId)
  .eq('status', 'completed')
  .order('created_at', { ascending: false })
  .limit(10)

// ❌ BAD - Raw SQL (harder to test, no type safety)
const { data, error } = await supabase.rpc('get_user_videos', { user_id: userId })
```

**Transaction Pattern:**

```typescript
// Use database functions for multi-step operations
const { data, error } = await supabase.rpc('create_video_render_job', {
  p_user_id: userId,
  p_script: script,
  p_duration: duration
})
```

### Migration Standards

**File Naming:** `{sequence}_{description}.sql`
- Example: `00001_initial_schema.sql`
- Example: `00002_add_video_tables.sql`

**Migration Structure:**

```sql
-- Migration: Add video_renders table
-- Created: 2025-12-23

-- Create table
CREATE TABLE video_renders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status TEXT NOT NULL CHECK (status IN ('queued', 'processing', 'completed', 'failed')),
  script JSONB NOT NULL,
  output_url TEXT,
  error TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_video_renders_user_id ON video_renders(user_id);
CREATE INDEX idx_video_renders_status ON video_renders(status);
CREATE INDEX idx_video_renders_created_at ON video_renders(created_at DESC);

-- Enable RLS
ALTER TABLE video_renders ENABLE ROW LEVEL SECURITY;

-- RLS policies
CREATE POLICY "Users can view own video renders"
  ON video_renders FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own video renders"
  ON video_renders FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Create trigger for updated_at
CREATE TRIGGER set_video_renders_updated_at
  BEFORE UPDATE ON video_renders
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Comments
COMMENT ON TABLE video_renders IS 'Stores video render jobs and their status';
COMMENT ON COLUMN video_renders.script IS 'JSONB containing video script and scene specifications';
```

---

## Testing Standards

### Unit Tests

**Test File Naming:** `{ComponentName}.test.ts(x)`

**Test Structure:**

```typescript
// SearchBar.test.tsx

import { render, screen, fireEvent } from '@testing-library/react'
import { SearchBar } from './SearchBar'

describe('SearchBar', () => {
  it('renders with placeholder text', () => {
    render(<SearchBar onSearch={vi.fn()} placeholder="Search..." />)
    expect(screen.getByPlaceholderText('Search...')).toBeInTheDocument()
  })

  it('calls onSearch with query when form is submitted', () => {
    const handleSearch = vi.fn()
    render(<SearchBar onSearch={handleSearch} />)

    const input = screen.getByRole('textbox')
    fireEvent.change(input, { target: { value: 'test query' } })

    const form = screen.getByRole('form')
    fireEvent.submit(form)

    expect(handleSearch).toHaveBeenCalledWith('test query')
  })

  it('resets input after submission', () => {
    render(<SearchBar onSearch={vi.fn()} />)

    const input = screen.getByRole('textbox') as HTMLInputElement
    fireEvent.change(input, { target: { value: 'test' } })
    fireEvent.submit(screen.getByRole('form'))

    expect(input.value).toBe('')
  })
})
```

### Integration Tests

**Edge Function Tests:**

```typescript
// pipes/doubt_video_converter_pipe/index.test.ts

import { assertEquals } from 'https://deno.land/std@0.208.0/testing/asserts.ts'
import { doubtVideoConverterPipe } from './index.ts'

Deno.test('doubt_video_converter_pipe returns 401 without auth', async () => {
  const req = new Request('http://localhost/doubt-video-converter', {
    method: 'POST',
    body: JSON.stringify({ query: 'Explain inflation' })
  })

  const res = await doubtVideoConverterPipe(req)
  assertEquals(res.status, 401)
})

Deno.test('doubt_video_converter_pipe accepts valid request', async () => {
  const req = new Request('http://localhost/doubt-video-converter', {
    method: 'POST',
    headers: {
      'Authorization': 'Bearer valid-token-here'
    },
    body: JSON.stringify({ query: 'Explain inflation' })
  })

  const res = await doubtVideoConverterPipe(req)
  assertEquals(res.status, 202)

  const body = await res.json()
  assertEquals(typeof body.jobId, 'string')
})
```

---

## Code Review Checklist

Before submitting a PR, verify:

- [ ] All TypeScript errors resolved (`pnpm type-check`)
- [ ] All ESLint warnings fixed (`pnpm lint`)
- [ ] All tests passing (`pnpm test`)
- [ ] Code formatted with Prettier (auto-format on save)
- [ ] No `console.log` statements (use proper logging)
- [ ] No hardcoded secrets or API keys
- [ ] All functions have explicit return types
- [ ] All components have prop type definitions
- [ ] All database queries use RLS policies
- [ ] Error handling implemented for all external calls
- [ ] Unit tests added for new functions/components
- [ ] Integration tests added for new Edge Functions

---

## Performance Guidelines

### Frontend Optimization

- Use `React.memo()` for expensive components
- Use `useMemo()` and `useCallback()` to prevent unnecessary re-renders
- Lazy-load routes with `next/dynamic`
- Optimize images with `next/image`
- Minimize bundle size (check with `pnpm build --analyze`)

### Backend Optimization

- Cache LLM responses in Redis (70% hit rate target)
- Use database indexes for all query filters
- Batch database operations when possible
- Use Supabase RPC functions for complex multi-step operations
- Implement rate limiting on all public endpoints

---

## Security Guidelines

### Authentication

- NEVER expose `SUPABASE_SERVICE_ROLE_KEY` to frontend
- Always use `SUPABASE_ANON_KEY` on client side
- Verify JWT tokens in Edge Functions before processing
- Use httpOnly cookies for session management

### Authorization

- Apply RLS policies on ALL database tables
- Check entitlements before granting access to premium features
- Validate user permissions in Edge Functions
- Never trust client-side checks alone

### Input Validation

- Validate all user input with Zod schemas
- Sanitize HTML content before rendering
- Use parameterized queries (Supabase client handles this)
- Implement rate limiting on all endpoints

---

## Documentation Standards

### Code Comments

**When to comment:**
- Complex algorithms or business logic
- Non-obvious workarounds
- Security-critical sections
- Performance optimizations

**When NOT to comment:**
- Self-explanatory code
- Function signatures (use TypeScript types instead)
- Obvious variable names

```typescript
// ❌ BAD - Obvious comment
// Get the user by ID
const user = await getUserById(userId)

// ✅ GOOD - Explains non-obvious logic
// We use exponential backoff here because the video rendering service
// occasionally returns 503 errors during high load, but recovers quickly
const result = await retryWithBackoff(renderVideo, { maxRetries: 3 })
```

### README Files

Every package and app should have a `README.md` with:
- Purpose and overview
- Setup instructions
- Development commands
- Testing instructions
- Deployment process (if applicable)

---

## Version Control

### Commit Messages

Follow Conventional Commits format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(search): add semantic search with pgvector

Implemented RAG-based search using pgvector embeddings.
Query latency is <500ms as required.

Closes #42
```

```
fix(auth): resolve refresh token expiration bug

Fixed issue where refresh tokens were not being properly
renewed after 7 days, causing users to be logged out.
```

### Branch Naming

- `feat/feature-name` - New features
- `fix/bug-description` - Bug fixes
- `docs/doc-update` - Documentation
- `refactor/code-improvement` - Refactoring

---

## Project-Specific Rules

### Pipes/Filters/Actions

- **Never skip filters**: Always apply auth, entitlement, and validation filters
- **Actions should be idempotent**: Safe to retry without side effects
- **Filters should be pure**: No side effects, only validation/enrichment
- **Pipe orchestration only**: Pipes coordinate, they don't contain business logic

### Video Generation

- **Always check cache first**: Before rendering, check `manim_scene_cache`
- **Use job queue**: Never block requests waiting for video render
- **Implement timeouts**: Video renders timeout after 10 minutes
- **Store render metadata**: Always log render time, cost, and quality metrics

### RAG System

- **Chunk size**: Maximum 1000 tokens per chunk, 200 token overlap
- **Embedding dimension**: Always 1536 (text-embedding-ada-002)
- **Similarity threshold**: Minimum 0.7 cosine similarity for relevance
- **Context window**: Maximum 5 chunks per query

### Subscription/Entitlement

- **Always check entitlements**: Before any premium feature access
- **Graceful degradation**: Free users see upgrade prompts, not errors
- **Trial handling**: 7-day full access, then downgrade to Free (not block)
- **Usage tracking**: Increment usage counters atomically
