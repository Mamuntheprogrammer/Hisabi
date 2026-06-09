class Category {
  final int? id;
  final String name;
  final String? nameBn;
  final String type;
  final String icon;
  final int color;

  Category({
    this.id,
    required this.name,
    this.nameBn,
    required this.type,
    this.icon = 'more_horiz',
    this.color = 0xFF006B5E,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'nameBn': nameBn,
    'type': type,
    'icon': icon,
    'color': color,
  };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
    id: map['id'] as int?,
    name: map['name'] as String,
    nameBn: map['nameBn'] as String?,
    type: map['type'] as String,
    icon: map['icon'] as String? ?? 'more_horiz',
    color: map['color'] as int? ?? 0xFF006B5E,
  );
}
