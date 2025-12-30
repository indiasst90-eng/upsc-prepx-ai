# Deploy Admin Dashboard to VPS
# Date: December 24, 2025

$VPS_IP = "89.117.60.144"
$VPS_USER = "root"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "📊 Deploying Admin Dashboard" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Step 1: Create directory on VPS
Write-Host "[1/5] Creating directory on VPS..." -ForegroundColor Yellow
ssh -o StrictHostKeyChecking=no ${VPS_USER}@${VPS_IP} "mkdir -p /opt/admin-dashboard"
Write-Host "✅ Directory created`n" -ForegroundColor Green

# Step 2: Upload files
Write-Host "[2/5] Uploading files to VPS..." -ForegroundColor Yellow
$sourceDir = "E:\BMAD method\BMAD 4\apps\admin"
scp -o StrictHostKeyChecking=no -r "$sourceDir/*" "${VPS_USER}@${VPS_IP}:/opt/admin-dashboard/"
Write-Host "✅ Files uploaded`n" -ForegroundColor Green

# Step 3: Build Docker image
Write-Host "[3/5] Building Docker image..." -ForegroundColor Yellow
ssh -o StrictHostKeyChecking=no ${VPS_USER}@${VPS_IP} @"
cd /opt/admin-dashboard && \
docker build -f Dockerfile.simple -t admin-dashboard:latest .
"@
Write-Host "✅ Image built`n" -ForegroundColor Green

# Step 4: Stop old container if exists
Write-Host "[4/5] Stopping old container..." -ForegroundColor Yellow
ssh -o StrictHostKeyChecking=no ${VPS_USER}@${VPS_IP} "docker stop admin-dashboard 2>/dev/null || true && docker rm admin-dashboard 2>/dev/null || true"
Write-Host "✅ Old container removed`n" -ForegroundColor Green

# Step 5: Start new container
Write-Host "[5/5] Starting new container..." -ForegroundColor Yellow
$startCommand = @"
docker run -d \
  --name admin-dashboard \
  --restart always \
  -p 3002:3000 \
  -e NEXT_PUBLIC_SUPABASE_URL=http://89.117.60.144:54321 \
  -e NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0 \
  admin-dashboard:latest
"@

ssh -o StrictHostKeyChecking=no ${VPS_USER}@${VPS_IP} $startCommand
Write-Host "✅ Container started`n" -ForegroundColor Green

# Step 6: Wait and test
Write-Host "[6/6] Testing dashboard..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

try {
    $response = Invoke-WebRequest -Uri "http://${VPS_IP}:3002" -Method Head -TimeoutSec 5 -UseBasicParsing
    Write-Host "✅ Dashboard is accessible!`n" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Dashboard may still be starting...`n" -ForegroundColor Yellow
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🎉 Deployment Complete!" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Dashboard URL: http://${VPS_IP}:3002" -ForegroundColor White
Write-Host "Queue Monitoring: http://${VPS_IP}:3002/queue/monitoring" -ForegroundColor White
Write-Host "`nTo view logs:" -ForegroundColor Gray
Write-Host "  ssh root@${VPS_IP} 'docker logs -f admin-dashboard'" -ForegroundColor DarkGray
Write-Host ""
