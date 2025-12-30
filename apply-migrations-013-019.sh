#!/bin/bash
# Apply migrations 013-019 to VPS Supabase database
# Following BMAD methodology - Story implementation continuation

set -e

VPS_HOST="89.117.60.144"
POSTGRES_PORT="54322"
POSTGRES_USER="postgres"
POSTGRES_PASSWORD="postgres"
POSTGRES_DB="postgres"

echo "🚀 Applying migrations 013-019 to VPS Supabase database..."
echo "VPS: $VPS_HOST"
echo ""

# Migrations to apply in order
MIGRATIONS=(
    "013_answer_writing.sql"
    "014_pyq_videos.sql"
    "015_daily_quiz.sql"
    "016_mock_tests.sql"
    "017_daily_ca_documentary.sql"
    "018_phase5_flagship.sql"
    "019_auth_profile_trigger.sql"
)

for migration in "${MIGRATIONS[@]}"; do
    echo "📝 Applying: $migration"

    # Copy migration to VPS temp location
    scp "packages/supabase/supabase/migrations/$migration" root@$VPS_HOST:/tmp/migration.sql

    # Execute via docker exec into Supabase DB container
    ssh root@$VPS_HOST "docker exec -i \$(docker ps | grep 'supabase.*db' | awk '{print \$1}') psql -U postgres -d postgres < /tmp/migration.sql"

    if [ $? -eq 0 ]; then
        echo "✅ Applied: $migration"
    else
        echo "⚠️  Warning: $migration may have failed or already applied"
    fi
    echo ""
done

echo "✅ All migrations processed!"
echo ""
echo "🔄 Next steps:"
echo "1. Verify tables created: curl http://89.117.60.144:54321/rest/v1/answer_submissions?limit=1 -H 'apikey: ...'"
echo "2. Regenerate types: cd packages/supabase && npx supabase gen types typescript --db-url 'postgresql://postgres:postgres@89.117.60.144:54322/postgres' > ../../apps/web/src/types/database.types.ts"
echo "3. Rebuild web app: cd apps/web && pnpm build"
