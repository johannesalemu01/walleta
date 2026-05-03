import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/models/transaction.dart';
import '../data/models/bank.dart';

class BankAccountCard extends StatelessWidget {
  final BankAccount account;

  const BankAccountCard({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    final bankInfo = getBankById(account.bankId);
    final bankColor = bankInfo?.color ?? const Color(0xFF6B3FA0);
    final bankShortName = bankInfo?.shortName ?? 'Bank';

    return GestureDetector(
      onTap: () => context.push('/bank-detail/${account.id}'),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bankColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: bankColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    bankShortName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (bankInfo?.logoAsset != null)
                  Image.asset(
                    bankInfo!.logoAsset!,
                    height: 24,
                    width: 24,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Text(
                        bankInfo.iconLetter,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  )
                else
                  Text(
                    bankInfo?.iconLetter ?? 'B',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.accountName,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${account.balance.toStringAsFixed(2)} ETB',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
