import '../core/database/database_helper.dart';
import '../models/material_item.dart';

class MaterialRepository {
  final DatabaseHelper _helper;
  MaterialRepository(this._helper);

  Future<List<MaterialItem>> getAll() async {
    final db = await _helper.database;
    final rows = await db.query('materials', orderBy: 'name ASC');
    return rows.map(MaterialItem.fromMap).toList();
  }

  Future<MaterialItem?> getById(int id) async {
    final db = await _helper.database;
    final rows =
        await db.query('materials', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return MaterialItem.fromMap(rows.first);
  }

  Future<int> insert(MaterialItem item) async {
    final db = await _helper.database;
    return db.insert('materials', item.toMap());
  }

  Future<void> update(MaterialItem item) async {
    final db = await _helper.database;
    await db.update(
      'materials',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _helper.database;
    await db.delete('materials', where: 'id = ?', whereArgs: [id]);
  }
}
