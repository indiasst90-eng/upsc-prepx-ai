# Complete Coolify Deployment Guide for Admin Dashboard

## 📋 Prerequisites

- Access to Coolify instance: https://coolify.aimasteryedu.in
- Credentials: dranilkumarsharma4@gmail.com / 22547728.mIas
- GitHub repository with the admin dashboard code
- VPS: 89.117.60.144 (password: 772877mAmcIaS)

## 🚀 Deployment Steps

### Step 1: Access Coolify Dashboard
1. Open browser and navigate to: https://coolify.aimasteryedu.in
2. Login with provided credentials
3. Verify access to the dashboard

### Step 2: Create New Project
1. Click on **"Projects"** in the left sidebar
2. Click the **"New Project"** button or **"+"** icon
3. Select **"Static Site"** or **"Node.js Application"**
4. Choose **"Deploy from GitHub"** option

### Step 3: Configure Project Settings

#### Basic Configuration
- **Project Name**: `admin-dashboard`
- **Description**: `NextJS Admin Dashboard with Supabase Integration`
- **Repository URL**: `[Your GitHub repository URL]`
- **Branch**: `main` (or your deployment branch)
- **Build Command**: `npm run build`
- **Start Command**: `npm start`
- **Port**: `3002` (to avoid conflicts with existing apps)

#### Advanced Configuration
- **Node Version**: `20`
- **Memory**: `512MB`
- **CPU**: `0.5 cores`
- **Disk Space**: `1GB`
- **Health Check Path**: `/api/health`
- **Health Check Port**: `3002`

### Step 4: Environment Variables
Add the following environment variables in the Coolify project settings:

```bash
# Supabase Configuration
NEXT_PUBLIC_SUPABASE_URL=http://89.117.60.144:54321
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0

# Application Configuration
NODE_ENV=production
NEXT_TELEMETRY_DISABLED=1
PORT=3002
HOSTNAME=0.0.0.0
NEXT_PUBLIC_APP_URL=http://89.117.60.144:3002
NEXT_PUBLIC_ADMIN_PANEL=true
```

### Step 5: Deployment Configuration Files

#### Dockerfile (if using Docker deployment)
Use the provided `Dockerfile.coolify` which includes:
- Multi-stage build for optimization
- Non-root user for security
- Health checks
- Proper port configuration

#### NextJS Configuration
Ensure `next.config.js` includes:
```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  output: 'standalone',
  images: {
    domains: ['localhost', '89.117.60.144'],
  },
};

module.exports = nextConfig;
```

### Step 6: Deploy
1. Click **"Deploy"** button
2. Monitor the deployment logs
3. Wait for successful completion (usually takes 2-5 minutes)
4. Note the assigned URL

### Step 7: Verification
1. Check application logs for any errors
2. Visit the health check endpoint: `http://[your-app-url]:3002/api/health`
3. Test main application functionality
4. Verify Supabase connectivity

## 🔧 Alternative: Manual Docker Deployment

If you prefer to deploy using Docker directly:

### Build and Run Commands
```bash
# Build the Docker image
docker build -f Dockerfile.coolify -t admin-dashboard .

# Run the container
docker run -d \
  --name admin-dashboard \
  -p 3002:3002 \
  -e NEXT_PUBLIC_SUPABASE_URL=http://89.117.60.144:54321 \
  -e NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0 \
  -e NODE_ENV=production \
  admin-dashboard
```

## 🛠 Troubleshooting

### Common Issues and Solutions

#### 1. Port Conflicts
- **Problem**: Port 3002 is already in use
- **Solution**: Change PORT environment variable to an available port (e.g., 3003, 3004)

#### 2. Build Failures
- **Problem**: npm install or build command fails
- **Solution**: 
  - Check package.json dependencies
  - Verify Node.js version compatibility
  - Review build logs for specific errors

#### 3. Environment Variables Missing
- **Problem**: Application fails to start due to missing env vars
- **Solution**: Ensure all required environment variables are set in Coolify

#### 4. Health Check Failures
- **Problem**: Health check endpoint returns non-200 status
- **Solution**: 
  - Verify the `/api/health` route exists
  - Check application logs for startup errors
  - Ensure Supabase connection is working

#### 5. Supabase Connection Issues
- **Problem**: Cannot connect to Supabase database
- **Solution**: 
  - Verify Supabase URL and key
  - Check if Supabase service is running on VPS
  - Ensure network connectivity

### Debug Commands
```bash
# Check application logs
docker logs admin-dashboard

# Test health endpoint
curl http://localhost:3002/api/health

# Check environment variables
docker exec admin-dashboard env | grep NEXT_PUBLIC
```

## 📊 Expected Results

### Successful Deployment
- ✅ Application starts without errors
- ✅ Health check returns 200 status
- ✅ Admin dashboard is accessible
- ✅ Supabase connectivity confirmed
- ✅ All admin pages load correctly

### Deployment URLs
After successful deployment:
- **Main Application**: `http://89.117.60.144:3002`
- **Health Check**: `http://89.117.60.144:3002/api/health`
- **Admin Dashboard**: `http://89.117.60.144:3002` (root path)

### Access Information
- **Admin Dashboard Features**:
  - Knowledge Base Management
  - Queue Monitoring
  - System Status
  - Supabase Integration

## 📝 Post-Deployment Checklist

- [ ] Application is accessible via browser
- [ ] All admin pages load correctly
- [ ] Supabase database connection working
- [ ] Environment variables properly configured
- [ ] Health check endpoint responding
- [ ] No errors in application logs
- [ ] Admin authentication (if applicable) working
- [ ] All admin features functional

## 🆘 Support

If you encounter issues:
1. Check the Coolify project logs
2. Verify all environment variables
3. Test locally first using the provided scripts
4. Ensure VPS connectivity and resources
5. Review the troubleshooting section above

## 📁 Deployment Files

The following files have been prepared for deployment:
- `coolify-deployment-config.json` - Deployment configuration
- `Dockerfile.coolify` - Optimized Docker configuration
- `.env.coolify` - Environment variables template
- `deploy-to-coolify.sh` - Deployment automation script
- `COOLIFY_DEPLOYMENT_GUIDE.md` - This comprehensive guide

All files are ready for use in the Coolify deployment process.