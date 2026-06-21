import 'model_material.dart';
import 'purse_model.dart';

class PurseModelWithBom {
  final PurseModel model;
  final List<ModelMaterial> bom;

  const PurseModelWithBom({required this.model, required this.bom});

  double get cost => bom.fold(
        0.0,
        (sum, mm) =>
            sum + mm.quantityPerUnit * (mm.material?.lastPricePerUnit ?? 0),
      );

  double get profit => model.sellingPrice - cost;

  double get marginPercent =>
      model.sellingPrice > 0 ? (profit / model.sellingPrice * 100) : 0;
}
