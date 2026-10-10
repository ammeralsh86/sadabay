
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase/supabase_config.dart';

/// خدمات المصادقة والتعامل مع بيانات المستخدم والأدوار.
class AuthService {
  AuthService._();

  static SupabaseClient get _client => SupabaseConfig.client;

  /// تسجيل الدخول بالبريد الإلكتروني أو رقم الهاتف.
  static Future<AuthResponse> signIn({
    required String login,
    required String password,
  }) async {
    final value = login.trim();

    if (value.isEmpty || password.isEmpty) {
      throw const AuthException('أدخل بيانات تسجيل الدخول');
    }

    if (value.contains('@')) {
      return _client.auth.signInWithPassword(
        email: value,
        password: password,
      );
    }

    return _client.auth.signInWithPassword(
      phone: value,
      password: password,
    );
  }

  /// المستخدم الحالي.
  static User? get currentUser => _client.auth.currentUser;

  /// جلب ملف المستخدم.
  static Future<Map<String, dynamic>?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;

    return await _client
        .from('profiles')
        .select('full_name, status')
        .eq('id', user.id)
        .maybeSingle();
  }

  /// جلب أدوار المستخدم بالطريقة المستخدمة في الكود الأصلي.
  static Future<List<Map<String, dynamic>>> getCurrentRoles() async {
    final user = currentUser;
    if (user == null) return [];

    final roleRows = await _client
        .from('user_roles')
        .select('role_id')
        .eq('user_id', user.id);

    final roles = <Map<String, dynamic>>[];

    for (final row in roleRows) {
      final role = await _client
          .from('roles')
          .select('name')
          .eq('id', row['role_id'])
          .maybeSingle();

      if (role != null) {
        roles.add({
          'role_id': row['role_id'],
          'name': role['name']?.toString() ?? '',
        });
      }
    }

    return roles;
  }

  /// التحقق من دور معين.
  static Future<bool> hasRole(String roleName) async {
    final roles = await getCurrentRoles();
    final expected = roleName.toUpperCase();

    return roles.any(
      (role) =>
          role['name']?.toString().toUpperCase() == expected,
    );
  }

  /// تسجيل الخروج.
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
