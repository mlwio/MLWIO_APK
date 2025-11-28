# Firebase Setup Guide - All Platforms (iOS, Web, macOS, Windows, Linux)

## 📱 iOS Setup (for iPhone/iPad)

### Step 1: Firebase Console Setup

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Select your project**: "mlwio-apk"
3. **Add iOS app**: Click "Add app" → Select iOS
4. **Fill in details**:
   - **iOS bundle ID**: `com.example.mlwio_app` (same as Android)
   - **App nickname** (optional): "MLWIO iOS"
   - Click "Register app"

### Step 2: Download GoogleService-Info.plist

1. **Download** the `GoogleService-Info.plist` file
2. **Place it** in this location:
   ```
   ios/Runner/GoogleService-Info.plist
   ```

### Step 3: Enable Google Sign-In for iOS

1. In Firebase Console → **Authentication** → **Sign-in method**
2. Click **Google** provider
3. **Copy the iOS URL scheme** (looks like: `com.googleusercontent.apps.188372451903-xxxxx`)
4. Keep this for next step

### Step 4: Update iOS Configuration

Add this to `ios/Runner/Info.plist` (inside `<dict>` tag):

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- Copy from Firebase Console -->
            <string>com.googleusercontent.apps.188372451903-ubcaij44j6qpn8fno559k08rkmr5eigr</string>
        </array>
    </dict>
</array>
```

### Step 5: Build for iOS

**On Mac only**:
```bash
flutter build ios
# or
flutter run (with iOS simulator/device)
```

**Requirements for iOS**:
- ✅ **macOS** computer (iOS can only be built on Mac)
- ✅ **Xcode** installed
- ✅ **CocoaPods** installed
- ✅ **iOS Simulator** or real iPhone/iPad

---

## 🌐 Web App Setup

### Step 1: Add Web App to Firebase

1. **Firebase Console**: https://console.firebase.google.com/
2. **Select project**: "mlwio-apk"
3. **Add Web app**: Click "Add app" → Select Web (</>) icon
4. **Register app**:
   - **App nickname**: "MLWIO Web"
   - ✅ **Check** "Also set up Firebase Hosting"
   - Click "Register app"

### Step 2: Copy Web Configuration

You'll see something like this:

```javascript
const firebaseConfig = {
  apiKey: "AIzaSyAP5ZkwpT-83XhuirCsY7uoA7kc9qI0qWk",
  authDomain: "mlwio-apk.firebaseapp.com",
  projectId: "mlwio-apk",
  storageBucket: "mlwio-apk.firebasestorage.app",
  messagingSenderId: "188372451903",
  appId: "1:188372451903:web:xxxxxxxxxxxxx"
};
```

### Step 3: Create Firebase Config for Web

Create file: `web/firebase-config.js`

```javascript
// Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyAP5ZkwpT-83XhuirCsY7uoA7kc9qI0qWk",
  authDomain: "mlwio-apk.firebaseapp.com",
  projectId: "mlwio-apk",
  storageBucket: "mlwio-apk.firebasestorage.app",
  messagingSenderId: "188372451903",
  appId: "YOUR_WEB_APP_ID" // Copy from Firebase Console
};
```

### Step 4: Add Authorized Domains

1. **Firebase Console** → **Authentication** → **Settings**
2. **Authorized domains** tab
3. **Add domain**: Add your Replit domain or localhost
   - For Replit: Your app URL (e.g., `xxxxx.replit.app`)
   - For local: `localhost`

### Step 5: Build Web App

```bash
flutter build web --release
```

Your web app with Firebase is ready! The current setup already serves on port 5000.

---

## 🖥️ macOS Desktop App Setup

### Step 1: Add macOS App to Firebase

1. **Firebase Console** → Select project
2. **Add macOS app**
3. **Bundle ID**: `com.example.mlwio_app`
4. **Download** `GoogleService-Info.plist`
5. **Place it** in: `macos/Runner/GoogleService-Info.plist`

### Step 2: Update macOS Configuration

Edit `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements`:

```xml
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.security.network.server</key>
<true/>
```

### Step 3: Build for macOS

**On Mac only**:
```bash
flutter build macos
# or
flutter run -d macos
```

**Requirements**:
- ✅ macOS computer
- ✅ Xcode installed

---

## 🪟 Windows Desktop App Setup

### Step 1: No Firebase Config File Needed

Windows uses the same Firebase configuration from your Flutter code (already done).

### Step 2: Build for Windows

**On Windows only**:
```bash
flutter build windows
# or
flutter run -d windows
```

**Requirements**:
- ✅ Windows 10/11
- ✅ Visual Studio 2019 or later with C++ tools
- ✅ Flutter Windows development setup

### Step 3: Enable Google Sign-In for Windows

Google Sign-In on Windows desktop requires:
1. OAuth web flow (already configured)
2. Local web server for callback

The current setup should work automatically!

---

## 🐧 Linux Desktop App Setup

### Step 1: No Firebase Config File Needed

Linux uses the same Firebase configuration from your Flutter code.

### Step 2: Install Required Dependencies

```bash
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev
```

### Step 3: Build for Linux

**On Linux only**:
```bash
flutter build linux
# or
flutter run -d linux
```

**Requirements**:
- ✅ Ubuntu 18.04 or later (or other Linux distros)
- ✅ Development tools installed
- ✅ GTK 3.0 development libraries

---

## 📊 Platform Comparison Table

| Platform | Firebase Config File | Where to Place | Build Command | Build OS Required |
|----------|---------------------|----------------|---------------|-------------------|
| **Android** | `google-services.json` | `android/app/` | `flutter build apk` | Any (Mac/Windows/Linux) |
| **iOS** | `GoogleService-Info.plist` | `ios/Runner/` | `flutter build ios` | **macOS only** |
| **Web** | Web config object | `web/firebase-config.js` | `flutter build web` | Any |
| **macOS** | `GoogleService-Info.plist` | `macos/Runner/` | `flutter build macos` | **macOS only** |
| **Windows** | Not needed | - | `flutter build windows` | **Windows only** |
| **Linux** | Not needed | - | `flutter build linux` | **Linux only** |

---

## 🎯 Quick Setup Checklist

### ✅ Already Done (Android)
- [x] Android google-services.json configured
- [x] SHA-1 fingerprint added
- [x] Google Sign-In enabled
- [x] OAuth client configured

### 📝 To Do for Other Platforms

#### iOS (if you have a Mac):
- [ ] Add iOS app to Firebase Console
- [ ] Download GoogleService-Info.plist
- [ ] Place in ios/Runner/
- [ ] Update Info.plist with URL scheme
- [ ] Build and test

#### Web:
- [ ] Add Web app to Firebase Console
- [ ] Get web configuration
- [ ] Add authorized domains
- [ ] Current web build already works!

#### macOS (if you have a Mac):
- [ ] Add macOS app to Firebase Console
- [ ] Download GoogleService-Info.plist
- [ ] Place in macos/Runner/
- [ ] Update entitlements
- [ ] Build and test

#### Windows (if you have Windows):
- [ ] No Firebase config needed
- [ ] Just build: `flutter build windows`

#### Linux (if you have Linux):
- [ ] Install dependencies
- [ ] No Firebase config needed
- [ ] Just build: `flutter build linux`

---

## 🚀 Build Commands Summary

```bash
# Android (any OS)
flutter build apk

# iOS (macOS only)
flutter build ios

# Web (any OS)
flutter build web --release

# macOS (macOS only)
flutter build macos

# Windows (Windows only)
flutter build windows

# Linux (Linux only)
flutter build linux
```

---

## 💡 Important Notes

1. **iOS & macOS**: Can ONLY be built on macOS with Xcode
2. **Windows**: Can ONLY be built on Windows with Visual Studio
3. **Linux**: Can ONLY be built on Linux
4. **Android & Web**: Can be built on ANY operating system

Your **Android setup is 100% complete**. For other platforms, follow the steps above based on which OS you have access to!
