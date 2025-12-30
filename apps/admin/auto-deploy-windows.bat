@echo off
REM Admin NextJS Dashboard - Windows Auto Deployment Script
REM This script deploys your admin dashboard to Coolify VPS

echo 🚀 Admin NextJS Dashboard - Coolify Auto Deployment
echo ==================================================
echo.

REM Configuration
set VPS_IP=89.117.60.144
set VPS_PASSWORD=772877mAmcIaS
set PROJECT_PORT=3002
set APP_DIR=C:\coolify-admin
set SERVICE_NAME=coolify-admin

echo [INFO] Starting deployment to VPS: %VPS_IP%
echo [INFO] Using port: %PROJECT_PORT%
echo.

REM Check if required tools are installed
echo [INFO] Checking system requirements...

where ssh >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] SSH client not found. Please install Git or OpenSSH.
    pause
    exit /b 1
)

where curl >nul 2>nul
if %errorlevel% neq 0 (
    echo [WARNING] curl not found. Will attempt to use built-in tools.
)

echo [INFO] All basic requirements met!
echo.

REM Create deployment directory
echo [INFO] Preparing deployment files...
if not exist "deployment" mkdir deployment
copy admin\* deployment\ /Y

REM Create docker-compose.yml for easy deployment
echo [INFO] Creating Docker Compose configuration...
echo version: '3.8' > deployment\docker-compose.yml
echo. >> deployment\docker-compose.yml
echo services: >> deployment\docker-compose.yml
echo   admin-dashboard: >> deployment\docker-compose.yml
echo     build: . >> deployment\docker-compose.yml
echo     ports: >> deployment\docker-compose.yml
echo       - "3002:3002" >> deployment\docker-compose.yml
echo     environment: >> deployment\docker-compose.yml
echo       - NEXT_PUBLIC_SUPABASE_URL=http://89.117.60.144:54321 >> deployment\docker-compose.yml
echo       - NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0 >> deployment\docker-compose.yml
echo       - NODE_ENV=production >> deployment\docker-compose.yml
echo       - NEXT_TELEMETRY_DISABLED=1 >> deployment\docker-compose.yml
echo       - PORT=3002 >> deployment\docker-compose.yml
echo       - HOSTNAME=0.0.0.0 >> deployment\docker-compose.yml
echo     restart: unless-stopped >> deployment\docker-compose.yml
echo     healthcheck: >> deployment\docker-compose.yml
echo       test: ["CMD", "curl", "-f", "http://localhost:3002/api/health"] >> deployment\docker-compose.yml
echo       interval: 30s >> deployment\docker-compose.yml
echo       timeout: 10s >> deployment\docker-compose.yml
echo       retries: 3 >> deployment\docker-compose.yml

echo [INFO] Deployment files prepared successfully!
echo.

REM Check for SSH key or ask for password
echo [INFO] Checking SSH authentication...

REM For this example, we'll use password authentication
echo [WARNING] This script will use password authentication.
echo [WARNING] Make sure you can SSH to your VPS: %VPS_IP%
echo.
set /p confirm="Continue with deployment? (Y/N): "
if /i not "%confirm%"=="Y" (
    echo [INFO] Deployment cancelled by user.
    pause
    exit /b 0
)

echo.
echo [INFO] Starting deployment to VPS...
echo [INFO] This may take a few minutes...
echo.

REM Deploy using SCP and SSH
echo [INFO] Copying files to VPS...
pscp -pw "%VPS_PASSWORD%" -r deployment\* root@%VPS_IP%:/var/www/coolify-admin/

if %errorlevel% neq 0 (
    echo [ERROR] Failed to copy files to VPS. Check SSH connection.
    pause
    exit /b 1
)

echo [INFO] Files copied successfully!
echo [INFO] Executing deployment commands on VPS...

REM Execute deployment commands on VPS
ssh -o StrictHostKeyChecking=no -o PasswordAuthentication=yes -pw "%VPS_PASSWORD%" root@%VPS_IP% << EOF
    cd /var/www/coolify-admin
    
    # Install Docker if not present
    if ! command -v docker &> /dev/null; then
        echo [INFO] Installing Docker...
        apt update
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        apt install -y docker-compose
    fi
    
    # Build and deploy
    echo [INFO] Building and deploying application...
    docker-compose up -d --build
    
    # Wait for service to start
    sleep 15
    
    # Check if service is running
    if docker ps | grep -q coolify-admin; then
        echo [SUCCESS] Admin dashboard deployed successfully!
        echo [INFO] Access your dashboard at: http://%VPS_IP%:%PROJECT_PORT%
        echo [INFO] Health check: http://%VPS_IP%:%PROJECT_PORT%/api/health
    else
        echo [ERROR] Deployment failed. Check logs with: docker-compose logs
    fi
    
    # Test the health endpoint
    echo [INFO] Testing application health...
    curl -f http://localhost:%PROJECT_PORT%/api/health
    echo.
    
    if %errorlevel% equ 0 (
        echo [SUCCESS] ✅ Application is healthy and responding!
        echo [SUCCESS] 🎉 Your Admin NextJS Dashboard is live at:
        echo [SUCCESS]    🌐 Main URL: http://%VPS_IP%:%PROJECT_PORT%
        echo [SUCCESS]    🔧 Health Check: http://%VPS_IP%:%PROJECT_PORT%/api/health
    ) else (
        echo [WARNING] Application may still be starting. Check logs after a few minutes.
    fi
EOF

echo.
echo [INFO] Deployment process completed!
echo.
echo 🎉 Admin NextJS Dashboard Deployment Summary:
echo =============================================
echo 🌐 Main Application: http://%VPS_IP%:%PROJECT_PORT%
echo 🔧 Health Check: http://%VPS_IP%:%PROJECT_PORT%/api/health
echo 🏠 Knowledge Base: http://%VPS_IP%:%PROJECT_PORT%/knowledge-base
echo 📊 Queue Monitoring: http://%VPS_IP%:%PROJECT_PORT%/queue/monitoring
echo 📈 System Status: http://%VPS_IP%:%PROJECT_PORT%/system-status
echo.
echo [INFO] If the application doesn't load immediately, wait 2-3 minutes for it to fully start.
echo [INFO] You can check the deployment status by running the verification script.
echo.

pause