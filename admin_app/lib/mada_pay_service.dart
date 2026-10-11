
import 'package:supabase_flutter/supabase_flutter.dart';

class MadaPayService {
  MadaPayService._();

  static final MadaPayService instance = MadaPayService._();

  final SupabaseClient db = Supabase.instance.client;

  // الحساب الحالي
  User? get currentUser => db.auth.currentUser;

  String? get userId => currentUser?.id;

  // تسجيل الدخول بالبريد الإلكتروني
  Future<void> login({
    required String email,
    required String password,
  }) async {
    await db.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  // تسجيل الخروج
  Future<void> logout() async {
    await db.auth.signOut();
  }

  // ملف المستخدم الحالي
  Future<Map<String, dynamic>?> myProfile() async {
    final id = userId;
    if (id == null) return null;

    return await db
        .from('profiles')
        .select()
        .eq('id', id)
        .maybeSingle();
  }

  // الأدوار المسندة إلى المستخدم الحالي
  Future<List<Map<String, dynamic>>> myRoles() async {
    final id = userId;
    if (id == null) return [];

    final rows = await db
        .from('user_roles')
        .select('role_id, roles(name)')
        .eq('user_id', id);

    return List<Map<String, dynamic>>.from(rows);
  }

  // ملف مستخدم محدد - للإدارة وفق سياسات قاعدة البيانات
  Future<Map<String, dynamic>?> profileById(
    String id,
  ) async {
    return await db
        .from('profiles')
        .select()
        .eq('id', id)
        .maybeSingle();
  }

  // معاملات المستخدم الحالي
  Future<List<Map<String, dynamic>>> myTransactions({
    int limit = 50,
  }) async {
    final id = userId;
    if (id == null) return [];

    final rows = await db
        .from('transactions')
        .select()
        .eq('user_id', id)
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(rows);
  }

  // معاملات النظام - ستُظهر فقط ما تسمح به RLS
  Future<List<Map<String, dynamic>>> allTransactions({
    int limit = 100,
  }) async {
    final rows = await db
        .from('transactions')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(rows);
  }

  // قائمة الخدمات
  Future<List<Map<String, dynamic>>> services() async {
    final rows = await db
        .from('services')
        .select();

    return List<Map<String, dynamic>>.from(rows);
  }

  // طلبات التسجيل - بحسب صلاحيات المستخدم وسياسات RLS
  Future<List<Map<String, dynamic>>> registrationRequests() async {
    final rows = await db
        .from('registration_requests')
        .select()
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows);
  }

  // تحديث بيانات الملف الشخصي غير المالية.
  // صلاحية التعديل يحددها الخادم.
  Future<void> updateMyProfile(
    Map<String, dynamic> values,
  ) async {
    final id = userId;
    if (id == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    await db
        .from('profiles')
        .update(values)
        .eq('id', id);
  }

  // تحديثات لحظية على ملف المستخدم
  Stream<List<Map<String, dynamic>>> watchMyProfile() {
    final id = userId;
    if (id == null) {
      return const Stream.empty();
    }

    return db
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', id);
  }

  // تحديثات لحظية على معاملات المستخدم
  Stream<List<Map<String, dynamic>>> watchMyTransactions() {
    final id = userId;
    if (id == null) {
      return const Stream.empty();
    }

    return db
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('user_id', id)
        .order('created_at');
  }
}
