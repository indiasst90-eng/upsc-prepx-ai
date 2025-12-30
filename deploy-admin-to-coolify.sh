#!/bin/bash

# ============================================================================
# Automated Admin Panel Deployment to Coolify
# ============================================================================
# This script automates the deployment of the admin panel to Coolify VPS
# VPS: 89.117.60.144
# ============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}UPSC PrepX Admin Panel Deployment${NC}"
echo -e "${GREEN}========================================${NC}"

# Configuration
VPS_IP="89.117.60.144"
VPS_USER="root"
VPS_PASSWORD="772877mAmcIaS"
PROJECT_NAME="upsc-prepx-admin"
APP_PORT="3001"

# Step 1: Create admin environment file
echo -e "\n${YELLOW}[1/5] Creating admin environment variables...${NC}"
cat > .env.admin << 'EOF'
# Supabase Configuration
NEXT_PUBLIC_SUPABASE_URL=${NEXT_PUBLIC_SUPABASE_URL}
SUPABASE_SERVICE_ROLE_KEY=${SUPABASE_SERVICE_ROLE_KEY}

# AI Provider
A4F_API_KEY=${A4F_API_KEY}

# Application
NEXT_PUBLIC_APP_URL=https://admin.upscprepx.ai
NODE_ENV=production
NEXT_TELEMETRY_DISABLED=1

# Admin Configuration
ADMIN_USERNAME=root
ADMIN_REQUIRE_PASSWORD_CHANGE=true
ADMIN_SESSION_TIMEOUT=3600
ADMIN_MFA_ENABLED=false

# Health Check
PORT=3001
HOSTNAME=0.0.0.0
EOF

echo -e "${GREEN}Admin environment file created${NC}"

# Step 2: Create Coolify configuration for admin
echo -e "\n${YELLOW}[2/5] Creating admin Coolify configuration...${NC}"
cat > coolify-admin-config.json << 'EOF'
{
  "project": {
    "name": "upsc-prepx-admin",
    "description": "UPSC PrepX AI - Admin Panel"
  },
  "application": {
    "name": "admin-panel",
    "build_pack": "dockerfile",
    "dockerfile_path": "apps/admin/Dockerfile.coolify",
    "base_directory": "/",
    "port": 3001,
    "health_check_path": "/",
    "health_check_interval": 30,
    "health_check_timeout": 5,
    "health_check_retries": 3
  },
  "domain": {
    "domain": "admin.upscprepx.ai",
    "https": true,
    "force_https": true,
    "lets_encrypt": true
  },
  "security": {
    "require_authentication": true,
    "admin_only": true,
    "ip_whitelist": []
  }
}
EOF

echo -e "${GREEN}Admin Coolify configuration created${NC}"

# Step 3: Create admin credentials file
echo -e "\n${YELLOW}[3/5] Creating admin credentials file...${NC}"
cat > ADMIN-CREDENTIALS-SECURE.md << 'EOF'
# Admin Panel Credentials (SECURE)

**IMPORTANT:** Store these credentials securely. Do not commit to repository.

## Initial Access Credentials

**Admin Panel URL:** https://admin.upscprepx.ai

**Default Credentials:**
- Username: `root`
- Password: `772877mAmcIaS` (VPS root password)

## First Login Requirement

On first login, you MUST:
1. Change the default password
2. Set a strong password (min 12 characters, mix of upper/lower/numbers/symbols)
3. Enable MFA (recommended)

## New Password Requirements

- Minimum length: 12 characters
- Must contain:
  - Uppercase letters
  - Lowercase letters
  - Numbers
  - Special characters
- Cannot be similar to username
- Cannot be a common password

## MFA Setup (Recommended)

1. After first login, go to Settings
2. Enable Two-Factor Authentication
3. Scan QR code with authenticator app (Google Authenticator, Authy, etc.)
4. Enter verification code
5. Save backup codes securely

## Session Management

- Session timeout: 60 minutes of inactivity
- Concurrent sessions: 1 (single device at a time)
- Re-authentication required for sensitive actions

## Password Reset

If you forget your password:
1. SSH to VPS (89.117.60.144)
2. Run password reset script
3. Follow instructions

## Security Best Practices

1. Never share admin credentials
2. Use MFA
3. Log out when not in use
4. Monitor admin audit logs
5. Change password every 90 days
6. Use password manager

## Audit Logging

All admin actions are logged:
- Login attempts
- Configuration changes
- User management actions
- System modifications
- Data exports

Access logs at: Admin Panel > System Status > Audit Logs

---

**Created:** $(date)
**VPS IP:** 89.117.60.144
**Admin Panel:** https://admin.upscprepx.ai

**KEEP THIS FILE SECURE - DO NOT SHARE**
EOF

chmod 600 ADMIN-CREDENTIALS-SECURE.md
echo -e "${GREEN}Admin credentials file created (secure permissions)${NC}"

# Step 4: Display deployment instructions
echo -e "\n${YELLOW}[4/5] Admin Panel Deployment Instructions:${NC}"
echo -e "${GREEN}============================================${NC}"
echo -e "1. Access Coolify Dashboard:"
echo -e "   URL: https://${VPS_IP}:8000"
echo -e ""
echo -e "2. Create New Project:"
echo -e "   - Click 'New Project'"
echo -e "   - Name: upsc-prepx-admin"
echo -e "   - Description: UPSC PrepX AI - Admin Panel"
echo -e ""
echo -e "3. Add Application:"
echo -e "   - Select 'Git Source'"
echo -e "   - Repository: $(git config --get remote.origin.url)"
echo -e "   - Branch: $(git branch --show-current)"
echo -e ""
echo -e "4. Configure Build:"
echo -e "   - Build Pack: Dockerfile"
echo -e "   - Dockerfile Path: apps/admin/Dockerfile.coolify"
echo -e "   - Base Directory: /"
echo -e "   - Port: 3001"
echo -e ""
echo -e "5. Add Environment Variables from .env.admin"
echo -e ""
echo -e "6. Configure Domain:"
echo -e "   - Domain: admin.upscprepx.ai"
echo -e "   - Enable Force HTTPS"
echo -e "   - Enable Let's Encrypt SSL"
echo -e ""
echo -e "7. Click Deploy"
echo -e "${GREEN}============================================${NC}"

# Step 5: Create admin verification checklist
echo -e "\n${YELLOW}[5/5] Creating admin verification checklist...${NC}"
cat > admin-deployment-verification.txt << 'EOF'
Admin Panel Deployment Verification Checklist
=============================================

After deployment completes, verify:

1. Access & Authentication
   [ ] Admin panel accessible: https://admin.upscprepx.ai
   [ ] SSL certificate valid
   [ ] Login page displays
   [ ] Can login with default credentials (root/VPS password)
   [ ] Forced password change on first login
   [ ] New password meets requirements
   [ ] Session created successfully

2. Admin Features
   [ ] Dashboard loads with metrics
   [ ] Knowledge Base management accessible
   [ ] Queue Monitor displays jobs
   [ ] AI Provider settings accessible
   [ ] Ads Management loads
   [ ] System Status shows VPS info

3. Isolation Verification
   [ ] Admin panel separate from user app
   [ ] No user features visible in admin
   [ ] No admin features in user panel
   [ ] Different navigation menus
   [ ] Separate sessions

4. Security
   [ ] HTTPS enforced
   [ ] Admin authentication required
   [ ] No secrets visible in Network tab
   [ ] Session timeout works
   [ ] Audit logging active
   [ ] VPS IP displayed correctly (89.117.60.144)

5. Functionality
   [ ] All navigation items work
   [ ] No console errors
   [ ] Responsive design
   [ ] Neumorphic styling visible
   [ ] System status shows "Online"

6. Post-Deployment Tasks
   [ ] Change admin password from default
   [ ] Enable MFA (recommended)
   [ ] Document new credentials securely
   [ ] Test admin actions
   [ ] Review audit logs
   [ ] Update ADMIN-CREDENTIALS-SECURE.md

If all items checked, admin deployment is successful!
EOF

cat admin-deployment-verification.txt

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Admin deployment preparation complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "\nFiles created:"
echo -e "  - .env.admin (admin environment variables)"
echo -e "  - coolify-admin-config.json (Coolify configuration)"
echo -e "  - ADMIN-CREDENTIALS-SECURE.md (secure credentials)"
echo -e "  - admin-deployment-verification.txt (verification checklist)"
echo -e "\n${YELLOW}IMPORTANT:${NC}"
echo -e "  - ADMIN-CREDENTIALS-SECURE.md contains sensitive information"
echo -e "  - File has secure permissions (600)"
echo -e "  - DO NOT commit to repository"
echo -e "  - Store in password manager"
echo -e "\nNext: Access Coolify dashboard and follow deployment instructions above"
