import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/home/home_screen.dart';
import '../screens/transactions/transactions_screen.dart';
import '../screens/analytics/analytics_screen.dart';
import '../screens/budget/budget_screen.dart';
import '../screens/friends/friends_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/add_transaction/add_transaction_screen.dart';
import '../screens/add_bank/add_bank_screen.dart';
import '../screens/bank_detail/bank_detail_screen.dart';
import '../screens/add_budget/add_budget_screen.dart';
import '../screens/add_friend/add_friend_screen.dart';
import '../screens/friend_detail/friend_detail_screen.dart';
import '../screens/about/about_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (c, s) => const HomeScreen()),
        GoRoute(path: '/transactions', builder: (c, s) => const TransactionsScreen()),
        GoRoute(path: '/analytics', builder: (c, s) => const AnalyticsScreen()),
        GoRoute(path: '/budget', builder: (c, s) => const BudgetScreen()),
        GoRoute(path: '/friends', builder: (c, s) => const FriendsScreen()),
        GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
      ],
    ),
    GoRoute(
      path: '/add-transaction',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (c, s) => AddTransactionScreen(
        transactionId: s.uri.queryParameters['id'],
      ),
    ),
    GoRoute(
      path: '/add-bank',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (c, s) => const AddBankScreen(),
    ),
    GoRoute(
      path: '/bank-detail/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (c, s) => BankDetailScreen(bankAccountId: s.pathParameters['id']!),
    ),
    GoRoute(
      path: '/add-budget',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (c, s) => AddBudgetScreen(budgetId: s.uri.queryParameters['id']),
    ),
    GoRoute(
      path: '/add-friend',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (c, s) => AddFriendScreen(friendId: s.uri.queryParameters['id']),
    ),
    GoRoute(
      path: '/friend-detail/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (c, s) => FriendDetailScreen(friendId: s.pathParameters['id']!),
    ),
    GoRoute(
      path: '/about',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (c, s) => const AboutScreen(),
    ),
  ],
);

class AppShell extends StatefulWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const _tabs = ['/', '/transactions', '/analytics', '/budget', '/friends', '/settings'];

  void _onTabTapped(BuildContext context, int index) {
    if (index != _selectedIndex) {
      setState(() => _selectedIndex = index);
      context.go(_tabs[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => _onTabTapped(context, i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Transactions'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Analytics'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Budget'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Friends'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
