#!/bin/bash

# Coolify Deployment Script for Admin Dashboard
# This script helps deploy the admin NextJS dashboard to Coolify

set -e

echo "🚀 Starting Coolify Deployment for Admin Dashboard"
echo "================================================"

# Configuration
COOLIFY_URL="https://coolify.aimasteryedu.in"
PROJECT_NAME="admin-dashboard"
PROJECT_PORT=3002
GIT_REPO_URL="https://github.com/your-repo/admin-dashboard.git"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required files exist
check_files() {
    print_status "Checking required files..."
    
    required_files=(
        "package.json"
        "next.config.js"
        ".env.local"
        "Dockerfile.coolify"
        "coolify-deployment-config.json"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            print_error "Required file missing: $file"
            exit 1
        fi
    done
    
    print_status "All required files found ✅"
}

# Validate environment configuration
validate_config() {
    print_status "Validating configuration..."
    
    # Check if port is available
    if netstat -tuln 2>/dev/null | grep -q ":$PROJECT_PORT "; then
        print_warning "Port $PROJECT_PORT is already in use"
    fi
    
    # Check NextJS config
    if ! grep -q "output.*standalone" next.config.js; then
        print_warning "NextJS config should use 'output: standalone' for optimal deployment"
    fi
    
    print_status "Configuration validation complete ✅"
}

# Prepare deployment package
prepare_package() {
    print_status "Preparing deployment package..."
    
    # Create deployment directory
    DEPLOY_DIR="coolify-deploy-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$DEPLOY_DIR"
    
    # Copy essential files
    cp package*.json "$DEPLOY_DIR/"
    cp next.config.js "$DEPLOY_DIR/"
    cp tailwind.config.js "$DEPLOY_DIR/"
    cp postcss.config.js "$DEPLOY_DIR/"
    cp tsconfig.json "$DEPLOY_DIR/"
    cp Dockerfile.coolify "$DEPLOY_DIR/Dockerfile"
    cp -r src "$DEPLOY_DIR/"
    cp -r public "$DEPLOY_DIR/" 2>/dev/null || true
    
    # Environment file for Coolify
    cat > "$DEPLOY_DIR/.env.production" << EOF
NEXT_PUBLIC_SUPABASE_URL=http://89.117.60.144:54321
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0
NODE_ENV=production
NEXT_TELEMETRY_DISABLED=1
PORT=$PROJECT_PORT
HOSTNAME=0.0.0.0
EOF
    
    print_status "Deployment package prepared in $DEPLOY_DIR ✅"
}

# Create deployment instructions
create_instructions() {
    print_status "Creating deployment instructions..."
    
    cat > "COOLIFY_DEPLOYMENT_INSTRUCTIONS.md" << 'EOF'
# Coolify Deployment Instructions for Admin Dashboard

## Quick Deployment Steps

### 1. Access Coolify Dashboard
- URL: https://coolify.aimasteryedu.in
- Username: dranilkumarsharma4@gmail.com
- Password: 22547728.mIas

### 2. Create New Project
1. Click on "Projects" in the sidebar
2. Click "New Project" or "+" button
3. Select "Static Site" or "Node.js Application"
4. Choose "Deploy from GitHub"

### 3. Configure Project Settings
- **Project Name**: admin-dashboard
- **Repository**: [Your GitHub repository URL]
- **Branch**: main (or your deployment branch)
- **Build Command**: `npm run build`
- **Start Command**: `npm start`
- **Port**: 3002

### 4. Environment Variables
Add the following environment variables in Coolify:

```
NEXT_PUBLIC_SUPABASE_URL=http://89.117.60.144:54321
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0
NODE_ENV=production
NEXT_TELEMETRY_DISABLED=1
PORT=3002
HOSTNAME=0.0.0.0
```

### 5. Advanced Settings
- **Node Version**: 20
- **Memory**: 512MB
- **CPU**: 0.5
- **Health Check**: `/api/health`
- **Health Check Port**: 3002

### 6. Deploy
1. Click "Deploy" button
2. Monitor deployment logs
3. Wait for successful deployment
4. Access your application at the provided URL

## Alternative: Docker Deployment

If you prefer using Docker:

1. Build the Docker image:
   ```bash
   docker build -f Dockerfile.coolify -t admin-dashboard .
   ```

2. Run the container:
   ```bash
   docker run -p 3002:3002 \
     -e NEXT_PUBLIC_SUPABASE_URL=http://89.117.60.144:54321 \
     -e NEXT_PUBLIC_SUPABASE_ANON_KEY=your_anon_key \
     admin-dashboard
   ```

## Troubleshooting

### Common Issues:
1. **Port conflicts**: Ensure port 3002 is available
2. **Environment variables**: Double-check all required env vars are set
3. **Build failures**: Check build logs for specific errors
4. **Health check failures**: Verify the `/api/health` endpoint works

### Verification Steps:
1. Check application logs in Coolify dashboard
2. Visit the health check endpoint: `http://your-app-url:3002/api/health`
3. Test main application functionality

## Expected Deployment URL
After successful deployment, your admin dashboard will be accessible at:
`http://your-coolify-domain:3002`

Or if using a custom domain:
`https://your-custom-domain.com`
EOF
    
    print_status "Deployment instructions created ✅"
}

# Main execution
main() {
    echo "Starting deployment preparation..."
    
    check_files
    validate_config
    prepare_package
    create_instructions
    
    echo ""
    print_status "🎉 Deployment preparation complete!"
    echo ""
    print_status "Next steps:"
    echo "1. Review COOLIFY_DEPLOYMENT_INSTRUCTIONS.md"
    echo "2. Upload the deployment package to your GitHub repository"
    echo "3. Follow the manual deployment steps in Coolify dashboard"
    echo ""
    print_warning "Note: Manual deployment in Coolify dashboard is required due to session management limitations"
}

# Run main function
main "$@"