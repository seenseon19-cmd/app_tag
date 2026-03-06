import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../theme/app_theme.dart';
import '../models/client_model.dart';
import '../services/hive_service.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';
import 'client_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: HiveService.clientsBox.listenable(),
      builder: (context, Box<Client> box, _) {
        final clients = box.values.toList();
        clients.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        final totalPurchases = HiveService.getTotalPurchases();
        final totalDeposits = HiveService.getTotalDeposits();
        final totalProfit = HiveService.getTotalProfit();
        final totalDollar = HiveService.getTotalDollarAmount();
        final clientsCount = clients.length;

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(gradient: AppColors.darkGradient),
            child: SafeArea(
              child: clients.isEmpty
                  ? _buildEmptyDashboard(context)
                  : _buildDashboard(
                      context,
                      clients,
                      totalPurchases,
                      totalDeposits,
                      totalProfit,
                      totalDollar,
                      clientsCount,
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyDashboard(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.gold.withAlpha(30),
                  AppColors.gold.withAlpha(10),
                ],
              ),
            ),
            child: const Icon(
              Icons.dashboard_rounded,
              size: 80,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'لوحة التحكم',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'أضف معاملات لعرض الإحصائيات والتقارير',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    List<Client> clients,
    double totalPurchases,
    double totalDeposits,
    double totalProfit,
    double totalDollar,
    int clientsCount,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold.withAlpha(60)),
              ),
              child: const Icon(
                Icons.diamond_outlined,
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
                    'لوحة التحكم 💎',
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge
                        ?.copyWith(fontSize: 20),
                  ),
                  Text(
                    'نظرة عامة على جميع المعاملات',
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

        const SizedBox(height: 16),

        // === Stat Cards Grid ===
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.people_rounded,
                label: 'المعاملات',
                value: '$clientsCount',
                color: AppColors.info,
                delay: 100,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                icon: Icons.monetization_on_rounded,
                label: 'إجمالي المشتريات',
                value: Formatters.currency(totalPurchases),
                color: AppColors.gold,
                delay: 200,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.payments_rounded,
                label: 'إجمالي الإيداع',
                value: Formatters.currency(totalDeposits),
                color: AppColors.warning,
                delay: 300,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                icon: Icons.trending_up_rounded,
                label: 'إجمالي الأرباح',
                value: Formatters.currency(totalProfit, symbol: 'د.ل'),
                color: totalProfit >= 0 ? AppColors.success : AppColors.error,
                delay: 400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Dollar Amount Card (full width)
        _buildStatCard(
          icon: Icons.attach_money_rounded,
          label: 'إجمالي مبالغ الدولار',
          value: Formatters.currency(totalDollar, symbol: '\$'),
          color: const Color(0xFF00BCD4),
          delay: 500,
          fullWidth: true,
        ),

        const SizedBox(height: 20),

        // === Profit Breakdown Pie Chart ===
        _buildSectionHeader('توزيع الأرباح', Icons.pie_chart_rounded),
        const SizedBox(height: 8),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 220,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 35,
                      sections: [
                        PieChartSectionData(
                          value: totalDeposits > 0 ? totalDeposits : 1,
                          title: '',
                          color: AppColors.warning,
                          radius: 55,
                          badgeWidget: _buildPieBadge(
                              Icons.payments_rounded, AppColors.warning),
                          badgePositionPercentageOffset: 1.2,
                        ),
                        PieChartSectionData(
                          value: totalProfit > 0 ? totalProfit : 1,
                          title: '',
                          color: AppColors.success,
                          radius: 60,
                          badgeWidget: _buildPieBadge(
                              Icons.trending_up_rounded, AppColors.success),
                          badgePositionPercentageOffset: 1.2,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem('الإيداع', AppColors.warning,
                          Formatters.currency(totalDeposits)),
                      const SizedBox(height: 16),
                      _buildLegendItem('الربح', AppColors.success,
                          Formatters.currency(totalProfit)),
                      const SizedBox(height: 16),
                      Container(
                        height: 1,
                        color: AppColors.gold.withAlpha(30),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'الإجمالي',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.currency(totalPurchases),
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

        const SizedBox(height: 20),

        // === Monthly Trends Bar Chart ===
        _buildSectionHeader('المعاملات الشهرية', Icons.bar_chart_rounded),
        const SizedBox(height: 8),
        GlassCard(
          padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
          child: SizedBox(
            height: 200,
            child: _buildMonthlyChart(clients),
          ),
        ).animate().fadeIn(delay: 700.ms, duration: 400.ms),

        const SizedBox(height: 20),

        // === Recent Transactions ===
        _buildSectionHeader('آخر المعاملات', Icons.receipt_long_rounded),
        const SizedBox(height: 8),
        ...clients.take(5).map((client) {
          return _buildRecentTransaction(context, client);
        }),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required int delay,
    bool fullWidth = false,
  }) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(vertical: 0),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
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
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: fullWidth ? 20 : 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(
          delay: Duration(milliseconds: delay),
          duration: 350.ms,
        ).slideY(begin: 0.05, end: 0);
  }

  Widget _buildSectionHeader(String title, IconData icon) {
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

  Widget _buildPieBadge(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(60),
            blurRadius: 8,
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 14),
    );
  }

  Widget _buildLegendItem(String label, Color color, String value) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
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
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyChart(List<Client> clients) {
    // Group clients by month (last 6 months)
    final now = DateTime.now();
    final months = <String, double>{};
    final monthLabels = <String>[];

    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      months[key] = 0;
      monthLabels.add(_getMonthName(date.month));
    }

    for (final client in clients) {
      final key =
          '${client.purchaseDate.year}-${client.purchaseDate.month.toString().padLeft(2, '0')}';
      if (months.containsKey(key)) {
        months[key] = months[key]! + client.profit;
      }
    }

    final values = months.values.toList();
    final maxValue =
        values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.backgroundElevated,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                Formatters.currency(rod.toY, symbol: 'د.ل'),
                const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < monthLabels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      monthLabels[index],
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxValue > 0 ? maxValue / 4 : 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.gold.withAlpha(15),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: values.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value,
                width: 20,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
                gradient: LinearGradient(
                  colors: [
                    AppColors.gold.withAlpha(180),
                    AppColors.goldLight.withAlpha(220),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxValue * 1.2,
                  color: AppColors.gold.withAlpha(8),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentTransaction(BuildContext context, Client client) {
    return GlassCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ClientDetailScreen(clientId: client.id),
          ),
        );
      },
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

          // Client Info
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
                Text(
                  Formatters.date(client.purchaseDate),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.gold.withAlpha(15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'ربح',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 900.ms, duration: 300.ms);
  }

  String _getMonthName(int month) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return months[month - 1];
  }
}
