import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../services/mini_player_service.dart';
import 'watch_history_screen.dart';
import 'downloads_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(AppColors.cardValue),
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final miniPlayerService = MiniPlayerService();
      miniPlayerService.close();
      
      final authService = AuthService();
      await authService.signOut();
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;
    final googleUser = authService.currentGoogleUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(AppColors.accentValue),
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  child: user?.photoURL == null
                      ? const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  user?.displayName ?? googleUser?.displayName ?? 'Guest User',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(AppColors.textValue),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user?.email ?? googleUser?.email ?? 'Sign in to access more features',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(AppColors.textMutedValue),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildSection('Account', [
            _buildListTile(
              Icons.person_outline,
              'Edit Profile',
              'Update your profile information',
              onTap: () => _showComingSoon(context, 'Edit Profile'),
            ),
            _buildListTile(
              Icons.lock_outline,
              'Privacy Settings',
              'Manage your privacy preferences',
              onTap: () => _showComingSoon(context, 'Privacy Settings'),
            ),
          ]),
          const SizedBox(height: 16),
          _buildSection('Content', [
            _buildListTile(
              Icons.download_outlined,
              'Downloads',
              'View your offline content',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DownloadsScreen(),
                  ),
                );
              },
            ),
            _buildListTile(
              Icons.history,
              'Watch History',
              'See what you\'ve watched',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WatchHistoryScreen(),
                  ),
                );
              },
            ),
          ]),
          const SizedBox(height: 16),
          _buildSection('Support', [
            _buildListTile(
              Icons.help_outline,
              'Help & Support',
              'Get help with the app',
              onTap: () => _showComingSoon(context, 'Help & Support'),
            ),
            _buildListTile(
              Icons.info_outline,
              'About',
              'App version and information',
              onTap: () => _showAboutDialog(context),
            ),
          ]),
          const SizedBox(height: 16),
          if (user != null)
            _buildSection('', [
              _buildListTile(
                Icons.logout,
                'Logout',
                'Sign out of your account',
                onTap: () => _handleLogout(context),
                textColor: Colors.red,
              ),
            ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(AppColors.textValue),
            ),
          ),
        ),
        Card(
          color: const Color(AppColors.cardValue),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildListTile(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? const Color(AppColors.textValue)),
      title: Text(
        title,
        style: TextStyle(color: textColor ?? const Color(AppColors.textValue)),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Color(AppColors.textMutedValue)),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Color(AppColors.textMutedValue),
      ),
      onTap: onTap,
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(AppColors.cardValue),
        title: const Text('Coming Soon', style: TextStyle(color: Colors.white)),
        content: Text(
          '$feature will be available in a future update!',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(AppColors.cardValue),
        title: const Text('About MLWIO', style: TextStyle(color: Colors.white)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version: 1.0.0',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 8),
            Text(
              'MLWIO - Your ultimate streaming platform',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 16),
            Text(
              '© 2024 MLWIO. All rights reserved.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
