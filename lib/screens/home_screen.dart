import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';
import '../models/video.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/category_chips.dart';
import '../widgets/app_wrapper.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'movie_screen.dart';
import 'search_screen.dart';
import 'series_detail_screen.dart';

String getProxyImageUrl(String originalUrl) {
  return originalUrl;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _selectedCategory = 'All';
  List<ContentItem> _content = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  bool _showGetStartPopup = true;

  @override
  void initState() {
    super.initState();
    _loadContent();
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_showGetStartPopup && mounted) {
        _showGetStartModal();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadContent({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _content = [];
      }
    });

    try {
      final content = await ApiService.getContent(category: _selectedCategory);

      setState(() {
        _content = content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading content: $e')),
        );
      }
    }
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadContent(refresh: true);
  }

  void _showGetStartModal() {
    // Popup disabled - user is already signed in
    setState(() {
      _showGetStartPopup = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget currentScreen;
    if (_currentIndex == 0) {
      currentScreen = _buildHomeContent();
    } else {
      currentScreen = const ProfileScreen();
    }

    return AppWrapper(
      child: Scaffold(
        body: currentScreen,
        bottomNavigationBar: ClipRRect(
          child: Container(
            decoration: BoxDecoration(
              border: const Border(
                top: BorderSide(
                  color: Colors.white24,
                  width: 0.5,
                ),
              ),
              color: const Color(AppColors.backgroundValue).withOpacity(0.85),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: const Color(AppColors.accentValue),
                unselectedItemColor: const Color(AppColors.textMutedValue),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return Column(
      children: [
        Container(
          height: MediaQuery.of(context).padding.top,
          color: const Color(AppColors.backgroundValue),
        ),
        _buildHeader(),
        CategoryChips(
          selectedCategory: _selectedCategory,
          onCategorySelected: _onCategoryChanged,
        ),
        Expanded(
          child: _buildVideoList(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'MLWIO',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(AppColors.textValue),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                color: const Color(AppColors.textValue),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.search),
                color: const Color(AppColors.textValue),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoList() {
    if (_content.isEmpty && _isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(AppColors.accentValue),
        ),
      );
    }

    if (_content.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.movie_outlined,
              size: 64,
              color: Color(AppColors.textMutedValue),
            ),
            const SizedBox(height: 16),
            const Text(
              'No content yet.\nTry another category.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(AppColors.textMutedValue),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _loadContent(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadContent(refresh: true),
      color: const Color(AppColors.accentValue),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          int crossAxisCount;
          double childAspectRatio;
          
          if (width > 1200) {
            crossAxisCount = 3;
            childAspectRatio = 1.22;
          } else if (width > 800) {
            crossAxisCount = 2;
            childAspectRatio = 1.18;
          } else {
            crossAxisCount = 1;
            childAspectRatio = 1.30;
          }
          
          return GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _content.length,
            itemBuilder: (context, index) {
              final item = _content[index];
              return _buildContentCard(item);
            },
          );
        },
      ),
    );
  }

  Widget _buildContentCard(ContentItem item) {
    return _HoverableContentCard(
      onTap: () {
        if (item is MovieContent) {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => MovieScreen(
                content: item,
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(0.0, 1.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;
                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
            ),
          );
        } else if (item is SeriesContent) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SeriesDetailScreen(series: item),
            ),
          );
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Hero(
                tag: 'video_${item.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: getProxyImageUrl(item.thumbnail),
                      width: double.infinity,
                      fit: BoxFit.cover,
                      memCacheWidth: 640,
                      memCacheHeight: 360,
                      fadeInDuration: const Duration(milliseconds: 150),
                      fadeOutDuration: const Duration(milliseconds: 150),
                      placeholder: (context, url) => Container(
                        color: Colors.grey[900],
                      ),
                      errorWidget: (context, url, error) {
                        return Container(
                          color: Colors.grey[800],
                          child: const Center(
                            child: Icon(
                              Icons.movie_outlined,
                              color: Colors.white,
                              size: 64,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              if (item is SeriesContent && item.totalEpisodes > 0)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${item.totalEpisodes} episodes',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12.0, left: 8.0, right: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.transparent,
                  radius: 18,
                  child: Image.asset(
                    'assets/images/mlwio_logo.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.movie,
                        color: Colors.white,
                        size: 20,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'MLWIO',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                          if (item.releaseYear != null) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                '•',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                            ),
                            Text(
                              '${item.releaseYear}',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.more_vert,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HoverableContentCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _HoverableContentCard({
    required this.child,
    required this.onTap,
  });

  @override
  State<_HoverableContentCard> createState() => _HoverableContentCardState();
}

class _HoverableContentCardState extends State<_HoverableContentCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ]
                  : [],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
