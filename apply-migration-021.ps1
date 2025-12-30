# Apply Migration 021: Monetization System
# This script applies the complete monetization system migration to the VPS database

$VPS_IP = "89.117.60.144"
$DB_PORT = "54322"
$DB_NAME = "postgres"
$DB_USER = "postgres"
$DB_PASSWORD = "postgres"

$MIGRATION_FILE = "packages/supabase/supabase/migrations/021_monetization_system.sql"

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Applying Migration 021" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Check if migration file exists
if (-not (Test-Path $MIGRATION_FILE)) {
    Write-Host "ERROR: Migration file not found: $MIGRATION_FILE" -ForegroundColor Red
    exit 1
}

Write-Host "[1/3] Reading migration file..." -ForegroundColor Yellow
$sql = Get-Content $MIGRATION_FILE -Raw
Write-Host "      Migration size: $($sql.Length) bytes" -ForegroundColor Gray

Write-Host "[2/3] Connecting to VPS database..." -ForegroundColor Yellow
Write-Host "      Host: $VPS_IP" -ForegroundColor Gray
Write-Host "      Port: $DB_PORT" -ForegroundColor Gray

# Set PostgreSQL password environment variable
$env:PGPASSWORD = $DB_PASSWORD

Write-Host "[3/3] Executing migration..." -ForegroundColor Yellow

# Execute migration using psql
$sql | & psql -h $VPS_IP -p $DB_PORT -U $DB_USER -d $DB_NAME 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "SUCCESS: Migration 021 applied successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Tables created:" -ForegroundColor Cyan
    Write-Host "  - payment_transactions" -ForegroundColor Gray
    Write-Host "  - feature_manifests" -ForegroundColor Gray
    Write-Host "  - coupons" -ForegroundColor Gray
    Write-Host "  - coupon_usages" -ForegroundColor Gray
    Write-Host "  - referrals" -ForegroundColor Gray
    Write-Host "  - subscription_events" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Functions created:" -ForegroundColor Cyan
    Write-Host "  - check_entitlement()" -ForegroundColor Gray
    Write-Host "  - validate_coupon()" -ForegroundColor Gray
    Write-Host "  - generate_referral_code()" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Sample coupons inserted:" -ForegroundColor Cyan
    Write-Host "  - WELCOME20 (20% off)" -ForegroundColor Gray
    Write-Host "  - ANNUAL50 (50% off)" -ForegroundColor Gray
    Write-Host "  - FLAT100 (₹100 off)" -ForegroundColor Gray
} else {
    Write-Host ""
    Write-Host "ERROR: Migration failed!" -ForegroundColor Red
    Write-Host "Check the error messages above for details" -ForegroundColor Yellow
    exit 1
}

# Clear password from environment
Remove-Item Env:\PGPASSWORD
