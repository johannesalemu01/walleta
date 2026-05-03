import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/colors.dart';

class PieSlice {
  final String label;
  final double value;
  final Color color;

  PieSlice({
    required this.label,
    required this.value,
    required this.color,
  });
}

class PieChartWidget extends StatelessWidget {
  final List<PieSlice> data;
  final double size;
  final String? centerLabel;
  final String? centerValue;

  const PieChartWidget({
    super.key,
    required this.data,
    this.size = 180,
    this.centerLabel,
    this.centerValue,
  });

  @override
  Widget build(BuildContext context) {
    final total = data.fold(0.0, (sum, d) => sum + d.value);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget chartWidget;
    if (total == 0) {
      chartWidget = PieChart(
        PieChartData(
          sectionsSpace: 0,
          centerSpaceRadius: size * 0.3,
          sections: [
            PieChartSectionData(
              color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceTertiary.withOpacity(0.3),
              value: 1,
              radius: size * 0.2,
              showTitle: false,
            ),
          ],
        ),
      );
    } else {
      chartWidget = PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: size * 0.3,
          sections: data.where((d) => d.value > 0).map((d) {
            return PieChartSectionData(
              color: d.color,
              value: d.value,
              radius: size * 0.2,
              showTitle: false,
            );
          }).toList(),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Spending Breakdown',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: SizedBox(
                    height: size,
                    child: Stack(
                      children: [
                        chartWidget,
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (total == 0) ...[
                                const Text(
                                  'No Data',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ] else ...[
                                if (centerValue != null)
                                  Text(
                                    centerValue!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.text,
                                    ),
                                  ),
                                if (centerLabel != null)
                                  Text(
                                    centerLabel!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 5,
                  child: _buildLegend(total),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(double total) {
    final sortedData = List<PieSlice>.from(data)
        .where((d) => d.value > 0)
        .toList();
    sortedData.sort((a, b) => b.value.compareTo(a.value));

    if (sortedData.isEmpty) {
      return const Center(
        child: Text(
          'No expenses recorded',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedData.length > 5 ? 5 : sortedData.length,
      itemBuilder: (context, index) {
        final slice = sortedData[index];
        final percent = total > 0 ? (slice.value / total * 100).round() : 0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: slice.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  slice.label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
