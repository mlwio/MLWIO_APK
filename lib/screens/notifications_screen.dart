import 'package:flutter/material.dart';
import '../utils/constants.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildNotification(
            'New Release',
            'Latest anime episode is now available!',
            '2 hours ago',
            Icons.movie_outlined,
          ),
          _buildNotification(
            'Download Complete',
            'Your video has been downloaded successfully',
            '1 day ago',
            Icons.download_done,
          ),
          _buildNotification(
            'Premium Offer',
            'Get 30% off on Premium subscription',
            '2 days ago',
            Icons.diamond_outlined,
          ),
          _buildNotification(
            'New Content',
            '5 new movies added to your favorites',
            '3 days ago',
            Icons.video_library_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildNotification(
    String title,
    String subtitle,
    String time,
    IconData icon,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(AppColors.cardValue),
      child: ListTile(
        leading: CircleAvatar(
          // ignore: deprecated_member_use
          backgroundColor: const Color(AppColors.accentValue).withOpacity(0.2),
          child: Icon(
            icon,
            color: const Color(AppColors.accentValue),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(AppColors.textValue),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(AppColors.textValue),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: const TextStyle(
                fontSize: 12,
                color: Color(AppColors.textMutedValue),
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
