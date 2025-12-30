# React Native (Expo) Mobile App

This folder contains the "True" React Native mobile app for UPSC PrepX.

## Tech Stack
- **Framework:** Expo (React Native)
- **Styling:** NativeWind (Tailwind CSS for Native)
- **Language:** TypeScript

## Setup & Run
1. Navigate to this folder:
   ```bash
   cd apps/mobile
   ```

2. Install dependencies (if you haven't):
   ```bash
   pnpm install
   ```

3. Run on Android Emulator (or connected device):
   ```bash
   npx expo start --android
   ```
   *Note: You need Android Studio installed and an emulator running, OR connect a physical Android device via USB.*

4. Run on iOS (Mac only):
   ```bash
   npx expo start --ios
   ```

## Folder Structure
- `App.tsx`: Main entry point.
- `global.css`: Tailwind imports.
- `tailwind.config.js`: Tailwind configuration.
- `babel.config.js`: Babel configuration for NativeWind.
