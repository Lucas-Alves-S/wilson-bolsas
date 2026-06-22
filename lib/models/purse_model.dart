class PurseModel {
  final int? id;
  final String name;
  final double sellingPrice;
  final int currentStock;
  final int weeklyTarget;
  final String? color;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PurseModel({
    this.id,
    required this.name,
    required this.sellingPrice,
    this.currentStock = 0,
    this.weeklyTarget = 0,
    this.color,
    this.imagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  PurseModel copyWith({
    int? id,
    String? name,
    double? sellingPrice,
    int? currentStock,
    int? weeklyTarget,
    String? color,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PurseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      currentStock: currentStock ?? this.currentStock,
      weeklyTarget: weeklyTarget ?? this.weeklyTarget,
      color: color ?? this.color,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'selling_price': sellingPrice,
        'current_stock': currentStock,
        'weekly_target': weeklyTarget,
        'color': color,
        'image_path': imagePath,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory PurseModel.fromMap(Map<String, dynamic> map) => PurseModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        sellingPrice: (map['selling_price'] as num).toDouble(),
        currentStock: map['current_stock'] as int,
        weeklyTarget: (map['weekly_target'] as int?) ?? 0,
        color: map['color'] as String?,
        imagePath: map['image_path'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );
}
