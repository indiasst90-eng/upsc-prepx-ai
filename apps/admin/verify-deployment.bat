@echo off
REM Deployment Verification Script for Windows
REM This script helps verify the deployment readiness

echo ========================================
echo Coolify Admin Dashboard Deployment Check
echo ========================================
echo.

echo [INFO] Checking required files...

set "required_files=package.json next.config.js tailwind.config.js postcss.config.js tsconfig.json Dockerfile.coolify coolify-deployment-config.json"

for %%f in (%required_files%) do (
    if exist "%%f" (
        echo [OK] %%f found
    ) else (
        echo [ERROR] %%f missing
    )
)

echo.
echo [INFO] Checking NextJS configuration...
if exist "next.config.js" (
    findstr /C:"output.*standalone" next.config.js >nul
    if %errorlevel% equ 0 (
        echo [OK] Standalone output configured
    ) else (
        echo [WARNING] Standalone output not found in next.config.js
    )
)

echo.
echo [INFO] Checking environment variables...
if exist ".env.coolify" (
    echo [OK] Environment configuration file found
) else (
    echo [WARNING] Environment configuration file not found
)

echo.
echo [INFO] Checking Dockerfile...
if exist "Dockerfile.coolify" (
    echo [OK] Coolify-optimized Dockerfile found
) else (
    echo [WARNING] Coolify Dockerfile not found
)

echo.
echo [INFO] Deployment package summary:
echo - Project: admin-dashboard
echo - Port: 3002
echo - Node Version: 20
echo - Framework: NextJS 14
echo - Database: Supabase

echo.
echo [INFO] Next steps:
echo 1. Review COOLIFY_DEPLOYMENT_GUIDE.md
echo 2. Upload code to GitHub repository
echo 3. Follow manual deployment steps in Coolify
echo 4. Configure environment variables
echo 5. Deploy and verify

echo.
echo Deployment preparation complete!
pause