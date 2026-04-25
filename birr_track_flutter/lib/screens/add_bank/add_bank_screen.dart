import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_provider.dart';
import '../../data/models/transaction.dart';
import '../../data/models/bank.dart';
import '../../core/colors.dart';

class AddBankScreen extends StatefulWidget {
  const AddBankScreen({super.key});

  @override
  State<AddBankScreen> createState() => _AddBankScreenState();
}

class _AddBankScreenState extends State<AddBankScreen> {
  BankInfo? _selectedBank;
  bool _isCashSelected = false;

  final _accountNameController = TextEditingController();
  final _balanceController = TextEditingController();

  bool _smsSyncEnabled = false;
  bool _saving = false;

  @override
  void dispose() {
    _accountNameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _handleSelectCash() {
    setState(() {
      _selectedBank = null;
      _isCashSelected = true;
      final provider = context.read<AppProvider>();
      _balanceController.text = provider.cashBalance > 0 ? provider.cashBalance.toStringAsFixed(2) : '';
      _smsSyncEnabled = false;
    });
  }

  void _handleSelectBank(BankInfo bank) {
    setState(() {
      _isCashSelected = false;
      _selectedBank = bank;
    });
  }

  Future<void> _handleSave() async {
    if (!_isCashSelected && _selectedBank == null) return;
    final balance = double.tryParse(_balanceController.text) ?? 0.0;

    setState(() => _saving = true);
    final provider = context.read<AppProvider>();

    try {
      if (_isCashSelected) {
        await provider.setCashBalance(balance);
        context.pop();
        return;
      }

      if (_selectedBank == null) return;
      final accountId = provider.generateId();
      final account = BankAccount(
        id: accountId,
        bankId: _selectedBank!.id,
        accountName: _accountNameController.text.trim().isNotEmpty
            ? _accountNameController.text.trim()
            : _selectedBank!.shortName,
        balance: balance,
        lastUpdated: DateTime.now().toIso8601String(),
        smsSyncEnabled: _smsSyncEnabled,
      );

      await provider.addBankAccount(account);
      if (_smsSyncEnabled) {
        context.replace('/bank-detail/$accountId');
      } else {
        context.pop();
      }
    } catch (_) {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canSave = _isCashSelected || _selectedBank != null;

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
                  const Text(
                    'Add Account',
                    style: TextStyle(
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

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Account Type',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text),
                    ),
                    const SizedBox(height: 12),

                    // Grid of account options
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.95,
                      ),
                      itemCount: banks.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          // Cash Box
                          return GestureDetector(
                            onTap: _handleSelectCash,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _isCashSelected
                                    ? AppColors.income.withOpacity(0.12)
                                    : (isDark ? AppColors.darkSurface : Colors.white),
                                border: Border.all(
                                  color: _isCashSelected ? AppColors.income : (isDark ? AppColors.darkBorder : AppColors.border),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppColors.income,
                                    child: const Icon(Icons.money, size: 20, color: Colors.white),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Cash',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final bank = banks[index - 1];
                        final isSelected = !_isCashSelected && _selectedBank?.id == bank.id;
                        return GestureDetector(
                          onTap: () => _handleSelectBank(bank),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? bank.color.withOpacity(0.12)
                                  : (isDark ? AppColors.darkSurface : Colors.white),
                              border: Border.all(
                                  color: isSelected ? bank.color : (isDark ? AppColors.darkBorder : AppColors.border),
                                  width: 1.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (bank.logoAsset != null)
                                  Image.asset(bank.logoAsset!, height: 36, width: 36, fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                    return CircleAvatar(
                                      radius: 18,
                                      backgroundColor: bank.color,
                                      child: Text(bank.iconLetter, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    );
                                  })
                                else
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: bank.color,
                                    child: Text(bank.iconLetter, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                const SizedBox(height: 6),
                                Text(
                                  bank.shortName,
                                  style: const TextStyle(fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Cash Fields
                    if (_isCashSelected) ...[
                      const Text(
                        'Cash on Hand (ETB)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('ETB', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _balanceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(hintText: '0.00'),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              autofocus: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.income.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.income.withOpacity(0.15)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, size: 16, color: AppColors.income),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Your cash balance will automatically update when you add transactions with "Cash" as the payment method.',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Bank Fields
                    if (_selectedBank != null) ...[
                      const Text(
                        'Account Name (optional)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _accountNameController,
                        decoration: InputDecoration(hintText: '${_selectedBank!.shortName} Account'),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Current Balance (ETB)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('ETB', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _balanceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(hintText: '0.00'),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // SMS sync
                      Container(
                        padding: const EdgeInsets.all(14),
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
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Enable SMS Parsing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      Text(
                                        'Auto-import transactions from SMS logs',
                                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _smsSyncEnabled,
                                  onChanged: (val) => setState(() => _smsSyncEnabled = val),
                                ),
                              ],
                            ),
                            if (_smsSyncEnabled) ...[
                              const SizedBox(height: 12),
                              Divider(color: isDark ? AppColors.darkBorder : AppColors.borderLight, height: 1),
                              const SizedBox(height: 12),
                              const Row(
                                children: [
                                  Icon(Icons.info_outline, size: 14, color: AppColors.income),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'After adding, you\'ll see bank settings to scan past messages.',
                                      style: TextStyle(fontSize: 12, color: AppColors.income, height: 1.4),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 36),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: canSave && !_saving ? _handleSave : null,
                        child: Text(_saving ? 'Saving...' : (_isCashSelected ? 'Set Cash Balance' : 'Add Bank Account')),
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
