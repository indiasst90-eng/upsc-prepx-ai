# 📋 MANUAL DEPLOYMENT STEPS - Step by Step Guide

## For Non-Technical Users - Completely Manual Approach

Since the automated scripts failed, here's a **step-by-step manual process** that anyone can follow:

---

## 🎯 **WHAT YOU'LL ACCOMPLISH**

After completing these steps, your admin dashboard will be available at:
- **Website**: http://89.117.60.144:3002
- **All admin features will work**: Knowledge Base, Queue Monitoring, System Status

---

## 📝 **STEP-BY-STEP MANUAL DEPLOYMENT**

### **STEP 1: Connect to Your VPS Server**

#### **Option A: Using Windows Command Prompt**
1. **Open Command Prompt** (Press Win+R, type `cmd`, press Enter)
2. **Connect to your server**:
   ```
   ssh root@89.117.60.144
   ```
3. **Enter password when prompted**: `772877mAmcIaS`

#### **Option B: Using PuTTY (Recommended for Windows)**
1. **Download PuTTY**: https://www.putty.org/
2. **Install and open PuTTY**
3. **Enter connection details**:
   - Host Name: `89.117.60.144`
   - Port: `22`
   - Connection type: SSH
4. **Click "Open"**
5. **Enter username**: `root`
6. **Enter password**: `772877mAmcIaS`

---

### **STEP 2: Install Required Software**

**Copy and paste each command one by one. Press Enter after each one:**

```bash
# Update the server
apt update

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose
apt install -y docker-compose

# Install additional tools
apt install -y curl wget git

# Restart Docker service
systemctl restart docker
systemctl enable docker
```

**Wait for each command to finish before running the next one.**

---

### **STEP 3: Create Deployment Directory**

```bash
# Create the main directory
mkdir -p /var/www/coolify-admin

# Navigate to the directory
cd /var/www/coolify-admin

# Create the main application file
cat > Dockerfile << 'EOF'
FROM node:20-alpine AS base

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy source code
COPY . .

# Build the application
ENV NEXT_TELEMETRY_DISABLED 1
ENV NODE_ENV production
RUN npm run build

# Production stage
FROM node:20-alpine AS runner

WORKDIR /app

# Create non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Copy built application
COPY --from=base --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=base --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --from=base --chown=nextjs:nodejs /app/public ./public

# Set environment variables
ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1
ENV PORT 3002
ENV HOSTNAME 0.0.0.0

USER nextjs

EXPOSE 3002

CMD ["node", "server.js"]
EOF
```

---

### **STEP 4: Create Package.json**

```bash
cat > package.json << 'EOF'
{
  "name": "admin-dashboard",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "next": "14.0.4",
    "react": "^18",
    "react-dom": "^18",
    "typescript": "^5",
    "@types/node": "^20",
    "@types/react": "^18",
    "@types/react-dom": "^18",
    "autoprefixer": "^10.0.1",
    "postcss": "^8",
    "tailwindcss": "^3.3.0"
  }
}
EOF
```

---

### **STEP 5: Create NextJS Configuration**

```bash
cat > next.config.js << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  experimental: {
    appDir: true,
  },
  env: {
    CUSTOM_KEY: 'my-value',
  },
}

module.exports = nextConfig
EOF
```

---

### **STEP 6: Create Environment Variables**

```bash
cat > .env << 'EOF'
NEXT_PUBLIC_SUPABASE_URL=http://89.117.60.144:54321
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0
NODE_ENV=production
NEXT_TELEMETRY_DISABLED=1
PORT=3002
HOSTNAME=0.0.0.0
NEXT_PUBLIC_APP_URL=http://89.117.60.144:3002
NEXT_PUBLIC_ADMIN_PANEL=true
EOF
```

---

### **STEP 7: Create Docker Compose File**

```bash
cat > docker-compose.yml << 'EOF'
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
```

---

### **STEP 8: Build and Deploy**

```bash
# Build the Docker image
docker-compose build

# Start the application
docker-compose up -d

# Check if it's running
docker ps

# Check logs to see if everything is working
docker-compose logs
```

---

### **STEP 9: Test Your Deployment**

```bash
# Test the health endpoint
curl http://localhost:3002/api/health

# Test the main page
curl http://localhost:3002
```

---

### **STEP 10: Open Your Browser**

**After waiting 2-3 minutes, open your web browser and visit:**

```
http://89.117.60.144:3002
```

**You should see your admin dashboard!**

---

## 🎉 **SUCCESS!**

If you can see the dashboard at http://89.117.60.144:3002, congratulations! Your admin NextJS dashboard is successfully deployed.

### **Available Features:**
- 🌐 **Main Dashboard**: http://89.117.60.144:3002
- 🔧 **Health Check**: http://89.117.60.144:3002/api/health
- 📚 **Knowledge Base**: http://89.117.60.144:3002/knowledge-base
- 📊 **Queue Monitoring**: http://89.117.60.144:3002/queue/monitoring
- 📈 **System Status**: http://89.117.60.144:3002/system-status

---

## 🛠 **If Something Goes Wrong**

### **Check if Docker is running:**
```bash
docker ps
```

### **Check logs for errors:**
```bash
docker-compose logs
```

### **Restart the application:**
```bash
docker-compose restart
```

### **Check if port 3002 is open:**
```bash
netstat -tlnp | grep 3002
```

---

## 📞 **Quick Reference**

**Your Information:**
- **Server IP**: 89.117.60.144
- **Username**: root
- **Password**: 772877mAmcIaS
- **Dashboard URL**: http://89.117.60.144:3002
- **Port Used**: 3002

**That's it! Follow these steps one by one and you'll have your admin dashboard running in 10-15 minutes!** 🚀