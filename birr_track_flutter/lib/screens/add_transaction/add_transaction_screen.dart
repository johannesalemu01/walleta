import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../data/models/transaction.dart';
import '../../data/models/category.dart';
import '../../data/models/bank.dart';
import '../../widgets/category_picker.dart';
import '../../core/colors.dart';

class AddTransactionScreen extends StatefulWidget {
  final String? transactionId;

  const AddTransactionScreen({super.key, this.transactionId});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  String _categoryId = 'food';
  String _paymentMethod = 'cash'; // 'cash' or bankAccountId
  String _date = '';

  bool _isEditing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _date = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Prepopulate if editing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.transactionId != null) {
        final provider = context.read<AppProvider>();
        final txns = provider.transactions.where((t) => t.id == widget.transactionId).toList();
        if (txns.isNotEmpty) {
          final txn = txns.first;
          setState(() {
            _isEditing = true;
            _amountController.text = txn.amount.toStringAsFixed(2);
            _descController.text = txn.description;
            _type = txn.type;
            _categoryId = txn.categoryId;
            _paymentMethod = txn.paymentMethod == 'cash' ? 'cash' : (txn.bankAccountId ?? 'cash');
            _date = txn.date;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_date),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _date = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _handleSave() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _saving = true);

    final provider = context.read<AppProvider>();

    try {
      final txn = Transaction(
        id: _isEditing ? widget.transactionId! : provider.generateId(),
        amount: amount,
        type: _type,
        categoryId: _categoryId,
        description: _descController.text.trim(),
        date: _date,
        paymentMethod: _paymentMethod == 'cash' ? 'cash' : 'bank',
        bankAccountId: _paymentMethod == 'cash' ? null : _paymentMethod,
        createdAt: DateTime.now().toIso8601String(),
      );

      if (_isEditing) {
        await provider.updateTransaction(txn);
      } else {
        await provider.addTransaction(txn);
      }
      context.pop();
    } catch (_) {
      setState(() => _saving = false);
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Transaction'),
          content: const Text('Are you sure you want to delete this transaction?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: AppColors.expense)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() => _saving = true);
      await context.read<AppProvider>().deleteTransaction(widget.transactionId!);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final canSave = (double.tryParse(_amountController.text) ?? 0.0) > 0 && _categoryId.isNotEmpty;

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
                    _isEditing ? 'Edit Transaction' : 'Add Transaction',
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
                    // Expense / Income Toggle
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _type = TransactionType.expense),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _type == TransactionType.expense
                                    ? AppColors.expense
                                    : (isDark ? AppColors.darkSurface : Colors.white),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _type == TransactionType.expense
                                      ? AppColors.expense
                                      : (isDark ? AppColors.darkBorder : AppColors.border),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.arrow_upward, color: _type == TransactionType.expense ? Colors.white : AppColors.textSecondary, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Expense',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _type == TransactionType.expense ? Colors.white : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _type = TransactionType.income),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _type == TransactionType.income
                                    ? AppColors.income
                                    : (isDark ? AppColors.darkSurface : Colors.white),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _type == TransactionType.income
                                      ? AppColors.income
                                      : (isDark ? AppColors.darkBorder : AppColors.border),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.arrow_downward, color: _type == TransactionType.income ? Colors.white : AppColors.textSecondary, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Income',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _type == TransactionType.income ? Colors.white : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Amount Container
                    Row(
                      children: [
                        const Text(
                          'ETB',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              hintText: '0.00',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                            onChanged: (val) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Description Input
                    TextField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        hintText: 'Description (optional)',
                        filled: true,
                        fillColor: AppColors.surfaceSecondary,
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(color: AppColors.text),
                    ),
                    const SizedBox(height: 20),

                    // Date Selector
                    const Text(
                      'Date',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('MMMM d, yyyy').format(DateTime.parse(_date)),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Icon(Icons.calendar_today, size: 18, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Category Picker
                    const Text(
                      'Category',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text),
                    ),
                    const SizedBox(height: 8),
                    CategoryPicker(
                      selectedCategoryId: _categoryId,
                      onCategorySelected: (catId) => setState(() => _categoryId = catId),
                    ),
                    const SizedBox(height: 20),

                    // Payment Method selector
                    const Text(
                      'Payment Method',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // Cash Option
                        GestureDetector(
                          onTap: () => setState(() => _paymentMethod = 'cash'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                            decoration: BoxDecoration(
                              color: _paymentMethod == 'cash'
                                  ? AppColors.primary.withOpacity(0.12)
                                  : (isDark ? AppColors.darkSurface : Colors.white),
                              border: Border.all(
                                color: _paymentMethod == 'cash' ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.border),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.money, size: 16, color: _paymentMethod == 'cash' ? AppColors.primary : AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Text(
                                  'Cash',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _paymentMethod == 'cash' ? AppColors.primary : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Bank Options
                        ...provider.bankAccounts.map((acc) {
                          final bank = getBankById(acc.bankId);
                          final active = _paymentMethod == acc.id;
                          return GestureDetector(
                            onTap: () => setState(() => _paymentMethod = acc.id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                              decoration: BoxDecoration(
                                color: active
                                    ? AppColors.primary.withOpacity(0.12)
                                    : (isDark ? AppColors.darkSurface : Colors.white),
                                border: Border.all(
                                  color: active ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.border),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: bank?.color ?? const Color(0xFF666666),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    bank?.shortName ?? acc.accountName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: active ? AppColors.primary : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 36),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: canSave && !_saving ? _handleSave : null,
                        child: Text(_saving ? 'Saving...' : (_isEditing ? 'Update Transaction' : 'Save Transaction')),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Delete Button (if editing)
                    if (_isEditing)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: !_saving ? _handleDelete : null,
                          icon: const Icon(Icons.delete_outline, color: AppColors.expense),
                          label: const Text('Delete Transaction', style: TextStyle(color: AppColors.expense)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.expense),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
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
