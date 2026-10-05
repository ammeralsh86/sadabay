
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

void main() {
  runApp(const MadaPay());
}

class MadaPay extends StatefulWidget {
  const MadaPay({super.key});

  @override
  State<MadaPay> createState() => _MadaPayState();
}

class _MadaPayState extends State<MadaPay> {
  int page = 0;
  double balance = 15000;
  String username = 'مستخدم مدى باي';
  String apiUrl = '';
  String apiToken = '';
  String apiStatus = 'غير متصل';

  final List<Map<String, dynamic>> transactions = [];

  final Color primary = const Color(0xFF147D64);

  final List<Map<String, dynamic>> services = [
    {'name': 'تحويل لحساب', 'icon': Icons.swap_horiz},
    {'name': 'شحن رصيد', 'icon': Icons.phone_android},
    {'name': 'تسديد إنترنت', 'icon': Icons.wifi},
    {'name': 'باقات الإنترنت', 'icon': Icons.language},
    {'name': 'بطاقات الألعاب', 'icon': Icons.sports_esports},
    {'name': 'خدمات أخرى', 'icon': Icons.grid_view},
  ];

  void notify(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void addDemoTransaction(String title, double amount) {
    setState(() {
      balance -= amount;
      transactions.insert(0, {
        'title': title,
        'amount': amount,
        'date': DateTime.now().toString().substring(0, 16),
      });
    });
  }

  void openService(String name) {
    final amountController = TextEditingController();
    final targetController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(name, textAlign: TextAlign.right),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: targetController,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                labelText: 'رقم الحساب أو الهاتف أو المستفيد',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                labelText: 'المبلغ',
                suffixText: 'ر.ي',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'هذه عملية تجريبية فقط، ولن يتم إرسال أموال.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (targetController.text.trim().isEmpty ||
                  amount == null ||
                  amount <= 0) {
                notify('أدخل بيانات صحيحة');
                return;
              }
              if (amount > balance) {
                notify('الرصيد التجريبي غير كافٍ');
                return;
              }
              Navigator.pop(dialogContext);
              addDemoTransaction(name, amount);
              notify('تم تسجيل عملية تجريبية');
            },
            child: const Text('تجربة العملية'),
          ),
        ],
      ),
    );
  }

  Future<void> testApi() async {
    if (apiUrl.trim().isEmpty) {
      notify('أدخل عنوان الخادم أولاً');
      return;
    }

    setState(() => apiStatus = 'جارٍ الاتصال...');

    try {
      final uri = Uri.parse(apiUrl.trim());
      if (uri.scheme != 'https') {
        throw Exception('يجب استخدام HTTPS');
      }

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      final request = await client.getUrl(uri);
      if (apiToken.trim().isNotEmpty) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer ${apiToken.trim()}',
        );
      }
      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );
      await response.drain();
      client.close();

      setState(() => apiStatus = 'استجابة HTTP ${response.statusCode}');
      notify('وصلنا إلى الخادم. تحقق من مواصفات API.');
    } catch (e) {
      setState(() => apiStatus = 'فشل الاتصال');
      notify('تعذر الاتصال: $e');
    }
  }

  Widget header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.account_balance_wallet, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'مدى باي',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(username, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            IconButton(
              onPressed: () => notify('لا توجد إشعارات جديدة'),
              icon: const Icon(Icons.notifications_none, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget balanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الرصيد المتاح', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            '${balance.toStringAsFixed(0)} ر.ي',
            style: TextStyle(
              color: primary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              quickAction(Icons.add_circle_outline, 'إيداع', () {
                notify('الإيداع الحقيقي يحتاج إلى ربط مزود');
              }),
              quickAction(Icons.send, 'تحويل', () => openService('تحويل لحساب')),
              quickAction(Icons.receipt_long, 'السجل', () {
                setState(() => page = 2);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget quickAction(IconData icon, String label, VoidCallback action) {
    return InkWell(
      onTap: action,
      child: Column(
        children: [
          Icon(icon, color: primary, size: 25),
          const SizedBox(height: 5),
          Text(label),
        ],
      ),
    );
  }

  Widget serviceGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: services.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.95,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final service = services[index];
        return InkWell(
          onTap: () => openService(service['name'] as String),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(service['icon'] as IconData, color: primary, size: 30),
                const SizedBox(height: 10),
                Text(
                  service['name'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget homePage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        balanceCard(),
        const SizedBox(height: 24),
        const Text(
          'الخدمات',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        serviceGrid(),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'آخر العمليات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => setState(() => page = 2),
              child: const Text('عرض الكل'),
            ),
          ],
        ),
        ...transactions.take(3).map((tx) => transactionTile(tx)),
      ],
    );
  }

  Widget transactionTile(Map<String, dynamic> tx) {
    return Card(
      color: Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: primary.withValues(alpha: 0.1),
          child: Icon(Icons.receipt_long, color: primary),
        ),
        title: Text(tx['title'] as String),
        subtitle: Text(tx['date'] as String),
        trailing: Text(
          '-${(tx['amount'] as double).toStringAsFixed(0)}',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget servicesPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'جميع الخدمات',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...services.map(
          (service) => Card(
            color: Colors.white,
            child: ListTile(
              leading: Icon(service['icon'] as IconData, color: primary),
              title: Text(service['name'] as String),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => openService(service['name'] as String),
            ),
          ),
        ),
      ],
    );
  }

  Widget reportsPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'التقارير وسجل العمليات',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          color: Colors.white,
          child: ListTile(
            title: const Text('الرصيد التجريبي الحالي'),
            trailing: Text('${balance.toStringAsFixed(0)} ر.ي'),
          ),
        ),
        const SizedBox(height: 12),
        if (transactions.isEmpty)
          const Padding(
            padding: EdgeInsets.all(30),
            child: Center(child: Text('لا توجد عمليات حتى الآن')),
          )
        else
          ...transactions.map(transactionTile),
      ],
    );
  }

  Widget accountPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const CircleAvatar(
          radius: 40,
          child: Icon(Icons.person, size: 40),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            username,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          color: Colors.white,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('تغيير اسم المستخدم'),
                trailing: const Icon(Icons.chevron_left),
                onTap: changeUsername,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.settings_ethernet),
                title: const Text('إعدادات ربط API'),
                subtitle: Text(apiStatus),
                trailing: const Icon(Icons.chevron_left),
                onTap: apiSettings,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('حول التطبيق'),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'مدى باي',
                    applicationVersion: '0.1.0',
                    children: const [
                      Text('نسخة أولية تجريبية قيد التطوير.'),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void changeUsername() {
    final controller = TextEditingController(text: username);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('اسم المستخدم'),
        content: TextField(
          controller: controller,
          textAlign: TextAlign.right,
          decoration: const InputDecoration(labelText: 'الاسم'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() => username = controller.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void apiSettings() {
    final urlController = TextEditingController(text: apiUrl);
    final tokenController = TextEditingController(text: apiToken);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'إعدادات API',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'عنوان الخادم (Base URL)',
                  hintText: 'https://example.com/api/health',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tokenController,
                obscureText: true,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'رمز تجريبي (Bearer Token)',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'الحالة: $apiStatus',
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  setState(() {
                    apiUrl = urlController.text.trim();
                    apiToken = tokenController.text.trim();
                  });
                  Navigator.pop(ctx);
                  testApi();
                },
                child: const Text('حفظ وتجربة الاتصال'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إغلاق'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      homePage(),
      servicesPage(),
      reportsPage(),
      accountPage(),
    ];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'مدى باي',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: primary),
        scaffoldBackgroundColor: const Color(0xFFF4F7F6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF4F7F6),
          centerTitle: true,
        ),
      ),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Column(
            children: [
              header(),
              Expanded(child: pages[page]),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: page,
            onDestinationSelected: (index) {
              setState(() => page = index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'الرئيسية',
              ),
              NavigationDestination(
                icon: Icon(Icons.grid_view),
                label: 'الخدمات',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long),
                label: 'التقارير',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                label: 'حسابي',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
