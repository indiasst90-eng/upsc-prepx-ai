# PowerShell script to deploy migration via SSH
$VPS_IP = "89.117.60.144"
$VPS_PASSWORD = "772877mAmcIaS"
$MIGRATION_FILE = "E:\BMAD method\BMAD 4\packages\supabase\supabase\migrations\009_video_jobs.sql"

Write-Host "Deploying migration to VPS..." -ForegroundColor Green

# Read migration content
$migrationContent = Get-Content $MIGRATION_FILE -Raw

# Create temporary script on VPS and execute
$sshCommand = @"
echo '$($migrationContent -replace "'", "''")' > /tmp/migration.sql && \
docker exec supabase-db psql -U postgres -d postgres -f /tmp/migration.sql
"@

# Execute via SSH (you'll need to enter password when prompted)
Write-Host "Connecting to VPS..." -ForegroundColor Yellow
ssh root@$VPS_IP $sshCommand

Write-Host "Migration deployment completed!" -ForegroundColor Green
