class Budget {
  final int? id;
  final int categoryId;
  final int month;
  final int year;
  final double amount;
  final bool carryOver;

  Budget({
    this.id,
    required this.categoryId,
    required this.month,
    required this.year,
    required this.amount,
    this.carryOver = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'categoryId': categoryId,
    'month': month,
    'year': year,
    'amount': amount,
    'carryOver': carryOver ? 1 : 0,
  };

  factory Budget.fromMap(Map<String, dynamic> map) => Budget(
    id: map['id'] as int?,
    categoryId: map['categoryId'] as int,
    month: map['month'] as int,
    year: map['year'] as int,
    amount: (map['amount'] as num).toDouble(),
    carryOver: (map['carryOver'] as int?) == 1,
  );

  String get key => '$year-$month';
}
