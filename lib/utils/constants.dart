import 'package:flutter/material.dart';

class AppConstants {
  static const String apiBaseUrl = 'https://api.movieway.site';
  static const int itemsPerPage = 10;
  static const double scrollThreshold = 0.8;
  
  static const Color backgroundColor = Color(0xFF0B0B0D);
  static const Color cardColor = Color(0xFF121214);
  static const Color textColor = Color(0xFFE6E6E6);
  static const Color textMutedColor = Color(0xFF999999);
  static const Color accentColor = Color(0xFFFF0000);
}

class AppColors {
  static const int backgroundValue = 0xFF0B0B0D;
  static const int cardValue = 0xFF121214;
  static const int textValue = 0xFFE6E6E6;
  static const int textMutedValue = 0xFF999999;
  static const int accentValue = 0xFFFF0000;
}

class AppCategories {
  static const List<String> categories = ['All', 'Movie', 'Web-series', 'Anime'];
}
