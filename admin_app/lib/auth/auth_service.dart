import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase/supabase_config.dart';

class AuthService {
  AuthService._();

  static final SupabaseClient _supabase = SupabaseConfig.client;

  /// تسجيل الدخول بالبريد الإلكتروني أو رقم الهاتف.
  ///
  /// إذا كانت القيمة تحتوي على @ يتم التعامل معها كبريد إلكتروني.
  /// غير ذلك يتم التعامل معها كرقم هاتف.
  static Future<AuthResponse> signIn({
    required String login,
    required String password,
  }) async {
    final value = login.trim();

    if (value.isEmpty) {
      throw const AuthException('يرجى إدخال البريد الإلكتروني أو رقم الهاتف.');
    }

    if (password.isEmpty) {
      throw const AuthException('يرجى إدخال كلمة المرور.');
    }

    if (value.contains('@')) {
      return await _supabase.auth.signInWithPassword(
        email: value,
        password: password,
      );
    }

    return await _supabase.auth.signInWithPassword(
      phone: value,
      password: password,
    );
  }

  /// المستخدم الحالي.
  static User? get currentUser {
    return _supabase.auth.currentUser;
  }

  /// جلب بيانات الملف الشخصي للمستخدم الحالي.
  static Future<Map<String, dynamic>?> getCurrentProfile() async {
    final user = currentUser;

    if (user == null) {
      return null;
    }

    return await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
  }

  /// جلب أدوار المستخدم الحالي.
  static Future<List<Map<String, dynamic>>> getCurrentRoles() async {
    final user = currentUser;

    if (user == null) {
      return [];
    }

    final result = await _supabase
        .from('user_roles')
        .select('role_id, roles(name)')
        .eq('user_id', user.id);

    return List<Map<String, dynamic>>.from(result);
  }

  /// التحقق من أن المستخدم لديه الدور المطلوب.
  static Future<bool> hasRole(String roleName) async {
    final roles = await getCurrentRoles();

    for (final role in roles) {
      final roleData = role['roles'];

      if (roleData is Map &&
          roleData['name']?.toString().toUpperCase() ==
              roleName.toUpperCase()) {
        return true;
      }
    }

    return false;
  }

  /// تسجيل الخروج.
  static Future<void> signOut() async {
    await SupabaseConfig.signOut();
  }
}
