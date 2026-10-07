import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';
import '../core/theme/app_colors.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

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

      final user = response.user;

      if (user == null) {
        throw const AuthException(
          'تعذر تسجيل الدخول. يرجى المحاولة مرة أخرى.',
        );
      }

      final profile = await AuthService.getCurrentProfile();

      if (!mounted) return;

      if (profile == null) {
        await AuthService.signOut();

        _showError(
          'لم يتم العثور على ملف المستخدم في النظام.',
        );

        return;
      }

      final status = profile['status']?.toString().toUpperCase();

      if (status != 'ACTIVE') {
        await AuthService.signOut();

        _showError(
          'هذا الحساب غير مفعل للدخول إلى لوحة الإدارة.',
        );

        return;
      }

      final isOwner = await AuthService.hasRole('OWNER');
      final isAdmin = await AuthService.hasRole('ADMIN');

      if (!mounted) return;

      if (!isOwner && !isAdmin) {
        await AuthService.signOut();

        _showError(
          'ليس لديك صلاحية الدخول إلى لوحة الإدارة.',
        );

        return;
      }

      Navigator.of(context).pushReplacementNamed(
        isOwner ? '/owner-dashboard' : '/dashboard',
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      _showError(
        _translateAuthError(e.message),
      );
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

  String _translateAuthError(String message) {
    final text = message.toLowerCase();

    if (text.contains('invalid login credentials')) {
      return 'بيانات تسجيل الدخول غير صحيحة.';
    }

    if (text.contains('email not confirmed')) {
      return 'لم يتم تأكيد البريد الإلكتروني.';
    }

    if (text.contains('invalid') && text.contains('phone')) {
      return 'رقم الهاتف أو كلمة المرور غير صحيحة.';
    }

    return message;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
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
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(
                                alpha: 0.20,
                              ),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
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
                          color: AppColors.primary,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'لوحة الإدارة',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'وكالة مدى باي لخدمات الرصيد وشحن التطبيقات',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 36),

                      TextFormField(
                        controller: _loginController,
                        keyboardType: TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                        decoration: _inputDecoration(
                          label: 'البريد الإلكتروني أو رقم الهاتف',
                          icon: Icons.person_outline_rounded,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
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
                        decoration: _inputDecoration(
                          label: 'كلمة المرور',
                          icon: Icons.lock_outline_rounded,
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

                      const SizedBox(height: 24),

                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          child: _loading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'تسجيل الدخول',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
}
