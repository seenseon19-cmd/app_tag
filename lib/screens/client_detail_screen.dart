import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../models/client_model.dart';
import '../services/hive_service.dart';
import '../services/firestore_service.dart';
import '../services/pdf_service.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';
import 'add_client_screen.dart';

class ClientDetailScreen extends StatefulWidget {
  final String clientId;

  const ClientDetailScreen({super.key, required this.clientId});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  void _confirmDelete(Client client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            SizedBox(width: 10),
            Text('تأكيد الحذف',
                style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف معاملة "${client.fullName}"?\nلا يمكن التراجع عن هذا الإجراء.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              // Delete from Hive (local)
              await HiveService.deleteClient(client.id);
              // Delete from Cloud Firestore
              await FirestoreService.deleteClient(client.id);
              if (mounted) {
                Navigator.of(context).pop(); // close dialog
                Navigator.of(context).pop(); // close detail
              }
            },
            child: const Text('حذف',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showShareOptions(Client client) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'مشاركة / تصدير',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),

              // Save PDF to phone
              _buildShareOption(
                icon: Icons.picture_as_pdf_rounded,
                title: 'حفظ كـ PDF على الجهاز',
                subtitle: 'طباعة أو حفظ التقرير',
                color: AppColors.error,
                onTap: () async {
                  Navigator.of(context).pop();
                  await PdfService.generateClientReport(client);
                },
              ),
              const SizedBox(height: 10),

              // Share via WhatsApp
              _buildShareOption(
                icon: Icons.share_rounded,
                title: 'إرسال عبر WhatsApp',
                subtitle: 'مشاركة معلومات العميل كنص',
                color: AppColors.success,
                onTap: () async {
                  Navigator.of(context).pop();
                  _shareViaWhatsApp(client);
                },
              ),
              const SizedBox(height: 10),

              // Share PDF via WhatsApp
              _buildShareOption(
                icon: Icons.picture_as_pdf_outlined,
                title: 'إرسال PDF عبر WhatsApp',
                subtitle: 'مشاركة التقرير كملف PDF',
                color: AppColors.info,
                onTap: () async {
                  Navigator.of(context).pop();
                  await PdfService.shareClientPdf(client);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _shareViaWhatsApp(Client client) {
    final text = '''
💎 *تاج الصرافة - Crown Exchange*
━━━━━━━━━━━━━━━━

👤 *الاسم:* ${client.fullName}
📞 *الهاتف:* ${client.phone}
🆔 *الرقم الوطني:* ${client.nationalId}
💳 *رقم البطاقة:* ${client.bankCardNumber}
🏦 *المصرف:* ${client.bankName ?? 'غير محدد'}
📅 *تاريخ الشراء:* ${Formatters.date(client.purchaseDate)}

━━━━━━━━━━━━━━━━
💰 *المعلومات المالية:*

🏷️ *سعر الشراء:* ${Formatters.currency(client.purchasePrice)} د.ل
💵 *الإيداع:* ${Formatters.currency(client.deposit)} د.ل
💲 *مبلغ الدولار:* ${Formatters.currency(client.dollarAmount, symbol: '\$')}
📊 *سعر الصرف:* ${client.exchangeRate != null ? '${Formatters.number(client.exchangeRate!)} د.ل/\$' : 'غير محدد'}
✅ *الربح:* ${Formatters.currency(client.profit)} د.ل
${client.note != null ? '\n📝 *ملاحظة:* ${client.note}' : ''}
━━━━━━━━━━━━━━━━
📆 ${Formatters.dateTime(DateTime.now())}
    ''';

    SharePlus.instance.share(ShareParams(text: text.trim()));
  }

  Widget _buildShareOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
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
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textMuted, size: 22),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final client = HiveService.getClient(widget.clientId);
    if (client == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('خطأ')),
        body: const Center(
          child: Text('العميل غير موجود',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(client.fullName,
            style: const TextStyle(color: AppColors.gold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, size: 22),
            tooltip: 'تعديل',
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddClientScreen(client: client),
                ),
              );
              if (result == true) setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.error, size: 22),
            tooltip: 'حذف',
            onPressed: () => _confirmDelete(client),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.darkGradient),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          children: [
            // ===== Client Info Card =====
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.gold.withAlpha(50),
                          AppColors.gold.withAlpha(15),
                        ],
                      ),
                      border: Border.all(
                        color: AppColors.gold.withAlpha(70),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        client.fullName.isNotEmpty
                            ? client.fullName[0]
                            : '?',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    client.fullName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (client.bankName != null &&
                      client.bankName!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withAlpha(15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '🏦 ${client.bankName}',
                        style: const TextStyle(
                          color: AppColors.goldLight,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    'تاريخ الشراء: ${Formatters.date(client.purchaseDate)}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 12),

            // ===== Personal Info =====
            _buildSectionTitle('معلومات العميل', Icons.person_outline_rounded),
            const SizedBox(height: 8),

            _buildInfoItem(Icons.phone_rounded, 'رقم الهاتف', client.phone)
                .animate()
                .fadeIn(delay: 100.ms, duration: 300.ms),
            _buildInfoItem(
                    Icons.badge_rounded, 'الرقم الوطني', client.nationalId)
                .animate()
                .fadeIn(delay: 150.ms, duration: 300.ms),
            _buildInfoItem(Icons.credit_card_rounded, 'رقم البطاقة',
                    client.bankCardNumber)
                .animate()
                .fadeIn(delay: 200.ms, duration: 300.ms),
            if (client.bankName != null && client.bankName!.isNotEmpty)
              _buildInfoItem(Icons.account_balance_rounded, 'المصرف',
                      client.bankName!)
                  .animate()
                  .fadeIn(delay: 225.ms, duration: 300.ms),
            _buildInfoItem(Icons.calendar_today_rounded, 'تاريخ الشراء',
                    Formatters.date(client.purchaseDate))
                .animate()
                .fadeIn(delay: 250.ms, duration: 300.ms),
            if (client.note != null && client.note!.isNotEmpty)
              _buildInfoItem(
                      Icons.note_alt_outlined, 'ملاحظة', client.note!)
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 300.ms),

            const SizedBox(height: 16),

            // ===== Financial Info =====
            _buildSectionTitle(
                'المعلومات المالية', Icons.account_balance_rounded),
            const SizedBox(height: 8),

            _buildInfoItem(
              Icons.monetization_on_rounded,
              'سعر الشراء',
              Formatters.currency(client.purchasePrice, symbol: 'د.ل'),
              valueColor: AppColors.textPrimary,
            ).animate().fadeIn(delay: 350.ms, duration: 300.ms),

            _buildInfoItem(
              Icons.payments_rounded,
              'الإيداع',
              Formatters.currency(client.deposit, symbol: 'د.ل'),
              valueColor: AppColors.warning,
            ).animate().fadeIn(delay: 400.ms, duration: 300.ms),

            _buildInfoItem(
              Icons.attach_money_rounded,
              'مبلغ الدولار',
              Formatters.currency(client.dollarAmount, symbol: '\$'),
              valueColor: AppColors.info,
            ).animate().fadeIn(delay: 450.ms, duration: 300.ms),

            _buildInfoItem(
              Icons.currency_exchange_rounded,
              'سعر الصرف',
              client.exchangeRate != null
                  ? '${Formatters.number(client.exchangeRate!)} د.ل/\$'
                  : 'غير محدد',
              valueColor: const Color(0xFF9C27B0),
            ).animate().fadeIn(delay: 475.ms, duration: 300.ms),

            // Profit (highlighted)
            GlassCard(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: client.profit >= 0
                          ? AppColors.success.withAlpha(25)
                          : AppColors.error.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      client.profit >= 0
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: client.profit >= 0
                          ? AppColors.success
                          : AppColors.error,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'الربح',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Formatters.currency(client.profit, symbol: 'د.ل'),
                          style: TextStyle(
                            color: client.profit >= 0
                                ? AppColors.success
                                : AppColors.error,
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'LYD',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

            const SizedBox(height: 20),

            // ===== Share / Export Buttons =====
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _showShareOptions(client),
                icon: const Icon(Icons.share_rounded),
                label: const Text(
                  'مشاركة / تصدير PDF',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.backgroundDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 6,
                  shadowColor: AppColors.gold.withAlpha(80),
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 600.ms, duration: 400.ms)
                .slideY(begin: 0.1, end: 0),

            const SizedBox(height: 12),

            // WhatsApp direct button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => _shareViaWhatsApp(client),
                icon: const Icon(Icons.send_rounded, size: 20),
                label: const Text(
                  'إرسال عبر WhatsApp مباشرة',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.success,
                  side: const BorderSide(
                      color: AppColors.success, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 700.ms, duration: 400.ms)
                .slideY(begin: 0.1, end: 0),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.gold, size: 20),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(height: 1, color: AppColors.gold.withAlpha(30)),
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value,
      {Color? valueColor}) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gold, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
