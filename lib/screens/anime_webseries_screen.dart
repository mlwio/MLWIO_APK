import 'package:flutter/material.dart';
import '../models/video.dart';
import 'youtube_style_player.dart';

class AnimeWebseriesScreen extends StatefulWidget {
  final ContentItem content;
  final int? initialEpisodeIndex;
  final int? initialSeasonIndex;

  const AnimeWebseriesScreen({
    super.key,
    required this.content,
    this.initialEpisodeIndex,
    this.initialSeasonIndex,
  });

  @override
  State<AnimeWebseriesScreen> createState() => _AnimeWebseriesScreenState();
}

class _AnimeWebseriesScreenState extends State<AnimeWebseriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => YouTubeStylePlayer(
            content: widget.content,
            initialSeasonIndex: widget.initialSeasonIndex,
            initialEpisodeIndex: widget.initialEpisodeIndex,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: const Center(
        child: CircularProgressIndicator(color: Colors.red),
      ),
    );
  }
}
