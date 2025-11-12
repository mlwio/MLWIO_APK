import 'package:flutter/foundation.dart';
import '../models/video.dart';

class PlaylistController extends ChangeNotifier {
  List<Episode> _playlist = [];
  int _currentIndex = 0;
  bool _autoPlayEnabled = true;

  List<Episode> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  Episode? get currentEpisode => _playlist.isNotEmpty ? _playlist[_currentIndex] : null;
  bool get hasNext => _currentIndex < _playlist.length - 1;
  bool get hasPrevious => _currentIndex > 0;
  bool get autoPlayEnabled => _autoPlayEnabled;

  void setPlaylist(List<Episode> episodes, {int startIndex = 0}) {
    _playlist = episodes;
    _currentIndex = startIndex.clamp(0, episodes.length - 1);
    notifyListeners();
  }

  void playNext() {
    if (hasNext) {
      _currentIndex++;
      notifyListeners();
    }
  }

  void playPrevious() {
    if (hasPrevious) {
      _currentIndex--;
      notifyListeners();
    }
  }

  void playEpisodeAt(int index) {
    if (index >= 0 && index < _playlist.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void toggleAutoPlay() {
    _autoPlayEnabled = !_autoPlayEnabled;
    notifyListeners();
  }

  void onVideoComplete() {
    if (_autoPlayEnabled && hasNext) {
      playNext();
    }
  }

  void clear() {
    _playlist = [];
    _currentIndex = 0;
    notifyListeners();
  }
}
