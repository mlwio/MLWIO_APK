import 'package:flutter/material.dart';
import '../services/mini_player_service.dart';
import 'bottom_right_mini_player.dart';

class AppWrapper extends StatefulWidget {
  final Widget child;

  const AppWrapper({super.key, required this.child});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  final MiniPlayerService _miniPlayerService = MiniPlayerService();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        const BottomRightMiniPlayer(),
      ],
    );
  }
}
