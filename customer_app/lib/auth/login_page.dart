import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';

class CustomerLoginPage extends StatefulWidget {
  const CustomerLoginPage({super.key});

  @override
  State<CustomerLoginPage> createState() => _CustomerLoginPageState();
}

class _CustomerLoginPageState extends State<CustomerLoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final response = await AuthService.signIn(
        login: _loginController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (response.user == null) {
        _showError('تعذر تسجيل الدخول. حاول مرة أخرى.');
        return;
      }

      final profile = await AuthService.getCurrentProfile();

      if (!mounted) return;

      if (profile == null) {
        await AuthService.signOut();
        _showError('لم يتم العثور على بيانات حسابك.');
        return;
      }

      final status = profile['status']?.toString().toUpperCase();

      if (status == 'SUSPENDED') {
        await AuthService.signOut();
        _showError('حسابك موقوف حاليًا.');
        return;
      }

      if (status == 'REJECTED') {
        await AuthService.signOut();
        _showError('تم رفض طلب حسابك.');
        return;
      }

      if (status == 'DISABLED') {
        await AuthService.signOut();
        _showError('حسابك معطل حاليًا.');
        return;
      }

      if (status != 'ACTIVE') {
        await AuthService.signOut();
        _showError(
          'حسابك قيد المراجعة. سيتم تفعيل الحساب بعد الموافقة عليه.',
        );
        return;
      }

      Navigator.of(context).pushReplacementNamed('/home');
    } on AuthException catch (e) {
      if (!mounted) return;

      final message = e.message.toLowerCase();

      if (message.contains('invalid login credentials')) {
        _showError('بيانات تسجيل الدخول غير صحيحة.');
      } else if (message.contains('email not confirmed')) {
        _showError('يرجى تأكيد البريد الإلكتروني أولًا.');
      } else {
        _showError(e.message);
      }
    } catch (e) {
      if (!mounted) return;

      _showError(
        'حدث خطأ أثناء تسجيل الدخول. حاول مرة أخرى.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textDirection: TextDirection.rtl,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 430,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 30),

                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B6B4F),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'مدى باي',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0B6B4F),
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'مرحبًا بك في تطبيق مدى باي',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'خدمات الرصيد وشحن التطبيقات',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 36),

                      TextFormField(
                        controller: _loginController,
                        keyboardType: TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(
                          labelText: 'البريد الإلكتروني أو رقم الهاتف',
                          prefixIcon: Icon(
                            Icons.person_outline_rounded,
                          ),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'أدخل البريد الإلكتروني أو رقم الهاتف';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword =
                                    !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'أدخل كلمة المرور';
                          }

                          return null;
                        },
                        onFieldSubmitted: (_) {
                          if (!_loading) {
                            _login();
                          }
                        },
                      ),

                      const SizedBox
