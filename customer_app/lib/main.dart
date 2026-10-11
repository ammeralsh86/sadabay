المسار: "customer_app/lib/main.dart"

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

const green = Color(0xFF0D5C4A);
const deepGreen = Color(0xFF073B32);
const gold = Color(0xFFC89B3C);
const lightGold = Color(0xFFE8C765);
const mutedGold = Color(0xFFB89A5A);
const bg = Color(0xFFF3F6F5);
const navy = Color(0xFF0A1931);
const navyLight = Color(0xFF121E3B);
const cardDark = Color(0xFF1A2744);

const String adminWhatsAppUrl = 'https://wa.me/qr/GXLC3B3LQK22B1';
const String developerWhatsAppUrl = 'https://wa.me/967772507268';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseKey = String.fromEnvironment('SUPABASE_KEY');

  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    runApp(const ConfigErrorApp());
    return;
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  runApp(const MadaPayApp());
}

final supabase = Supabase.instance.client;

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
                'يجب تمرير SUPABASE_URL وSUPABASE_KEY عند بناء التطبيق.',
                textAlign: TextAlign.center,
              ),
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

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('تعذر التحقق من جلسة الدخول.')),
          );
        }

        if (supabase.auth.currentSession != null) {
          return const DeviceCheckGate();
        }

        return const LoginPage();
      },
    );
  }
}

void showMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text, textDirection: TextDirection.rtl),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// --------------------------------------------------
// بوابة التحقق من تفعيل الجهاز
// --------------------------------------------------

class DeviceCheckGate extends StatefulWidget {
  const DeviceCheckGate({super.key});

  @override
  State<DeviceCheckGate> createState() => _DeviceCheckGateState();
}

class _DeviceCheckGateState extends State<DeviceCheckGate> {
  bool checking = true;
  bool isDeviceAuthorized = false;
  String deviceId = '';
  String? checkError;

  @override
  void initState() {
    super.initState();
    _checkDeviceAuthorization();
  }

  Future<String> _getStableDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'mada_pay_installation_device_id';

    String? savedId = prefs.getString(key);
    if (savedId != null && savedId.isNotEmpty) {
      return savedId;
    }

    final random = Random.secure();
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final randomPart = List.generate(
      32,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();

    savedId = 'MADA-$timestamp-$randomPart';
    await prefs.setString(key, savedId);
    return savedId;
  }

  Future<void> _checkDeviceAuthorization() async {
    if (mounted) {
      setState(() {
        checking = true;
        checkError = null;
      });
    }

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() {
          checking = false;
          isDeviceAuthorized = false;
          checkError = 'انتهت جلسة الدخول. سجّل الدخول مجدداً.';
        });
        return;
      }

      final localDeviceId = await _getStableDeviceId();

      if (!mounted) return;
      setState(() => deviceId = localDeviceId);

      // نقرأ حالة الجهاز فقط؛ لا نغيّر صلاحياته من تطبيق العميل.
      final profile = await supabase
          .from('profiles')
          .select('device_id, device_status, status')
          .eq('id', user.id)
          .maybeSingle();

      final profileStatus =
          profile?['status']?.toString().toUpperCase() ?? '';
      final registeredDeviceId = profile?['device_id']?.toString() ?? '';
      final deviceStatus =
          profile?['device_status']?.toString().toUpperCase() ?? '';

      final authorized = profile != null &&
          registeredDeviceId.isNotEmpty &&
          registeredDeviceId == localDeviceId &&
          deviceStatus == 'ACTIVE' &&
          profileStatus == 'ACTIVE';

      if (!mounted) return;
      setState(() {
        isDeviceAuthorized = authorized;
        checking = false;
        checkError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        checking = false;
        isDeviceAuthorized = false;
        checkError =
            'تعذر التحقق من الجهاز. تحقق من اتصال الإنترنت ثم أعد المحاولة.';
      });
    }
  }

  Future<void> launchWhatsApp() async {
    final message = Uri.encodeComponent(
      'السلام عليكم، أرجو تفعيل جهازي في تطبيق مدى باي.\n'
      'معرّف الجهاز: $deviceId\n'
      'البريد: ${supabase.auth.currentUser?.email ?? 'غير متوفر'}',
    );

    final url = Uri.parse('$adminWhatsAppUrl?text=$message');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        final fallback = Uri.parse(
          'https://wa.me/967772507268?text=$message',
        );
        await launchUrl(fallback, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (mounted) showMessage(context, 'تعذر فتح واتساب.');
    }
  }

  Future<void> launchSMS() async {
    final message = Uri.encodeComponent(
      'أرجو تفعيل جهازي في مدى باي. معرّف الجهاز: $deviceId',
    );
    final url = Uri.parse('sms:?body=$message');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        showMessage(context, 'تعذر فتح تطبيق الرسائل.');
      }
    } catch (_) {
      if (mounted) showMessage(context, 'تعذر فتح تطبيق الرسائل.');
    }
  }

  Future<void> _signOut() async {
    await supabase.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (checking) {
      return const Scaffold(
        backgroundColor: navy,
        body: Center(
          child: CircularProgressIndicator(color: lightGold),
        ),
      );
    }

    if (!isDeviceAuthorized) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: navy,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardDark,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: gold.withOpacity(0.4)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.phonelink_lock_rounded,
                          size: 64,
                          color: lightGold,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'تفعيل الجهاز مطلوب',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: lightGold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          checkError ??
                              'للدخول إلى حسابك من هذا الجهاز، أرسل معرّف الجهاز إلى الإدارة لاعتماده.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: navy,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: gold.withOpacity(0.2),
                            ),
                          ),
                          child: SelectableText(
                            deviceId.isEmpty ? 'جارٍ تجهيز المعرّف...' : deviceId,
                            style: const TextStyle(
                              color: lightGold,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: launchWhatsApp,
                          icon: const Icon(Icons.chat, color: Colors.white),
                          label: const Text(
                            'التفعيل عبر واتساب',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: launchSMS,
                          icon: const Icon(Icons.sms, color: lightGold),
                          label: const Text(
                            'التفعيل عبر رسائل SMS',
                            style: TextStyle(
                              color: lightGold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            side: BorderSide(color: gold.withOpacity(0.5)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _checkDeviceAuthorization,
                          child: const Text(
                            'إعادة فحص حالة التفعيل',
                            style: TextStyle(color: lightGold),
                          ),
                        ),
                        TextButton(
                          onPressed: _signOut,
                          child: const Text(
                            'تسجيل الخروج',
                            style: TextStyle(color: Colors.redAccent),
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

    return const CustomerHomePage();
  }
}

// --------------------------------------------------
// صفحة تسجيل الدخول وإنشاء الحساب
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
  bool agreeToPrivacyPolicy = false;
  String selectedCountryCode = '+967';

  final List<Map<String, String>> countryCodes = [
    {'name': 'اليمن', 'code': '+967'},
    {'name': 'السعودية', 'code': '+966'},
    {'name': 'الإمارات', 'code': '+971'},
    {'name': 'مصر', 'code': '+20'},
    {'name': 'الأردن', 'code': '+962'},
    {'name': 'عمان', 'code': '+968'},
    {'name': 'الكويت', 'code': '+965'},
    {'name': 'قطر', 'code': '+974'},
    {'name': 'البحرين', 'code': '+973'},
    {'name': 'العراق', 'code': '+964'},
    {'name': 'تركيا', 'code': '+90'},
    {'name': 'الولايات المتحدة', 'code': '+1'},
  ];

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
      if (!agreeToPrivacyPolicy) {
        showMessage(context, 'يجب الموافقة على سياسة الخصوصية للمتابعة.');
        return;
      }

      final fullName = fullNameController.text.trim();
      final phoneNum = phoneController.text.trim();
      final email = emailController.text.trim();
      final fullPhone = '$selectedCountryCode$phoneNum';

      if (fullName.isEmpty ||
          email.isEmpty ||
          phoneNum.isEmpty ||
          pass.length < 6) {
        showMessage(
          context,
          'الرجاء إدخال الاسم والبريد ورقم الهاتف وكلمة مرور من 6 أحرف على الأقل.',
        );
        return;
      }

      setState(() => loading = true);

      try {
        final result = await supabase.auth.signUp(
          email: email,
          password: pass,
          data: {
            'full_name': fullName,
            'phone': fullPhone,
          },
        );

        if (result.user != null) {
          await supabase.from('profiles').upsert({
            'id': result.user!.id,
            'full_name': fullName,
            'phone': fullPhone,
            'status': 'ACTIVE',
          });
        }

        if (!mounted) return;
        showMessage(
          context,
          'تم إرسال طلب التسجيل. تفقد بريدك الإلكتروني لإكمال التحقق.',
        );
      } on AuthException catch (e) {
        showMessage(context, 'تعذر إكمال التسجيل: ${e.message}');
      } catch (e) {
        showMessage(context, 'حدث خطأ أثناء الاتصال بالخادم.');
      } finally {
        if (mounted) setState(() => loading = false);
      }
    } else {
      final loginValue = loginController.text.trim();

      if (loginValue.isEmpty || pass.isEmpty) {
        showMessage(context, 'أدخل البريد الإلكتروني وكلمة المرور.');
        return;
      }

      setState(() => loading = true);

      try {
        await supabase.auth.signInWithPassword(
          email: loginValue,
          password: pass,
        );

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
        borderSide: BorderSide.none,
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

  Future<void> launchDeveloperWhatsApp() async {
    final url = Uri.parse(developerWhatsAppUrl);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        showMessage(context, 'تعذر فتح واتساب.');
      }
    } catch (_) {
      if (mounted) showMessage(context, 'تعذر فتح واتساب.');
    }
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
                    Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [lightGold, gold],
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
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'لخدمات الدفع الرقمية الحديثة',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: gold),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF101D35),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: gold.withOpacity(0.45)),
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
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(color: Colors.white),
                              decoration: fieldDecoration(
                                label: 'البريد الإلكتروني لتلقي كود التحقق',
                                icon: Icons.email_outlined,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cardDark,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: gold.withOpacity(0.35),
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedCountryCode,
                                      dropdownColor: cardDark,
                                      style: const TextStyle(
                                        color: lightGold,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      items: countryCodes.map((c) {
                                        return DropdownMenuItem(
                                          value: c['code'],
                                          child: Text(
                                            '${c['name']} (${c['code']})',
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(
                                            () => selectedCountryCode = val,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: phoneController,
                                    keyboardType: TextInputType.phone,
                                    textDirection: TextDirection.ltr,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: fieldDecoration(
                                      label: 'رقم الهاتف الأساسي',
                                      icon: Icons.phone_android_rounded,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Checkbox(
                                  value: agreeToPrivacyPolicy,
                                  activeColor: lightGold,
                                  checkColor: navy,
                                  onChanged: (val) {
                                    setState(
                                      () => agreeToPrivacyPolicy = val ?? false,
                                    );
                                  },
                                ),
                                const Expanded(
                                  child: Text(
                                    'أوافق على سياسة الخصوصية وشروط الاستخدام',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ] else ...[
                            TextField(
                              controller: loginController,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(color: Colors.white),
                              decoration: fieldDecoration(
                                label: 'البريد الإلكتروني',
                                icon: Icons.email_outlined,
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
                                onPressed: () => setState(
                                  () => obscurePassword = !obscurePassword,
                                ),
                                icon: Icon(
                                  obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: lightGold,
                                ),
                              ),
                            ),
                            onSubmitted: (_) => submit(),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
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
                                    createAccount
                                        ? Icons.person_add_rounded
                                        : Icons.login_rounded,
                                    color: navy,
                                  ),
                            label: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 15),
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
                              backgroundColor: lightGold,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: loading
                                ? null
                                : () => setState(
                                      () => createAccount = !createAccount,
                                    ),
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
                    const SizedBox(height: 30),
                    const Divider(
                      color: Colors.white24,
                      thickness: 1,
                      indent: 40,
                      endIndent: 40,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'جميع الحقوق محفوظة لوكالة مدى باي لخدمات الدفع الرقمية الحديثة',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: mutedGold,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'برمجة وتطوير م / أبومعاوية الشبيبي',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'للاتصال بنا: ',
                          style: TextStyle(color: mutedGold, fontSize: 12),
                        ),
                        InkWell(
                          onTap: launchDeveloperWhatsApp,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF25D366).withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF25D366),
                              ),
                            ),
                            child: const Icon(
                              Icons.chat,
                              color: Color(0xFF25D366),
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
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
      if (user == null) throw Exception('انتهت جلسة الدخول.');

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
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  void checkVerificationAndProceed(VoidCallback onVerifiedAction) {
    final isVerified = profile?['is_verified'] == true ||
        profile?['kyc_status']?.toString().toUpperCase() == 'APPROVED';

    if (isVerified) {
      onVerifiedAction();
    } else {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text(
            'تنويه هام',
            style: TextStyle(fontWeight: FontWeight.bold, color: deepGreen),
          ),
          content: const Text(
            'عزيزي العميل، الرجاء توثيق حسابك للاستمتاع بمزايا تطبيق وكالة مدى باي الحصرية. اختر زر التوثيق أدناه للمتابعة.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('لاحقاً'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                showKycDialog();
              },
              style: FilledButton.styleFrom(backgroundColor: green),
              child: const Text('توثيق الآن'),
            ),
          ],
        ),
      );
    }
  }

  void showKycDialog() {
    final nameController = TextEditingController(
      text: profile?['full_name']?.toString() ?? '',
    );
    final docNumberController = TextEditingController();
    String docType = 'بطاقة شخصية';
    DateTime? birthDate;
    DateTime? issueDate;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'توثيق المحفظة',
              style: TextStyle(fontWeight: FontWeight.bold, color: deepGreen),
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'أدخل بيانات الوثيقة الرسمية كما تظهر في البطاقة الشخصية أو جواز السفر لتفعيل خدمات السحب والشحن.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'الاسم الكامل',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: docType,
                      decoration: const InputDecoration(
                        labelText: 'نوع الوثيقة',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'بطاقة شخصية',
                          child: Text('بطاقة شخصية'),
                        ),
                        DropdownMenuItem(
                          value: 'جواز سفر',
                          child: Text('جواز سفر'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => docType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: docNumberController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'رقم الوثيقة',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: birthDate == null
                            ? 'تاريخ الميلاد'
                            : birthDate!.toString().split(' ')[0],
                        prefixIcon: const Icon(Icons.calendar_today),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime(1995),
                          firstDate: DateTime(1940),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() => birthDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: issueDate == null
                            ? 'تاريخ إصدار الوثيقة'
                            : issueDate!.toString().split(' ')[0],
                        prefixIcon: const Icon(Icons.calendar_today),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2010),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() => issueDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'صورة وجه البطاقة',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          OutlinedButton.icon(
                            onPressed: () => showMessage(
                              this.context,
                              'ميزة اختيار الصور غير مفعلة في هذه النسخة.',
                            ),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('تصوير الوثيقة'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'صورة ظهر البطاقة',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          OutlinedButton.icon(
                            onPressed: () => showMessage(
                              this.context,
                              'ميزة اختيار الصور غير مفعلة في هذه النسخة.',
                            ),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('تصوير الوثيقة'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () async {
                  final user = supabase.auth.currentUser;
                  if (user == null) return;

                  if (nameController.text.trim().isEmpty ||
                      docNumberController.text.trim().isEmpty ||
                      birthDate == null ||
                      issueDate == null) {
                    showMessage(
                      this.context,
                      'أكمل الاسم ورقم الوثيقة وتاريخ الميلاد وتاريخ الإصدار.',
                    );
                    return;
                  }

                  try {
                    await supabase.from('registration_requests').insert({
                      'user_id': user.id,
                      'full_name': nameController.text.trim(),
                      'phone': profile?['phone'],
                      'account_type': 'KYC_VERIFICATION',
                      'status': 'PENDING',
                    });

                    await supabase
                        .from('profiles')
                        .update({'kyc_status': 'PENDING'})
                        .eq('id', user.id);

                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);

                    showMessage(
                      this.context,
                      'تم إرسال طلب التوثيق بنجاح إلى الإدارة للمراجعة.',
                    );
                    await loadData();
                  } catch (e) {
                    showMessage(
                      this.context,
                      'تعذر إرسال طلب التوثيق. تحقق من الاتصال وصلاحيات الحساب.',
                    );
                  } finally {
                    nameController.dispose();
                    docNumberController.dispose();
                  }
                },
                style: FilledButton.styleFrom(backgroundColor: green),
                child: const Text('إرسال طلب التوثيق'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'مدى باي - بوابة العميل',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: loadData,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () => supabase.auth.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: green))
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 42,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'تعذر تحميل بيانات الحساب.',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error!,
                          textAlign: TextAlign.center,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
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
                            child: Icon(Icons.person, color: green),
                          ),
                          title: Text(
                            profile?['full_name']?.toString() ??
                                'عميل مدى باي',
                          ),
                          subtitle: Text(
                            'حالة التوثيق: ${profile?['kyc_status']?.toString().toUpperCase() == 'APPROVED' ? 'موثق ✓' : 'غير موثق أو قيد المراجعة'}',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.account_balance_wallet,
                            size: 32,
                            color: gold,
                          ),
                          title: const Text('الرصيد المتاح'),
                          subtitle: Text(
                            profile?['balance']?.toString() ?? '0.00',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'الخدمات السريعة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: deepGreen,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.5,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => checkVerificationAndProceed(
                              () => showMessage(
                                context,
                                'خدمة شحن الرصيد غير مربوطة بواجهة تنفيذ بعد.',
                              ),
                            ),
                            icon: const Icon(Icons.phone_android),
                            label: const Text('شحن رصيد وباقات'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => checkVerificationAndProceed(
                              () => showMessage(
                                context,
                                'خدمة تحويل الأموال غير مربوطة بواجهة تنفيذ بعد.',
                              ),
                            ),
                            icon: const Icon(Icons.swap_horiz),
                            label: const Text('تحويل أموال'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'آخر العمليات',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: deepGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (transactions.isEmpty)
                        const Card(
                          child: ListTile(
                            title: Text('لا توجد عمليات مسجلة حالياً.'),
                          ),
                        )
                      else
                        ...transactions.map(
                          (tx) => Card(
                            child: ListTile(
                              title: Text(
                                'معاملة: ${tx['service_id'] ?? 'عام'}',
                              ),
                              subtitle: Text(
                                'الحالة: ${tx['status'] ?? 'غير محددة'}',
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

ملف "customer_app/pubspec.yaml" — أضف الاعتماد التالي ضمن "dependencies" إذا لم يكن موجودًا:

shared_preferences: ^2.5.3

ثم نفّذ:

flutter pub get
