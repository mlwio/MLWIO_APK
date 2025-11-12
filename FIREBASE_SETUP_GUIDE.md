# Firebase Authentication Setup Guide for MLWIO App

## 📋 Overview
This guide will walk you through setting up Firebase Authentication with Google Sign-In for your Android app.

---

## 🔑 Step 1: Get Your SHA-1 Certificate

Run this command in your terminal to get your SHA-1 fingerprint:

```bash
cd android && ./gradlew signingReport
```

Look for the **SHA-1** under the **debug** variant. It will look like:
```
SHA1: AA:BB:CC:DD:EE:FF:11:22:33:44:55:66:77:88:99:00:11:22:33:44
```

**Copy this SHA-1 key** - you'll need it in the next step.

---

## 🔥 Step 2: Firebase Console Setup

### 2.1 Create/Select Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"** or select an existing project
3. Follow the setup wizard to create your project

### 2.2 Add Android App

1. In your Firebase project, click **"Add app"** and select **Android**
2. Fill in the details:
   - **Package name**: `com.example.mlwio_app`
   - **App nickname** (optional): "MLWIO App"
   - **SHA-1 certificate**: Paste the SHA-1 from Step 1
3. Click **"Register app"**

### 2.3 Download google-services.json

1. After registering, Firebase will provide a **`google-services.json`** file
2. Click **"Download google-services.json"**
3. **IMPORTANT**: Place this file at: `android/app/google-services.json`

```
android/
└── app/
    ├── build.gradle.kts
    └── google-services.json  ← Put it here!
```

### 2.4 Enable Google Sign-In

1. In Firebase Console, go to **Authentication** → **Sign-in method**
2. Click **Google** and enable it
3. Set a support email
4. Click **Save**

---

## ✅ Step 3: Verify Your Configuration

Your project files have been updated with:

### ✓ Firebase Dependencies Added
- `firebase_core: ^3.1.0`
- `firebase_auth: ^5.1.0`
- Google Services plugin configured

### ✓ Updated Files
1. **`pubspec.yaml`** - Added Firebase packages
2. **`android/build.gradle.kts`** - Added Google Services classpath
3. **`android/app/build.gradle.kts`** - Added Google Services plugin
4. **`lib/services/auth_service.dart`** - Integrated Firebase Auth
5. **`lib/main.dart`** - Added Firebase initialization

---

## 🎯 Step 4: Using the Authentication Service

### Sign In with Google

```dart
import 'package:mlwio_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> handleGoogleSignIn() async {
  try {
    final UserCredential? credential = await AuthService().signInWithGoogle();
    
    if (credential != null) {
      print('✅ Sign-in successful!');
      print('User: ${credential.user?.displayName}');
      print('Email: ${credential.user?.email}');
      print('UID: ${credential.user?.uid}');
      
      // Navigate to home screen or show success
    } else {
      print('Sign-in cancelled by user');
    }
  } on FirebaseAuthException catch (e) {
    // Handle Firebase-specific errors
    if (e.code == 'account-exists-with-different-credential') {
      print('Account exists with different credential');
    } else if (e.code == 'invalid-credential') {
      print('Invalid credential');
    } else if (e.code == 'operation-not-allowed') {
      print('Operation not allowed');
    } else if (e.code == 'user-disabled') {
      print('User account disabled');
    } else {
      print('Firebase error: ${e.code} - ${e.message}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
```

### Check Sign-In Status

```dart
bool isUserSignedIn = AuthService().isSignedIn;
User? currentUser = AuthService().currentUser;

if (isUserSignedIn) {
  print('User is signed in: ${currentUser?.displayName}');
} else {
  print('No user signed in');
}
```

### Sign Out

```dart
Future<void> handleSignOut() async {
  try {
    await AuthService().signOut();
    print('✅ Signed out successfully');
    // Navigate to welcome/sign-in screen
  } catch (e) {
    print('Error signing out: $e');
  }
}
```

### Get User Information

```dart
User? user = AuthService().currentUser;

if (user != null) {
  String? displayName = user.displayName;
  String? email = user.email;
  String? photoURL = user.photoURL;
  String uid = user.uid;
  
  print('Name: $displayName');
  print('Email: $email');
  print('Photo: $photoURL');
  print('UID: $uid');
}
```

---

## 🔒 Common Error Codes & Solutions

| Error Code | Meaning | Solution |
|------------|---------|----------|
| `account-exists-with-different-credential` | Account exists with different provider | Ask user to sign in with the original provider |
| `invalid-credential` | Credential is malformed or expired | Re-authenticate |
| `operation-not-allowed` | Google sign-in not enabled | Enable in Firebase Console |
| `user-disabled` | User account has been disabled | Contact support |
| `user-not-found` | No user with this credential | Sign up first |
| `network-request-failed` | No internet connection | Check network |

---

## 🧪 Testing Your Implementation

### 1. Build and Run on Android

```bash
flutter run -d <your-device-id>
```

### 2. Test Sign-In Flow

1. Click "Sign in with Google"
2. Select your Google account
3. Grant permissions
4. Verify you're signed in (check debug console for logs)

### 3. Check Debug Logs

Look for these logs in your console:
- ✅ `Firebase sign-in successful!`
- ✅ `User: [Name]`
- ✅ `Email: [Email]`
- ✅ `UID: [User ID]`

---

## 📱 Android-Specific Requirements

### Minimum SDK Version
Your app requires:
- **minSdk**: Set by Flutter (usually 21+)
- **targetSdk**: Latest Android version

### Permissions
Google Sign-In requires internet permission (already included in Android by default):
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

---

## 🚀 Next Steps

1. **Place `google-services.json`** in `android/app/` directory
2. **Build your app**: `flutter run`
3. **Test sign-in** with a real Google account
4. **Handle errors** gracefully with user-friendly messages
5. **Store user data** in Firestore or your backend

---

## 🆘 Troubleshooting

### Issue: "google-services.json not found"
**Solution**: Ensure `google-services.json` is in `android/app/` directory

### Issue: "SHA-1 mismatch" or "Sign-in failed"
**Solution**: 
- Verify SHA-1 is correctly added in Firebase Console
- Make sure you're using the correct package name

### Issue: "API not enabled"
**Solution**: 
- Go to Google Cloud Console
- Enable "Google Sign-In API"

### Issue: "Developer error" on sign-in
**Solution**:
- Double-check OAuth client is created in Firebase
- Verify SHA-1 matches your debug keystore

---

## 📚 Additional Resources

- [Firebase Auth Documentation](https://firebase.google.com/docs/auth/android/google-signin)
- [Flutter Firebase Documentation](https://firebase.flutter.dev/docs/auth/usage)
- [Google Sign-In Plugin](https://pub.dev/packages/google_sign_in)

---

## ✨ Your App is Ready!

Once you've completed all the steps above, your MLWIO app will have:
- ✅ Firebase Authentication integrated
- ✅ Google Sign-In working
- ✅ Proper error handling
- ✅ User session management
- ✅ Secure authentication flow

**Happy coding! 🎉**
