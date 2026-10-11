import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';

class UpdateChecker {
  static const String owner = "ammeralsh86";
  static const String repo = "sadabay";
  
  static Future<void> checkForUpdate(BuildContext context, {bool showNoUpdateMessage = false}) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final url = Uri.parse('https://api.github.com/repos/$owner/$repo/releases/latest');
      final res = await http.get(url);

      if (res.statusCode != 200) {
        if (showNoUpdateMessage && context.mounted) {
          showMessage(context, 'تعذر فحص التحديثات الآن.');
        }
        return;
      }

      final data = jsonDecode(res.body);
      final latestTag = (data['tag_name'] as String).replaceAll('v', '');
      final releaseNotes = data['body'] ?? 'يوجد تحديث جديد يحسن الأداء ويضيف مزايا جديدة.';
      final downloadUrl = data['html_url'] ?? 'https://github.com/$owner/$repo/releases/latest';
      
      String? apkUrl;
      if (data['assets'] != null && (data['assets'] as List).isNotEmpty) {
        try {
          final apkAsset = (data['assets'] as List).firstWhere(
            (a) => (a['name'] as String).endsWith('.apk'),
          );
          apkUrl = apkAsset['browser_download_url'];
        } catch (_) {
          apkUrl = null;
        }
      }

      if (_isNewer(latestTag, currentVersion)) {
        if (!context.mounted) return;
        _showUpdateDialog(context, currentVersion, latestTag, releaseNotes, apkUrl ?? downloadUrl);
      } else {
        if (showNoUpdateMessage && context.mounted) {
          showMessage(context, 'أنت على أحدث إصدار $currentVersion ✅');
        }
      }
    } catch (e) {
      if (showNoUpdateMessage && context.mounted) {
        showMessage(context, 'لا يوجد اتصال للتحقق من التحديث.');
      }
    }
  }

  static bool _isNewer(String latest, String current) {
    try {
      final latestParts = latest.split('.').map(int.parse).toList();
      final currentParts = current.split('.').map(int.parse).toList();
      for (int i = 0; i < latestParts.length; i++) {
        if (i >= currentParts.length) return true;
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return false;
    } catch (_) {
      return latest != current;
    }
  }

  static void _showUpdateDialog(BuildContext context, String current, String latest, String notes, String url) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: lightGold, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.system_update_rounded, color: navy),
              ),
              const SizedBox(width: 12),
              Text('تحديث جديد متاح!', style: GoogleFonts.cairo(color: lightGold, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الإصدار الحالي: $current', style: GoogleFonts.cairo(color: Colors.white54, fontSize: 12)),
              Text('الإصدار الجديد: $latest', style: GoogleFonts.cairo(color: lightGold, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(12)),
                child: Text(notes, style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('لاحقاً', style: GoogleFonts.cairo(color: Colors.white54)),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: lightGold),
              onPressed: () async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.download_rounded, color: navy),
              label: Text('تحديث الآن', style: GoogleFonts.cairo(color: navy, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
