enum ContentType { movie, anime, webSeries }

abstract class ContentItem {
  final String id;
  final String title;
  final String thumbnail;
  final ContentType type;
  final int? releaseYear;

  ContentItem({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.type,
    this.releaseYear,
  });

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as String?;
    final seasons = json['seasons'] as List<dynamic>?;

    if (category == 'Movie' || (seasons != null && seasons.isEmpty)) {
      return MovieContent.fromJson(json);
    } else {
      return SeriesContent.fromJson(json);
    }
  }
}

class MovieContent extends ContentItem {
  final String driveLink;

  MovieContent({
    required super.id,
    required super.title,
    required super.thumbnail,
    required this.driveLink,
    super.releaseYear,
  }) : super(type: ContentType.movie);

  factory MovieContent.fromJson(Map<String, dynamic> json) {
    return MovieContent(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      driveLink: json['driveLink'] ?? '',
      releaseYear: json['releaseYear'],
    );
  }
}

class SeriesContent extends ContentItem {
  final List<Season> seasons;

  SeriesContent({
    required super.id,
    required super.title,
    required super.thumbnail,
    required this.seasons,
    super.releaseYear,
    ContentType type = ContentType.anime,
  }) : super(type: type);

  factory SeriesContent.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as String?;
    final type = category == 'Anime' ? ContentType.anime : ContentType.webSeries;

    return SeriesContent(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      seasons: (json['seasons'] as List<dynamic>?)
              ?.map((e) => Season.fromJson(e))
              .toList() ??
          [],
      releaseYear: json['releaseYear'],
      type: type,
    );
  }

  int get totalEpisodes => seasons.fold(0, (sum, season) => sum + season.episodes.length);
}

class Season {
  final String id;
  final int seasonNumber;
  final String title;
  final List<Episode> episodes;

  Season({
    required this.id,
    required this.seasonNumber,
    required this.title,
    required this.episodes,
  });

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      id: json['_id'] ?? json['id'] ?? '',
      seasonNumber: json['seasonNumber'] ?? 1,
      title: json['title'] ?? 'Season ${json['seasonNumber'] ?? 1}',
      episodes: (json['episodes'] as List<dynamic>?)
              ?.map((e) => Episode.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class Episode {
  final String id;
  final int episodeNumber;
  final String title;
  final String thumbnail;
  final String driveLink;
  final String? duration;
  final String? description;

  Episode({
    required this.id,
    required this.episodeNumber,
    required this.title,
    required this.thumbnail,
    required this.driveLink,
    this.duration,
    this.description,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['_id'] ?? json['id'] ?? '',
      episodeNumber: json['episodeNumber'] ?? 1,
      title: json['title'] ?? 'Episode ${json['episodeNumber'] ?? 1}',
      thumbnail: json['thumbnail'] ?? '',
      driveLink: json['link'] ?? json['driveLink'] ?? '',
      duration: json['duration'],
      description: json['description'],
    );
  }
}

class Video {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String channelLogo;
  final String channelName;
  final String releaseDate;
  final String videoUrl;
  final String duration;
  final String description;
  final List<DownloadLink> downloadLinks;

  Video({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.channelLogo,
    required this.channelName,
    required this.releaseDate,
    required this.videoUrl,
    required this.duration,
    required this.description,
    required this.downloadLinks,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      thumbnailUrl: json['thumbnail_url'] ?? '',
      channelLogo: json['channel_logo'] ?? '',
      channelName: json['channel_name'] ?? 'MLWIO',
      releaseDate: json['release_date'] ?? json['published_at'] ?? '',
      videoUrl: json['video_url'] ?? '',
      duration: json['duration'] ?? '',
      description: json['description'] ?? '',
      downloadLinks: (json['download_links'] as List<dynamic>?)
              ?.map((e) => DownloadLink.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class DownloadLink {
  final String quality;
  final String url;

  DownloadLink({required this.quality, required this.url});

  factory DownloadLink.fromJson(Map<String, dynamic> json) {
    return DownloadLink(
      quality: json['quality'] ?? '',
      url: json['url'] ?? '',
    );
  }
}

class VideosResponse {
  final int page;
  final int limit;
  final int total;
  final List<Video> videos;

  VideosResponse({
    required this.page,
    required this.limit,
    required this.total,
    required this.videos,
  });

  factory VideosResponse.fromJson(Map<String, dynamic> json) {
    return VideosResponse(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      total: json['total'] ?? 0,
      videos: (json['videos'] as List<dynamic>?)
              ?.map((e) => Video.fromJson(e))
              .toList() ??
          [],
    );
  }
}
