#!/bin/bash

# ============================================================================
# Automated Web App Deployment to Coolify
# ============================================================================
# This script automates the deployment of the web app to Coolify VPS
# VPS: 89.117.60.144
# ============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}UPSC PrepX Web App Deployment${NC}"
echo -e "${GREEN}========================================${NC}"

# Configuration
VPS_IP="89.117.60.144"
VPS_USER="root"
VPS_PASSWORD="772877mAmcIaS"
PROJECT_NAME="upsc-prepx-web"
APP_PORT="3000"

# Step 1: Verify Git repository is clean
echo -e "\n${YELLOW}[1/8] Checking Git status...${NC}"
if [[ -n $(git status -s) ]]; then
    echo -e "${YELLOW}Warning: Uncommitted changes detected. Committing...${NC}"
    git add .
    git commit -m "Frontend UI redesign - Production deployment $(date +%Y-%m-%d)"
fi

# Step 2: Push to repository
echo -e "\n${YELLOW}[2/8] Pushing to Git repository...${NC}"
git push origin main || git push origin master

# Step 3: SSH to VPS and check Coolify
echo -e "\n${YELLOW}[3/8] Connecting to VPS...${NC}"
sshpass -p "$VPS_PASSWORD" ssh -o StrictHostKeyChecking=no ${VPS_USER}@${VPS_IP} << 'ENDSSH'
    echo "Connected to VPS successfully"
    
    # Check if Coolify is running
    if ! docker ps | grep -q coolify; then
        echo "Error: Coolify is not running"
        exit 1
    fi
    
    echo "Coolify is running"
ENDSSH

# Step 4: Build Docker image locally (test)
echo -e "\n${YELLOW}[4/8] Testing Docker build locally...${NC}"
cd "$(dirname "$0")"
docker build -f apps/web/Dockerfile.optimized -t upsc-prepx-web:test . || {
    echo -e "${RED}Docker build failed locally${NC}"
    exit 1
}

echo -e "${GREEN}Local Docker build successful${NC}"

# Step 5: Create .env file for deployment
echo -e "\n${YELLOW}[5/8] Creating environment variables file...${NC}"
cat > .env.production << 'EOF'
# Supabase Configuration
NEXT_PUBLIC_SUPABASE_URL=${NEXT_PUBLIC_SUPABASE_URL}
SUPABASE_SERVICE_ROLE_KEY=${SUPABASE_SERVICE_ROLE_KEY}

# AI Provider
A4F_API_KEY=${A4F_API_KEY}

# Application
NEXT_PUBLIC_APP_URL=https://app.upscprepx.ai
NODE_ENV=production
NEXT_TELEMETRY_DISABLED=1

# Health Check
PORT=3000
HOSTNAME=0.0.0.0
EOF

echo -e "${GREEN}Environment file created${NC}"

# Step 6: Create Coolify project configuration
echo -e "\n${YELLOW}[6/8] Creating Coolify configuration...${NC}"
cat > coolify-web-config.json << 'EOF'
{
  "project": {
    "name": "upsc-prepx-web",
    "description": "UPSC PrepX AI - User Web Application"
  },
  "application": {
    "name": "web-app",
    "build_pack": "dockerfile",
    "dockerfile_path": "apps/web/Dockerfile.optimized",
    "base_directory": "/",
    "port": 3000,
    "health_check_path": "/api/health",
    "health_check_interval": 30,
    "health_check_timeout": 5,
    "health_check_retries": 3
  },
  "domain": {
    "domain": "app.upscprepx.ai",
    "https": true,
    "force_https": true,
    "lets_encrypt": true
  }
}
EOF

echo -e "${GREEN}Coolify configuration created${NC}"

# Step 7: Display deployment instructions
echo -e "\n${YELLOW}[7/8] Deployment Instructions:${NC}"
echo -e "${GREEN}============================================${NC}"
echo -e "1. Access Coolify Dashboard:"
echo -e "   URL: https://${VPS_IP}:8000"
echo -e ""
echo -e "2. Create New Project:"
echo -e "   - Click 'New Project'"
echo -e "   - Name: upsc-prepx-web"
echo -e "   - Description: UPSC PrepX AI - User Web Application"
echo -e ""
echo -e "3. Add Application:"
echo -e "   - Select 'Git Source'"
echo -e "   - Repository: $(git config --get remote.origin.url)"
echo -e "   - Branch: $(git branch --show-current)"
echo -e ""
echo -e "4. Configure Build:"
echo -e "   - Build Pack: Dockerfile"
echo -e "   - Dockerfile Path: apps/web/Dockerfile.optimized"
echo -e "   - Base Directory: /"
echo -e "   - Port: 3000"
echo -e ""
echo -e "5. Add Environment Variables from .env.production"
echo -e ""
echo -e "6. Configure Domain:"
echo -e "   - Domain: app.upscprepx.ai"
echo -e "   - Enable Force HTTPS"
echo -e "   - Enable Let's Encrypt SSL"
echo -e ""
echo -e "7. Click Deploy"
echo -e "${GREEN}============================================${NC}"

# Step 8: Verification checklist
echo -e "\n${YELLOW}[8/8] Post-Deployment Verification:${NC}"
cat > deployment-verification.txt << 'EOF'
Web Application Deployment Verification Checklist
=================================================

After deployment completes, verify:

1. Application Access
   [ ] App accessible via HTTPS: https://app.upscprepx.ai
   [ ] Admin panel accessible: https://app.upscprepx.ai/admin
   [ ] SSL certificate valid (green padlock)
   [ ] No certificate warnings

2. Functionality
   [ ] Homepage loads without errors
   [ ] User can signup/login
   [ ] Dashboard displays correctly
   [ ] Search functionality works
   [ ] AI features accessible
   [ ] Static assets load (images, fonts)

3. Performance
   [ ] Page load time < 3 seconds
   [ ] No console errors in browser
   [ ] Responsive on mobile/tablet/desktop
   [ ] Animations smooth (60fps)

4. Security
   [ ] HTTPS enforced (HTTP redirects to HTTPS)
   [ ] No secrets visible in Network tab
   [ ] Admin panel requires authentication
   [ ] Session management works
   [ ] CORS configured correctly

5. Health Check
   [ ] /api/health returns 200 OK
   [ ] Docker container status: running
   [ ] Application logs show no errors

If all items checked, deployment is successful!
EOF

cat deployment-verification.txt

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment preparation complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "\nFiles created:"
echo -e "  - .env.production (environment variables)"
echo -e "  - coolify-web-config.json (Coolify configuration)"
echo -e "  - deployment-verification.txt (verification checklist)"
echo -e "\nNext: Access Coolify dashboard and follow deployment instructions above"
