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
}
