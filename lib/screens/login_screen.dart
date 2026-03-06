import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/hive_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _rememberMe = HiveService.getRememberMe();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Simulate a small delay for UX
    await Future.delayed(const Duration(milliseconds: 800));

    final success = HiveService.verifyLogin(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    if (success) {
      // Save Remember Me preference
      await HiveService.setRememberMe(_rememberMe);
      if (_rememberMe) {
        await HiveService.setLoggedIn(true);
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const HomeScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                  )),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'اسم المستخدم أو كلمة المرور غير صحيحة';
      });
    }
  }

  void _resetPassword() async {
    final recoveryEmail = HiveService.getRecoveryEmail();

    if (recoveryEmail != null && recoveryEmail.isNotEmpty) {
      // Open Gmail with pre-filled email
      final uri = Uri(
        scheme: 'mailto',
        path: recoveryEmail,
        queryParameters: {
          'subject': 'استعادة كلمة المرور - تاج الصرافة',
          'body': 'أرجو إعادة تعيين كلمة المرور لحسابي في تطبيق تاج الصرافة.',
        },
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } else {
      // Show dialog to set recovery email
      _showSetRecoveryEmailDialog();
    }
  }

  void _showSetRecoveryEmailDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.email_rounded, color: AppColors.gold),
            SizedBox(width: 10),
            Text(
              'استعادة كلمة المرور',
              style: TextStyle(color: AppColors.gold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'أدخل بريدك الإلكتروني للاستعادة:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                hintText: 'example@gmail.com',
                prefixIcon: Icon(Icons.email_outlined, color: AppColors.gold),
              ),
            ),

          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.isNotEmpty) {
                await HiveService.setRecoveryEmail(emailController.text.trim());

                final uri = Uri(
                  scheme: 'mailto',
                  path: emailController.text.trim(),
                  queryParameters: {
                    'subject': 'استعادة كلمة المرور - تاج الصرافة',
                    'body':
                        'أرجو إعادة تعيين كلمة المرور لحسابي في تطبيق تاج الصرافة.',
                  },
                );

                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }

                if (context.mounted) Navigator.of(context).pop();
              }
            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.darkGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    _buildLogo(),
                    const SizedBox(height: 50),

                    // Username Field
                    TextFormField(
                      controller: _usernameController,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        labelText: 'اسم المستخدم',
                        hintText: 'admin',
                        prefixIcon: const Icon(Icons.person_rounded,
                            color: AppColors.gold),
                        filled: true,
                        fillColor: AppColors.backgroundElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: AppColors.gold.withAlpha(50)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: AppColors.gold.withAlpha(50)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: AppColors.gold, width: 2),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'أدخل اسم المستخدم';
                        }
                        return null;
                      },
                    )
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 500.ms)
                        .slideX(begin: -0.1, end: 0),
                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        hintText: '••••',
                        prefixIcon: const Icon(Icons.lock_rounded,
                            color: AppColors.gold),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () {
                            setState(() =>
                                _obscurePassword = !_obscurePassword);
                          },
                        ),
                        filled: true,
                        fillColor: AppColors.backgroundElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: AppColors.gold.withAlpha(50)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: AppColors.gold.withAlpha(50)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: AppColors.gold, width: 2),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'أدخل كلمة المرور';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _login(),
                    )
                        .animate()
                        .fadeIn(delay: 500.ms, duration: 500.ms)
                        .slideX(begin: 0.1, end: 0),

                    const SizedBox(height: 12),

                    // Remember Me Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() => _rememberMe = value ?? false);
                          },
                          activeColor: AppColors.gold,
                          checkColor: AppColors.backgroundDark,
                          side: const BorderSide(
                              color: AppColors.goldLight, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() => _rememberMe = !_rememberMe);
                          },
                          child: const Text(
                            'تذكرني',
                            style: TextStyle(
                              color: AppColors.goldLight,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(delay: 550.ms, duration: 400.ms),

                    // Error Message
                    if (_errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.error.withAlpha(60)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: AppColors.error, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 300.ms).shake(),

                    const SizedBox(height: 24),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: AppColors.backgroundDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 6,
                          shadowColor: AppColors.gold.withAlpha(80),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.backgroundDark,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.login_rounded, size: 22),
                                  SizedBox(width: 10),
                                  Text(
                                    'تسجيل الدخول',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 600.ms, duration: 500.ms)
                        .slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 20),

                    // Reset Password
                    TextButton.icon(
                      onPressed: _resetPassword,
                      icon: const Icon(Icons.email_outlined,
                          color: AppColors.goldLight, size: 18),
                      label: const Text(
                        'نسيت كلمة المرور؟ استعادة عبر Gmail',
                        style: TextStyle(
                          color: AppColors.goldLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 700.ms, duration: 500.ms),


                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppColors.gold.withAlpha(45),
                AppColors.gold.withAlpha(15),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: AppColors.gold.withAlpha(70),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withAlpha(30),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.diamond_outlined,
            size: 56,
            color: AppColors.gold,
          ),
        )
            .animate()
            .fadeIn(duration: 800.ms)
            .scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1.0, 1.0),
              duration: 800.ms,
              curve: Curves.elasticOut,
            ),
        const SizedBox(height: 20),
        Text(
          'تاج الصرافة',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: AppColors.gold,
                fontWeight: FontWeight.w800,
                fontSize: 34,
              ),
        ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
        const SizedBox(height: 8),
        Text(
          '💎 Crown Exchange',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.goldLight,
                letterSpacing: 3,
                fontSize: 14,
              ),
        ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
      ],
    );
  }
}
