import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../widgets/budget_progress_bar.dart';
import '../../data/models/transaction.dart';
import '../../core/colors.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  BudgetPeriod _selectedPeriod = BudgetPeriod.monthly;

  Map<String, String> _getPeriodDateRange() {
    final now = DateTime.now();
    if (_selectedPeriod == BudgetPeriod.daily) {
      final dateStr = DateFormat('yyyy-MM-dd').format(now);
      return {
        'start': dateStr,
        'end': dateStr,
        'label': DateFormat('MMMM d, yyyy').format(now),
      };
    } else if (_selectedPeriod == BudgetPeriod.weekly) {
      final weekStart = now.subtract(Duration(days: now.weekday % 7));
      final weekEnd = weekStart.add(const Duration(days: 6));
      final startStr = DateFormat('yyyy-MM-dd').format(weekStart);
      final endStr = DateFormat('yyyy-MM-dd').format(weekEnd);
      return {
        'start': startStr,
        'end': endStr,
        'label': '${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d, yyyy').format(weekEnd)}',
      };
    } else if (_selectedPeriod == BudgetPeriod.yearly) {
      final startStr = '${now.year}-01-01';
      final endStr = '${now.year}-12-31';
      return {
        'start': startStr,
        'end': endStr,
        'label': 'Year of ${now.year}',
      };
    } else {
      // Monthly
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final startStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
      final endStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-$daysInMonth';
      return {
        'start': startStr,
        'end': endStr,
        'label': DateFormat('MMMM yyyy').format(now),
      };
    }
  }

  void _confirmDelete(BuildContext context, Budget budget) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Budget'),
          content: const Text('Are you sure you want to delete this budget?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                context.read<AppProvider>().deleteBudget(budget.id);
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: AppColors.expense)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dateRange = _getPeriodDateRange();

    // Filter budgets
    final periodBudgets = provider.budgets.where((b) => b.period == _selectedPeriod).toList();
    final overallBudget = periodBudgets.firstWhere((b) => b.categoryId == null, orElse: () => const Budget(id: '', amount: 0, period: BudgetPeriod.monthly, createdAt: ''));
    final categoryBudgets = periodBudgets.where((b) => b.categoryId != null).toList();

    // Expenses in range
    final periodExpenses = provider.transactions.where((t) {
      if (t.type != TransactionType.expense) return false;
      return t.date.compareTo(dateRange['start']!) >= 0 && t.date.compareTo(dateRange['end']!) <= 0;
    }).toList();

    final totalSpent = periodExpenses.fold(0.0, (sum, t) => sum + t.amount);

    final overallBudgetExists = overallBudget.id.isNotEmpty;
    final overallPct = overallBudgetExists && overallBudget.amount > 0
        ? (totalSpent / overallBudget.amount).clamp(0.0, 1.0)
        : 0.0;

    final overallBarColor = overallBudgetExists
        ? totalSpent > overallBudget.amount
            ? AppColors.expense
            : totalSpent > overallBudget.amount * 0.8
                ? Colors.orange
                : AppColors.primary
        : AppColors.primary;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Budget',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 28, color: AppColors.primary),
                    onPressed: () => context.push('/add-budget?period=${_selectedPeriod.name}'),
                  ),
                ],
              ),
            ),

            // Period Selector Row
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SizedBox(
                height: 70,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  children: BudgetPeriod.values.map((p) {
                    final active = _selectedPeriod == p;
                    final count = provider.budgets.where((b) => b.period == p).length;
                    IconData icon;
                    String label;
                    switch (p) {
                      case BudgetPeriod.daily:
                        icon = Icons.today;
                        label = 'Daily';
                        break;
                      case BudgetPeriod.weekly:
                        icon = Icons.calendar_view_week;
                        label = 'Weekly';
                        break;
                      case BudgetPeriod.monthly:
                        icon = Icons.calendar_month;
                        label = 'Monthly';
                        break;
                      case BudgetPeriod.yearly:
                        icon = Icons.language;
                        label = 'Yearly';
                        break;
                    }

                    return GestureDetector(
                      onTap: () => setState(() => _selectedPeriod = p),
                      child: Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary.withOpacity(0.12) : AppColors.surfaceSecondary,
                          border: Border.all(
                            color: active ? AppColors.primary : Colors.transparent,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(icon, size: 14, color: active ? AppColors.primary : AppColors.textTertiary),
                                const SizedBox(width: 4),
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: active ? AppColors.primary : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: active ? AppColors.primary : AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Date Range Label
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Text(
                dateRange['label']!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Main Content Area
            Expanded(
              child: periodBudgets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: const Icon(Icons.wallet_outlined, size: 40, color: AppColors.primary),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No ${_selectedPeriod.name} budgets',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.text),
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40.0),
                            child: Text(
                              'Set a ${_selectedPeriod.name} budget to track and control your spending habits.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/add-budget?period=${_selectedPeriod.name}'),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Budget'),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 100),
                      child: Column(
                        children: [
                          // Overall Budget Card
                          if (overallBudgetExists)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                              child: GestureDetector(
                                onTap: () => context.push('/add-budget?id=${overallBudget.id}'),
                                onLongPress: () => _confirmDelete(context, overallBudget),
                                child: Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkSurface : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark ? AppColors.darkBorder : AppColors.borderLight,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            child: const Icon(Icons.shield_outlined, size: 24, color: AppColors.primary),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Overall ${_selectedPeriod.name.toUpperCase()} Budget',
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.text,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${totalSpent.toStringAsFixed(0)} spent of ${overallBudget.amount.toStringAsFixed(0)} ETB',
                                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '${(overallPct * 100).toStringAsFixed(0)}%',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: overallBarColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(5),
                                        child: LinearProgressIndicator(
                                          value: overallPct,
                                          minHeight: 10,
                                          backgroundColor: isDark
                                              ? AppColors.darkSurfaceSecondary
                                              : AppColors.surfaceTertiary.withOpacity(0.3),
                                          valueColor: AlwaysStoppedAnimation<Color>(overallBarColor),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          _buildStatColumn('Budget', '${overallBudget.amount.toStringAsFixed(0)} ETB', AppColors.text),
                                          Container(
                                            width: 1,
                                            height: 28,
                                            color: isDark ? AppColors.darkBorder : AppColors.borderLight,
                                          ),
                                          _buildStatColumn('Spent', '${totalSpent.toStringAsFixed(0)} ETB', AppColors.expense),
                                          Container(
                                            width: 1,
                                            height: 28,
                                            color: isDark ? AppColors.darkBorder : AppColors.borderLight,
                                          ),
                                          _buildStatColumn(
                                            totalSpent > overallBudget.amount ? 'Over' : 'Left',
                                            '${(overallBudget.amount - totalSpent).abs().toStringAsFixed(0)} ETB',
                                            totalSpent > overallBudget.amount ? AppColors.expense : AppColors.income,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          // Category Budgets Title
                          if (categoryBudgets.isNotEmpty) ...[
                            Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 20.0, top: 16.0, bottom: 8.0),
                              child: const Text(
                                'CATEGORY BUDGETS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: categoryBudgets.length,
                              itemBuilder: (context, index) {
                                final budget = categoryBudgets[index];
                                return GestureDetector(
                                  onTap: () => context.push('/add-budget?id=${budget.id}'),
                                  onLongPress: () => _confirmDelete(context, budget),
                                  child: BudgetProgressBar(budget: budget),
                                );
                              },
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

  Widget _buildStatColumn(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
