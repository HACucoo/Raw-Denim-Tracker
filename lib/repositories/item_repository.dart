import 'package:sqflite/sqflite.dart';
import '../core/database/app_database.dart';
import '../models/item.dart';

class ItemRepository {
  Future<Database> get _db => AppDatabase.instance.database;

  Future<List<Item>> getAll() async {
    final db = await _db;
    final rows = await db.query('items', orderBy: 'created_at DESC');
    return rows.map(Item.fromMap).toList();
  }

  Future<Item?> getById(String id) async {
    final db = await _db;
    final rows = await db.query('items', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Item.fromMap(rows.first);
  }

  Future<Item?> getByNfcTagId(String nfcTagId) async {
    final db = await _db;
    final rows = await db.query('items', where: 'nfc_tag_id = ?', whereArgs: [nfcTagId]);
    return rows.isEmpty ? null : Item.fromMap(rows.first);
  }

  Future<void> insert(Item item) async {
    final db = await _db;
    await db.insert('items', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(Item item) async {
    final db = await _db;
    await db.update('items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }
}
