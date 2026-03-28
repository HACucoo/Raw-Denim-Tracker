import 'package:sqflite/sqflite.dart';
import '../core/database/app_database.dart';
import '../models/wash.dart';

class WashRepository {
  Future<Database> get _db => AppDatabase.instance.database;

  Future<List<Wash>> getByItemId(String itemId) async {
    final db = await _db;
    final rows = await db.query(
      'washes',
      where: 'item_id = ?',
      whereArgs: [itemId],
      orderBy: 'date DESC',
    );
    return rows.map(Wash.fromMap).toList();
  }

  Future<List<Wash>> getAll() async {
    final db = await _db;
    final rows = await db.query('washes', orderBy: 'date DESC');
    return rows.map(Wash.fromMap).toList();
  }

  Future<void> insert(Wash wash) async {
    final db = await _db;
    await db.insert('washes', wash.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(Wash wash) async {
    final db = await _db;
    await db.update('washes', wash.toMap(), where: 'id = ?', whereArgs: [wash.id]);
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('washes', where: 'id = ?', whereArgs: [id]);
  }
}
