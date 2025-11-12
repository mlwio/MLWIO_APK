import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../models/video.dart';
import '../utils/constants.dart';
import '../controllers/playlist_controller.dart';

class YouTubeStylePlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;
  final List<Episode>? playlist;
  final int? currentIndex;
  final String? thumbnailUrl;

  const YouTubeStylePlayerScreen({
    super.key,
    required this.videoUrl,
    required this.title,
    this.playlist,
    this.currentIndex,
    this.thumbnailUrl,
  });

  @override
  State<YouTubeStylePlayerScreen> createState() => _YouTubeStylePlayerScreenState();
}

class _YouTubeStylePlayerScreenState extends State<YouTubeStylePlayerScreen> {
  late PlaylistController _playlistController;
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  bool _showPlaylist = true;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _playlistController = PlaylistController();
    
    if (widget.playlist != null && widget.playlist!.isNotEmpty) {
      _playlistController.setPlaylist(
        widget.playlist!,
        startIndex: widget.currentIndex ?? 0,
      );
    }
  }

  @override
  void dispose() {
    _playlistController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  String _getDriveFileId(String driveLink) {
    final fileIdMatch = RegExp(r'/d/([a-zA-Z0-9_-]+)').firstMatch(driveLink);
    if (fileIdMatch != null) {
      return fileIdMatch.group(1)!;
    }
    
    final ucIdMatch = RegExp(r'[?&]id=([a-zA-Z0-9_-]+)').firstMatch(driveLink);
    if (ucIdMatch != null) {
      return ucIdMatch.group(1)!;
    }
    
    return '';
  }

  String _createCustomPlayerHtml(String fileId, {String? fallbackUrl}) {
    final iframeUrl = fileId.isNotEmpty 
        ? 'https://drive.google.com/file/d/$fileId/preview'
        : (fallbackUrl ?? '');
    
    if (iframeUrl.isEmpty) {
      return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      background: #000;
      display: flex;
      align-items: center;
      justify-content: center;
      height: 100vh;
      margin: 0;
      font-family: Arial, sans-serif;
    }
    .error {
      color: #ff5252;
      text-align: center;
      padding: 20px;
    }
  </style>
</head>
<body>
  <div class="error">
    <h3>Video URL Error</h3>
    <p>Unable to load video. Invalid URL format.</p>
  </div>
</body>
</html>
      ''';
    }
    
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    body {
      background: #000;
      overflow: hidden;
    }
    #player-container {
      width: 100vw;
      height: 100vh;
      position: relative;
    }
    iframe {
      width: 100%;
      height: 100%;
      border: none;
    }
    video {
      width: 100%;
      height: 100%;
      object-fit: contain;
    }
    .loading {
      position: absolute;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      color: white;
      font-family: Arial, sans-serif;
      font-size: 18px;
    }
  </style>
</head>
<body>
  <div id="player-container">
    <div class="loading">Loading video...</div>
    <iframe 
      src="$iframeUrl" 
      allow="autoplay; encrypted-media" 
      allowfullscreen>
    </iframe>
  </div>
  <script>
    window.addEventListener('message', function(event) {
      if (event.data === 'play') {
        var iframe = document.querySelector('iframe');
        if (iframe) {
          iframe.contentWindow.postMessage('{"event":"command","func":"playVideo","args":""}', '*');
        }
      }
    });
    
    document.querySelector('iframe').addEventListener('load', function() {
      document.querySelector('.loading').style.display = 'none';
    });
  </script>
</body>
</html>
    ''';
  }

  String get _currentVideoUrl {
    if (_playlistController.playlist.isNotEmpty) {
      return _playlistController.currentEpisode?.driveLink ?? widget.videoUrl;
    }
    return widget.videoUrl;
  }

  String get _currentTitle {
    if (_playlistController.playlist.isNotEmpty) {
      return _playlistController.currentEpisode?.title ?? widget.title;
    }
    return widget.title;
  }

  void _playNextEpisode() {
    if (_playlistController.hasNext) {
      setState(() {
        _isLoading = true;
        _playlistController.playNext();
      });
      _loadVideo();
    }
  }

  void _playPreviousEpisode() {
    if (_playlistController.hasPrevious) {
      setState(() {
        _isLoading = true;
        _playlistController.playPrevious();
      });
      _loadVideo();
    }
  }

  void _loadVideo() {
    final fileId = _getDriveFileId(_currentVideoUrl);
    final customHtml = _createCustomPlayerHtml(fileId, fallbackUrl: _currentVideoUrl);
    _webViewController?.loadData(data: customHtml, mimeType: 'text/html', encoding: 'utf-8');
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
    
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullscreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: _buildVideoPlayer(),
      );
    }

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildVideoPlayer(),
          if (_playlistController.playlist.isNotEmpty)
            _buildPlaylistToggle(),
          if (_showPlaylist && _playlistController.playlist.isNotEmpty)
            Expanded(child: _buildYouTubeStylePlaylist()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppConstants.backgroundColor,
      elevation: 0,
      title: Text(
        _currentTitle,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (_playlistController.playlist.isNotEmpty)
          IconButton(
            icon: Icon(
              _playlistController.autoPlayEnabled
                  ? Icons.playlist_play
                  : Icons.playlist_remove,
              color: _playlistController.autoPlayEnabled
                  ? AppConstants.accentColor
                  : Colors.white,
            ),
            onPressed: () {
              setState(() {
                _playlistController.toggleAutoPlay();
              });
            },
          ),
        IconButton(
          icon: Icon(
            _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
            color: Colors.white,
          ),
          onPressed: _toggleFullscreen,
        ),
      ],
    );
  }

  Widget _buildVideoPlayer() {
    final fileId = _getDriveFileId(_currentVideoUrl);
    final customHtml = _createCustomPlayerHtml(fileId, fallbackUrl: _currentVideoUrl);
    
    final stackContent = Stack(
      children: [
        InAppWebView(
          initialData: InAppWebViewInitialData(
            data: customHtml,
            mimeType: 'text/html',
            encoding: 'utf-8',
          ),
          initialSettings: InAppWebViewSettings(
            mediaPlaybackRequiresUserGesture: false,
            allowsInlineMediaPlayback: true,
            javaScriptEnabled: true,
            useHybridComposition: true,
            supportZoom: false,
            transparentBackground: false,
            disableContextMenu: true,
            allowFileAccessFromFileURLs: true,
            allowUniversalAccessFromFileURLs: true,
          ),
          onWebViewCreated: (controller) {
            _webViewController = controller;
          },
          onLoadStart: (controller, url) {
            setState(() {
              _isLoading = true;
            });
          },
          onLoadStop: (controller, url) async {
            setState(() {
              _isLoading = false;
            });
          },
          onReceivedError: (controller, request, error) {
            setState(() {
              _isLoading = false;
            });
            print('WebView Error: ${error.description}');
          },
          onConsoleMessage: (controller, consoleMessage) {
            print('Console: ${consoleMessage.message}');
          },
        ),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
        if (_playlistController.playlist.isNotEmpty && !_isFullscreen)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.skip_previous,
                      color: _playlistController.hasPrevious
                          ? Colors.white
                          : Colors.grey,
                    ),
                    onPressed: _playlistController.hasPrevious
                        ? _playPreviousEpisode
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Episode ${_playlistController.currentIndex + 1} of ${_playlistController.playlist.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: Icon(
                      Icons.skip_next,
                      color: _playlistController.hasNext
                          ? Colors.white
                          : Colors.grey,
                    ),
                    onPressed: _playlistController.hasNext
                        ? _playNextEpisode
                        : null,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
    
    if (_isFullscreen) {
      return Container(
        color: Colors.black,
        child: stackContent,
      );
    }
    
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Colors.black,
        child: stackContent,
      ),
    );
  }

  Widget _buildPlaylistToggle() {
    return Container(
      color: AppConstants.cardColor,
      child: InkWell(
        onTap: () {
          setState(() {
            _showPlaylist = !_showPlaylist;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.playlist_play,
                    color: AppConstants.accentColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Episodes (${_playlistController.currentIndex + 1}/${_playlistController.playlist.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Icon(
                _showPlaylist ? Icons.expand_less : Icons.expand_more,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYouTubeStylePlaylist() {
    return Container(
      color: AppConstants.backgroundColor,
      child: ListView.builder(
        itemCount: _playlistController.playlist.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          final episode = _playlistController.playlist[index];
          final isPlaying = index == _playlistController.currentIndex;

          return InkWell(
            onTap: () {
              setState(() {
                _playlistController.playEpisodeAt(index);
              });
              _loadVideo();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isPlaying
                    ? AppConstants.accentColor.withOpacity(0.1)
                    : AppConstants.cardColor,
                borderRadius: BorderRadius.circular(8),
                border: isPlaying
                    ? Border.all(color: AppConstants.accentColor, width: 2)
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Episode number or playing indicator
                  Container(
                    width: 48,
                    height: 72,
                    decoration: BoxDecoration(
                      color: isPlaying
                          ? AppConstants.accentColor
                          : Colors.grey[800],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: isPlaying
                          ? const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 32,
                            )
                          : Text(
                              '${episode.episodeNumber}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Episode info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          episode.title,
                          style: TextStyle(
                            color: isPlaying ? AppConstants.accentColor : Colors.white,
                            fontWeight: isPlaying ? FontWeight.bold : FontWeight.w600,
                            fontSize: 15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (episode.duration != null) ...[
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                episode.duration!,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (isPlaying)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.volume_up,
                                  size: 14,
                                  color: AppConstants.accentColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Now Playing',
                                  style: TextStyle(
                                    color: AppConstants.accentColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
