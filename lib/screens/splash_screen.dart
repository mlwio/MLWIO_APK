import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/version_checker_service.dart';
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
  
  bool _dataLoaded = false;
  bool _animationComplete = false;
  bool _updateCheckComplete = true;

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

    _startAnimationAndDataLoading();
  }

  Future<void> _startAnimationAndDataLoading() async {
    _startAnimation();
    
    await Future.wait([
      _loadData(),
      _checkForUpdates(),
    ]);
    
    await _waitForAnimationCompletion();
    
    if (mounted && _updateCheckComplete) {
      _navigateToNextScreen();
    }
  }

  void _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();
    _glowController.forward();
    
    await Future.delayed(const Duration(milliseconds: 2300));
    setState(() {
      _animationComplete = true;
    });
  }

  Future<void> _loadData() async {
    try {
      await Hive.openBox('userBox');
      
      await Future.delayed(const Duration(milliseconds: 1500));
      
      setState(() {
        _dataLoaded = true;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() {
        _dataLoaded = true;
      });
    }
  }

  Future<void> _checkForUpdates() async {
    try {
      final versionChecker = VersionCheckerService();
      final needsUpdate = await versionChecker.needsUpdate();
      
      if (needsUpdate && mounted) {
        final remoteData = await versionChecker.fetchRemoteVersion();
        if (remoteData != null && remoteData.containsKey('downloadUrl')) {
          final downloadUrl = remoteData['downloadUrl'] as String;
          
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (mounted) {
            versionChecker.showUpdateDialog(context, downloadUrl);
            setState(() {
              _updateCheckComplete = false;
            });
            return;
          }
        }
      }
      
      setState(() {
        _updateCheckComplete = true;
      });
    } catch (e) {
      debugPrint('Version check error: $e');
      setState(() {
        _updateCheckComplete = true;
      });
    }
  }

  Future<void> _waitForAnimationCompletion() async {
    while (!_animationComplete || !_dataLoaded) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  void _navigateToNextScreen() {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const WelcomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
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
              flightShuttleBuilder: (
                BuildContext flightContext,
                Animation<double> animation,
                HeroFlightDirection flightDirection,
                BuildContext fromHeroContext,
                BuildContext toHeroContext,
              ) {
                return DefaultTextStyle(
                  style: DefaultTextStyle.of(toHeroContext).style,
                  child: toHeroContext.widget,
                );
              },
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
