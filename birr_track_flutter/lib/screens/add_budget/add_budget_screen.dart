import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_provider.dart';
import '../../data/models/transaction.dart';
import '../../data/models/category.dart';
import '../../widgets/category_picker.dart';
import '../../core/colors.dart';

class AddBudgetScreen extends StatefulWidget {
  final String? budgetId;

  const AddBudgetScreen({super.key, this.budgetId});

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _amountController = TextEditingController();

  BudgetPeriod _period = BudgetPeriod.monthly;
  String _budgetType = 'overall'; // 'overall' | 'category'
  String _categoryId = 'food';

  bool _isEditing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check for default period in query parameters or edit
      final uri = GoRouterState.of(context).uri;
      final defaultPeriod = uri.queryParameters['period'];

      if (defaultPeriod != null) {
        final matchedPeriod = BudgetPeriod.values.firstWhere(
          (p) => p.name == defaultPeriod,
          orElse: () => BudgetPeriod.monthly,
        );
        setState(() => _period = matchedPeriod);
      }

      if (widget.budgetId != null) {
        final provider = context.read<AppProvider>();
        final matched = provider.budgets.where((b) => b.id == widget.budgetId).toList();
        if (matched.isNotEmpty) {
          final b = matched.first;
          setState(() {
            _isEditing = true;
            _amountController.text = b.amount.toStringAsFixed(2);
            _period = b.period;
            _budgetType = b.categoryId == null ? 'overall' : 'category';
            if (b.categoryId != null) {
              _categoryId = b.categoryId!;
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid budget amount')),
      );
      return;
    }

    final provider = context.read<AppProvider>();

    // Validation: overall budget already exists for this period
    if (_budgetType == 'overall' && !_isEditing) {
      final overallExists = provider.budgets.any(
        (b) => b.period == _period && b.categoryId == null,
      );
      if (overallExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An overall ${_period.name} budget already exists')),
        );
        return;
      }
    }

    setState(() => _saving = true);

    try {
      final newBudget = Budget(
        id: _isEditing ? widget.budgetId! : provider.generateId(),
        categoryId: _budgetType == 'overall' ? null : _categoryId,
        amount: amount,
        period: _period,
        createdAt: DateTime.now().toIso8601String(),
      );

      if (_isEditing) {
        await provider.updateBudget(newBudget);
      } else {
        await provider.addBudget(newBudget);
      }
      context.pop();
    } catch (_) {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canSave = (double.tryParse(_amountController.text) ?? 0.0) > 0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.text),
                    onPressed: () => context.pop(),
                  ),
                  Text(
                    _isEditing ? 'Edit Budget' : 'Add Budget',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check, color: AppColors.primary),
                    onPressed: canSave && !_saving ? _handleSave : null,
                  ),
                ],
              ),
            ),

            // Scrollable Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Period Selection
                    const Text(
                      'Budget Period',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: BudgetPeriod.values.map((p) {
                        final active = _period == p;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _period = p),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: active ? AppColors.primary.withOpacity(0.12) : AppColors.surfaceSecondary,
                                border: Border.all(
                                  color: active ? AppColors.primary : Colors.transparent,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                p.name.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: active ? AppColors.primary : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Budget Type Selector
                    const Text(
                      'Budget Type',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Overall card
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _budgetType = 'overall'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                              decoration: BoxDecoration(
                                color: _budgetType == 'overall'
                                    ? AppColors.primary.withOpacity(0.08)
                                    : (isDark ? AppColors.darkSurface : Colors.white),
                                border: Border.all(
                                  color: _budgetType == 'overall' ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.borderLight),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.shield_outlined, color: _budgetType == 'overall' ? AppColors.primary : AppColors.textTertiary),
                                  const SizedBox(height: 6),
                                  const Text('Overall', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(height: 2),
                                  const Text('Total spending limit', style: TextStyle(fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Category card
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _budgetType = 'category'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                              decoration: BoxDecoration(
                                color: _budgetType == 'category'
                                    ? AppColors.primary.withOpacity(0.08)
                                    : (isDark ? AppColors.darkSurface : Colors.white),
                                border: Border.all(
                                  color: _budgetType == 'category' ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.borderLight),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.grid_view_outlined, color: _budgetType == 'category' ? AppColors.primary : AppColors.textTertiary),
                                  const SizedBox(height: 6),
                                  const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(height: 2),
                                  const Text('Per-category limit', style: TextStyle(fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Amount Row
                    const Text(
                      'Amount (ETB)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('ETB', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(hintText: '0.00'),
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            autofocus: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Category Picker (if category mode)
                    if (_budgetType == 'category') ...[
                      const Text(
                        'Category',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text),
                      ),
                      const SizedBox(height: 8),
                      CategoryPicker(
                        selectedCategoryId: _categoryId,
                        onCategorySelected: (catId) => setState(() => _categoryId = catId),
                      ),
                    ],

                    const SizedBox(height: 36),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: canSave && !_saving ? _handleSave : null,
                        child: Text(_saving ? 'Saving...' : (_isEditing ? 'Update Budget' : 'Set Budget')),
                      ),
                    ),
                    const SizedBox(height: 48),
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
