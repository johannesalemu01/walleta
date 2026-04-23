import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/bank_account_card.dart';
import '../../widgets/transaction_item.dart';
import '../../core/colors.dart';
import '../../core/router.dart';
import '../../data/models/transaction.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _amountsVisible = false;
  final _cashController = TextEditingController();

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  void _showEditCashDialog(BuildContext context, double currentCash) {
    _cashController.text = currentCash > 0 ? currentCash.toStringAsFixed(2) : '';
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Cash Balance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Set your current cash on hand',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _cashController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  prefixText: 'ETB ',
                  hintText: '0.00',
                ),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(_cashController.text) ?? 0.0;
                context.read<AppProvider>().setCashBalance(amount);
                Navigator.pop(context);
              },
              child: const Text('Save'),
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

    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final formattedDate = DateFormat('EEEE, MMMM d').format(now);

    final todayTxns = provider.transactions.where((t) => t.date == todayStr).toList();
    final recentTxns = provider.transactions.take(15).toList();

    final todayIncome = todayTxns.where((t) => t.type == TransactionType.income).fold(0.0, (s, t) => s + t.amount);
    final todayExpense = todayTxns.where((t) => t.type == TransactionType.expense).fold(0.0, (s, t) => s + t.amount);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: provider.refreshData,
        color: AppColors.primary,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Birr Track',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _amountsVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppColors.text,
                            ),
                            onPressed: () => setState(() => _amountsVisible = !_amountsVisible),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: IconButton(
                              icon: const Icon(Icons.add, color: Colors.white),
                              onPressed: () => context.push('/add-transaction'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Balance Card
                BalanceCard(
                  totalBalance: provider.totalBalance,
                  income: provider.monthlyStats['income'] ?? 0.0,
                  expense: provider.monthlyStats['expense'] ?? 0.0,
                  amountsVisible: _amountsVisible,
                ),

                // Accounts Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Accounts',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                          ),
                          if (provider.bankAccounts.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                              onPressed: () => context.push('/add-bank'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (provider.bankAccounts.isEmpty) ...[
                        GestureDetector(
                          onTap: () => context.push('/add-bank'),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.3),
                                width: 1.5,
                                style: BorderStyle.solid, // fallback dashed style using simple card
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.add_circle_outline, size: 36, color: AppColors.primary),
                                const SizedBox(height: 8),
                                Text(
                                  'Add your first bank account',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        SizedBox(
                          height: 110,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              // Cash Card
                              GestureDetector(
                                onTap: () => _showEditCashDialog(context, provider.cashBalance),
                                child: Container(
                                  width: 120,
                                  margin: const EdgeInsets.only(right: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkSurface : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark ? AppColors.darkBorder : AppColors.borderLight,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.money, size: 20, color: AppColors.primary),
                                      ),
                                      const Text(
                                        'Cash',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.text,
                                        ),
                                      ),
                                      Text(
                                        _amountsVisible
                                            ? '${provider.cashBalance.toStringAsFixed(0)} ETB'
                                            : '••••••',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              ...provider.bankAccounts.map((acc) => Padding(
                                    padding: const EdgeInsets.only(right: 10.0),
                                    child: BankAccountCard(account: acc),
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Net with friends card
                if (provider.friends.isNotEmpty && provider.friendsNet.netWithFriends != 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: (provider.friendsNet.netWithFriends > 0 ? AppColors.income : AppColors.expense)
                            .withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: (provider.friendsNet.netWithFriends > 0 ? AppColors.income : AppColors.expense)
                              .withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 18,
                                color: provider.friendsNet.netWithFriends > 0 ? AppColors.income : AppColors.expense,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Net with friends',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.text,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _amountsVisible
                                ? '${provider.friendsNet.netWithFriends >= 0 ? "+" : "−"}${provider.friendsNet.netWithFriends.abs().toStringAsFixed(0)} ETB'
                                : '••••••',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: provider.friendsNet.netWithFriends > 0 ? AppColors.income : AppColors.expense,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Today's summary
                if (todayTxns.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Today',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.arrow_downward, size: 18, color: AppColors.income),
                                const SizedBox(width: 6),
                                Text(
                                  _amountsVisible ? '+${todayIncome.toStringAsFixed(0)} ETB' : '••••••',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(width: 24),
                            Row(
                              children: [
                                const Icon(Icons.arrow_upward, size: 18, color: AppColors.expense),
                                const SizedBox(width: 6),
                                Text(
                                  _amountsVisible ? '-${todayExpense.toStringAsFixed(0)} ETB' : '••••••',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                // Recent Transactions Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Transactions',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                          ),
                          if (provider.transactions.isNotEmpty)
                            TextButton.icon(
                              onPressed: () => context.go('/transactions'),
                              icon: const Icon(Icons.history, size: 16, color: AppColors.primary),
                              label: const Text('History', style: TextStyle(color: AppColors.primary)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (recentTxns.isEmpty) ...[
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 48.0),
                            child: Column(
                              children: [
                                const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textTertiary),
                                const SizedBox(height: 8),
                                const Text(
                                  'No transactions yet',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Tap the + icon to add your first transaction',
                                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.borderLight,
                            ),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: recentTxns.length,
                            separatorBuilder: (context, index) => Divider(
                              color: isDark ? AppColors.darkBorder : AppColors.borderLight,
                              height: 1,
                            ),
                            itemBuilder: (context, index) {
                              return TransactionItem(transaction: recentTxns[index]);
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-transaction'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}
