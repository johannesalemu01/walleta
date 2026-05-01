import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/models/transaction.dart';
import '../core/colors.dart';

class DayData {
  final String date;
  double income;
  double expense;
  double net;

  DayData({
    required this.date,
    this.income = 0,
    this.expense = 0,
    this.net = 0,
  });
}

class ContributionHeatmap extends StatefulWidget {
  final List<Transaction> transactions;
  final String period; // 'daily' | 'monthly' | 'yearly'

  const ContributionHeatmap({
    super.key,
    required this.transactions,
    required this.period,
  });

  @override
  State<ContributionHeatmap> createState() => _ContributionHeatmapState();
}

class _ContributionHeatmapState extends State<ContributionHeatmap> {
  DayData? _selectedDay;

  List<String> _getDaysForPeriod() {
    final now = DateTime.now();
    final List<String> days = [];

    if (widget.period == 'daily' || widget.period == 'monthly') {
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      for (int d = 1; d <= daysInMonth; d++) {
        final date = DateTime(now.year, now.month, d);
        days.add(DateFormat('yyyy-MM-dd').format(date));
      }
    } else {
      // Last 365 days
      for (int i = 364; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        days.add(DateFormat('yyyy-MM-dd').format(date));
      }
    }
    return days;
  }

  Color _getColor(double net, double maxAbs, bool isDark) {
    if (net == 0) {
      return isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary;
    }

    final intensity = (net.abs() / (maxAbs > 0 ? maxAbs : 1.0)).clamp(0.0, 1.0);
    final idx = (intensity * 4).floor().clamp(0, 4);

    final greenShades = [
      const Color(0x3322C55E),
      const Color(0x6622C55E),
      const Color(0xAA22C55E),
      const Color(0xDD22C55E),
      const Color(0xFF22C55E),
    ];

    final redShades = [
      const Color(0x33EF4444),
      const Color(0x66EF4444),
      const Color(0xAAEF4444),
      const Color(0xDDEF4444),
      const Color(0xFFEF4444),
    ];

    return net > 0 ? greenShades[idx] : redShades[idx];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final days = _getDaysForPeriod();

    // Map transactions
    final Map<String, DayData> dayMap = {};
    for (final date in days) {
      dayMap[date] = DayData(date: date);
    }

    for (final t in widget.transactions) {
      if (dayMap.containsKey(t.date)) {
        final data = dayMap[t.date]!;
        if (t.type == TransactionType.income) {
          data.income += t.amount;
          data.net += t.amount;
        } else {
          data.expense += t.amount;
          data.net -= t.amount;
        }
      }
    }

    double maxAbs = 0;
    for (final data in dayMap.values) {
      if (data.net.abs() > maxAbs) {
        maxAbs = data.net.abs();
      }
    }

    // Build grid (cols of 7 rows)
    final List<List<String?>> grid = [];
    if (days.isNotEmpty) {
      final firstDay = DateTime.parse(days.first);
      final startDow = firstDay.weekday % 7; // 0=Sun, 1=Mon, ..., 6=Sat

      List<String?> col = List.filled(7, null);
      int dayIdx = 0;

      // Fill first column
      for (int row = startDow; row < 7 && dayIdx < days.length; row++) {
        col[row] = days[dayIdx++];
      }
      grid.add(col);

      // Fill remaining columns
      while (dayIdx < days.length) {
        col = List.filled(7, null);
        for (int row = 0; row < 7 && dayIdx < days.length; row++) {
          col[row] = days[dayIdx++];
        }
        grid.add(col);
      }
    }

    final isYearly = widget.period == 'yearly';
    final double cellSize = isYearly ? 10 : 14;
    final double cellGap = isYearly ? 2 : 3;

    final dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Activity Heatmap',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.text,
                  ),
                ),
                if (_selectedDay != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Text(
                          DateFormat('MMM dd').format(DateTime.parse(_selectedDay!.date)),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_selectedDay!.net >= 0 ? "+" : ""}${_selectedDay!.net.toStringAsFixed(0)} ETB',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _selectedDay!.net >= 0 ? AppColors.income : AppColors.expense,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day Labels column
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: List.generate(7, (i) {
                    return Container(
                      height: cellSize + cellGap,
                      alignment: Alignment.center,
                      child: Text(
                        i % 2 == 1 ? dayLabels[i] : '',
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(width: 6),
                // Heatmap Grid
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Row(
                      children: List.generate(grid.length, (colIdx) {
                        final col = grid[colIdx];
                        return Container(
                          margin: EdgeInsets.only(right: cellGap),
                          child: Column(
                            children: List.generate(7, (rowIdx) {
                              final dateStr = col[rowIdx];
                              if (dateStr == null) {
                                return SizedBox(
                                  width: cellSize,
                                  height: cellSize,
                                  child: Container(color: Colors.transparent),
                                );
                              }
                              final dayData = dayMap[dateStr];
                              final color = _getColor(dayData?.net ?? 0, maxAbs, isDark);

                              return GestureDetector(
                                onTap: () {
                                  if (dayData != null && (dayData.income > 0 || dayData.expense > 0)) {
                                    setState(() {
                                      _selectedDay = _selectedDay?.date == dateStr ? null : dayData;
                                    });
                                  }
                                },
                                child: Container(
                                  width: cellSize,
                                  height: cellSize,
                                  margin: EdgeInsets.only(bottom: cellGap),
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(isYearly ? 2 : 3),
                                  ),
                                ),
                              );
                            }),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('More Expense', style: TextStyle(fontSize: 9, color: AppColors.textTertiary)),
                const SizedBox(width: 4),
                Row(
                  children: [
                    _buildLegendSquare(const Color(0xFFEF4444)),
                    _buildLegendSquare(const Color(0xDDEF4444)),
                    _buildLegendSquare(const Color(0xAAEF4444)),
                    _buildLegendSquare(const Color(0x66EF4444)),
                    _buildLegendSquare(isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary),
                    _buildLegendSquare(const Color(0x6622C55E)),
                    _buildLegendSquare(const Color(0xAA22C55E)),
                    _buildLegendSquare(const Color(0xDD22C55E)),
                    _buildLegendSquare(const Color(0xFF22C55E)),
                  ],
                ),
                const SizedBox(width: 4),
                const Text('More Income', style: TextStyle(fontSize: 9, color: AppColors.textTertiary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendSquare(Color color) {
    return Container(
      width: 9,
      height: 9,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }
}
