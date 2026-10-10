import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_KEY');
  if (url.isNotEmpty && key.isNotEmpty) {
    await Supabase.initialize(url: url, anonKey: key);
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
  bool loggedIn = false, showWelcome = true, showRegister = false;
  bool rememberMe = false, privacyAccepted = false;
  String username = '', phone = '', apiUrl = '', apiToken = '', apiStatus = 'غير متصل';
  String selectedCountry = 'اليمن', countryCode = '+967';
  String accountType = 'فردي', identityType = 'بطاقة شخصية';
  String? province, district, neighborhood;
  DateTime? birthDate, issueDate, expiryDate;
  File? frontImage, backImage, businessImage;
  int page = 0;
  double balance = 15000;
  final users = <String, Map<String, String>>{
    '777777777': {'username': 'مستخدم مدى باي', 'password': '123456'},
  };
  final List<Map<String, dynamic>> transactions = [];
  final services = <Map<String, dynamic>>[
    {'name':'تحويل لحساب','icon':Icons.swap_horiz_rounded},
    {'name':'شحن رصيد','icon':Icons.phone_android_rounded},
    {'name':'تسديد إنترنت','icon':Icons.wifi_rounded},
    {'name':'باقات الإنترنت','icon':Icons.language_rounded},
    {'name':'بطاقات الألعاب','icon':Icons.sports_esports_rounded},
    {'name':'خدمات أخرى','icon':Icons.grid_view_rounded},
  ];
  final countries = <Map<String, String>>[
    {'name':'اليمن','code':'+967','flag':'🇾🇪'}, {'name':'السعودية','code':'+966','flag':'🇸🇦'},
    {'name':'الإمارات','code':'+971','flag':'🇦🇪'}, {'name':'عُمان','code':'+968','flag':'🇴🇲'},
    {'name':'قطر','code':'+974','flag':'🇶🇦'}, {'name':'الكويت','code':'+965','flag':'🇰🇼'},
    {'name':'مصر','code':'+20','flag':'🇪🇬'}, {'name':'الأردن','code':'+962','flag':'🇯🇴'},
    {'name':'العراق','code':'+964','flag':'🇮🇶'}, {'name':'تركيا','code':'+90','flag':'🇹🇷'},
    {'name':'الولايات المتحدة','code':'+1','flag':'🇺🇸'}, {'name':'المملكة المتحدة','code':'+44','flag':'🇬🇧'},
    {'name':'فرنسا','code':'+33','flag':'🇫🇷'}, {'name':'ألمانيا','code':'+49','flag':'🇩🇪'},
    {'name':'الهند','code':'+91','flag':'🇮🇳'}, {'name':'باكستان','code':'+92','flag':'🇵🇰'},
  ];
  final Map<String, Map<String, List<String>>> regions = {
    'أمانة العاصمة': {'آزال':['حي آزال','حي نقم'], 'التحرير':['حي التحرير','حي القاع'], 'معين':['حي معين','حي شملان']},
    'عدن': {'المعلا':['حي المعلا','حي الدكة'], 'التواهي':['حي التواهي','حي جولد مور'], 'خور مكسر':['حي خور مكسر','حي العريش'], 'الشيخ عثمان':['حي الشيخ عثمان','حي الممدارة']},
    'تعز': {'القاهرة':['حي القاهرة','حي الروضة'], 'المظفر':['حي المظفر','حي باب موسى']},
    'مأرب': {'مدينة مأرب':['حي المطار','حي الجامعة'], 'الوادي':['حي الوادي']},
  };

  void msg(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s), behavior: SnackBarBehavior.floating));
  void login(String id, String password) {
    final u = users[id.trim()];
    if (u == null) return msg('الحساب غير موجود. الدخول الحالي تجريبي فقط.');
    if (u['password'] != password) return msg('كلمة المرور غير صحيحة');
    setState(() { loggedIn = true; phone = id.trim(); username = u['username']!; page = 0; });
    msg('تم الدخول إلى الحساب التجريبي');
  }
  void register(String id, String pass, String confirm, String name, String identity) {
    if (id.trim().isEmpty || name.trim().length < 5 || identity.trim().isEmpty) return msg('أكمل بيانات الاتصال والاسم ورقم الهوية');
    if (pass.length < 6) return msg('كلمة المرور يجب ألا تقل عن 6 أحرف أو أرقام');
    if (pass != confirm) return msg('كلمتا المرور غير متطابقتين');
    if (birthDate == null || province == null || district == null || neighborhood == null || issueDate == null || expiryDate == null || frontImage == null) return msg('أكمل بيانات الموقع والتواريخ وارفق صورة الهوية');
    if (identityType != 'جواز سفر' && backImage == null) return msg('أرفق صورة الوجه الخلفي للهوية');
    if (accountType != 'فردي' && businessImage == null) return msg('أرفق مستند النشاط التجاري');
    if (!privacyAccepted) return msg('وافق على الشروط والخصوصية');
    final full = '$countryCode${id.trim()}';
    if (users.containsKey(full) || users.containsKey(id.trim())) return msg('رقم الهاتف مسجل مسبقًا');
    users[full] = {'username': name.trim(), 'password': pass};
    setState(() { showRegister = false; showWelcome = false; });
    msg('حُفظ الحساب محليًا للتجربة فقط؛ لم يتم إرسال طلب إلى الإدارة.');
  }
  Future<File?> pickImage() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    return x == null ? null : File(x.path);
  }
  Future<DateTime?> pickDate({DateTime? first, DateTime? last}) => showDatePicker(
    context: context, initialDate: DateTime.now(), firstDate: first ?? DateTime(1900),
    lastDate: last ?? DateTime(2100), locale: const Locale('ar'));
  void logout() => setState(() { loggedIn = false; showWelcome = true; showRegister = false; page = 0; });

  Widget field(String label, TextEditingController c, {bool secret = false, TextInputType? type}) => TextField(
    controller: c, obscureText: secret, keyboardType: type, textDirection: TextDirection.ltr,
    decoration: InputDecoration(labelText: label, filled: true, fillColor: Colors.white,
      prefixIcon: Icon(secret ? Icons.lock_outline : Icons.person_outline),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))));
  Widget countryPicker() => DropdownButtonFormField<String>(
    value: selectedCountry, isExpanded: true, decoration: const InputDecoration(labelText:'الدولة',border:OutlineInputBorder()),
    items: countries.map((c)=>DropdownMenuItem(value:c['name'],child:Text('${c['flag']} ${c['name']} (${c['code']})'))).toList(),
    onChanged:(v){if(v==null)return;setState((){selectedCountry=v;countryCode=countries.firstWhere((c)=>c['name']==v)['code']!;province=null;district=null;neighborhood=null;});});
  Widget regionPicker(String label, String? value, List<String> values, ValueChanged<String?> change) => DropdownButtonFormField<String>(
    value: values.contains(value) ? value : null, isExpanded:true,
    decoration:InputDecoration(labelText:label,border:const OutlineInputBorder()),
    items:values.map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),
    onChanged:values.isEmpty?null:change);
  Widget dateField(String label, DateTime? value, VoidCallback tap) => ListTile(
    shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12),side:BorderSide(color:Colors.grey.shade300)),
    leading:const Icon(Icons.calendar_month), title:Text(label),
    subtitle:Text(value==null?'اختر التاريخ':'${value.year}/${value.month}/${value.day}'), onTap:tap);
  Widget imagePickerBox(String label, File? image, ValueChanged<File?> setImage) => InkWell(
    onTap:()async{final f=await pickImage();if(f!=null)setState(()=>setImage(f));},
    child:Container(height:125,width:double.infinity,margin:const EdgeInsets.symmetric(vertical:6),
      decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(14),border:Border.all(color:Colors.grey.shade300)),
      child:image==null?Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(Icons.cloud_upload_outlined,color:primary,size:34),Text(label)]):
      ClipRRect(borderRadius:BorderRadius.circular(14),child:Image.file(image,fit:BoxFit.cover))));
  Widget welcomePage() => Scaffold(
    backgroundColor:const Color(0xFFF1F6F4),
    body:SafeArea(child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(22),child:Column(children:[
      const SizedBox(height:14),
      Container(width:112,height:112,decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF31B99A),Color(0xFF075B49)]),borderRadius:BorderRadius.circular(32),boxShadow:const [BoxShadow(color:Color(0x44307868),blurRadius:24,offset:Offset(0,12))]),child:const Icon(Icons.account_balance_wallet_rounded,size:62,color:Colors.white)),
      const SizedBox(height:16),Text('وكالة مدى باي',style:TextStyle(color:primary,fontSize:29,fontWeight:FontWeight.w900)),
      const SizedBox(height:22),
      Container(width:double.infinity,padding:const EdgeInsets.all(23),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Colors.white,Color(0xFFE2F2EC)]),borderRadius:BorderRadius.circular(28),boxShadow:const [BoxShadow(color:Color(0x1F174C40),blurRadius:22,offset:Offset(0,10))]),child:Column(children:[
        Text('مرحبًا بكم',style:TextStyle(color:primary,fontSize:27,fontWeight:FontWeight.w900)),
        const SizedBox(height:12),const Text('مرحبًا بكم في وكالة مدى باي لخدمات الدفع الإلكتروني، الوكالة الموثوقة الأولى في الوطن العربي.',textAlign:TextAlign.center,style:TextStyle(fontSize:17,height:1.9,color:Color(0xFF344A45))),
        const SizedBox(height:22),const Wrap(alignment:WrapAlignment.center,spacing:16,runSpacing:16,children:[
          _WelcomeIcon(Icons.phone_android_rounded,'شحن الرصيد'),_WelcomeIcon(Icons.wifi_rounded,'الإنترنت'),
          _WelcomeIcon(Icons.swap_horiz_rounded,'التحويلات'),_WelcomeIcon(Icons.credit_card_rounded,'الدفع الإلكتروني')]) ])),
      const SizedBox(height:22),
      Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(24),boxShadow:const [BoxShadow(color:Color(0x17174C40),blurRadius:18,offset:Offset(0,7))]),child:Column(children:[
        SizedBox(width:double.infinity,height:53,child:ElevatedButton(onPressed:()=>setState(()=>showWelcome=false),style:ElevatedButton.styleFrom(backgroundColor:primary,foregroundColor:Colors.white),child:const Text('تسجيل الدخول'))),
        const SizedBox(height:12),SizedBox(width:double.infinity,height:52,child:OutlinedButton(onPressed:()=>setState(()=>{showWelcome=false,showRegister=true}),child:const Text('إنشاء حساب جديد')))])),
      const SizedBox(height:24),const Text('تطوير م/ أبو معاوية الشبيبي',style:TextStyle(fontWeight:FontWeight.w600,color:Color(0xFF53655F))),
      const SizedBox(height:5),const Text('© وكالة مدى باي — جميع الحقوق محفوظة',style:TextStyle(color:Colors.grey,fontSize:12)),
    ])))));
  Widget loginPage() {
    final id=TextEditingController(), pass=TextEditingController();
    return Scaffold(backgroundColor:const Color(0xFFF2F6F4),body:SafeArea(child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(22),child:Column(children:[
      Container(width:88,height:88,decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF31B99A),Color(0xFF075B49)]),borderRadius:BorderRadius.circular(25)),child:const Icon(Icons.account_balance_wallet_rounded,color:Colors.white,size:48)),
      const SizedBox(height:18),Text('مدى باي',style:TextStyle(color:primary,fontSize:30,fontWeight:FontWeight.w900)),
      const SizedBox(height:8),const Text('قم بإدخال بيانات تسجيل الدخول الخاصة بك للحصول على مميزات وخدمات وكالة مدى باي',textAlign:TextAlign.center),
      const SizedBox(height:24),Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(25),boxShadow:const [BoxShadow(color:Color(0x17174C40),blurRadius:20,offset:Offset(0,8))]),child:Column(children:[
        const Text('تسجيل الدخول',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),const SizedBox(height:20),
        field('رقم الهاتف أو البريد الإلكتروني',id,type:TextInputType.emailAddress),const SizedBox(height:14),field('كلمة المرور',pass,secret:true),
        Row(children:[Checkbox(value:rememberMe,onChanged:(v)=>setState(()=>rememberMe=v??false)),const Text('تذكرني'),const Spacer(),TextButton(onPressed:()=>msg('استعادة كلمة المرور تحتاج تفعيل Supabase Auth.'),child:const Text('نسيت كلمة المرور؟'))]),
        SizedBox(width:double.infinity,height:50,child:ElevatedButton(onPressed:()=>login(id.text,pass.text),style:ElevatedButton.styleFrom(backgroundColor:primary,foregroundColor:Colors.white),child:const Text('تسجيل الدخول'))),
        TextButton(onPressed:()=>setState(()=>showRegister=true),child:const Text('ليس لديك حساب؟ إنشاء حساب جديد'))])),
      const SizedBox(height:20),const Text('تطوير / وكالة مدى باي للدفع الإلكتروني\nم / أبو معاوية الشبيبي',textAlign:TextAlign.center),
      const SizedBox(height:10),const Text('حساب تجريبي: 777777777 / 123456',style:TextStyle(color:Colors.grey,fontSize:12)),
      TextButton(onPressed:()=>setState(()=>showWelcome=true),child:const Text('العودة إلى الترحيب')),
    ])))));
  }
  Widget registerPage() {
    final id=TextEditingController(), pass=TextEditingController(), confirm=TextEditingController(), name=TextEditingController(), identity=TextEditingController();
    final districts=regions[province]?.keys.toList()??[];
    final neighborhoods=regions[province]?[district??'']??[];
    return Scaffold(appBar:AppBar(title:const Text('إنشاء حساب جديد'),leading:IconButton(icon:const Icon(Icons.arrow_back),onPressed:()=>setState(()=>{showRegister=false,showWelcome=true})),centerTitle:true),
      body:SafeArea(child:SingleChildScrollView(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(gradient:LinearGradient(colors:[primary,const Color(0xFF075B49)]),borderRadius:BorderRadius.circular(20)),child:const Column(children:[Icon(Icons.person_add_alt_1,color:Colors.white,size:42),SizedBox(height:8),Text('طلب فتح حساب مدى باي',style:TextStyle(color:Colors.white,fontSize:21,fontWeight:FontWeight.bold)),Text('أدخل بياناتك الحقيقية حسب وثائقك الرسمية',style:TextStyle(color:Colors.white70))])),
        const SizedBox(height:16),phoneField(id),const SizedBox(height:12),field('كلمة المرور',pass,secret:true),const SizedBox(height:12),field('تأكيد كلمة المرور',confirm,secret:true),
        const SizedBox(height:20),field('الاسم الكامل حسب الهوية',name),const SizedBox(height:12),
        dateField('تاريخ الميلاد',birthDate,()async{final d=await pickDate(last:DateTime.now());if(d!=null)setState(()=>birthDate=d);}),
        const SizedBox(height:12),countryPicker(),const SizedBox(height:12),
        regionPicker('المحافظة / الولاية',province,regions.keys.toList(),(v)=>setState(()=>{province=v,district=null,neighborhood=null})),
        const SizedBox(height:12),regionPicker('المديرية',district,districts,(v)=>setState(()=>{district=v,neighborhood=null})),
        const SizedBox(height:12),regionPicker('الحي / المنطقة',neighborhood,neighborhoods,(v)=>setState(()=>neighborhood=v)),
        const SizedBox(height:12),DropdownButtonFormField<String>(value:accountType,decoration:const InputDecoration(labelText:'نوع الحساب',border:OutlineInputBorder()),items:const ['فردي','تجاري','موزع','وكيل'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>setState(()=>accountType=v??'فردي')),
        if(accountType!='فردي')imagePickerBox('مستند النشاط التجاري',businessImage,(v)=>businessImage=v),
        const SizedBox(height:12),DropdownButtonFormField<String>(value:identityType,decoration:const InputDecoration(labelText:'نوع الهوية',border:OutlineInputBorder()),items:const ['بطاقة شخصية','جواز سفر','إقامة'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>setState(()=>{identityType=v??'بطاقة شخصية',frontImage=null,backImage=null})),
        const SizedBox(height:12),field('رقم الهوية',identity),
        dateField('تاريخ إصدار الهوية',issueDate,()async{final d=await pickDate(last:DateTime.now());if(d!=null)setState(()=>issueDate=d);}),
        dateField('تاريخ انتهاء الهوية',expiryDate,()async{final d=await pickDate();if(d!=null)setState(()=>expiryDate=d);}),
        imagePickerBox('صورة الهوية - الوجه الأمامي',frontImage,(v)=>frontImage=v),
        if(identityType!='جواز سفر')imagePickerBox('صورة الهوية - الوجه الخلفي',backImage,(v)=>backImage=v),
        CheckboxListTile(value:privacyAccepted,onChanged:(v)=>setState(()=>privacyAccepted=v??false),title:const Text('أوافق على الخصوصية والشروط'),controlAffinity:ListTileControlAffinity.leading),
        SizedBox(height:52,child:ElevatedButton(onPressed:()=>register(id.text,pass.text,confirm.text,name.text,identity.text),style:ElevatedButton.styleFrom(backgroundColor:primary,foregroundColor:Colors.white),child:const Text('إرسال طلب التسجيل'))),
        const SizedBox(height:12),const Text('نسخة تجريبية: لا تُرسل البيانات أو الصور إلى الخادم ولا ترسل رمز تحقق بعد.',textAlign:TextAlign.center,style:TextStyle(color:Colors.grey,fontSize:12)),
      ]))));
  }
  Widget phoneField(TextEditingController c)=>Row(children:[
    SizedBox(width:105,child:DropdownButtonFormField<String>(value:countryCode,isExpanded:true,decoration:const InputDecoration(labelText:'المفتاح',border:OutlineInputBorder()),items:countries.map((x)=>DropdownMenuItem(value:x['code'],child:Text(x['code']!))).toList(),onChanged:(v)=>setState(()=>countryCode=v??'+967'))),
    const SizedBox(width:8),Expanded(child:TextField(controller:c,keyboardType:TextInputType.phone,textDirection:TextDirection.ltr,decoration:const InputDecoration(labelText:'رقم الهاتف',border:OutlineInputBorder())))
  ]);
  Widget header()=>Container(padding:const EdgeInsets.fromLTRB(18,16,18,22),decoration:BoxDecoration(gradient:LinearGradient(colors:[primary,const Color(0xFF075B49)]),borderRadius:const BorderRadius.vertical(bottom:Radius.circular(25))),child:SafeArea(bottom:false,child:Row(children:[
    const CircleAvatar(backgroundColor:Colors.white24,child:Icon(Icons.account_balance_wallet,color:Colors.white)),const SizedBox(width:12),
    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('مدى باي',style:TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.bold)),Text(username,style:const TextStyle(color:Colors.white70))])),
    IconButton(onPressed:()=>msg('لا توجد إشعارات جديدة'),icon:const Icon(Icons.notifications_none,color:Colors.white))
  ])));
  Widget balanceCard()=>Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(gradient:LinearGradient(colors:[primary,const Color(0xFF075B49)]),borderRadius:BorderRadius.circular(23),boxShadow:const [BoxShadow(color:Color(0x33147D64),blurRadius:16,offset:Offset(0,7))]),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const Text('الرصيد المتاح',style:TextStyle(color:Colors.white70)),const SizedBox(height:7),Text('${balance.toStringAsFixed(0)} ر.ي',style:const TextStyle(color:Colors.white,fontSize:29,fontWeight:FontWeight.w900)),
    const Text('رصيد تجريبي فقط — ليس رصيدًا ماليًا حقيقيًا',style:TextStyle(color:Colors.white70,fontSize:11)),const Divider(color:Colors.white30,height:28),
    Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[
      _QuickAction(Icons.add_circle_outline,'إيداع',()=>msg('الإيداع الحقيقي يحتاج مزود دفع')),
      _QuickAction(Icons.send,'تحويل',()=>openService('تحويل لحساب')),
      _QuickAction(Icons.receipt_long,'السجل',()=>setState(()=>page=2)),
    ])
  ]));
  Widget serviceGrid()=>GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:services.length,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:3,childAspectRatio:.9,crossAxisSpacing:10,mainAxisSpacing:10),itemBuilder:(ctx,i){
    final s=services[i];return InkWell(onTap:()=>openService(s['name'] as String),borderRadius:BorderRadius.circular(17),child:Container(decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(17),boxShadow:const [BoxShadow(color:Color(0x10174C40),blurRadius:10,offset:Offset(0,4))]),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
      Container(padding:const EdgeInsets.all(11),decoration:BoxDecoration(color:const Color(0xFFDDF1EA),borderRadius:BorderRadius.circular(14)),child:Icon(s['icon'] as IconData,color:primary,size:27)),const SizedBox(height:8),Text(s['name'] as String,textAlign:TextAlign.center,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w600))
    ])));
  });
  Widget txTile(Map<String,dynamic> tx)=>Card(color:Colors.white,child:ListTile(leading:CircleAvatar(backgroundColor:const Color(0xFFDDF1EA),child:Icon(Icons.receipt_long,color:primary)),title:Text(tx['title'] as String),subtitle:Text(tx['date'] as String),trailing:Text('-${(tx['amount'] as num).toStringAsFixed(0)}',style:const TextStyle(color:Colors.red))));
  Widget homePage()=>ListView(padding:const EdgeInsets.all(16),children:[balanceCard(),const SizedBox(height:22),const Text('الخدمات',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold)),const SizedBox(height:12),serviceGrid(),const SizedBox(height:22),const Text('آخر العمليات',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold)),if(transactions.isEmpty)const Padding(padding:EdgeInsets.all(20),child:Text('لا توجد عمليات حتى الآن',textAlign:TextAlign.center))else ...transactions.take(3).map(txTile)]);
  Widget servicesPage()=>ListView(padding:const EdgeInsets.all(16),children:[const Text('جميع الخدمات',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),...services.map((s)=>Card(color:Colors.white,child:ListTile(leading:Icon(s['icon'] as IconData,color:primary),title:Text(s['name'] as String),trailing:const Icon(Icons.chevron_left),onTap:()=>openService(s['name'] as String))))]);
  Widget reportsPage()=>ListView(padding:const EdgeInsets.all(16),children:[const Text('التقارير وسجل العمليات',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),Card(child:ListTile(title:const Text('الرصيد التجريبي'),subtitle:const Text('ليس رصيدًا حقيقيًا'),trailing:Text('${balance.toStringAsFixed(0)} ر.ي'))),if(transactions.isEmpty)const Text('لا توجد عمليات حتى الآن')else ...transactions.map(txTile)]);
  Widget accountPage()=>ListView(padding:const EdgeInsets.all(16),children:[CircleAvatar(radius:40,backgroundColor:const Color(0xFFDDF1EA),child:Icon(Icons.person,size:42,color:primary)),const SizedBox(height:12),Center(child:Text(username,style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold))),Center(child:Text(phone)),const SizedBox(height:20),Card(color:Colors.white,child:Column(children:[
    ListTile(leading:const Icon(Icons.settings_ethernet),title:const Text('إعدادات API'),subtitle:Text(apiStatus),onTap:apiSettings),
    ListTile(leading:const Icon(Icons.logout,color:Colors.red),title:const Text('تسجيل الخروج'),onTap:logout)
  ]))]);
  void openService(String name){
    final target=TextEditingController(), amount=TextEditingController();
    showDialog(context:context,builder:(ctx)=>AlertDialog(title:Text(name),content:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:target,decoration:const InputDecoration(labelText:'رقم الهاتف أو الحساب')),TextField(controller:amount,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'المبلغ'))
    ,const Text('عملية تجريبية فقط؛ لا يتم إرسال أموال.',style:TextStyle(color:Colors.orange,fontSize:12))]),actions:[
      TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('إلغاء')),
      FilledButton(onPressed:(){final n=double.tryParse(amount.text);if(target.text.trim().isEmpty||n==null||n<=0){msg('أدخل بيانات صحيحة');return;}if(n>balance){msg('الرصيد التجريبي غير كافٍ');return;}Navigator.pop(ctx);setState((){balance-=n;transactions.insert(0,{'title':name,'amount':n,'date':DateTime.now().toString().substring(0,16)});});msg('سُجلت عملية تجريبية');},child:const Text('تجربة العملية'))
    ]));
  }
  void apiSettings(){
    final u=TextEditingController(text:apiUrl), t=TextEditingController(text:apiToken);
    showModalBottomSheet(context:context,isScrollControlled:true,builder:(ctx)=>Padding(padding:EdgeInsets.fromLTRB(20,20,20,MediaQuery.of(ctx).viewInsets.bottom+20),child:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:u,textDirection:TextDirection.ltr,decoration:const InputDecoration(labelText:'عنوان API')),
      TextField(controller:t,obscureText:true,textDirection:TextDirection.ltr,decoration:const InputDecoration(labelText:'Bearer Token')),
      FilledButton(onPressed:(){setState((){apiUrl=u.text.trim();apiToken=t.text.trim();apiStatus='الإعدادات محفوظة محليًا فقط';});Navigator.pop(ctx);msg('تم حفظ الإعدادات محليًا فقط.');},child:const Text('حفظ'))
    ])));
  }
  @override Widget build(BuildContext context){
    final theme=ThemeData(useMaterial3:true,colorScheme:ColorScheme.fromSeed(seedColor:primary),scaffoldBackgroundColor:const Color(0xFFF2F6F4),inputDecorationTheme:InputDecorationTheme(filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(14))));
    if(!loggedIn)return MaterialApp(debugShowCheckedModeBanner:false,title:'مدى باي',theme:theme,home:Directionality(textDirection:TextDirection.rtl,child:AnimatedSwitcher(duration:const Duration(milliseconds:450),transitionBuilder:(child,a){final r=Tween<double>(begin:.13,end:0).animate(a);return FadeTransition(opacity:a,child:AnimatedBuilder(animation:r,child:child,builder:(c,ch)=>Transform(alignment:Alignment.center,transform:Matrix4.identity()..setEntry(3,2,.001)..rotateY(r.value),child:ch)));},child:showWelcome?KeyedSubtree(key:const ValueKey('welcome'),child:welcomePage()):showRegister?KeyedSubtree(key:const ValueKey('register'),child:registerPage()):KeyedSubtree(key:const ValueKey('login'),child:loginPage()))));
    final pages=[homePage(),servicesPage(),reportsPage(),accountPage()];
    return MaterialApp(debugShowCheckedModeBanner:false,title:'مدى باي',theme:theme,home:Directionality(textDirection:TextDirection.rtl,child:Scaffold(body:Column(children:[header(),Expanded(child:pages[page.clamp(0,3)]))]),bottomNavigationBar:NavigationBar(selectedIndex:page,onDestinationSelected:(i)=>setState(()=>page=i),destinations:const[
      NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:'الرئيسية'),
      NavigationDestination(icon:Icon(Icons.grid_view),label:'الخدمات'),
      NavigationDestination(icon:Icon(Icons.receipt_long),label:'التقارير'),
      NavigationDestination(icon:Icon(Icons.person_outline),label:'حسابي')
    ])));
  }
}

class _WelcomeIcon extends StatelessWidget{
  final IconData icon; final String label;
  const _WelcomeIcon(this.icon,this.label);
  @override Widget build(BuildContext context)=>SizedBox(width:112,child:Column(children:[
    Container(width:50,height:50,decoration:BoxDecoration(color:const Color(0xFFD5EEE6),borderRadius:BorderRadius.circular(16)),child:Icon(icon,color:const Color(0xFF147D64),size:27)),
    const SizedBox(height:7),Text(label,textAlign:TextAlign.center,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w600,color:Color(0xFF40564F)))
  ]));
}
class _QuickAction extends StatelessWidget{
  final IconData icon; final String label; final VoidCallback action;
  const _QuickAction(this.icon,this.label,this.action);
  @override Widget build(BuildContext context)=>InkWell(onTap:action,child:Padding(padding:const EdgeInsets.all(5),child:Column(children:[Icon(icon,color:Colors.white,size:25),const SizedBox(height:5),Text(label,style:const TextStyle(color:Colors.white))])));
}
