class Debt {
  final int? id;
  final String personName;
  final String? phone;
  final double amount;
  final double amountPaid;
  final String type;
  final DateTime date;
  final DateTime? dueDate;
  final String? note;
  final int? relatedTransactionId;
  final String status;

  Debt({
    this.id,
    required this.personName,
    this.phone,
    required this.amount,
    this.amountPaid = 0,
    required this.type,
    required this.date,
    this.dueDate,
    this.note,
    this.relatedTransactionId,
    this.status = 'pending',
  });

  double get remaining => amount - amountPaid;

  bool get isCleared => remaining <= 0;

  Map<String, dynamic> toMap() => {
    'id': id,
    'personName': personName,
    'phone': phone,
    'amount': amount,
    'amountPaid': amountPaid,
    'type': type,
    'date': date.toIso8601String(),
    'dueDate': dueDate?.toIso8601String(),
    'note': note,
    'relatedTransactionId': relatedTransactionId,
    'status': isCleared ? 'cleared' : status,
  };

  factory Debt.fromMap(Map<String, dynamic> map) => Debt(
    id: map['id'] as int?,
    personName: map['personName'] as String,
    phone: map['phone'] as String?,
    amount: (map['amount'] as num).toDouble(),
    amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0,
    type: map['type'] as String,
    date: DateTime.parse(map['date'] as String),
    dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate'] as String) : null,
    note: map['note'] as String?,
    relatedTransactionId: map['relatedTransactionId'] as int?,
    status: map['status'] as String? ?? 'pending',
  );
}
