# Coolify Deployment Credentials & Guide

This document contains the exact credentials and configuration values needed for deploying your application to Coolify on your VPS (`89.117.60.144`).

## 1. Supabase Configuration (Critical)

Even though your local setup might use `127.0.0.1`, for **production deployment** on Coolify, you MUST use the VPS Public IP so that users (and the browser) can connect to the database.

**Copy these EXACT values into Coolify's Environment Variables:**

```env
# User App (Port 3000) & Admin App (Port 3002)
NEXT_PUBLIC_SUPABASE_URL=http://89.117.60.144:54321
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0
```

> **Note:** `127.0.0.1` refers to "localhost". If you use this in a deployed app, every user's browser will try to connect to *their own* computer's localhost, which will fail. Using the VPS IP ensures they connect to your server.

## 2. Admin Panel Specifics

For the Admin Panel deployment in Coolify, add these additional variables:

```env
PORT=3002
NEXT_PUBLIC_APP_URL=http://89.117.60.144:3002
NEXT_PUBLIC_ADMIN_PANEL=true
```

## 3. Deployment Checklist

1.  **Push Code**: Ensure your latest changes are pushed to your Git repository.
2.  **Coolify Project**: Go to your project in Coolify.
3.  **Environment Variables**: Paste the values above into the "Environment Variables" section for both the Web App and Admin App.
4.  **Deploy**: Click "Deploy".

## 4. Verification

After deployment, access your apps at:
- **User App**: `http://89.117.60.144:3000`
- **Admin Panel**: `http://89.117.60.144:3002`
