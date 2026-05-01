import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/models/transaction.dart';
import '../core/colors.dart';

class SpendingStreakCard extends StatelessWidget {
  final List<Transaction> transactions;

  const SpendingStreakCard({super.key, required this.transactions});

  Map<String, dynamic> _calculateStats() {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    // 1. Savings streak (consecutive days with net >= 0 and at least one transaction)
    int streak = 0;
    for (int i = 0; i < 365; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final dayTxns = transactions.where((t) => t.date == dateStr).toList();

      if (dayTxns.isEmpty && i > 0) break;
      if (dayTxns.isEmpty) continue;

      final net = dayTxns.fold(0.0, (sum, t) => sum + (t.type == TransactionType.income ? t.amount : -t.amount));
      if (net >= 0) {
        streak++;
      } else {
        break;
      }
    }

    // 2. Average daily spending (last 30 days)
    double totalExpense = 0;
    int daysWithData = 0;
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final dayExpenseTxns = transactions.where((t) => t.date == dateStr && t.type == TransactionType.expense).toList();

      if (dayExpenseTxns.isNotEmpty) {
        totalExpense += dayExpenseTxns.fold(0.0, (sum, t) => sum + t.amount);
        daysWithData++;
      }
    }
    final avgDaily = daysWithData > 0 ? totalExpense / daysWithData : 0.0;

    // 3. Best saving day (last 30 days)
    String bestDay = '';
    double bestNet = -99999999.0;
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final dayTxns = transactions.where((t) => t.date == dateStr).toList();

      if (dayTxns.isNotEmpty) {
        final net = dayTxns.fold(0.0, (sum, t) => sum + (t.type == TransactionType.income ? t.amount : -t.amount));
        if (net > bestNet) {
          bestNet = net;
          bestDay = DateFormat('MMM dd').format(date);
        }
      }
    }

    // 4. Today's transaction count
    final todayCount = transactions.where((t) => t.date == todayStr).length;

    return {
      'streak': streak,
      'avgDaily': avgDaily,
      'bestDay': bestDay.isNotEmpty ? bestDay : '—',
      'todayCount': todayCount,
    };
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Insights',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    label: 'Saving Streak',
                    value: '${stats['streak']} day${stats['streak'] != 1 ? "s" : ""}',
                    color: AppColors.income,
                    icon: Icons.local_fire_department,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatItem(
                    label: 'Avg Daily Spend',
                    value: '${(stats['avgDaily'] as double).toStringAsFixed(0)} ETB',
                    color: AppColors.expense,
                    icon: Icons.trending_down,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    label: 'Best Saving Day',
                    value: stats['bestDay'],
                    color: AppColors.accent,
                    icon: Icons.emoji_events,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatItem(
                    label: "Today's Txns",
                    value: '${stats['todayCount']}',
                    color: AppColors.primary,
                    icon: Icons.receipt_long,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
