import '../models/video.dart';

class MockApiService {
  static Future<VideosResponse> getVideos({
    int page = 1,
    int limit = 10,
    String category = 'All',
    String search = '',
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final List<Video> allVideos = _generateMockVideos();
    
    List<Video> filteredVideos = allVideos;
    
    if (category != 'All') {
      filteredVideos = allVideos.where((v) => 
        v.description.toLowerCase().contains(category.toLowerCase())
      ).toList();
    }
    
    if (search.isNotEmpty) {
      filteredVideos = filteredVideos.where((v) =>
        v.title.toLowerCase().contains(search.toLowerCase()) ||
        v.description.toLowerCase().contains(search.toLowerCase())
      ).toList();
    }
    
    final startIndex = (page - 1) * limit;
    final endIndex = (startIndex + limit).clamp(0, filteredVideos.length);
    
    final paginatedVideos = startIndex < filteredVideos.length
        ? filteredVideos.sublist(startIndex, endIndex)
        : <Video>[];

    return VideosResponse(
      page: page,
      limit: limit,
      total: filteredVideos.length,
      videos: paginatedVideos,
    );
  }

  static Future<Video> getVideoById(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final videos = _generateMockVideos();
    return videos.firstWhere(
      (v) => v.id == id,
      orElse: () => videos.first,
    );
  }

  static List<Video> _generateMockVideos() {
    return [
      Video(
        id: '1',
        title: 'Attack on Titan: Final Season',
        thumbnailUrl: 'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=800&h=450&fit=crop',
        channelLogo: 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=96&h=96&fit=crop',
        channelName: 'MLWIO Anime',
        releaseDate: '2025-10-15',
        videoUrl: 'https://www.youtube.com/watch?v=HRZN8MVg82c',
        duration: '01:45:30',
        description: 'Epic anime series finale. The battle for humanity reaches its climax.',
        downloadLinks: [
          DownloadLink(quality: '1080p', url: 'https://example.com/1080p.mp4'),
          DownloadLink(quality: '720p', url: 'https://example.com/720p.mp4'),
        ],
      ),
      Video(
        id: '2',
        title: 'Inception - Mind Bending Thriller',
        thumbnailUrl: 'https://images.unsplash.com/photo-1440404653325-ab127d49abc1?w=800&h=450&fit=crop',
        channelLogo: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=96&h=96&fit=crop',
        channelName: 'MLWIO Movies',
        releaseDate: '2024-12-20',
        videoUrl: 'https://www.youtube.com/watch?v=YoHD9XEInc0',
        duration: '02:28:00',
        description: 'A thief who steals corporate secrets through dream-sharing technology. Movies.',
        downloadLinks: [
          DownloadLink(quality: '2K', url: 'https://example.com/2k.mp4'),
          DownloadLink(quality: '1080p', url: 'https://example.com/1080p.mp4'),
        ],
      ),
      Video(
        id: '3',
        title: 'Breaking Bad: Complete Series',
        thumbnailUrl: 'https://images.unsplash.com/photo-1594908900066-3f47337549d8?w=800&h=450&fit=crop',
        channelLogo: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=96&h=96&fit=crop',
        channelName: 'MLWIO Series',
        releaseDate: '2025-09-10',
        videoUrl: 'https://www.youtube.com/watch?v=HhesaQXLuRY',
        duration: '45:00:00',
        description: 'A chemistry teacher turned methamphetamine manufacturer. Web-series.',
        downloadLinks: [
          DownloadLink(quality: '1080p', url: 'https://example.com/1080p.mp4'),
          DownloadLink(quality: '720p', url: 'https://example.com/720p.mp4'),
        ],
      ),
      Video(
        id: '4',
        title: 'One Piece: Wano Arc',
        thumbnailUrl: 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=800&h=450&fit=crop',
        channelLogo: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=96&h=96&fit=crop',
        channelName: 'MLWIO Anime',
        releaseDate: '2025-11-01',
        videoUrl: 'https://www.youtube.com/watch?v=MCb13lbVGE0',
        duration: '01:30:00',
        description: 'The Straw Hats land in Wano for the ultimate battle. Anime epic adventure.',
        downloadLinks: [
          DownloadLink(quality: '1080p', url: 'https://example.com/1080p.mp4'),
        ],
      ),
      Video(
        id: '5',
        title: 'The Dark Knight Returns',
        thumbnailUrl: 'https://images.unsplash.com/photo-1509347528160-9a9e33742cdb?w=800&h=450&fit=crop',
        channelLogo: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=96&h=96&fit=crop',
        channelName: 'MLWIO Movies',
        releaseDate: '2024-11-25',
        videoUrl: 'https://www.youtube.com/watch?v=EXeTwQWrcwY',
        duration: '02:45:00',
        description: 'Batman faces his greatest challenge yet. Movies superhero action.',
        downloadLinks: [
          DownloadLink(quality: '2K', url: 'https://example.com/2k.mp4'),
          DownloadLink(quality: '1080p', url: 'https://example.com/1080p.mp4'),
          DownloadLink(quality: '720p', url: 'https://example.com/720p.mp4'),
        ],
      ),
      Video(
        id: '6',
        title: 'Stranger Things Season 5',
        thumbnailUrl: 'https://images.unsplash.com/photo-1485846234645-a62644f84728?w=800&h=450&fit=crop',
        channelLogo: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=96&h=96&fit=crop',
        channelName: 'MLWIO Series',
        releaseDate: '2025-10-31',
        videoUrl: 'https://www.youtube.com/watch?v=b9EkMc79ZSU',
        duration: '50:00:00',
        description: 'The final battle against the Upside Down. Web-series thriller.',
        downloadLinks: [
          DownloadLink(quality: '1080p', url: 'https://example.com/1080p.mp4'),
        ],
      ),
      Video(
        id: '7',
        title: 'Demon Slayer: Infinity Castle',
        thumbnailUrl: 'https://images.unsplash.com/photo-1606041008023-472dfb5e530f?w=800&h=450&fit=crop',
        channelLogo: 'https://images.unsplash.com/photo-1527980965255-d3b416303d12?w=96&h=96&fit=crop',
        channelName: 'MLWIO Anime',
        releaseDate: '2025-10-20',
        videoUrl: 'https://www.youtube.com/watch?v=ATJYac_dORw',
        duration: '02:00:00',
        description: 'Tanjiro faces Muzan in the final confrontation. Anime action.',
        downloadLinks: [
          DownloadLink(quality: '1080p', url: 'https://example.com/1080p.mp4'),
          DownloadLink(quality: '720p', url: 'https://example.com/720p.mp4'),
        ],
      ),
      Video(
        id: '8',
        title: 'Interstellar Journey',
        thumbnailUrl: 'https://images.unsplash.com/photo-1446776653964-20c1d3a81b06?w=800&h=450&fit=crop',
        channelLogo: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=96&h=96&fit=crop',
        channelName: 'MLWIO Movies',
        releaseDate: '2024-12-15',
        videoUrl: 'https://www.youtube.com/watch?v=zSWdZVtXT7E',
        duration: '02:49:00',
        description: 'A team of explorers travel through a wormhole. Movies sci-fi.',
        downloadLinks: [
          DownloadLink(quality: '2K', url: 'https://example.com/2k.mp4'),
          DownloadLink(quality: '1080p', url: 'https://example.com/1080p.mp4'),
        ],
      ),
    ];
  }
}
