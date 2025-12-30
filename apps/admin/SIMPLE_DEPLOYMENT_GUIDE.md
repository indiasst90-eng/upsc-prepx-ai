# 🚀 Super Simple Admin Dashboard Deployment Guide

## For Non-Technical Users - One-Click Deployment

I've created **automated deployment scripts** that will handle everything for you. Just follow these simple steps:

---

## 📋 What You'll Get

After deployment, your admin dashboard will be available at:
- **Main URL**: http://89.117.60.144:3002
- **Health Check**: http://89.117.60.144:3002/api/health
- **Knowledge Base**: http://89.117.60.144:3002/knowledge-base
- **Queue Monitoring**: http://89.117.60.144:3002/queue/monitoring
- **System Status**: http://89.117.60.144:3002/system-status

---

## 🎯 Choose Your Deployment Method

### **Option 1: Windows Users (Easiest)**
1. **Download and run the automated script**:
   - Double-click on: `auto-deploy-windows.bat`
   - Follow the on-screen prompts
   - The script will automatically handle everything

### **Option 2: Mac/Linux Users**
1. **Open Terminal**
2. **Navigate to the admin folder**
3. **Make the script executable**:
   ```bash
   chmod +x auto-deploy-coolify.sh
   ```
4. **Run the script**:
   ```bash
   ./auto-deploy-coolify.sh
   ```

### **Option 3: Manual Step-by-Step (If scripts don't work)**

---

## 🛠 Manual Deployment Steps (For Non-Technical Users)

### Step 1: Prepare Your Files
1. **Open your file explorer**
2. **Navigate to**: `admin/` folder
3. **Copy these files** to a new folder called `deployment-files`:
   - All files from the `admin/` folder
   - Make sure you have: `package.json`, `next.config.js`, `.env.coolify`, etc.

### Step 2: Connect to Your VPS Server
1. **Download and install**:
   - For Windows: [PuTTY](https://www.putty.org/) or [Windows Terminal](https://www.microsoft.com/en-us/p/windows-terminal/9n0dx20hk701)
   - For Mac: Use Terminal (built-in)
   - For Linux: Use Terminal (built-in)

2. **Connect to your server**:
   - **Server IP**: 89.117.60.144
   - **Username**: root
   - **Password**: 772877mAmcIaS

### Step 3: Set Up Docker on Your VPS
1. **Run these commands** (copy and paste one by one):
   ```bash
   apt update
   apt upgrade -y
   apt install -y curl wget git
   curl -fsSL https://get.docker.com -o get-docker.sh
   sh get-docker.sh
   apt install -y docker-compose
   ```

### Step 4: Upload Your Files
1. **Create deployment folder**:
   ```bash
   mkdir -p /var/www/coolify-admin
   cd /var/www/coolify-admin
   ```

2. **Upload your files** using FileZilla or SCP:
   - Host: 89.117.60.144
   - Username: root
   - Password: 772877mAmcIaS
   - Upload all files from your `deployment-files` folder to `/var/www/coolify-admin/`

### Step 5: Deploy the Application
1. **Navigate to deployment folder**:
   ```bash
   cd /var/www/coolify-admin
   ```

2. **Run the deployment**:
   ```bash
   docker-compose up -d --build
   ```

3. **Wait for completion** (2-3 minutes)

### Step 6: Verify Deployment
1. **Check if service is running**:
   ```bash
   docker ps
   ```

2. **Test the health check**:
   ```bash
   curl http://localhost:3002/api/health
   ```

3. **Access your dashboard**:
   - Open browser
   - Go to: http://89.117.60.144:3002

---

## 📊 Environment Variables (Already Configured)

The deployment uses these environment variables:
- **NEXT_PUBLIC_SUPABASE_URL**: http://89.117.60.144:54321
- **NEXT_PUBLIC_SUPABASE_ANON_KEY**: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
- **NODE_ENV**: production
- **PORT**: 3002

---

## 🔍 Troubleshooting

### If deployment fails:

1. **Check if Docker is installed**:
   ```bash
   docker --version
   ```

2. **Check service status**:
   ```bash
   docker ps
   ```

3. **Check logs**:
   ```bash
   docker-compose logs
   ```

4. **Restart if needed**:
   ```bash
   docker-compose restart
   ```

### If you can't access the website:
1. **Check if port 3002 is open**:
   ```bash
   netstat -tlnp | grep 3002
   ```

2. **Check firewall**:
   ```bash
   ufw status
   ```

3. **Allow port 3002**:
   ```bash
   ufw allow 3002
   ```

---

## 🎉 Success Indicators

When everything is working correctly:
- ✅ `docker ps` shows your service running
- ✅ `curl http://localhost:3002/api/health` returns "OK"
- ✅ Website loads at http://89.117.60.144:3002
- ✅ No error messages in `docker-compose logs`

---

## 📞 Quick Reference

**Your Deployment Information:**
- **VPS IP**: 89.117.60.144
- **Application Port**: 3002
- **Dashboard URL**: http://89.117.60.144:3002
- **Admin Features**: Knowledge Base, Queue Monitoring, System Status

**Commands to remember:**
- **Check service**: `docker ps`
- **View logs**: `docker-compose logs`
- **Restart service**: `docker-compose restart`
- **Test health**: `curl http://localhost:3002/api/health`

---

## 🚀 Ready to Deploy?

**Just run the automated script or follow the manual steps above!**

Your admin NextJS dashboard will be fully deployed and accessible within 5-10 minutes.