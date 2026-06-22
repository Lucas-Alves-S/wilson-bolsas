import 'material_item.dart';

class MaterialPurchase {
  final int? id;
  final int materialId;
  final double quantity;
  final double unitPrice;
  final DateTime purchasedAt;

  /// Optional joined material, populated by reads that include it (history
  /// rows). Not persisted.
  final MaterialItem? material;

  const MaterialPurchase({
    this.id,
    required this.materialId,
    required this.quantity,
    required this.unitPrice,
    required this.purchasedAt,
    this.material,
  });

  double get totalPrice => quantity * unitPrice;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'material_id': materialId,
        'quantity': quantity,
        'unit_price': unitPrice,
        'purchased_at': purchasedAt.toIso8601String(),
      };

  factory MaterialPurchase.fromMap(Map<String, dynamic> map) => MaterialPurchase(
        id: map['id'] as int?,
        materialId: map['material_id'] as int,
        quantity: (map['quantity'] as num).toDouble(),
        unitPrice: (map['unit_price'] as num).toDouble(),
        purchasedAt: DateTime.parse(map['purchased_at'] as String),
      );
}
