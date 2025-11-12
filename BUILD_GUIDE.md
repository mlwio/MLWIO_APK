# MLWIO - Multi-Platform Build Guide

এই Flutter project টি সব platform এর জন্য ready!

## 📱 Supported Platforms

- ✅ **Android** (Phone/Tablet)
- ✅ **iOS** (iPhone/iPad)
- ✅ **macOS** (MacBook/iMac)
- ✅ **Windows** (PC/Laptop)
- ✅ **Linux** (Desktop)
- ✅ **Web** (Browser)

## 🚀 Build Commands

### Android এর জন্য:
```bash
flutter build apk --release          # APK file (সব Android device এ চলবে)
flutter build appbundle --release    # AAB file (Google Play Store এর জন্য)
```
**Output:** `build/app/outputs/flutter-apk/app-release.apk`

### iOS এর জন্য (শুধু Mac থেকে build করতে পারবেন):
```bash
flutter build ios --release
```
**Note:** Xcode দরকার হবে এবং Apple Developer Account

### macOS এর জন্য (শুধু Mac থেকে):
```bash
flutter build macos --release
```
**Output:** `build/macos/Build/Products/Release/mlwio_app.app`

### Windows এর জন্য (শুধু Windows থেকে):
```bash
flutter build windows --release
```
**Output:** `build/windows/x64/runner/Release/`

### Linux এর জন্য:
```bash
flutter build linux --release
```
**Output:** `build/linux/x64/release/bundle/`

### Web এর জন্য:
```bash
flutter build web --release
```
**Output:** `build/web/` (এখন যেটা চলছে)

## 🧪 Testing (Development Mode)

কোনো platform এ test করার জন্য:
```bash
flutter run -d android       # Android
flutter run -d ios          # iOS
flutter run -d macos        # macOS
flutter run -d windows      # Windows
flutter run -d linux        # Linux
flutter run -d chrome       # Web (Chrome)
```

সব available device দেখতে:
```bash
flutter devices
```

## 📦 Requirements

### General:
- Flutter SDK installed
- Dart SDK (Flutter এর সাথে আসে)

### Platform-specific:
- **Android:** Android Studio + Android SDK
- **iOS/macOS:** Xcode (Mac এ)
- **Windows:** Visual Studio 2022 with C++ tools
- **Linux:** Required system libraries (CMake, GTK+3)
- **Web:** Chrome browser

## 🎯 Current Status

✅ All platforms configured and ready to build!
✅ Hero animation smooth and perfect
✅ Multi-platform Flutter project structure complete

## 📝 Notes

- এই project একই codebase দিয়ে সব platform এ চলবে
- Platform-specific customization করতে চাইলে সেই platform এর folder এ যেতে হবে
  - Android: `android/`
  - iOS: `ios/`
  - macOS: `macos/`
  - Windows: `windows/`
  - Linux: `linux/`
  - Web: `web/`

## 🔧 Common Issues

যদি build করতে সমস্যা হয়:
```bash
flutter clean          # Clean previous builds
flutter pub get        # Get dependencies
flutter doctor         # Check system setup
```

Happy Building! 🚀
