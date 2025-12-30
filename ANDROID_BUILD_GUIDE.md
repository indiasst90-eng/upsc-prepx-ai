# Android App Build Guide for UPSC PrepX

This guide explains how to convert your Next.js Web App into a native Android App using **Capacitor**.

## How It Works
We have configured the app as a **Hybrid App**.
- The Android App acts as a "Shell" (like a dedicated browser).
- It loads your live website (e.g., from Netlify or your VPS).
- This ensures all features (Auth, Database, UI) work exactly as they do on the web.

## Prerequisites
To build the `.apk` file, you need **Android Studio** installed on your computer.
- [Download Android Studio](https://developer.android.com/studio) (It's free).

## Step 1: Configure Your URL
Before building, you MUST tell the app where your website is hosted.

1. Open `apps/web/capacitor.config.ts`.
2. Look for the `server` section:
   ```typescript
   server: {
     // Replace this with your REAL URL
     url: 'http://89.117.60.144:3000', 
     cleartext: true,
     androidScheme: 'https'
   }
   ```
3. If you deployed to Netlify, change it to: `url: 'https://your-app-name.netlify.app'`.

## Step 2: Sync Changes
If you change the config or icons, run this command in your terminal (inside `apps/web`):
```bash
cd apps/web
pnpm cap sync
```

## Step 3: Build the APK
1. Open **Android Studio**.
2. Click **Open** and select the folder: `E:\BMAD method\BMAD 4\apps\web\android`.
3. Wait for Gradle to sync (it downloads necessary tools).
4. Connect your Android phone via USB (enable Developer Options > USB Debugging).
5. Click the green **Run (Play)** button in the top toolbar.

### To generate a shareable APK (for others to install):
1. In Android Studio, go to **Build > Build Bundle(s) / APK(s) > Build APK(s)**.
2. Once done, a popup will appear. Click **locate** to find the `app-debug.apk` file.
3. You can send this file to your phone and install it.

## Troubleshooting
- **"Webpage not available"**: Check if your `url` in `capacitor.config.ts` is correct and accessible from your phone.
- **"Cleartext traffic not permitted"**: We already enabled `usesCleartextTraffic="true"`, so HTTP URLs should work.
