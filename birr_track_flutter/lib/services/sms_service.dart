import 'dart:io';
import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';
import '../data/models/transaction.dart';
import '../data/models/bank.dart';
import '../data/storage/storage_service.dart';
import 'sms_parser.dart';

class SyncResult {
  final bool added;
  final String? transactionId;
  final String? feeTransactionId;
  final bool skippedDuplicate;

  SyncResult({
    required this.added,
    this.transactionId,
    this.feeTransactionId,
    this.skippedDuplicate = false,
  });
}

class SmsService {
  final StorageService _storage;
  
  SmsService(this._storage);

  static const String _smsCategoryId = "other";

  String _generateId() => DateTime.now().millisecondsSinceEpoch.toString() + '_' + (1000 + DateTime.now().microsecond).toString();

  Future<SyncResult> syncTransactionFromSms(
    ParsedBankSms parsed,
    String? bankAccountId, {
    bool skipBalanceUpdate = false,
  }) async {
    final smsHashes = _storage.getSmsHashes();
    if (smsHashes.contains(parsed.smsId)) {
      return SyncResult(added: false, skippedDuplicate: true);
    }

    final bankName = banks.firstWhere(
      (b) => b.id == parsed.bankId, 
      orElse: () => BankInfo(
        id: parsed.bankId,
        name: parsed.bankId,
        shortName: parsed.bankId,
        color: const Color(0xFF000000),
        iconLetter: parsed.bankId.isNotEmpty ? parsed.bankId[0].toUpperCase() : 'B',
      )
    ).name;

    final mainTxn = Transaction(
      id: _generateId(),
      amount: parsed.amount,
      type: parsed.direction == 'credit' ? TransactionType.income : TransactionType.expense,
      categoryId: _smsCategoryId,
      description: parsed.description ?? (parsed.direction == 'credit' ? 'SMS: Credit' : 'SMS: Debit'),
      date: parsed.timestamp,
      paymentMethod: bankAccountId != null ? PaymentMethod.bank.name : PaymentMethod.cash.name,
      bankAccountId: bankAccountId,
      createdAt: DateTime.now().toIso8601String(),
      metadata: TransactionMetadata(
        smsId: parsed.smsId,
        bankName: bankName,
        smsRawText: parsed.rawText,
        accountMask: parsed.accountMask,
        refNo: parsed.refNo,
      ),
    );

    await _storage.saveTransaction(mainTxn);

    String? feeTransactionId;
    if (parsed.fees != null && parsed.fees! > 0) {
      final feeTxn = Transaction(
        id: _generateId(),
        amount: parsed.fees!,
        type: TransactionType.expense,
        categoryId: 'bills',
        description: 'Service charge + VAT ($bankName)',
        date: parsed.timestamp,
        paymentMethod: bankAccountId != null ? PaymentMethod.bank.name : PaymentMethod.cash.name,
        bankAccountId: bankAccountId,
        createdAt: DateTime.now().toIso8601String(),
        metadata: TransactionMetadata(
          smsId: '${parsed.smsId}_fee',
          bankName: bankName,
          isFee: true,
          refNo: parsed.refNo,
        ),
      );
      await _storage.saveTransaction(feeTxn);
      feeTransactionId = feeTxn.id;
    }

    if (!skipBalanceUpdate && bankAccountId != null && parsed.newBalance != null) {
      final accounts = _storage.getBankAccounts();
      final idx = accounts.indexWhere((a) => a.id == bankAccountId);
      if (idx >= 0) {
        final acc = accounts[idx];
        await _storage.saveBankAccount(acc.copyWith(
          balance: parsed.newBalance!,
          lastUpdated: DateTime.now().toIso8601String(),
        ));
      }
    }

    await _storage.addSmsHash(parsed.smsId);
    if (parsed.fees != null && parsed.fees! > 0) {
      await _storage.addSmsHash('${parsed.smsId}_fee');
    }

    return SyncResult(
      added: true,
      transactionId: mainTxn.id,
      feeTransactionId: feeTransactionId,
    );
  }

  String? findBankAccountForParsed(List<BankAccount> bankAccounts, String bankId) {
    for (final account in bankAccounts) {
      if (account.bankId == bankId) {
        return account.id;
      }
    }
    return null;
  }

  Future<Map<String, dynamic>> syncBatchFromSms(List<ParsedBankSms> parsedMessages, String? bankAccountId) async {
    int imported = 0;
    int skipped = 0;
    double? latestBalance;

    final sorted = List<ParsedBankSms>.from(parsedMessages);
    sorted.sort((a, b) => DateTime.parse(a.timestamp).compareTo(DateTime.parse(b.timestamp)));

    for (final parsed in sorted) {
      final result = await syncTransactionFromSms(parsed, bankAccountId, skipBalanceUpdate: true);
      if (result.added) {
        imported++;
      } else {
        skipped++;
      }
      if (parsed.newBalance != null) {
        latestBalance = parsed.newBalance;
      }
    }

    if (bankAccountId != null && latestBalance != null) {
      final accounts = _storage.getBankAccounts();
      final idx = accounts.indexWhere((a) => a.id == bankAccountId);
      if (idx >= 0) {
        final acc = accounts[idx];
        await _storage.saveBankAccount(acc.copyWith(
          balance: latestBalance!,
          lastUpdated: DateTime.now().toIso8601String(),
        ));
      }
    }

    return {
      'imported': imported,
      'skipped': skipped,
      'newBalance': latestBalance,
    };
  }

  Future<void> importSmsFromInbox(String bankId, String? bankAccountId) async {
    if (!Platform.isAndroid) return;

    final telephony = Telephony.instance;
    bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;

    if (permissionsGranted != true) return;

    List<SmsMessage> messages = await telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE, SmsColumn.ID],
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.ASC)],
    );

    List<ParsedBankSms> parsedList = [];
    for (final msg in messages) {
      if (msg.body == null || msg.date == null || msg.address == null) continue;
      
      final bSms = BankSmsMessage(
        sender: msg.address!,
        body: msg.body!,
        date: msg.date!,
        id: msg.id?.toString() ?? '',
      );

      final parsed = parseBankSms(bankId, bSms);
      if (parsed != null) {
        parsedList.add(parsed);
      }
    }

    await syncBatchFromSms(parsedList, bankAccountId);
  }

  Future<void> autoDetectAndImportAllSms() async {
    if (!Platform.isAndroid) return;

    final telephony = Telephony.instance;
    bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;

    if (permissionsGranted != true) return;

    List<SmsMessage> messages = await telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE, SmsColumn.ID],
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.ASC)],
    );

    final bankAccounts = _storage.getBankAccounts();
    
    Map<String, List<ParsedBankSms>> groupedParsed = {};

    for (final msg in messages) {
      if (msg.body == null || msg.date == null || msg.address == null) continue;

      final bSms = BankSmsMessage(
        sender: msg.address!,
        body: msg.body!,
        date: msg.date!,
        id: msg.id?.toString() ?? '',
      );

      final parsed = parseSmsAutoDetect(bSms);
      if (parsed != null) {
        groupedParsed.putIfAbsent(parsed.bankId, () => []).add(parsed);
      }
    }

    for (final entry in groupedParsed.entries) {
      final bankId = entry.key;
      final parsedList = entry.value;
      
      String? bankAccountId = findBankAccountForParsed(bankAccounts, bankId);
      await syncBatchFromSms(parsedList, bankAccountId);
    }
  }
}
