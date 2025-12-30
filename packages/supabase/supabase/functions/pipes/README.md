# Edge Function Pipes

This directory contains the Pipe (orchestrator) functions for the Supabase Edge Functions.

## Structure

Each pipe handles a specific feature:
- `search_pipe.ts` - RAG-based search
- `notes_pipe.ts` - Notes generation
- `video_pipe.ts` - Video generation requests
- `doubt_pipe.ts` - Doubt resolution

## Pattern

```
USER REQUEST → PIPE (orchestrator) → FILTER(s) → ACTION(s) → RESPONSE
```

## Example

```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { validationFilter } from '../filters/validation_filter.ts';
import { ragSearchFilter } from '../filters/rag_search_filter.ts';
import { cacheAction } from '../actions/cache_action.ts';

serve(async (req) => {
  const { query } = await req.json();

  // Filter: Validation
  const validatedData = await validationFilter({ query });

  // Filter: RAG Search
  const results = await ragSearchFilter(validatedData.query);

  // Action: Cache results
  await cacheAction({ query, results });

  return new Response(JSON.stringify(results), {
    headers: { 'Content-Type': 'application/json' }
  });
});
```
