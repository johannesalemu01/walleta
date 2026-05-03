import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/models/transaction.dart';
import '../core/colors.dart';

class BarData {
  final String label;
  double income;
  double expense;

  BarData({
    required this.label,
    this.income = 0,
    this.expense = 0,
  });
}

class AnimatedBarChart extends StatelessWidget {
  final List<Transaction> transactions;
  final String period; // 'daily' | 'monthly' | 'yearly'

  const AnimatedBarChart({
    super.key,
    required this.transactions,
    required this.period,
  });

  List<BarData> _getBarData() {
    final now = DateTime.now();

    if (period == 'daily') {
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final todayTxns = transactions.where((t) => t.date == todayStr).toList();

      final List<BarData> hours = [];
      for (int h = 0; h < 24; h += 3) {
        hours.add(BarData(label: '$h h'));
      }

      for (final t in todayTxns) {
        try {
          final dt = DateTime.parse(t.createdAt);
          final hour = dt.hour;
          final idx = (hour / 3).floor().clamp(0, hours.length - 1);
          if (t.type == TransactionType.income) {
            hours[idx].income += t.amount;
          } else {
            hours[idx].expense += t.amount;
          }
        } catch (_) {}
      }
      return hours;
    } else if (period == 'monthly') {
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final List<BarData> weeks = [];
      const weekSize = 7;

      for (int d = 1; d <= daysInMonth; d += weekSize) {
        final endDay = (d + weekSize - 1) < daysInMonth ? (d + weekSize - 1) : daysInMonth;
        weeks.add(BarData(label: '$d-$endDay'));
      }

      final monthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final monthTxns = transactions.where((t) => t.date.startsWith(monthStr)).toList();

      for (final t in monthTxns) {
        try {
          final parts = t.date.split('-');
          final day = int.parse(parts[2]);
          final idx = ((day - 1) / weekSize).floor().clamp(0, weeks.length - 1);
          if (t.type == TransactionType.income) {
            weeks[idx].income += t.amount;
          } else {
            weeks[idx].expense += t.amount;
          }
        } catch (_) {}
      }
      return weeks;
    } else {
      // Yearly
      final yearStr = '${now.year}';
      final yearTxns = transactions.where((t) => t.date.startsWith(yearStr)).toList();

      final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final List<BarData> months = List.generate(12, (i) => BarData(label: monthNames[i]));

      for (final t in yearTxns) {
        try {
          final parts = t.date.split('-');
          final monthIdx = int.parse(parts[1]) - 1;
          if (monthIdx >= 0 && monthIdx < 12) {
            if (t.type == TransactionType.income) {
              months[monthIdx].income += t.amount;
            } else {
              months[monthIdx].expense += t.amount;
            }
          }
        } catch (_) {}
      }
      return months;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _getBarData();
    double maxVal = 0;
    for (final b in data) {
      if (b.income > maxVal) maxVal = b.income;
      if (b.expense > maxVal) maxVal = b.expense;
    }
    if (maxVal == 0) maxVal = 1000; // fallback grid scaling

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Income vs Expenses',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 24),
            AspectRatio(
              aspectRatio: 1.7,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxVal * 1.15,
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxVal / 4,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: isDark ? AppColors.darkBorder : AppColors.borderLight,
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value == 0 || value > maxVal) return const SizedBox.shrink();
                          String text = '';
                          if (value >= 1000) {
                            text = '${(value / 1000).toStringAsFixed(0)}k';
                          } else {
                            text = value.toStringAsFixed(0);
                          }
                          return Text(
                            text,
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < data.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(
                                data[idx].label,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => isDark ? AppColors.darkSurface : Colors.white,
                      tooltipBorder: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${rod.toY.toStringAsFixed(1)} ETB',
                          TextStyle(
                            color: rodIndex == 0 ? AppColors.income : AppColors.expense,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  barGroups: List.generate(data.length, (i) {
                    final item = data[i];
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: item.income,
                          color: AppColors.income,
                          width: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        BarChartRodData(
                          toY: item.expense,
                          color: AppColors.expense,
                          width: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(AppColors.income, 'Income'),
                const SizedBox(width: 24),
                _buildLegendItem(AppColors.expense, 'Expense'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
