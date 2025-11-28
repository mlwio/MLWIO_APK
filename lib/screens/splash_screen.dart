import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';
import 'welcome_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _glowController;
  late Animation<double> _logoScale;
  late Animation<double> _logoPosition;
  late Animation<double> _glowIntensity;
  
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_logoController);

    _logoPosition = Tween<double>(
      begin: -300.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    ));

    _glowIntensity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.5)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.5, end: 0.3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
    ]).animate(_glowController);

    _startSplash();
  }

  Future<void> _startSplash() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    _logoController.forward();
    _glowController.forward();
    _playIntroAudio();
    
    try {
      await Hive.openBox('userBox');
    } catch (e) {
      debugPrint('Hive error: $e');
    }
    
    await Future.delayed(const Duration(milliseconds: 2500));
    
    if (mounted) {
      _navigateToNextScreen();
    }
  }

  Future<void> _playIntroAudio() async {
    try {
      if (kIsWeb) {
        await _audioPlayer.play(AssetSource('sound/intro_sound.mp3')).timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            debugPrint('Audio play timed out on web');
          },
        );
        debugPrint('Audio started playing on web');
      } else {
        _audioPlayer.play(AssetSource('sound/intro_sound.mp3'));
      }
    } catch (e) {
      debugPrint('Error playing intro audio: $e');
    }
  }

  void _navigateToNextScreen() {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      Get.offAll(
        () => const HomeScreen(),
        transition: Transition.fade,
        duration: const Duration(milliseconds: 600),
      );
    } else {
      Get.offAll(
        () => const WelcomeScreen(),
        transition: Transition.fade,
        duration: const Duration(milliseconds: 800),
      );
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _logoController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0D),
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_logoController, _glowController]),
          builder: (context, child) {
            return Hero(
              tag: 'appLogo',
              child: Transform.translate(
                offset: Offset(0, _logoPosition.value),
                child: Transform.scale(
                  scale: _logoScale.value,
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(_glowIntensity.value),
                          blurRadius: 60,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/mlwio_logo.png',
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
