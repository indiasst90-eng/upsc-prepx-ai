$ErrorActionPreference = "Stop"

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Applying Migration 023 - Study Schedules" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

$migrationFile = "packages\supabase\supabase\migrations\023_study_schedules.sql"

if (-not (Test-Path $migrationFile)) {
    Write-Host "Error: Migration file not found: $migrationFile" -ForegroundColor Red
    exit 1
}

Write-Host "[1/2] Reading migration file..." -ForegroundColor Yellow
$migrationSQL = Get-Content $migrationFile -Raw
Write-Host "      Migration size: $($migrationSQL.Length) bytes" -ForegroundColor Gray
Write-Host ""

Write-Host "[2/2] Applying to VPS database..." -ForegroundColor Yellow
Write-Host "      Host: 89.117.60.144" -ForegroundColor Gray
Write-Host "      Database: postgres" -ForegroundColor Gray
Write-Host ""

# Use psql via SSH or direct connection
$env:PGPASSWORD = "772877mAmcIaS"

try {
    # Try direct psql connection
    $result = $migrationSQL | psql -h 89.117.60.144 -p 5432 -U postgres -d postgres 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "=====================================" -ForegroundColor Green
        Write-Host "SUCCESS: Migration 023 Applied!" -ForegroundColor Green
        Write-Host "=====================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Tables created:" -ForegroundColor White
        Write-Host "  ✓ study_schedules" -ForegroundColor Green
        Write-Host "  ✓ schedule_tasks" -ForegroundColor Green
        Write-Host ""
        exit 0
    } else {
        throw "psql command failed"
    }
} catch {
    Write-Host ""
    Write-Host "=====================================" -ForegroundColor Red
    Write-Host "ERROR: Automatic migration failed" -ForegroundColor Red
    Write-Host "=====================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Manual application required:" -ForegroundColor Yellow
    Write-Host "1. Open: http://89.117.60.144:3000" -ForegroundColor White
    Write-Host "2. Go to SQL Editor" -ForegroundColor White
    Write-Host "3. Copy and execute contents of:" -ForegroundColor White
    Write-Host "   $migrationFile" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Migration SQL Preview:" -ForegroundColor Yellow
    Write-Host $migrationSQL.Substring(0, [Math]::Min(500, $migrationSQL.Length)) -ForegroundColor Gray
    Write-Host "..." -ForegroundColor Gray
    exit 1
}
