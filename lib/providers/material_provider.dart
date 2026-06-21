import 'package:flutter/foundation.dart';

import '../models/material_item.dart';
import '../repositories/material_repository.dart';

class MaterialProvider extends ChangeNotifier {
  final MaterialRepository _repo;
  MaterialProvider(this._repo);

  List<MaterialItem> _materials = [];
  List<MaterialItem> get materials => _materials;

  bool _loading = false;
  bool get loading => _loading;

  Future<void> loadAll() async {
    _loading = true;
    notifyListeners();
    _materials = await _repo.getAll();
    _loading = false;
    notifyListeners();
  }

  Future<void> add(MaterialItem item) async {
    final id = await _repo.insert(item);
    _materials = [..._materials, item.copyWith(id: id)];
    _materials.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  Future<void> save(MaterialItem item) async {
    await _repo.update(item);
    final idx = _materials.indexWhere((m) => m.id == item.id);
    if (idx >= 0) {
      _materials = [..._materials]..[idx] = item;
      _materials.sort((a, b) => a.name.compareTo(b.name));
    }
    notifyListeners();
  }

  Future<void> remove(int id) async {
    await _repo.delete(id);
    _materials = _materials.where((m) => m.id != id).toList();
    notifyListeners();
  }
}
