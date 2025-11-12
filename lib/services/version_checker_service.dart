import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:version/version.dart';
import 'package:url_launcher/url_launcher.dart';

class VersionCheckerService {
  static const String versionJsonUrl = 'https://www.dropbox.com/scl/fi/your_file_id/version.json?rlkey=your_key&dl=1';
  
  Future<Map<String, dynamic>?> fetchRemoteVersion() async {
    try {
      final response = await http.get(Uri.parse(versionJsonUrl));
      
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error fetching remote version: $e');
    }
    return null;
  }
  
  Future<String> getLocalVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }
  
  Future<bool> needsUpdate() async {
    try {
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
