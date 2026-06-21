import 'package:flutter/foundation.dart';

import '../models/stock_movement.dart';
import '../repositories/stock_movement_repository.dart';

class StockMovementProvider extends ChangeNotifier {
  final StockMovementRepository _repo;
  StockMovementProvider(this._repo);

  List<StockMovement> _movements = [];
  List<StockMovement> get movements => _movements;

  bool _loading = false;
  bool get loading => _loading;

  Future<void> loadForModel(int modelId) async {
    _loading = true;
    notifyListeners();
    _movements = await _repo.getForModel(modelId);
    _loading = false;
    notifyListeners();
  }

  Future<void> addMovement(StockMovement movement) async {
    await _repo.addMovement(movement);
    _movements = [movement, ..._movements];
    notifyListeners();
  }
}
