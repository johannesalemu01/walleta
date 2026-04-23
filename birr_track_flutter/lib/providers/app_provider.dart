import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/models/transaction.dart';
import '../data/models/category.dart';
import '../data/storage/storage_service.dart';

class FriendsNet {
  final double totalLent;
  final double totalBorrowed;
  final double netWithFriends;

  const FriendsNet({
    required this.totalLent,
    required this.totalBorrowed,
    required this.netWithFriends,
  });
}

class AppProvider extends ChangeNotifier {
  final StorageService _storage;
  final _uuid = const Uuid();

  List<Transaction> _transactions = [];
  List<BankAccount> _bankAccounts = [];
  List<Budget> _budgets = [];
  List<Friend> _friends = [];
  List<FriendTransaction> _friendTransactions = [];
  double _cashBalance = 0;
  bool _isLoading = false;

  AppProvider(this._storage) {
    _loadAll();
  }

  // ─── Getters ────────────────────────────────────────────────────────────────

  List<Transaction> get transactions => _transactions;
  List<BankAccount> get bankAccounts => _bankAccounts;
  List<Budget> get budgets => _budgets;
  List<Friend> get friends => _friends;
  List<FriendTransaction> get friendTransactions => _friendTransactions;
  List<Category> get categories => defaultCategories;
  double get cashBalance => _cashBalance;
  bool get isLoading => _isLoading;

  double get totalBalance {
    final bankTotal = _bankAccounts.fold(0.0, (sum, a) => sum + a.balance);
    return bankTotal + _cashBalance;
  }

  FriendsNet get friendsNet {
    double lent = 0;
    double borrowed = 0;
    for (final ft in _friendTransactions) {
      if (ft.direction == LoanDirection.lent) {
        lent += ft.amount;
      } else {
        borrowed += ft.amount;
      }
    }
    return FriendsNet(totalLent: lent, totalBorrowed: borrowed, netWithFriends: lent - borrowed);
  }

  double get overallNetBalance => totalBalance + friendsNet.netWithFriends;

  // ─── Monthly stats ────────────────────────────────────────────────────────────

  Map<String, double> get monthlyStats {
    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final monthTxns = _transactions.where((t) => t.date.startsWith(month));
    final income = monthTxns.where((t) => t.type == TransactionType.income).fold(0.0, (s, t) => s + t.amount);
    final expense = monthTxns.where((t) => t.type == TransactionType.expense).fold(0.0, (s, t) => s + t.amount);
    return {'income': income, 'expense': expense};
  }

  // ─── Load ─────────────────────────────────────────────────────────────────────

  Future<void> _loadAll() async {
    _isLoading = true;
    notifyListeners();
    _transactions = _storage.getTransactions();
    _bankAccounts = _storage.getBankAccounts();
    _budgets = _storage.getBudgets();
    _friends = _storage.getFriends();
    _friendTransactions = _storage.getFriendTransactions();
    _cashBalance = _storage.getCashBalance();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshData() => _loadAll();

  // ─── Transactions ─────────────────────────────────────────────────────────────

  Future<void> addTransaction(Transaction txn) async {
    await _storage.saveTransaction(txn);
    _transactions = _storage.getTransactions();

    // Update bank balance if linked
    if (txn.bankAccountId != null) {
      final accIdx = _bankAccounts.indexWhere((a) => a.id == txn.bankAccountId);
      if (accIdx >= 0) {
        final acc = _bankAccounts[accIdx];
        final delta = txn.type == TransactionType.income ? txn.amount : -txn.amount;
        final updated = acc.copyWith(
          balance: acc.balance + delta,
          lastUpdated: DateTime.now().toIso8601String(),
        );
        _bankAccounts[accIdx] = updated;
        await _storage.saveBankAccount(updated);
      }
    }
    notifyListeners();
  }

  Future<void> updateTransaction(Transaction txn) async {
    await _storage.saveTransaction(txn);
    _transactions = _storage.getTransactions();
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    await _storage.deleteTransaction(id);
    _transactions = _storage.getTransactions();
    notifyListeners();
  }

  // ─── Bank Accounts ────────────────────────────────────────────────────────────

  String generateId() => _uuid.v4();

  String getToday() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> addBankAccount(BankAccount account) async {
    await _storage.saveBankAccount(account);
    _bankAccounts = _storage.getBankAccounts();
    notifyListeners();
  }

  Future<void> updateBankAccount(BankAccount account) async {
    await _storage.saveBankAccount(account);
    _bankAccounts = _storage.getBankAccounts();
    notifyListeners();
  }

  Future<void> deleteBankAccount(String id) async {
    await _storage.deleteBankAccount(id);
    _bankAccounts = _storage.getBankAccounts();
    notifyListeners();
  }

  // ─── Budgets ──────────────────────────────────────────────────────────────────

  Future<void> addBudget(Budget budget) async {
    await _storage.saveBudget(budget);
    _budgets = _storage.getBudgets();
    notifyListeners();
  }

  Future<void> updateBudget(Budget budget) async {
    await _storage.saveBudget(budget);
    _budgets = _storage.getBudgets();
    notifyListeners();
  }

  Future<void> deleteBudget(String id) async {
    await _storage.deleteBudget(id);
    _budgets = _storage.getBudgets();
    notifyListeners();
  }

  // ─── Friends ──────────────────────────────────────────────────────────────────

  Future<void> addFriend(Friend friend) async {
    await _storage.saveFriend(friend);
    _friends = _storage.getFriends();
    notifyListeners();
  }

  Future<void> updateFriend(Friend friend) async {
    await _storage.saveFriend(friend);
    _friends = _storage.getFriends();
    notifyListeners();
  }

  Future<void> deleteFriend(String id) async {
    await _storage.deleteFriend(id);
    _friends = _storage.getFriends();
    _friendTransactions = _storage.getFriendTransactions();
    notifyListeners();
  }

  // ─── Friend Transactions ──────────────────────────────────────────────────────

  Future<void> addFriendTransaction(FriendTransaction ft) async {
    await _storage.saveFriendTransaction(ft);
    _friendTransactions = _storage.getFriendTransactions();
    notifyListeners();
  }

  Future<void> deleteFriendTransaction(String id) async {
    await _storage.deleteFriendTransaction(id);
    _friendTransactions = _storage.getFriendTransactions();
    notifyListeners();
  }

  // ─── Cash Balance ─────────────────────────────────────────────────────────────

  Future<void> setCashBalance(double amount) async {
    await _storage.saveCashBalance(amount);
    _cashBalance = amount;
    notifyListeners();
  }

  // ─── Clear All ────────────────────────────────────────────────────────────────

  Future<void> clearAll() async {
    await _storage.clearAll();
    await _loadAll();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────

  double getFriendNet(String friendId) {
    double net = 0;
    for (final ft in _friendTransactions.where((t) => t.friendId == friendId)) {
      net += ft.direction == LoanDirection.lent ? ft.amount : -ft.amount;
    }
    return net;
  }
}
