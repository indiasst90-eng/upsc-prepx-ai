@echo off
REM ============================================================================
REM PHASE 2: Quick Deployment Script (Batch Version)
REM VPS: 89.117.60.144
REM ============================================================================

echo ========================================
echo PHASE 2: Video Queue System Deployment
echo ========================================
echo.

REM Execute PowerShell script
powershell -ExecutionPolicy Bypass -File "%~dp0deploy-phase2.ps1"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo DEPLOYMENT SUCCESSFUL!
    echo ========================================
) else (
    echo.
    echo ========================================
    echo DEPLOYMENT FAILED - See errors above
    echo ========================================
)

pause
