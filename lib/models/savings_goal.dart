class SavingsGoal {
  final int? id;
  final String name;
  final String? nameBn;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final int? accountId;
  final String icon;
  final int color;
  final int priority;
  final bool isActive;
  final String? createdAt;

  SavingsGoal({
    this.id,
    required this.name,
    this.nameBn,
    required this.targetAmount,
    this.currentAmount = 0,
    this.deadline,
    this.accountId,
    this.icon = 'savings',
    this.color = 0xFF006B5E,
    this.priority = 0,
    this.isActive = true,
    this.createdAt,
  });

  double get progress => targetAmount > 0 ? currentAmount / targetAmount : 0;
  double get remaining => targetAmount - currentAmount;
  bool get isCompleted => currentAmount >= targetAmount;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'nameBn': nameBn,
    'targetAmount': targetAmount,
    'currentAmount': currentAmount,
    'deadline': deadline?.toIso8601String(),
    'accountId': accountId,
    'icon': icon,
    'color': color,
    'priority': priority,
    'isActive': isActive ? 1 : 0,
    'createdAt': createdAt,
  };

  factory SavingsGoal.fromMap(Map<String, dynamic> map) => SavingsGoal(
    id: map['id'] as int?,
    name: map['name'] as String,
    nameBn: map['nameBn'] as String?,
    targetAmount: (map['targetAmount'] as num).toDouble(),
    currentAmount: (map['currentAmount'] as num?)?.toDouble() ?? 0,
    deadline: map['deadline'] != null ? DateTime.parse(map['deadline'] as String) : null,
    accountId: map['accountId'] as int?,
    icon: map['icon'] as String? ?? 'savings',
    color: map['color'] as int? ?? 0xFF006B5E,
    priority: map['priority'] as int? ?? 0,
    isActive: (map['isActive'] as int?) == 1,
    createdAt: map['createdAt'] as String?,
  );

  SavingsGoal copyWith({
    int? id,
    String? name,
    String? nameBn,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    int? accountId,
    String? icon,
    int? color,
    int? priority,
    bool? isActive,
    String? createdAt,
  }) => SavingsGoal(
    id: id ?? this.id,
    name: name ?? this.name,
    nameBn: nameBn ?? this.nameBn,
    targetAmount: targetAmount ?? this.targetAmount,
    currentAmount: currentAmount ?? this.currentAmount,
    deadline: deadline ?? this.deadline,
    accountId: accountId ?? this.accountId,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    priority: priority ?? this.priority,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
  );
}
