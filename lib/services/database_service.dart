import 'package:hive_flutter/hive_flutter.dart';

class WatchHistoryItem {
  final String videoId;
  final String title;
  final String? thumbnailUrl;
  final String videoUrl;
  final String type;
  final int watchedAt;
  final String? userEmail;

  WatchHistoryItem({
    required this.videoId,
    required this.title,
    this.thumbnailUrl,
    required this.videoUrl,
    required this.type,
    required this.watchedAt,
    this.userEmail,
  });

  Map<String, dynamic> toMap() {
    return {
      'video_id': videoId,
      'title': title,
      'thumbnail_url': thumbnailUrl,
      'video_url': videoUrl,
      'type': type,
      'watched_at': watchedAt,
      'user_email': userEmail,
    };
  }

  factory WatchHistoryItem.fromMap(Map<String, dynamic> map) {
    return WatchHistoryItem(
      videoId: map['video_id'] as String,
      title: map['title'] as String,
      thumbnailUrl: map['thumbnail_url'] as String?,
      videoUrl: map['video_url'] as String,
      type: map['type'] as String,
      watchedAt: map['watched_at'] as int,
      userEmail: map['user_email'] as String?,
    );
  }
}

class DownloadItem {
  final String videoId;
  final String title;
  final String? thumbnailUrl;
  final String videoUrl;
  final String type;
  final String filePath;
  final int downloadedAt;
  final int fileSize;
  final String? userEmail;

  DownloadItem({
    required this.videoId,
    required this.title,
    this.thumbnailUrl,
    required this.videoUrl,
    required this.type,
    required this.filePath,
    required this.downloadedAt,
    required this.fileSize,
    this.userEmail,
  });

  Map<String, dynamic> toMap() {
    return {
      'video_id': videoId,
      'title': title,
      'thumbnail_url': thumbnailUrl,
      'video_url': videoUrl,
      'type': type,
      'file_path': filePath,
      'downloaded_at': downloadedAt,
      'file_size': fileSize,
      'user_email': userEmail,
    };
  }

  factory DownloadItem.fromMap(Map<String, dynamic> map) {
    return DownloadItem(
      videoId: map['video_id'] as String,
      title: map['title'] as String,
      thumbnailUrl: map['thumbnail_url'] as String?,
      videoUrl: map['video_url'] as String,
      type: map['type'] as String,
      filePath: map['file_path'] as String,
      downloadedAt: map['downloaded_at'] as int,
      fileSize: map['file_size'] as int,
      userEmail: map['user_email'] as String?,
    );
  }
}

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const String _watchHistoryBox = 'watch_history';
  static const String _downloadsBox = 'downloads';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      await Hive.initFlutter();
      await Hive.openBox(_watchHistoryBox);
      await Hive.openBox(_downloadsBox);
      _initialized = true;
    } catch (e) {
      print('Error initializing Hive: $e');
    }
  }

  Future<void> addToWatchHistory({
    required String videoId,
    required String title,
    String? thumbnailUrl,
    required String videoUrl,
    required String type,
    String? userEmail,
  }) async {
    try {
      await init();
      final box = Hive.box(_watchHistoryBox);
      final item = WatchHistoryItem(
        videoId: videoId,
        title: title,
        thumbnailUrl: thumbnailUrl,
        videoUrl: videoUrl,
        type: type,
        watchedAt: DateTime.now().millisecondsSinceEpoch,
        userEmail: userEmail,
      );
      await box.add(item.toMap());
    } catch (e) {
      print('Error adding to watch history: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getWatchHistory({String? userEmail}) async {
    try {
      await init();
      final box = Hive.box(_watchHistoryBox);
      final items = box.values.toList();
      
      List<Map<String, dynamic>> history = items
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      
      if (userEmail != null) {
        history = history
            .where((item) => item['user_email'] == userEmail)
            .toList();
      }
      
      history.sort((a, b) => (b['watched_at'] as int).compareTo(a['watched_at'] as int));
      
      return history;
    } catch (e) {
      print('Error getting watch history: $e');
      return [];
    }
  }

  Future<void> clearWatchHistory({String? userEmail}) async {
    try {
      await init();
      final box = Hive.box(_watchHistoryBox);
      
      if (userEmail != null) {
        final keysToDelete = <dynamic>[];
        for (var i = 0; i < box.length; i++) {
          final item = box.getAt(i) as Map;
          if (item['user_email'] == userEmail) {
            keysToDelete.add(box.keyAt(i));
          }
        }
        for (var key in keysToDelete) {
          await box.delete(key);
        }
      } else {
        await box.clear();
      }
    } catch (e) {
      print('Error clearing watch history: $e');
    }
  }

  Future<void> addDownload({
    required String videoId,
    required String title,
    String? thumbnailUrl,
    required String videoUrl,
    required String type,
    required String filePath,
    required int fileSize,
    String? userEmail,
  }) async {
    try {
      await init();
      final box = Hive.box(_downloadsBox);
      
      final existingKey = await _findDownloadKey(videoId);
      if (existingKey != null) {
        return;
      }
      
      final item = DownloadItem(
        videoId: videoId,
        title: title,
        thumbnailUrl: thumbnailUrl,
        videoUrl: videoUrl,
        type: type,
        filePath: filePath,
        downloadedAt: DateTime.now().millisecondsSinceEpoch,
        fileSize: fileSize,
        userEmail: userEmail,
      );
      await box.add(item.toMap());
    } catch (e) {
      print('Error adding download: $e');
    }
  }

  Future<dynamic> _findDownloadKey(String videoId) async {
    try {
      final box = Hive.box(_downloadsBox);
      for (var i = 0; i < box.length; i++) {
        final item = box.getAt(i) as Map;
        if (item['video_id'] == videoId) {
          return box.keyAt(i);
        }
      }
      return null;
    } catch (e) {
      print('Error finding download key: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getDownloads({String? userEmail}) async {
    try {
      await init();
      final box = Hive.box(_downloadsBox);
      final items = box.values.toList();
      
      List<Map<String, dynamic>> downloads = items
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      
      if (userEmail != null) {
        downloads = downloads
            .where((item) => item['user_email'] == userEmail)
            .toList();
      }
      
      downloads.sort((a, b) => 
          (b['downloaded_at'] as int).compareTo(a['downloaded_at'] as int));
      
      return downloads;
    } catch (e) {
      print('Error getting downloads: $e');
      return [];
    }
  }

  Future<void> deleteDownload(String videoId) async {
    try {
      await init();
      final box = Hive.box(_downloadsBox);
      final key = await _findDownloadKey(videoId);
      if (key != null) {
        await box.delete(key);
      }
    } catch (e) {
      print('Error deleting download: $e');
    }
  }

  Future<bool> isDownloaded(String videoId) async {
    try {
      await init();
      final key = await _findDownloadKey(videoId);
      return key != null;
    } catch (e) {
      print('Error checking if downloaded: $e');
      return false;
    }
  }
}
