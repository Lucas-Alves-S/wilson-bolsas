import '../core/database/database_helper.dart';
import '../models/material_purchase.dart';

class MaterialPurchaseRepository {
  final DatabaseHelper _helper;
  MaterialPurchaseRepository(this._helper);

  Future<List<MaterialPurchase>> getForMaterial(int materialId,
      {int limit = 50}) async {
    final db = await _helper.database;
    final rows = await db.query(
      'material_purchases',
      where: 'material_id = ?',
      whereArgs: [materialId],
      orderBy: 'purchased_at DESC',
      limit: limit,
    );
    return rows.map(MaterialPurchase.fromMap).toList();
  }

  Future<List<MaterialPurchase>> getAllRecent({int limit = 500}) async {
    final db = await _helper.database;
    final rows = await db.query(
      'material_purchases',
      orderBy: 'purchased_at DESC',
      limit: limit,
    );
    return rows.map(MaterialPurchase.fromMap).toList();
  }

  /// Records a purchase and, in the same transaction, restocks the material and
  /// refreshes its last paid price (which feeds BOM cost calculations).
  Future<void> addPurchase(MaterialPurchase purchase) async {
    final db = await _helper.database;
    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      await txn.insert('material_purchases', purchase.toMap());
      await txn.rawUpdate(
        'UPDATE materials SET current_stock = current_stock + ?, '
        'last_price_per_unit = ?, updated_at = ? WHERE id = ?',
        [purchase.quantity, purchase.unitPrice, now, purchase.materialId],
      );
    });
  }
}
