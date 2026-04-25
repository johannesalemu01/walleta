import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../data/models/transaction.dart';
import '../../data/models/bank.dart';
import '../../widgets/transaction_item.dart';
import '../../core/colors.dart';

class BankDetailScreen extends StatefulWidget {
  final String bankAccountId;

  const BankDetailScreen({super.key, required this.bankAccountId});

  @override
  State<BankDetailScreen> createState() => _BankDetailScreenState();
}

class _BankDetailScreenState extends State<BankDetailScreen> {
  bool _syncing = false;
  String? _syncResultMsg;
  String? _syncErrorMsg;

  void _confirmDelete(BuildContext context, BankAccount account, BankInfo bank) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Bank Account'),
          content: Text('Delete "${account.accountName}"? Transactions will remain but the bank link will be removed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                context.read<AppProvider>().deleteBankAccount(account.id);
                Navigator.pop(context);
                context.pop();
              },
              child: const Text('Delete', style: TextStyle(color: AppColors.expense)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleScanSms(BankAccount account) async {
    setState(() {
      _syncing = true;
      _syncResultMsg = null;
      _syncErrorMsg = null;
    });

    // We'll hook this up to the SmsService once it's implemented.
    // Stubbing a brief scan delay:
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _syncing = false;
        _syncResultMsg = 'Scan completed. No new SMS messages detected.';
      });
      context.read<AppProvider>().refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final accounts = provider.bankAccounts.where((a) => a.id == widget.bankAccountId).toList();
    if (accounts.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bank Account')),
        body: const Center(
          child: Text('Account not found', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final account = accounts.first;
    final bank = getBankById(account.bankId);
    if (bank == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bank Account')),
        body: const Center(
          child: Text('Bank information missing', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    // Filter transactions
    final bankTxns = provider.transactions.where((t) => t.bankAccountId == account.id).toList();
    bankTxns.sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.text),
                    onPressed: () => context.pop(),
                  ),
                  Text(
                    bank.shortName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.expense),
                    onPressed: () => _confirmDelete(context, account, bank),
                  ),
                ],
              ),
            ),

            // Form Fields
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  children: [
                    // Bank Card details
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: bank.color.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: bank.color.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            if (bank.logoAsset != null)
                              Image.asset(bank.logoAsset!, height: 48, width: 48, fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                return CircleAvatar(
                                  radius: 24,
                                  backgroundColor: bank.color,
                                  child: Text(bank.iconLetter, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                );
                              })
                            else
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: bank.color,
                                child: Text(bank.iconLetter, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                              ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bank.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    account.accountName,
                                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Balance', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                                const SizedBox(height: 2),
                                Text(
                                  '${account.balance.toStringAsFixed(0)} ETB',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Last Synced label
                    if (account.lastSmsSyncAt != null)
                      Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                        child: Text(
                          'Last synced: ${DateFormat('MMMM d, yyyy h:mm a').format(DateTime.parse(account.lastSmsSyncAt!))}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                        ),
                      ),

                    // SMS live toggle card (Android style stub)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderLight),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Auto-import SMS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      Text(
                                        account.smsSyncEnabled ? 'Listening for new bank SMS messages' : 'Tap to enable live SMS scanning',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: account.smsSyncEnabled,
                                  onChanged: (val) {
                                    context.read<AppProvider>().updateBankAccount(
                                          account.copyWith(
                                            smsSyncEnabled: val,
                                            lastUpdated: DateTime.now().toIso8601String(),
                                          ),
                                        );
                                  },
                                ),
                              ],
                            ),
                            if (account.smsSyncEnabled) ...[
                              const SizedBox(height: 12),
                              Divider(color: isDark ? AppColors.darkBorder : AppColors.borderLight, height: 1),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(color: AppColors.income, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Sync listener active — new bank SMS will auto-import',
                                      style: TextStyle(fontSize: 12, color: AppColors.income, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Manual Scan card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderLight),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.phone_android, color: AppColors.primary),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Scan Device SMS Inbox', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      Text(
                                        'Read your inbox history to import past ${bank.shortName} statements.',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _syncing ? null : () => _handleScanSms(account),
                                icon: _syncing
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.settings_overscan),
                                label: Text(_syncing ? 'Scanning Inbox...' : 'Scan & Import'),
                              ),
                            ),
                            if (_syncResultMsg != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _syncResultMsg!,
                                style: const TextStyle(fontSize: 12, color: AppColors.income, fontWeight: FontWeight.w600),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            if (_syncErrorMsg != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _syncErrorMsg!,
                                style: const TextStyle(fontSize: 12, color: AppColors.expense, fontWeight: FontWeight.w600),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Transaction List for this bank
                    Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20.0, top: 24.0, bottom: 12.0),
                      child: Text(
                        'TRANSACTIONS (${bankTxns.length})',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textTertiary, letterSpacing: 0.5),
                      ),
                    ),

                    if (bankTxns.isEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48.0),
                        child: Column(
                          children: [
                            const Icon(Icons.receipt_long_outlined, size: 36, color: AppColors.textTertiary),
                            const SizedBox(height: 8),
                            const Text(
                              'No transactions for this bank yet',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Tap Scan & Import above to read statements from SMS',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Container(
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
                            itemCount: bankTxns.length,
                            separatorBuilder: (context, index) => Divider(
                              color: isDark ? AppColors.darkBorder : AppColors.borderLight,
                              height: 1,
                            ),
                            itemBuilder: (context, index) {
                              return TransactionItem(transaction: bankTxns[index]);
                            },
                          ),
                        ),
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
}
