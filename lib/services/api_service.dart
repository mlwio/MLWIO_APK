import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/video.dart';
import '../utils/constants.dart';
import 'mock_api_service.dart';

class ApiService {
  static const bool useMockData = false;
  static const String contentApiUrl = 'https://api.movieway.site/api/content';

  static Future<VideosResponse> getVideos({
    int page = 1,
    int limit = 10,
    String category = 'All',
    String search = '',
  }) async {
    if (useMockData) {
      return MockApiService.getVideos(
        page: page,
        limit: limit,
        category: category,
        search: search,
      );
    }

    try {
      final uri = Uri.parse('${AppConstants.apiBaseUrl}/videos').replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          if (category != 'All') 'category': category.toLowerCase(),
          if (search.isNotEmpty) 'search': search,
        },
      );

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return VideosResponse.fromJson(data);
      } else {
        throw Exception('Failed to load videos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching videos: $e');
    }
  }

  static Future<Video> getVideoById(String id) async {
    if (useMockData) {
      return MockApiService.getVideoById(id);
    }

    try {
      final uri = Uri.parse('${AppConstants.apiBaseUrl}/videos/$id');
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Video.fromJson(data);
      } else {
        throw Exception('Failed to load video: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching video: $e');
    }
  }

  static Future<List<ContentItem>> getContent({
    String category = 'All',
  }) async {
    try {
      final response = await http.get(Uri.parse(contentApiUrl)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        List<ContentItem> allContent = data
            .map((json) => ContentItem.fromJson(json))
            .toList();

        if (category == 'All') {
          return allContent;
        } else if (category == 'Movie') {
          return allContent.where((item) => item.type == ContentType.movie).toList();
        } else if (category == 'Anime') {
          return allContent.where((item) => item.type == ContentType.anime).toList();
        } else if (category == 'Web-series') {
          return allContent.where((item) => item.type == ContentType.webSeries).toList();
        }
        
        return allContent;
      } else {
        throw Exception('Failed to load content: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching content: $e');
    }
  }

  static Future<List<MovieContent>> getMovies() async {
    final content = await getContent(category: 'Movie');
    return content.whereType<MovieContent>().toList();
  }

  static Future<List<SeriesContent>> getSeries() async {
    final content = await getContent();
    return content.whereType<SeriesContent>().toList();
  }

  static Future<List<SeriesContent>> getAnime() async {
    final content = await getContent(category: 'Anime');
    return content.whereType<SeriesContent>().toList();
  }

  static Future<List<SeriesContent>> getWebSeries() async {
    final content = await getContent(category: 'Web-series');
    return content.whereType<SeriesContent>().toList();
  }
}
