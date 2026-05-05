import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../data/models/transaction.dart';
import '../core/colors.dart';

class DataPoint {
  final String label;
  final double value;

  DataPoint({required this.label, required this.value});
}

class SpendingFlowChart extends StatelessWidget {
  final List<Transaction> transactions;
  final String period; // 'daily' | 'monthly' | 'yearly'

  const SpendingFlowChart({
    super.key,
    required this.transactions,
    required this.period,
  });

  List<DataPoint> _getDataPoints() {
    final now = DateTime.now();

    if (period == 'daily') {
      // Last 7 days net daily balance
      final List<DataPoint> points = [];
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(date);

        final dayTxns = transactions.where((t) => t.date == dateStr);
        final net = dayTxns.fold(0.0, (sum, t) => sum + (t.type == TransactionType.income ? t.amount : -t.amount));

        points.add(DataPoint(
          label: DateFormat('E').format(date),
          value: net,
        ));
      }
      return points;
    } else if (period == 'monthly') {
      // Daily cumulative net for current month
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final currentDay = now.day;
      final List<DataPoint> points = [];
      final monthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      double cumulative = 0;
      for (int d = 1; d <= currentDay; d++) {
        final dateStr = '$monthStr-${d.toString().padLeft(2, '0')}';
        final dayTxns = transactions.where((t) => t.date == dateStr);
        final net = dayTxns.fold(0.0, (sum, t) => sum + (t.type == TransactionType.income ? t.amount : -t.amount));
        cumulative += net;

        if (d % 3 == 1 || d == currentDay) {
          points.add(DataPoint(
            label: '$d',
            value: cumulative,
          ));
        }
      }
      return points;
    } else {
      // Monthly net for the year cumulative
      final yearStr = '${now.year}';
      final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final List<DataPoint> points = [];
      double cumulative = 0;

      for (int m = 0; m < 12; m++) {
        final monthStr = '$yearStr-${(m + 1).toString().padLeft(2, '0')}';
        final monthTxns = transactions.where((t) => t.date.startsWith(monthStr));
        final net = monthTxns.fold(0.0, (sum, t) => sum + (t.type == TransactionType.income ? t.amount : -t.amount));
        cumulative += net;
        points.add(DataPoint(label: monthNames[m], value: cumulative));
      }
      return points;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataPoints = _getDataPoints();
    if (dataPoints.length < 2) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          height: 200,
          alignment: Alignment.center,
          child: const Text(
            'Not enough data to display flow chart',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final latestValue = dataPoints.last.value;
    final isPositive = latestValue >= 0;
    final lineColor = isPositive ? AppColors.income : AppColors.expense;

    double minVal = dataPoints[0].value;
    double maxVal = dataPoints[0].value;
    for (final pt in dataPoints) {
      if (pt.value < minVal) minVal = pt.value;
      if (pt.value > maxVal) maxVal = pt.value;
    }

    final range = maxVal - minVal;
    final paddingVal = range == 0 ? 100.0 : range * 0.15;
    final minY = minVal - paddingVal;
    final maxY = maxVal + paddingVal;

    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                Text(
                  period == 'daily' ? 'Daily Net' : 'Cumulative Flow',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  '${latestValue >= 0 ? "+" : ""}${latestValue.toStringAsFixed(0)} ETB',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: lineColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            AspectRatio(
              aspectRatio: 1.7,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      if (value.abs() < 1) {
                        return FlLine(
                          color: isDark ? AppColors.textTertiary.withOpacity(0.3) : AppColors.textSecondary.withOpacity(0.3),
                          strokeWidth: 1.5,
                          dashArray: [4, 4],
                        );
                      }
                      return FlLine(
                        color: isDark ? AppColors.darkBorder : AppColors.borderLight,
                        strokeWidth: 0.5,
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
                          if (value == minY || value == maxY) return const SizedBox.shrink();
                          String text = '';
                          if (value.abs() >= 1000) {
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
                          if (idx >= 0 && idx < dataPoints.length) {
                            // Show subset of labels
                            final step = (dataPoints.length / 5).ceil();
                            if (idx == 0 || idx == dataPoints.length - 1 || idx % step == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Text(
                                  dataPoints[idx].label,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (spot) => isDark ? AppColors.darkSurface : Colors.white,
                      tooltipBorder: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            '${spot.y.toStringAsFixed(1)} ETB',
                            TextStyle(
                              color: lineColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(dataPoints.length, (i) {
                        return FlSpot(i.toDouble(), dataPoints[i].value);
                      }),
                      isCurved: true,
                      color: lineColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 3,
                            color: lineColor,
                            strokeWidth: 1,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            lineColor.withOpacity(0.3),
                            lineColor.withOpacity(0.02),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
