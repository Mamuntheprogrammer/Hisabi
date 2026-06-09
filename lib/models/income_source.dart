class IncomeSource {
  final int? id;
  final String name;
  final String? nameBn;
  final int? categoryId;
  final int accountId;
  final double amount;
  final String frequency;
  final DateTime? nextDate;
  final String? note;
  final bool isActive;

  IncomeSource({
    this.id,
    required this.name,
    this.nameBn,
    this.categoryId,
    required this.accountId,
    this.amount = 0,
    this.frequency = 'one_time',
    this.nextDate,
    this.note,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'nameBn': nameBn,
    'categoryId': categoryId,
    'accountId': accountId,
    'amount': amount,
    'frequency': frequency,
    'nextDate': nextDate?.toIso8601String(),
    'note': note,
    'isActive': isActive ? 1 : 0,
  };

  factory IncomeSource.fromMap(Map<String, dynamic> map) => IncomeSource(
    id: map['id'] as int?,
    name: map['name'] as String,
    nameBn: map['nameBn'] as String?,
    categoryId: map['categoryId'] as int?,
    accountId: map['accountId'] as int,
    amount: (map['amount'] as num?)?.toDouble() ?? 0,
    frequency: map['frequency'] as String? ?? 'one_time',
    nextDate: map['nextDate'] != null ? DateTime.parse(map['nextDate'] as String) : null,
    note: map['note'] as String?,
    isActive: (map['isActive'] as int?) == 1,
  );
}
