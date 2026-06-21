import 'package:flutter/foundation.dart';

import '../models/model_material.dart';
import '../models/purse_model.dart';
import '../models/purse_model_with_bom.dart';
import '../repositories/purse_model_repository.dart';

class PurseModelProvider extends ChangeNotifier {
  final PurseModelRepository _repo;
  PurseModelProvider(this._repo);

  List<PurseModel> _models = [];
  List<PurseModel> get models => _models;

  PurseModelWithBom? _selected;
  PurseModelWithBom? get selected => _selected;

  bool _loading = false;
  bool get loading => _loading;

  Future<void> loadAll() async {
    _loading = true;
    notifyListeners();
    _models = await _repo.getAll();
    _loading = false;
    notifyListeners();
  }

  Future<void> loadDetail(int id) async {
    _selected = await _repo.getWithBom(id);
    notifyListeners();
  }

  void clearDetail() {
    _selected = null;
  }

  Future<int> add(PurseModel model, List<ModelMaterial> bom) async {
    final id = await _repo.insert(model);
    await _repo.setBom(id, bom);
    await loadAll();
    return id;
  }

  Future<void> save(PurseModel model, List<ModelMaterial> bom) async {
    await _repo.update(model);
    await _repo.setBom(model.id!, bom);
    await loadAll();
    if (_selected?.model.id == model.id) {
      await loadDetail(model.id!);
    }
  }

  Future<void> remove(int id) async {
    await _repo.delete(id);
    _models = _models.where((m) => m.id != id).toList();
    if (_selected?.model.id == id) _selected = null;
    notifyListeners();
  }

  Future<void> refreshSelected() async {
    if (_selected != null) {
      await loadDetail(_selected!.model.id!);
    }
  }
}
