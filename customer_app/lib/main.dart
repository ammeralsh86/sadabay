import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const green = Color(0xFF0D5C4A);
const deepGreen = Color(0xFF073B32);
const gold = Color(0xFFC89B3C);
const lightGold = Color(0xFFE8C765);
const mutedGold = Color(0xFFB89A5A);
const bg = Color(0xFFF3F6F5);
const navy = Color(0xFF0A1931);
const navyLight = Color(0xFF121E3B);
const cardDark = Color(0xFF1A2744);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseKey = String.fromEnvironment('SUPABASE_KEY');

  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    runApp(const ConfigErrorApp());
    return;
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

  runApp(const MadaPayApp());
}

final supabase = Supabase.instance.client;

// --------------------------------------------------
// شاشة إعداد الاتصال
// --------------------------------------------------

class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'إعدادات Supabase غير موجودة.\n'
                'يجب تمرير SUPABASE_URL وSUPABASE_KEY '
                'عند بناء التطبيق.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------
// التطبيق الرئيسي
// --------------------------------------------------

class MadaPayApp extends StatelessWidget {
  const MadaPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مدى باي',
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
          centerTitle: true,
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
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: AuthGate(),
      ),
    );
  }
}

// --------------------------------------------------
// توجيه المستخدم حسب جلسة الدخول
// --------------------------------------------------

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text('تعذر التحقق من جلسة الدخول.'),
            ),
          );
        }

        if (supabase.auth.currentSession != null) {
          return const CustomerHomePage();
        }

        return const LoginPage();
      },
    );
  }
}

// --------------------------------------------------
// أدوات مساعدة
// --------------------------------------------------

void showMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text, textDirection: TextDirection.rtl),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// --------------------------------------------------
// تسجيل الدخول وإنشاء الحساب (بنفس ثيم الإدارة الفاخر)
// --------------------------------------------------

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final loginController = TextEditingController();
  final passwordController = TextEditingController();
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  bool loading = false;
  bool createAccount = false;
  bool obscurePassword = true;
  String selectedAccountType = 'CUSTOMER';

  @override
  void dispose() {
    loginController.dispose();
    passwordController.dispose();
    fullNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final pass = passwordController.text;

    if (createAccount) {
      final fullName = fullNameController.text.trim();
      final phone = phoneController.text.trim();
      final email = emailController.text.trim();

      if (fullName.isEmpty || phone.isEmpty || pass.length < 6) {
        showMessage(context, 'الرجاء إدخال الاسم، رقم الهاتف، وكلمة مرور من 6 أحرف على الأقل');
        return;
      }

      setState(() => loading = true);

      try {
        final result = await supabase.auth.signUp(
          email: email.isNotEmpty ? email : null,
          password: pass,
          phone: phone,
          data: {
            'full_name': fullName,
            'phone': phone,
            'account_type': selectedAccountType,
          },
        );

        if (result.user != null) {
          await supabase.from('profiles').upsert({
            'id': result.user!.id,
            'full_name': fullName,
            'phone': phone,
            'account_type': selectedAccountType,
            'status': 'ACTIVE',
          });
        }

        if (!mounted) return;

        if (result.session == null) {
          showMessage(context, 'تم إرسال طلب إنشاء الحساب بنجاح. قد تحتاج إلى تأكيد رقم الهاتف.');
        } else {
          showMessage(context, 'تم إنشاء الحساب وتسجيل الدخول بنجاح.');
        }
      } on AuthException catch (e) {
        showMessage(context, 'تعذر إكمال التسجيل: ${e.message}');
      } catch (e) {
        showMessage(context, 'حدث خطأ أثناء الاتصال بالخادم: $e');
      } finally {
        if (mounted) setState(() => loading = false);
      }
    } else {
      final loginValue = loginController.text.trim();

      if (loginValue.isEmpty || pass.isEmpty) {
        showMessage(context, 'أدخل اسم المستخدم أو البريد الإلكتروني أو الهاتف وكلمة المرور');
        return;
      }

      setState(() => loading = true);

      try {
        if (loginValue.contains('@')) {
          await supabase.auth.signInWithPassword(
            email: loginValue,
            password: pass,
          );
        } else {
          await supabase.auth.signInWithPassword(
            phone: loginValue,
            password: pass,
          );
        }

        if (!mounted) return;
        showMessage(context, 'تم تسجيل الدخول بنجاح.');
      } on AuthException catch (e) {
        showMessage(context, 'تعذر تسجيل الدخول: ${e.message}');
      } catch (e) {
        showMessage(context, 'حدث خطأ أثناء الاتصال بالخادم.');
      } finally {
        if (mounted) setState(() => loading = false);
      }
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
    return Scaffold(
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

                    // الشعار الذهبي للوكالة
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
                          Text(
                            createAccount ? 'إنشاء حساب جديد' : 'تسجيل الدخول',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: lightGold,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            createAccount ? 'انضم إلينا واستمتع بخدمات مدى باي' : 'مرحبًا بك، يرجى تسجيل الدخول للمتابعة',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: mutedGold,
                              fontSize: 13,
                            ),
                          ),

                          const SizedBox(height: 26),

                          if (createAccount) ...[
                            TextField(
                              controller: fullNameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: fieldDecoration(
                                label: 'الاسم الكامل',
                                icon: Icons.person_outline_rounded,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: phoneController,
                              keyboardType: TextInputType.phone,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(color: Colors.white),
                              decoration: fieldDecoration(
                                label: 'رقم الهاتف (مع مفتاح الدولة)',
                                icon: Icons.phone_android_rounded,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(color: Colors.white),
                              decoration: fieldDecoration(
                                label: 'البريد الإلكتروني (اختياري)',
                                icon: Icons.email_outlined,
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: selectedAccountType,
                              dropdownColor: cardDark,
                              style: const TextStyle(color: Colors.white),
                              decoration: fieldDecoration(
                                label: 'نوع الحساب / الدور المطلوب',
                                icon: Icons.badge_outlined,
                              ),
                              items: const [
                                DropdownMenuItem(value: 'CUSTOMER', child: Text('عميل', style: TextStyle(color: Colors.white))),
                                DropdownMenuItem(value: 'AGENT', child: Text('وكيل', style: TextStyle(color: Colors.white))),
                                DropdownMenuItem(value: 'DISTRIBUTOR', child: Text('موزع', style: TextStyle(color: Colors.white))),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => selectedAccountType = val);
                              },
                            ),
                            const SizedBox(height: 16),
                          ] else ...[
                            TextField(
                              controller: loginController,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(color: Colors.white),
                              decoration: fieldDecoration(
                                label: 'البريد الإلكتروني أو رقم الهاتف',
                                icon: Icons.person_outline_rounded,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          TextField(
                            controller: passwordController,
                            obscureText: obscurePassword,
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(color: Colors.white),
                            decoration: fieldDecoration(
                              label: 'كلمة المرور',
                              icon: Icons.lock_outline_rounded,
                              suffix: IconButton(
                                onPressed: () {
                                  setState(() => obscurePassword = !obscurePassword);
                                },
                                icon: Icon(
                                  obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: lightGold,
                                ),
                              ),
                            ),
                            onSubmitted: (_) => submit(),
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
                              onPressed: loading ? null : submit,
                              icon: loading
                                  ? const SizedBox(
                                      width: 19,
                                      height: 19,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: navy,
                                      ),
                                    )
                                  : Icon(
                                      createAccount ? Icons.person_add_rounded : Icons.login_rounded,
                                      color: navy,
                                    ),
                              label: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                child: Text(
                                  loading
                                      ? 'جارٍ المعالجة...'
                                      : createAccount
                                          ? 'إنشاء الحساب'
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
                                disabledBackgroundColor: Colors.white24,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          TextButton(
                            onPressed: loading
                                ? null
                                : () {
                                    setState(() => createAccount = !createAccount);
                                  },
                            child: Text(
                              createAccount
                                  ? 'لديك حساب بالفعل؟ تسجيل الدخول'
                                  : 'ليس لديك حساب؟ إنشاء حساب جديد',
                              style: const TextStyle(
                                color: lightGold,
                                fontWeight: FontWeight.bold,
                              ),
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
    );
  }
}

// --------------------------------------------------
// الصفحة الرئيسية للعميل
// --------------------------------------------------

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  bool loading = true;
  String? error;

  Map<String, dynamic>? profile;
  List<Map<String, dynamic>> transactions = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }

    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('انتهت جلسة الدخول. سجّل الدخول مجددًا.');
      }

      final profileData = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      final transactionData = await supabase
          .from('transactions')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(20);

      if (!mounted) return;

      setState(() {
        profile = profileData;
        transactions = List<Map<String, dynamic>>.from(transactionData);
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> logout() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      if (!mounted) return;
      showMessage(context, 'تعذر تسجيل الخروج. حاول مجددًا.');
    }
  }

  String displayValue(dynamic value) {
    if (value == null) return '—';
    return value.toString();
  }

  String transactionTitle(Map<String, dynamic> tx) {
    final serviceId = tx['service_id'];
    if (serviceId == null) {
      return 'معاملة مالية';
    }
    return 'الخدمة: $serviceId';
  }

  String transactionSubtitle(Map<String, dynamic> tx) {
    final status = displayValue(tx['status']);
    final createdAt = displayValue(tx['created_at']);
    return 'الحالة: $status\nالتاريخ: $createdAt';
  }

  String transactionAmount(Map<String, dynamic> tx) {
    final total = tx['total_amount'];
    if (total != null) {
      return total.toString();
    }
    return displayValue(tx['amount']);
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('مدى باي - بوابة العميل', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: loading ? null : loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث البيانات',
          ),
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: green),
            )
          : error != null
              ? Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off, size: 52, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text(
                          'تعذر تحميل البيانات من Supabase.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: loadData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadData,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        color: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFFE5ECE8)),
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFE4F1ED),
                            child: Icon(Icons.person, color: green),
                          ),
                          title: Text(
                            profile?['full_name']?.toString() ?? 'عميل مدى باي',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: deepGreen),
                          ),
                          subtitle: Text(
                            user?.phone ?? user?.email ?? '',
                            textDirection: TextDirection.ltr,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        color: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFFE5ECE8)),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.account_balance_wallet,
                            size: 32,
                            color: gold,
                          ),
                          title: const Text('الرصيد المتاح', style: TextStyle(color: Colors.black54)),
                          subtitle: Text(
                            profile?['balance'] == null ? '0.00' : profile!['balance'].toString(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: deepGreen,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'آخر العمليات',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: deepGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (transactions.isEmpty)
                        const Card(
                          child: ListTile(
                            leading: Icon(Icons.receipt_long),
                            title: Text('لا توجد عمليات مسجلة حالياً.'),
                          ),
                        )
                      else
                        ...transactions.map(
                          (tx) => Card(
                            color: Colors.white,
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(color: Color(0xFFE5ECE8)),
                            ),
                            child: ListTile(
                              leading: const Icon(
                                Icons.receipt_long,
                                color: green,
                              ),
                              title: Text(transactionTitle(tx), style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(transactionSubtitle(tx)),
                              isThreeLine: true,
                              trailing: Text(
                                transactionAmount(tx),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: green,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
