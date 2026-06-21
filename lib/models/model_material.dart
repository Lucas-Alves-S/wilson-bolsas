import 'material_item.dart';

class ModelMaterial {
  final int? id;
  final int modelId;
  final int materialId;
  final double quantityPerUnit;
  final MaterialItem? material;

  const ModelMaterial({
    this.id,
    required this.modelId,
    required this.materialId,
    required this.quantityPerUnit,
    this.material,
  });

  ModelMaterial copyWith({
    int? id,
    int? modelId,
    int? materialId,
    double? quantityPerUnit,
    MaterialItem? material,
  }) {
    return ModelMaterial(
      id: id ?? this.id,
      modelId: modelId ?? this.modelId,
      materialId: materialId ?? this.materialId,
      quantityPerUnit: quantityPerUnit ?? this.quantityPerUnit,
      material: material ?? this.material,
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'model_id': modelId,
        'material_id': materialId,
        'quantity_per_unit': quantityPerUnit,
      };

  factory ModelMaterial.fromMap(Map<String, dynamic> map,
      {MaterialItem? material}) =>
      ModelMaterial(
        id: map['id'] as int?,
        modelId: map['model_id'] as int,
        materialId: map['material_id'] as int,
        quantityPerUnit: (map['quantity_per_unit'] as num).toDouble(),
        material: material,
      );
}
