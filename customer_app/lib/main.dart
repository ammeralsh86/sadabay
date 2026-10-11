
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF147D64),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
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
// تسجيل الدخول وإنشاء الحساب
// --------------------------------------------------

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final phone = TextEditingController();
  final password = TextEditingController();

  bool loading = false;
  bool createAccount = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    phone.dispose();
    password.dispose();
    super.dispose();
  }

  void showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> submit() async {
    final phoneNumber = phone.text.trim();
    final pass = password.text;

    if (phoneNumber.isEmpty || pass.length < 6) {
      showMessage(
        'أدخل رقم الهاتف مع مفتاح الدولة '
        'وكلمة مرور من 6 أحرف أو أرقام على الأقل.',
      );
      return;
    }

    setState(() => loading = true);

    try {
      if (createAccount) {
        final result = await supabase.auth.signUp(
          phone: phoneNumber,
          password: pass,
          data: {
            'phone': phoneNumber,
          },
        );

        if (!mounted) return;

        if (result.session == null) {
          showMessage(
            'تم إرسال طلب إنشاء الحساب. '
            'قد تحتاج إلى تأكيد رقم الهاتف برمز SMS '
            'بحسب إعدادات Supabase.',
          );
        } else {
          showMessage('تم إنشاء الحساب وتسجيل الدخول.');
        }
      } else {
        await supabase.auth.signInWithPassword(
          phone: phoneNumber,
          password: pass,
        );

        if (!mounted) return;

        showMessage('تم تسجيل الدخول بنجاح.');
      }
    } on AuthException catch (e) {
      showMessage('تعذر إكمال العملية: ${e.message}');
    } catch (e) {
      showMessage('حدث خطأ أثناء الاتصال بالخادم.');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('وكالة مدى باي'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 82,
                  color: Color(0xFF147D64),
                ),
                const SizedBox(height: 16),
                Text(
                  createAccount ? 'إنشاء حساب جديد' : 'تسجيل الدخول',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف مع مفتاح الدولة',
                    hintText: '+967XXXXXXXXX',
                    prefixIcon: Icon(Icons.phone_android),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: password,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: loading ? null : submit,
                  child: Text(
                    loading
                        ? 'جارٍ الاتصال...'
                        : createAccount
                            ? 'إنشاء الحساب'
                            : 'تسجيل الدخول',
                  ),
                ),
                TextButton(
                  onPressed: loading
                      ? null
                      : () {
                          setState(() {
                            createAccount = !createAccount;
                          });
                        },
                  child: Text(
                    createAccount
                        ? 'لدي حساب بالفعل'
                        : 'إنشاء حساب جديد',
                  ),
                ),
              ],
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
  State<CustomerHomePage> createState() =>
      _CustomerHomePageState();
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

  // تحميل بيانات المستخدم ومعاملاته من Supabase
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
        transactions =
            List<Map<String, dynamic>>.from(transactionData);
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر تسجيل الخروج. حاول مجددًا.'),
        ),
      );
    }
  }

  String displayValue(dynamic value) {
    if (value == null) return '—';
    return value.toString();
  }

  String transactionTitle(Map<String, dynamic> tx) {
    final serviceId = tx['service_id'];

    if (serviceId == null) {
      return 'معاملة';
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
        title: const Text('مدى باي'),
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
              child: CircularProgressIndicator(),
            )
          : error != null
              ? Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off,
                          size: 52,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'تعذر تحميل البيانات من Supabase.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          error!,
                          textAlign: TextAlign.center,
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
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(
                            profile?['full_name']?.toString() ??
                                'عميل مدى باي',
                          ),
                          subtitle: Text(
                            user?.phone ?? '',
                            textDirection: TextDirection.ltr,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // عرض الرصيد المقروء من قاعدة البيانات
                      Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.account_balance_wallet,
                            size: 32,
                          ),
                          title: const Text('الرصيد'),
                          subtitle: Text(
                            profile?['balance'] == null
                                ? 'الرصيد غير متاح'
                                : profile!['balance'].toString(),
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'آخر العمليات',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),

                      if (transactions.isEmpty)
                        const Card(
                          child: ListTile(
                            leading: Icon(Icons.receipt_long),
                            title: Text('لا توجد عمليات مسجلة.'),
                          ),
                        )
                      else
                        ...transactions.map(
                          (tx) => Card(
                            child: ListTile(
                              leading: const Icon(
                                Icons.receipt_long,
                              ),
                              title: Text(transactionTitle(tx)),
                              subtitle: Text(
                                transactionSubtitle(tx),
                              ),
                              isThreeLine: true,
                              trailing: Text(
                                transactionAmount(tx),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),
                      const Card(
                        child: ListTile(
                          leading: Icon(Icons.security),
                          title: Text('حماية الحساب'),
                          subtitle: Text(
                            'يتم تحميل بياناتك من الخادم. '
                            'لا ينفذ هذا التطبيق تعديلات مباشرة '
                            'على الرصيد أو المعاملات المالية.',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
