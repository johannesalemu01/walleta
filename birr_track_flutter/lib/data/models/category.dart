import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

const List<Category> defaultCategories = [
  Category(id: 'food', name: 'Food & Dining', icon: Icons.restaurant, color: Color(0xFFEF6C00)),
  Category(id: 'transport', name: 'Transport', icon: Icons.directions_car, color: Color(0xFF1565C0)),
  Category(id: 'utilities', name: 'Utilities', icon: Icons.flash_on, color: Color(0xFFF9A825)),
  Category(id: 'healthcare', name: 'Healthcare', icon: Icons.medical_services, color: Color(0xFFC62828)),
  Category(id: 'entertainment', name: 'Entertainment', icon: Icons.movie, color: Color(0xFF7B1FA2)),
  Category(id: 'groceries', name: 'Groceries', icon: Icons.shopping_cart, color: Color(0xFF2E7D32)),
  Category(id: 'rent', name: 'Rent', icon: Icons.home, color: Color(0xFF4E342E)),
  Category(id: 'shopping', name: 'Shopping', icon: Icons.shopping_bag, color: Color(0xFFD81B60)),
  Category(id: 'education', name: 'Education', icon: Icons.school, color: Color(0xFF0097A7)),
  Category(id: 'transfer', name: 'Personal Transfer', icon: Icons.swap_horiz, color: Color(0xFF5C6BC0)),
  Category(id: 'salary', name: 'Salary', icon: Icons.account_balance_wallet, color: Color(0xFF00897B)),
  Category(id: 'business', name: 'Business', icon: Icons.business_center, color: Color(0xFF37474F)),
  Category(id: 'bills', name: 'Bills', icon: Icons.receipt, color: Color(0xFF6D4C41)),
  Category(id: 'other', name: 'Other', icon: Icons.more_horiz, color: Color(0xFF78909C)),
];

Category? getCategoryById(String id) {
  try {
    return defaultCategories.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
}
