import 'package:flutter/material.dart';

class BankInfo {
  final String id;
  final String name;
  final String shortName;
  final Color color;
  final String iconLetter;
  final String? logoAsset;

  const BankInfo({
    required this.id,
    required this.name,
    required this.shortName,
    required this.color,
    required this.iconLetter,
    this.logoAsset,
  });
}

const List<BankInfo> banks = [
  BankInfo(id: 'cbe', name: 'Commercial Bank of Ethiopia', shortName: 'CBE', color: Color(0xFF6B3FA0), iconLetter: 'C', logoAsset: 'assets/logos/CBE.png'),
  BankInfo(id: 'awash', name: 'Awash Bank', shortName: 'Awash', color: Color(0xFFE8532F), iconLetter: 'A', logoAsset: 'assets/logos/Awash.png'),
  BankInfo(id: 'dashen', name: 'Dashen Bank', shortName: 'Dashen', color: Color(0xFF0066CC), iconLetter: 'D', logoAsset: 'assets/logos/Dashen.png'),
  BankInfo(id: 'boa', name: 'Bank of Abyssinia', shortName: 'Abyssinia', color: Color(0xFFE8A817), iconLetter: 'B', logoAsset: 'assets/logos/BoA.png'),
  BankInfo(id: 'abay', name: 'Abay Bank', shortName: 'Abay', color: Color(0xFF0277BD), iconLetter: 'A', logoAsset: 'assets/logos/Abay.png'),
  BankInfo(id: 'amhara', name: 'Amhara Bank', shortName: 'Amhara', color: Color(0xFF1565C0), iconLetter: 'A', logoAsset: 'assets/logos/Amhara.png'),
  BankInfo(id: 'telebirr', name: 'Telebirr', shortName: 'Telebirr', color: Color(0xFF0072BC), iconLetter: 'T', logoAsset: 'assets/logos/telebir.png'),
  BankInfo(id: 'coop', name: 'Cooperative Bank of Oromia', shortName: 'CBO', color: Color(0xFFF57C00), iconLetter: 'O'),
  BankInfo(id: 'nib', name: 'Nib International Bank', shortName: 'NIB', color: Color(0xFFC62828), iconLetter: 'N'),
  BankInfo(id: 'wegagen', name: 'Wegagen Bank', shortName: 'Wegagen', color: Color(0xFF4527A0), iconLetter: 'W'),
  BankInfo(id: 'united', name: 'United Bank', shortName: 'United', color: Color(0xFF00695C), iconLetter: 'U'),
  BankInfo(id: 'bunna', name: 'Bunna International Bank', shortName: 'Bunna', color: Color(0xFF795548), iconLetter: 'B'),
  BankInfo(id: 'mpesa', name: 'M-Pesa', shortName: 'M-Pesa', color: Color(0xFF4CAF50), iconLetter: 'M'),
  BankInfo(id: 'enat', name: 'Enat Bank', shortName: 'Enat', color: Color(0xFFE91E63), iconLetter: 'E'),
];

BankInfo? getBankById(String id) {
  try {
    return banks.firstWhere((b) => b.id == id);
  } catch (_) {
    return null;
  }
}
