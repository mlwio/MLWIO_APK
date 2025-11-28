import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/mini_player_service.dart';
import '../models/video.dart';
import '../screens/youtube_style_player.dart';

class BottomRightMiniPlayer extends StatefulWidget {
  const BottomRightMiniPlayer({super.key});

  @override
  State<BottomRightMiniPlayer> createState() => _BottomRightMiniPlayerState();
}

class _BottomRightMiniPlayerState extends State<BottomRightMiniPlayer> {
  final MiniPlayerService _miniPlayerService = MiniPlayerService();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _miniPlayerService,
      builder: (context, child) {
        if (!_miniPlayerService.isMinimized) {
          return const SizedBox.shrink();
        }

        final content = _miniPlayerService.currentContent;
        final title = _miniPlayerService.currentTitle ?? '';

        return Positioned(
          right: 16,
          bottom: 80,
          child: GestureDetector(
            onTap: _expandToFullScreen,
            child: Container(
              width: 200,
              height: 140,
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
                child: Column(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          _buildMiniPlayerContent(content),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                _miniPlayerService.close();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      color: const Color(0xFF1A1A1A),
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniPlayerContent(ContentItem? content) {
    if (content != null && content.thumbnail.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: content.thumbnail,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[900],
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[900],
          child: const Center(
            child: Icon(
              Icons.movie_outlined,
              color: Colors.white54,
              size: 32,
            ),
          ),
        ),
      );
    }

    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Icon(
          Icons.play_circle_outline,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }

  void _expandToFullScreen() {
    final content = _miniPlayerService.currentContent;
    if (content == null) return;

    final episodeIndex = _miniPlayerService.currentEpisodeIndex;
    final seasonIndex = _miniPlayerService.currentSeasonIndex;

    _miniPlayerService.maximize();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => YouTubeStylePlayer(
          content: content,
          initialEpisodeIndex: episodeIndex,
          initialSeasonIndex: seasonIndex,
        ),
      ),
    );
  }
}
