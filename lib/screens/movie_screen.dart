import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import '../models/video.dart';
import '../services/database_service.dart';
import '../services/mini_player_service.dart';
import '../utils/video_url_converter.dart';
import 'youtube_style_player.dart';

class MovieScreen extends StatefulWidget {
  final ContentItem content;

  const MovieScreen({
    super.key,
    required this.content,
  });

  @override
  State<MovieScreen> createState() => _MovieScreenState();
}

class _MovieScreenState extends State<MovieScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => YouTubeStylePlayer(content: widget.content),
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
