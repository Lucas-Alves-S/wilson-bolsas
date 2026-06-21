class MaterialItem {
  final int? id;
  final String name;
  final String unit;
  final double lastPricePerUnit;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MaterialItem({
    this.id,
    required this.name,
    required this.unit,
    required this.lastPricePerUnit,
    required this.createdAt,
    required this.updatedAt,
  });

  MaterialItem copyWith({
    int? id,
    String? name,
    String? unit,
    double? lastPricePerUnit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaterialItem(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      lastPricePerUnit: lastPricePerUnit ?? this.lastPricePerUnit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'unit': unit,
        'last_price_per_unit': lastPricePerUnit,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory MaterialItem.fromMap(Map<String, dynamic> map) => MaterialItem(
        id: map['id'] as int?,
        name: map['name'] as String,
        unit: map['unit'] as String,
        lastPricePerUnit: (map['last_price_per_unit'] as num).toDouble(),
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );
}
