# Deploy crawl4ai to VPS
# Run this script from PowerShell

$VPS_IP = "89.117.60.144"
$VPS_USER = "root"  # Change to your username
$REMOTE_PATH = "/opt/crawl4ai"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Deploying crawl4ai to VPS" -ForegroundColor Cyan
Write-Host "  Target: $VPS_IP:8105" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Step 1: Create directory on VPS
Write-Host "`n[1/4] Creating directory on VPS..." -ForegroundColor Yellow
ssh ${VPS_USER}@${VPS_IP} "mkdir -p $REMOTE_PATH"

# Step 2: Copy files to VPS
Write-Host "`n[2/4] Copying files to VPS..." -ForegroundColor Yellow
scp packages/crawl4ai-vps/main.py ${VPS_USER}@${VPS_IP}:${REMOTE_PATH}/
scp packages/crawl4ai-vps/requirements.txt ${VPS_USER}@${VPS_IP}:${REMOTE_PATH}/
scp packages/crawl4ai-vps/Dockerfile ${VPS_USER}@${VPS_IP}:${REMOTE_PATH}/

# Step 3: Build and run Docker container on VPS
Write-Host "`n[3/4] Building Docker image on VPS..." -ForegroundColor Yellow
ssh ${VPS_USER}@${VPS_IP} "cd $REMOTE_PATH && docker build -t crawl4ai-upsc ."

# Step 4: Run the container
Write-Host "`n[4/4] Starting crawl4ai container..." -ForegroundColor Yellow
ssh ${VPS_USER}@${VPS_IP} "docker stop crawl4ai 2>/dev/null; docker rm crawl4ai 2>/dev/null; docker run -d --name crawl4ai --restart unless-stopped -p 8105:8105 crawl4ai-upsc"

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "  Deployment Complete!" -ForegroundColor Green
Write-Host "  Service URL: http://${VPS_IP}:8105" -ForegroundColor Green
Write-Host "  Health Check: http://${VPS_IP}:8105/health" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

# Test health
Write-Host "`nTesting health endpoint..." -ForegroundColor Yellow
curl -s http://${VPS_IP}:8105/health
