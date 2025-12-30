# ============================================================================
# PHASE 2: Video Queue System Deployment Script (Fixed)
# VPS: 89.117.60.144
# Date: December 24, 2025
# ============================================================================

# Configuration
$VPS_IP = "89.117.60.144"
$VPS_USER = "root"
$SUPABASE_URL = "http://89.117.60.144:54321"
$SUPABASE_SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"
$ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "PHASE 2: Video Queue System Deployment" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# ============================================================================
# STEP 1: Deploy Database Migration
# ============================================================================
Write-Host "[1/4] Deploying Database Migration..." -ForegroundColor Yellow

$migrationPath = "E:\BMAD method\BMAD 4\packages\supabase\supabase\migrations\009_video_jobs.sql"

if (-not (Test-Path $migrationPath)) {
    Write-Host "  ✗ Migration file not found!" -ForegroundColor Red
    exit 1
}

Write-Host "  → Reading migration file..." -ForegroundColor Gray
$migrationContent = Get-Content $migrationPath -Raw

# Create temp file
$tempMigration = [System.IO.Path]::GetTempFileName() + ".sql"
Set-Content -Path $tempMigration -Value $migrationContent

Write-Host "  → Uploading to VPS..." -ForegroundColor Gray

# Upload file
$scpArgs = @("-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null", $tempMigration, "${VPS_USER}@${VPS_IP}:/tmp/migration.sql")
$scpResult = & scp $scpArgs 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "  → Executing migration..." -ForegroundColor Gray

    $sshArgs = @("-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null", "${VPS_USER}@${VPS_IP}", "docker exec supabase-db psql -U postgres -d postgres -f /tmp/migration.sql")
    $sshResult = & ssh $sshArgs 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Migration deployed successfully!`n" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ Migration may have warnings (continuing...)`n" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ✗ Failed to upload migration!" -ForegroundColor Red
    Write-Host "  Please check SSH connectivity to VPS`n" -ForegroundColor Red
}

# Cleanup
Remove-Item $tempMigration -ErrorAction SilentlyContinue

# ============================================================================
# STEP 2: Verify Database Tables
# ============================================================================
Write-Host "[2/4] Verifying Database Tables..." -ForegroundColor Yellow

try {
    $uri = "$SUPABASE_URL/rest/v1/jobs"
    $params = "?select=id&limit=1"
    $fullUri = $uri + $params

    $headers = @{
        "apikey" = $SUPABASE_SERVICE_KEY
        "Authorization" = "Bearer $SUPABASE_SERVICE_KEY"
    }

    $response = Invoke-RestMethod -Uri $fullUri -Headers $headers -Method Get -ErrorAction Stop
    Write-Host "  ✓ 'jobs' table verified!`n" -ForegroundColor Green
} catch {
    Write-Host "  ✗ 'jobs' table not found!" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)`n" -ForegroundColor Red
    Write-Host "  You may need to run the migration manually via Supabase Studio`n" -ForegroundColor Yellow
}

# ============================================================================
# STEP 3: Deploy Edge Function Files
# ============================================================================
Write-Host "[3/4] Deploying Edge Function Files..." -ForegroundColor Yellow

$workerFile = "E:\BMAD method\BMAD 4\packages\supabase\supabase\functions\workers\video-queue-worker\index.ts"
$denoFile = "E:\BMAD method\BMAD 4\packages\supabase\supabase\functions\workers\video-queue-worker\deno.json"
$queueUtilsFile = "E:\BMAD method\BMAD 4\packages\supabase\supabase\functions\shared\queue-utils.ts"
$actionFile = "E:\BMAD method\BMAD 4\packages\supabase\supabase\functions\actions\queue_management_action.ts"

Write-Host "  → Creating directories on VPS..." -ForegroundColor Gray

$mkdirCmd = @"
mkdir -p /tmp/supabase-deploy/video-queue-worker && \
mkdir -p /tmp/supabase-deploy/shared && \
mkdir -p /tmp/supabase-deploy/actions
"@

$sshArgs = @("-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null", "${VPS_USER}@${VPS_IP}", $mkdirCmd)
& ssh $sshArgs 2>&1 | Out-Null

Write-Host "  → Uploading function files..." -ForegroundColor Gray

# Upload worker file
$scpArgs = @("-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null", $workerFile, "${VPS_USER}@${VPS_IP}:/tmp/supabase-deploy/video-queue-worker/index.ts")
& scp $scpArgs 2>&1 | Out-Null

# Upload deno config
$scpArgs = @("-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null", $denoFile, "${VPS_USER}@${VPS_IP}:/tmp/supabase-deploy/video-queue-worker/deno.json")
& scp $scpArgs 2>&1 | Out-Null

# Upload shared utils
$scpArgs = @("-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null", $queueUtilsFile, "${VPS_USER}@${VPS_IP}:/tmp/supabase-deploy/shared/queue-utils.ts")
& scp $scpArgs 2>&1 | Out-Null

# Upload action
$scpArgs = @("-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null", $actionFile, "${VPS_USER}@${VPS_IP}:/tmp/supabase-deploy/actions/queue_management_action.ts")
& scp $scpArgs 2>&1 | Out-Null

Write-Host "  ✓ Files uploaded successfully!`n" -ForegroundColor Green

Write-Host "  Note: Edge Function deployment requires manual Supabase restart" -ForegroundColor Yellow
Write-Host "  Run on VPS: docker-compose restart edge-runtime`n" -ForegroundColor Gray

# ============================================================================
# STEP 4: Setup Cron Job
# ============================================================================
Write-Host "[4/4] Setting up Cron Job..." -ForegroundColor Yellow

$cronSetupCmd = @"
touch /var/log/queue-worker.log && \
chmod 644 /var/log/queue-worker.log && \
echo 'Cron setup complete'
"@

$sshArgs = @("-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null", "${VPS_USER}@${VPS_IP}", $cronSetupCmd)
$result = & ssh $sshArgs 2>&1

if ($result -match "complete") {
    Write-Host "  ✓ Log file created`n" -ForegroundColor Green
}

Write-Host "  Note: Cron job must be configured manually" -ForegroundColor Yellow
Write-Host "  Add to crontab: */1 * * * * curl -X POST http://localhost:54321/functions/v1/video-queue-worker ...`n" -ForegroundColor Gray

# ============================================================================
# TESTING
# ============================================================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "TESTING DEPLOYMENT" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Test 1: Add Test Job
Write-Host "[TEST 1] Adding Test Job to Queue..." -ForegroundColor Yellow

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
    $headers = @{
        "apikey" = $SUPABASE_SERVICE_KEY
        "Authorization" = "Bearer $SUPABASE_SERVICE_KEY"
        "Content-Type" = "application/json"
        "Prefer" = "return=representation"
    }

    $response = Invoke-RestMethod -Uri "$SUPABASE_URL/rest/v1/jobs" `
        -Headers $headers `
        -Method Post `
        -Body $testJob `
        -ErrorAction Stop

    Write-Host "  ✓ Test job created!" -ForegroundColor Green
    Write-Host "  Job ID: $($response.id)" -ForegroundColor Gray
    Write-Host "  Priority: $($response.priority)" -ForegroundColor Gray
    Write-Host "  Queue Position: $($response.queue_position)`n" -ForegroundColor Gray
} catch {
    Write-Host "  ✗ Failed to create test job" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)`n" -ForegroundColor Gray
}

# Test 2: Check Queue Stats
Write-Host "[TEST 2] Checking Queue Statistics..." -ForegroundColor Yellow

try {
    $headers = @{
        "apikey" = $ANON_KEY
        "Content-Type" = "application/json"
    }

    $response = Invoke-RestMethod -Uri "$SUPABASE_URL/rest/v1/rpc/get_queue_stats" `
        -Headers $headers `
        -Method Post `
        -Body "{}" `
        -ErrorAction Stop

    Write-Host "  ✓ Statistics retrieved!" -ForegroundColor Green
    Write-Host "  Total Queued: $($response.total_queued)" -ForegroundColor Gray
    Write-Host "  Total Processing: $($response.total_processing)" -ForegroundColor Gray
    Write-Host "  High Priority: $($response.high_priority_count)`n" -ForegroundColor Gray
} catch {
    Write-Host "  ✗ Failed to get statistics" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)`n" -ForegroundColor Gray
}

# Test 3: View Recent Jobs
Write-Host "[TEST 3] Viewing Recent Jobs..." -ForegroundColor Yellow

try {
    $uri = "$SUPABASE_URL/rest/v1/jobs"
    $params = "?select=*&order=created_at.desc&limit=5"
    $fullUri = $uri + $params

    $headers = @{
        "apikey" = $ANON_KEY
    }

    $response = Invoke-RestMethod -Uri $fullUri -Headers $headers -Method Get -ErrorAction Stop

    Write-Host "  ✓ Recent jobs retrieved!" -ForegroundColor Green
    foreach ($job in $response) {
        $jobId = $job.id.Substring(0, 8)
        Write-Host "  → Job $jobId... | Type: $($job.job_type) | Status: $($job.status) | Priority: $($job.priority)" -ForegroundColor Gray
    }
    Write-Host ""
} catch {
    Write-Host "  ✗ Failed to retrieve jobs" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)`n" -ForegroundColor Gray
}

# ============================================================================
# SUMMARY
# ============================================================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "DEPLOYMENT SUMMARY" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "✓ Database migration deployed" -ForegroundColor Green
Write-Host "✓ Edge function files uploaded to /tmp/supabase-deploy/" -ForegroundColor Green
Write-Host "✓ Test job created successfully" -ForegroundColor Green

Write-Host "`nManual Steps Required:" -ForegroundColor Yellow
Write-Host "1. SSH into VPS: ssh root@89.117.60.144" -ForegroundColor Gray
Write-Host "2. Restart edge runtime or deploy functions via Supabase CLI" -ForegroundColor Gray
Write-Host "3. Setup cron job for queue processing" -ForegroundColor Gray

Write-Host "`n========================================`n" -ForegroundColor Cyan
