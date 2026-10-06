import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl =
      String.fromEnvironment('SUPABASE_URL');

  const supabaseKey =
      String.fromEnvironment('SUPABASE_KEY');

  if (supabaseUrl.isNotEmpty &&
      supabaseKey.isNotEmpty) {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
  }

  runApp(const MadaPay());
}

class MadaPay extends StatefulWidget {
  const MadaPay({super.key});

  @override
  State<MadaPay> createState() => _MadaPayState();
}

class _MadaPayState extends State<MadaPay> {
  final Color primary = const Color(0xFF147D64);

  bool loggedIn = false;
  bool showRegister = false;

  String username = '';
  String phone = '';

  // ============================================================
  // حسابات تجريبية
  // ============================================================

  final Map<String, Map<String, String>> users = {
    '777777777': {
      'username': 'مستخدم مدى باي',
      'password': '123456',
    },
  };

  // ============================================================
  // بيانات التطبيق
  // ============================================================

  int page = 0;

  double balance = 15000;

  String apiUrl = '';
  String apiToken = '';
  String apiStatus = 'غير متصل';

  final List<Map<String, dynamic>> transactions = [];

  // ============================================================
  // الخدمات
  // ============================================================

  final List<Map<String, dynamic>> services = [
    {
      'name': 'تحويل لحساب',
      'icon': Icons.swap_horiz,
    },
    {
      'name': 'شحن رصيد',
      'icon': Icons.phone_android,
    },
    {
      'name': 'تسديد إنترنت',
      'icon': Icons.wifi,
    },
    {
      'name': 'باقات الإنترنت',
      'icon': Icons.language,
    },
    {
      'name': 'بطاقات الألعاب',
      'icon': Icons.sports_esports,
    },
    {
      'name': 'خدمات أخرى',
      'icon': Icons.grid_view,
    },
  ];

  // ============================================================
  // الدول
  //
  // هذه نسخة أولية.
  // سيتم لاحقًا نقل قاعدة الدول والتقسيمات إلى Backend.
  // ============================================================

  final List<Map<String, String>> countries = [
    {'name': 'اليمن', 'code': '+967'},
    {'name': 'السعودية', 'code': '+966'},
    {'name': 'الإمارات', 'code': '+971'},
    {'name': 'عُمان', 'code': '+968'},
    {'name': 'قطر', 'code': '+974'},
    {'name': 'البحرين', 'code': '+973'},
    {'name': 'الكويت', 'code': '+965'},
    {'name': 'مصر', 'code': '+20'},
    {'name': 'الأردن', 'code': '+962'},
    {'name': 'العراق', 'code': '+964'},
    {'name': 'سوريا', 'code': '+963'},
    {'name': 'لبنان', 'code': '+961'},
    {'name': 'تركيا', 'code': '+90'},
    {'name': 'الولايات المتحدة', 'code': '+1'},
    {'name': 'كندا', 'code': '+1'},
    {'name': 'المملكة المتحدة', 'code': '+44'},
    {'name': 'فرنسا', 'code': '+33'},
    {'name': 'ألمانيا', 'code': '+49'},
    {'name': 'إيطاليا', 'code': '+39'},
    {'name': 'إسبانيا', 'code': '+34'},
    {'name': 'الهند', 'code': '+91'},
    {'name': 'باكستان', 'code': '+92'},
    {'name': 'بنغلاديش', 'code': '+880'},
    {'name': 'ماليزيا', 'code': '+60'},
    {'name': 'إندونيسيا', 'code': '+62'},
    {'name': 'الصين', 'code': '+86'},
    {'name': 'اليابان', 'code': '+81'},
    {'name': 'كوريا الجنوبية', 'code': '+82'},
    {'name': 'أستراليا', 'code': '+61'},
    {'name': 'جنوب أفريقيا', 'code': '+27'},
    {'name': 'نيجيريا', 'code': '+234'},
    {'name': 'إثيوبيا', 'code': '+251'},
  ];

  // ============================================================
  // التقسيمات الإدارية - نسخة أولية لليمن
  //
  // البنية:
  // الدولة -> المحافظة -> المديرية -> الحي
  //
  // سيتم لاحقًا توسيعها لجميع دول العالم من Backend.
  // ============================================================

  final Map<String, Map<String, Map<String, List<String>>>>
      administrativeData = {
    'اليمن': {
      'أمانة العاصمة': {
        'آزال': [
          'حي آزال',
          'حي نقم',
          'حي بيت بوس',
        ],
        'التحرير': [
          'حي التحرير',
          'حي القاع',
          'حي بغداد',
        ],
        'معين': [
          'حي معين',
          'حي شملان',
          'حي عصر',
        ],
        'السبعين': [
          'حي السبعين',
          'حي حدة',
          'حي الصافية',
        ],
      },
      'عدن': {
        'المعلا': [
          'حي المعلا',
          'حي الدكة',
          'حي القلوعة',
        ],
        'التواهي': [
          'حي التواهي',
          'حي القلوعة',
          'حي جولد مور',
        ],
        'خور مكسر': [
          'حي خور مكسر',
          'حي العريش',
          'حي المطار',
        ],
        'الشيخ عثمان': [
          'حي الشيخ عثمان',
          'حي عبدالقوي',
          'حي الممدارة',
        ],
      },
      'تعز': {
        'القاهرة': [
          'حي القاهرة',
          'حي الروضة',
          'حي المسبح',
        ],
        'المظفر': [
          'حي المظفر',
          'حي باب موسى',
          'حي وادي القاضي',
        ],
        'صالة': [
          'حي صالة',
          'حي الحوبان',
          'حي الكمب',
        ],
      },
      'مأرب': {
        'مدينة مأرب': [
          'حي المطار',
          'حي الروضة',
          'حي الجامعة',
          'حي المجمع',
        ],
        'الوادي': [
          'حي الوادي',
        ],
      },
      'حضرموت': {
        'المكلا': [
          'حي المكلا',
          'حي فوة',
          'حي الديس',
          'حي خلف',
        ],
        'سيئون': [
          'حي سيئون',
          'حي السحيل',
          'حي القرن',
        ],
      },
      'الحديدة': {
        'الحوك': [
          'حي الحوك',
          'حي السلخانة',
        ],
        'الحالي': [
          'حي الحالي',
          'حي الربصة',
        ],
      },
      'إب': {
        'الظهار': [
          'حي الظهار',
          'حي الجامعة',
        ],
        'المشنة': [
          'حي المشنة',
          'حي المعاين',
        ],
      },
    },
  };

  // ============================================================
  // بيانات التسجيل
  // ============================================================

  String selectedCountry = 'اليمن';
  String countryCode = '+967';

  String? selectedProvince;
  String? selectedDistrict;
  String? selectedNeighborhood;

  String accountType = 'فردي';

  String identityType = 'بطاقة شخصية';

  DateTime? birthDate;
  DateTime? identityIssueDate;
  DateTime? identityExpiryDate;

  File? identityFrontImage;
  File? identityBackImage;
  File? commercialDocumentImage;

  bool privacyAccepted = false;

  bool registrationSent = false;

  // ============================================================
  // رسائل
  // ============================================================

  void notify(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // تسجيل الدخول
  // ============================================================

  void login(
    String enteredPhone,
    String password,
  ) {
    final cleanPhone = enteredPhone.trim();

    if (cleanPhone.isEmpty || password.isEmpty) {
      notify('أدخل رقم الهاتف وكلمة المرور');
      return;
    }

    final user = users[cleanPhone];

    if (user == null) {
      notify('لا يوجد حساب بهذا الرقم');
      return;
    }

    if (user['password'] != password) {
      notify('كلمة المرور غير صحيحة');
      return;
    }

    setState(() {
      loggedIn = true;
      phone = cleanPhone;
      username = user['username'] ?? 'مستخدم مدى باي';
      page = 0;
    });

    notify('تم تسجيل الدخول بنجاح');
  }

  // ============================================================
  // إنشاء الحساب
  // ============================================================

  void submitRegistration({
    required String phoneNumber,
    required String password,
    required String confirmPassword,
    required String fullName,
    required String identityNumber,
  }) {
    if (phoneNumber.trim().isEmpty) {
      notify('أدخل رقم الهاتف');
      return;
    }

    if (password.length < 6) {
      notify('كلمة المرور يجب أن تكون 6 أحرف أو أرقام على الأقل');
      return;
    }

    if (password != confirmPassword) {
      notify('كلمتا المرور غير متطابقتين');
      return;
    }

    if (fullName.trim().length < 5) {
      notify('أدخل الاسم الكامل حسب الهوية');
      return;
    }

    if (birthDate == null) {
      notify('اختر تاريخ الميلاد');
      return;
    }

    if (selectedCountry.isEmpty) {
      notify('اختر الدولة');
      return;
    }

    if (selectedProvince == null) {
      notify('اختر المحافظة أو الولاية');
      return;
    }

    if (selectedDistrict == null) {
      notify('اختر المديرية أو التقسيم الإداري');
      return;
    }

    if (selectedNeighborhood == null) {
      notify('اختر الحي أو المنطقة');
      return;
    }

    if (accountType != 'فردي') {
      if (commercialDocumentImage == null) {
        notify('أرفق السجل التجاري أو عقد الإيجار');
        return;
      }
    }

    if (identityNumber.trim().isEmpty) {
      notify('أدخل رقم الهوية');
      return;
    }

    if (identityIssueDate == null) {
      notify('اختر تاريخ إصدار الهوية');
      return;
    }

    if (identityExpiryDate == null) {
      notify('اختر تاريخ انتهاء الهوية');
      return;
    }

    if (identityFrontImage == null) {
      notify('أرفق صورة المستند الثبوتي');
      return;
    }

    if (!privacyAccepted) {
      notify('يجب الموافقة على سياسة الخصوصية والشروط');
      return;
    }

    final fullPhone = '$countryCode${phoneNumber.trim()}';

    if (users.containsKey(fullPhone)) {
      notify('رقم الهاتف مسجل مسبقًا');
      return;
    }

    // ========================================================
    // في هذه المرحلة نحفظ الحساب بشكل تجريبي فقط.
    //
    // في النسخة الحقيقية سيتم إرسال الطلب إلى Backend
    // ليظهر مباشرة في تطبيق الأدمن للمراجعة.
    // ========================================================

    users[fullPhone] = {
      'username': fullName.trim(),
      'password': password,
    };

    setState(() {
      registrationSent = true;
      showRegister = false;
    });

    notify(
      'تم إرسال طلب التسجيل بنجاح وهو الآن قيد مراجعة الإدارة',
    );
  }

  // ============================================================
  // اختيار صورة
  // ============================================================

  Future<File?> pickImage() async {
    final picker = ImagePicker();

    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) {
      return null;
    }

    return File(image.path);
  }

  // ============================================================
  // اختيار تاريخ
  // ============================================================

  Future<DateTime?> selectDate({
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    return showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(1900),
      lastDate: lastDate ?? DateTime(2100),
      locale: const Locale('ar'),
    );
  }

  // ============================================================
  // تسجيل الخروج
  // ============================================================

  void logout() {
    setState(() {
      loggedIn = false;
      showRegister = false;
      page = 0;
    });

    notify('تم تسجيل الخروج');
  }

  // ============================================================
  // العمليات التجريبية
  // ============================================================

  void addDemoTransaction(
    String title,
    double amount,
  ) {
    setState(() {
      balance -= amount;

      transactions.insert(
        0,
        {
          'title': title,
          'amount': amount,
          'date': DateTime.now()
              .toString()
              .substring(0, 16),
        },
      );
    });
  }

  void openService(String name) {
    final amountController = TextEditingController();
    final targetController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          name,
          textAlign: TextAlign.right,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: targetController,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                labelText:
                    'رقم الحساب أو الهاتف أو المستفيد',
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
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
              ),
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
              final amount = double.tryParse(
                amountController.text.trim(),
              );

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

              addDemoTransaction(
                name,
                amount,
              );

              notify('تم تسجيل عملية تجريبية');
            },
            child: const Text('تجربة العملية'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // اختبار API
  // ============================================================

  Future<void> testApi() async {
    if (apiUrl.trim().isEmpty) {
      notify('أدخل عنوان الخادم أولاً');
      return;
    }

    setState(() {
      apiStatus = 'جارٍ الاتصال...';
    });

    try {
      final uri = Uri.parse(apiUrl.trim());

      if (uri.scheme != 'https') {
        throw Exception('يجب استخدام HTTPS');
      }

      final client = HttpClient();

      client.connectionTimeout =
          const Duration(seconds: 10);

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

      setState(() {
        apiStatus =
            'استجابة HTTP ${response.statusCode}';
      });

      notify(
        'وصلنا إلى الخادم. تحقق من مواصفات API.',
      );
    } catch (e) {
      setState(() {
        apiStatus = 'فشل الاتصال';
      });

      notify('تعذر الاتصال بالخادم');
    }
  }

  // ============================================================
  // اختيار الدولة
  // ============================================================

  Widget countrySelector() {
    return DropdownButtonFormField<String>(
      value: selectedCountry,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'الدولة',
        prefixIcon: Icon(Icons.public),
        border: OutlineInputBorder(),
      ),
      items: countries.map((country) {
        return DropdownMenuItem<String>(
          value: country['name'],
          child: Text(
            '${country['name']} (${country['code']})',
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value == null) return;

        final selected = countries.firstWhere(
          (country) => country['name'] == value,
        );

        setState(() {
          selectedCountry = value;
          countryCode = selected['code']!;

          selectedProvince = null;
          selectedDistrict = null;
          selectedNeighborhood = null;
        });
      },
    );
  }

  // ============================================================
  // مفتاح الدولة + رقم الهاتف
  // ============================================================

  Widget phoneField(
    TextEditingController controller,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 135,
          child: DropdownButtonFormField<String>(
            value: countryCode,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'المفتاح',
              border: OutlineInputBorder(),
            ),
            items: countries.map((country) {
              return DropdownMenuItem<String>(
                value: country['code'],
                child: Text(
                  '${country['code']} ${country['name']}',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                countryCode = value;
              });
            },
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              labelText: 'رقم الهاتف',
              prefixIcon:
                  Icon(Icons.phone_android),
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // المحافظة
  // ============================================================

  Widget provinceSelector() {
    final countryData =
        administrativeData[selectedCountry];

    final provinces =
        countryData?.keys.toList() ?? [];

    return DropdownButtonFormField<String>(
      value: selectedProvince,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'المحافظة / الولاية / المقاطعة',
        prefixIcon: Icon(Icons.location_city),
        border: OutlineInputBorder(),
      ),
      items: provinces.map((province) {
        return DropdownMenuItem<String>(
          value: province,
          child: Text(province),
        );
      }).toList(),
      onChanged: provinces.isEmpty
          ? null
          : (value) {
              setState(() {
                selectedProvince = value;
                selectedDistrict = null;
                selectedNeighborhood = null;
              });
            },
    );
  }

  // ============================================================
  // المديرية
  // ============================================================

  Widget districtSelector() {
    final districts =
        administrativeData[selectedCountry]
                ?[selectedProvince ?? '']
                ?.keys
                .toList() ??
            [];

    return DropdownButtonFormField<String>(
      value: selectedDistrict,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText:
            'المديرية / المنطقة الإدارية',
        prefixIcon:
            Icon(Icons.location_on_outlined),
        border: OutlineInputBorder(),
      ),
      items: districts.map((district) {
        return DropdownMenuItem<String>(
          value: district,
          child: Text(district),
        );
      }).toList(),
      onChanged: districts.isEmpty
          ? null
          : (value) {
              setState(() {
                selectedDistrict = value;
                selectedNeighborhood = null;
              });
            },
    );
  }

  // ============================================================
  // الحي
  // ============================================================

  Widget neighborhoodSelector() {
    final neighborhoods =
        administrativeData[selectedCountry]
                ?[selectedProvince ?? '']
                ?[selectedDistrict ?? ''] ??
            [];

    return DropdownButtonFormField<String>(
      value: selectedNeighborhood,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'الحي / المنطقة',
        prefixIcon: Icon(
          Icons.home_work_outlined,
        ),
        border: OutlineInputBorder(),
      ),
      items: neighborhoods.map((neighborhood) {
        return DropdownMenuItem<String>(
          value: neighborhood,
          child: Text(neighborhood),
        );
      }).toList(),
      onChanged: neighborhoods.isEmpty
          ? null
          : (value) {
              setState(() {
                selectedNeighborhood = value;
              });
            },
    );
  }

  // ============================================================
  // نوع الحساب
  // ============================================================

  Widget accountTypeSelector() {
    return DropdownButtonFormField<String>(
      value: accountType,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'نوع الحساب',
        prefixIcon: Icon(
          Icons.account_balance_outlined,
        ),
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(
          value: 'فردي',
          child: Text('فردي'),
        ),
        DropdownMenuItem(
          value: 'تجاري',
          child: Text('تجاري'),
        ),
        DropdownMenuItem(
          value: 'موزع',
          child: Text('موزع'),
        ),
        DropdownMenuItem(
          value: 'وكيل',
          child: Text('وكيل'),
        ),
      ],
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          accountType = value;

          if (accountType == 'فردي') {
            commercialDocumentImage = null;
          }
        });
      },
    );
  }

  // ============================================================
  // نوع الهوية
  // ============================================================

  Widget identityTypeSelector() {
    return DropdownButtonFormField<String>(
      value: identityType,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'نوع الهوية',
        prefixIcon: Icon(
          Icons.badge_outlined,
        ),
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(
          value: 'جواز سفر',
          child: Text('جواز سفر'),
        ),
        DropdownMenuItem(
          value: 'بطاقة شخصية',
          child: Text('بطاقة شخصية'),
        ),
        DropdownMenuItem(
          value: 'إقامة',
          child: Text('إقامة'),
        ),
      ],
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          identityType = value;
          identityFrontImage = null;
          identityBackImage = null;
        });
      },
    );
  }

  // ============================================================
  // التاريخ
  // ============================================================

  Widget dateButton({
    required String title,
    required DateTime? value,
    required VoidCallback onPressed,
  }) {
    final text = value == null
        ? 'اختيار التاريخ'
        : '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: title,
          prefixIcon:
              const Icon(Icons.calendar_month),
          border: const OutlineInputBorder(),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: value == null
                ? Colors.grey
                : Colors.black,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // رفع مستند
  // ============================================================

  Widget documentBox({
    required String title,
    required File? image,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius:
              BorderRadius.circular(15),
          border: Border.all(
            color: Colors.grey.shade300,
          ),
        ),
        child: image == null
            ? Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 42,
                    color: primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'اضغط لاختيار الصورة',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius:
                    BorderRadius.circular(15),
                child: Image.file(
                  image,
                  width: double.infinity,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
      ),
    );
  }

  // ============================================================
  // شاشة إنشاء الحساب
  // ============================================================

  Widget registerPage() {
    final phoneController =
        TextEditingController();

    final passwordController =
        TextEditingController();

    final confirmPasswordController =
        TextEditingController();

    final fullNameController =
        TextEditingController();

    final identityNumberController =
        TextEditingController();

    return Scaffold(
      backgroundColor:
          const Color(0xFFF4F7F6),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF4F7F6),
        title: const Text(
          'إنشاء حساب جديد',
        ),
        centerTitle: true,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              // ------------------------------------------------
              // العنوان
              // ------------------------------------------------

              Container(
                padding:
                    const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius:
                      BorderRadius.circular(18),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.person_add_alt_1,
                      color: Colors.white,
                      size: 45,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'طلب فتح حساب مدى باي',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'أدخل بياناتك الحقيقية كما هي في وثائقك الرسمية',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ------------------------------------------------
              // رقم الهاتف
              // ------------------------------------------------

              const Text(
                'بيانات الاتصال',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              phoneField(phoneController),

              const SizedBox(height: 15),

              // ------------------------------------------------
              // كلمة المرور
              // ------------------------------------------------

              TextField(
                controller:
                    passwordController,
                obscureText: true,
                textDirection:
                    TextDirection.ltr,
                decoration:
                    const InputDecoration(
                  labelText:
                      'كلمة المرور',
                  prefixIcon:
                      Icon(Icons.lock_outline),
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller:
                    confirmPasswordController,
                obscureText: true,
                textDirection:
                    TextDirection.ltr,
                decoration:
                    const InputDecoration(
                  labelText:
                      'تأكيد كلمة المرور',
                  prefixIcon:
                      Icon(Icons.lock_reset),
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 25),

              // ------------------------------------------------
              // البيانات الشخصية
              // ------------------------------------------------

              const Text(
                'البيانات الشخصية',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller:
                    fullNameController,
                textAlign:
                    TextAlign.right,
                decoration:
                    const InputDecoration(
                  labelText:
                      'الاسم كاملًا حسب البطاقة أو الجواز',
                  prefixIcon:
                      Icon(Icons.person_outline),
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 15),

              dateButton(
                title: 'تاريخ الميلاد',
                value: birthDate,
                onPressed: () async {
                  final date =
                      await selectDate(
                    firstDate:
                        DateTime(1900),
                    lastDate:
                        DateTime.now(),
                  );

                  if (date != null) {
                    setState(() {
                      birthDate = date;
                    });
                  }
                },
              ),

              const SizedBox(height: 15),

              // ------------------------------------------------
              // الدولة
              // ------------------------------------------------

              countrySelector(),

              const SizedBox(height: 15),

              // ------------------------------------------------
              // المحافظة
              // ------------------------------------------------

              provinceSelector(),

              const SizedBox(height: 15),

              // ------------------------------------------------
              // المديرية
              // ------------------------------------------------

              districtSelector(),

              const SizedBox(height: 15),

              // ------------------------------------------------
              // الحي
              // ------------------------------------------------

              neighborhoodSelector(),

              const SizedBox(height: 25),

              // ------------------------------------------------
              // نوع الحساب
              // ------------------------------------------------

              const Text(
                'نوع الحساب',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              accountTypeSelector(),

              // ------------------------------------------------
              // المستند التجاري
              // ------------------------------------------------

              if (accountType != 'فردي') ...[
                const SizedBox(height: 15),

                Text(
                  accountType == 'تجاري'
                      ? 'السجل التجاري أو عقد الإيجار'
                      : 'مستند مزاولة النشاط / الوكالة',
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                documentBox(
                  title:
                      'صورة السجل التجاري أو عقد الإيجار',
                  image:
                      commercialDocumentImage,
                  onTap: () async {
                    final image =
                        await pickImage();

                    if (image != null) {
                      setState(() {
                        commercialDocumentImage =
                            image;
                      });
                    }
                  },
                ),
              ],

              const SizedBox(height: 25),

              // ------------------------------------------------
              // الهوية
              // ------------------------------------------------

              const Text(
                'بيانات الهوية',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              identityTypeSelector(),

              const SizedBox(height: 15),

              TextField(
                controller:
                    identityNumberController,
                textDirection:
                    TextDirection.ltr,
                decoration:
                    const InputDecoration(
                  labelText:
                      'رقم الهوية',
                  prefixIcon:
                      Icon(Icons.numbers),
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 15),

              dateButton(
                title:
                    'تاريخ إصدار الهوية',
                value:
                    identityIssueDate,
                onPressed: () async {
                  final date =
                      await selectDate(
                    firstDate:
                        DateTime(1900),
                    lastDate:
                        DateTime.now(),
                  );

                  if (date != null) {
                    setState(() {
                      identityIssueDate =
                          date;
                    });
                  }
                },
              ),

              const SizedBox(height: 15),

              dateButton(
                title:
                    'تاريخ انتهاء الهوية',
                value:
                    identityExpiryDate,
                onPressed: () async {
                  final date =
                      await selectDate(
                    firstDate:
                        DateTime.now(),
                    lastDate:
                        DateTime(2100),
                  );

                  if (date != null) {
                    setState(() {
                      identityExpiryDate =
                          date;
                    });
                  }
                },
              ),

              const SizedBox(height: 20),

              // ------------------------------------------------
              // صور الهوية
              // ------------------------------------------------

              const Text(
                'صور المستندات الثبوتية',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                identityType ==
                        'جواز سفر'
                    ? 'أرفق صورة صفحة البيانات في جواز السفر'
                    : 'أرفق صور المستند من الأمام والخلف',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 12),

              documentBox(
                title:
                    'صورة المستند - الوجه الأمامي',
                image:
                    identityFrontImage,
                onTap: () async {
                  final image =
                      await pickImage();

                  if (image != null) {
                    setState(() {
                      identityFrontImage =
                          image;
                    });
                  }
                },
              ),

              if (identityType !=
                  'جواز سفر') ...[
                const SizedBox(height: 12),

                documentBox(
                  title:
                      'صورة المستند - الوجه الخلفي',
                  image:
                      identityBackImage,
                  onTap: () async {
                    final image =
                        await pickImage();

                    if (image != null) {
                      setState(() {
                        identityBackImage =
                            image;
                      });
                    }
                  },
                ),
              ],

              const SizedBox(height: 20),

              // ------------------------------------------------
              // الخصوصية
              // ------------------------------------------------

              Card(
                child: CheckboxListTile(
                  value:
                      privacyAccepted,
                  onChanged: (value) {
                    setState(() {
                      privacyAccepted =
                          value ?? false;
                    });
                  },
                  title: const Text(
                    'أوافق على بنود الخصوصية والشروط والأحكام',
                    style: TextStyle(
                      fontSize: 13,
                    ),
                  ),
                  controlAffinity:
                      ListTileControlAffinity
                          .leading,
                ),
              ),

              const SizedBox(height: 18),

              // ------------------------------------------------
              // زر التسجيل
              // ------------------------------------------------

              SizedBox(
                height: 55,
                child: FilledButton.icon(
                  onPressed: () {
                    submitRegistration(
                      phoneNumber:
                          phoneController.text,
                      password:
                          passwordController.text,
                      confirmPassword:
                          confirmPasswordController
                              .text,
                      fullName:
                          fullNameController.text,
                      identityNumber:
                          identityNumberController
                              .text,
                    );
                  },
                  icon: const Icon(
                    Icons.send,
                  ),
                  label: const Text(
                    'إرسال طلب التسجيل',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              const Text(
                'بعد إرسال الطلب ستقوم الإدارة بمراجعة البيانات والمستندات قبل تفعيل الحساب.',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // شاشة تسجيل الدخول
  // ============================================================

  Widget loginPage() {
    final phoneController =
        TextEditingController();

    final passwordController =
        TextEditingController();

    return Scaffold(
      backgroundColor:
          const Color(0xFFF4F7F6),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 30),

                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius:
                        BorderRadius.circular(25),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 48,
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'مدى باي',
                  style: TextStyle(
                    color: primary,
                    fontSize: 30,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'خدمات الرصيد والدفع الإلكتروني',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 35),

                Card(
                  elevation: 0,
                  child: Padding(
                    padding:
                        const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          'تسجيل الدخول',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 25,
                        ),

                        TextField(
                          controller:
                              phoneController,
                          keyboardType:
                              TextInputType.phone,
                          textDirection:
                              TextDirection.ltr,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'رقم الهاتف',
                            prefixIcon: Icon(
                              Icons.phone_android,
                            ),
                            border:
                                OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(
                          height: 15,
                        ),

                        TextField(
                          controller:
                              passwordController,
                          obscureText: true,
                          textDirection:
                              TextDirection.ltr,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'كلمة المرور',
                            prefixIcon: Icon(
                              Icons.lock_outline,
                            ),
                            border:
                                OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(
                          height: 20,
                        ),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child:
                              FilledButton(
                            onPressed: () {
                              login(
                                phoneController
                                    .text,
                                passwordController
                                    .text,
                              );
                            },
                            child: const Text(
                              'تسجيل الدخول',
                              style: TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 15,
                        ),

                        TextButton(
                          onPressed: () {
                            setState(() {
                              showRegister =
                                  true;
                            });
                          },
                          child: const Text(
                            'ليس لديك حساب؟ إنشاء حساب جديد',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'الحساب التجريبي:\n'
                  'الهاتف: 777777777\n'
                  'كلمة المرور: 123456',
                  textAlign:
                      TextAlign.center,
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
    );
  }

  // ============================================================
  // بقية واجهة العميل
  // ============================================================

  Widget header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        16,
        18,
        22,
      ),
      decoration: BoxDecoration(
        color: primary,
        borderRadius:
            const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'مدى باي',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  Text(
                    username,
                    style:
                        const TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                notify(
                  'لا توجد إشعارات جديدة',
                );
              },
              icon: const Icon(
                Icons.notifications_none,
                color: Colors.white,
              ),
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
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'الرصيد المتاح',
            style:
                TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            '${balance.toStringAsFixed(0)} ر.ي',
            style: TextStyle(
              color: primary,
              fontSize: 28,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const Divider(height: 28),
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceAround,
            children: [
              quickAction(
                Icons.add_circle_outline,
                'إيداع',
                () {
                  notify(
                    'الإيداع الحقيقي يحتاج إلى ربط مزود',
                  );
                },
              ),
              quickAction(
                Icons.send,
                'تحويل',
                () => openService(
                  'تحويل لحساب',
                ),
              ),
              quickAction(
                Icons.receipt_long,
                'السجل',
                () {
                  setState(() {
                    page = 2;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget quickAction(
    IconData icon,
    String label,
    VoidCallback action,
  ) {
    return InkWell(
      onTap: action,
      child: Column(
        children: [
          Icon(
            icon,
            color: primary,
            size: 25,
          ),
          const SizedBox(height: 5),
          Text(label),
        ],
      ),
    );
  }

  Widget serviceGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      itemCount: services.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.95,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final service =
            services[index];

        return InkWell(
          onTap: () => openService(
            service['name'] as String,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(16),
              border: Border.all(
                color:
                    Colors.grey.shade200,
              ),
            ),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  service['icon']
                      as IconData,
                  color: primary,
                  size: 30,
                ),
                const SizedBox(height: 10),
                Text(
                  service['name']
                      as String,
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    fontSize: 12,
                  ),
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
      padding:
          const EdgeInsets.all(16),
      children: [
        balanceCard(),
        const SizedBox(height: 24),
        const Text(
          'الخدمات',
          style: TextStyle(
            fontSize: 18,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        serviceGrid(),
        const SizedBox(height: 24),
        const Text(
          'آخر العمليات',
          style: TextStyle(
            fontSize: 18,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...transactions
            .take(3)
            .map(transactionTile),
      ],
    );
  }

  Widget transactionTile(
    Map<String, dynamic> tx,
  ) {
    return Card(
      color: Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              primary.withValues(
            alpha: 0.1,
          ),
          child: Icon(
            Icons.receipt_long,
            color: primary,
          ),
        ),
        title: Text(
          tx['title'] as String,
        ),
        subtitle: Text(
          tx['date'] as String,
        ),
        trailing: Text(
          '-${(tx['amount'] as double).toStringAsFixed(0)}',
          style:
              const TextStyle(
            color: Colors.red,
          ),
        ),
      ),
    );
  }

  Widget servicesPage() {
    return ListView(
      padding:
          const EdgeInsets.all(16),
      children: [
        const Text(
          'جميع الخدمات',
          style: TextStyle(
            fontSize: 20,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...services.map(
          (service) => Card(
            color: Colors.white,
            child: ListTile(
              leading: Icon(
                service['icon']
                    as IconData,
                color: primary,
              ),
              title: Text(
                service['name']
                    as String,
              ),
              trailing:
                  const Icon(
                Icons.chevron_left,
              ),
              onTap: () =>
                  openService(
                service['name']
                    as String,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget reportsPage() {
    return ListView(
      padding:
          const EdgeInsets.all(16),
      children: [
        const Text(
          'التقارير وسجل العمليات',
          style: TextStyle(
            fontSize: 20,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: Colors.white,
          child: ListTile(
            title: const Text(
              'الرصيد التجريبي الحالي',
            ),
            trailing: Text(
              '${balance.toStringAsFixed(0)} ر.ي',
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (transactions.isEmpty)
          const Padding(
            padding:
                EdgeInsets.all(30),
            child: Center(
              child: Text(
                'لا توجد عمليات حتى الآن',
              ),
            ),
          )
        else
          ...transactions.map(
            transactionTile,
          ),
      ],
    );
  }

  Widget accountPage() {
    return ListView(
      padding:
          const EdgeInsets.all(16),
      children: [
        const CircleAvatar(
          radius: 40,
          child: Icon(
            Icons.person,
            size: 40,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            username,
            style: const TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Center(
          child: Text(
            phone,
            style:
                const TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          color: Colors.white,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.person_outline,
                ),
                title: const Text(
                  'تغيير اسم المستخدم',
                ),
                onTap: changeUsername,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.settings_ethernet,
                ),
                title: const Text(
                  'إعدادات ربط API',
                ),
                subtitle:
                    Text(apiStatus),
                onTap: apiSettings,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.logout,
                  color: Colors.red,
                ),
                title: const Text(
                  'تسجيل الخروج',
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),
                onTap: logout,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void changeUsername() {
    final controller =
        TextEditingController(
      text: username,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            const Text('اسم المستخدم'),
        content: TextField(
          controller: controller,
          textAlign:
              TextAlign.right,
          decoration:
              const InputDecoration(
            labelText: 'الاسم',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx),
            child:
                const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (controller
                  .text
                  .trim()
                  .isNotEmpty) {
                setState(() {
                  username =
                      controller
                          .text
                          .trim();
                });
              }

              Navigator.pop(ctx);
            },
            child:
                const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void apiSettings() {
    final urlController =
        TextEditingController(
      text: apiUrl,
    );

    final tokenController =
        TextEditingController(
      text: apiToken,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx)
                  .viewInsets
                  .bottom +
              20,
        ),
        child:
            SingleChildScrollView(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Text(
                'إعدادات API',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              TextField(
                controller:
                    urlController,
                textDirection:
                    TextDirection.ltr,
                decoration:
                    const InputDecoration(
                  labelText:
                      'عنوان الخادم',
                  border:
                      OutlineInputBorder(),
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              TextField(
                controller:
                    tokenController,
                obscureText: true,
                textDirection:
                    TextDirection.ltr,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Bearer Token',
                  border:
                      OutlineInputBorder(),
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              FilledButton(
                onPressed: () {
                  setState(() {
                    apiUrl =
                        urlController
                            .text
                            .trim();
                    apiToken =
                        tokenController
                            .text
                            .trim();
                  });

                  Navigator.pop(ctx);
                  testApi();
                },
                child:
                    const Text(
                  'حفظ وتجربة الاتصال',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    if (!loggedIn) {
      return MaterialApp(
        debugShowCheckedModeBanner:
            false,
        title: 'مدى باي',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme:
              ColorScheme.fromSeed(
            seedColor: primary,
          ),
        ),
        home: Directionality(
          textDirection:
              TextDirection.rtl,
          child: showRegister
              ? registerPage()
              : loginPage(),
        ),
      );
    }

    final pages = [
      homePage(),
      servicesPage(),
      reportsPage(),
      accountPage(),
    ];

    return MaterialApp(
      debugShowCheckedModeBanner:
          false,
      title: 'مدى باي',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme:
            ColorScheme.fromSeed(
          seedColor: primary,
        ),
        scaffoldBackgroundColor:
            const Color(0xFFF4F7F6),
      ),
      home: Directionality(
        textDirection:
            TextDirection.rtl,
        child: Scaffold(
          body: Column(
            children: [
              header(),
              Expanded(
                child:
                    pages[page],
              ),
            ],
          ),
          bottomNavigationBar:
              NavigationBar(
            selectedIndex: page,
            onDestinationSelected:
                (index) {
              setState(() {
                page = index;
              });
            },
            destinations:
                const [
              NavigationDestination(
                icon: Icon(
                  Icons.home_outlined,
                ),
                selectedIcon:
                    Icon(Icons.home),
                label: 'الرئيسية',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.grid_view,
                ),
                label: 'الخدمات',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.receipt_long,
                ),
                label: 'التقارير',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.person_outline,
                ),
                label: 'حسابي',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
