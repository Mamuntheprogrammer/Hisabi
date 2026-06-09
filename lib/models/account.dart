class Account {
  final int? id;
  final String name;
  final String? nameBn;
  final String type;
  final String? bankName;
  final double balance;
  final int color;
  final String icon;
  final bool isActive;
  final String? createdAt;

  Account({
    this.id,
    required this.name,
    this.nameBn,
    required this.type,
    this.bankName,
    this.balance = 0,
    this.color = 0xFF006B5E,
    this.icon = 'account_balance',
    this.isActive = true,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'nameBn': nameBn,
    'type': type,
    'bankName': bankName,
    'balance': balance,
    'color': color,
    'icon': icon,
    'isActive': isActive ? 1 : 0,
    'createdAt': createdAt,
  };

  factory Account.fromMap(Map<String, dynamic> map) => Account(
    id: map['id'] as int?,
    name: map['name'] as String,
    nameBn: map['nameBn'] as String?,
    type: map['type'] as String,
    bankName: map['bankName'] as String?,
    balance: (map['balance'] as num?)?.toDouble() ?? 0,
    color: map['color'] as int? ?? 0xFF006B5E,
    icon: map['icon'] as String? ?? 'account_balance',
    isActive: (map['isActive'] as int?) == 1,
    createdAt: map['createdAt'] as String?,
  );

  Account copyWith({
    int? id,
    String? name,
    String? nameBn,
    String? type,
    String? bankName,
    double? balance,
    int? color,
    String? icon,
    bool? isActive,
    String? createdAt,
  }) => Account(
    id: id ?? this.id,
    name: name ?? this.name,
    nameBn: nameBn ?? this.nameBn,
    type: type ?? this.type,
    bankName: bankName ?? this.bankName,
    balance: balance ?? this.balance,
    color: color ?? this.color,
    icon: icon ?? this.icon,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
  );
}
