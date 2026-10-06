import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' as intl;

void main() {
  runApp(const MadaPayAdmin());
}

// ============================================================
// Mada Pay Admin
// نظام إدارة وصلاحيات - النسخة الأولية
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF147D64),
        ),
      ),
      home: const AdminLoginPage(),
    );
  }
}

// ============================================================
// اتجاه اللغة العربية
// ============================================================

const TextDirection arabicDirection = TextDirection.rtl;

// ============================================================
// الصلاحيات
// ============================================================

class Permissions {
  bool customersView;
  bool customersAdd;
  bool customersEdit;
  bool customersSuspend;

  bool balancesView;
  bool balancesEdit;

  bool transactionsView;
  bool transactionsExecute;

  bool servicesView;
  bool servicesManage;

  bool pricesEdit;
  bool commissionsEdit;

  bool agentsManage;
  bool distributorsManage;

  bool registrationRequests;
  bool employeesView;
  bool employeesManage;

  bool permissionsManage;

  bool providersManage;
  bool apiSettings;

  bool reportsView;
  bool financialReports;

  bool auditLog;
  bool systemSettings;

  Permissions({
    this.customersView = false,
    this.customersAdd = false,
    this.customersEdit = false,
    this.customersSuspend = false,
    this.balancesView = false,
    this.balancesEdit = false,
    this.transactionsView = false,
    this.transactionsExecute = false,
    this.servicesView = false,
    this.servicesManage = false,
    this.pricesEdit = false,
    this.commissionsEdit = false,
    this.agentsManage = false,
    this.distributorsManage = false,
    this.registrationRequests = false,
    this.employeesView = false,
    this.employeesManage = false,
    this.permissionsManage = false,
    this.providersManage = false,
    this.apiSettings = false,
    this.reportsView = false,
    this.financialReports = false,
    this.auditLog = false,
    this.systemSettings = false,
  });

  factory Permissions.owner() {
    return Permissions(
      customersView: true,
      customersAdd: true,
      customersEdit: true,
      customersSuspend: true,
      balancesView: true,
      balancesEdit: true,
      transactionsView: true,
      transactionsExecute: true,
      servicesView: true,
      servicesManage: true,
      pricesEdit: true,
      commissionsEdit: true,
      agentsManage: true,
      distributorsManage: true,
      registrationRequests: true,
      employeesView: true,
      employeesManage: true,
      permissionsManage: true,
      providersManage: true,
      apiSettings: true,
      reportsView: true,
      financialReports: true,
      auditLog: true,
      systemSettings: true,
    );
  }
}

// ============================================================
// نموذج طلب التسجيل
// ============================================================

class AdminRequest {
  String fullName;
  String phone;
  String country;
  String accountType;
  String requestedRole;
  String identityType;
  String identityNumber;
  String status;

  AdminRequest({
    required this.fullName,
    required this.phone,
    required this.country,
    required this.accountType,
    required this.requestedRole,
    required this.identityType,
    required this.identityNumber,
    this.status = 'قيد المراجعة',
  });
}

// ============================================================
// نموذج حساب إداري
// ============================================================

class AdminUser {
  String name;
  String phone;
  String role;
  bool active;
  Permissions permissions;

  AdminUser({
    required this.name,
    required this.phone,
    required this.role,
    this.active = true,
    required this.permissions,
  });
}

// ============================================================
// تخزين مؤقت للتجربة
// ============================================================

class AdminStore {
  static final List<AdminRequest> requests = [];

  static final List<AdminUser> admins = [
    AdminUser(
      name: 'المالك الرئيسي',
      phone: 'OWNER',
      role: 'OWNER',
      permissions: Permissions.owner(),
    ),
  ];
}

// ============================================================
// شاشة تسجيل الدخول
// ============================================================

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final TextEditingController phoneController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool obscurePassword = true;

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void login() {
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      showMessage('أدخل رقم الهاتف وكلمة المرور');
      return;
    }

    if (phone == 'OWNER' && password == 'OWNER') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OwnerDashboard(
            user: AdminStore.admins.first,
          ),
        ),
      );
      return;
    }

    AdminUser? admin;

    for (final item in AdminStore.admins) {
      if (item.phone == phone && item.active) {
        admin = item;
        break;
      }
    }

    if (admin != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AdminDashboard(
            user: admin!,
          ),
        ),
      );
      return;
    }

    showMessage(
      'بيانات الدخول غير صحيحة أو الحساب غير مفعل',
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: arabicDirection,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(
                    Icons.admin_panel_settings,
                    size: 90,
                    color: Color(0xFF147D64),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'مدى باي',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'نظام الإدارة',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 35),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'رقم الهاتف',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
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
                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const AdminRegistrationPage(),
                        ),
                      );
                    },
                    child: const Text(
                      'إنشاء حساب إداري جديد',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'ملاحظة: بيانات OWNER/OWNER للاختبار فقط، '
                    'وسيتم حذفها عند ربط النظام بالخادم.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// تسجيل حساب إداري
// ============================================================

class AdminRegistrationPage extends StatefulWidget {
  const AdminRegistrationPage({super.key});

  @override
  State<AdminRegistrationPage> createState() =>
      _AdminRegistrationPageState();
}

class _AdminRegistrationPageState
    extends State<AdminRegistrationPage> {
  final formKey = GlobalKey<FormState>();

  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nameController = TextEditingController();
  final identityNumberController = TextEditingController();

  String country = 'اليمن';
  String accountType = 'إداري';
  String role = 'EMPLOYEE';
  String identityType = 'البطاقة الشخصية';

  DateTime? birthDate;
  DateTime? issueDate;
  DateTime? expiryDate;

  XFile? identityImage;
  XFile? commercialImage;

  bool termsAccepted = false;

  final List<String> countries = [
    'اليمن',
    'السعودية',
    'الإمارات',
    'عُمان',
    'قطر',
    'الكويت',
    'البحرين',
    'مصر',
    'الأردن',
    'العراق',
    'تركيا',
    'الولايات المتحدة',
    'المملكة المتحدة',
  ];

  final List<String> roles = [
    'ADMIN',
    'MANAGER',
    'EMPLOYEE',
    'AGENT',
    'DISTRIBUTOR',
  ];

  final List<String> identityTypes = [
    'البطاقة الشخصية',
    'جواز السفر',
    'الإقامة',
  ];

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    identityNumberController.dispose();
    super.dispose();
  }

  Future<void> selectDate(
    void Function(DateTime) callback,
  ) async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (!mounted) return;

    if (selected != null) {
      callback(selected);
    }
  }

  Future<void> pickIdentityImage() async {
    final picker = ImagePicker();

    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (!mounted) return;

    if (image != null) {
      setState(() {
        identityImage = image;
      });
    }
  }

  Future<void> pickCommercialImage() async {
    final picker = ImagePicker();

    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (!mounted) return;

    if (image != null) {
      setState(() {
        commercialImage = image;
      });
    }
  }

  void submit() {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (passwordController.text !=
        confirmPasswordController.text) {
      message('كلمتا المرور غير متطابقتين');
      return;
    }

    if (!termsAccepted) {
      message('يجب الموافقة على الشروط والأحكام');
      return;
    }

    if (identityImage == null) {
      message('أرفق صورة وثيقة الهوية');
      return;
    }

    if (birthDate == null ||
        issueDate == null ||
        expiryDate == null) {
      message('أكمل جميع التواريخ المطلوبة');
      return;
    }

    if (expiryDate!.isBefore(issueDate!)) {
      message(
        'تاريخ انتهاء الهوية يجب أن يكون بعد تاريخ الإصدار',
      );
      return;
    }

    final phone = phoneController.text.trim();

    final existing = AdminStore.admins.any(
      (admin) => admin.phone == phone,
    );

    if (existing) {
      message('رقم الهاتف مرتبط بحساب إداري بالفعل');
      return;
    }

    final pendingRequest = AdminStore.requests.any(
      (request) =>
          request.phone == phone &&
          request.status == 'قيد المراجعة',
    );

    if (pendingRequest) {
      message(
        'يوجد طلب تسجيل قيد المراجعة لهذا الرقم',
      );
      return;
    }

    AdminStore.requests.add(
      AdminRequest(
        fullName: nameController.text.trim(),
        phone: phone,
        country: country,
        accountType: accountType,
        requestedRole: role,
        identityType: identityType,
        identityNumber:
            identityNumberController.text.trim(),
      ),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('تم إرسال الطلب'),
        content: const Text(
          'تم إرسال طلب إنشاء الحساب إلى المالك الرئيسي.\n\n'
          'لن يتم تفعيل الحساب حتى يقوم المالك بمراجعة '
          'الطلب والموافقة عليه وتحديد الصلاحيات.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('حسنًا'),
          ),
        ],
      ),
    );
  }

  void message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
      ),
    );
  }

  InputDecoration decoration(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: const OutlineInputBorder(),
    );
  }

  String dateText(DateTime? date) {
    if (date == null) {
      return 'اختر التاريخ';
    }

    return intl.DateFormat('yyyy/MM/dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: arabicDirection,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إنشاء حساب إداري'),
        ),
        body: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const Text(
                'بيانات الحساب',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: nameController,
                decoration: decoration(
                  'الاسم الكامل حسب الهوية',
                  Icons.person,
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'أدخل الاسم الكامل';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: decoration(
                  'رقم الهاتف',
                  Icons.phone,
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'أدخل رقم الهاتف';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: country,
                decoration: decoration(
                  'الدولة',
                  Icons.public,
                ),
                items: countries
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      country = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: decoration(
                  'كلمة المرور',
                  Icons.lock,
                ),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'كلمة المرور يجب ألا تقل عن 6 أحرف';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: decoration(
                  'تأكيد كلمة المرور',
                  Icons.lock_outline,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'أكد كلمة المرور';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 25),
              const Text(
                'نوع الحساب الإداري',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: role,
                decoration: decoration(
                  'الدور المطلوب',
                  Icons.admin_panel_settings,
                ),
                items: roles
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      role = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: accountType,
                decoration: decoration(
                  'نوع النشاط',
                  Icons.business,
                ),
                items: const [
                  'إداري',
                  'وكيل',
                  'موزع',
                  'موظف',
                  'إدارة',
                ]
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      accountType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 25),
              const Text(
                'بيانات الهوية',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: identityType,
                decoration: decoration(
                  'نوع الهوية',
                  Icons.badge,
                ),
                items: identityTypes
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      identityType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: identityNumberController,
                decoration: decoration(
                  'رقم الهوية',
                  Icons.numbers,
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'أدخل رقم الهوية';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              dateButton(
                'تاريخ الميلاد',
                birthDate,
                () {
                  selectDate(
                    (date) => setState(() {
                      birthDate = date;
                    }),
                  );
                },
              ),
              const SizedBox(height: 10),
              dateButton(
                'تاريخ إصدار الهوية',
                issueDate,
                () {
                  selectDate(
                    (date) => setState(() {
                      issueDate = date;
                    }),
                  );
                },
              ),
              const SizedBox(height: 10),
              dateButton(
                'تاريخ انتهاء الهوية',
                expiryDate,
                () {
                  selectDate(
                    (date) => setState(() {
                      expiryDate = date;
                    }),
                  );
                },
              ),
              const SizedBox(height: 15),
              OutlinedButton.icon(
                onPressed: pickIdentityImage,
                icon: const Icon(Icons.upload_file),
                label: Text(
                  identityImage == null
                      ? 'إرفاق صورة الهوية'
                      : 'تم إرفاق صورة الهوية ✓',
                ),
              ),
              if (role == 'AGENT' ||
                  role == 'DISTRIBUTOR')
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: OutlinedButton.icon(
                    onPressed: pickCommercialImage,
                    icon: const Icon(Icons.business),
                    label: Text(
                      commercialImage == null
                          ? 'إرفاق السجل التجاري / عقد الإيجار'
                          : 'تم إرفاق المستند ✓',
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              CheckboxListTile(
                value: termsAccepted,
                onChanged: (value) {
                  setState(() {
                    termsAccepted = value ?? false;
                  });
                },
                title: const Text(
                  'أوافق على سياسة الخصوصية والشروط والأحكام',
                ),
                controlAffinity:
                    ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 55,
                child: FilledButton.icon(
                  onPressed: submit,
                  icon: const Icon(Icons.send),
                  label: const Text(
                    'إرسال طلب إنشاء الحساب',
                    style: TextStyle(fontSize: 17),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget dateButton(
    String title,
    DateTime? date,
    VoidCallback onPressed,
  ) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.calendar_month),
      label: Align(
        alignment: Alignment.centerRight,
        child: Text(
          '$title: ${dateText(date)}',
        ),
      ),
    );
  }
}

// ============================================================
// لوحة المالك الرئيسي
// ============================================================

class OwnerDashboard extends StatefulWidget {
  final AdminUser user;

  const OwnerDashboard({
    super.key,
    required this.user,
  });

  @override
  State<OwnerDashboard> createState() =>
      _OwnerDashboardState();
}

class _OwnerDashboardState
    extends State<OwnerDashboard> {
  void openRequests() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const RegistrationRequestsPage(),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void openAdmins() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const AdminManagementPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: arabicDirection,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'لوحة المالك الرئيسي',
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text(
              'مرحبًا بك، المالك الرئيسي',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            dashboardCard(
              'طلبات التسجيل',
              '${AdminStore.requests.length} طلب',
              Icons.person_add,
              openRequests,
            ),
            dashboardCard(
              'المستخدمون الإداريون',
              '${AdminStore.admins.length} حساب',
              Icons.groups,
              openAdmins,
            ),
            dashboardCard(
              'العملاء',
              'إدارة العملاء',
              Icons.people,
              () {},
            ),
            dashboardCard(
              'الأرصدة',
              'إدارة الأرصدة',
              Icons.account_balance_wallet,
              () {},
            ),
            dashboardCard(
              'التحويلات',
              'إدارة التحويلات',
              Icons.swap_horiz,
              () {},
            ),
            dashboardCard(
              'الخدمات والأسعار',
              'إدارة الخدمات والعمولات',
              Icons.miscellaneous_services,
              () {},
            ),
            dashboardCard(
              'التقارير',
              'التقارير المالية والتشغيلية',
              Icons.bar_chart,
              () {},
            ),
            dashboardCard(
              'الإعدادات',
              'إعدادات النظام',
              Icons.settings,
              () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget dashboardCard(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          size: 32,
          color: const Color(0xFF147D64),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(
          Icons.arrow_back_ios,
        ),
        onTap: onTap,
      ),
    );
  }
}

// ============================================================
// طلبات التسجيل
// ============================================================

class RegistrationRequestsPage
    extends StatefulWidget {
  const RegistrationRequestsPage({
    super.key,
  });

  @override
  State<RegistrationRequestsPage> createState() =>
      _RegistrationRequestsPageState();
}

class _RegistrationRequestsPageState
    extends State<RegistrationRequestsPage> {
  void approve(AdminRequest request) {
    if (request.status != 'قيد المراجعة') {
      return;
    }

    final alreadyExists = AdminStore.admins.any(
      (admin) => admin.phone == request.phone,
    );

    setState(() {
      request.status = 'مقبول';

      if (!alreadyExists) {
        AdminStore.admins.add(
          AdminUser(
            name: request.fullName,
            phone: request.phone,
            role: request.requestedRole,
            permissions: Permissions(),
          ),
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم قبول الحساب. يرجى تحديد الصلاحيات.',
        ),
      ),
    );
  }

  void reject(AdminRequest request) {
    if (request.status != 'قيد المراجعة') {
      return;
    }

    setState(() {
      request.status = 'مرفوض';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: arabicDirection,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'طلبات التسجيل',
          ),
        ),
        body: AdminStore.requests.isEmpty
            ? const Center(
                child: Text(
                  'لا توجد طلبات تسجيل حاليًا',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount:
                    AdminStore.requests.length,
                itemBuilder: (_, index) {
                  final request =
                      AdminStore.requests[index];

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.fullName,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'الهاتف: ${request.phone}',
                          ),
                          Text(
                            'الدولة: ${request.country}',
                          ),
                          Text(
                            'نوع الحساب: ${request.accountType}',
                          ),
                          Text(
                            'الدور المطلوب: ${request.requestedRole}',
                          ),
                          Text(
                            'الهوية: ${request.identityType}',
                          ),
                          Text(
                            'رقم الهوية: ${request.identityNumber}',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'الحالة: ${request.status}',
                            style: TextStyle(
                              color: request.status == 'مقبول'
                                  ? Colors.green
                                  : request.status == 'مرفوض'
                                      ? Colors.red
                                      : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (request.status == 'قيد المراجعة')
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () =>
                                        approve(request),
                                    child: const Text('قبول'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        reject(request),
                                    child: const Text('رفض'),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

// ============================================================
// إدارة الحسابات الإدارية
// ============================================================

class AdminManagementPage
    extends StatefulWidget {
  const AdminManagementPage({
    super.key,
  });

  @override
  State<AdminManagementPage> createState() =>
      _AdminManagementPageState();
}

class _AdminManagementPageState
    extends State<AdminManagementPage> {
  void editPermissions(AdminUser admin) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PermissionsPage(admin: admin),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: arabicDirection,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'الحسابات الإدارية',
          ),
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: AdminStore.admins.length,
          itemBuilder: (_, index) {
            final admin = AdminStore.admins[index];

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    admin.role.isNotEmpty
                        ? admin.role.substring(0, 1)
                        : '?',
                  ),
                ),
                title: Text(admin.name),
                subtitle: Text(
                  '${admin.role} • '
                  '${admin.active ? 'نشط' : 'موقوف'}',
                ),
                trailing: admin.role == 'OWNER'
                    ? const Icon(
                        Icons.lock,
                        color: Colors.red,
                      )
                    : IconButton(
                        icon: const Icon(
                          Icons.security,
                        ),
                        onPressed: () =>
                            editPermissions(admin),
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// شاشة الصلاحيات
// ============================================================

class PermissionsPage
    extends StatefulWidget {
  final AdminUser admin;

  const PermissionsPage({
    super.key,
    required this.admin,
  });

  @override
  State<PermissionsPage> createState() =>
      _PermissionsPageState();
}

class _PermissionsPageState
    extends State<PermissionsPage> {
  late Permissions p;

  @override
  void initState() {
    super.initState();
    p = widget.admin.permissions;
  }

  void save() {
    widget.admin.permissions = p;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم حفظ الصلاحيات',
        ),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: arabicDirection,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'صلاحيات ${widget.admin.name}',
          ),
          actions: [
            IconButton(
              onPressed: save,
              icon: const Icon(
                Icons.save,
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const Text(
              'العملاء',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            permission(
              'مشاهدة العملاء',
              p.customersView,
              (v) => p.customersView = v,
            ),
            permission(
              'إضافة عميل',
              p.customersAdd,
              (v) => p.customersAdd = v,
            ),
            permission(
              'تعديل العملاء',
              p.customersEdit,
              (v) => p.customersEdit = v,
            ),
            permission(
              'تعليق العملاء',
              p.customersSuspend,
              (v) => p.customersSuspend = v,
            ),
            const Divider(),
            const Text(
              'الأرصدة',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            permission(
              'مشاهدة الأرصدة',
              p.balancesView,
              (v) => p.balancesView = v,
            ),
            permission(
              'تعديل الأرصدة',
              p.balancesEdit,
              (v) => p.balancesEdit = v,
            ),
            const Divider(),
            const Text(
              'التحويلات',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            permission(
              'مشاهدة التحويلات',
              p.transactionsView,
              (v) => p.transactionsView = v,
            ),
            permission(
              'تنفيذ التحويلات',
              p.transactionsExecute,
              (v) => p.transactionsExecute = v,
            ),
            const Divider(),
            const Text(
              'الخدمات',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            permission(
              'مشاهدة الخدمات',
              p.servicesView,
              (v) => p.servicesView = v,
            ),
            permission(
              'إدارة الخدمات',
              p.servicesManage,
              (v) => p.servicesManage = v,
            ),
            permission(
              'تعديل الأسعار',
              p.pricesEdit,
              (v) => p.pricesEdit = v,
            ),
            permission(
              'تعديل العمولات',
              p.commissionsEdit,
              (v) => p.commissionsEdit = v,
            ),
            const Divider(),
            const Text(
              'الوكلاء والموزعون',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            permission(
              'إدارة الوكلاء',
              p.agentsManage,
              (v) => p.agentsManage = v,
            ),
            permission(
              'إدارة الموزعين',
              p.distributorsManage,
              (v) => p.distributorsManage = v,
            ),
            const Divider(),
            const Text(
              'الإدارة',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            permission(
              'طلبات التسجيل',
              p.registrationRequests,
              (v) => p.registrationRequests = v,
            ),
            permission(
              'مشاهدة الموظفين',
              p.employeesView,
              (v) => p.employeesView = v,
            ),
            permission(
              'إدارة الموظفين',
              p.employeesManage,
              (v) => p.employeesManage = v,
            ),
            permission(
              'إدارة الصلاحيات',
              p.permissionsManage,
              (v) => p.permissionsManage = v,
            ),
            const Divider(),
            const Text(
              'مزودو الخدمات و API',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            permission(
              'إدارة مزودي الخدمات',
              p.providersManage,
              (v) => p.providersManage = v,
            ),
            permission(
              'إعدادات API',
              p.apiSettings,
              (v) => p.apiSettings = v,
            ),
            const Divider(),
            const Text(
              'التقارير',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            permission(
              'مشاهدة التقارير',
              p.reportsView,
              (v) => p.reportsView = v,
            ),
            permission(
              'التقارير المالية',
              p.financialReports,
              (v) => p.financialReports = v,
            ),
            permission(
              'سجل العمليات',
              p.auditLog,
              (v) => p.auditLog = v,
            ),
            const Divider(),
            const Text(
              'النظام',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            permission(
              'إعدادات النظام',
              p.systemSettings,
              (v) => p.systemSettings = v,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: save,
              icon: const Icon(Icons.save),
              label: const Text(
                'حفظ الصلاحيات',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget permission(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: (newValue) {
        setState(() {
          onChanged(newValue);
        });
      },
    );
  }
}

// ============================================================
// لوحة المستخدم الإداري العادي
// ============================================================

class AdminDashboard
    extends StatelessWidget {
  final AdminUser user;

  const AdminDashboard({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final p = user.permissions;

    return Directionality(
      textDirection: arabicDirection,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'مدى باي - ${user.role}',
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              'مرحبًا ${user.name}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            if (p.customersView)
              menu(
                context,
                'العملاء',
                Icons.people,
              ),
            if (p.balancesView)
              menu(
                context,
                'الأرصدة',
                Icons.account_balance_wallet,
              ),
            if (p.transactionsView)
              menu(
                context,
                'التحويلات',
                Icons.swap_horiz,
              ),
            if (p.servicesView)
              menu(
                context,
                'الخدمات',
                Icons.miscellaneous_services,
              ),
            if (p.agentsManage)
              menu(
                context,
                'الوكلاء',
                Icons.support_agent,
              ),
            if (p.distributorsManage)
              menu(
                context,
                'الموزعون',
                Icons.inventory,
              ),
            if (p.reportsView)
              menu(
                context,
                'التقارير',
                Icons.bar_chart,
              ),
            if (p.financialReports)
              menu(
                context,
                'التقارير المالية',
                Icons.attach_money,
              ),
            if (p.auditLog)
              menu(
                context,
                'سجل العمليات',
                Icons.history,
              ),
            if (p.permissionsManage)
              menu(
                context,
                'إدارة الصلاحيات',
                Icons.security,
              ),
            const SizedBox(height: 30),
            const Text(
              'الصلاحيات غير الممنوحة لا تظهر هنا.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget menu(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: const Color(0xFF147D64),
        ),
        title: Text(title),
        trailing: const Icon(
          Icons.arrow_back_ios,
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'قسم $title سيتم ربطه بالـBackend لاحقًا.',
              ),
            ),
          );
        },
      ),
    );
  }
}
