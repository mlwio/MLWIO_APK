import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../models/video.dart';
import '../screens/youtube_style_player.dart';
import '../utils/video_url_converter.dart';

class MiniPlayerOverlay {
  static OverlayEntry? _overlayEntry;
  static ContentItem? _currentContent;
  static String? _currentVideoUrl;
  static String? _currentTitle;
  static int? _currentSeasonIndex;
  static int? _currentEpisodeIndex;

  static bool get isActive => _overlayEntry != null;

  static void show(
    BuildContext context, {
    required ContentItem content,
    required String videoUrl,
    required String title,
    int? seasonIndex,
    int? episodeIndex,
  }) {
    dismiss();

    _currentContent = content;
    _currentVideoUrl = videoUrl;
    _currentTitle = title;
    _currentSeasonIndex = seasonIndex;
    _currentEpisodeIndex = episodeIndex;

    _overlayEntry = OverlayEntry(
      builder: (context) => _MiniPlayerWidget(
        content: content,
        videoUrl: videoUrl,
        title: title,
        seasonIndex: seasonIndex,
        episodeIndex: episodeIndex,
        onExpand: () {
          dismiss();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => YouTubeStylePlayer(
                content: content,
                initialSeasonIndex: seasonIndex,
                initialEpisodeIndex: episodeIndex,
              ),
            ),
          );
        },
        onDismiss: dismiss,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static void dismiss() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _currentContent = null;
    _currentVideoUrl = null;
    _currentTitle = null;
    _currentSeasonIndex = null;
    _currentEpisodeIndex = null;
  }
}

class _MiniPlayerWidget extends StatefulWidget {
  final ContentItem content;
  final String videoUrl;
  final String title;
  final int? seasonIndex;
  final int? episodeIndex;
  final VoidCallback onExpand;
  final VoidCallback onDismiss;

  const _MiniPlayerWidget({
    required this.content,
    required this.videoUrl,
    required this.title,
    this.seasonIndex,
    this.episodeIndex,
    required this.onExpand,
    required this.onDismiss,
  });

  @override
  State<_MiniPlayerWidget> createState() => _MiniPlayerWidgetState();
}

class _MiniPlayerWidgetState extends State<_MiniPlayerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  double _dragOffset = 0;
  bool _isDragging = false;
  bool _showControls = false;
  bool _isPlaying = true;

  InAppWebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _isDragging = true;
      _dragOffset += details.delta.dy;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dragOffset > 50 || details.velocity.pixelsPerSecond.dy > 300) {
      _animController.reverse().then((_) {
        widget.onDismiss();
      });
    } else {
      setState(() {
        _isDragging = false;
        _dragOffset = 0;
      });
    }
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    _webViewController?.evaluateJavascript(source: '''
      var video = document.querySelector('video');
      if (video) {
        if (video.paused) {
          video.play();
        } else {
          video.pause();
        }
      }
    ''');
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final playerWidth = screenSize.width * 0.45;
    final playerHeight = playerWidth * 9 / 16;

    return Positioned(
      right: 12,
      bottom: bottomPadding + 80 - (_isDragging ? _dragOffset.clamp(0, 100) : 0),
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Opacity(
            opacity: _isDragging ? (1 - (_dragOffset / 200).clamp(0, 0.5)) : 1,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showControls = !_showControls;
                });
                if (_showControls) {
                  Future.delayed(const Duration(seconds: 3), () {
                    if (mounted) {
                      setState(() {
                        _showControls = false;
                      });
                    }
                  });
                }
              },
              onVerticalDragUpdate: _handleDragUpdate,
              onVerticalDragEnd: _handleDragEnd,
              child: Container(
                width: playerWidth,
                height: playerHeight,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      InAppWebView(
                        initialUrlRequest: URLRequest(
                          url: WebUri(VideoUrlConverter.getPreviewUrl(widget.videoUrl)),
                        ),
                        initialSettings: InAppWebViewSettings(
                          mediaPlaybackRequiresUserGesture: false,
                          allowsInlineMediaPlayback: true,
                          javaScriptEnabled: true,
                          supportMultipleWindows: false,
                        ),
                        onWebViewCreated: (controller) {
                          _webViewController = controller;
                        },
                        onLoadStop: (controller, url) async {
                          await controller.evaluateJavascript(source: '''
                            var style = document.createElement('style');
                            style.innerHTML = \`
                              .ndfHFb-c4YZDc-Wrber-fmcmS,
                              .ndfHFb-c4YZDc-Wrber,
                              [aria-label="Open in new window"],
                              [aria-label="Pop-out"] {
                                display: none !important;
                              }
                            \`;
                            document.head.appendChild(style);
                            var video = document.querySelector('video');
                            if (video) video.play();
                          ''');
                        },
                        shouldOverrideUrlLoading: (controller, action) async {
                          return NavigationActionPolicy.CANCEL;
                        },
                      ),

                      if (_showControls)
                        Container(
                          color: Colors.black.withOpacity(0.5),
                          child: Stack(
                            children: [
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        _isPlaying ? Icons.pause : Icons.play_arrow,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                      onPressed: _togglePlayPause,
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 4,
                                left: 4,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.fullscreen,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: widget.onExpand,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 28,
                                    minHeight: 28,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: widget.onDismiss,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 28,
                                    minHeight: 28,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.8),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
