import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateChecker {
  static const Color _navy = Color(0xFF0A1931);
  static const Color _cardDark = Color(0xFF1A2744);
  static const Color _lightGold = Color(0xFFE8C765);

  static const String owner = 'ammeralsh86';
  static const String repo = 'sadabay';

  static Future<void> checkForUpdate(
    BuildContext context, {
    bool showNoUpdateMessage = false,
  }) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final settings = await Supabase.instance.client
          .from('app_settings')
          .select()
          .eq('id', 1)
          .maybeSingle();

      if (settings == null) return;

      final latest = (settings['latest_version'] as String?)
          ?.replaceAll('v', '')
          .trim();

      if (latest == null) return;

      final minVersion = ((settings['min_version'] as String?) ?? latest)
          .replaceAll('v', '')
          .trim();

      final apkUrl = (settings['apk_url'] as String?) ??
          'https://github.com/$owner/$repo/releases/latest';

      final notes = (settings['update_notes'] as String?) ??
          'يوجد تحديث جديد يحسن الأداء';

      final forceUpdate = (settings['update_force'] as bool?) ?? false;
      final maintenance = (settings['maintenance_mode'] as bool?) ?? false;

      if (maintenance) {
        if (!context.mounted) return;
        _showMaintenanceDialog(
          context,
          (settings['maintenance_message'] as String?) ??
              'التطبيق تحت الصيانة حالياً',
        );
        return;
      }

      if (_isNewer(latest, currentVersion)) {
        if (!context.mounted) return;
        final isForce = forceUpdate || _isNewer(minVersion, currentVersion);
        _showUpdateDialog(
          context,
          currentVersion,
          latest,
          notes,
          apkUrl,
          isForce,
        );
        return;
      }

      if (showNoUpdateMessage && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('أنت على أحدث إصدار ($currentVersion)'),
            backgroundColor: _lightGold,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (showNoUpdateMessage && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يوجد اتصال للتحقق من التحديث'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  
  
static bool _isNewer(String latest, String current) {
  List<int>? parseVersion(String version) {
    final normalized = version.trim().replaceFirst(
      RegExp(r'^[vV]'),
      '',
    );

    final parts = normalized.split('.');
    if (parts.isEmpty) return null;

    final result = <int>[];
    for (final part in parts) {
      final value = int.tryParse(part);
      if (value == null || value < 0) return null;
      result.add(value);
    }
    return result;
  }

  final latestParts = parseVersion(latest);
  final currentParts = parseVersion(current);

  if (latestParts == null || currentParts == null) {
    return false;
  }

  final length = latestParts.length > currentParts.length
      ? latestParts.length
      : currentParts.length;

  for (var i = 0; i < length; i++) {
    final l = i < latestParts.length ? latestParts[i] : 0;
    final c = i < currentParts.length ? currentParts[i] : 0;

    if (l > c) return true;
    if (l < c) return false;
  }

  return false;
}



  static void _showMaintenanceDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: _cardDark,
          title: const Text(
            'وضع الصيانة',
            style: TextStyle(
              color: _lightGold,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white70),
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
      barrierDismissible: !force,
      builder: (ctx) => PopScope(
        canPop: !force,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: _cardDark,
            title: Text(
              force ? 'تحديث إجباري!' : 'تحديث جديد متاح!',
              style: const TextStyle(
                color: _lightGold,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الحالي: $current -> الجديد: $latest',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _navy,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    notes,
                    style: constTextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
            actions: [
              if (!force)
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'لاحقاً',
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _lightGold,
                ),
                onPressed: () async {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
                icon: const Icon(Icons.download_rounded, color: _navy),
                label: const Text(
                  'تحديث الآن',
                  style: const TextStyle(color: Colors.white70),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
