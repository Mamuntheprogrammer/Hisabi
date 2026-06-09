class Transaction {
  final int? id;
  final double amount;
  final String type;
  final int? categoryId;
  final int accountId;
  final int? toAccountId;
  final DateTime date;
  final String? note;
  final String? photo;
  final String? tags;
  final bool isRecurring;
  final String? createdAt;

  Transaction({
    this.id,
    required this.amount,
    required this.type,
    this.categoryId,
    required this.accountId,
    this.toAccountId,
    required this.date,
    this.note,
    this.photo,
    this.tags,
    this.isRecurring = false,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'amount': amount,
    'type': type,
    'categoryId': categoryId,
    'accountId': accountId,
    'toAccountId': toAccountId,
    'date': date.toIso8601String(),
    'note': note,
    'photo': photo,
    'tags': tags,
    'isRecurring': isRecurring ? 1 : 0,
    'createdAt': createdAt,
  };

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
    id: map['id'] as int?,
    amount: (map['amount'] as num).toDouble(),
    type: map['type'] as String,
    categoryId: map['categoryId'] as int?,
    accountId: map['accountId'] as int,
    toAccountId: map['toAccountId'] as int?,
    date: DateTime.parse(map['date'] as String),
    note: map['note'] as String?,
    photo: map['photo'] as String?,
    tags: map['tags'] as String?,
    isRecurring: (map['isRecurring'] as int?) == 1,
    createdAt: map['createdAt'] as String?,
  );

  Transaction copyWith({
    int? id,
    double? amount,
    String? type,
    int? categoryId,
    int? accountId,
    int? toAccountId,
    DateTime? date,
    String? note,
    String? photo,
    String? tags,
    bool? isRecurring,
    String? createdAt,
  }) => Transaction(
    id: id ?? this.id,
    amount: amount ?? this.amount,
    type: type ?? this.type,
    categoryId: categoryId ?? this.categoryId,
    accountId: accountId ?? this.accountId,
    toAccountId: toAccountId ?? this.toAccountId,
    date: date ?? this.date,
    note: note ?? this.note,
    photo: photo ?? this.photo,
    tags: tags ?? this.tags,
    isRecurring: isRecurring ?? this.isRecurring,
    createdAt: createdAt ?? this.createdAt,
  );
}
