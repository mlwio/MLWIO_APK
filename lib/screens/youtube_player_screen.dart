import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import '../models/video.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/video_playback_controller.dart';
import '../utils/video_url_converter.dart';

class YouTubePlayerScreen extends StatefulWidget {
  final ContentItem content;
  final int? initialEpisodeIndex;
  final int? initialSeasonIndex;

  const YouTubePlayerScreen({
    super.key,
    required this.content,
    this.initialEpisodeIndex,
    this.initialSeasonIndex,
  });

  @override
  State<YouTubePlayerScreen> createState() => _YouTubePlayerScreenState();
}

class _YouTubePlayerScreenState extends State<YouTubePlayerScreen> {
  final VideoPlaybackController _playbackController = VideoPlaybackController();
  bool _isLoading = true;
  List<ContentItem> _suggestedVideos = [];
  final List<Comment> _comments = [];
  final TextEditingController _commentController = TextEditingController();
  bool _isLiked = false;
  bool _isDisliked = false;
  int _likeCount = 0;
  int _dislikeCount = 0;
  bool _isPlaylistVisible = true;
  
  int? _currentEpisodeIndex;
  int? _currentSeasonIndex;

  @override
  void initState() {
    super.initState();
    _currentEpisodeIndex = widget.initialEpisodeIndex ?? 0;
    _currentSeasonIndex = widget.initialSeasonIndex ?? 0;
    _loadSuggestedVideos();
    _likeCount = (widget.content.id.hashCode % 1000).abs();
    _dislikeCount = (widget.content.id.hashCode % 100).abs();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    final videoUrl = _getVideoUrl();
    if (videoUrl.isNotEmpty) {
      await _playbackController.initializeVideo(videoUrl);
    }
  }

  @override
  void dispose() {
    _playbackController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  String _getVideoUrl() {
    String url = '';
    if (widget.content is MovieContent) {
      url = (widget.content as MovieContent).driveLink;
    } else if (widget.content is SeriesContent) {
      final series = widget.content as SeriesContent;
      if (series.seasons.isNotEmpty && 
          _currentSeasonIndex! < series.seasons.length &&
          series.seasons[_currentSeasonIndex!].episodes.isNotEmpty &&
          _currentEpisodeIndex! < series.seasons[_currentSeasonIndex!].episodes.length) {
        url = series.seasons[_currentSeasonIndex!].episodes[_currentEpisodeIndex!].driveLink;
      }
    }
    return VideoUrlConverter.convertGoogleDriveUrl(url);
  }

  String _getCurrentTitle() {
    if (widget.content is MovieContent) {
      return widget.content.title;
    } else if (widget.content is SeriesContent) {
      final series = widget.content as SeriesContent;
      if (series.seasons.isNotEmpty && 
          _currentSeasonIndex! < series.seasons.length &&
          series.seasons[_currentSeasonIndex!].episodes.isNotEmpty &&
          _currentEpisodeIndex! < series.seasons[_currentSeasonIndex!].episodes.length) {
        final episode = series.seasons[_currentSeasonIndex!].episodes[_currentEpisodeIndex!];
        return '${widget.content.title} - ${episode.title}';
      }
    }
    return widget.content.title;
  }

  Future<void> _loadSuggestedVideos() async {
    try {
      final content = await ApiService.getContent();
      if (!mounted) return;
      setState(() {
        _suggestedVideos = content.where((item) => item.id != widget.content.id).take(10).toList();
      });
    } catch (e) {
    }
  }


  void _toggleLike() {
    setState(() {
      if (_isLiked) {
        _isLiked = false;
        _likeCount--;
      } else {
        _isLiked = true;
        _likeCount++;
        if (_isDisliked) {
          _isDisliked = false;
          _dislikeCount--;
        }
      }
    });
  }

  void _toggleDislike() {
    setState(() {
      if (_isDisliked) {
        _isDisliked = false;
        _dislikeCount--;
      } else {
        _isDisliked = true;
        _dislikeCount++;
        if (_isLiked) {
          _isLiked = false;
          _likeCount--;
        }
      }
    });
  }

  void _shareVideo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming Soon!')),
    );
  }

  Future<void> _downloadVideo() async {
    try {
      final videoUrl = _getVideoUrl();
      if (videoUrl.isEmpty) return;
      
      final currentTitle = _getCurrentTitle();
      final contentId = widget.content is SeriesContent 
          ? '${widget.content.id}_s${_currentSeasonIndex}_e${_currentEpisodeIndex}'
          : widget.content.id;
      
      final isAlreadyDownloaded = await DatabaseService().isDownloaded(contentId);
      
      if (isAlreadyDownloaded) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Already downloaded!'),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }
      
      await DatabaseService().addDownload(
        videoId: contentId,
        title: currentTitle,
        thumbnailUrl: widget.content.thumbnail,
        videoUrl: videoUrl,
        type: widget.content.type.name,
        filePath: videoUrl,
        fileSize: 0,
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added to downloads! Check Profile > Downloads'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('Error downloading video: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add to downloads'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addComment() {
    if (_commentController.text.trim().isNotEmpty) {
      setState(() {
        _comments.insert(0, Comment(
          username: 'User',
          text: _commentController.text.trim(),
          timestamp: DateTime.now(),
        ));
        _commentController.clear();
      });
    }
  }

  void _playVideo(ContentItem content) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => YouTubePlayerScreen(content: content),
      ),
    );
  }

  Future<void> _playEpisode(int seasonIndex, int episodeIndex) async {
    setState(() {
      _currentSeasonIndex = seasonIndex;
      _currentEpisodeIndex = episodeIndex;
      _isLoading = true;
    });
    
    final videoUrl = _getVideoUrl();
    if (videoUrl.isNotEmpty) {
      await _playbackController.switchVideo(videoUrl);
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isSeries = widget.content is SeriesContent;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0D),
      body: Stack(
        children: [
          SafeArea(
            child: isLandscape ? _buildLandscapePlayer() : _buildPortraitLayout(isSeries),
          ),
        ],
      ),
    );
  }
  

  Widget _buildLandscapePlayer() {
    return _buildVideoPlayer();
  }

  Widget _buildPortraitLayout(bool isSeries) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: const Color(0xFF0B0B0D),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          pinned: false,
        ),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildVideoPlayer(),
              if (isSeries) _buildPlaylistToggle(),
              _buildVideoInfo(),
              _buildActionButtons(),
              if (isSeries && _isPlaylistVisible) _buildPlaylist(),
              if (!isSeries || !_isPlaylistVisible) ...[
                const Divider(color: Colors.grey),
                _buildCommentsSection(),
                const Divider(color: Colors.grey),
                _buildSuggestedVideos(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaylistToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _isPlaylistVisible ? 'Playlist' : 'Show Playlist',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: Icon(
              _isPlaylistVisible ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isPlaylistVisible = !_isPlaylistVisible;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylist() {
    if (widget.content is! SeriesContent) return const SizedBox.shrink();
    
    final series = widget.content as SeriesContent;
    
    if (series.seasons.isEmpty || 
        _currentSeasonIndex == null || 
        _currentSeasonIndex! >= series.seasons.length) {
      return const SizedBox.shrink();
    }
    
    final currentSeason = series.seasons[_currentSeasonIndex!];
    
    if (currentSeason.episodes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'No episodes available',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }
    
    return Container(
      color: const Color(0xFF1A1A1D),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (series.seasons.length > 1)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<int>(
                  value: _currentSeasonIndex,
                  dropdownColor: const Color(0xFF2D2D30),
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  items: series.seasons.asMap().entries.map((entry) {
                    return DropdownMenuItem<int>(
                      value: entry.key,
                      child: Text(entry.value.title),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _currentSeasonIndex = newValue;
                        _currentEpisodeIndex = 0;
                      });
                    }
                  },
                ),
              ),
            ),
          Container(
            constraints: const BoxConstraints(maxHeight: 400),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: currentSeason.episodes.length,
              itemBuilder: (context, index) {
                final episode = currentSeason.episodes[index];
                final isPlaying = index == _currentEpisodeIndex;
                
                return InkWell(
                  onTap: () => _playEpisode(_currentSeasonIndex!, index),
                  child: Container(
                    color: isPlaying ? const Color(0xFF2D2D30) : Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                episode.thumbnail.isNotEmpty 
                                    ? episode.thumbnail 
                                    : series.thumbnail,
                                width: 120,
                                height: 68,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 120,
                                    height: 68,
                                    color: Colors.grey[800],
                                    child: const Icon(Icons.play_circle_outline, color: Colors.white),
                                  );
                                },
                              ),
                            ),
                            if (isPlaying)
                              Container(
                                width: 120,
                                height: 68,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                episode.title,
                                style: TextStyle(
                                  color: isPlaying ? Colors.red : Colors.white,
                                  fontSize: 14,
                                  fontWeight: isPlaying ? FontWeight.bold : FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (episode.duration != null && episode.duration!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    episode.duration!,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (isPlaying)
                          const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Icon(Icons.volume_up, color: Colors.red, size: 20),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    final videoUrl = _getVideoUrl();
    
    if (videoUrl.isEmpty) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text(
                  'No video URL available',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: AnimatedBuilder(
          animation: _playbackController,
          builder: (context, child) {
            if (_playbackController.hasError) {
              return Container(
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        'Error loading video',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _playbackController.errorMessage,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            if (!_playbackController.isInitialized || _playbackController.chewieController == null) {
              return Container(
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.red,
                  ),
                ),
              );
            }

            return Chewie(
              controller: _playbackController.chewieController!,
            );
          },
        ),
      ),
    );
  }

  Widget _buildVideoInfo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getCurrentTitle(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.content.releaseYear != null ? '${widget.content.releaseYear}' : '',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
            label: _formatCount(_likeCount),
            onTap: _toggleLike,
            isActive: _isLiked,
          ),
          _buildActionButton(
            icon: _isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
            label: _formatCount(_dislikeCount),
            onTap: _toggleDislike,
            isActive: _isDisliked,
          ),
          _buildActionButton(
            icon: Icons.share,
            label: 'Share',
            onTap: _shareVideo,
          ),
          _buildActionButton(
            icon: Icons.download,
            label: 'Download',
            onTap: _downloadVideo,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(
              icon,
              color: isActive ? Colors.red : Colors.white,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.red : Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comments (${_comments.length})',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Add a comment...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.red),
                onPressed: _addComment,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _comments.length,
            itemBuilder: (context, index) {
              final comment = _comments[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                comment.username,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatTimestamp(comment.timestamp),
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            comment.text,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedVideos() {
    if (_suggestedVideos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Suggested Videos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _suggestedVideos.length,
            itemBuilder: (context, index) {
              final video = _suggestedVideos[index];
              return InkWell(
                onTap: () => _playVideo(video),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 68,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            video.thumbnail,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(Icons.play_circle_filled, color: Colors.white, size: 32),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              video.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              video.releaseYear != null ? '${video.releaseYear}' : '',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
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
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}

class Comment {
  final String username;
  final String text;
  final DateTime timestamp;

  Comment({
    required this.username,
    required this.text,
    required this.timestamp,
  });
}
