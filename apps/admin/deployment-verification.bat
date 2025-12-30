@echo off
REM Admin Dashboard Deployment Verification Script
REM This script checks if your deployment was successful

echo 🔍 Admin Dashboard Deployment Verification
echo =========================================
echo.

set VPS_IP=89.117.60.144
set PROJECT_PORT=3002

echo [INFO] Checking deployment status...
echo [INFO] VPS: %VPS_IP%
echo [INFO] Port: %PROJECT_PORT%
echo.

REM Test main application
echo [1/4] Testing main application...
curl -f -m 10 http://%VPS_IP%:%PROJECT_PORT% 2>nul
if %errorlevel% equ 0 (
    echo ✅ Main application: ACCESSIBLE
) else (
    echo ❌ Main application: NOT ACCESSIBLE
)

echo.

REM Test health endpoint
echo [2/4] Testing health endpoint...
curl -f -m 10 http://%VPS_IP%:%PROJECT_PORT%/api/health 2>nul
if %errorlevel% equ 0 (
    echo ✅ Health endpoint: RESPONDING
) else (
    echo ❌ Health endpoint: NOT RESPONDING
)

echo.

REM Test knowledge base
echo [3/4] Testing knowledge base page...
curl -f -m 10 http://%VPS_IP%:%PROJECT_PORT%/knowledge-base 2>nul
if %errorlevel% equ 0 (
    echo ✅ Knowledge Base: ACCESSIBLE
) else (
    echo ❌ Knowledge Base: NOT ACCESSIBLE
)

echo.

REM Test queue monitoring
echo [4/4] Testing queue monitoring page...
curl -f -m 10 http://%VPS_IP%:%PROJECT_PORT%/queue/monitoring 2>nul
if %errorlevel% equ 0 (
    echo ✅ Queue Monitoring: ACCESSIBLE
) else (
    echo ❌ Queue Monitoring: NOT ACCESSIBLE
)

echo.
echo =========================================
echo 🎯 Deployment Status Summary:
echo =========================================
echo 🌐 Main Dashboard: http://%VPS_IP%:%PROJECT_PORT%
echo 🔧 Health Check: http://%VPS_IP%:%PROJECT_PORT%/api/health
echo 📚 Knowledge Base: http://%VPS_IP%:%PROJECT_PORT%/knowledge-base
echo 📊 Queue Monitoring: http://%VPS_IP%:%PROJECT_PORT%/queue/monitoring
echo 📈 System Status: http://%VPS_IP%:%PROJECT_PORT%/system-status
echo.
echo [INFO] If any test failed, wait 2-3 minutes and try again.
echo [INFO] The application may still be starting up.
echo.

pause