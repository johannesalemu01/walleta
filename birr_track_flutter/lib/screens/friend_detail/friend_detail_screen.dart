import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/app_provider.dart';
import '../../data/models/transaction.dart';
import '../../core/colors.dart';

class FriendDetailScreen extends StatefulWidget {
  final String friendId;

  const FriendDetailScreen({super.key, required this.friendId});

  @override
  State<FriendDetailScreen> createState() => _FriendDetailScreenState();
}

class _FriendDetailScreenState extends State<FriendDetailScreen> {
  bool _showForm = false;
  LoanDirection _direction = LoanDirection.lent;
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _saving = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePhoto(Friend friend) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 70,
      );
      if (image != null) {
        final provider = context.read<AppProvider>();
        await provider.updateFriend(friend.copyWith(photoUri: image.path));
      }
    } catch (_) {}
  }

  Future<void> _handleAddEntry(Friend friend) async {
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
      final ft = FriendTransaction(
        id: provider.generateId(),
        friendId: friend.id,
        direction: _direction,
        amount: amount,
        reason: _reasonController.text.trim().isNotEmpty ? _reasonController.text.trim() : null,
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        createdAt: DateTime.now().toIso8601String(),
      );

      await provider.addFriendTransaction(ft);
      setState(() {
        _amountController.clear();
        _reasonController.clear();
        _showForm = false;
        _saving = false;
      });
    } catch (_) {
      setState(() => _saving = false);
    }
  }

  void _confirmDeleteFriend(BuildContext context, Friend friend) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Friend'),
          content: Text('Remove "${friend.name}" and all their loan entries?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                context.read<AppProvider>().deleteFriend(friend.id);
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

  void _confirmDeleteEntry(BuildContext context, FriendTransaction ft) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete entry'),
          content: const Text('Remove this loan entry?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                context.read<AppProvider>().deleteFriendTransaction(ft.id);
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

    final matched = provider.friends.where((f) => f.id == widget.friendId).toList();
    if (matched.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Friend Details')),
        body: const Center(
          child: Text('Friend not found', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final friend = matched.first;
    final net = provider.getFriendNet(friend.id);
    final isPositive = net > 0;
    final isNeutral = net == 0;

    // Filter friend transactions
    final friendTxns = provider.friendTransactions.where((t) => t.friendId == friend.id).toList();
    friendTxns.sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
                    friend.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.expense),
                    onPressed: () => _confirmDeleteFriend(context, friend),
                  ),
                ],
              ),
            ),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  children: [
                    // Profile card
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => _handleChangePhoto(friend),
                            child: Stack(
                              children: [
                                if (friend.photoUri != null && friend.photoUri!.isNotEmpty)
                                  CircleAvatar(
                                    radius: 40,
                                    backgroundImage: FileImage(File(friend.photoUri!)),
                                  )
                                else
                                  CircleAvatar(
                                    radius: 40,
                                    backgroundColor: isNeutral
                                        ? AppColors.textTertiary.withOpacity(0.12)
                                        : isPositive
                                            ? AppColors.income.withOpacity(0.12)
                                            : AppColors.expense.withOpacity(0.12),
                                    child: Text(
                                      friend.name[0].toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                        color: isNeutral
                                            ? AppColors.textSecondary
                                            : isPositive
                                                ? AppColors.income
                                                : AppColors.expense,
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: AppColors.primary,
                                    child: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            friend.name,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text),
                          ),
                          if (friend.phone != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              friend.phone!,
                              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderLight),
                            ),
                            child: Text(
                              isNeutral
                                  ? 'Settled up'
                                  : isPositive
                                      ? 'Owes you ${net.toStringAsFixed(0)} ETB'
                                      : 'You owe ${net.abs().toStringAsFixed(0)} ETB',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isNeutral
                                    ? AppColors.text
                                    : isPositive
                                        ? AppColors.income
                                        : AppColors.expense,
                              ),
                            ),
                          ),
                          if (friend.note != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              friend.note!,
                              style: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Add Entry Form Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        children: [
                          if (!_showForm)
                            GestureDetector(
                              onTap: () => setState(() => _showForm = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurface : Colors.white,
                                  border: Border.all(color: AppColors.primary.withOpacity(0.3), style: BorderStyle.solid),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_circle_outline, color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Add Loan Entry',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurface : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderLight),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('New Entry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 16),
                                  // Direction toggle buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(() => _direction = LoanDirection.lent),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            decoration: BoxDecoration(
                                              color: _direction == LoanDirection.lent
                                                  ? AppColors.income.withOpacity(0.12)
                                                  : AppColors.surfaceSecondary,
                                              border: Border.all(
                                                color: _direction == LoanDirection.lent ? AppColors.income : Colors.transparent,
                                                width: 1.5,
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.arrow_upward, size: 16, color: _direction == LoanDirection.lent ? AppColors.income : AppColors.textTertiary),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'I lent them',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: _direction == LoanDirection.lent ? AppColors.income : AppColors.textSecondary,
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
                                          onTap: () => setState(() => _direction = LoanDirection.borrowed),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            decoration: BoxDecoration(
                                              color: _direction == LoanDirection.borrowed
                                                  ? AppColors.expense.withOpacity(0.12)
                                                  : AppColors.surfaceSecondary,
                                              border: Border.all(
                                                color: _direction == LoanDirection.borrowed ? AppColors.expense : Colors.transparent,
                                                width: 1.5,
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.arrow_downward, size: 16, color: _direction == LoanDirection.borrowed ? AppColors.expense : AppColors.textTertiary),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'I borrowed',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: _direction == LoanDirection.borrowed ? AppColors.expense : AppColors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Amount Row
                                  Row(
                                    children: [
                                      const Text('ETB', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: _amountController,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          decoration: const InputDecoration(hintText: '0.00'),
                                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Reason input
                                  TextField(
                                    controller: _reasonController,
                                    decoration: const InputDecoration(hintText: 'Reason / note (optional)'),
                                  ),
                                  const SizedBox(height: 16),

                                  // Action Buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.surfaceSecondary, foregroundColor: AppColors.textSecondary),
                                          onPressed: () {
                                            setState(() {
                                              _showForm = false;
                                              _amountController.clear();
                                              _reasonController.clear();
                                            });
                                          },
                                          child: const Text('Cancel'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: _saving ? null : () => _handleAddEntry(friend),
                                          child: Text(_saving ? 'Adding...' : 'Add'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    // History Section
                    Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20.0, top: 24.0, bottom: 12.0),
                      child: Text(
                        'History (${friendTxns.length})',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.text),
                      ),
                    ),

                    if (friendTxns.isEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32.0),
                        child: Column(
                          children: [
                            const Icon(Icons.swap_horiz, size: 36, color: AppColors.textTertiary),
                            const SizedBox(height: 8),
                            const Text('No entries yet', style: TextStyle(color: AppColors.textSecondary)),
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
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: friendTxns.length,
                            itemBuilder: (context, index) {
                              final txn = friendTxns[index];
                              final isLent = txn.direction == LoanDirection.lent;
                              final dateStr = DateFormat('MMM d, yyyy').format(DateTime.parse(txn.date));

                              return InkWell(
                                onLongPress: () => _confirmDeleteEntry(context, txn),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                  decoration: BoxDecoration(
                                    border: index < friendTxns.length - 1
                                        ? Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.borderLight))
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: isLent ? AppColors.income.withOpacity(0.12) : AppColors.expense.withOpacity(0.12),
                                        child: Icon(
                                          isLent ? Icons.arrow_upward : Icons.arrow_downward,
                                          size: 16,
                                          color: isLent ? AppColors.income : AppColors.expense,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              isLent ? 'You lent' : 'You borrowed',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            if (txn.reason != null) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                txn.reason!,
                                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                            const SizedBox(height: 2),
                                            Text(
                                              dateStr,
                                              style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${isLent ? "+" : "-"}${txn.amount.toStringAsFixed(0)} ETB',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: isLent ? AppColors.income : AppColors.expense,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
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
