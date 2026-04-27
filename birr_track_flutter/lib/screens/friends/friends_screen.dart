import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_provider.dart';
import '../../data/models/transaction.dart';
import '../../core/colors.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sortedFriends = List<Friend>.from(provider.friends);
    sortedFriends.sort((a, b) {
      final netA = provider.getFriendNet(a.id).abs();
      final netB = provider.getFriendNet(b.id).abs();
      return netB.compareTo(netA);
    });

    final fNet = provider.friendsNet;

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
                    'Friends',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 28, color: AppColors.primary),
                    onPressed: () => context.push('/add-friend'),
                  ),
                ],
              ),
            ),

            // Main scroll area
            Expanded(
              child: RefreshIndicator(
                onRefresh: provider.refreshData,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                label: 'Owed to you',
                                value: '${fNet.totalLent.toStringAsFixed(0)} ETB',
                                valueColor: AppColors.income,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryCard(
                                label: 'You owe',
                                value: '${fNet.totalBorrowed.toStringAsFixed(0)} ETB',
                                valueColor: AppColors.expense,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Net Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: fNet.netWithFriends != 0
                                ? (fNet.netWithFriends > 0 ? AppColors.income : AppColors.expense).withOpacity(0.08)
                                : (isDark ? AppColors.darkSurface : Colors.white),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: fNet.netWithFriends != 0
                                  ? (fNet.netWithFriends > 0 ? AppColors.income : AppColors.expense).withOpacity(0.15)
                                  : (isDark ? AppColors.darkBorder : AppColors.borderLight),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Net with friends',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${fNet.netWithFriends >= 0 ? "+" : ""}${fNet.netWithFriends.toStringAsFixed(0)} ETB',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: fNet.netWithFriends > 0
                                      ? AppColors.income
                                      : fNet.netWithFriends < 0
                                          ? AppColors.expense
                                          : AppColors.text,
                                ),
                              ),
                              if (fNet.netWithFriends != 0) ...[
                                const SizedBox(height: 4),
                                Text(
                                  fNet.netWithFriends > 0 ? 'Friends owe you overall' : 'You owe friends overall',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Friends List Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              provider.friends.isNotEmpty ? 'All Friends (${provider.friends.length})' : 'No friends yet',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (sortedFriends.isEmpty) ...[
                              GestureDetector(
                                onTap: () => context.push('/add-friend'),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 48.0),
                                    child: Column(
                                      children: [
                                        const Icon(Icons.people_outline, size: 48, color: AppColors.textTertiary),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Track loans & debts',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Add a friend to start tracking money lent or borrowed',
                                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
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
                                  itemCount: sortedFriends.length,
                                  separatorBuilder: (context, index) => Divider(
                                    color: isDark ? AppColors.darkBorder : AppColors.borderLight,
                                    height: 1,
                                  ),
                                  itemBuilder: (context, index) {
                                    final friend = sortedFriends[index];
                                    final net = provider.getFriendNet(friend.id);
                                    final isPositive = net > 0;
                                    final isNeutral = net == 0;

                                    return InkWell(
                                      onTap: () => context.push('/friend-detail/${friend.id}'),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                        child: Row(
                                          children: [
                                            // Avatar
                                            if (friend.photoUri != null && friend.photoUri!.isNotEmpty)
                                              CircleAvatar(
                                                radius: 22,
                                                backgroundImage: FileImage(File(friend.photoUri!)),
                                              )
                                            else
                                              CircleAvatar(
                                                radius: 22,
                                                backgroundColor: isNeutral
                                                    ? AppColors.textTertiary.withOpacity(0.12)
                                                    : isPositive
                                                        ? AppColors.income.withOpacity(0.12)
                                                        : AppColors.expense.withOpacity(0.12),
                                                child: Text(
                                                  friend.name.isNotEmpty ? friend.name[0].toUpperCase() : 'F',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: isNeutral
                                                        ? AppColors.textSecondary
                                                        : isPositive
                                                            ? AppColors.income
                                                            : AppColors.expense,
                                                  ),
                                                ),
                                              ),
                                            const SizedBox(width: 12),
                                            // Name and Details
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    friend.name,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.text,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    isNeutral
                                                        ? 'Settled up'
                                                        : isPositive
                                                            ? 'Owes you ${net.toStringAsFixed(0)} ETB'
                                                            : 'You owe ${net.abs().toStringAsFixed(0)} ETB',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors.textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Amount
                                            Text(
                                              isNeutral ? '—' : '${isPositive ? "+" : "-"}${net.abs().toStringAsFixed(0)} ETB',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: isNeutral
                                                    ? AppColors.textTertiary
                                                    : isPositive
                                                        ? AppColors.income
                                                        : AppColors.expense,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-friend'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.person_add_alt_outlined, color: Colors.white),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required Color valueColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: valueColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: valueColor.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
