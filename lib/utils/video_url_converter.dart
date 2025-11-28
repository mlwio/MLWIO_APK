class VideoUrlConverter {
  static String convertGoogleDriveUrl(String url) {
    if (url.isEmpty) return '';
    
    if (url.contains('/file/d/') && url.contains('/view')) {
      final fileIdMatch = RegExp(r'/d/([^/]+)').firstMatch(url);
      if (fileIdMatch != null) {
        final fileId = fileIdMatch.group(1);
        return 'https://drive.google.com/uc?export=download&id=$fileId';
      }
    }
    
    if (url.contains('/preview')) {
      final fileIdMatch = RegExp(r'/d/([^/]+)').firstMatch(url);
      if (fileIdMatch != null) {
        final fileId = fileIdMatch.group(1);
        return 'https://drive.google.com/uc?export=download&id=$fileId';
      }
    }
    
    return url;
  }

  static String convertToDirectUrl(String url) {
    return convertGoogleDriveUrl(url);
  }

  static String extractDriveId(String url) {
    if (url.isEmpty) return '';
    
    final patterns = [
      RegExp(r'/d/([a-zA-Z0-9_-]+)'),
      RegExp(r'id=([a-zA-Z0-9_-]+)'),
      RegExp(r'^([a-zA-Z0-9_-]{25,})$'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null) {
        return match.group(1) ?? '';
      }
    }
    
    return url;
  }

  static String getPreviewUrl(String url) {
    if (url.isEmpty) return '';
    
    if (url.startsWith('http://drive.movieway.site') || 
        url.startsWith('https://drive.movieway.site')) {
      return url;
    }
    
    if (url.contains('drive.google.com')) {
      final driveId = extractDriveId(url);
      if (driveId.isNotEmpty) {
        return 'https://drive.google.com/file/d/$driveId/preview';
      }
    }
    
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    
    return url;
  }

  static String getEmbedUrl(String url) {
    if (url.isEmpty) return '';
    
    if (url.startsWith('http://drive.movieway.site') || 
        url.startsWith('https://drive.movieway.site')) {
      return url;
    }
    
    if (url.contains('drive.google.com')) {
      final driveId = extractDriveId(url);
      if (driveId.isNotEmpty) {
        return 'https://drive.google.com/file/d/$driveId/preview?autoplay=1';
      }
    }
    
    return url;
  }

  static String getVideoUrl(String? playbackUrl, String? driveLink) {
    if (playbackUrl != null && playbackUrl.isNotEmpty) {
      return playbackUrl;
    }
    
    if (driveLink != null && driveLink.isNotEmpty) {
      if (driveLink.startsWith('http')) {
        return getPreviewUrl(driveLink);
      }
    }
    
    return '';
  }
}
