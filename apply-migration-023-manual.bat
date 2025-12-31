@echo off
echo =====================================
echo Applying Migration 023 via REST API
echo =====================================
echo.

set SUPABASE_URL=http://89.117.60.144:54321
set SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU

echo [INFO] Migration must be applied via Supabase Studio
echo.
echo Please follow these steps:
echo 1. Open: http://89.117.60.144:3000
echo 2. Navigate to: SQL Editor
echo 3. Copy the SQL from: packages\supabase\supabase\migrations\023_study_schedules.sql
echo 4. Paste and click "Run"
echo.
echo After applying, verify with:
echo curl -X GET "%SUPABASE_URL%/rest/v1/study_schedules?select=id&limit=1" -H "apikey: %SERVICE_KEY%"
echo.
pause
