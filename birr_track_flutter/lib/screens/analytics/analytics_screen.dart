import 'package:birr_track/data/models/category.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../widgets/spending_streak_card.dart';
import '../../widgets/contribution_heatmap.dart';
import '../../widgets/spending_flow_chart.dart';
import '../../widgets/animated_bar_chart.dart';
import '../../widgets/pie_chart_widget.dart';
import '../../data/models/transaction.dart';
import '../../core/colors.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _period = 'monthly'; // 'daily' | 'monthly' | 'yearly'

  Map<String, dynamic> _calculatePeriodStats(
    List<Transaction> transactions,
    List<Category> categories,
  ) {
    final now = DateTime.now();
    List<Transaction> filtered = [];

    if (_period == 'daily') {
      final todayStr = DateFormat('yyyy-MM-dd').format(now);
      filtered = transactions.where((t) => t.date == todayStr).toList();
    } else if (_period == 'monthly') {
      final monthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      filtered = transactions
          .where((t) => t.date.startsWith(monthStr))
          .toList();
    } else {
      final yearStr = '${now.year}';
      filtered = transactions.where((t) => t.date.startsWith(yearStr)).toList();
    }

    final income = filtered
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);
    final expense = filtered
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);

    final Map<String, double> catBreakdown = {};
    for (final t in filtered.where((t) => t.type == TransactionType.expense)) {
      catBreakdown[t.categoryId] =
          (catBreakdown[t.categoryId] ?? 0.0) + t.amount;
    }

    final pieData = catBreakdown.entries.map((entry) {
      final cat = categories.firstWhere(
        (c) => c.id == entry.key,
        orElse: () => categories.first,
      );
      return PieSlice(label: cat.name, value: entry.value, color: cat.color);
    }).toList();
    pieData.sort((a, b) => b.value.compareTo(a.value));

    return {
      'income': income,
      'expense': expense,
      'net': income - expense,
      'pieData': pieData,
      'txnCount': filtered.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final stats = _calculatePeriodStats(
      provider.transactions,
      provider.categories,
    );
    final pieData = stats['pieData'] as List<PieSlice>;

    String periodLabel = '';
    final now = DateTime.now();
    if (_period == 'daily') {
      periodLabel = 'Today';
    } else if (_period == 'monthly') {
      periodLabel = DateFormat('MMMM yyyy').format(now);
    } else {
      periodLabel = '${now.year}';
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text(
                    'Analytics',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    periodLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Period Selector
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildPeriodChip('daily', 'Today', Icons.today),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPeriodChip(
                      'monthly',
                      'Month',
                      Icons.calendar_today,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPeriodChip('yearly', 'Year', Icons.language),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Scrollable charts and breakdown list
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  children: [
                    // Summary metrics cards
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              label: 'Income',
                              value:
                                  '${(stats['income'] as double).toStringAsFixed(0)} ETB',
                              color: AppColors.income,
                              icon: Icons.arrow_downward,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              label: 'Expenses',
                              value:
                                  '${(stats['expense'] as double).toStringAsFixed(0)} ETB',
                              color: AppColors.expense,
                              icon: Icons.arrow_upward,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Net savings card
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 8.0,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              ((stats['net'] as double) >= 0
                                      ? AppColors.income
                                      : AppColors.expense)
                                  .withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color:
                                ((stats['net'] as double) >= 0
                                        ? AppColors.income
                                        : AppColors.expense)
                                    .withOpacity(0.15),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Net Savings',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${(stats['net'] as double) >= 0 ? "+" : ""}${(stats['net'] as double).toStringAsFixed(0)} ETB',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: (stats['net'] as double) >= 0
                                            ? AppColors.income
                                            : AppColors.expense,
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  (stats['net'] as double) >= 0
                                      ? Icons.trending_up
                                      : Icons.trending_down,
                                  size: 28,
                                  color: (stats['net'] as double) >= 0
                                      ? AppColors.income
                                      : AppColors.expense,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${stats['txnCount']} transactions',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Streak Insight Card
                    SpendingStreakCard(transactions: provider.transactions),

                    // Heatmap
                    ContributionHeatmap(
                      transactions: provider.transactions,
                      period: _period,
                    ),

                    // Flow Chart
                    SpendingFlowChart(
                      transactions: provider.transactions,
                      period: _period,
                    ),

                    // Bar Chart
                    AnimatedBarChart(
                      transactions: provider.transactions,
                      period: _period,
                    ),

                    // Category Breakdown Donut Chart
                    PieChartWidget(
                      data: pieData,
                      centerLabel: 'Expenses',
                      centerValue:
                          '${(stats['expense'] as double).toStringAsFixed(0)} ETB',
                    ),

                    // Top Spending ranked list
                    if (pieData.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 16.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Top Spending Categories',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkSurface
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.borderLight,
                                ),
                              ),
                              child: Column(
                                children: List.generate(
                                  pieData.length > 5 ? 5 : pieData.length,
                                  (idx) {
                                    final item = pieData[idx];
                                    final maxVal = pieData.first.value;
                                    final pct = maxVal > 0
                                        ? item.value / maxVal
                                        : 0.0;

                                    return Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        border:
                                            idx <
                                                (pieData.length > 5
                                                    ? 4
                                                    : pieData.length - 1)
                                            ? Border(
                                                bottom: BorderSide(
                                                  color: isDark
                                                      ? AppColors.darkBorder
                                                      : AppColors.borderLight,
                                                ),
                                              )
                                            : null,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 28,
                                            height: 28,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: item.color.withOpacity(
                                                0.12,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${idx + 1}',
                                              style: TextStyle(
                                                color: item.color,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      item.label,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: AppColors.text,
                                                      ),
                                                    ),
                                                    Text(
                                                      '${item.value.toStringAsFixed(0)} ETB',
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: AppColors
                                                            .textSecondary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(3),
                                                  child: LinearProgressIndicator(
                                                    value: pct,
                                                    minHeight: 6,
                                                    backgroundColor: isDark
                                                        ? AppColors
                                                              .darkSurfaceSecondary
                                                        : AppColors
                                                              .surfaceSecondary,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(item.color),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String key, String label, IconData icon) {
    final isActive = _period == key;
    return GestureDetector(
      onTap: () => setState(() => _period = key),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
