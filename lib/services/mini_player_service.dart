import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/video.dart';

class MiniPlayerService extends ChangeNotifier {
  static final MiniPlayerService _instance = MiniPlayerService._internal();
  factory MiniPlayerService() => _instance;
  MiniPlayerService._internal();

  bool _isMinimized = false;
  ContentItem? _currentContent;
  String? _currentVideoUrl;
  String? _currentTitle;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  int? _currentEpisodeIndex;
  int? _currentSeasonIndex;

  bool get isMinimized => _isMinimized;
  ContentItem? get currentContent => _currentContent;
  String? get currentVideoUrl => _currentVideoUrl;
  String? get currentTitle => _currentTitle;
  VideoPlayerController? get videoController => _videoController;
  ChewieController? get chewieController => _chewieController;
  int? get currentEpisodeIndex => _currentEpisodeIndex;
  int? get currentSeasonIndex => _currentSeasonIndex;

  void minimize({
    required ContentItem content,
    required String videoUrl,
    required String title,
    VideoPlayerController? videoController,
    ChewieController? chewieController,
    int? currentEpisodeIndex,
    int? currentSeasonIndex,
  }) {
    _isMinimized = true;
    _currentContent = content;
    _currentVideoUrl = videoUrl;
    _currentTitle = title;
    _videoController = videoController;
    _chewieController = chewieController;
    _currentEpisodeIndex = currentEpisodeIndex;
    _currentSeasonIndex = currentSeasonIndex;
    notifyListeners();
  }

  void maximize() {
    _isMinimized = false;
    notifyListeners();
  }

  void close() {
    _isMinimized = false;
    _videoController?.pause();
    _videoController?.dispose();
    _chewieController?.dispose();
    _videoController = null;
    _chewieController = null;
    _currentContent = null;
    _currentVideoUrl = null;
    _currentTitle = null;
    _currentEpisodeIndex = null;
    _currentSeasonIndex = null;
    notifyListeners();
  }

  void updateVideoController(VideoPlayerController? controller, ChewieController? chewieController) {
    _videoController = controller;
    _chewieController = chewieController;
    notifyListeners();
  }
}
