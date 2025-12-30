#!/bin/bash
# Apply all Supabase migrations to VPS database

set -e

VPS_HOST="89.117.60.144"
DB_URL="postgresql://postgres:postgres@localhost:54322/postgres"

echo "Applying all Supabase migrations to VPS..."

# Copy migrations to VPS
scp -r packages/supabase/supabase/migrations root@$VPS_HOST:/tmp/

# SSH and apply migrations
ssh root@$VPS_HOST <<'ENDSSH'
cd /tmp/migrations

for migration in *.sql; do
    echo "Applying: $migration"
    docker exec supabase-db psql -U postgres -d postgres -f "/tmp/migrations/$migration" || echo "Warning: $migration may have failed or already applied"
done

echo "✓ All migrations processed!"
ENDSSH

echo ""
echo "Next: Regenerate TypeScript types"
echo "Run: cd packages/supabase && npx supabase gen types typescript --local > ../../apps/web/src/types/database.types.ts"
