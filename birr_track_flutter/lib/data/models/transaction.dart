enum TransactionType { income, expense }

enum TransactionSource { manual, bankSms, loan }

enum PaymentMethod { cash, bank }

class TransactionMetadata {
  final String? smsId;
  final String? bankName;
  final String? smsRawText;
  final String? accountMask;
  final bool? isFee;
  final String? refNo;

  const TransactionMetadata({
    this.smsId,
    this.bankName,
    this.smsRawText,
    this.accountMask,
    this.isFee,
    this.refNo,
  });

  factory TransactionMetadata.fromJson(Map<String, dynamic> json) {
    return TransactionMetadata(
      smsId: json['smsId'],
      bankName: json['bankName'],
      smsRawText: json['smsRawText'],
      accountMask: json['accountMask'],
      isFee: json['isFee'],
      refNo: json['refNo'],
    );
  }

  Map<String, dynamic> toJson() => {
        if (smsId != null) 'smsId': smsId,
        if (bankName != null) 'bankName': bankName,
        if (smsRawText != null) 'smsRawText': smsRawText,
        if (accountMask != null) 'accountMask': accountMask,
        if (isFee != null) 'isFee': isFee,
        if (refNo != null) 'refNo': refNo,
      };
}

class Transaction {
  final String id;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String description;
  final String date; // YYYY-MM-DD
  final String paymentMethod;
  final String? bankAccountId;
  final String createdAt;
  final TransactionSource source;
  final TransactionMetadata? metadata;

  const Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.description,
    required this.date,
    required this.paymentMethod,
    this.bankAccountId,
    required this.createdAt,
    this.source = TransactionSource.manual,
    this.metadata,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] == 'income' ? TransactionType.income : TransactionType.expense,
      categoryId: json['categoryId'],
      description: json['description'] ?? '',
      date: json['date'],
      paymentMethod: json['paymentMethod'] ?? 'cash',
      bankAccountId: json['bankAccountId'],
      createdAt: json['createdAt'],
      source: _parseSource(json['source']),
      metadata: json['metadata'] != null ? TransactionMetadata.fromJson(json['metadata']) : null,
    );
  }

  static TransactionSource _parseSource(String? s) {
    switch (s) {
      case 'bank_sms': return TransactionSource.bankSms;
      case 'loan': return TransactionSource.loan;
      default: return TransactionSource.manual;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'type': type == TransactionType.income ? 'income' : 'expense',
        'categoryId': categoryId,
        'description': description,
        'date': date,
        'paymentMethod': paymentMethod,
        if (bankAccountId != null) 'bankAccountId': bankAccountId,
        'createdAt': createdAt,
        'source': source == TransactionSource.bankSms ? 'bank_sms' : source == TransactionSource.loan ? 'loan' : 'manual',
        if (metadata != null) 'metadata': metadata!.toJson(),
      };

  Transaction copyWith({
    String? id,
    double? amount,
    TransactionType? type,
    String? categoryId,
    String? description,
    String? date,
    String? paymentMethod,
    String? bankAccountId,
    String? createdAt,
    TransactionSource? source,
    TransactionMetadata? metadata,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      bankAccountId: bankAccountId ?? this.bankAccountId,
      createdAt: createdAt ?? this.createdAt,
      source: source ?? this.source,
      metadata: metadata ?? this.metadata,
    );
  }
}

class BankAccount {
  final String id;
  final String bankId;
  final String accountName;
  final double balance;
  final String lastUpdated;
  final bool smsSyncEnabled;
  final String? lastSmsSyncAt;

  const BankAccount({
    required this.id,
    required this.bankId,
    required this.accountName,
    required this.balance,
    required this.lastUpdated,
    this.smsSyncEnabled = false,
    this.lastSmsSyncAt,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'],
      bankId: json['bankId'],
      accountName: json['accountName'],
      balance: (json['balance'] as num).toDouble(),
      lastUpdated: json['lastUpdated'],
      smsSyncEnabled: json['smsSyncEnabled'] ?? false,
      lastSmsSyncAt: json['lastSmsSyncAt'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bankId': bankId,
        'accountName': accountName,
        'balance': balance,
        'lastUpdated': lastUpdated,
        'smsSyncEnabled': smsSyncEnabled,
        if (lastSmsSyncAt != null) 'lastSmsSyncAt': lastSmsSyncAt,
      };

  BankAccount copyWith({
    String? id,
    String? bankId,
    String? accountName,
    double? balance,
    String? lastUpdated,
    bool? smsSyncEnabled,
    String? lastSmsSyncAt,
  }) {
    return BankAccount(
      id: id ?? this.id,
      bankId: bankId ?? this.bankId,
      accountName: accountName ?? this.accountName,
      balance: balance ?? this.balance,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      smsSyncEnabled: smsSyncEnabled ?? this.smsSyncEnabled,
      lastSmsSyncAt: lastSmsSyncAt ?? this.lastSmsSyncAt,
    );
  }
}

enum BudgetPeriod { daily, weekly, monthly, yearly }

class Budget {
  final String id;
  final String? categoryId;
  final double amount;
  final BudgetPeriod period;
  final String createdAt;

  const Budget({
    required this.id,
    this.categoryId,
    required this.amount,
    required this.period,
    required this.createdAt,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      categoryId: json['categoryId'],
      amount: (json['amount'] as num).toDouble(),
      period: _parsePeriod(json['period']),
      createdAt: json['createdAt'],
    );
  }

  static BudgetPeriod _parsePeriod(String? s) {
    switch (s) {
      case 'daily': return BudgetPeriod.daily;
      case 'weekly': return BudgetPeriod.weekly;
      case 'yearly': return BudgetPeriod.yearly;
      default: return BudgetPeriod.monthly;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (categoryId != null) 'categoryId': categoryId,
        'amount': amount,
        'period': period.name,
        'createdAt': createdAt,
      };
}

class Friend {
  final String id;
  final String name;
  final String? phone;
  final String? note;
  final String? photoUri;
  final String createdAt;

  const Friend({
    required this.id,
    required this.name,
    this.phone,
    this.note,
    this.photoUri,
    required this.createdAt,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      note: json['note'],
      photoUri: json['photoUri'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (phone != null) 'phone': phone,
        if (note != null) 'note': note,
        if (photoUri != null) 'photoUri': photoUri,
        'createdAt': createdAt,
      };

  Friend copyWith({String? name, String? phone, String? note, String? photoUri}) {
    return Friend(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      note: note ?? this.note,
      photoUri: photoUri ?? this.photoUri,
      createdAt: createdAt,
    );
  }
}

enum LoanDirection { lent, borrowed }

class FriendTransaction {
  final String id;
  final String friendId;
  final LoanDirection direction;
  final double amount;
  final String? reason;
  final String date;
  final String createdAt;

  const FriendTransaction({
    required this.id,
    required this.friendId,
    required this.direction,
    required this.amount,
    this.reason,
    required this.date,
    required this.createdAt,
  });

  factory FriendTransaction.fromJson(Map<String, dynamic> json) {
    return FriendTransaction(
      id: json['id'],
      friendId: json['friendId'],
      direction: json['direction'] == 'lent' ? LoanDirection.lent : LoanDirection.borrowed,
      amount: (json['amount'] as num).toDouble(),
      reason: json['reason'],
      date: json['date'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'friendId': friendId,
        'direction': direction == LoanDirection.lent ? 'lent' : 'borrowed',
        'amount': amount,
        if (reason != null) 'reason': reason,
        'date': date,
        'createdAt': createdAt,
      };
}
