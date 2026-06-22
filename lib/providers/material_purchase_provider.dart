import 'package:flutter/foundation.dart';

import '../models/material_purchase.dart';
import '../repositories/material_purchase_repository.dart';

class MaterialPurchaseProvider extends ChangeNotifier {
  final MaterialPurchaseRepository _repo;
  MaterialPurchaseProvider(this._repo);

  Future<void> addPurchase(MaterialPurchase purchase) async {
    await _repo.addPurchase(purchase);
    notifyListeners();
  }
}
