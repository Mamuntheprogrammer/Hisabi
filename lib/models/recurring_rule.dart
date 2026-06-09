class RecurringRule {
  final int? id;
  final int transactionId;
  final String frequency;
  final int intervalValue;
  final int? dayOfWeek;
  final int? dayOfMonth;
  final DateTime nextDate;
  final DateTime? endDate;
  final bool isActive;

  RecurringRule({
    this.id,
    required this.transactionId,
    required this.frequency,
    this.intervalValue = 1,
    this.dayOfWeek,
    this.dayOfMonth,
    required this.nextDate,
    this.endDate,
    this.isActive = true,
  });

  DateTime? computeNextDate(DateTime from) {
    switch (frequency) {
      case 'daily':
        return from.add(Duration(days: intervalValue));
      case 'weekly':
        return from.add(Duration(days: 7 * intervalValue));
      case 'monthly':
        return DateTime(from.year, from.month + intervalValue, from.day);
      case 'yearly':
        return DateTime(from.year + intervalValue, from.month, from.day);
      default:
        return null;
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'transactionId': transactionId,
    'frequency': frequency,
    'intervalValue': intervalValue,
    'dayOfWeek': dayOfWeek,
    'dayOfMonth': dayOfMonth,
    'nextDate': nextDate.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'isActive': isActive ? 1 : 0,
  };

  factory RecurringRule.fromMap(Map<String, dynamic> map) => RecurringRule(
    id: map['id'] as int?,
    transactionId: map['transactionId'] as int,
    frequency: map['frequency'] as String,
    intervalValue: map['intervalValue'] as int? ?? 1,
    dayOfWeek: map['dayOfWeek'] as int?,
    dayOfMonth: map['dayOfMonth'] as int?,
    nextDate: DateTime.parse(map['nextDate'] as String),
    endDate: map['endDate'] != null ? DateTime.parse(map['endDate'] as String) : null,
    isActive: (map['isActive'] as int?) == 1,
  );
}
