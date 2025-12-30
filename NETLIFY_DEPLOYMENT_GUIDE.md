# How to Deploy to Netlify

Since you are having trouble with Coolify/Docker, **Netlify** is a much easier alternative. It handles Next.js applications automatically without needing any Dockerfiles.

## Step 1: Sign Up & Connect GitHub
1.  Go to [https://www.netlify.com/](https://www.netlify.com/) and click **Sign Up**.
2.  Choose **"Sign up with GitHub"**.
3.  Authorize Netlify to access your GitHub account.

## Step 2: Add Your Site
1.  Once logged in, click **"Add new site"** > **"Import an existing project"**.
2.  Select **GitHub**.
3.  Search for your repository: `upscvideodeploy-render/NextJS`.
4.  Select it.

## Step 3: Configure Build Settings (Important!)
You will see a configuration screen. Fill it out exactly like this:

*   **Branch to deploy**: `main`
*   **Base directory**: `apps/web`
    *   *(This tells Netlify your app is inside the 'apps/web' folder, not the root)*
*   **Build command**: `npm run build`
    *   *(Netlify usually auto-detects this)*
*   **Publish directory**: `.next`
    *   *(Netlify usually auto-detects this)*

## Step 4: Add Environment Variables
Click on **"Add environment variables"** (or "Show advanced" > "New Variable"). You need to add the same keys you used in Coolify:

1.  **Key**: `NEXT_PUBLIC_SUPABASE_URL`
    *   **Value**: `http://89.117.60.144:54321` (Or your actual Supabase URL)
2.  **Key**: `NEXT_PUBLIC_SUPABASE_ANON_KEY`
    *   **Value**: `(Paste your long Anon Key here)`
3.  **Key**: `NEXT_PUBLIC_SITE_URL`
    *   **Value**: (Leave blank for now, or put your Netlify URL after deploy)

## Step 5: Deploy
1.  Click **"Deploy NextJS"**.
2.  Netlify will start building. It might take 2-3 minutes.
3.  Once done, it will give you a link like `https://funny-name-123456.netlify.app`.

## Troubleshooting
*   If the build fails saying "Command not found", make sure your **Base directory** is set to `apps/web`.
