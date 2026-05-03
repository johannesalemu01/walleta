import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models/transaction.dart';
import '../data/models/category.dart';
import '../providers/app_provider.dart';
import '../core/colors.dart';

class BudgetProgressBar extends StatelessWidget {
  final Budget budget;

  const BudgetProgressBar({super.key, required this.budget});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    
    // Find category
    final category = budget.categoryId != null
        ? defaultCategories.firstWhere(
            (c) => c.id == budget.categoryId,
            orElse: () => defaultCategories.first,
          )
        : null;

    final categoryName = category?.name ?? 'Overall Budget';
    final categoryColor = category?.color ?? AppColors.primary;
    final categoryIcon = category?.icon ?? Icons.all_inclusive;

    // Calculate spent for budget period
    // Standard monthly budget check
    final now = DateTime.now();
    final prefix = budget.period == BudgetPeriod.daily
        ? '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}'
        : budget.period == BudgetPeriod.weekly
            // Simpler fallback: current month
            ? '${now.year}-${now.month.toString().padLeft(2, '0')}'
            : budget.period == BudgetPeriod.yearly
                ? '${now.year}'
                : '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final categoryTxns = provider.transactions.where((t) {
      if (t.type != TransactionType.expense) return false;
      if (budget.categoryId != null && t.categoryId != budget.categoryId) return false;
      return t.date.startsWith(prefix);
    });

    final spent = categoryTxns.fold(0.0, (sum, t) => sum + t.amount);
    final limit = budget.amount;
    final progress = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
    final isOver = spent > limit;

    Color progressColor;
    if (progress >= 1.0) {
      progressColor = AppColors.expense;
    } else if (progress >= 0.8) {
      progressColor = Colors.orange;
    } else {
      progressColor = isOver ? AppColors.expense : categoryColor;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    categoryIcon,
                    color: categoryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        'Period: ${budget.period.name}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${spent.toStringAsFixed(0)} / ${limit.toStringAsFixed(0)} ETB',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isOver ? AppColors.expense : AppColors.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(0)}% spent',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOver ? AppColors.expense : AppColors.textSecondary,
                    fontWeight: isOver ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (isOver)
                  const Text(
                    'Limit Exceeded!',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.expense,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  Text(
                    '${(limit - spent).toStringAsFixed(0)} ETB left',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
