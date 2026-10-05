import 'package:flutter/material.dart';

void main() {
  runApp(const MadaPayAdmin());
}

class MadaPayAdmin extends StatelessWidget {
  const MadaPayAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mada Pay Admin',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
      ),
      home: const AdminLoginPage(),
    );
  }
}

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  bool hidePassword = true;

  void login() {
    final username = usernameController.text.trim();
    final password = passwordController.text;

    // حساب تجريبي مؤقت.
    // سيتم استبداله لاحقًا بنظام تسجيل دخول حقيقي عبر Backend.
    if (username == 'admin' && password == 'MadaPay@123') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AdminDashboard(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('بيانات تسجيل الدخول غير صحيحة'),
        ),
      );
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const Icon(
                      Icons.admin_panel_settings,
                      size: 90,
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Mada Pay Admin',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'لوحة إدارة مدى باي',
                      style: TextStyle(fontSize: 17),
                    ),

                    const SizedBox(height: 35),

                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم المستخدم',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: passwordController,
                      obscureText: hidePassword,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: const Icon(Icons.lock),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              hidePassword = !hidePassword;
                            });
                          },
                          icon: Icon(
                            hidePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: login,
                        child: const Text(
                          'تسجيل الدخول',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    const Text(
                      'الحساب التجريبي: admin',
                      style: TextStyle(fontSize: 13),
                    ),

                    const Text(
                      'كلمة المرور: MadaPay@123',
                      style: TextStyle(fontSize: 13),
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

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة التحكم'),
          actions: [
            IconButton(
              tooltip: 'تسجيل الخروج',
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminLoginPage(),
                  ),
                );
              },
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'مرحبًا بك في إدارة Mada Pay',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _statCard(
                    icon: Icons.people,
                    title: 'العملاء',
                    value: '0',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    icon: Icons.receipt_long,
                    title: 'العمليات',
                    value: '0',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _statCard(
                    icon: Icons.account_balance_wallet,
                    title: 'الأرصدة',
                    value: '0',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    icon: Icons.miscellaneous_services,
                    title: 'الخدمات',
                    value: '0',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            _adminButton(
              context,
              Icons.people,
              'إدارة العملاء',
              'إضافة وتعديل وإيقاف العملاء',
            ),

            _adminButton(
              context,
              Icons.miscellaneous_services,
              'إدارة الخدمات',
              'إدارة خدمات الشحن والتحويل والدفع',
            ),

            _adminButton(
              context,
              Icons.api,
              'مزودو API',
              'إدارة شركات ومزودي الخدمات',
            ),

            _adminButton(
              context,
              Icons.receipt_long,
              'العمليات',
              'متابعة عمليات العملاء',
            ),

            _adminButton(
              context,
              Icons.analytics,
              'التقارير',
              'الإحصائيات والتقارير المالية',
            ),

            _adminButton(
              context,
              Icons.settings,
              'إعدادات التطبيق',
              'إعدادات Mada Pay العامة',
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 35),
            const SizedBox(height: 8),
            Text(title),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _adminButton(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_back_ios),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$title سيتم تطويره في الخطوة التالية',
              ),
            ),
          );
        },
      ),
    );
  }
}
