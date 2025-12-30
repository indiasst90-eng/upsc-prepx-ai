# Apply all Supabase migrations to VPS database
# Run this from project root

$SUPABASE_DB_URL = "postgresql://postgres:your-super-secret-and-long-postgres-password@89.117.60.144:54322/postgres"

Write-Host "Applying Supabase migrations to VPS database..." -ForegroundColor Green

# Get all migration files sorted
$migrations = Get-ChildItem -Path "packages\supabase\supabase\migrations\*.sql" | Sort-Object Name

foreach ($migration in $migrations) {
    Write-Host "`nApplying: $($migration.Name)" -ForegroundColor Cyan

    # Apply migration using psql
    $content = Get-Content $migration.FullName -Raw

    # Use Supabase REST API to execute SQL
    $response = Invoke-RestMethod -Uri "http://89.117.60.144:54321/rest/v1/rpc/exec_sql" `
        -Method POST `
        -Headers @{
            "apikey" = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"
            "Authorization" = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"
            "Content-Type" = "application/json"
        } `
        -Body (ConvertTo-Json @{ query = $content }) `
        -ErrorAction SilentlyContinue

    if ($?) {
        Write-Host "✓ Applied successfully" -ForegroundColor Green
    } else {
        Write-Host "✗ Failed (may already be applied)" -ForegroundColor Yellow
    }
}

Write-Host "`n✓ All migrations processed!" -ForegroundColor Green
Write-Host "`nNext steps:"
Write-Host "1. Regenerate TypeScript types: cd packages/supabase && pnpm run gen-types"
Write-Host "2. Copy types to web app: cp supabase/types/database.types.ts ../../apps/web/src/types/"
Write-Host "3. Rebuild web app: cd ../../apps/web && pnpm build"
