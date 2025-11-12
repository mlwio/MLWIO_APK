import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _initializeGoogleSignIn();
  }

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn;
  bool _isInitialized = false;

  void _initializeGoogleSignIn() {
    if (kIsWeb) {
      _googleSignIn = GoogleSignIn(
        clientId: '188372451903-ubcaij44j6qpn8fno559k08rkmr5eigr.apps.googleusercontent.com',
        scopes: [
          'email',
          'profile',
        ],
      );
    } else {
      _googleSignIn = GoogleSignIn(
        scopes: [
          'email',
          'profile',
        ],
      );
    }
    _isInitialized = true;
  }

  GoogleSignInAccount? _currentGoogleUser;
  User? get currentUser => _firebaseAuth.currentUser;
  GoogleSignInAccount? get currentGoogleUser => _currentGoogleUser;

  bool get isSignedIn => _firebaseAuth.currentUser != null;

  Future<void> initialize() async {
    if (!_isInitialized) {
      _initializeGoogleSignIn();
    }
    
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      _currentGoogleUser = account;
      if (kDebugMode) {
        print('Google user changed: ${account?.displayName}');
      }
    });

    _firebaseAuth.authStateChanges().listen((User? user) {
      if (kDebugMode) {
        print('Firebase auth state changed: ${user?.displayName ?? 'No user'}');
      }
    });

    try {
      await _googleSignIn.signInSilently();
    } catch (error) {
      if (kDebugMode) {
        print('Error signing in silently: $error');
      }
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        if (kDebugMode) {
          print('Google Sign-In cancelled by user');
        }
        return null;
      }

      _currentGoogleUser = googleUser;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = 
          await _firebaseAuth.signInWithCredential(credential);

      if (kDebugMode) {
        print('✅ Firebase sign-in successful!');
        print('User: ${userCredential.user?.displayName}');
        print('Email: ${userCredential.user?.email}');
        print('UID: ${userCredential.user?.uid}');
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('❌ Firebase Auth Error: ${e.code}');
        print('Message: ${e.message}');
      }
      rethrow;
    } catch (error) {
      if (kDebugMode) {
        print('❌ Error signing in with Google: $error');
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
      _currentGoogleUser = null;
      if (kDebugMode) {
        print('✅ User signed out successfully');
      }
    } catch (error) {
      if (kDebugMode) {
        print('❌ Error signing out: $error');
      }
      rethrow;
    }
  }

  Future<GoogleSignInAuthentication?> getGoogleAuthentication() async {
    if (_currentGoogleUser == null) return null;
    try {
      return await _currentGoogleUser!.authentication;
    } catch (error) {
      if (kDebugMode) {
        print('Error getting Google authentication: $error');
      }
      return null;
    }
  }

  Future<String?> getIdToken() async {
    try {
      return await _firebaseAuth.currentUser?.getIdToken();
    } catch (error) {
      if (kDebugMode) {
        print('Error getting ID token: $error');
      }
      return null;
    }
  }
}
