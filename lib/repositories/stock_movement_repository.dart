import '../core/database/database_helper.dart';
import '../models/stock_movement.dart';

class StockMovementRepository {
  final DatabaseHelper _helper;
  StockMovementRepository(this._helper);

  Future<List<StockMovement>> getForModel(int modelId,
      {int limit = 50}) async {
    final db = await _helper.database;
    final rows = await db.query(
      'stock_movements',
      where: 'model_id = ?',
      whereArgs: [modelId],
      orderBy: 'moved_at DESC',
      limit: limit,
    );
    return rows.map(StockMovement.fromMap).toList();
  }

  Future<List<StockMovement>> getAllRecent({int limit = 500}) async {
    final db = await _helper.database;
    final rows = await db.query(
      'stock_movements',
      orderBy: 'moved_at DESC',
      limit: limit,
    );
    return rows.map(StockMovement.fromMap).toList();
  }

  Future<void> addMovement(StockMovement movement) async {
    final db = await _helper.database;
    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      await txn.insert('stock_movements', movement.toMap());
      await txn.rawUpdate(
        'UPDATE purse_models SET current_stock = current_stock + ?, updated_at = ? WHERE id = ?',
        [movement.delta, now, movement.modelId],
      );
      // A positive delta is an Entrada — treated as production, so consume the
      // model's Ficha técnica (BOM) from material stock. (All Entradas are
      // assumed to be production; a rare Devolução can be corrected via the
      // material's manual stock edit. Material stock may go negative, which
      // simply reads as "low".)
      if (movement.delta > 0) {
        final bom = await txn.query(
          'model_materials',
          columns: ['material_id', 'quantity_per_unit'],
          where: 'model_id = ?',
          whereArgs: [movement.modelId],
        );
        for (final row in bom) {
          final consumed =
              movement.delta * (row['quantity_per_unit'] as num).toDouble();
          await txn.rawUpdate(
            'UPDATE materials SET current_stock = current_stock - ?, updated_at = ? WHERE id = ?',
            [consumed, now, row['material_id']],
          );
        }
      }
    });
  }
}
