// lib/models/expense_data.dart

class ExpenseEntry {
  final String id;
  final String vendor;
  final double amount;
  final String currency;
  final String categoryId;
  final DateTime date;
  final String notes;
  final DateTime createdAt;

  const ExpenseEntry({
    required this.id,
    required this.vendor,
    required this.amount,
    required this.currency,
    required this.categoryId,
    required this.date,
    required this.notes,
    required this.createdAt,
  });

  ExpenseEntry copyWith({
    String? vendor,
    double? amount,
    String? currency,
    String? categoryId,
    DateTime? date,
    String? notes,
  }) {
    return ExpenseEntry(
      id: id,
      vendor: vendor ?? this.vendor,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'vendor': vendor,
        'amount': amount,
        'currency': currency,
        'categoryId': categoryId,
        'date': date.toIso8601String(),
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ExpenseEntry.fromJson(Map<String, dynamic> j) => ExpenseEntry(
        id: j['id'] as String,
        vendor: j['vendor'] as String,
        amount: (j['amount'] as num).toDouble(),
        currency: j['currency'] as String,
        categoryId: j['categoryId'] as String,
        date: DateTime.parse(j['date'] as String),
        notes: j['notes'] as String? ?? '',
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}
