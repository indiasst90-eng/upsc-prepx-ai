# Apply migrations 013-019 to VPS Supabase database (PowerShell)
# Following BMAD methodology - Story implementation continuation

$VPS_HOST = "89.117.60.144"
$POSTGRES_PORT = "54322"
$POSTGRES_USER = "postgres"
$POSTGRES_PASSWORD = "postgres"

Write-Host "🚀 Applying migrations 013-019 to VPS Supabase database..." -ForegroundColor Green
Write-Host "VPS: $VPS_HOST" -ForegroundColor Cyan
Write-Host ""

$migrations = @(
    "013_answer_writing.sql",
    "014_pyq_videos.sql",
    "015_daily_quiz.sql",
    "016_mock_tests.sql",
    "017_daily_ca_documentary.sql",
    "018_phase5_flagship.sql",
    "019_auth_profile_trigger.sql"
)

foreach ($migration in $migrations) {
    Write-Host "📝 Applying: $migration" -ForegroundColor Yellow

    $migrationPath = "packages\supabase\supabase\migrations\$migration"
    $sqlContent = Get-Content $migrationPath -Raw

    # Copy to VPS and execute
    Write-Host "   Copying to VPS..."
    scp "$migrationPath" "root@${VPS_HOST}:/tmp/migration.sql"

    Write-Host "   Executing migration..."
    $dockerCmd = 'docker exec -i $(docker ps | grep supabase.*db | awk ''{print $1}'') psql -U postgres -d postgres < /tmp/migration.sql'
    ssh "root@$VPS_HOST" $dockerCmd

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Applied: $migration" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Warning: $migration may have failed or already applied" -ForegroundColor Yellow
    }
    Write-Host ""
}

Write-Host "✅ All migrations processed!" -ForegroundColor Green
Write-Host ""
Write-Host "🔄 Next steps:" -ForegroundColor Cyan
Write-Host "1. Verify tables: curl http://89.117.60.144:54321/rest/v1/answer_submissions?limit=1 -H 'apikey: ...'"
Write-Host "2. Regenerate types: cd packages/supabase && npx supabase gen types typescript --db-url 'postgresql://postgres:postgres@89.117.60.144:54322/postgres' > ../../apps/web/src/types/database.types.ts"
Write-Host "3. Rebuild app: cd apps/web && pnpm build"
