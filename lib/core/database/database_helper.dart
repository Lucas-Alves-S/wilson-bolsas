import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

const int kLowStockThreshold = 3;
const int _dbVersion = 1;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = join(dir, 'wilson_bolsas.db');
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE purse_models (
            id            INTEGER PRIMARY KEY AUTOINCREMENT,
            name          TEXT    NOT NULL,
            selling_price REAL    NOT NULL DEFAULT 0,
            current_stock INTEGER NOT NULL DEFAULT 0,
            created_at    TEXT    NOT NULL,
            updated_at    TEXT    NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE materials (
            id                  INTEGER PRIMARY KEY AUTOINCREMENT,
            name                TEXT NOT NULL,
            unit                TEXT NOT NULL,
            last_price_per_unit REAL NOT NULL DEFAULT 0,
            created_at          TEXT NOT NULL,
            updated_at          TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE model_materials (
            id                INTEGER PRIMARY KEY AUTOINCREMENT,
            model_id          INTEGER NOT NULL,
            material_id       INTEGER NOT NULL,
            quantity_per_unit REAL    NOT NULL,
            FOREIGN KEY (model_id)    REFERENCES purse_models(id) ON DELETE CASCADE,
            FOREIGN KEY (material_id) REFERENCES materials(id)    ON DELETE CASCADE,
            UNIQUE (model_id, material_id)
          )
        ''');
        await db.execute('''
          CREATE TABLE stock_movements (
            id       INTEGER PRIMARY KEY AUTOINCREMENT,
            model_id INTEGER NOT NULL,
            delta    INTEGER NOT NULL,
            reason   TEXT,
            moved_at TEXT NOT NULL,
            FOREIGN KEY (model_id) REFERENCES purse_models(id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }
}
