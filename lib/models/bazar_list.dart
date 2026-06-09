import 'bazar_item.dart';

class BazarList {
  final int? id;
  final String name;
  final DateTime date;
  final double totalEstimated;
  final double? totalActual;
  final bool isTemplate;
  final int? accountId;
  final int? categoryId;
  final bool isCompleted;
  final String? createdAt;
  final List<BazarItem> items;

  BazarList({
    this.id,
    required this.name,
    required this.date,
    this.totalEstimated = 0,
    this.totalActual,
    this.isTemplate = false,
    this.accountId,
    this.categoryId,
    this.isCompleted = false,
    this.createdAt,
    this.items = const [],
  });

  double get actualTotal => items.fold(0, (sum, item) => sum + (item.priceActual ?? 0));
  double get estimatedTotal => items.fold(0, (sum, item) => sum + (item.priceEstimated * item.quantity));
  int get boughtCount => items.where((i) => i.isBought).length;
  bool get allBought => items.every((i) => i.isBought);
  double get remainingEstTotal => estimatedTotal - actualTotal;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'date': date.toIso8601String(),
    'totalEstimated': totalEstimated,
    'totalActual': totalActual,
    'isTemplate': isTemplate ? 1 : 0,
    'accountId': accountId,
    'categoryId': categoryId,
    'isCompleted': isCompleted ? 1 : 0,
    'createdAt': createdAt,
  };

  BazarList copyWith({
    int? id,
    String? name,
    DateTime? date,
    double? totalEstimated,
    double? totalActual,
    bool? isTemplate,
    int? accountId,
    int? categoryId,
    bool? isCompleted,
    String? createdAt,
  }) => BazarList(
    id: id ?? this.id,
    name: name ?? this.name,
    date: date ?? this.date,
    totalEstimated: totalEstimated ?? this.totalEstimated,
    totalActual: totalActual ?? this.totalActual,
    isTemplate: isTemplate ?? this.isTemplate,
    accountId: accountId ?? this.accountId,
    categoryId: categoryId ?? this.categoryId,
    isCompleted: isCompleted ?? this.isCompleted,
    createdAt: createdAt ?? this.createdAt,
    items: items,
  );

  factory BazarList.fromMap(Map<String, dynamic> map) => BazarList(
    id: map['id'] as int?,
    name: map['name'] as String,
    date: DateTime.parse(map['date'] as String),
    totalEstimated: (map['totalEstimated'] as num?)?.toDouble() ?? 0,
    totalActual: (map['totalActual'] as num?)?.toDouble(),
    isTemplate: (map['isTemplate'] as int?) == 1,
    accountId: map['accountId'] as int?,
    categoryId: map['categoryId'] as int?,
    isCompleted: (map['isCompleted'] as int?) == 1,
    createdAt: map['createdAt'] as String?,
  );
}
