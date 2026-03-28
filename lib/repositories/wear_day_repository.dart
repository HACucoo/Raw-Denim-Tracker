import 'package:sqflite/sqflite.dart';
import '../core/database/app_database.dart';
import '../models/wear_day.dart';

class WearDayRepository {
  Future<Database> get _db => AppDatabase.instance.database;

  Future<List<WearDay>> getByItemId(String itemId) async {
    final db = await _db;
    final rows = await db.query(
      'wear_days',
      where: 'item_id = ?',
      whereArgs: [itemId],
      orderBy: 'date DESC',
    );
    return rows.map(WearDay.fromMap).toList();
  }

  Future<List<WearDay>> getAll() async {
    final db = await _db;
    final rows = await db.query('wear_days', orderBy: 'date DESC');
    return rows.map(WearDay.fromMap).toList();
  }

  /// Returns a map of itemId → tracked wear day count for all items.
  Future<Map<String, int>> getAllTrackedCounts() async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT item_id, COUNT(*) as count FROM wear_days GROUP BY item_id',
    );
    return {for (final r in rows) r['item_id'] as String: r['count'] as int};
  }

  Future<int> countByItemId(String itemId) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM wear_days WHERE item_id = ?',
      [itemId],
    );
    return (result.firstOrNull?['count'] as int?) ?? 0;
  }

  Future<void> insert(WearDay wearDay) async {
    final db = await _db;
    await db.insert('wear_days', wearDay.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(WearDay wearDay) async {
    final db = await _db;
    await db.update('wear_days', wearDay.toMap(), where: 'id = ?', whereArgs: [wearDay.id]);
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('wear_days', where: 'id = ?', whereArgs: [id]);
  }

  /// Returns a map of itemId → most recent wear day date.
  Future<Map<String, DateTime>> getLastWornDates() async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT item_id, MAX(date) as last_date FROM wear_days GROUP BY item_id',
    );
    final result = <String, DateTime>{};
    for (final r in rows) {
      final dateStr = r['last_date'] as String?;
      final dt = dateStr != null ? DateTime.tryParse(dateStr) : null;
      if (dt != null) result[r['item_id'] as String] = dt;
    }
    return result;
  }

  Future<DateTime?> getLastWornDate(String itemId) async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT MAX(date) as last_date FROM wear_days WHERE item_id = ?',
      [itemId],
    );
    final dateStr = rows.firstOrNull?['last_date'] as String?;
    return dateStr != null ? DateTime.tryParse(dateStr) : null;
  }

  Future<bool> existsForDate(String itemId, DateTime date) async {
    final db = await _db;
    final dateStr = DateTime(date.year, date.month, date.day).toIso8601String().substring(0, 10);
    final rows = await db.rawQuery(
      "SELECT id FROM wear_days WHERE item_id = ? AND date LIKE ?",
      [itemId, '$dateStr%'],
    );
    return rows.isNotEmpty;
  }
}
