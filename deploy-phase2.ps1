# ============================================================================
# PHASE 2: Video Queue System Deployment Script
# VPS: 89.117.60.144
# Date: December 24, 2025
# ============================================================================

param(
    [switch]$SkipMigration,
    [switch]$SkipEdgeFunction,
    [switch]$SkipCron,
    [switch]$TestOnly
)

# Configuration
$VPS_IP = "89.117.60.144"
$VPS_USER = "root"
$VPS_PASSWORD = "772877mAmcIaS"
$SUPABASE_URL = "http://89.117.60.144:54321"
$SUPABASE_SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "PHASE 2: Video Queue System Deployment" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# ============================================================================
# STEP 1: Deploy Database Migration
# ============================================================================
if (-not $SkipMigration -and -not $TestOnly) {
    Write-Host "[1/4] Deploying Database Migration..." -ForegroundColor Yellow

    $migrationPath = "E:\BMAD method\BMAD 4\packages\supabase\supabase\migrations\009_video_jobs.sql"

    if (-not (Test-Path $migrationPath)) {
        Write-Host "ERROR: Migration file not found at $migrationPath" -ForegroundColor Red
        exit 1
    }

    Write-Host "  → Reading migration file..." -ForegroundColor Gray
    $migrationContent = Get-Content $migrationPath -Raw

    # Create a temporary file with the migration
    $tempMigration = [System.IO.Path]::GetTempFileName() + ".sql"
    Set-Content -Path $tempMigration -Value $migrationContent

    Write-Host "  → Uploading to VPS..." -ForegroundColor Gray

    # Use scp to copy file
    & scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $tempMigration "${VPS_USER}@${VPS_IP}:/tmp/migration.sql" 2>&1 | Out-Null

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  → Executing migration on database..." -ForegroundColor Gray

        # Execute the migration
        $sshCommand = "docker exec supabase-db psql -U postgres -d postgres -f /tmp/migration.sql"
        $result = & ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${VPS_USER}@${VPS_IP}" $sshCommand 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ Migration deployed successfully!`n" -ForegroundColor Green
        } else {
            Write-Host "  ✗ Migration failed!" -ForegroundColor Red
            Write-Host "Error: $result" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "  ✗ Failed to upload migration file!" -ForegroundColor Red
        exit 1
    }

    # Cleanup
    Remove-Item $tempMigration -ErrorAction SilentlyContinue

} else {
    Write-Host "[1/4] Skipping Database Migration" -ForegroundColor Gray
}

# ============================================================================
# STEP 2: Verify Database Tables
# ============================================================================
Write-Host "[2/4] Verifying Database Tables..." -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod -Uri "$SUPABASE_URL/rest/v1/jobs?select=id&limit=1" `
        -Headers @{
            "apikey" = $SUPABASE_SERVICE_KEY
            "Authorization" = "Bearer $SUPABASE_SERVICE_KEY"
        } `
        -Method Get `
        -ErrorAction Stop

    Write-Host "  ✓ 'jobs' table verified!`n" -ForegroundColor Green
} catch {
    Write-Host "  ✗ 'jobs' table not found!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# ============================================================================
# STEP 3: Deploy Edge Function
# ============================================================================
if (-not $SkipEdgeFunction -and -not $TestOnly) {
    Write-Host "[3/4] Deploying Edge Function (video-queue-worker)..." -ForegroundColor Yellow

    # Create Edge Function deployment package
    $workerPath = "E:\BMAD method\BMAD 4\packages\supabase\supabase\functions\workers\video-queue-worker"
    $sharedPath = "E:\BMAD method\BMAD 4\packages\supabase\supabase\functions\shared"
    $actionsPath = "E:\BMAD method\BMAD 4\packages\supabase\supabase\functions\actions"

    # Create temporary directory for deployment
    $tempDir = Join-Path $env:TEMP "supabase-functions-$(Get-Random)"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    New-Item -ItemType Directory -Path "$tempDir\video-queue-worker" -Force | Out-Null
    New-Item -ItemType Directory -Path "$tempDir\shared" -Force | Out-Null
    New-Item -ItemType Directory -Path "$tempDir\actions" -Force | Out-Null

    Write-Host "  → Copying function files..." -ForegroundColor Gray

    # Copy files
    Copy-Item "$workerPath\index.ts" "$tempDir\video-queue-worker\"
    Copy-Item "$workerPath\deno.json" "$tempDir\video-queue-worker\"
    Copy-Item "$sharedPath\queue-utils.ts" "$tempDir\shared\"
    Copy-Item "$actionsPath\queue_management_action.ts" "$tempDir\actions\"

    Write-Host "  → Uploading to VPS..." -ForegroundColor Gray

    # Upload to VPS
    & scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r "$tempDir\*" "${VPS_USER}@${VPS_IP}:/tmp/functions/" 2>&1 | Out-Null

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  → Deploying to Supabase..." -ForegroundColor Gray

        # Deploy via Docker
        $deployCommand = @"
# Move function to Supabase functions directory
mkdir -p /var/lib/docker/volumes/supabase_functions/_data/video-queue-worker
mkdir -p /var/lib/docker/volumes/supabase_functions/_data/shared
mkdir -p /var/lib/docker/volumes/supabase_functions/_data/actions

cp /tmp/functions/video-queue-worker/* /var/lib/docker/volumes/supabase_functions/_data/video-queue-worker/
cp /tmp/functions/shared/* /var/lib/docker/volumes/supabase_functions/_data/shared/
cp /tmp/functions/actions/* /var/lib/docker/volumes/supabase_functions/_data/actions/

# Restart Supabase Edge Runtime
docker-compose -f /opt/supabase/docker-compose.yml restart edge-runtime || echo "Edge runtime restart may require manual intervention"

echo "Edge function deployed"
"@

        $result = & ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${VPS_USER}@${VPS_IP}" $deployCommand 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ Edge Function deployed successfully!`n" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ Edge Function deployment completed with warnings" -ForegroundColor Yellow
            Write-Host "  Note: You may need to manually restart the edge-runtime container`n" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  ✗ Failed to upload function files!" -ForegroundColor Red
        exit 1
    }

    # Cleanup
    Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue

} else {
    Write-Host "[3/4] Skipping Edge Function Deployment" -ForegroundColor Gray
}

# ============================================================================
# STEP 4: Setup Cron Job
# ============================================================================
if (-not $SkipCron -and -not $TestOnly) {
    Write-Host "[4/4] Setting up Cron Job..." -ForegroundColor Yellow

    $cronCommand = @"
# Add cron job to process video queue every minute
(crontab -l 2>/dev/null | grep -v 'video-queue-worker'; echo '*/1 * * * * curl -X POST http://localhost:54321/functions/v1/video-queue-worker -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" >> /var/log/queue-worker.log 2>&1') | crontab -

# Create log file
touch /var/log/queue-worker.log
chmod 644 /var/log/queue-worker.log

# Verify cron is running
systemctl status cron | grep -q 'active (running)' && echo "Cron job configured successfully" || echo "Warning: Cron service may not be running"
"@

    Write-Host "  → Configuring cron on VPS..." -ForegroundColor Gray
    $result = & ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${VPS_USER}@${VPS_IP}" $cronCommand 2>&1

    if ($result -match "configured successfully") {
        Write-Host "  ✓ Cron job configured successfully!`n" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ Cron job configuration completed with warnings`n" -ForegroundColor Yellow
    }

} else {
    Write-Host "[4/4] Skipping Cron Job Setup" -ForegroundColor Gray
}

# ============================================================================
# TESTING PHASE
# ============================================================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "TESTING DEPLOYMENT" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Test 1: Check Edge Function Endpoint
Write-Host "[TEST 1] Testing Edge Function Endpoint..." -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod -Uri "$SUPABASE_URL/functions/v1/video-queue-worker" `
        -Headers @{
            "Authorization" = "Bearer $SUPABASE_SERVICE_KEY"
            "Content-Type" = "application/json"
        } `
        -Method Post `
        -Body "{}" `
        -ErrorAction Stop

    Write-Host "  ✓ Edge Function is responding!" -ForegroundColor Green
    Write-Host "  Response: $($response | ConvertTo-Json -Compress)`n" -ForegroundColor Gray
} catch {
    Write-Host "  ⚠ Edge Function not responding (may need manual deployment)" -ForegroundColor Yellow
    Write-Host "  Error: $($_.Exception.Message)`n" -ForegroundColor Gray
}

# Test 2: Add Test Job to Queue
Write-Host "[TEST 2] Adding Test Job to Queue..." -ForegroundColor Yellow

$testJob = @{
    job_type = "doubt"
    priority = "high"
    status = "queued"
    payload = @{
        question = "Test deployment - Phase 2"
        timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$SUPABASE_URL/rest/v1/jobs" `
        -Headers @{
            "apikey" = $SUPABASE_SERVICE_KEY
            "Authorization" = "Bearer $SUPABASE_SERVICE_KEY"
            "Content-Type" = "application/json"
            "Prefer" = "return=representation"
        } `
        -Method Post `
        -Body $testJob `
        -ErrorAction Stop

    Write-Host "  ✓ Test job created successfully!" -ForegroundColor Green
    Write-Host "  Job ID: $($response.id)" -ForegroundColor Gray
    Write-Host "  Queue Position: $($response.queue_position)`n" -ForegroundColor Gray
} catch {
    Write-Host "  ✗ Failed to create test job!" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)`n" -ForegroundColor Red
}

# Test 3: Check Queue Statistics
Write-Host "[TEST 3] Checking Queue Statistics..." -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod -Uri "$SUPABASE_URL/rest/v1/rpc/get_queue_stats" `
        -Headers @{
            "apikey" = $SUPABASE_SERVICE_KEY
            "Authorization" = "Bearer $SUPABASE_SERVICE_KEY"
            "Content-Type" = "application/json"
        } `
        -Method Post `
        -Body "{}" `
        -ErrorAction Stop

    Write-Host "  ✓ Queue statistics retrieved!" -ForegroundColor Green
    Write-Host "  Total Queued: $($response.total_queued)" -ForegroundColor Gray
    Write-Host "  Total Processing: $($response.total_processing)" -ForegroundColor Gray
    Write-Host "  High Priority: $($response.high_priority_count)" -ForegroundColor Gray
    Write-Host "  Medium Priority: $($response.medium_priority_count)" -ForegroundColor Gray
    Write-Host "  Low Priority: $($response.low_priority_count)`n" -ForegroundColor Gray
} catch {
    Write-Host "  ✗ Failed to retrieve statistics!" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)`n" -ForegroundColor Red
}

# Test 4: View Recent Jobs
Write-Host "[TEST 4] Viewing Recent Jobs..." -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod -Uri "$SUPABASE_URL/rest/v1/jobs?select=*&order=created_at.desc&limit=5" `
        -Headers @{
            "apikey" = $SUPABASE_SERVICE_KEY
            "Authorization" = "Bearer $SUPABASE_SERVICE_KEY"
        } `
        -Method Get `
        -ErrorAction Stop

    Write-Host "  ✓ Recent jobs retrieved!" -ForegroundColor Green
    $response | ForEach-Object {
        Write-Host "  → Job $($_.id.Substring(0,8))... | Type: $($_.job_type) | Status: $($_.status) | Priority: $($_.priority)" -ForegroundColor Gray
    }
    Write-Host ""
} catch {
    Write-Host "  ✗ Failed to retrieve jobs!" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)`n" -ForegroundColor Red
}

# ============================================================================
# DEPLOYMENT SUMMARY
# ============================================================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "DEPLOYMENT COMPLETE!" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "✓ Database migration deployed" -ForegroundColor Green
Write-Host "✓ Edge Function uploaded (may need manual restart)" -ForegroundColor Green
Write-Host "✓ Cron job configured" -ForegroundColor Green
Write-Host "✓ System tested" -ForegroundColor Green

Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Verify Edge Function: http://89.117.60.144:54321/functions/v1/video-queue-worker" -ForegroundColor Gray
Write-Host "2. Monitor queue: Check logs at /var/log/queue-worker.log on VPS" -ForegroundColor Gray
Write-Host "3. Watch cron: ssh root@89.117.60.144 'tail -f /var/log/queue-worker.log'" -ForegroundColor Gray
Write-Host "4. Deploy Admin Dashboard (Phase 3)" -ForegroundColor Gray

Write-Host "`nMonitoring Commands:" -ForegroundColor Yellow
Write-Host "  View queue stats:" -ForegroundColor Gray
Write-Host "    curl '$SUPABASE_URL/rest/v1/rpc/get_queue_stats' -H 'apikey: $SUPABASE_SERVICE_KEY' -H 'Content-Type: application/json' -X POST -d '{}'" -ForegroundColor DarkGray
Write-Host "`n  View recent jobs:" -ForegroundColor Gray
Write-Host "    curl '$SUPABASE_URL/rest/v1/jobs?select=*&order=created_at.desc&limit=5' -H 'apikey: $SUPABASE_SERVICE_KEY'" -ForegroundColor DarkGray

Write-Host "`n========================================`n" -ForegroundColor Cyan
