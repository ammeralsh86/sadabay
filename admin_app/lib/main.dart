
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const green = Color(0xFF0D5C4A);
const deepGreen = Color(0xFF073B32);
const gold = Color(0xFFC89B3C);
const bg = Color(0xFFF3F6F5);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_KEY');

  if (url.isEmpty || key.isEmpty) {
    runApp(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            'إعدادات Supabase غير موجودة.\n'
            'أضف SUPABASE_URL و SUPABASE_KEY إلى إعدادات البناء.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ));
    return;
  }

  await Supabase.initialize(url: url, anonKey: key);
  runApp(const MadaPayAdmin());
}

final db = Supabase.instance.client;

class MadaPayAdmin extends StatelessWidget {
  const MadaPayAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مدى باي - الإدارة',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(seedColor: green),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: deepGreen,
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const LoginPage(),
    );
  }
}

// ------------------------------------------------------------
// أدوات مساعدة
// ------------------------------------------------------------

void message(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text, textDirection: TextDirection.rtl),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

String readable(dynamic value) {
  if (value == null) return '—';
  if (value is Map || value is List) return value.toString();
  return value.toString();
}

String arabicRole(String role) {
  switch (role.toUpperCase()) {
    case 'OWNER':
      return 'المالك الرئيسي';
    case 'ADMIN':
      return 'مدير النظام';
    case 'MANAGER':
      return 'مدير';
    case 'EMPLOYEE':
      return 'موظف';
    case 'AGENT':
      return 'وكيل';
    case 'DISTRIBUTOR':
      return 'موزع';
    case 'CUSTOMER':
      return 'عميل';
    default:
      return role;
  }
}

// ------------------------------------------------------------
// تسجيل الدخول والتحقق من الحساب والدور
// ------------------------------------------------------------

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final loginController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool obscure = true;

  @override
  void dispose() {
    loginController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final login = loginController.text.trim();
    final password = passwordController.text;

    if (login.isEmpty || password.isEmpty) {
      message(context, 'أدخل بيانات تسجيل الدخول');
      return;
    }

    setState(() => loading = true);

    try {
      AuthResponse response;

      if (login.contains('@')) {
        response = await db.auth.signInWithPassword(
          email: login,
          password: password,
        );
      } else {
        response = await db.auth.signInWithPassword(
          phone: login,
          password: password,
        );
      }

      final user = response.user;
      if (user == null) throw Exception('تعذر التحقق من الحساب');

      final profile = await db
          .from('profiles')
          .select('id, full_name, status')
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) {
        await db.auth.signOut();
        throw Exception('لا يوجد ملف مستخدم مرتبط بهذا الحساب');
      }

      if (profile['status']?.toString().toUpperCase() != 'ACTIVE') {
        await db.auth.signOut();
        throw Exception('الحساب غير مفعل');
      }

      final rows = await db
          .from('user_roles')
          .select('role_id, roles(name)')
          .eq('user_id', user.id);

      final roleNames = <String>[];

      for (final row in rows) {
        final relation = row['roles'];
        if (relation is Map && relation['name'] != null) {
          roleNames.add(relation['name'].toString().toUpperCase());
        }
      }

      const allowed = {
        'OWNER',
        'ADMIN',
        'MANAGER',
        'EMPLOYEE',
        'AGENT',
        'DISTRIBUTOR',
      };

      final matched = roleNames.where(allowed.contains).toList();

      if (matched.isEmpty) {
        await db.auth.signOut();
        throw Exception('هذا الحساب لا يملك دورًا إداريًا');
      }

      // لا نعطي أولوية عشوائية لدور أقل إذا كان الحساب مالكًا.
      final role = matched.contains('OWNER')
          ? 'OWNER'
          : matched.contains('ADMIN')
              ? 'ADMIN'
              : matched.first;

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AdminShell(
            name: readable(profile['full_name']),
            role: role,
          ),
        ),
      );
    } on AuthException catch (e) {
      if (mounted) message(context, e.message);
    } catch (e) {
      if (mounted) {
        message(context, e.toString().replaceFirst('Exception: ', ''));
      }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final loginController = TextEditingController();
  final passwordController = TextEditingController();

  static const navy = Color(0xFF0A1931);
  static const navyLight = Color(0xFF121E3B);
  static const cardDark = Color(0xFF1A2744);
  static const gold = Color(0xFFD4AF37);
  static const lightGold = Color(0xFFE8C765);
  static const mutedGold = Color(0xFFB89A5A);

  bool loading = false;
  bool obscure = true;

  @override
  void dispose() {
    loginController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final loginValue = loginController.text.trim();
    final password = passwordController.text;

    if (loginValue.isEmpty || password.isEmpty) {
      message(context, 'أدخل اسم المستخدم أو البريد الإلكتروني أو الهاتف وكلمة المرور');
      return;
    }

    setState(() => loading = true);

    try {
      AuthResponse response;

      if (loginValue.contains('@')) {
        response = await db.auth.signInWithPassword(
          email: loginValue,
          password: password,
        );
      } else {
        // تسجيل الدخول برقم الهاتف أو باسم المستخدم.
        // Supabase لا يدعم اسم المستخدم مباشرة؛ سنحاول الهاتف أولاً.
        response = await db.auth.signInWithPassword(
          phone: loginValue,
          password: password,
        );
      }

      final user = response.user;
      if (user == null) throw Exception('تعذر التحقق من الحساب');

      final profile = await db
          .from('profiles')
          .select('id, full_name, status')
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) {
        await db.auth.signOut();
        throw Exception('لا يوجد ملف مستخدم مرتبط بهذا الحساب');
      }

      if (profile['status']?.toString().toUpperCase() != 'ACTIVE') {
        await db.auth.signOut();
        throw Exception('الحساب غير مفعل');
      }

      final rows = await db
          .from('user_roles')
          .select('role_id, roles(name)')
          .eq('user_id', user.id);

      final roleNames = <String>[];

      for (final row in rows) {
        final relation = row['roles'];
        if (relation is Map && relation['name'] != null) {
          roleNames.add(relation['name'].toString().toUpperCase());
        }
      }

      const allowed = {
        'OWNER',
        'ADMIN',
        'MANAGER',
        'EMPLOYEE',
        'AGENT',
        'DISTRIBUTOR',
      };

      final matched = roleNames.where(allowed.contains).toList();

      if (matched.isEmpty) {
        await db.auth.signOut();
        throw Exception('هذا الحساب لا يملك دورًا إداريًا');
      }

      final role = matched.contains('OWNER')
          ? 'OWNER'
          : matched.contains('ADMIN')
              ? 'ADMIN'
              : matched.first;

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AdminShell(
            name: readable(profile['full_name']),
            role: role,
          ),
        ),
      );
    } on AuthException catch (e) {
      if (mounted) message(context, e.message);
    } catch (e) {
      if (mounted) {
        message(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  InputDecoration fieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: mutedGold),
      prefixIcon: Icon(icon, color: lightGold),
      suffixIcon: suffix,
      filled: true,
      fillColor: cardDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: gold.withOpacity(0.35)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: gold.withOpacity(0.35)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: lightGold, width: 1.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [navy, Color(0xFF0A1525), navyLight],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),

                      // الشعار الذهبي
                      Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [lightGold, gold],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: gold.withOpacity(0.24),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 58,
                          color: navy,
                        ),
                      ),

                      const SizedBox(height: 22),

                      const Text(
                        'وكالة مدى باي',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: lightGold,
                          letterSpacing: 0.5,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'لخدمات الدفع الرقمية الحديثة',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: gold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        'وشحن الرصيد والتطبيقات والألعاب',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: mutedGold,
                        ),
                      ),

                      const SizedBox(height: 32),

                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF101D35),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: gold.withOpacity(0.45),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.20),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'تسجيل دخول الإدارة',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: lightGold,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            const SizedBox(height: 8),

                            const Text(
                              'مرحبًا بك في لوحة التحكم الخاصة بوكالة مدى باي',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: mutedGold,
                                fontSize: 13,
                              ),
                            ),

                            const SizedBox(height: 26),

                            TextField(
                              controller: loginController,
                              textDirection: TextDirection.ltr,
                              keyboardType: TextInputType.text,
                              style: const TextStyle(color: Colors.white),
                              decoration: fieldDecoration(
                                label: 'البريد الإلكتروني أو رقم الهاتف',
                                icon: Icons.person_outline_rounded,
                              ),
                            ),

                            const SizedBox(height: 16),

                            TextField(
                              controller: passwordController,
                              obscureText: obscure,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(color: Colors.white),
                              decoration: fieldDecoration(
                                label: 'كلمة المرور',
                                icon: Icons.lock_outline_rounded,
                                suffix: IconButton(
                                  onPressed: () {
                                    setState(() => obscure = !obscure);
                                  },
                                  icon: Icon(
                                    obscure
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: lightGold,
                                  ),
                                ),
                              ),
                              onSubmitted: (_) => login(),
                            ),

                            const SizedBox(height: 24),

                            Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [lightGold, gold],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: gold.withOpacity(0.20),
                                    blurRadius: 14,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: FilledButton.icon(
                                onPressed: loading ? null : login,
                                icon: loading
                                    ? const SizedBox(
                                        width: 19,
                                        height: 19,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: navy,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.login_rounded,
                                        color: navy,
                                      ),
                                label: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  child: Text(
                                    loading
                                        ? 'جارٍ التحقق من الحساب...'
                                        : 'تسجيل الدخول',
                                    style: const TextStyle(
                                      color: navy,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  disabledBackgroundColor:
                                      Colors.white24,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            const Text(
                              'بوابة الإدارة الآمنة',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: mutedGold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      const Text(
                        'وكالة مدى باي ©',
                        style: TextStyle(
                          color: mutedGold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// ------------------------------------------------------------
// القائمة الإدارية والواجهة الاحترافية
// ------------------------------------------------------------

class AdminShell extends StatefulWidget {
  final String name;
  final String role;

  const AdminShell({
    super.key,
    required this.name,
    required this.role,
  });

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int selected = 0;

  final sections = const [
    ('الرئيسية', Icons.dashboard_rounded),
    ('طلبات التسجيل', Icons.pending_actions_rounded),
    ('المستخدمون', Icons.people_alt_rounded),
    ('الأرصدة', Icons.account_balance_wallet_rounded),
    ('التحويلات', Icons.swap_horiz_rounded),
    ('الخدمات والأسعار', Icons.apps_rounded),
    ('التقارير', Icons.bar_chart_rounded),
  ];

  bool get isOwner => widget.role == 'OWNER';
  bool get isAdmin => isOwner || widget.role == 'ADMIN';

  Future<void> logout() async {
    await db.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  Widget currentPage() {
    switch (selected) {
      case 0:
        return DashboardPage(
          name: widget.name,
          role: widget.role,
          onOpen: (index) => setState(() => selected = index),
        );
      case 1:
        return const DataPage(
          title: 'طلبات التسجيل',
          table: 'registration_requests',
          icon: Icons.pending_actions_rounded,
        );
      case 2:
        return const DataPage(
          title: 'المستخدمون',
          table: 'profiles',
          icon: Icons.people_alt_rounded,
        );
      case 3:
        return const BalancePage();
      case 4:
        return const DataPage(
          title: 'التحويلات والمعاملات',
          table: 'transactions',
          icon: Icons.swap_horiz_rounded,
          filterOwnTransactions: true,
        );
      case 5:
        return const DataPage(
          title: 'الخدمات والأسعار',
          table: 'services',
          icon: Icons.apps_rounded,
        );
      default:
        return const ReportsPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 850;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'مدى باي',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Center(
                child: Text(
                  arabicRole(widget.role),
                  style: const TextStyle(
                    color: green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'تسجيل الخروج',
              onPressed: logout,
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
        ),
        drawer: wide ? null : Drawer(child: buildMenu()),
        body: Row(
          children: [
            if (wide)
              SizedBox(width: 265, child: buildMenu()),
            Expanded(child: currentPage()),
          ],
        ),
      ),
    );
  }

  Widget buildMenu() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 25),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [deepGreen, green],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 27,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.verified_user_rounded, color: green),
                ),
                const SizedBox(height: 14),
                Text(
                  widget.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  arabicRole(widget.role),
                  style: const TextStyle(color: Color(0xFFD9EAE4)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.13),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'لوحة التحكم',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: sections.length,
              itemBuilder: (context, index) {
                final item = sections[index];
                final active = selected == index;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Material(
                    color: active ? const Color(0xFFE4F1ED) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: ListTile(
                      leading: Icon(
                        item.$2,
                        color: active ? green : Colors.blueGrey,
                      ),
                      title: Text(
                        item.$1,
                        style: TextStyle(
                          color: active ? deepGreen : Colors.black87,
                          fontWeight:
                              active ? FontWeight.w800 : FontWeight.normal,
                        ),
                      ),
                      trailing: active
                          ? const Icon(Icons.chevron_left, color: gold)
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      onTap: () {
                        setState(() => selected = index);
                        if (MediaQuery.of(context).size.width < 850) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('تسجيل الخروج'),
            onTap: logout,
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// الصفحة الرئيسية - إحصائيات من قاعدة البيانات
// ------------------------------------------------------------

class DashboardPage extends StatefulWidget {
  final String name;
  final String role;
  final ValueChanged<int> onOpen;

  const DashboardPage({
    super.key,
    required this.name,
    required this.role,
    required this.onOpen,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool loading = true;
  String? error;
  int users = 0;
  int transactions = 0;
  int requests = 0;
  int services = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<int> countRows(String table) async {
    final result = await db.from(table).select('id');
    return result.length;
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final values = await Future.wait([
        countRows('profiles'),
        countRows('transactions'),
        countRows('registration_requests'),
        countRows('services'),
      ]);

      if (!mounted) return;
      setState(() {
        users = values[0];
        transactions = values[1];
        requests = values[2];
        services = values[3];
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'تعذر تحميل الإحصائيات. تحقق من اتصال قاعدة البيانات والصلاحيات.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(23),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [green, deepGreen],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22304D44),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'لوحة التحكم الرئيسية',
                  style: TextStyle(color: Color(0xFFD5E8E1)),
                ),
                const SizedBox(height: 10),
                Text(
                  'مرحبًا، ${widget.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'الدور: ${arabicRole(widget.role)}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 18),
                const Row(
                  children: [
                    Icon(Icons.shield_rounded, color: gold),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'إدارة مدى باي',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'ملخص النظام',
            style: TextStyle(
              color: deepGreen,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (loading)
            const Padding(
              padding: EdgeInsets.all(25),
              child: Center(child: CircularProgressIndicator(color: green)),
            )
          else if (error != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.error_outline, color: Colors.red),
                title: Text(error!),
                trailing: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: load,
                ),
              ),
            )
          else
            GridView.count(
              crossAxisCount:
                  MediaQuery.of(context).size.width > 650 ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.22,
              children: [
                StatCard('المستخدمون', '$users', Icons.people_alt, green),
                StatCard(
                  'المعاملات',
                  '$transactions',
                  Icons.swap_horiz,
                  const Color(0xFF3576B8),
                ),
                StatCard(
                  'طلبات التسجيل',
                  '$requests',
                  Icons.pending_actions,
                  const Color(0xFFB47B20),
                ),
                StatCard(
                  'الخدمات',
                  '$services',
                  Icons.apps,
                  const Color(0xFF7456A8),
                ),
              ],
            ),
          const SizedBox(height: 24),
          const Text(
            'الوصول السريع',
            style: TextStyle(
              color: deepGreen,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          QuickButton(
            title: 'طلبات التسجيل',
            subtitle: 'عرض الطلبات الواردة ومراجعتها',
            icon: Icons.assignment_turned_in_rounded,
            color: const Color(0xFFB47B20),
            onTap: () => widget.onOpen(1),
          ),
          QuickButton(
            title: 'إدارة المستخدمين',
            subtitle: 'عرض الحسابات المسجلة',
            icon: Icons.people_alt_rounded,
            color: green,
            onTap: () => widget.onOpen(2),
          ),
          QuickButton(
            title: 'المعاملات والتحويلات',
            subtitle: 'مراجعة سجلات المعاملات',
            icon: Icons.swap_horiz_rounded,
            color: const Color(0xFF3576B8),
            onTap: () => widget.onOpen(4),
          ),
          QuickButton(
            title: 'الخدمات والأسعار',
            subtitle: 'عرض الخدمات المسجلة',
            icon: Icons.apps_rounded,
            color: const Color(0xFF7456A8),
            onTap: () => widget.onOpen(5),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: load,
            icon: const Icon(Icons.refresh),
            label: const Text('تحديث بيانات لوحة التحكم'),
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard(this.title, this.value, this.icon, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7ECE9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(.12),
            child: Icon(icon, color: color),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: deepGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

class QuickButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const QuickButton({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 11),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE7ECE9)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(.72)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(.18),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: deepGreen,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_back_ios_new, size: 16, color: gold),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// صفحات البيانات الفعلية: profiles / transactions / services
// / registration_requests
// ------------------------------------------------------------

class DataPage extends StatefulWidget {
  final String title;
  final String table;
  final IconData icon;
  final bool filterOwnTransactions;

  const DataPage({
    super.key,
    required this.title,
    required this.table,
    required this.icon,
    this.filterOwnTransactions = false,
  });

  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> rows = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      dynamic result;

      if (widget.filterOwnTransactions) {
        final id = db.auth.currentUser?.id;
        if (id == null) throw Exception('انتهت جلسة الدخول');

        result = await db
            .from(widget.table)
            .select()
            .eq('user_id', id)
            .order('created_at', ascending: false)
            .limit(100);
      } else if (widget.table == 'transactions') {
        result = await db
            .from(widget.table)
            .select()
            .order('created_at', ascending: false)
            .limit(100);
      } else if (widget.table == 'registration_requests') {
        result = await db
            .from(widget.table)
            .select()
            .limit(100);
      } else {
        result = await db.from(widget.table).select().limit(100);
      }

      if (!mounted) return;
      setState(() {
        rows = List<Map<String, dynamic>>.from(result);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'تعذر تحميل البيانات. قد تكون صلاحيات القراءة غير متاحة.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [green, deepGreen]),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Icon(widget.icon, color: gold, size: 34),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'البيانات المحمّلة من قاعدة البيانات',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: load,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (loading)
            const Padding(
              padding: EdgeInsets.all(35),
              child: Center(child: CircularProgressIndicator(color: green)),
            )
          else if (error != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.error_outline, color: Colors.red),
                title: Text(error!),
                trailing: IconButton(
                  onPressed: load,
                  icon: const Icon(Icons.refresh),
                ),
              ),
            )
          else if (rows.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(25),
                child: Text(
                  'لا توجد سجلات ظاهرة، أو أن سياسات قاعدة البيانات تمنع قراءتها.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else ...[
            Text(
              'عدد السجلات المعروضة: ${rows.length}',
              style: const TextStyle(
                color: deepGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            for (final row in rows) _recordCard(row),
          ],
        ],
      ),
    );
  }

  Widget _recordCard(Map<String, dynamic> row) {
    final preferred = [
      'full_name',
      'name',
      'phone',
      'email',
      'status',
      'account_type',
      'requested_role',
      'amount',
      'total_amount',
      'fee',
      'commission',
      'service_id',
      'user_id',
      'created_at',
      'id',
    ];

    final keys = <String>[
      ...preferred.where(row.containsKey),
      ...row.keys.where((k) => !preferred.contains(k)),
    ];

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 11),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: const BorderSide(color: Color(0xFFE5ECE8)),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE4F1ED),
          child: Icon(widget.icon, color: green),
        ),
        title: Text(
          readable(
            row['full_name'] ??
                row['name'] ??
                row['phone'] ??
                row['id'],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: deepGreen,
          ),
        ),
        subtitle: Text(
          'الحالة: ${readable(row['status'])}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        children: [
          const Divider(height: 1),
          for (final key in keys)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 7, 16, 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 125,
                    child: Text(
                      key,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: green,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SelectableText(readable(row[key])),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// الأرصدة: عرض فقط، دون تعديل مالي غير آمن
// ------------------------------------------------------------

class BalancePage extends StatefulWidget {
  const BalancePage({super.key});

  @override
  State<BalancePage> createState() => _BalancePageState();
}

class _BalancePageState extends State<BalancePage> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> profiles = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await db
          .from('profiles')
          .select('id, full_name, status, balance')
          .limit(200);

      if (!mounted) return;
      setState(() {
        profiles = List<Map<String, dynamic>>.from(data);
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'تعذر قراءة الأرصدة. تحقق من سياسة القراءة المسموح بها.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [green, deepGreen]),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_rounded,
                  color: gold,
                  size: 34,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'أرصدة المستخدمين',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 21,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'هذه الصفحة للعرض فقط. تعديل الرصيد يجب أن يتم '
                'من خلال إجراء مالي خادمي موثوق يسجل العملية ويمنع التلاعب.',
              ),
            ),
          ),
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: CircularProgressIndicator(color: green),
              ),
            )
          else if (error != null)
            ListTile(
              title: Text(error!),
              trailing: IconButton(
                onPressed: load,
                icon: const Icon(Icons.refresh),
              ),
            )
          else if (profiles.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('لا توجد سجلات متاحة.'),
            )
          else
            for (final p in profiles)
              Card(
                color: Colors.white,
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE4F1ED),
                    child: Icon(
                      Icons.account_balance_wallet,
                      color: green,
                    ),
                  ),
                  title: Text(readable(p['full_name'])),
                  subtitle: Text(
                    'الحالة: ${readable(p['status'])}\n'
                    'معرّف الحساب: ${readable(p['id'])}',
                  ),
                  isThreeLine: true,
                  trailing: Text(
                    readable(p['balance']),
                    style: const TextStyle(
                      color: green,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// التقارير - أعداد حقيقية ضمن ما تسمح به RLS
// ------------------------------------------------------------

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  bool loading = true;
  String? error;
  Map<String, int> totals = {};

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<int> count(String table) async {
    final result = await db.from(table).select('id');
    return result.length;
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final results = await Future.wait([
        count('profiles'),
        count('transactions'),
        count('registration_requests'),
        count('services'),
      ]);

      if (!mounted) return;
      setState(() {
        totals = {
          'المستخدمون': results[0],
          'المعاملات': results[1],
          'طلبات التسجيل': results[2],
          'الخدمات': results[3],
        };
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'تعذر إنشاء التقرير بسبب الاتصال أو صلاحيات القراءة.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'التقارير والإحصائيات',
            style: TextStyle(
              fontSize: 24,
              color: deepGreen,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: CircularProgressIndicator(color: green),
              ),
            )
          else if (error != null)
            Card(
              child: ListTile(
                title: Text(error!),
                trailing: IconButton(
                  onPressed: load,
                  icon: const Icon(Icons.refresh),
                ),
              ),
            )
          else
            for (final entry in totals.entries)
              Card(
                color: Colors.white,
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE4F1ED),
                    child: Icon(Icons.bar_chart_rounded, color: green),
                  ),
                  title: Text(entry.key),
                  trailing: Text(
                    '${entry.value}',
                    style: const TextStyle(
                      color: green,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          const SizedBox(height: 10),
          const Text(
            'تعكس هذه الأعداد السجلات التي تسمح سياسات قاعدة البيانات '
            'للحساب الحالي بقراءتها؛ وليست بالضرورة إجمالي سجلات النظام.',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
