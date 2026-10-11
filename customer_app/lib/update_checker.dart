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
      final currentVersion = packageInfo.version.trim();

      final settings = await Supabase.instance.client
          .from('app_settings')
          .select(
            'latest_version, min_version, apk_url, update_notes, '
            'update_force, maintenance_mode, maintenance_message',
          )
          .eq('id', 1)
          .maybeSingle();

      if (settings == null) {
        if (showNoUpdateMessage && context.mounted) {
          _showMessage(context, 'إعدادات التحديث غير متوفرة.');
        }
        return;
      }

      final latest = settings['latest_version']?.toString().trim() ?? '';
      if (latest.isEmpty || !_isValidVersion(latest)) {
        if (showNoUpdateMessage && context.mounted) {
          _showMessage(context, 'رقم إصدار التحديث غير صالح.');
        }
        return;
      }

      final minVersion = settings['min_version']?.toString().trim() ?? latest;
      if (!_isValidVersion(minVersion)) {
        if (showNoUpdateMessage && context.mounted) {
          _showMessage(context, 'الحد الأدنى للإصدار غير صالح.');
        }
        return;
      }

      final configuredUrl = settings['apk_url']?.toString().trim();
      final apkUrl = configuredUrl == null || configuredUrl.isEmpty
          ? 'https://github.com/$owner/$repo/releases/latest'
          : configuredUrl;

      final notes = settings['update_notes']?.toString().trim();
      final forceUpdate = settings['update_force'] == true;
      final maintenance = settings['maintenance_mode'] == true;

      if (maintenance) {
        if (!context.mounted) return;
        _showMaintenanceDialog(
          context,
          settings['maintenance_message']?.toString().trim().isNotEmpty == true
              ? settings['maintenance_message'].toString().trim()
              : 'التطبيق تحت الصيانة حالياً.',
        );
        return;
      }

      final isForce = forceUpdate || _isNewer(minVersion, currentVersion);

      if (_isNewer(latest, currentVersion)) {
        if (!context.mounted) return;
        _showUpdateDialog(
          context,
          currentVersion,
          latest,
          notes?.isNotEmpty == true ? notes : 'يوجد تحديث جديد يحسن الأداء.',
          apkUrl,
          isForce,
        );
        return;
      }

      if (isForce) {
        if (!context.mounted) return;
        _showUpdateDialog(
          context,
          currentVersion,
          latest,
          notes?.isNotEmpty == true ? notes : 'يوجد تحديث جديد يحسن الأداء.',
          apkUrl,
          true,
        );
        return;
      }

      if (showNoUpdateMessage && context.mounted) {
        _showMessage(context, 'أنت على أحدث إصدار ($currentVersion)');
      }
    } catch (_) {
      if (showNoUpdateMessage && context.mounted) {
        _showMessage(context, 'تعذر الاتصال للتحقق من التحديث.');
      }
    }
  }

  static bool _isValidVersion(String version) {
    final normalized = version.trim();
    if (normalized.isEmpty) return false;

    final cleaned = normalized
        .replaceFirst(RegExp(r'^[vV]'), '')
        .replaceAll(RegExp(r'[^0-9.]'), '');

    if (cleaned.isEmpty) return false;
    if (cleaned.startsWith('.') || cleaned.endsWith('.')) return false;

    final parts = cleaned.split('.');
    return parts.isNotEmpty && parts.every((p) => int.tryParse(p) != null);
  }

  static List<int> _parseVersionParts(String version) {
    final cleaned = version.trim().replaceFirst(RegExp(r'^[vV]'), '')
        .replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return const [];
    return cleaned.split('.').where((p) => p.isNotEmpty).map(int.parse).toList();
  }

  static bool _isNewer(String latest, String current) {
    if (!_isValidVersion(latest) || !_isValidVersion(current)) return false;

    final latestParts = _parseVersionParts(latest);
    final currentParts = _parseVersionParts(current);

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

  static void _showMessage(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: _cardDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void _showMaintenanceDialog(BuildContext context, String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: PopScope(
          canPop: false,
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
    showDialog<void>(
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
                  'الحالي: $current ← الجديد: $latest',
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
                    style: const TextStyle(color: Colors.white70),
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
                  final uri = Uri.tryParse(url);

                  if (uri == null ||
                      (uri.scheme != 'https' && uri.scheme != 'http') ||
                      uri.host.isEmpty) {
                    if (ctx.mounted) {
                      _showMessage(ctx, 'رابط التحديث غير صالح.');
                    }
                    return;
                  }

                  try {
                    final opened = await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );

                    if (!opened && ctx.mounted) {
                      _showMessage(ctx, 'تعذر فتح رابط التحديث.');
                    }
                  } catch (_) {
                    if (ctx.mounted) {
                      _showMessage(ctx, 'تعذر فتح رابط التحديث.');
                    }
                  }
                },
                icon: const Icon(Icons.download_rounded, color: _navy),
                label: const Text(
                  'تحديث الآن',
                  style: TextStyle(
                    color: _navy,
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
