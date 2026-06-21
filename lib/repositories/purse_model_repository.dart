import '../core/database/database_helper.dart';
import '../models/material_item.dart';
import '../models/model_material.dart';
import '../models/purse_model.dart';
import '../models/purse_model_with_bom.dart';

class PurseModelRepository {
  final DatabaseHelper _helper;
  PurseModelRepository(this._helper);

  Future<List<PurseModel>> getAll() async {
    final db = await _helper.database;
    final rows = await db.query('purse_models', orderBy: 'name ASC');
    return rows.map(PurseModel.fromMap).toList();
  }

  Future<PurseModelWithBom> getWithBom(int id) async {
    final db = await _helper.database;

    final modelRows =
        await db.query('purse_models', where: 'id = ?', whereArgs: [id]);
    final model = PurseModel.fromMap(modelRows.first);

    final bomRows = await db.rawQuery('''
      SELECT mm.*, m.name AS mat_name, m.unit AS mat_unit,
             m.last_price_per_unit AS mat_price,
             m.created_at AS mat_created_at, m.updated_at AS mat_updated_at
      FROM model_materials mm
      JOIN materials m ON m.id = mm.material_id
      WHERE mm.model_id = ?
      ORDER BY m.name ASC
    ''', [id]);

    final bom = bomRows.map((row) {
      final material = MaterialItem(
        id: row['material_id'] as int,
        name: row['mat_name'] as String,
        unit: row['mat_unit'] as String,
        lastPricePerUnit: (row['mat_price'] as num).toDouble(),
        createdAt: DateTime.parse(row['mat_created_at'] as String),
        updatedAt: DateTime.parse(row['mat_updated_at'] as String),
      );
      return ModelMaterial.fromMap(row as Map<String, dynamic>,
          material: material);
    }).toList();

    return PurseModelWithBom(model: model, bom: bom);
  }

  Future<int> insert(PurseModel model) async {
    final db = await _helper.database;
    return db.insert('purse_models', model.toMap());
  }

  Future<void> update(PurseModel model) async {
    final db = await _helper.database;
    await db.update(
      'purse_models',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _helper.database;
    await db.delete('purse_models', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setBom(int modelId, List<ModelMaterial> entries) async {
    final db = await _helper.database;
    await db.transaction((txn) async {
      await txn.delete(
        'model_materials',
        where: 'model_id = ?',
        whereArgs: [modelId],
      );
      for (final entry in entries) {
        await txn.insert(
          'model_materials',
          entry.copyWith(modelId: modelId).toMap(),
        );
      }
    });
  }
}
