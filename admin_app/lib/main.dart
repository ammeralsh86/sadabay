import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseKey = String.fromEnvironment('SUPABASE_KEY');

  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    runApp(const ConfigurationErrorApp());
    return;
  }

  echo "SUPABASE_URL is configured."
echo "SUPABASE_URL = ${SUPABASE_URL}"
echo "SUPABASE_KEY is configured."
  );

  runApp(const MadaPayAdmin());
}

// ============================================================
// الألوان
// ============================================================

const Color luxuryGreen = Color(0xFF0D5C4A);
const Color deepGreen = Color(0xFF073B32);
const Color gold = Color(0xFFC89B3C);
const Color backgroundColor = Color(0xFFF4F7F6);
const Color white = Colors.white;

// ============================================================
// خطأ الإعداد - يظهر فقط إذا كانت إعدادات البناء ناقصة
// ============================================================

class ConfigurationErrorApp extends StatelessWidget {
  const ConfigurationErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'مدى باي',
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: backgroundColor,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.settings_rounded,
                        size: 55,
                        color: luxuryGreen,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'إعداد النظام غير مكتمل',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'تعذر تشغيل التطبيق. يرجى إعادة تثبيت النسخة الصحيحة.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15),
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

// ============================================================
// التطبيق
// ============================================================

class MadaPayAdmin extends StatelessWidget {
  const MadaPayAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'مدى باي - الإدارة',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: luxuryGreen,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: Colors.grey.shade200,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: luxuryGreen,
              width: 1.5,
            ),
          ),
        ),
      ),
      home: const AdminLoginPage(),
    );
  }
}

// ============================================================
// زر احترافي ثلاثي الأبعاد خفيف
// ============================================================

class PremiumButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool loading;
  final bool outlined;

  const PremiumButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.loading = false,
    this.outlined = false,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;

    return GestureDetector(
      onTapDown: enabled
          ? (_) {
              setState(() => pressed = true);
            }
          : null,
      onTapUp: enabled
          ? (_) {
              setState(() => pressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: enabled
          ? () {
              setState(() => pressed = false);
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(
          0,
          pressed ? 3 : 0,
          0,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: widget.outlined
              ? null
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF167C67),
                    Color(0xFF0A4F41),
                  ],
                ),
          color: widget.outlined ? Colors.white : null,
          border: widget.outlined
              ? Border.all(
                  color: luxuryGreen,
                  width: 1.3,
                )
              : null,
          boxShadow: pressed
              ? []
              : [
                  BoxShadow(
                    color: luxuryGreen.withOpacity(0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.loading)
                const SizedBox(
                  width: 21,
                  height: 21,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: white,
                  ),
                )
              else
                Icon(
                  widget.icon,
                  color: widget.outlined ? luxuryGreen : white,
                ),
              const SizedBox(width: 10),
              Text(
                widget.loading
                    ? 'جارٍ التنفيذ...'
                    : widget.text,
                style: TextStyle(
                  color: widget.outlined ? luxuryGreen : white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// تسجيل الدخول
// ============================================================

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final loginController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool obscurePassword = true;

  final client = Supabase.instance.client;

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
      showMessage('أدخل بيانات تسجيل الدخول');
      return;
    }

    setState(() => loading = true);

    try {
      AuthResponse response;

      if (login.contains('@')) {
        response = await client.auth.signInWithPassword(
          email: login,
          password: password,
        );
      } else {
        response = await client.auth.signInWithPassword(
          phone: login,
          password: password,
        );
      }

      final user = response.user;

      if (user == null) {
        showMessage('بيانات الدخول غير صحيحة');
        return;
      }

      final profile = await client
          .from('profiles')
          .select('full_name, status')
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) {
        await client.auth.signOut();
        showMessage('لا يوجد ملف مستخدم لهذا الحساب');
        return;
      }

      final status = profile['status']?.toString();

      if (status != 'ACTIVE') {
        await client.auth.signOut();
        showMessage('الحساب غير مفعل حاليًا');
        return;
      }

      final roleRows = await client
          .from('user_roles')
          .select('role_id')
          .eq('user_id', user.id);

      if (roleRows.isEmpty) {
        await client.auth.signOut();
        showMessage('هذا الحساب لا يملك صلاحية إدارية');
        return;
      }

      bool isOwner = false;
      String roleName = '';

      for (final row in roleRows) {
        final roleId = row['role_id'];

        final role = await client
            .from('roles')
            .select('name')
            .eq('id', roleId)
            .maybeSingle();

        if (role != null) {
          final name = role['name']?.toString() ?? '';

          if (name == 'OWNER') {
            isOwner = true;
            roleName = 'OWNER';
            break;
          }

          if (roleName.isEmpty) {
            roleName = name;
          }
        }
      }

      if (!mounted) return;

      if (isOwner) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OwnerDashboard(
              name: profile['full_name']?.toString() ??
                  'مالك مدى باي',
            ),
          ),
        );
        return;
      }

      if (roleName.isEmpty) {
        await client.auth.signOut();
        showMessage('لم يتم تحديد دور لهذا الحساب');
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AdminDashboard(
            name: profile['full_name']?.toString() ??
                'مستخدم إداري',
            role: roleName,
          ),
        ),
      );
    } on AuthException catch (e) {
      showMessage(
        e.message.isNotEmpty ? e.message : 'فشل تسجيل الدخول',
      );
    } catch (e) {
      showMessage('حدث خطأ أثناء الاتصال بالنظام');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textDirection: TextDirection.rtl,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
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
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Color(0xFF063A31),
                Color(0xFF0C5E4B),
                Color(0xFF0A463A),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 470,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 25,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 46,
                          color: luxuryGreen,
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'مـدى بـاي',
                        style: TextStyle(
                          color: white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        'لوحة الإدارة والتحكم',
                        style: TextStyle(
                          color: Color(0xFFD9E9E4),
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 36),

                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.97),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.22),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'مرحبًا بك',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: deepGreen,
                              ),
                            ),

                            const SizedBox(height: 7),

                            Text(
                              'سجّل الدخول للوصول إلى لوحة مدى باي',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),

                            const SizedBox(height: 28),

                            TextField(
                              controller: loginController,
                              textDirection: TextDirection.ltr,
                              keyboardType:
                                  TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText:
                                    'البريد الإلكتروني أو رقم الهاتف',
                                prefixIcon: Icon(
                                  Icons.person_outline_rounded,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            TextField(
                              controller: passwordController,
                              obscureText: obscurePassword,
                              textDirection: TextDirection.ltr,
                              decoration: InputDecoration(
                                labelText: 'كلمة المرور',
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(
                                      () => obscurePassword =
                                          !obscurePassword,
                                    );
                                  },
                                  icon: Icon(
                                    obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            PremiumButton(
                              text: 'تسجيل الدخول',
                              icon: Icons.login_rounded,
                              loading: loading,
                              onPressed: loading ? null : login,
                            ),

                            const SizedBox(height: 18),

                            const Text(
                              'تطوير م / أبو معاوية الشبيبي',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF777777),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'وكالة مدى باي لخدمات الرصيد وشحن التطبيقات',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFD9E9E4),
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

// ============================================================
// لوحة المالك
// ============================================================

class OwnerDashboard extends StatelessWidget {
  final String name;

  const OwnerDashboard({
    super.key,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return AdminHome(
      name: name,
      role: 'OWNER',
      isOwner: true,
    );
  }
}

// ============================================================
// لوحة الموظف / المدير
// ============================================================

class AdminDashboard extends StatelessWidget {
  final String name;
  final String role;

  const AdminDashboard({
    super.key,
    required this.name,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return AdminHome(
      name: name,
      role: role,
      isOwner: false,
    );
  }
}

// ============================================================
// الصفحة الرئيسية
// ============================================================

class AdminHome extends StatefulWidget {
  final String name;
  final String role;
  final bool isOwner;

  const AdminHome({
    super.key,
    required this.name,
    required this.role,
    required this.isOwner,
  });

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int selectedIndex = 0;

  final client = Supabase.instance.client;

  Future<void> logout() async {
    await client.auth.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminLoginPage(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardOverview(
        name: widget.name,
        role: widget.role,
      ),
      const SimpleSectionPage(
        title: 'المستخدمون',
        icon: Icons.people_alt_rounded,
        description: 'إدارة العملاء والحسابات والمستخدمين.',
      ),
      const SimpleSectionPage(
        title: 'الأرصدة',
        icon: Icons.account_balance_wallet_rounded,
        description: 'متابعة الأرصدة والحسابات المالية.',
      ),
      const SimpleSectionPage(
        title: 'التحويلات',
        icon: Icons.swap_horiz_rounded,
        description: 'متابعة التحويلات والعمليات المالية.',
      ),
      const SimpleSectionPage(
        title: 'الخدمات والأسعار',
        icon: Icons.apps_rounded,
        description: 'إدارة الخدمات والأسعار ومتابعة حالتها.',
      ),
      const SimpleSectionPage(
        title: 'التقارير',
        icon: Icons.bar_chart_rounded,
        description: 'عرض التقارير والإحصائيات المالية والتشغيلية.',
      ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.white,
          title: const Text(
            'مدى باي',
            style: TextStyle(
              color: deepGreen,
              fontWeight: FontWeight.w900,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'تسجيل الخروج',
              onPressed: logout,
              icon: const Icon(
                Icons.logout_rounded,
                color: luxuryGreen,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        drawer: _buildDrawer(),
        body: pages[selectedIndex],
      ),
    );
  }

  Widget _buildDrawer() {
    final items = [
      ('الرئيسية', Icons.dashboard_rounded),
      ('المستخدمون', Icons.people_alt_rounded),
      (
        'الأرصدة',
        Icons.account_balance_wallet_rounded,
      ),
      ('التحويلات', Icons.swap_horiz_rounded),
      ('الخدمات والأسعار', Icons.apps_rounded),
      ('التقارير', Icons.bar_chart_rounded),
    ];

    return Drawer(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                22,
                55,
                22,
                25,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    deepGreen,
                    luxuryGreen,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 29,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person_rounded,
                      color: luxuryGreen,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.name,
                    style: const TextStyle(
                      color: white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.isOwner
                        ? 'المالك الرئيسي'
                        : widget.role,
                    style: const TextStyle(
                      color: Color(0xFFD6E9E3),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final selected = selectedIndex == index;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 3,
                    ),
                    child: ListTile(
                      selected: selected,
                      selectedTileColor:
                          luxuryGreen.withOpacity(0.10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      leading: Icon(
                        item.$2,
                        color: selected
                            ? luxuryGreen
                            : Colors.grey.shade600,
                      ),
                      title: Text(
                        item.$1,
                        style: TextStyle(
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: selected
                              ? luxuryGreen
                              : Colors.grey.shade800,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          selectedIndex = index;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),

            const Divider(),

            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: Colors.redAccent,
              ),
              title: const Text('تسجيل الخروج'),
              onTap: logout,
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// لوحة الإحصائيات
// ============================================================

class DashboardOverview extends StatelessWidget {
  final String name;
  final String role;

  const DashboardOverview({
    super.key,
    required this.name,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color(0xFF0B624F),
                  Color(0xFF063D33),
                ],
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: luxuryGreen.withOpacity(0.20),
                  blurRadius: 18,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person_rounded,
                    color: luxuryGreen,
                    size: 31,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مرحبًا، $name',
                        style: const TextStyle(
                          color: white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        role == 'OWNER'
                            ? 'لديك صلاحيات المالك الكاملة'
                            : 'لوحة التحكم الإدارية',
                        style: const TextStyle(
                          color: Color(0xFFD5E9E3),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          const Text(
            'ملخص النظام',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: deepGreen,
            ),
          ),

          const SizedBox(height: 14),

          GridView.count(
            crossAxisCount:
                MediaQuery.of(context).size.width > 650
                    ? 4
                    : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: const [
              StatCard(
                title: 'العملاء',
                value: '—',
                icon: Icons.people_alt_rounded,
              ),
              StatCard(
                title: 'الرصيد',
                value: '—',
                icon: Icons.account_balance_wallet_rounded,
              ),
              StatCard(
                title: 'التحويلات',
                value: '—',
                icon: Icons.swap_horiz_rounded,
              ),
              StatCard(
                title: 'الطلبات',
                value: '—',
                icon: Icons.pending_actions_rounded,
              ),
            ],
          ),

          const SizedBox(height: 24),

          const Text(
            'الوصول السريع',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: deepGreen,
            ),
          ),

          const SizedBox(height: 14),

          QuickAction(
            icon: Icons.people_alt_rounded,
            title: 'إدارة المستخدمين',
            subtitle: 'عرض وإدارة العملاء والحسابات',
            onTap: () {},
          ),

          QuickAction(
            icon: Icons.account_balance_wallet_rounded,
            title: 'إدارة الأرصدة',
            subtitle: 'متابعة الأرصدة والحسابات المالية',
            onTap: () {},
          ),

          QuickAction(
            icon: Icons.swap_horiz_rounded,
            title: 'التحويلات',
            subtitle: 'متابعة العمليات والمعاملات',
            onTap: () {},
          ),

          QuickAction(
            icon: Icons.apps_rounded,
            title: 'الخدمات والأسعار',
            subtitle: 'إدارة الخدمات والأسعار',
            onTap: () {},
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: gold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: gold,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'النظام متصل',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: deepGreen,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'تم تسجيل الدخول بنجاح',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// بطاقة إحصائية
// ============================================================

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.055),
            blurRadius: 15,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: luxuryGreen.withOpacity(0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: luxuryGreen,
              size: 23,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: deepGreen,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// وصول سريع
// ============================================================

class QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const QuickAction({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.045),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF16806A),
                        Color(0xFF0A5546),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: luxuryGreen.withOpacity(0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: white,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: deepGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 17,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// الصفحات المؤقتة للأقسام
// ============================================================

class SimpleSectionPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;

  const SimpleSectionPage({
    super.key,
    required this.title,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(
            maxWidth: 600,
          ),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: luxuryGreen.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: luxuryGreen,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  color: deepGreen,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: gold.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.construction_rounded,
                      color: gold,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'القسم قيد التجهيز',
                      style: TextStyle(
                        color: deepGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
