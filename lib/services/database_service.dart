import 'package:hive_flutter/hive_flutter.dart';
import '../models/video.dart';

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

class LikeDislikeItem {
  final String videoId;
  final bool isLiked;
  final int timestamp;

  LikeDislikeItem({
    required this.videoId,
    required this.isLiked,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'video_id': videoId,
      'is_liked': isLiked,
      'timestamp': timestamp,
    };
  }

  factory LikeDislikeItem.fromMap(Map<String, dynamic> map) {
    return LikeDislikeItem(
      videoId: map['video_id'] as String,
      isLiked: map['is_liked'] as bool,
      timestamp: map['timestamp'] as int,
    );
  }
}

class CommentItem {
  final String id;
  final String videoId;
  final String text;
  final String userName;
  final String? userAvatar;
  final int timestamp;
  final int likes;
  final List<CommentItem> replies;

  CommentItem({
    required this.id,
    required this.videoId,
    required this.text,
    required this.userName,
    this.userAvatar,
    required this.timestamp,
    this.likes = 0,
    this.replies = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'video_id': videoId,
      'text': text,
      'user_name': userName,
      'user_avatar': userAvatar,
      'timestamp': timestamp,
      'likes': likes,
      'replies': replies.map((r) => r.toMap()).toList(),
    };
  }

  factory CommentItem.fromMap(Map<String, dynamic> map) {
    return CommentItem(
      id: map['id'] as String,
      videoId: map['video_id'] as String,
      text: map['text'] as String,
      userName: map['user_name'] as String,
      userAvatar: map['user_avatar'] as String?,
      timestamp: map['timestamp'] as int,
      likes: map['likes'] as int? ?? 0,
      replies: (map['replies'] as List<dynamic>?)
              ?.map((r) => CommentItem.fromMap(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SavedItem {
  final String videoId;
  final String title;
  final String? thumbnailUrl;
  final String videoUrl;
  final String type;
  final int savedAt;

  SavedItem({
    required this.videoId,
    required this.title,
    this.thumbnailUrl,
    required this.videoUrl,
    required this.type,
    required this.savedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'video_id': videoId,
      'title': title,
      'thumbnail_url': thumbnailUrl,
      'video_url': videoUrl,
      'type': type,
      'saved_at': savedAt,
    };
  }

  factory SavedItem.fromMap(Map<String, dynamic> map) {
    return SavedItem(
      videoId: map['video_id'] as String,
      title: map['title'] as String,
      thumbnailUrl: map['thumbnail_url'] as String?,
      videoUrl: map['video_url'] as String,
      type: map['type'] as String,
      savedAt: map['saved_at'] as int,
    );
  }
}

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const String _watchHistoryBox = 'watch_history';
  static const String _downloadsBox = 'downloads';
  static const String _likesBox = 'likes';
  static const String _commentsBox = 'comments';
  static const String _savedBox = 'saved';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      await Hive.initFlutter();
      await Hive.openBox(_watchHistoryBox);
      await Hive.openBox(_downloadsBox);
      await Hive.openBox(_likesBox);
      await Hive.openBox(_commentsBox);
      await Hive.openBox(_savedBox);
      _initialized = true;
    } catch (e) {
      print('Error initializing Hive: $e');
    }
  }

  Future<void> saveToWatchHistory(ContentItem content, {String? userEmail}) async {
    String type = 'Movie';
    if (content.type == ContentType.anime) {
      type = 'Anime';
    } else if (content.type == ContentType.webSeries) {
      type = 'Series';
    }

    await addToWatchHistory(
      videoId: content.id,
      title: content.title,
      thumbnailUrl: content.thumbnail,
      videoUrl: content.driveLink ?? '',
      type: type,
      userEmail: userEmail,
    );
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

  Future<void> setLikeStatus(String videoId, bool? isLiked) async {
    try {
      await init();
      final box = Hive.box(_likesBox);
      
      if (isLiked == null) {
        await box.delete(videoId);
      } else {
        final item = LikeDislikeItem(
          videoId: videoId,
          isLiked: isLiked,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
        await box.put(videoId, item.toMap());
      }
    } catch (e) {
      print('Error setting like status: $e');
    }
  }

  Future<bool?> getLikeStatus(String videoId) async {
    try {
      await init();
      final box = Hive.box(_likesBox);
      final data = box.get(videoId);
      if (data != null) {
        return (data as Map)['is_liked'] as bool;
      }
      return null;
    } catch (e) {
      print('Error getting like status: $e');
      return null;
    }
  }

  Future<int> getLikeCount(String videoId) async {
    try {
      await init();
      final box = Hive.box(_likesBox);
      int count = 0;
      for (var item in box.values) {
        final map = item as Map;
        if (map['is_liked'] == true) {
          count++;
        }
      }
      return count;
    } catch (e) {
      print('Error getting like count: $e');
      return 0;
    }
  }

  Future<void> addComment({
    required String videoId,
    required String text,
    required String userName,
    String? userAvatar,
    String? parentId,
  }) async {
    try {
      await init();
      final box = Hive.box(_commentsBox);
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      
      final comment = CommentItem(
        id: id,
        videoId: videoId,
        text: text,
        userName: userName,
        userAvatar: userAvatar,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      
      await box.add(comment.toMap());
    } catch (e) {
      print('Error adding comment: $e');
    }
  }

  Future<List<CommentItem>> getComments(String videoId) async {
    try {
      await init();
      final box = Hive.box(_commentsBox);
      final items = box.values.toList();
      
      List<CommentItem> comments = items
          .map((item) => CommentItem.fromMap(Map<String, dynamic>.from(item as Map)))
          .where((c) => c.videoId == videoId)
          .toList();
      
      comments.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return comments;
    } catch (e) {
      print('Error getting comments: $e');
      return [];
    }
  }

  Future<void> saveToPlaylist(ContentItem content) async {
    try {
      await init();
      final box = Hive.box(_savedBox);
      
      final existingKey = await _findSavedKey(content.id);
      if (existingKey != null) {
        return;
      }

      String type = 'Movie';
      if (content.type == ContentType.anime) {
        type = 'Anime';
      } else if (content.type == ContentType.webSeries) {
        type = 'Series';
      }
      
      final item = SavedItem(
        videoId: content.id,
        title: content.title,
        thumbnailUrl: content.thumbnail,
        videoUrl: content.driveLink ?? '',
        type: type,
        savedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await box.add(item.toMap());
    } catch (e) {
      print('Error saving to playlist: $e');
    }
  }

  Future<dynamic> _findSavedKey(String videoId) async {
    try {
      final box = Hive.box(_savedBox);
      for (var i = 0; i < box.length; i++) {
        final item = box.getAt(i) as Map;
        if (item['video_id'] == videoId) {
          return box.keyAt(i);
        }
      }
      return null;
    } catch (e) {
      print('Error finding saved key: $e');
      return null;
    }
  }

  Future<bool> isSaved(String videoId) async {
    try {
      await init();
      final key = await _findSavedKey(videoId);
      return key != null;
    } catch (e) {
      print('Error checking if saved: $e');
      return false;
    }
  }

  Future<void> removeFromPlaylist(String videoId) async {
    try {
      await init();
      final box = Hive.box(_savedBox);
      final key = await _findSavedKey(videoId);
      if (key != null) {
        await box.delete(key);
      }
    } catch (e) {
      print('Error removing from playlist: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSavedItems() async {
    try {
      await init();
      final box = Hive.box(_savedBox);
      final items = box.values.toList();
      
      List<Map<String, dynamic>> saved = items
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      
      saved.sort((a, b) => 
          (b['saved_at'] as int).compareTo(a['saved_at'] as int));
      
      return saved;
    } catch (e) {
      print('Error getting saved items: $e');
      return [];
    }
  }
}
