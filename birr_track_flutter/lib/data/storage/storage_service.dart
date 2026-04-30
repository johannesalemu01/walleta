import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';

class StorageService {
  static const _transactionsKey = 'transactions';
  static const _bankAccountsKey = 'bankAccounts';
  static const _budgetsKey = 'budgets';
  static const _friendsKey = 'friends';
  static const _friendTransactionsKey = 'friendTransactions';
  static const _cashBalanceKey = 'cashBalance';
  static const _smsHashesKey = 'smsHashes';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // ─── Transactions ───────────────────────────────────────────────────────────

  List<Transaction> getTransactions() {
    final raw = _prefs.getString(_transactionsKey);
    if (raw == null) return [];
    final List<dynamic> list = jsonDecode(raw);
    final txns = list.map((e) => Transaction.fromJson(e)).toList();
    txns.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return txns;
  }

  Future<void> saveTransaction(Transaction txn) async {
    final txns = getTransactions();
    final idx = txns.indexWhere((t) => t.id == txn.id);
    if (idx >= 0) {
      txns[idx] = txn;
    } else {
      txns.insert(0, txn);
    }
    await _prefs.setString(_transactionsKey, jsonEncode(txns.map((t) => t.toJson()).toList()));
  }

  Future<void> saveTransactions(List<Transaction> txns) async {
    await _prefs.setString(_transactionsKey, jsonEncode(txns.map((t) => t.toJson()).toList()));
  }

  Future<void> deleteTransaction(String id) async {
    final txns = getTransactions()..removeWhere((t) => t.id == id);
    await _prefs.setString(_transactionsKey, jsonEncode(txns.map((t) => t.toJson()).toList()));
  }

  // ─── Bank Accounts ───────────────────────────────────────────────────────────

  List<BankAccount> getBankAccounts() {
    final raw = _prefs.getString(_bankAccountsKey);
    if (raw == null) return [];
    final List<dynamic> list = jsonDecode(raw);
    return list.map((e) => BankAccount.fromJson(e)).toList();
  }

  Future<void> saveBankAccount(BankAccount account) async {
    final accounts = getBankAccounts();
    final idx = accounts.indexWhere((a) => a.id == account.id);
    if (idx >= 0) {
      accounts[idx] = account;
    } else {
      accounts.add(account);
    }
    await _prefs.setString(_bankAccountsKey, jsonEncode(accounts.map((a) => a.toJson()).toList()));
  }

  Future<void> deleteBankAccount(String id) async {
    final accounts = getBankAccounts()..removeWhere((a) => a.id == id);
    await _prefs.setString(_bankAccountsKey, jsonEncode(accounts.map((a) => a.toJson()).toList()));
  }

  // ─── Budgets ─────────────────────────────────────────────────────────────────

  List<Budget> getBudgets() {
    final raw = _prefs.getString(_budgetsKey);
    if (raw == null) return [];
    final List<dynamic> list = jsonDecode(raw);
    return list.map((e) => Budget.fromJson(e)).toList();
  }

  Future<void> saveBudget(Budget budget) async {
    final budgets = getBudgets();
    final idx = budgets.indexWhere((b) => b.id == budget.id);
    if (idx >= 0) {
      budgets[idx] = budget;
    } else {
      budgets.add(budget);
    }
    await _prefs.setString(_budgetsKey, jsonEncode(budgets.map((b) => b.toJson()).toList()));
  }

  Future<void> deleteBudget(String id) async {
    final budgets = getBudgets()..removeWhere((b) => b.id == id);
    await _prefs.setString(_budgetsKey, jsonEncode(budgets.map((b) => b.toJson()).toList()));
  }

  // ─── Friends ─────────────────────────────────────────────────────────────────

  List<Friend> getFriends() {
    final raw = _prefs.getString(_friendsKey);
    if (raw == null) return [];
    final List<dynamic> list = jsonDecode(raw);
    return list.map((e) => Friend.fromJson(e)).toList();
  }

  Future<void> saveFriend(Friend friend) async {
    final friends = getFriends();
    final idx = friends.indexWhere((f) => f.id == friend.id);
    if (idx >= 0) {
      friends[idx] = friend;
    } else {
      friends.add(friend);
    }
    await _prefs.setString(_friendsKey, jsonEncode(friends.map((f) => f.toJson()).toList()));
  }

  Future<void> deleteFriend(String id) async {
    final friends = getFriends()..removeWhere((f) => f.id == id);
    await _prefs.setString(_friendsKey, jsonEncode(friends.map((f) => f.toJson()).toList()));
    // Also remove friend's transactions
    final ftxns = getFriendTransactions()..removeWhere((ft) => ft.friendId == id);
    await _prefs.setString(_friendTransactionsKey, jsonEncode(ftxns.map((ft) => ft.toJson()).toList()));
  }

  // ─── Friend Transactions ─────────────────────────────────────────────────────

  List<FriendTransaction> getFriendTransactions() {
    final raw = _prefs.getString(_friendTransactionsKey);
    if (raw == null) return [];
    final List<dynamic> list = jsonDecode(raw);
    return list.map((e) => FriendTransaction.fromJson(e)).toList();
  }

  Future<void> saveFriendTransaction(FriendTransaction ft) async {
    final ftxns = getFriendTransactions();
    final idx = ftxns.indexWhere((t) => t.id == ft.id);
    if (idx >= 0) {
      ftxns[idx] = ft;
    } else {
      ftxns.add(ft);
    }
    await _prefs.setString(_friendTransactionsKey, jsonEncode(ftxns.map((t) => t.toJson()).toList()));
  }

  Future<void> deleteFriendTransaction(String id) async {
    final ftxns = getFriendTransactions()..removeWhere((t) => t.id == id);
    await _prefs.setString(_friendTransactionsKey, jsonEncode(ftxns.map((t) => t.toJson()).toList()));
  }

  // ─── Cash Balance ─────────────────────────────────────────────────────────────

  double getCashBalance() => _prefs.getDouble(_cashBalanceKey) ?? 0.0;

  Future<void> saveCashBalance(double amount) async {
    await _prefs.setDouble(_cashBalanceKey, amount);
  }

  // ─── SMS Deduplication Hashes ─────────────────────────────────────────────────

  Set<String> getSmsHashes() {
    final raw = _prefs.getStringList(_smsHashesKey);
    return raw?.toSet() ?? {};
  }

  Future<void> addSmsHash(String hash) async {
    final hashes = getSmsHashes()..add(hash);
    await _prefs.setStringList(_smsHashesKey, hashes.toList());
  }

  // ─── Clear All ────────────────────────────────────────────────────────────────

  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
