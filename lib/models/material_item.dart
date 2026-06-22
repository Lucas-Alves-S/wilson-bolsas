class MaterialItem {
  final int? id;
  final String name;
  final String unit;
  final double lastPricePerUnit;
  final double currentStock;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MaterialItem({
    this.id,
    required this.name,
    required this.unit,
    required this.lastPricePerUnit,
    this.currentStock = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  MaterialItem copyWith({
    int? id,
    String? name,
    String? unit,
    double? lastPricePerUnit,
    double? currentStock,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaterialItem(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      lastPricePerUnit: lastPricePerUnit ?? this.lastPricePerUnit,
      currentStock: currentStock ?? this.currentStock,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'unit': unit,
        'last_price_per_unit': lastPricePerUnit,
        'current_stock': currentStock,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory MaterialItem.fromMap(Map<String, dynamic> map) => MaterialItem(
        id: map['id'] as int?,
        name: map['name'] as String,
        unit: map['unit'] as String,
        lastPricePerUnit: (map['last_price_per_unit'] as num).toDouble(),
        currentStock: (map['current_stock'] as num?)?.toDouble() ?? 0,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );
}
