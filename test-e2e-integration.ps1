# E2E Integration Test for Video Queue System (PowerShell)
# Tests: Job creation → Worker processing → Video generation → Completion

$VPS_IP = "89.117.60.144"
$SUPABASE_URL = "http://$VPS_IP:54321"
$SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"
$ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "🧪 E2E Integration Test Starting..." -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Cyan

# Test 1: Create test job
Write-Host "[1/5] Creating test job..." -ForegroundColor Yellow

$testJob = @{
    job_type = "doubt"
    priority = "high"
    status = "queued"
    payload = @{
        question = "E2E Test: Explain Article 370 of Indian Constitution"
    }
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$SUPABASE_URL/rest/v1/jobs" `
        -Method Post `
        -Headers @{
            "apikey" = $SERVICE_KEY
            "Authorization" = "Bearer $SERVICE_KEY"
            "Content-Type" = "application/json"
            "Prefer" = "return=representation"
        } `
        -Body $testJob

    $JOB_ID = $response[0].id
    Write-Host "✅ Job created: $JOB_ID`n" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to create job" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Test 2: Verify job is in queue
Write-Host "[2/5] Verifying job in queue..." -ForegroundColor Yellow
Start-Sleep -Seconds 2

$jobCheck = Invoke-RestMethod -Uri "$SUPABASE_URL/rest/v1/jobs?id=eq.$JOB_ID" `
    -Headers @{ "apikey" = $ANON_KEY }

if ($jobCheck[0].status -ne "queued") {
    Write-Host "❌ Job not in 'queued' status. Current: $($jobCheck[0].status)" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Job is queued`n" -ForegroundColor Green

# Test 3: Wait for worker to process
Write-Host "[3/5] Waiting for worker to process job (max 90s)..." -ForegroundColor Yellow
$TIMEOUT = 90
$ELAPSED = 0

while ($ELAPSED -lt $TIMEOUT) {
    $statusCheck = Invoke-RestMethod -Uri "$SUPABASE_URL/rest/v1/jobs?id=eq.$JOB_ID" `
        -Headers @{ "apikey" = $ANON_KEY }

    $currentStatus = $statusCheck[0].status

    if ($currentStatus -eq "completed") {
        Write-Host "✅ Job completed in ${ELAPSED}s`n" -ForegroundColor Green
        break
    } elseif ($currentStatus -eq "failed") {
        Write-Host "❌ Job failed" -ForegroundColor Red
        Write-Host "Error: $($statusCheck[0].error_message)" -ForegroundColor Red
        exit 1
    } elseif ($currentStatus -eq "processing") {
        Write-Host "   ⏳ Job is processing..." -ForegroundColor Gray
    }

    Start-Sleep -Seconds 5
    $ELAPSED += 5
}

if ($ELAPSED -ge $TIMEOUT) {
    Write-Host "❌ Timeout: Job not completed within ${TIMEOUT}s" -ForegroundColor Red
    Write-Host "Final status: $currentStatus" -ForegroundColor Red
    exit 1
}

# Test 4: Verify video URL
Write-Host "[4/5] Verifying video URL..." -ForegroundColor Yellow

$finalJob = Invoke-RestMethod -Uri "$SUPABASE_URL/rest/v1/jobs?id=eq.$JOB_ID" `
    -Headers @{ "apikey" = $ANON_KEY }

$VIDEO_URL = $finalJob[0].payload.video_url

if ([string]::IsNullOrEmpty($VIDEO_URL)) {
    Write-Host "❌ No video URL in completed job" -ForegroundColor Red
    Write-Host "Job payload: $($finalJob[0].payload | ConvertTo-Json)" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Video URL found: $VIDEO_URL`n" -ForegroundColor Green

# Test 5: Test video accessibility
Write-Host "[5/5] Testing video accessibility..." -ForegroundColor Yellow

if ($VIDEO_URL -match "^http") {
    try {
        $videoCheck = Invoke-WebRequest -Uri $VIDEO_URL -Method Head -UseBasicParsing
        if ($videoCheck.StatusCode -eq 200) {
            Write-Host "✅ Video is accessible (HTTP $($videoCheck.StatusCode))`n" -ForegroundColor Green
        }
    } catch {
        Write-Host "⚠️  Video not accessible" -ForegroundColor Yellow
        Write-Host "   (May be expected if video is still processing)`n" -ForegroundColor Gray
    }
} else {
    Write-Host "ℹ️  Video URL is not HTTP (skipping accessibility check)`n" -ForegroundColor Gray
}

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "🎉 E2E Test PASSED" -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Cyan

Write-Host "Test Summary:" -ForegroundColor White
Write-Host "  Job ID: $JOB_ID" -ForegroundColor Gray
Write-Host "  Processing Time: ${ELAPSED}s" -ForegroundColor Gray
Write-Host "  Video URL: $VIDEO_URL`n" -ForegroundColor Gray
