import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../theme/app_theme.dart';
import '../models/client_model.dart';
import '../services/hive_service.dart';
import '../services/pdf_service.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';
import 'client_detail_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();
  String _activeFilter = 'month'; // 'today', 'month', 'year', 'custom'

  List<Client> _filteredClients = [];

  @override
  void initState() {
    super.initState();
    _applyMonthFilter();
  }

  void _applyTodayFilter() {
    final now = DateTime.now();
    setState(() {
      _fromDate = DateTime(now.year, now.month, now.day);
      _toDate = now;
      _activeFilter = 'today';
      _loadData();
    });
  }

  void _applyMonthFilter() {
    final now = DateTime.now();
    setState(() {
      _fromDate = DateTime(now.year, now.month, 1);
      _toDate = now;
      _activeFilter = 'month';
      _loadData();
    });
  }

  void _applyYearFilter() {
    final now = DateTime.now();
    setState(() {
      _fromDate = DateTime(now.year, 1, 1);
      _toDate = now;
      _activeFilter = 'year';
      _loadData();
    });
  }

  void _loadData() {
    _filteredClients = HiveService.getClientsByDateRange(_fromDate, _toDate);
    _filteredClients.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
  }

  Future<void> _selectDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.gold,
              onPrimary: AppColors.backgroundDark,
              surface: AppColors.backgroundElevated,
              onSurface: AppColors.textPrimary,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.backgroundElevated,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
        _activeFilter = 'custom';
        _loadData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalProfit =
        _filteredClients.fold(0.0, (sum, c) => sum + c.profit);
    final totalTransactions = _filteredClients.length;
    final uniqueCards =
        _filteredClients.map((c) => c.bankCardNumber).toSet().length;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.darkGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AppColors.gold.withAlpha(60)),
                      ),
                      child: const Icon(
                        Icons.analytics_rounded,
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
                            'التقارير 📊',
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(fontSize: 20),
                          ),
                          Text(
                            'تحليل الأرباح والمعاملات',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    // Export filtered report
                    if (_filteredClients.isNotEmpty)
                      IconButton(
                        onPressed: () async {
                          await PdfService.generateAllClientsReport(
                              _filteredClients);
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.picture_as_pdf_rounded,
                            color: AppColors.gold,
                            size: 20,
                          ),
                        ),
                        tooltip: 'تصدير كـ PDF',
                      ),
                  ],
                ).animate().fadeIn(duration: 400.ms),
              ),

              const SizedBox(height: 8),

              // Quick Filters
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildFilterChip('اليوم', 'today', Icons.today_rounded,
                        _applyTodayFilter),
                    const SizedBox(width: 8),
                    _buildFilterChip('هذا الشهر', 'month',
                        Icons.calendar_month_rounded, _applyMonthFilter),
                    const SizedBox(width: 8),
                    _buildFilterChip('هذا العام', 'year',
                        Icons.date_range_rounded, _applyYearFilter),
                  ],
                ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
              ),

              const SizedBox(height: 12),

              // Date Range Picker
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassCard(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectDate(true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundElevated,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.calendar_today_rounded,
                                    color: AppColors.gold, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  DateFormat('yyyy/MM/dd')
                                      .format(_fromDate),
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward_rounded,
                            color: AppColors.gold, size: 18),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectDate(false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundElevated,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.calendar_today_rounded,
                                    color: AppColors.gold, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  DateFormat('yyyy/MM/dd').format(_toDate),
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
              ),

              const SizedBox(height: 16),

              // Stats Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.trending_up_rounded,
                        label: 'إجمالي الربح',
                        value: Formatters.currency(totalProfit, symbol: 'د.ل'),
                        color: totalProfit >= 0
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.receipt_long_rounded,
                        label: 'المعاملات',
                        value: '$totalTransactions',
                        color: AppColors.info,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.credit_card_rounded,
                        label: 'البطاقات',
                        value: '$uniqueCards',
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
              ),

              const SizedBox(height: 16),

              // Transactions List Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.list_rounded,
                        color: AppColors.gold, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'المعاملات (${_filteredClients.length})',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                          height: 1,
                          color: AppColors.gold.withAlpha(30)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Transactions List
              Expanded(
                child: _filteredClients.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 60,
                                color: AppColors.textMuted.withAlpha(80)),
                            const SizedBox(height: 16),
                            const Text(
                              'لا توجد معاملات في هذه الفترة',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredClients.length,
                        itemBuilder: (context, index) {
                          final client = _filteredClients[index];
                          return _buildTransactionItem(context, client)
                              .animate()
                              .fadeIn(
                                delay: Duration(
                                    milliseconds:
                                        40 * (index.clamp(0, 12))),
                                duration: 350.ms,
                              )
                              .slideY(
                                begin: 0.05,
                                end: 0,
                                delay: Duration(
                                    milliseconds:
                                        40 * (index.clamp(0, 12))),
                              );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
      String label, String filter, IconData icon, VoidCallback onTap) {
    final isActive = _activeFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.gold.withAlpha(30)
                : AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? AppColors.gold.withAlpha(80)
                  : AppColors.gold.withAlpha(20),
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color:
                      isActive ? AppColors.gold : AppColors.textMuted,
                  size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color:
                      isActive ? AppColors.gold : AppColors.textMuted,
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, Client client) {
    return GlassCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ClientDetailScreen(clientId: client.id),
          ),
        );
      },
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.gold.withAlpha(50),
                  AppColors.gold.withAlpha(20),
                ],
              ),
              border: Border.all(color: AppColors.gold.withAlpha(60)),
            ),
            child: Center(
              child: Text(
                client.fullName.isNotEmpty ? client.fullName[0] : '?',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.fullName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (client.bankName != null &&
                        client.bankName!.isNotEmpty) ...[
                      Icon(Icons.account_balance_rounded,
                          size: 11,
                          color: AppColors.textMuted.withAlpha(150)),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          client.bankName!,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Icon(Icons.calendar_today_outlined,
                        size: 11,
                        color: AppColors.textMuted.withAlpha(150)),
                    const SizedBox(width: 3),
                    Text(
                      Formatters.date(client.purchaseDate),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Profit
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.currency(client.profit, symbol: 'د.ل'),
                style: TextStyle(
                  color: client.profit >= 0
                      ? AppColors.success
                      : AppColors.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'ربح',
                style: TextStyle(
                  color: AppColors.textMuted.withAlpha(150),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
