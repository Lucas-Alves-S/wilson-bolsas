import '../../models/material_item.dart';
import '../../models/purse_model_with_bom.dart';

/// How much of each material is required to produce this week's planned purses.
///
/// For every model's Ficha técnica (BOM), accumulates `weeklyTarget ×
/// quantityPerUnit` keyed by material id. Materials not consumed by any planned
/// production simply won't appear in the map.
Map<int, double> weeklyMaterialNeed(List<PurseModelWithBom> boms) {
  final need = <int, double>{};
  for (final b in boms) {
    final target = b.model.weeklyTarget;
    if (target <= 0) continue;
    for (final mm in b.bom) {
      need.update(
        mm.materialId,
        (v) => v + target * mm.quantityPerUnit,
        ifAbsent: () => target * mm.quantityPerUnit,
      );
    }
  }
  return need;
}

/// A material is low when this week's planned production needs more of it than
/// is currently in stock.
bool isMaterialLow(MaterialItem m, Map<int, double> need) {
  final required = need[m.id];
  return required != null && required > 0 && m.currentStock < required;
}

/// How much of a material still needs to be bought to cover this week's plan:
/// the shortfall between need and current stock (never negative).
double materialToBuy(MaterialItem m, Map<int, double> need) {
  final shortfall = (need[m.id] ?? 0) - m.currentStock;
  return shortfall > 0 ? shortfall : 0;
}
