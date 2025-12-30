import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.upscprepx.app',
  appName: 'UPSC PrepX',
  webDir: 'out',
  server: {
    // IMPORTANT: Replace this with your actual deployed URL (e.g., https://your-app.netlify.app)
    // For local testing on emulator, use http://10.0.2.2:3000
    // For local testing on physical device, use your computer's IP address
    url: 'http://89.117.60.144:3000', 
    cleartext: true, // Allows http (not just https)
    androidScheme: 'https'
  }
};

export default config;
