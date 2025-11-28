import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:get/get.dart';
import 'screens/home_screen.dart';
import 'services/admob_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Hive.initFlutter();
    await Hive.openBox('watch_history');
    await Hive.openBox('downloads');
    print('Hive initialized successfully');
  } catch (e) {
    if (kDebugMode) {
      print('Error initializing Hive: $e');
    }
  }
  
  if (!kIsWeb) {
    AdMobService().initialize();
  }
  
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyAP5ZkwpT-83XhuirCsY7uoA7kc9qI0qWk",
          authDomain: "mlwio-apk.firebaseapp.com",
          projectId: "mlwio-apk",
          storageBucket: "mlwio-apk.firebasestorage.app",
          messagingSenderId: "188372451903",
          appId: "1:188372451903:web:e474051112589aac512e8a",
          measurementId: "G-RQQ9HM1NV6",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error initializing Firebase: $e');
    }
  }
  
  runApp(const MLWIOApp());
}

class MLWIOApp extends StatelessWidget {
  const MLWIOApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'MLWIO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0B0D),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
          surface: const Color(0xFF121214),
          background: const Color(0xFF0B0B0D),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
