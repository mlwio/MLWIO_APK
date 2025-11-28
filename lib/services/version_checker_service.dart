import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:version/version.dart';
import 'package:url_launcher/url_launcher.dart';

class VersionCheckerService {
  Future<Map<String, dynamic>?> fetchRemoteVersion() async {
    try {
      if (kIsWeb) {
        return null;
      }
      
      final response = await http.get(
        Uri.parse('https://api.movieway.site/api/version'),
      ).timeout(
        const Duration(seconds: 3),
      );
      
      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.startsWith('{')) {
          return json.decode(body) as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('Error fetching remote version: $e');
    }
    return null;
  }
  
  Future<String> getLocalVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      debugPrint('Error getting local version: $e');
      return '1.0.0';
    }
  }
  
  Future<bool> needsUpdate() async {
    try {
      if (kIsWeb) {
        return false;
      }
      
      final localVersion = await getLocalVersion();
      final remoteData = await fetchRemoteVersion();
      
      if (remoteData == null || !remoteData.containsKey('latestVersion')) {
        return false;
      }
      
      final remoteVersion = remoteData['latestVersion'] as String;
      
      final local = Version.parse(localVersion);
      final remote = Version.parse(remoteVersion);
      
      return remote > local;
    } catch (e) {
      debugPrint('Error checking version: $e');
      return false;
    }
  }
  
  void showUpdateDialog(BuildContext context, String downloadUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.system_update, color: Colors.red, size: 32),
                const SizedBox(width: 12),
                const Text(
                  'Update Required',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A new version of MLWIO is available!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Please update to the latest version to continue using the app.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final uri = Uri.parse(downloadUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Update Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Future<void> checkAndShowUpdateIfNeeded(BuildContext context) async {
    if (kIsWeb) return;
    
    final needsUpdateFlag = await needsUpdate();
    
    if (needsUpdateFlag) {
      final remoteData = await fetchRemoteVersion();
      if (remoteData != null && remoteData.containsKey('downloadUrl')) {
        final downloadUrl = remoteData['downloadUrl'] as String;
        if (context.mounted) {
          showUpdateDialog(context, downloadUrl);
        }
      }
    }
  }
}
