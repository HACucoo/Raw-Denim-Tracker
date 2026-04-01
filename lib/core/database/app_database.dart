import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  AppDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'raw_denim_tracker.db');
    return openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE items (
        id TEXT PRIMARY KEY,
        brand TEXT NOT NULL,
        model TEXT NOT NULL,
        size TEXT NOT NULL,
        first_wear_date TEXT NOT NULL,
        notes TEXT,
        photo_path TEXT,
        nfc_tag_id TEXT,
        created_at TEXT NOT NULL,
        base_wear_count INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE wear_days (
        id TEXT PRIMARY KEY,
        item_id TEXT NOT NULL,
        date TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        FOREIGN KEY (item_id) REFERENCES items (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE washes (
        id TEXT PRIMARY KEY,
        item_id TEXT NOT NULL,
        date TEXT NOT NULL,
        temp_celsius INTEGER NOT NULL,
        wear_days_at_wash INTEGER,
        FOREIGN KEY (item_id) REFERENCES items (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_wear_days_item_id ON wear_days (item_id)');
    await db.execute('CREATE INDEX idx_washes_item_id ON washes (item_id)');
    await db.execute('CREATE UNIQUE INDEX idx_nfc_tag ON items (nfc_tag_id) WHERE nfc_tag_id IS NOT NULL');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE items ADD COLUMN base_wear_count INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE washes ADD COLUMN wear_days_at_wash INTEGER',
      );
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE wear_days ADD COLUMN latitude REAL');
      await db.execute('ALTER TABLE wear_days ADD COLUMN longitude REAL');
    }
  }

  Future<void> close() async => _db?.close();
}
