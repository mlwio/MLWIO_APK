import 'package:flutter/material.dart';

class VideoSettingsSheet extends StatefulWidget {
  final String currentQuality;
  final double currentSpeed;
  final String currentSubtitle;
  final String currentAudioTrack;
  final bool isLocked;
  final bool isDialog;
  final Function(String) onQualityChanged;
  final Function(double) onSpeedChanged;
  final Function(String) onSubtitleChanged;
  final Function(String) onAudioTrackChanged;
  final VoidCallback onLockScreen;

  const VideoSettingsSheet({
    super.key,
    required this.currentQuality,
    required this.currentSpeed,
    required this.currentSubtitle,
    required this.currentAudioTrack,
    required this.isLocked,
    this.isDialog = false,
    required this.onQualityChanged,
    required this.onSpeedChanged,
    required this.onSubtitleChanged,
    required this.onAudioTrackChanged,
    required this.onLockScreen,
  });

  @override
  State<VideoSettingsSheet> createState() => _VideoSettingsSheetState();
}

class _VideoSettingsSheetState extends State<VideoSettingsSheet> {
  String? _activeSubmenu;

  final List<String> _qualities = [
    'Auto (1080p)',
    '1080p',
    '720p',
    '480p',
    '360p',
    '240p',
  ];

  final List<double> _speeds = [
    0.25,
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    1.75,
    2.0,
  ];

  final List<String> _subtitles = [
    'Off',
    'Auto',
    'English',
    'Bangla',
    'Hindi',
    'Arabic',
  ];

  final List<String> _audioTracks = [
    'Original',
    'Bangla',
    'English',
    'Hindi',
    'Japanese',
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.isDialog) {
      return _buildDialogContent();
    }
    return _buildBottomSheetContent();
  }

  Widget _buildDialogContent() {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.4,
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        decoration: BoxDecoration(
          color: const Color(0xFF212121),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDragHandle(),
            Flexible(
              child: SingleChildScrollView(
                child: _activeSubmenu != null
                    ? _buildSubmenu()
                    : _buildMainMenu(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetContent() {
    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF212121),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              _buildDragHandle(),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: _activeSubmenu != null
                      ? _buildSubmenu()
                      : _buildMainMenu(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDragHandle() {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.velocity.pixelsPerSecond.dy > 300) {
          Navigator.pop(context);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainMenu() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMenuItem(
          icon: Icons.tune,
          title: 'Quality',
          value: widget.currentQuality,
          onTap: () => setState(() => _activeSubmenu = 'quality'),
        ),
        _buildMenuItem(
          icon: Icons.slow_motion_video,
          title: 'Playback speed',
          value: '${widget.currentSpeed}x',
          onTap: () => setState(() => _activeSubmenu = 'speed'),
        ),
        _buildMenuItem(
          icon: Icons.closed_caption,
          title: 'Captions',
          value: widget.currentSubtitle,
          onTap: () => setState(() => _activeSubmenu = 'captions'),
        ),
        _buildMenuItem(
          icon: Icons.audiotrack,
          title: 'Audio Track',
          value: widget.currentAudioTrack,
          onTap: () => setState(() => _activeSubmenu = 'audio'),
        ),
        _buildMenuItem(
          icon: Icons.lock_outline,
          title: 'Lock screen',
          onTap: widget.onLockScreen,
        ),
        _buildMenuItem(
          icon: Icons.settings,
          title: 'More',
          showArrow: true,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildSubmenu() {
    switch (_activeSubmenu) {
      case 'quality':
        return _buildQualitySubmenu();
      case 'speed':
        return _buildSpeedSubmenu();
      case 'captions':
        return _buildCaptionsSubmenu();
      case 'audio':
        return _buildAudioSubmenu();
      default:
        return _buildMainMenu();
    }
  }

  Widget _buildSubmenuHeader(String title) {
    return InkWell(
      onTap: () => setState(() => _activeSubmenu = null),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQualitySubmenu() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSubmenuHeader('Quality'),
        const Divider(color: Colors.grey, height: 1),
        ..._qualities.map((quality) => _buildRadioItem(
              title: quality,
              isSelected: widget.currentQuality == quality,
              onTap: () => widget.onQualityChanged(quality),
            )),
      ],
    );
  }

  Widget _buildSpeedSubmenu() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSubmenuHeader('Playback speed'),
        const Divider(color: Colors.grey, height: 1),
        ..._speeds.map((speed) => _buildRadioItem(
              title: speed == 1.0 ? 'Normal' : '${speed}x',
              isSelected: widget.currentSpeed == speed,
              onTap: () => widget.onSpeedChanged(speed),
            )),
      ],
    );
  }

  Widget _buildCaptionsSubmenu() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSubmenuHeader('Captions'),
        const Divider(color: Colors.grey, height: 1),
        ..._subtitles.map((subtitle) => _buildRadioItem(
              title: subtitle,
              isSelected: widget.currentSubtitle == subtitle,
              onTap: () => widget.onSubtitleChanged(subtitle),
            )),
      ],
    );
  }

  Widget _buildAudioSubmenu() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSubmenuHeader('Audio Track'),
        const Divider(color: Colors.grey, height: 1),
        ..._audioTracks.map((track) => _buildRadioItem(
              title: track,
              isSelected: widget.currentAudioTrack == track,
              onTap: () => widget.onAudioTrackChanged(track),
            )),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? value,
    bool showArrow = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
            if (value != null)
              Text(
                value,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            if (showArrow || value != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioItem({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.blue, size: 24)
                  : null,
            ),
            const SizedBox(width: 20),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
