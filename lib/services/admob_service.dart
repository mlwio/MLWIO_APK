import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  static const String appId = "ca-app-pub-1106487052120776~9296916453";
  static const String interstitialAdUnitId = "ca-app-pub-1106487052120776/8445324625";
  static const String testInterstitialAdUnitId = "ca-app-pub-3940256099942544/1033173712";
  
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;
  Timer? _autoAdTimer;
  DateTime? _lastAdShownTime;
  
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();
  
  Future<void> initialize() async {
    if (kIsWeb) {
      if (kDebugMode) {
        print('AdMob is not supported on Web platform - using simulation');
      }
      _startAutoAdTimer();
      return;
    }
    
    try {
      await MobileAds.instance.initialize();
      
      if (kDebugMode) {
        print('AdMob initialized successfully');
      }
      
      await _loadInterstitialAd();
      _startAutoAdTimer();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing AdMob: $e');
      }
    }
  }
  
  Future<void> _loadInterstitialAd() async {
    if (kIsWeb) return;
    
    try {
      await InterstitialAd.load(
        adUnitId: kDebugMode ? testInterstitialAdUnitId : interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isInterstitialAdReady = true;
            
            if (kDebugMode) {
              print('Interstitial ad loaded successfully');
            }
            
            _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _interstitialAd = null;
                _isInterstitialAdReady = false;
                _loadInterstitialAd();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                if (kDebugMode) {
                  print('Interstitial ad failed to show: $error');
                }
                ad.dispose();
                _interstitialAd = null;
                _isInterstitialAdReady = false;
                _loadInterstitialAd();
              },
            );
          },
          onAdFailedToLoad: (error) {
            if (kDebugMode) {
              print('Interstitial ad failed to load: $error');
            }
            _isInterstitialAdReady = false;
            _interstitialAd = null;
            
            Future.delayed(const Duration(seconds: 5), () {
              _loadInterstitialAd();
            });
          },
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error loading interstitial ad: $e');
      }
    }
  }
  
  void _startAutoAdTimer() {
    _autoAdTimer?.cancel();
    
    _autoAdTimer = Timer.periodic(const Duration(minutes: 8), (timer) {
      showAutoAd();
    });
  }
  
  Future<void> showAutoAd() async {
    if (_lastAdShownTime != null) {
      final timeSinceLastAd = DateTime.now().difference(_lastAdShownTime!);
      if (timeSinceLastAd.inMinutes < 5) {
        if (kDebugMode) {
          print('Ad shown recently, skipping...');
        }
        return;
      }
    }
    
    if (kIsWeb) {
      _showWebAutoAd();
      return;
    }
    
    if (_isInterstitialAdReady && _interstitialAd != null) {
      await _interstitialAd?.show();
      _lastAdShownTime = DateTime.now();
      _isInterstitialAdReady = false;
      _interstitialAd = null;
      await _loadInterstitialAd();
    } else {
      await _loadInterstitialAd();
    }
  }
  
  void _showWebAutoAd() {
    _lastAdShownTime = DateTime.now();
    
    if (kDebugMode) {
      print('Showing web ad simulation');
    }
  }
  
  void dispose() {
    _autoAdTimer?.cancel();
    _interstitialAd?.dispose();
  }
}
