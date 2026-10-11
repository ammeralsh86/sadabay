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

class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'إعدادات Supabase غير موجودة.\n'
              'مرّر SUPABASE_URL وSUPABASE_KEY عند البناء.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

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
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (supabase.auth.currentUser != null) {
          return const CustomerHomePage();
        }
        return const LoginPage();
      },
    );
  }
}

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

  @override
  void dispose() {
    phone.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final phoneNumber = phone.text.trim();
    final pass = password.text;

    if (phoneNumber.isEmpty || pass.length < 6) {
      message('أدخل رقم الهاتف وكلمة مرور من 6 أحرف أو أرقام على الأقل.');
      return;
    }

    setState(() => loading = true);

    try {
      if (createAccount) {
        final result = await supabase.auth.signUp(
          phone: phoneNumber,
          password: pass,
          data: {'phone': phoneNumber},
        );

        if (!mounted) return;

        if (result.session == null) {
          message(
            'تم إرسال طلب إنشاء الحساب. '
            'تحقق من الهاتف برمز SMS إذا كان التحقق مفعّلًا في Supabase.',
          );
        } else {
          message('تم إنشاء الحساب وتسجيل الدخول.');
        }
      } else {
        await supabase.auth.signInWithPassword(
          phone: phoneNumber,
          password: pass,
        );

        if (!mounted) return;
        message('تم تسجيل الدخول بنجاح.');
      }
    } on AuthException catch (e) {
      message('تعذّر إكمال العملية: ${e.message}');
    } catch (e) {
      message('حدث خطأ أثناء الاتصال بالخادم.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('وكالة مدى باي')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                size: 76,
                color: Color(0xFF147D64),
              ),
              const SizedBox(height: 16),
              Text(
                createAccount ? 'إنشاء حساب' : 'تسجيل الدخول',
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
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  border: OutlineInputBorder(),
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
                    : () => setState(
                          () => createAccount = !createAccount,
                        ),
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
    );
  }
}

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
    setState(() {
      loading = true;
      error = null;
    });

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
          .order('created_at', ascending: false)
          .limit(20);

      if (!mounted) return;

      setState(() {
        profile = profileData;
        transactions = List<Map<String, dynamic>>.from(
          transactionData,
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('مدى باي'),
        actions: [
          IconButton(
            onPressed: loadData,
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
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off, size: 48),
                        const SizedBox(height: 12),
                        const Text(
                          'تعذّر تحميل البيانات من Supabase.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: loadData,
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadData,
                  child: ListView(
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
                          subtitle: Text(user?.phone ?? ''),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.account_balance_wallet,
                          ),
                          title: const Text('الرصيد'),
                          subtitle: Text(
                            profile?['balance'] == null
                                ? 'لم يتم إعداد الرصيد في قاعدة البيانات.'
                                : '${profile!['balance']}',
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
                              title: Text(
                                tx['description']?.toString() ??
                                    tx['type']?.toString() ??
                                    'عملية',
                              ),
                              subtitle: Text(
                                tx['created_at']?.toString() ?? '',
                              ),
                              trailing: Text(
                                tx['amount']?.toString() ?? '',
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
