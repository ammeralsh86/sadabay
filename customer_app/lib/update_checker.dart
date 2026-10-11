import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart';

class UpdateChecker {
  static const String owner = "ammeralsh86";
  static const String repo = "sadabay";

  static Future<void> checkForUpdate(
    BuildContext context, {
    bool showNoUpdateMessage = false,
  }) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final supabase = Supabase.instance.client;
      final settings = await supabase
         .from('app_settings')
         .select()
         .eq('id', 1)
         .maybeSingle();

      if (settings!= null && settings['latest_version']!= null) {
        final latest = (settings['latest_version'] as String)
           .replaceAll('v', '');
        final minVersion = ((settings['min_version'] as String?)?? latest)
           .replaceAll('v', '');
        final apkUrl = (settings['apk_url'] as String?)??
            'https://github.com/$owner/$repo/releases/latest';
        final notes = (settings['update_notes'] as String?)??
            'يوجد تحديث جديد يحسن الأداء.';
        final forceUpdate = (settings['update_force'] as bool?)?? false;
        final maintenance = (settings['maintenance_mode'] as bool?)?? false;

        if (maintenance) {
          if (!context.mounted) return;
          _showMaintenanceDialog(
            context,
            settings['maintenance_message'] as String???
                'التطبيق تحت الصيانة',
          );
          return;
        }

        if (_isNewer(latest, currentVersion)) {
          if (!context.mounted) return;
          final isForce =
              forceUpdate || _isNewer(minVersion, currentVersion);
          _showUpdateDialog(
            context,
            currentVersion,
            latest,
            notes,
            apkUrl,
            isForce,
          );
          return;
        } else {
          if (showNoUpdateMessage && context.mounted) {
            _showSnack(context, 'أنت على أحدث إصدار $currentVersion ✅');
          }
          return;
        }
      }

      await _checkFromGitHub(context, currentVersion, showNoUpdateMessage);
    } catch (e) {
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        await _checkFromGitHub(
          context,
          packageInfo.version,
          showNoUpdateMessage,
        );
      } catch (_) {
        if (showNoUpdateMessage && context.mounted) {
          _showSnack(context, 'لا يوجد اتصال للتحقق من التحديث.');
        }
      }
    }
  }

  static Future<void> _checkFromGitHub(
    BuildContext context,
    String currentVersion,
    bool showNoUpdateMessage,
  ) async {
    final url = Uri.parse(
      'https://api.github.com/repos/$owner/$repo/releases/latest',
    );
    final res = await http.get(url);
    if (res.statusCode!= 200) return;

    final data = jsonDecode(res.body);
    final latestTag = (data['tag_name'] as String).replaceAll('v', '');
    final releaseNotes = data['body']?? 'يوجد تحديث جديد';
    final downloadUrl = data['html_url']??
        'https://github.com/$owner/$repo/releases/latest';

    String? apkUrl;
    if (data['assets']!= null && (data['assets'] as List).isNotEmpty) {
      try {
        final apkAsset = (data['assets'] as List).firstWhere(
          (a) => (a['name'] as String).endsWith('.apk'),
        );
        apkUrl = apkAsset['browser_download_url'] as String?;
      } catch (_) {}
    }

    if (_isNewer(latestTag, currentVersion) && context.mounted) {
      _showUpdateDialog(
        context,
        currentVersion,
        latestTag,
        releaseNotes,
        apkUrl?? downloadUrl,
        false,
      );
    } else if (showNoUpdateMessage && context.mounted) {
      _showSnack(context, 'أنت على أحدث إصدار $currentVersion ✅');
    }
  }

  static bool _isNewer(String latest, String current) {
    try {
      final l = latest.split('.').map(int.parse).toList();
      final c = current.split('.').map(int.parse).toList();
      for (int i = 0; i < l.length; i++) {
        if (i >= c.length) return true;
        if (l[i] > c[i]) return true;
        if (l[i] < c[i]) return false;
      }
      return false;
    } catch (_) {
      return latest!= current;
    }
  }

  static void _showSnack(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: GoogleFonts.cairo(color: navy),
        ),
        backgroundColor: lightGold,
      ),
    );
  }

  static void _showMaintenanceDialog(
    BuildContext context,
    String message,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'وضع الصيانة 🛠️',
            style: GoogleFonts.cairo(
              color: lightGold,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            style: GoogleFonts.cairo(color: Colors.white70),
          ),
        ),
      ),
    );
  }

  static void _showUpdateDialog(
    BuildContext context,
    String current,
    String latest,
    String notes,
    String url,
    bool force,
  ) {
    showDialog(
      context: context,
      barrierDismissible:!force,
      builder: (ctx) => PopScope(
        canPop:!force,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: cardDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: lightGold,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.system_update_rounded,
                    color: navy,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    force? 'تحديث إجباري!' : 'تحديث جديد متاح!',
                    style: GoogleFonts.cairo(
                      color: lightGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
