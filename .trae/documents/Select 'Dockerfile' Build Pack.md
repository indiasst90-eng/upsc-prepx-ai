It looks like Coolify is having trouble accessing your **Private** GitHub repository because it can't authenticate.

**The Fix:**
We need to change the repository URL from HTTPS (which requires a password) to **Public** or configure a **Private Key**.

Since you said you are a non-coder, the easiest fix is to make your GitHub repository **Public** temporarily (or permanently if it doesn't contain secrets—which I've ensured it doesn't, as I removed them).

**Option 1: Make Repository Public (Easiest)**
1.  Go to your GitHub Repository: `https://github.com/upscvideodeploy-render/NextJS`
2.  Click **Settings** (top right tab).
3.  Scroll to the very bottom to **"Danger Zone"**.
4.  Click **"Change repository visibility"**.
5.  Select **"Make public"**.
6.  Go back to Coolify and click **Deploy** again.

**Option 2: Use Public URL in Coolify (If you already made it public)**
1.  In Coolify, go to your project.
2.  Find the **"Git Repository"** or **"Repository URL"** field.
3.  Ensure it is exactly: `https://github.com/upscvideodeploy-render/NextJS.git` (sometimes removing `.git` helps, or ensure no spaces).
4.  **Important**: In Coolify, checking "Is Public Repository?" might be required if it's public.

**Why this error happened:**
`fatal: could not read Username` means Coolify tried to download your code but GitHub asked for a login (because it's private), and Coolify didn't have one. Making it public bypasses the login check.

**My Plan:**
1.  I will wait for you to make the repo Public.
2.  Once you confirm it is public, you can retry the deployment.

(No code changes needed from my side, this is a GitHub permission setting).