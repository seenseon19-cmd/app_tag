import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../services/hive_service.dart';
import '../services/pdf_service.dart';
import '../widgets/common_widgets.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;

  void _changePassword() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.backgroundElevated,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.lock_rounded, color: AppColors.gold),
                  SizedBox(width: 10),
                  Text('تغيير كلمة المرور',
                      style: TextStyle(
                          color: AppColors.gold, fontSize: 18)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPasswordController,
                    obscureText: obscureCurrent,
                    style:
                        const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور الحالية',
                      prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: AppColors.gold),
                      suffixIcon: IconButton(
                        icon: Icon(
                            obscureCurrent
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: AppColors.textMuted,
                            size: 20),
                        onPressed: () => setDialogState(
                            () => obscureCurrent = !obscureCurrent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPasswordController,
                    obscureText: obscureNew,
                    style:
                        const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور الجديدة',
                      prefixIcon: const Icon(
                          Icons.lock_reset_rounded,
                          color: AppColors.gold),
                      suffixIcon: IconButton(
                        icon: Icon(
                            obscureNew
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: AppColors.textMuted,
                            size: 20),
                        onPressed: () => setDialogState(
                            () => obscureNew = !obscureNew),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    style:
                        const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'تأكيد كلمة المرور',
                      prefixIcon: Icon(Icons.check_circle_outline_rounded,
                          color: AppColors.gold),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('إلغاء',
                      style: TextStyle(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Validate
                    if (!HiveService.verifyLogin(
                        HiveService.getAdminUsername(),
                        currentPasswordController.text.trim())) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('كلمة المرور الحالية غير صحيحة'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }

                    if (newPasswordController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('أدخل كلمة مرور جديدة'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }

                    if (newPasswordController.text !=
                        confirmPasswordController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('كلمة المرور غير متطابقة'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }

                    await HiveService.changePassword(
                        newPasswordController.text.trim());
                    if (ctx.mounted) Navigator.of(ctx).pop();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Row(
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  color: AppColors.success),
                              SizedBox(width: 10),
                              Text('تم تغيير كلمة المرور بنجاح ✓'),
                            ],
                          ),
                          backgroundColor: AppColors.backgroundElevated,
                        ),
                      );
                    }
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _setRecoveryEmail() {
    final emailController = TextEditingController(
      text: HiveService.getRecoveryEmail() ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundElevated,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.email_rounded, color: AppColors.gold),
              SizedBox(width: 10),
              Text('البريد الإلكتروني للاستعادة',
                  style: TextStyle(
                      color: AppColors.gold, fontSize: 16)),
            ],
          ),
          content: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'البريد الإلكتروني',
              hintText: 'example@gmail.com',
              prefixIcon:
                  Icon(Icons.email_outlined, color: AppColors.gold),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إلغاء',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (emailController.text.trim().isNotEmpty) {
                  await HiveService.setRecoveryEmail(
                      emailController.text.trim());
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle_rounded,
                                color: AppColors.success),
                            SizedBox(width: 10),
                            Text('تم حفظ البريد الإلكتروني ✓'),
                          ],
                        ),
                        backgroundColor: AppColors.backgroundElevated,
                      ),
                    );
                  }
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  void _exportCsv() async {
    setState(() => _isExporting = true);
    try {
      final path = await HiveService.exportToCsv();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.success),
                const SizedBox(width: 10),
                Expanded(child: Text('تم التصدير بنجاح:\n$path')),
              ],
            ),
            backgroundColor: AppColors.backgroundElevated,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'مشاركة',
              textColor: AppColors.gold,
              onPressed: () {
                SharePlus.instance.share(
                  ShareParams(
                    files: [XFile(path)],
                    text: '💎 بيانات تاج الصرافة - CSV',
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في التصدير: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _exportPdf() async {
    final clients = HiveService.getAllClients();
    if (clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد بيانات للتصدير'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    await PdfService.generateAllClientsReport(clients);
  }

  void _confirmDeleteAll() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundElevated,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: AppColors.error, size: 26),
              SizedBox(width: 10),
              Text('حذف جميع البيانات',
                  style: TextStyle(color: AppColors.error, fontSize: 18)),
            ],
          ),
          content: const Text(
            'هل أنت متأكد من حذف جميع المعاملات؟\n\n⚠️ هذا الإجراء لا يمكن التراجع عنه!',
            style: TextStyle(
                color: AppColors.textSecondary, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إلغاء',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error),
              onPressed: () async {
                // Delete all clients
                final clients = HiveService.getAllClients();
                for (final c in clients) {
                  await HiveService.deleteClient(c.id);
                }
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.delete_sweep_rounded,
                              color: AppColors.error),
                          SizedBox(width: 10),
                          Text('تم حذف جميع البيانات'),
                        ],
                      ),
                      backgroundColor: AppColors.backgroundElevated,
                    ),
                  );
                }
              },
              child: const Text('حذف الكل',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundElevated,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: AppColors.gold),
              SizedBox(width: 10),
              Text('تسجيل الخروج',
                  style: TextStyle(
                      color: AppColors.gold, fontSize: 18)),
            ],
          ),
          content: const Text(
            'هل تريد تسجيل الخروج من التطبيق؟',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إلغاء',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                await HiveService.logout();
                await HiveService.setRememberMe(false);
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              child: const Text('تسجيل الخروج'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientsCount = HiveService.getTotalClientsCount();
    final recoveryEmail = HiveService.getRecoveryEmail();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.darkGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppColors.gold.withAlpha(60)),
                    ),
                    child: const Icon(
                      Icons.settings_rounded,
                      color: AppColors.gold,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الإعدادات ⚙️',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(fontSize: 20),
                        ),
                        Text(
                          'إدارة التطبيق والبيانات',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 20),

              // ===== Account Section =====
              _buildSectionHeader('الحساب', Icons.person_outline_rounded),
              const SizedBox(height: 10),

              _buildSettingsTile(
                icon: Icons.lock_rounded,
                title: 'تغيير كلمة المرور',
                subtitle: 'تحديث كلمة المرور الخاصة بك',
                color: AppColors.gold,
                onTap: _changePassword,
              ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

              _buildSettingsTile(
                icon: Icons.email_rounded,
                title: 'البريد الإلكتروني للاستعادة',
                subtitle: recoveryEmail ?? 'لم يتم تعيينه بعد',
                color: AppColors.info,
                onTap: _setRecoveryEmail,
              ).animate().fadeIn(delay: 150.ms, duration: 300.ms),

              const SizedBox(height: 16),

              // ===== Info Section =====
              _buildSectionHeader('المعلومات', Icons.info_outline_rounded),
              const SizedBox(height: 10),

              _buildSettingsTile(
                icon: Icons.receipt_long_rounded,
                title: 'عدد المعاملات',
                subtitle: '$clientsCount معاملة',
                color: AppColors.success,
                onTap: () {
                  // Show detailed breakdown
                  final totalProfit = HiveService.getTotalProfit();
                  final totalPurchases = HiveService.getTotalPurchases();
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.backgroundElevated,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      title: const Row(
                        children: [
                          Icon(Icons.analytics_rounded,
                              color: AppColors.gold),
                          SizedBox(width: 10),
                          Text('إحصائيات سريعة',
                              style: TextStyle(
                                  color: AppColors.gold, fontSize: 18)),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildStatRow('عدد المعاملات', '$clientsCount'),
                          _buildStatRow('إجمالي المشتريات',
                              '${totalPurchases.toStringAsFixed(2)} د.ل'),
                          _buildStatRow('إجمالي الأرباح',
                              '${totalProfit.toStringAsFixed(2)} د.ل'),
                        ],
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('إغلاق'),
                        ),
                      ],
                    ),
                  );
                },
              ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

              const SizedBox(height: 16),

              // ===== Export Section =====
              _buildSectionHeader('التصدير', Icons.upload_file_rounded),
              const SizedBox(height: 10),

              _buildSettingsTile(
                icon: Icons.picture_as_pdf_rounded,
                title: 'تصدير كـ PDF',
                subtitle: 'تقرير بجميع المعاملات',
                color: AppColors.error,
                onTap: _exportPdf,
              ).animate().fadeIn(delay: 250.ms, duration: 300.ms),

              if (!kIsWeb)
                _buildSettingsTile(
                  icon: Icons.table_chart_rounded,
                  title: 'تصدير كـ CSV',
                  subtitle: 'بيانات قابلة للفتح في Excel',
                  color: const Color(0xFF217346),
                  trailing: _isExporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.gold,
                          ),
                        )
                      : null,
                  onTap: _isExporting ? null : _exportCsv,
                ).animate().fadeIn(delay: 300.ms, duration: 300.ms),

              const SizedBox(height: 16),

              // ===== Danger Zone =====
              _buildSectionHeader('منطقة الخطر', Icons.warning_amber_rounded,
                  color: AppColors.error),
              const SizedBox(height: 10),

              _buildSettingsTile(
                icon: Icons.delete_sweep_rounded,
                title: 'حذف جميع البيانات',
                subtitle: 'حذف جميع المعاملات نهائياً',
                color: AppColors.error,
                onTap: _confirmDeleteAll,
              ).animate().fadeIn(delay: 350.ms, duration: 300.ms),

              const SizedBox(height: 24),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: const Text(
                    'تسجيل الخروج',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gold,
                    side: const BorderSide(
                        color: AppColors.gold, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 300.ms),

              const SizedBox(height: 30),

              // App Info
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.diamond_outlined,
                        color: AppColors.gold, size: 30),
                    const SizedBox(height: 8),
                    const Text(
                      'تاج الصرافة 💎',
                      style: TextStyle(
                        color: AppColors.goldLight,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'الإصدار 2.0.0',
                      style: TextStyle(
                        color: AppColors.textMuted.withAlpha(150),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon,
      {Color? color}) {
    return Row(
      children: [
        Icon(icon, color: color ?? AppColors.gold, size: 20),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: color ?? AppColors.gold,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
              height: 1,
              color: (color ?? AppColors.gold).withAlpha(30)),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return GlassCard(
      onTap: onTap,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          trailing ??
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted.withAlpha(120), size: 22),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(value,
              style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}
