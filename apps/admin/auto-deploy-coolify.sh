#!/bin/bash

# Auto Deployment Script for Admin NextJS Dashboard to Coolify
# This script will deploy your admin dashboard directly to your VPS

echo "🚀 Starting Admin NextJS Dashboard Deployment to Coolify..."
echo "=================================================="

# Configuration
VPS_IP="89.117.60.144"
VPS_PASSWORD="772877mAmcIaS"
PROJECT_PORT="3002"
APP_DIR="/var/www/coolify-admin"
SERVICE_NAME="coolify-admin"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are available
check_requirements() {
    print_status "Checking system requirements..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! command -v curl &> /dev/null; then
        print_error "curl is not installed. Please install curl first."
        exit 1
    fi
    
    print_status "All requirements met!"
}

# Connect to VPS and set up environment
setup_vps() {
    print_status "Setting up VPS environment..."
    
    sshpass -p "$VPS_PASSWORD" ssh -o StrictHostKeyChecking=no root@$VPS_IP << EOF
        # Update system
        apt update && apt upgrade -y
        
        # Install required packages
        apt install -y curl wget git
        
        # Create application directory
        mkdir -p $APP_DIR
        cd $APP_DIR
        
        # Clone or copy application files
        # Note: This is a placeholder - in real deployment, you'd copy your files here
        
        # Set up environment
        cp .env.coolify .env
        
        # Build and run with Docker
        docker build -t coolify-admin -f Dockerfile.coolify .
        
        # Stop any existing service
        docker stop $SERVICE_NAME 2>/dev/null || true
        docker rm $SERVICE_NAME 2>/dev/null || true
        
        # Run the new service
        docker run -d \
            --name $SERVICE_NAME \
            -p $PROJECT_PORT:3002 \
            --env-file .env \
            --restart unless-stopped \
            coolify-admin
            
        print_status "Application deployed successfully!"
        print_status "Your admin dashboard is available at: http://$VPS_IP:$PROJECT_PORT"
EOF
}

# Alternative: Direct deployment using Docker on VPS
direct_docker_deployment() {
    print_status "Starting direct Docker deployment..."
    
    # Create deployment directory structure
    mkdir -p deployment
    
    # Copy application files
    cp -r admin/* deployment/
    
    # Create docker-compose.yml for easy deployment
    cat > deployment/docker-compose.yml << EOF
version: '3.8'

services:
  admin-dashboard:
    build: .
    ports:
      - "3002:3002"
    environment:
      - NEXT_PUBLIC_SUPABASE_URL=http://89.117.60.144:54321
      - NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0
      - NODE_ENV=production
      - NEXT_TELEMETRY_DISABLED=1
      - PORT=3002
      - HOSTNAME=0.0.0.0
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3002/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF
    
    # Deploy using Docker Compose
    sshpass -p "$VPS_PASSWORD" scp -r deployment/* root@$VPS_IP:$APP_DIR/
    
    sshpass -p "$VPS_PASSWORD" ssh -o StrictHostKeyChecking=no root@$VPS_IP << EOF
        cd $APP_DIR
        docker-compose up -d --build
        
        print_status "Deployment completed successfully!"
        print_status "Admin Dashboard URL: http://$VPS_IP:$PROJECT_PORT"
        print_status "Health Check: http://$VPS_IP:$PROJECT_PORT/api/health"
EOF
}

# Verify deployment
verify_deployment() {
    print_status "Verifying deployment..."
    
    # Wait for service to start
    sleep 10
    
    # Check if service is running
    sshpass -p "$VPS_PASSWORD" ssh -o StrictHostKeyChecking=no root@$VPS_IP << EOF
        docker ps | grep coolify-admin
        curl -f http://localhost:$PROJECT_PORT/api/health
EOF
    
    # Test from external
    if curl -f http://$VPS_IP:$PROJECT_PORT/api/health; then
        print_status "✅ Deployment verified successfully!"
        print_status "🎉 Your Admin NextJS Dashboard is now live at:"
        print_status "   🌐 Main URL: http://$VPS_IP:$PROJECT_PORT"
        print_status "   🔧 Health Check: http://$VPS_IP:$PROJECT_PORT/api/health"
    else
        print_warning "Service may still be starting. Check logs manually."
    fi
}

# Main execution
main() {
    echo "Admin NextJS Dashboard - Coolify Auto Deployment"
    echo "=================================================="
    
    check_requirements
    
    # Choose deployment method
    echo "Select deployment method:"
    echo "1) Direct Docker deployment (Recommended)"
    echo "2) SSH-based deployment"
    read -p "Enter choice (1 or 2): " choice
    
    case $choice in
        1)
            direct_docker_deployment
            ;;
        2)
            setup_vps
            ;;
        *)
            print_error "Invalid choice. Exiting."
            exit 1
            ;;
    esac
    
    verify_deployment
    
    echo ""
    print_status "🎉 Deployment Complete!"
    print_status "Your admin dashboard is ready to use!"
    print_status "Access it at: http://$VPS_IP:$PROJECT_PORT"
}

# Run main function
main "$@"