import 'dart:convert';
import 'package:crypto/crypto.dart';

class ParsedBankSms {
  String bankId;
  String direction; // 'credit' | 'debit'
  double amount;
  double? fees;
  String timestamp;
  String? accountMask;
  double? newBalance;
  String? description;
  String smsId;
  String rawText;
  String? refNo;

  ParsedBankSms({
    required this.bankId,
    required this.direction,
    required this.amount,
    this.fees,
    required this.timestamp,
    this.accountMask,
    this.newBalance,
    this.description,
    required this.smsId,
    required this.rawText,
    this.refNo,
  });
}

class BankSmsMessage {
  final String sender;
  final String body;
  final int date; // milliseconds since epoch
  final String id;

  BankSmsMessage({
    required this.sender,
    required this.body,
    required this.date,
    this.id = '',
  });
}

double _num(String str) {
  final cleaned = str.replaceAll(',', '').trim();
  final n = double.tryParse(cleaned);
  return n ?? 0.0;
}

String _extractDate(String text, int fallbackMs) {
  final iso = RegExp(r'(\d{4})-(\d{2})-(\d{2})\s+(\d{2}:\d{2}:\d{2})').firstMatch(text);
  if (iso != null) {
    return '${iso.group(1)}-${iso.group(2)}-${iso.group(3)}';
  }
  final ddmmyyyy = RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})\s+(\d{2}:\d{2}:\d{2})').firstMatch(text);
  if (ddmmyyyy != null) {
    return '${ddmmyyyy.group(3)}-${ddmmyyyy.group(2)!.padLeft(2, '0')}-${ddmmyyyy.group(1)!.padLeft(2, '0')}';
  }
  final ddmmyyyy2 = RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})').firstMatch(text);
  if (ddmmyyyy2 != null) {
    return '${ddmmyyyy2.group(3)}-${ddmmyyyy2.group(2)!.padLeft(2, '0')}-${ddmmyyyy2.group(1)!.padLeft(2, '0')}';
  }
  return DateTime.fromMillisecondsSinceEpoch(fallbackMs).toIso8601String().split('T')[0];
}

double? _extractBalance(String text) {
  final m = RegExp(r'(?:current\s+)?balance\s+(?:is\s+)?ETB\s*([\d,]+\.?\d*)', caseSensitive: false).firstMatch(text);
  if (m != null) return _num(m.group(1)!);
  final m2 = RegExp(r'available\s+balance:\s+ETB\s*([\d,]+\.?\d*)', caseSensitive: false).firstMatch(text);
  if (m2 != null) return _num(m2.group(1)!);
  return null;
}

String? _extractAccountMask(String text) {
  final m = RegExp(r'account\s+(\d\*+\d+)', caseSensitive: false).firstMatch(text);
  if (m != null) return m.group(1);
  return null;
}

String? _extractRefNo(String text) {
  final m = RegExp(r'ref\s*no\s+([A-Z0-9]+)', caseSensitive: false).firstMatch(text);
  if (m != null) return m.group(1);
  final m2 = RegExp(r'transaction\s+number\s+(?:is\s+)?([A-Z0-9]+)', caseSensitive: false).firstMatch(text);
  if (m2 != null) return m2.group(1);
  final m3 = RegExp(r'\?id=([A-Z0-9]+)', caseSensitive: false).firstMatch(text);
  if (m3 != null) return m3.group(1);
  return null;
}

String generateSmsIdSync(String body, int date) {
  final trimmed = body.replaceAll(RegExp(r'\s+'), ' ').trim();
  final sliceLength = trimmed.length > 100 ? 100 : trimmed.length;
  final sliced = trimmed.substring(0, sliceLength);
  final bytes = utf8.encode('$sliced|$date');
  final digest = sha256.convert(bytes);
  return 'sms_${date}_${sliceLength}_${digest.toString().substring(0, 8)}';
}

ParsedBankSms? parseCbeSms(BankSmsMessage sms) {
  final body = sms.body;
  final date = sms.date;
  final id = sms.id.isNotEmpty ? sms.id : generateSmsIdSync(body, date);

  final accountMask = _extractAccountMask(body);
  final newBalance = _extractBalance(body);
  final refNo = _extractRefNo(body);
  final timestamp = _extractDate(body, date);

  final creditMatch = RegExp(r'(?:has been|been)\s+credited\s+with\s+ETB\s*([\d,]+\.?\d*)\s+from\s+(.+?)(?:,\s*on|\.\s)', caseSensitive: false).firstMatch(body);
  if (creditMatch != null) {
    return ParsedBankSms(
      bankId: 'cbe',
      direction: 'credit',
      amount: _num(creditMatch.group(1)!),
      timestamp: timestamp,
      accountMask: accountMask,
      newBalance: newBalance,
      description: 'From ${creditMatch.group(2)!.trim()}',
      smsId: id,
      rawText: body,
      refNo: refNo,
    );
  }

  final transferMatch = RegExp(r'(?:you have|have)\s+transfer(?:r?ed)\s+ETB\s*([\d,]+\.?\d*)\s+to\s+(.+?)\s+on\s+', caseSensitive: false).firstMatch(body);
  if (transferMatch != null) {
    final feeMatch = RegExp(r'S\.?\s*charge\s+of\s+ETB\s*([\d,]+\.?\d*)', caseSensitive: false).firstMatch(body);
    final vatMatch = RegExp(r'VAT.*?ETB\s*([\d,]+\.?\d*)', caseSensitive: false).firstMatch(body);
    final fee = (feeMatch != null ? _num(feeMatch.group(1)!) : 0.0) + (vatMatch != null ? _num(vatMatch.group(1)!) : 0.0);
    return ParsedBankSms(
      bankId: 'cbe',
      direction: 'debit',
      amount: _num(transferMatch.group(1)!),
      fees: fee > 0.0 ? fee : null,
      timestamp: timestamp,
      accountMask: accountMask,
      newBalance: newBalance,
      description: 'To ${transferMatch.group(2)!.trim()}',
      smsId: id,
      rawText: body,
      refNo: refNo,
    );
  }

  final debitMatch = RegExp(r'(?:has been|been)\s+debited\s+with\s+ETB\s*([\d,]+\.?\d*)', caseSensitive: false).firstMatch(body);
  if (debitMatch != null) {
    final scMatch = RegExp(r'service\s+charge\s+of\s+ETB\s*([\d,]+\.?\d*)', caseSensitive: false).firstMatch(body);
    final vatMatch2 = RegExp(r'VAT.*?ETB\s*([\d,]+\.?\d*)', caseSensitive: false).firstMatch(body);
    final fee = (scMatch != null ? _num(scMatch.group(1)!) : 0.0) + (vatMatch2 != null ? _num(vatMatch2.group(1)!) : 0.0);
    return ParsedBankSms(
      bankId: 'cbe',
      direction: 'debit',
      amount: _num(debitMatch.group(1)!),
      fees: fee > 0.0 ? fee : null,
      timestamp: timestamp,
      accountMask: accountMask,
      newBalance: newBalance,
      description: 'Debit',
      smsId: id,
      rawText: body,
      refNo: refNo,
    );
  }

  final genericCredit = RegExp(r'credited.*?ETB\s*([\d,]+\.?\d*)', caseSensitive: false).firstMatch(body);
  if (genericCredit != null) {
    return ParsedBankSms(
      bankId: 'cbe',
      direction: 'credit',
      amount: _num(genericCredit.group(1)!),
      timestamp: timestamp,
      accountMask: accountMask,
      newBalance: newBalance,
      description: 'Credit',
      smsId: id,
      rawText: body,
      refNo: refNo,
    );
  }

  return null;
}

ParsedBankSms? parseTelebirrSms(BankSmsMessage sms) {
  final body = sms.body;
  final date = sms.date;
  final id = sms.id.isNotEmpty ? sms.id : generateSmsIdSync(body, date);
  final timestamp = _extractDate(body, date);
  final refNo = _extractRefNo(body);

  final balMatch = RegExp(r'current\s+(?:telebirr\s+)?balance\s+is\s+ETB\s*([\d,]+\.?\d*)', caseSensitive: false).firstMatch(body);
  final newBalance = balMatch != null ? _num(balMatch.group(1)!) : null;

  final acctMatch = RegExp(r'telebirr\s+account\s+(\d+)', caseSensitive: false).firstMatch(body);
  final accountMask = acctMatch != null ? acctMatch.group(1) : null;

  final receivedMatch = RegExp(r'you have received\s+ETB\s*([\d,]+\.?\d*).*?from\s+(.+?)\s+to\s+your', caseSensitive: false).firstMatch(body);
  if (receivedMatch != null) {
    return ParsedBankSms(
      bankId: 'telebirr',
      direction: 'credit',
      amount: _num(receivedMatch.group(1)!),
      timestamp: timestamp,
      accountMask: accountMask,
      newBalance: newBalance,
      description: 'From ${receivedMatch.group(2)!.trim()}',
      smsId: id,
      rawText: body,
      refNo: refNo,
    );
  }

  final packageMatch = RegExp(r'you have paid\s+ETB\s*([\d,]+\.?\d*)\s+for\s+package\s+(.+?)\s+(?:for|purchase)', caseSensitive: false).firstMatch(body);
  if (packageMatch != null) {
    return ParsedBankSms(
      bankId: 'telebirr',
      direction: 'debit',
      amount: _num(packageMatch.group(1)!),
      timestamp: timestamp,
      accountMask: accountMask,
      newBalance: newBalance,
      description: 'Package: ${packageMatch.group(2)!.trim()}',
      smsId: id,
      rawText: body,
      refNo: refNo,
    );
  }

  final paidMatch = RegExp(r'you have paid\s+ETB\s*([\d,]+\.?\d*)\s+to\s+(.+?)\s+with', caseSensitive: false).firstMatch(body);
  if (paidMatch != null) {
    final feeMatch = RegExp(r'service fee\s+is\s+ETB\s*([\d,]+\.?\d*)', caseSensitive: false).firstMatch(body);
    final vatMatch = RegExp(r'VAT.*?ETB\s*([\d,]+\.?\d*)', caseSensitive: false).firstMatch(body);
    final fee = (feeMatch != null ? _num(feeMatch.group(1)!) : 0.0) + (vatMatch != null ? _num(vatMatch.group(1)!) : 0.0);
    return ParsedBankSms(
      bankId: 'telebirr',
      direction: 'debit',
      amount: _num(paidMatch.group(1)!),
      fees: fee > 0.0 ? fee : null,
      timestamp: timestamp,
      accountMask: accountMask,
      newBalance: newBalance,
      description: 'To ${paidMatch.group(2)!.trim()}',
      smsId: id,
      rawText: body,
      refNo: refNo,
    );
  }

  final genericPaid = RegExp(r'you have paid\s+ETB\s*([\d,]+\.?\d*)', caseSensitive: false).firstMatch(body);
  if (genericPaid != null) {
    return ParsedBankSms(
      bankId: 'telebirr',
      direction: 'debit',
      amount: _num(genericPaid.group(1)!),
      timestamp: timestamp,
      accountMask: accountMask,
      newBalance: newBalance,
      description: 'Payment',
      smsId: id,
      rawText: body,
      refNo: refNo,
    );
  }

  return null;
}

ParsedBankSms? parseBoaSms(BankSmsMessage sms) {
  final body = sms.body;
  final date = sms.date;
  final id = sms.id.isNotEmpty ? sms.id : generateSmsIdSync(body, date);
  final timestamp = _extractDate(body, date);

  final balMatch = RegExp(r'available\s+balance:\s+ETB\s*([\d,]+\.?\d*)', caseSensitive: false).firstMatch(body);
  final newBalance = balMatch != null ? _num(balMatch.group(1)!) : null;

  final acctMatch = RegExp(r'account\s+(\d\*\d+)', caseSensitive: false).firstMatch(body);
  final accountMask = acctMatch != null ? acctMatch.group(1) : null;

  final receiptMatch = RegExp(r'receipt:\s*(https?:\/\/\S+)', caseSensitive: false).firstMatch(body);
  String? refNo;
  if (receiptMatch != null) {
    final split1 = receiptMatch.group(1)!.split('trx=');
    if (split1.length > 1) {
      refNo = split1[1].split(RegExp(r'[&\s]')).first;
    }
  }

  final creditMatch = RegExp(r'was\s+credited\s+with\s+ETB\s*([\d,]+\.?\d*)(?:\s+by\s+(.+?))?(?:\.\s|$)', caseSensitive: false).firstMatch(body);
  if (creditMatch != null) {
    return ParsedBankSms(
      bankId: 'boa',
      direction: 'credit',
      amount: _num(creditMatch.group(1)!),
      timestamp: timestamp,
      accountMask: accountMask,
      newBalance: newBalance,
      description: creditMatch.group(2) != null ? 'From ${creditMatch.group(2)!.trim()}' : 'Credit',
      smsId: id,
      rawText: body,
      refNo: refNo,
    );
  }

  final debitMatch = RegExp(r'was\s+debited\s+with\s+ETB\s*([\d,]+\.?\d*)', caseSensitive: false).firstMatch(body);
  if (debitMatch != null) {
    return ParsedBankSms(
      bankId: 'boa',
      direction: 'debit',
      amount: _num(debitMatch.group(1)!),
      timestamp: timestamp,
      accountMask: accountMask,
      newBalance: newBalance,
      description: 'Debit',
      smsId: id,
      rawText: body,
      refNo: refNo,
    );
  }

  return null;
}

ParsedBankSms? parseGenericSms(BankSmsMessage sms) {
  final body = sms.body;
  final date = sms.date;
  final id = sms.id.isNotEmpty ? sms.id : generateSmsIdSync(body, date);
  final timestamp = _extractDate(body, date);
  final accountMask = _extractAccountMask(body);
  final newBalance = _extractBalance(body);
  final refNo = _extractRefNo(body);

  final creditMatch = RegExp(r'(?:credited|received|deposited).*?ETB\s*([\d,]+\.?\d*)', caseSensitive: false).firstMatch(body);
  if (creditMatch != null) {
    final fromMatch = RegExp(r'(?:from|by)\s+(.+?)(?:\.|,|on\s)', caseSensitive: false).firstMatch(body);
    return ParsedBankSms(
      bankId: 'unknown',
      direction: 'credit',
      amount: _num(creditMatch.group(1)!),
      timestamp: timestamp,
      accountMask: accountMask,
      newBalance: newBalance,
      description: fromMatch != null ? 'From ${fromMatch.group(1)!.trim()}' : 'Credit',
      smsId: id,
      rawText: body,
      refNo: refNo,
    );
  }

  final debitMatch = RegExp(r'(?:debited|transferred|paid|withdrawn).*?ETB\s*([\d,]+\.?\d*)', caseSensitive: false).firstMatch(body);
  if (debitMatch != null) {
    final toMatch = RegExp(r'to\s+(.+?)(?:\.|,|on\s)', caseSensitive: false).firstMatch(body);
    return ParsedBankSms(
      bankId: 'unknown',
      direction: 'debit',
      amount: _num(debitMatch.group(1)!),
      timestamp: timestamp,
      accountMask: accountMask,
      newBalance: newBalance,
      description: toMatch != null ? 'To ${toMatch.group(1)!.trim()}' : 'Debit',
      smsId: id,
      rawText: body,
      refNo: refNo,
    );
  }

  return null;
}

final Map<String, ParsedBankSms? Function(BankSmsMessage)> bankSmsParsers = {
  'cbe': parseCbeSms,
  'telebirr': parseTelebirrSms,
  'boa': parseBoaSms,
  'awash': parseGenericSms,
  'dashen': parseGenericSms,
  'abay': parseGenericSms,
  'coop': parseGenericSms,
  'nib': parseGenericSms,
  'wegagen': parseGenericSms,
  'united': parseGenericSms,
  'bunna': parseGenericSms,
  'mpesa': parseGenericSms,
  'enat': parseGenericSms,
};

ParsedBankSms? parseBankSms(String bankId, BankSmsMessage sms) {
  final parser = bankSmsParsers[bankId];
  if (parser != null) {
    final result = parser(sms);
    if (result != null) {
      if (result.bankId == 'unknown') result.bankId = bankId;
      return result;
    }
  }

  final result = parseGenericSms(sms);
  if (result != null) {
    result.bankId = bankId;
    return result;
  }
  return null;
}

ParsedBankSms? parseSmsAutoDetect(BankSmsMessage sms) {
  final upper = sms.body.toUpperCase();

  if (upper.contains('CBE') || upper.contains('COMMERCIAL BANK') || RegExp(r'Dear\s+\w+\s+your\s+Account\s+\d\*+\d+', caseSensitive: false).hasMatch(sms.body)) {
    final result = parseCbeSms(sms);
    if (result != null) return result;
  }
  if (upper.contains('TELEBIRR') || upper.contains('ETHIO TELECOM') || upper.contains('ETHIO_TELECOM')) {
    final result = parseTelebirrSms(sms);
    if (result != null) return result;
  }
  if (upper.contains('ABYSSINIA') || upper.contains('BOA')) {
    final result = parseBoaSms(sms);
    if (result != null) return result;
  }

  for (final parser in bankSmsParsers.values) {
    final result = parser(sms);
    if (result != null) return result;
  }

  return parseGenericSms(sms);
}
