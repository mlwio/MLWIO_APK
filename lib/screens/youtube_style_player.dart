import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';
import '../models/video.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/mini_player_service.dart';
import '../utils/video_url_converter.dart';
import '../utils/constants.dart';
import '../widgets/video_settings_sheet.dart';

class YouTubeStylePlayer extends StatefulWidget {
  final ContentItem content;
  final int? initialSeasonIndex;
  final int? initialEpisodeIndex;

  const YouTubeStylePlayer({
    super.key,
    required this.content,
    this.initialSeasonIndex,
    this.initialEpisodeIndex,
  });

  @override
  State<YouTubeStylePlayer> createState() => _YouTubeStylePlayerState();
}

class _YouTubeStylePlayerState extends State<YouTubeStylePlayer>
    with SingleTickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();
  final MiniPlayerService _miniPlayerService = MiniPlayerService();

  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  bool _hasError = false;
  bool _showControls = true;
  bool _isFullscreen = false;
  bool _isDragging = false;
  double _dragOffset = 0;
  Timer? _controlsTimer;
  Timer? _positionTimer;

  bool? _isLiked;
  int _likeCount = 0;
  int _dislikeCount = 0;
  bool _isDownloaded = false;
  bool _isSaved = false;
  bool _autoPlay = true;
  bool _isLocked = false;

  bool _isDescriptionExpanded = false;
  bool _showPlaylist = true;

  final TextEditingController _commentController = TextEditingController();
  List<CommentItem> _comments = [];
  bool _isLoadingComments = true;

  List<ContentItem> _relatedContent = [];
  bool _isLoadingRelated = true;

  int _currentSeasonIndex = 0;
  int _currentEpisodeIndex = 0;

  String _currentVideoUrl = '';
  String _currentTitle = '';
  String _currentDescription = '';

  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _playbackSpeed = 1.0;
  String _currentQuality = 'Auto (1080p)';
  String _currentAudioTrack = 'Original';
  String _currentSubtitle = 'Off';
  bool _isPlaying = false;
  bool _isBuffering = false;

  @override
  void initState() {
    super.initState();
    _currentSeasonIndex = widget.initialSeasonIndex ?? 0;
    _currentEpisodeIndex = widget.initialEpisodeIndex ?? 0;

    _initializeData();
    _startControlsTimer();
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    if (_isPlaying && _showControls && !_isDragging) {
      _controlsTimer = Timer(const Duration(seconds: 4), () {
        if (mounted && _isPlaying && !_isDragging) {
          setState(() => _showControls = false);
        }
      });
    }
  }

  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _syncPlayerState();
    });
  }

  Future<void> _syncPlayerState() async {
    if (_webViewController == null) return;
    
    try {
      final result = await _webViewController!.evaluateJavascript(source: '''
        (function() {
          var video = document.querySelector('video');
          if (video) {
            return JSON.stringify({
              currentTime: video.currentTime || 0,
              duration: video.duration || 0,
              paused: video.paused,
              playbackRate: video.playbackRate || 1
            });
          }
          return null;
        })();
      ''');
      
      if (result != null && result != 'null' && mounted) {
        try {
          final data = result.toString().replaceAll('"', '').replaceAll("'", "");
          if (data.contains('currentTime')) {
            final jsonStr = result.toString();
            if (jsonStr.contains('{')) {
              final parts = jsonStr.replaceAll('{', '').replaceAll('}', '').replaceAll('"', '').split(',');
              double currentTime = 0;
              double duration = 0;
              bool paused = true;
              double playbackRate = 1;
              
              for (var part in parts) {
                final kv = part.split(':');
                if (kv.length == 2) {
                  final key = kv[0].trim();
                  final value = kv[1].trim();
                  if (key == 'currentTime') currentTime = double.tryParse(value) ?? 0;
                  if (key == 'duration') duration = double.tryParse(value) ?? 0;
                  if (key == 'paused') paused = value == 'true';
                  if (key == 'playbackRate') playbackRate = double.tryParse(value) ?? 1;
                }
              }
              
              if (duration > 0) {
                setState(() {
                  _currentPosition = Duration(seconds: currentTime.toInt());
                  _totalDuration = Duration(seconds: duration.toInt());
                  _isPlaying = !paused;
                  _playbackSpeed = playbackRate;
                  _isBuffering = false;
                });
              }
            }
          }
        } catch (e) {
          debugPrint('Error parsing player state: $e');
        }
      }
    } catch (e) {
      debugPrint('Error syncing player state: $e');
    }
  }

  Future<void> _initializeData() async {
    _updateCurrentVideoInfo();
    await Future.wait([
      _loadLikeStatus(),
      _loadDownloadStatus(),
      _loadSavedStatus(),
      _loadComments(),
      _loadRelatedContent(),
      _saveToWatchHistory(),
    ]);
  }

  void _updateCurrentVideoInfo() {
    if (widget.content is SeriesContent) {
      final series = widget.content as SeriesContent;
      if (series.seasons.isNotEmpty &&
          _currentSeasonIndex < series.seasons.length &&
          series.seasons[_currentSeasonIndex].episodes.isNotEmpty &&
          _currentEpisodeIndex <
              series.seasons[_currentSeasonIndex].episodes.length) {
        final episode =
            series.seasons[_currentSeasonIndex].episodes[_currentEpisodeIndex];
        _currentVideoUrl = VideoUrlConverter.getVideoUrl(episode.playbackUrl, episode.driveLink);
        _currentTitle = '${series.title} - ${episode.title}';
        _currentDescription =
            episode.description ?? series.description ?? 'No description available';
      }
    } else {
      _currentVideoUrl = VideoUrlConverter.getVideoUrl(widget.content.playbackUrl, widget.content.driveLink);
      _currentTitle = widget.content.title;
      _currentDescription =
          widget.content.description ?? 'No description available';
    }
  }

  void _toggleControls() {
    if (_isLocked) {
      setState(() => _isLocked = false);
      return;
    }
    setState(() => _showControls = !_showControls);
    _startControlsTimer();
  }

  Future<void> _loadLikeStatus() async {
    final status = await _dbService.getLikeStatus(widget.content.id);
    if (mounted) {
      setState(() {
        _isLiked = status;
        _likeCount = status == true ? 1 : 0;
        _dislikeCount = status == false ? 1 : 0;
      });
    }
  }

  Future<void> _loadDownloadStatus() async {
    final isDownloaded = await _dbService.isDownloaded(widget.content.id);
    if (mounted) {
      setState(() => _isDownloaded = isDownloaded);
    }
  }

  Future<void> _loadSavedStatus() async {
    final isSaved = await _dbService.isSaved(widget.content.id);
    if (mounted) {
      setState(() => _isSaved = isSaved);
    }
  }

  Future<void> _loadComments() async {
    setState(() => _isLoadingComments = true);
    final comments = await _dbService.getComments(widget.content.id);
    if (mounted) {
      setState(() {
        _comments = comments;
        _isLoadingComments = false;
      });
    }
  }

  Future<void> _loadRelatedContent() async {
    setState(() => _isLoadingRelated = true);
    try {
      final content = await ApiService.getContent();
      if (mounted) {
        setState(() {
          _relatedContent =
              content.where((c) => c.id != widget.content.id).take(10).toList();
          _isLoadingRelated = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRelated = false);
      }
    }
  }

  Future<void> _saveToWatchHistory() async {
    try {
      final userEmail = _authService.currentUser?.email;
      await _dbService.saveToWatchHistory(widget.content, userEmail: userEmail);
    } catch (e) {
      debugPrint('Error saving to watch history: $e');
    }
  }

  void _toggleLike() async {
    bool? newStatus = _isLiked == true ? null : true;
    await _dbService.setLikeStatus(widget.content.id, newStatus);
    setState(() {
      _isLiked = newStatus;
      _likeCount = newStatus == true ? 1 : 0;
      _dislikeCount = newStatus == false ? 1 : 0;
    });
  }

  void _toggleDislike() async {
    bool? newStatus = _isLiked == false ? null : false;
    await _dbService.setLikeStatus(widget.content.id, newStatus);
    setState(() {
      _isLiked = newStatus;
      _likeCount = newStatus == true ? 1 : 0;
      _dislikeCount = newStatus == false ? 1 : 0;
    });
  }

  void _shareVideo() async {
    await Share.share(
      'Check out "${widget.content.title}" on MLWIO!',
      subject: widget.content.title,
    );
  }

  void _downloadVideo() async {
    if (_isDownloaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Already downloaded'), backgroundColor: Colors.orange),
      );
      return;
    }

    String type = 'Movie';
    if (widget.content.type == ContentType.anime) {
      type = 'Anime';
    } else if (widget.content.type == ContentType.webSeries) {
      type = 'Series';
    }

    await _dbService.addDownload(
      videoId: widget.content.id,
      title: widget.content.title,
      thumbnailUrl: widget.content.thumbnail,
      videoUrl: widget.content.driveLink ?? '',
      type: type,
      filePath: 'local_storage/${widget.content.id}',
      fileSize: 0,
    );

    setState(() => _isDownloaded = true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to downloads'), backgroundColor: Colors.green),
      );
    }
  }

  void _toggleSave() async {
    if (_isSaved) {
      await _dbService.removeFromPlaylist(widget.content.id);
      setState(() => _isSaved = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from Watch Later'), backgroundColor: Colors.orange),
        );
      }
    } else {
      await _dbService.saveToPlaylist(widget.content);
      setState(() => _isSaved = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to Watch Later'), backgroundColor: Colors.green),
        );
      }
    }
  }

  void _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to comment'), backgroundColor: Colors.red),
      );
      return;
    }

    await _dbService.addComment(
      videoId: widget.content.id,
      text: text,
      userName: user.displayName ?? user.email ?? 'Anonymous',
      userAvatar: user.photoURL,
    );

    _commentController.clear();
    await _loadComments();
  }

  void _playEpisode(int seasonIndex, int episodeIndex) {
    setState(() {
      _currentSeasonIndex = seasonIndex;
      _currentEpisodeIndex = episodeIndex;
      _isLoading = true;
      _hasError = false;
      _currentPosition = Duration.zero;
    });
    _updateCurrentVideoInfo();
    _webViewController?.loadUrl(
      urlRequest: URLRequest(url: WebUri(_getVideoEmbedUrl())),
    );
    _saveToWatchHistory();
  }

  void _playNextEpisode() {
    if (widget.content is! SeriesContent) return;
    final series = widget.content as SeriesContent;

    if (_currentEpisodeIndex < series.seasons[_currentSeasonIndex].episodes.length - 1) {
      _playEpisode(_currentSeasonIndex, _currentEpisodeIndex + 1);
    } else if (_currentSeasonIndex < series.seasons.length - 1) {
      _playEpisode(_currentSeasonIndex + 1, 0);
    }
  }

  void _playPreviousEpisode() {
    if (widget.content is! SeriesContent) return;

    if (_currentEpisodeIndex > 0) {
      _playEpisode(_currentSeasonIndex, _currentEpisodeIndex - 1);
    } else if (_currentSeasonIndex > 0) {
      final series = widget.content as SeriesContent;
      final prevSeasonEpisodes = series.seasons[_currentSeasonIndex - 1].episodes.length;
      _playEpisode(_currentSeasonIndex - 1, prevSeasonEpisodes - 1);
    }
  }

  String _getVideoEmbedUrl() {
    return VideoUrlConverter.getPreviewUrl(_currentVideoUrl);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatTimeAgo(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7}w ago';
    if (diff.inDays < 365) return '${diff.inDays ~/ 30}mo ago';
    return '${diff.inDays ~/ 365}y ago';
  }

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);

    if (!kIsWeb) {
      if (_isFullscreen) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    }
  }

  void _togglePlayPause() {
    _webViewController?.evaluateJavascript(source: '''
      (function() {
        var video = document.querySelector('video');
        if (video) {
          if (video.paused) {
            video.play();
          } else {
            video.pause();
          }
        }
      })();
    ''');
    setState(() => _isPlaying = !_isPlaying);
    _startControlsTimer();
  }

  void _seekTo(double seconds) {
    _webViewController?.evaluateJavascript(source: '''
      (function() {
        var video = document.querySelector('video');
        if (video) {
          video.currentTime = $seconds;
        }
      })();
    ''');
    setState(() => _currentPosition = Duration(seconds: seconds.toInt()));
  }

  void _setPlaybackSpeed(double speed) {
    _webViewController?.evaluateJavascript(source: '''
      (function() {
        var video = document.querySelector('video');
        if (video) {
          video.playbackRate = $speed;
        }
      })();
    ''');
    setState(() => _playbackSpeed = speed);
  }

  void _showSettingsSheet() {
    if (_isFullscreen) {
      _showFullscreenSettingsDialog();
    } else {
      _showBottomSettingsSheet();
    }
  }

  void _showBottomSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => VideoSettingsSheet(
        currentQuality: _currentQuality,
        currentSpeed: _playbackSpeed,
        currentSubtitle: _currentSubtitle,
        currentAudioTrack: _currentAudioTrack,
        isLocked: _isLocked,
        onQualityChanged: (quality) {
          setState(() => _currentQuality = quality);
          Navigator.pop(context);
        },
        onSpeedChanged: (speed) {
          _setPlaybackSpeed(speed);
          Navigator.pop(context);
        },
        onSubtitleChanged: (subtitle) {
          setState(() => _currentSubtitle = subtitle);
          Navigator.pop(context);
        },
        onAudioTrackChanged: (track) {
          setState(() => _currentAudioTrack = track);
          Navigator.pop(context);
        },
        onLockScreen: () {
          Navigator.pop(context);
          setState(() {
            _isLocked = true;
            _showControls = false;
          });
        },
      ),
    );
  }

  void _showFullscreenSettingsDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Center(
        child: VideoSettingsSheet(
          currentQuality: _currentQuality,
          currentSpeed: _playbackSpeed,
          currentSubtitle: _currentSubtitle,
          currentAudioTrack: _currentAudioTrack,
          isLocked: _isLocked,
          isDialog: true,
          onQualityChanged: (quality) {
            setState(() => _currentQuality = quality);
            Navigator.pop(context);
          },
          onSpeedChanged: (speed) {
            _setPlaybackSpeed(speed);
            Navigator.pop(context);
          },
          onSubtitleChanged: (subtitle) {
            setState(() => _currentSubtitle = subtitle);
            Navigator.pop(context);
          },
          onAudioTrackChanged: (track) {
            setState(() => _currentAudioTrack = track);
            Navigator.pop(context);
          },
          onLockScreen: () {
            Navigator.pop(context);
            setState(() {
              _isLocked = true;
              _showControls = false;
            });
          },
        ),
      ),
    );
  }

  void _handleVerticalDrag(DragUpdateDetails details) {
    if (_isLocked || _isFullscreen) return;
    setState(() {
      _isDragging = true;
      _dragOffset += details.delta.dy;
    });
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    if (_isLocked || _isFullscreen) return;

    if (_dragOffset > 100 || details.velocity.pixelsPerSecond.dy > 500) {
      _minimizeToMiniPlayer();
    }
    setState(() {
      _isDragging = false;
      _dragOffset = 0;
    });
  }

  void _minimizeToMiniPlayer() {
    _miniPlayerService.minimize(
      content: widget.content,
      videoUrl: _currentVideoUrl,
      title: _currentTitle,
      currentEpisodeIndex: _currentEpisodeIndex,
      currentSeasonIndex: _currentSeasonIndex,
    );
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _controlsTimer?.cancel();
    _positionTimer?.cancel();
    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullscreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: _buildVideoPlayerWithControls(fullscreen: true),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 900;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: isWideScreen ? _buildWideLayout() : _buildNarrowLayout(),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildVideoPlayerWithControls(),
                _buildMetadataSection(),
                _buildCommentsSection(),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            color: const Color(0xFF0F0F0F),
            child: _buildRelatedAndPlaylistSection(),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildVideoPlayerWithControls(),
          _buildMetadataSection(),
          _buildActionButtons(),
          if (widget.content is SeriesContent) _buildPlaylistSection(),
          _buildCommentsSection(),
          _buildRelatedVideosSection(),
        ],
      ),
    );
  }

  Widget _buildVideoPlayerWithControls({bool fullscreen = false}) {
    final embedUrl = _getVideoEmbedUrl();
    final playerHeight = fullscreen
        ? MediaQuery.of(context).size.height
        : MediaQuery.of(context).size.width * 9 / 16;

    return GestureDetector(
      onTap: _toggleControls,
      onVerticalDragUpdate: fullscreen ? null : _handleVerticalDrag,
      onVerticalDragEnd: fullscreen ? null : _handleVerticalDragEnd,
      child: Transform.translate(
        offset: Offset(0, _isDragging ? _dragOffset.clamp(0, 200) : 0),
        child: Opacity(
          opacity: _isDragging ? (1 - (_dragOffset / 400).clamp(0, 0.5)) : 1,
          child: SizedBox(
            width: double.infinity,
            height: playerHeight,
            child: Stack(
              children: [
                InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(embedUrl)),
                  initialSettings: InAppWebViewSettings(
                    mediaPlaybackRequiresUserGesture: false,
                    allowsInlineMediaPlayback: true,
                    javaScriptEnabled: true,
                    useWideViewPort: true,
                    supportMultipleWindows: false,
                    javaScriptCanOpenWindowsAutomatically: false,
                  ),
                  onWebViewCreated: (controller) {
                    _webViewController = controller;
                  },
                  onLoadStart: (controller, url) {
                    setState(() {
                      _isLoading = true;
                      _hasError = false;
                    });
                  },
                  onLoadStop: (controller, url) async {
                    setState(() => _isLoading = false);
                    
                    await controller.evaluateJavascript(source: '''
                      (function() {
                        var style = document.createElement('style');
                        style.innerHTML = \`
                          .ndfHFb-c4YZDc-Wrber-fmcmS,
                          .ndfHFb-c4YZDc-Wrber,
                          [aria-label="Open in new window"],
                          [aria-label="Pop-out"],
                          .ndfHFb-c4YZDc-GSQQnc-LgbsSe,
                          .ndfHFb-c4YZDc-to915-LgbsSe {
                            display: none !important;
                            visibility: hidden !important;
                            pointer-events: none !important;
                          }
                        \`;
                        document.head.appendChild(style);
                        
                        var video = document.querySelector('video');
                        if (video) {
                          video.play();
                        }
                        
                        setInterval(function() {
                          var elements = document.querySelectorAll('[aria-label="Open in new window"], [aria-label="Pop-out"]');
                          elements.forEach(function(el) { el.remove(); });
                        }, 500);
                      })();
                    ''');
                    
                    _startPositionTimer();
                  },
                  onReceivedError: (controller, request, error) {
                    setState(() {
                      _isLoading = false;
                      _hasError = true;
                    });
                  },
                  shouldOverrideUrlLoading: (controller, navigationAction) async {
                    return NavigationActionPolicy.CANCEL;
                  },
                ),

                if (_isLoading)
                  Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.red),
                    ),
                  ),

                if (_hasError)
                  Container(
                    color: Colors.black,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 60),
                          const SizedBox(height: 16),
                          const Text('Failed to load video',
                              style: TextStyle(color: Colors.white, fontSize: 18)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isLoading = true;
                                _hasError = false;
                              });
                              _webViewController?.reload();
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('Retry', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (_isLocked)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => setState(() => _isLocked = false),
                      child: Container(
                        color: Colors.transparent,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock, color: Colors.white, size: 40),
                                SizedBox(height: 8),
                                Text('Tap to unlock',
                                    style: TextStyle(color: Colors.white, fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                if (_showControls && !_isLocked)
                  _buildPlayerControls(fullscreen: fullscreen),
                  
                if (_isBuffering && !_isLoading)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerControls({bool fullscreen = false}) {
    return AnimatedOpacity(
      opacity: _showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
            stops: const [0.0, 0.25, 0.75, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: fullscreen ? MediaQuery.of(context).padding.top + 8 : 8,
              left: 0,
              right: 0,
              child: _buildTopControls(fullscreen: fullscreen),
            ),
            Center(child: _buildCenterControls()),
            Positioned(
              bottom: fullscreen ? MediaQuery.of(context).padding.bottom + 8 : 8,
              left: 0,
              right: 0,
              child: _buildBottomControls(fullscreen: fullscreen),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopControls({bool fullscreen = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
            onPressed: fullscreen ? _toggleFullscreen : _minimizeToMiniPlayer,
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: _autoPlay,
                        onChanged: (value) => setState(() => _autoPlay = value),
                        activeColor: Colors.white,
                        activeTrackColor: Colors.blue,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentSubtitle = _currentSubtitle == 'Off' ? 'Auto' : 'Off';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _currentSubtitle != 'Off' ? Colors.white : Colors.grey,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'CC',
                    style: TextStyle(
                      color: _currentSubtitle != 'Off' ? Colors.white : Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white, size: 24),
                onPressed: _showSettingsSheet,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCenterControls() {
    final hasPrevious = widget.content is SeriesContent &&
        (_currentEpisodeIndex > 0 || _currentSeasonIndex > 0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (hasPrevious)
          IconButton(
            icon: const Icon(Icons.skip_previous, color: Colors.white70, size: 36),
            onPressed: _playPreviousEpisode,
          )
        else
          const SizedBox(width: 48),
        const SizedBox(width: 24),
        Container(
          decoration: BoxDecoration(
            color: Colors.black26,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 56,
            ),
            onPressed: _togglePlayPause,
          ),
        ),
        const SizedBox(width: 24),
        if (widget.content is SeriesContent)
          IconButton(
            icon: const Icon(Icons.skip_next, color: Colors.white70, size: 36),
            onPressed: _playNextEpisode,
          )
        else
          const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildBottomControls({bool fullscreen = false}) {
    final double maxSeconds = _totalDuration.inSeconds > 0 ? _totalDuration.inSeconds.toDouble() : 1.0;
    final double currentSeconds = _currentPosition.inSeconds.toDouble().clamp(0.0, maxSeconds);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                _formatDuration(_currentPosition),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: Colors.red,
                    inactiveTrackColor: Colors.grey[700],
                    thumbColor: Colors.red,
                  ),
                  child: Slider(
                    value: currentSeconds,
                    max: maxSeconds,
                    onChanged: (value) {
                      setState(() {
                        _currentPosition = Duration(seconds: value.toInt());
                      });
                    },
                    onChangeEnd: (value) => _seekTo(value),
                  ),
                ),
              ),
              Text(
                _formatDuration(_totalDuration),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  fullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: _toggleFullscreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF0F0F0F),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _currentTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${_likeCount + _dislikeCount} views',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              const SizedBox(width: 8),
              Text('•', style: TextStyle(color: Colors.grey[400])),
              const SizedBox(width: 8),
              Text(
                widget.content.releaseYear?.toString() ?? 'Recently added',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: const Color(0xFF0F0F0F),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            _buildActionButton(
              icon: Icons.thumb_up,
              label: _likeCount.toString(),
              isActive: _isLiked == true,
              onTap: _toggleLike,
            ),
            _buildActionButton(
              icon: Icons.thumb_down,
              label: _dislikeCount.toString(),
              isActive: _isLiked == false,
              onTap: _toggleDislike,
            ),
            _buildActionButton(icon: Icons.share, label: 'Share', onTap: _shareVideo),
            _buildActionButton(
              icon: _isDownloaded ? Icons.download_done : Icons.download,
              label: _isDownloaded ? 'Downloaded' : 'Download',
              isActive: _isDownloaded,
              onTap: _downloadVideo,
            ),
            _buildActionButton(
              icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
              label: _isSaved ? 'Saved' : 'Save',
              isActive: _isSaved,
              onTap: _toggleSave,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(icon, color: isActive ? Colors.blue : Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.blue : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    final cleanDescription = _currentDescription
        .replaceAll('\n\n', '\n')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
        
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF272727),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cleanDescription.isEmpty ? 'No description available' : cleanDescription,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                maxLines: _isDescriptionExpanded ? null : 2,
                overflow: _isDescriptionExpanded ? null : TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (cleanDescription.isNotEmpty)
                Text(
                  _isDescriptionExpanded ? 'Show less' : 'Show more',
                  style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistSection() {
    if (widget.content is! SeriesContent) return const SizedBox.shrink();
    final series = widget.content as SeriesContent;

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF272727),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _showPlaylist = !_showPlaylist),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Playlist (${series.totalEpisodes} episodes)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    _showPlaylist ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          if (_showPlaylist) ...[
            const Divider(color: Colors.grey, height: 1),
            if (series.seasons.length > 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButton<int>(
                  value: _currentSeasonIndex,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF272727),
                  style: const TextStyle(color: Colors.white),
                  underline: Container(),
                  items: series.seasons.asMap().entries.map((entry) {
                    return DropdownMenuItem<int>(
                      value: entry.key,
                      child: Text('Season ${entry.value.seasonNumber}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _currentSeasonIndex = value);
                  },
                ),
              ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: series.seasons[_currentSeasonIndex].episodes.length,
              itemBuilder: (context, index) {
                final episode = series.seasons[_currentSeasonIndex].episodes[index];
                final isPlaying = index == _currentEpisodeIndex;

                return InkWell(
                  onTap: () => _playEpisode(_currentSeasonIndex, index),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    color: isPlaying ? Colors.blue.withOpacity(0.2) : Colors.transparent,
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 120,
                            height: 68,
                            child: episode.thumbnail.isNotEmpty
                                ? Image.network(
                                    episode.thumbnail,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Container(
                                      color: Colors.grey[800],
                                      child: const Icon(Icons.movie, color: Colors.white54),
                                    ),
                                  )
                                : Container(
                                    color: Colors.grey[800],
                                    child: const Icon(Icons.movie, color: Colors.white54),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                episode.title,
                                style: TextStyle(
                                  color: isPlaying ? Colors.blue : Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (episode.duration != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    episode.duration!,
                                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (isPlaying)
                          const Icon(Icons.play_arrow, color: Colors.blue, size: 24),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comments ${_comments.isNotEmpty ? "(${_comments.length})" : ""}',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF272727),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[700],
                  backgroundImage: _authService.currentUser?.photoURL != null
                      ? NetworkImage(_authService.currentUser!.photoURL!)
                      : null,
                  child: _authService.currentUser?.photoURL == null
                      ? const Icon(Icons.person, color: Colors.white, size: 20)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _postComment,
                ),
              ],
            ),
          ),
          if (_isLoadingComments)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            )
          else if (_comments.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text('No comments yet. Be the first!', style: TextStyle(color: Colors.grey[400])),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _comments.length,
              itemBuilder: (context, index) => _buildCommentItem(_comments[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(CommentItem comment) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[700],
            backgroundImage:
                comment.userAvatar != null ? NetworkImage(comment.userAvatar!) : null,
            child: comment.userAvatar == null
                ? Text(
                    comment.userName.isNotEmpty ? comment.userName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTimeAgo(comment.timestamp),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.text, style: const TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.thumb_up_outlined, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(comment.likes.toString(),
                        style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    const SizedBox(width: 16),
                    Icon(Icons.thumb_down_outlined, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 16),
                    Text('Reply', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedVideosSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Related Videos',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_isLoadingRelated)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else if (_relatedContent.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('No related videos', style: TextStyle(color: Colors.grey[400])),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _relatedContent.length,
              itemBuilder: (context, index) => _buildRelatedVideoItem(_relatedContent[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildRelatedVideoItem(ContentItem item) {
    return InkWell(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => YouTubeStylePlayer(content: item)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 160,
                height: 90,
                child: Image.network(
                  item.thumbnail,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    color: Colors.grey[800],
                    child: const Icon(Icons.movie, color: Colors.white54),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text('MLWIO', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  if (item.releaseYear != null)
                    Text(item.releaseYear.toString(),
                        style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedAndPlaylistSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.content is SeriesContent) ...[
            const Text('Playlist',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildCompactPlaylist(),
            const SizedBox(height: 24),
          ],
          const Text('Related',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildCompactRelatedList(),
        ],
      ),
    );
  }

  Widget _buildCompactPlaylist() {
    if (widget.content is! SeriesContent) return const SizedBox.shrink();
    final series = widget.content as SeriesContent;

    return Column(
      children: [
        if (series.seasons.length > 1)
          DropdownButton<int>(
            value: _currentSeasonIndex,
            isExpanded: true,
            dropdownColor: const Color(0xFF272727),
            style: const TextStyle(color: Colors.white, fontSize: 12),
            underline: Container(),
            items: series.seasons.asMap().entries.map((entry) {
              return DropdownMenuItem<int>(
                value: entry.key,
                child: Text('Season ${entry.value.seasonNumber}'),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) setState(() => _currentSeasonIndex = value);
            },
          ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: series.seasons[_currentSeasonIndex].episodes.length,
          itemBuilder: (context, index) {
            final episode = series.seasons[_currentSeasonIndex].episodes[index];
            final isPlaying = index == _currentEpisodeIndex;

            return InkWell(
              onTap: () => _playEpisode(_currentSeasonIndex, index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 45,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.grey[800],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: episode.thumbnail.isNotEmpty
                            ? Image.network(
                                episode.thumbnail,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => const Center(
                                    child: Icon(Icons.movie, size: 16, color: Colors.white54)),
                              )
                            : const Center(
                                child: Icon(Icons.movie, size: 16, color: Colors.white54)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        episode.title,
                        style: TextStyle(
                          color: isPlaying ? Colors.blue : Colors.white,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isPlaying)
                      const Icon(Icons.play_arrow, color: Colors.blue, size: 16),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCompactRelatedList() {
    if (_isLoadingRelated) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _relatedContent.length,
      itemBuilder: (context, index) {
        final item = _relatedContent[index];
        return InkWell(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => YouTubeStylePlayer(content: item)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    width: 80,
                    height: 45,
                    child: Image.network(
                      item.thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.movie, size: 16, color: Colors.white54),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      Text('MLWIO', style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
