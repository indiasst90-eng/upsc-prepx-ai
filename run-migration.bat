@echo off
echo 🚀 Running Supabase Migration...
echo.

cd /d "%~dp0"

REM Try different methods to run the migration
echo 📁 Current directory: %CD%
echo.

echo Method 1: Direct Node execution
node apply-migration-023.mjs
if %ERRORLEVEL% EQU 0 (
    echo ✅ Migration completed successfully!
    pause
    exit /b 0
)

echo.
echo ❌ Method 1 failed, trying Method 2...
echo.

echo Method 2: Installing dependencies and retry
npm install @supabase/supabase-js --legacy-peer-deps
if %ERRORLEVEL% EQU 0 (
    echo ✅ Dependencies installed, retrying migration...
    node apply-migration-023.mjs
    if %ERRORLEVEL% EQU 0 (
        echo ✅ Migration completed successfully!
        pause
        exit /b 0
    )
)

echo.
echo ❌ Method 2 failed, trying Method 3...
echo.

echo Method 3: Using our automated system
echo Copying migration file...
copy "apply-migration-023.mjs" "C:\Users\Dr Varuni\Desktop\migration.mjs"
if %ERRORLEVEL% EQU 0 (
    echo 📦 Running automated migration...
    cd /d "C:\Users\Dr Varuni\Desktop"
    node simple_migration_automation.js migration.mjs
    if %ERRORLEVEL% EQU 0 (
        echo ✅ Migration completed with automated system!
        pause
        exit /b 0
    )
)

echo.
echo ❌ All methods failed
echo Please check the error messages above
pause
exit /b 1
