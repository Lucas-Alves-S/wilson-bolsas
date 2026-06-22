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
    });
  }
}
