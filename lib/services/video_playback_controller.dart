import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class VideoPlaybackController extends ChangeNotifier {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  String? _currentUrl;

  VideoPlayerController? get videoController => _videoController;
  ChewieController? get chewieController => _chewieController;
  bool get isInitialized => _isInitialized;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;

  Future<void> initializeVideo(String videoUrl, {bool autoPlay = true}) async {
    if (_currentUrl == videoUrl && _isInitialized) {
      return;
    }

    await cleanup();

    _currentUrl = videoUrl;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();

    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        httpHeaders: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
      );

      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: autoPlay,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        autoInitialize: true,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error loading video',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.red,
          handleColor: Colors.red,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.white70,
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.red,
            ),
          ),
        ),
      );

      _isInitialized = true;

      if (!kIsWeb) {
        WakelockPlus.enable();
      }

      notifyListeners();
    } catch (e) {
      _hasError = true;
      _errorMessage = e.toString();
      _isInitialized = false;
      notifyListeners();
    }
  }

  Future<void> switchVideo(String newUrl, {bool autoPlay = true}) async {
    await initializeVideo(newUrl, autoPlay: autoPlay);
  }

  void togglePlayPause() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
      notifyListeners();
    }
  }

  Future<void> cleanup() async {
    if (_chewieController != null) {
      await _chewieController!.pause();
      _chewieController!.dispose();
      _chewieController = null;
    }

    if (_videoController != null) {
      await _videoController!.pause();
      await _videoController!.dispose();
      _videoController = null;
    }

    if (!kIsWeb) {
      WakelockPlus.disable();
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }

    _isInitialized = false;
    _currentUrl = null;
  }

  @override
  void dispose() {
    cleanup();
    super.dispose();
  }
}
