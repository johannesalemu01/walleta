import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_provider.dart';
import '../../widgets/transaction_item.dart';
import '../../data/models/transaction.dart';
import '../../core/colors.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _filter = 'all'; // 'all' | 'expense' | 'income'
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDelete(BuildContext context, Transaction txn) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Transaction'),
          content: const Text('Are you sure you want to delete this transaction?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                context.read<AppProvider>().deleteTransaction(txn.id);
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

    // Filtering logic
    final filtered = provider.transactions.where((t) {
      // Filter by type
      if (_filter == 'expense' && t.type != TransactionType.expense) return false;
      if (_filter == 'income' && t.type != TransactionType.income) return false;

      // Filter by search
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final descMatches = t.description.toLowerCase().contains(query);
        final cat = provider.categories.firstWhere((c) => c.id == t.categoryId, orElse: () => provider.categories.first);
        final catMatches = cat.name.toLowerCase().contains(query);
        return descMatches || catMatches;
      }

      return true;
    }).toList();

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
                    'Transactions',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 28, color: AppColors.primary),
                    onPressed: () => context.push('/add-transaction'),
                  ),
                ],
              ),
            ),

            // Search Box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search transactions...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.textTertiary),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  style: const TextStyle(color: AppColors.text),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  _buildFilterChip('all', 'All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('expense', 'Expenses'),
                  const SizedBox(width: 8),
                  _buildFilterChip('income', 'Income'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Transaction List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textTertiary),
                          const SizedBox(height: 8),
                          const Text(
                            'No transactions found',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _searchQuery.isNotEmpty ? 'Try a different search query' : 'Add your first transaction',
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final txn = filtered[index];
                        return GestureDetector(
                          onLongPress: () => _confirmDelete(context, txn),
                          child: TransactionItem(transaction: txn),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isActive = _filter == key;
    return GestureDetector(
      onTap: () => setState(() => _filter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
