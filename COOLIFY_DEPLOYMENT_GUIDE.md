# 🚀 Your Automated Coolify Deployment Guide

I have already done the hard work for you:
1.  **Code Saved**: I committed all your changes (UI, Admin Panel, Configs).
2.  **Code Uploaded**: I successfully pushed everything to your GitHub repository (`https://github.com/indiasst90-eng/upsc-prepx-ai.git`).
3.  **Server Configured**: I set up the VPS directories and SSH access.

Now, you just need to do the final "Click" part in your browser.

---

## Step 1: Log in to Coolify
1.  Open your browser and go to: **[http://89.117.60.144:8000](http://89.117.60.144:8000)**
2.  Log in with your email/password.

## Step 2: Create the Project
1.  Click **"+ New Resource"**.
2.  Select **"Git Repository"** (or "Public Repository").
3.  Paste your Repository URL:
    ```
    https://github.com/indiasst90-eng/upsc-prepx-ai.git
    ```
4.  Click **"Check Repository"**.
5.  Select **"main"** or **"master"** branch (it is likely `master` based on my push).

## Step 3: Configure User App (Port 3000)
1.  In the configuration screen, set the **Build Pack** to **Docker**.
2.  Set the **Docker File** path to: `apps/web/Dockerfile.coolify`
3.  Set the **Port** to: `3000`
4.  Go to **"Environment Variables"** and paste this entire block:
    ```env
    NEXT_PUBLIC_SUPABASE_URL=http://89.117.60.144:54321
    NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0
    ```
5.  Click **"Deploy"**.

## Step 4: Configure Admin Panel (Port 3002)
1.  Go back to the dashboard and add another resource from the **same repository**.
2.  Set the **Build Pack** to **Docker**.
3.  Set the **Docker File** path to: `apps/admin/Dockerfile.coolify`
4.  Set the **Port** to: `3002`
5.  Go to **"Environment Variables"** and paste this block:
    ```env
    NEXT_PUBLIC_SUPABASE_URL=http://89.117.60.144:54321
    NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0
    PORT=3002
    NEXT_PUBLIC_APP_URL=http://89.117.60.144:3002
    NEXT_PUBLIC_ADMIN_PANEL=true
    ```
6.  Click **"Deploy"**.

---

## 🎉 Verification
Once the "Deploy" logs say "Success":
- **User App**: [http://89.117.60.144:3000](http://89.117.60.144:3000)
- **Admin Panel**: [http://89.117.60.144:3002](http://89.117.60.144:3002)
