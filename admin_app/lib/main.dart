import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'update_checker.dart';

// ========= نفس ثيم تطبيق العميل 100% =========
const navy = Color(0xFF0A1931);
const navyLight = Color(0xFF121E3B);
const cardDark = Color(0xFF1A2744);
const gold = Color(0xFFD4AF37);
const lightGold = Color(0xFFE8C765);
const mutedGold = Color(0xFFB89A5A);
const bg = Color(0xFF0A1931);

// للتوافق مع الكود القديم
const green = navy;
const deepGreen = navyLight;

const LinearGradient goldGradient = LinearGradient(
  colors: [Color(0xFFE8C765), Color(0xFFD4AF37)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient backgroundGradient = LinearGradient(
  colors: [Color(0xFF0A1525), Color(0xFF0A1931), Color(0xFF121E3B)],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_KEY');

  if (url.isEmpty || key.isEmpty) {
    runApp(const ConfigErrorApp());
    return;
  }

  await Supabase.initialize(url: url, anonKey: key);
  runApp(const MadaPayAdmin());
}

final db = Supabase.instance.client;

class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: navy,
        body: Center(
          child: Text(
            'إعدادات Supabase غير موجودة',
            style: GoogleFonts.cairo(color: lightGold),
          ),
        ),
      ),
    );
  }
}

class MadaPayAdmin extends StatelessWidget {
  const MadaPayAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مدى باي - الإدارة',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: navy,
        textTheme: GoogleFonts.cairoTextTheme(
          ThemeData.dark().textTheme,
        ),
        colorScheme: const ColorScheme.dark(
          primary: lightGold,
          secondary: gold,
          surface: cardDark,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: navy,
          foregroundColor: lightGold,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.cairo(
            color: lightGold,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cardDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        cardTheme: CardThemeData(
          color: cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: LoginPage(),
      ),
    );
  }
}

void message(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        text,
        textDirection: TextDirection.rtl,
        style: GoogleFonts.cairo(color: navy),
      ),
      backgroundColor: lightGold,
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

// ================= تسجيل الدخول =================
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
    final loginValue = loginController.text.trim();
    final password = passwordController.text;

    if (loginValue.isEmpty || password.isEmpty) {
      message(context, 'أدخل البريد وكلمة المرور');
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
        response = await db.auth.signInWithPassword(
          phone: loginValue,
          password: password,
        );
      }

      final user = response.user;
      if (user == null) throw Exception('تعذر التحقق');

      final profile = await db
          .from('profiles')
          .select('id, full_name, status')
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) {
        await db.auth.signOut();
        throw Exception('لا يوجد ملف مستخدم');
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
        throw Exception('ليس لديك دور إداري');
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
      labelStyle: GoogleFonts.cairo(color: mutedGold),
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: backgroundGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  children: [
                    Container(
                      width: 112,
                      height: 112,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: goldGradient,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x3DD4AF37),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        size: 58,
                        color: navy,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'وكالة مدى باي',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: lightGold,
                      ),
                    ),
                    Text(
                      'لوحة تحكم الإدارة',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
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
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'تسجيل دخول الإدارة',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              color: lightGold,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 26),
                          TextField(
                            controller: loginController,
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(color: Colors.white),
                            decoration: fieldDecoration(
                              label: 'البريد أو الهاتف',
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
                                onPressed: () =>
                                    setState(() => obscure = !obscure),
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
                          FilledButton.icon(
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
                                    ? 'جارٍ التحقق...'
                                    : 'تسجيل الدخول',
                                style: GoogleFonts.cairo(
                                  color: navy,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: lightGold,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ================= القائمة الإدارية =================
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
    ('إعدادات التحديث', Icons.system_update_rounded),
    ('التقارير', Icons.bar_chart_rounded),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        UpdateChecker.checkForUpdate(context);
      }
    });
  }

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
      case 6:
        return const AppSettingsPage();
      default:
        return const ReportsPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 850;

    return Scaffold(
      backgroundColor: navy,
      appBar: AppBar(
        title: Text(
          'مدى باي',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w900,
            color: lightGold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'فحص التحديث',
            onPressed: () => UpdateChecker.checkForUpdate(
              context,
              showNoUpdateMessage: true,
            ),
            icon: const Icon(Icons.system_update, color: lightGold),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Center(
              child: Text(
                arabicRole(widget.role),
                style: GoogleFonts.cairo(
                  color: lightGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'خروج',
            onPressed: logout,
            icon: const Icon(Icons.logout_rounded, color: lightGold),
          ),
        ],
      ),
      drawer: wide
          ? null
          : Drawer(
              backgroundColor: navy,
              child: buildMenu(),
            ),
      body: Row(
        children: [
          if (wide) SizedBox(width: 280, child: buildMenu()),
          Expanded(child: currentPage()),
        ],
      ),
    );
  }

  Widget buildMenu() {
    return Container(
      color: navy,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 25),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [navyLight, navy],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 27,
                  backgroundColor: lightGold,
                  child: Icon(
                    Icons.verified_user_rounded,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  widget.name,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  arabicRole(widget.role),
                  style: GoogleFonts.cairo(color: mutedGold),
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
                    color: active ? cardDark : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: ListTile(
                      leading: Icon(
                        item.$2,
                        color: active ? lightGold : Colors.white54,
                      ),
                      title: Text(
                        item.$1,
                        style: GoogleFonts.cairo(
                          color: active ? lightGold : Colors.white70,
                          fontWeight:
                              active ? FontWeight.w800 : FontWeight.normal,
                        ),
                      ),
                      trailing: active
                          ? const Icon(Icons.chevron_left, color: gold)
                          : null,
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
          const Divider(color: Color(0x33D4AF37)),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: Text(
              'تسجيل الخروج',
              style: GoogleFonts.cairo(color: Colors.white),
            ),
            onTap: logout,
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// ================= Dashboard =================
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
        error = 'تعذر تحميل الإحصائيات';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: load,
      color: lightGold,
      backgroundColor: cardDark,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(23),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [navyLight, navy],
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: const Color(0x33D4AF37)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحبًا، ${widget.name}',
                  style: GoogleFonts.cairo(
                    color: lightGold,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'الدور: ${arabicRole(widget.role)}',
                  style: GoogleFonts.cairo(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'ملخص النظام',
            style: GoogleFonts.cairo(
              color: lightGold,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (loading)
            const Center(
              child: CircularProgressIndicator(color: lightGold),
            )
          else if (error != null)
            Card(
              child: ListTile(
                title: Text(error!, style: GoogleFonts.cairo()),
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
                StatCard('المستخدمون', '$users', Icons.people_alt, lightGold),
                StatCard(
                  'المعاملات',
                  '$transactions',
                  Icons.swap_horiz,
                  const Color(0xFF5BA4E5),
                ),
                StatCard(
                  'طلبات التسجيل',
                  '$requests',
                  Icons.pending_actions,
                  const Color(0xFFE8C765),
                ),
                StatCard(
                  'الخدمات',
                  '$services',
                  Icons.apps,
                  const Color(0xFF9B8AF4),
                ),
              ],
            ),
          const SizedBox(height: 24),
          Text(
            'الوصول السريع',
            style: GoogleFonts.cairo(
              color: lightGold,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          QuickButton(
            title: 'طلبات التسجيل',
            subtitle: 'مراجعة الطلبات',
            icon: Icons.assignment_turned_in_rounded,
            color: const Color(0xFFB47B20),
            onTap: () => widget.onOpen(1),
          ),
          QuickButton(
            title: 'إدارة المستخدمين',
            subtitle: 'عرض الحسابات',
            icon: Icons.people_alt_rounded,
            color: navyLight,
            onTap: () => widget.onOpen(2),
          ),
          QuickButton(
            title: 'إعدادات التحديث',
            subtitle: 'التحكم بنسخة العميل',
            icon: Icons.system_update_rounded,
            color: gold,
            onTap: () => widget.onOpen(6),
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
        color: cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x22D4AF37)),
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
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: lightGold,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.cairo(color: Colors.white54),
          ),
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
      color: cardDark,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 11),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0x1AD4AF37)),
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
                ),
                child: Icon(icon, color: navy, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        color: lightGold,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.cairo(
                        color: Colors.white54,
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

// ========= صفحة التحكم بالتحديث =========
class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({super.key});

  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  bool loading = true;
  final latestCtrl = TextEditingController();
  final minCtrl = TextEditingController();
  final urlCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  bool force = false;
  bool maintenance = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final data =
          await db.from('app_settings').select().eq('id', 1).maybeSingle();
      if (data != null) {
        latestCtrl.text = data['latest_version']?.toString() ?? '';
        minCtrl.text = data['min_version']?.toString() ?? '';
        urlCtrl.text = data['apk_url']?.toString() ?? '';
        notesCtrl.text = data['update_notes']?.toString() ?? '';
        force = data['update_force'] == true;
        maintenance = data['maintenance_mode'] == true;
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> save() async {
    try {
      await db.from('app_settings').upsert({
        'id': 1,
        'latest_version': latestCtrl.text.trim(),
        'min_version': minCtrl.text.trim(),
        'apk_url': urlCtrl.text.trim(),
        'update_notes': notesCtrl.text.trim(),
        'update_force': force,
        'maintenance_mode': maintenance,
        'updated_at': DateTime.now().toIso8601String(),
      });
      if (!mounted) return;
      message(context, 'تم حفظ إعدادات التحديث ✅');
    } catch (e) {
      if (!mounted) return;
      message(context, 'خطأ: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: lightGold),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: goldGradient,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إدارة تحديثات التطبيقات',
                style: GoogleFonts.cairo(
                  color: navy,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              Text(
                'تتحكم بنسخة العميل والإدارة معاً',
                style: GoogleFonts.cairo(color: navy, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _field(
          'أحدث نسخة (latest_version)',
          latestCtrl,
          'مثال: 1.0.2',
        ),
        _field(
          'أقل نسخة إجبارية (min_version)',
          minCtrl,
          'مثال: 1.0.1',
        ),
        _field(
          'رابط التحميل المباشر (apk_url)',
          urlCtrl,
          'https://...',
        ),
        _field(
          'ملاحظات التحديث',
          notesCtrl,
          '✨ تحسينات جديدة',
          maxLines: 3,
        ),
        SwitchListTile(
          title: Text(
            'تحديث إجباري',
            style: GoogleFonts.cairo(color: lightGold),
          ),
          value: force,
          activeColor: lightGold,
          onChanged: (v) => setState(() => force = v),
        ),
        SwitchListTile(
          title: Text(
            'وضع الصيانة',
            style: GoogleFonts.cairo(color: lightGold),
          ),
          value: maintenance,
          activeColor: Colors.redAccent,
          onChanged: (v) => setState(() => maintenance = v),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: save,
          icon: const Icon(Icons.save, color: navy),
          label: Text(
            'حفظ التغييرات',
            style: GoogleFonts.cairo(
              color: navy,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: lightGold,
            minimumSize: const Size.fromHeight(50),
          ),
        ),
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController c,
    String hint, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.cairo(color: mutedGold, fontSize: 12),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: c,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: cardDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ========= باقي الصفحات =========
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
        if (id == null) throw Exception('انتهت الجلسة');

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
        error = 'تعذر تحميل البيانات';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: load,
      color: lightGold,
      backgroundColor: cardDark,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [navyLight, navy],
              ),
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
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'من قاعدة البيانات',
                        style: GoogleFonts.cairo(color: Colors.white70),
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
            const Center(
              child: CircularProgressIndicator(color: lightGold),
            )
          else if (error != null)
            Card(
              child: ListTile(
                title: Text(error!, style: GoogleFonts.cairo()),
              ),
            )
          else if (rows.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Text(
                  'لا توجد سجلات',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(),
                ),
              ),
            )
          else ...[
            Text(
              'عدد السجلات: ${rows.length}',
              style: GoogleFonts.cairo(
                color: lightGold,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            for (final row in rows)
              Card(
                color: cardDark,
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF1A2744),
                    child: Icon(widget.icon, color: gold),
                  ),
                  title: Text(
                    readable(
                      row['full_name'] ??
                          row['name'] ??
                          row['phone'] ??
                          row['id'],
                    ),
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'الحالة: ${readable(row['status'])}',
                    style: GoogleFonts.cairo(color: Colors.white54),
                  ),
                  children: [
                    for (final k in row.keys)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 7, 16, 7),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 125,
                              child: Text(
                                k,
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  color: gold,
                                ),
                              ),
                            ),
                            Expanded(
                              child: SelectableText(
                                readable(row[k]),
                                style: const TextStyle(
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

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
        error = 'تعذر قراءة الأرصدة';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: load,
      color: lightGold,
      backgroundColor: cardDark,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [navyLight, navy],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: gold,
                  size: 34,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'أرصدة المستخدمين',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 21,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: CircularProgressIndicator(color: lightGold),
              ),
            )
          else if (error != null)
            ListTile(
              title: Text(error!, style: GoogleFonts.cairo()),
            )
          else
            for (final p in profiles)
              Card(
                color: cardDark,
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF1A2744),
                    child: Icon(
                      Icons.account_balance_wallet,
                      color: gold,
                    ),
                  ),
                  title: Text(
                    readable(p['full_name']),
                    style: GoogleFonts.cairo(color: Colors.white),
                  ),
                  subtitle: Text(
                    'الحالة: ${readable(p['status'])}',
                    style: GoogleFonts.cairo(color: Colors.white54),
                  ),
                  trailing: Text(
                    readable(p['balance']),
                    style: GoogleFonts.cairo(
                      color: lightGold,
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
        error = 'تعذر إنشاء التقرير';
      });
    }
  }

  @override
  Widget build(BodyContext context) {
    return RefreshIndicator(
      onRefresh: load,
      color: lightGold,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            'التقارير والإحصائيات',
            style: GoogleFonts.cairo(
              fontSize: 24,
              color: lightGold,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          if (loading)
            const Center(
              child: CircularProgressIndicator(color: lightGold),
            )
          else if (error != null)
            Card(
              child: ListTile(
                title: Text(error!, style: GoogleFonts.cairo()),
              ),
            )
          else
            for (final e in totals.entries)
              Card(
                color: cardDark,
                child: ListTile(
                  title: Text(
                    e.key,
                    style: GoogleFonts.cairo(color: Colors.white),
                  ),
                  trailing: Text(
                    '${e.value}',
                    style: GoogleFonts.cairo(
                      color: lightGold,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
