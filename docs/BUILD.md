# ==============================================================================
# MEETING TRACKER - COMPILATION & BUILD INSTRUCTIONS
# Target Platforms: Windows 64-bit Desktop, Android APK, Web, Node.js Backend
# ==============================================================================

This document provides exact instructions for compiling, building release binaries, and running the Meeting Tracker application across all supported targets.

---

## PREREQUISITES

| Component | Minimum Version | Verified Version |
|---|---|---|
| **Flutter SDK** | 3.24.0+ | 3.50.1 |
| **Dart SDK** | 3.5.0+ | 3.14.0 |
| **Node.js** | 20.0.0+ | 26.13.0 |
| **PostgreSQL** | 15.0+ | 16.0 (Managed Render) |
| **Visual Studio** (Windows) | 2022 Community | MSVC v143 toolchain |
| **Android SDK / JDK** | JDK 17, SDK 34 | Android Studio Giraffe+ |

---

## 1. COMPILING NATIVE WINDOWS RELEASE BINARY

### Step 1: Navigate to Flutter Application Directory
```bash
cd "meeting_tracker/app"
```

### Step 2: Fetch Dependencies
```bash
flutter pub get
```

### Step 3: Compile Windows Release
```bash
flutter build windows --release
```

### Step 4: Output Location
The compiled release executable and its supporting DLLs will be generated at:
```
build\windows\x64\runner\Release\
├── meeting_tracker.exe
├── flutter_windows.dll
├── sqlite3.dll
├── data\
```

### Step 5: Packaging for Distribution
To create a standalone portable bundle or installer:
1. Zip the contents of `build\windows\x64\runner\Release\`.
2. Name the archive `MeetingTracker-Windows-v1.0.0.zip`.
3. Alternatively, compile an Inno Setup script to generate `MeetingTracker-Setup.exe`.
4. Copy the release artifact into `meeting_tracker/release/`.

---

## 2. COMPILING ANDROID RELEASE APK

### Step 1: Verify Android SDK & Keystore
Ensure `ANDROID_HOME` is configured in your environment variables.

### Step 2: Build Release APK
```bash
cd "meeting_tracker/app"
flutter build apk --release
```

To build architecture-specific APKs (reduced file size):
```bash
flutter build apk --split-per-abi --release
```

### Step 3: Output Location
The generated APK will be located at:
```
build\app\outputs\flutter-apk\app-release.apk
```
Copy `app-release.apk` into `meeting_tracker/release/MeetingTracker-Android-v1.0.0.apk`.

---

## 3. BUILDING & RUNNING THE WEB APPLICATION

To serve the application on local or internal enterprise intranets:
```bash
cd "meeting_tracker/app"
flutter build web --release
```
Output files will be generated in `build/web/` and can be hosted on Cloudflare Pages, Nginx, or Amazon S3.

---

## 4. RUNNING AND DEPLOYING THE BACKEND SERVER

### Step 1: Navigate to Server Directory
```bash
cd "meeting_tracker/server"
```

### Step 2: Install Server Dependencies
```bash
npm install
```

### Step 3: Run Database Migrations and Seed Data
```bash
npm run migrate
npm run seed
```

### Step 4: Run Automated Test Suite
```bash
npm test
```

### Step 5: Start Local Server
```bash
npm start
```
The server will bind to `http://localhost:3000` with:
- Health check: `http://localhost:3000/api/v1/health`
- Interactive Swagger Docs: `http://localhost:3000/api/docs`
- Realtime WebSocket: `ws://localhost:3000/ws`
