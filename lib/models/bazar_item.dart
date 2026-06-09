class BazarItem {
  final int? id;
  final int listId;
  final String name;
  final String? nameBn;
  final double quantity;
  final String unit;
  final double priceEstimated;
  final double? priceActual;
  final bool isBought;

  BazarItem({
    this.id,
    required this.listId,
    required this.name,
    this.nameBn,
    this.quantity = 1,
    this.unit = 'pcs',
    this.priceEstimated = 0,
    this.priceActual,
    this.isBought = false,
  });

  double get totalEstimated => priceEstimated * quantity;
  double? get totalActual => priceActual != null ? priceActual! * quantity : null;

  Map<String, dynamic> toMap() => {
    'id': id,
    'listId': listId,
    'name': name,
    'nameBn': nameBn,
    'quantity': quantity,
    'unit': unit,
    'priceEstimated': priceEstimated,
    'priceActual': priceActual,
    'isBought': isBought ? 1 : 0,
  };

  factory BazarItem.fromMap(Map<String, dynamic> map) => BazarItem(
    id: map['id'] as int?,
    listId: map['listId'] as int,
    name: map['name'] as String,
    nameBn: map['nameBn'] as String?,
    quantity: (map['quantity'] as num?)?.toDouble() ?? 1,
    unit: map['unit'] as String? ?? 'pcs',
    priceEstimated: (map['priceEstimated'] as num?)?.toDouble() ?? 0,
    priceActual: (map['priceActual'] as num?)?.toDouble(),
    isBought: (map['isBought'] as int?) == 1,
  );

  BazarItem copyWith({
    int? id,
    int? listId,
    String? name,
    String? nameBn,
    double? quantity,
    String? unit,
    double? priceEstimated,
    double? priceActual,
    bool? isBought,
  }) => BazarItem(
    id: id ?? this.id,
    listId: listId ?? this.listId,
    name: name ?? this.name,
    nameBn: nameBn ?? this.nameBn,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    priceEstimated: priceEstimated ?? this.priceEstimated,
    priceActual: priceActual ?? this.priceActual,
    isBought: isBought ?? this.isBought,
  );
}

class Unit {
  static const List<Map<String, String>> units = [
    {'en': 'pcs', 'bn': 'টি'},
    {'en': 'kg', 'bn': 'কেজি'},
    {'en': 'g', 'bn': 'গ্রাম'},
    {'en': 'litre', 'bn': 'লিটার'},
    {'en': 'mL', 'bn': 'মিলি'},
    {'en': 'dozen', 'bn': 'ডজন'},
    {'en': 'bundle', 'bn': 'আটি'},
    {'en': 'pack', 'bn': 'প্যাক'},
    {'en': 'sack', 'bn': 'বস্তা'},
    {'en': 'metre', 'bn': 'মিটার'},
    {'en': 'cm', 'bn': 'সেমি'},
    {'en': 'inch', 'bn': 'ইঞ্চি'},
    {'en': 'piece', 'bn': 'খানা'},
    {'en': 'pair', 'bn': 'জোড়া'},
    {'en': 'set', 'bn': 'সেট'},
    {'en': 'box', 'bn': 'বক্স'},
    {'en': 'bottle', 'bn': 'বোতল'},
    {'en': 'carton', 'bn': 'কার্টন'},
  ];
}
