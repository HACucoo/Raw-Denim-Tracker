import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item.dart';
import '../models/wear_day.dart';
import '../models/wash.dart';
import '../repositories/item_repository.dart';
import '../repositories/wear_day_repository.dart';
import '../repositories/wash_repository.dart';

const _lastAutoBackupKey = 'last_auto_backup_ms';
// Single canonical filename for the local auto-backup. Suffix is .zip because
// v2 backups bundle photos alongside the JSON; we keep the same name on disk
// so old paths are replaced cleanly when a user upgrades.
const _autoBackupFilename = 'denim_backup.zip';
// Legacy v1 backups were plain JSON. We still try to import them.
const _legacyAutoBackupFilename = 'denim_backup.json';
const _backupJsonEntry = 'backup.json';
const _photosDirEntry = 'photos/';

class BackupService {
  final ItemRepository _itemRepo;
  final WearDayRepository _wearDayRepo;
  final WashRepository _washRepo;

  BackupService({
    required ItemRepository itemRepo,
    required WearDayRepository wearDayRepo,
    required WashRepository washRepo,
  })  : _itemRepo = itemRepo,
        _wearDayRepo = wearDayRepo,
        _washRepo = washRepo;

  // ---------------------------------------------------------------------------
  // Export
  // ---------------------------------------------------------------------------

  /// Builds a v2 ZIP backup containing backup.json + photos/. Photo paths in
  /// the JSON are stored as bare filenames ("photo_123.jpg") so they survive
  /// being restored on a different device.
  Future<List<int>> _buildBackupZipBytes() async {
    final items = await _itemRepo.getAll();
    final wearDays = await _wearDayRepo.getAll();
    final washes = await _washRepo.getAll();

    final archive = Archive();

    // Items: rewrite photo_path to bare filename for portability.
    final itemsJson = items.map((i) {
      final json = i.toJson();
      final path = json['photo_path'] as String?;
      json['photo_path'] = path == null ? null : p.basename(path);
      return json;
    }).toList();

    final payload = {
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'items': itemsJson,
      'wearDays': wearDays.map((w) => w.toJson()).toList(),
      'washes': washes.map((w) => w.toJson()).toList(),
    };

    final jsonBytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
    archive.addFile(
      ArchiveFile(_backupJsonEntry, jsonBytes.length, jsonBytes),
    );

    // Embed each item's photo file under photos/. Skips missing files silently.
    for (final item in items) {
      final path = item.photoPath;
      if (path == null) continue;
      final file = File(path);
      if (!await file.exists()) continue;
      final bytes = await file.readAsBytes();
      archive.addFile(
        ArchiveFile('$_photosDirEntry${p.basename(path)}', bytes.length, bytes),
      );
    }

    return ZipEncoder().encode(archive)!;
  }

  /// Share backup via the system share sheet.
  Future<void> exportBackup() async {
    final bytes = await _buildBackupZipBytes();
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .substring(0, 19);
    final file = File('${dir.path}/denim_backup_$timestamp.zip');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/zip')],
      subject: 'Raw Denim Tracker Backup',
    );
  }

  /// Save backup directly to app-specific external storage.
  /// Returns the file path, or throws on error.
  Future<String> saveLocalBackup() async {
    final bytes = await _buildBackupZipBytes();
    final dir = await _localBackupDir();
    final file = File('${dir.path}/$_autoBackupFilename');
    await file.writeAsBytes(bytes);
    // Clean up stale v1 JSON next to it so the file manager doesn't show two.
    final legacy = File('${dir.path}/$_legacyAutoBackupFilename');
    if (await legacy.exists()) {
      try {
        await legacy.delete();
      } catch (_) {/* best-effort */}
    }
    return file.path;
  }

  /// Returns true and performs a backup if more than 7 days have passed since
  /// the last auto-backup (or no backup has ever been made).
  Future<bool> autoBackupIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt(_lastAutoBackupKey);
    final now = DateTime.now();
    if (lastMs != null) {
      final last = DateTime.fromMillisecondsSinceEpoch(lastMs);
      if (now.difference(last).inDays < 7) return false;
    }
    await saveLocalBackup();
    await prefs.setInt(_lastAutoBackupKey, now.millisecondsSinceEpoch);
    return true;
  }

  Future<Directory> _localBackupDir() async {
    // getExternalStorageDirectory → app-specific external: accessible via file manager
    // under Android/data/<package>/files/backups/ without any extra permissions.
    final base = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/backups');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  // ---------------------------------------------------------------------------
  // Import
  // ---------------------------------------------------------------------------

  /// Import from a file chosen via the system file picker. Accepts both the
  /// new ZIP format (v2) and the legacy JSON format (v1).
  Future<BackupResult> importBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip', 'json'],
    );

    if (result == null || result.files.single.path == null) {
      return BackupResult.cancelled;
    }

    return _importFromFile(File(result.files.single.path!));
  }

  /// Import the locally saved backup. Tries the new ZIP first, then the legacy
  /// JSON. Returns [BackupResult.notFound] if neither exists.
  Future<BackupResult> importLocalBackup() async {
    final dir = await _localBackupDir();
    final zipFile = File('${dir.path}/$_autoBackupFilename');
    if (await zipFile.exists()) return _importFromFile(zipFile);
    final jsonFile = File('${dir.path}/$_legacyAutoBackupFilename');
    if (await jsonFile.exists()) return _importFromFile(jsonFile);
    return BackupResult.notFound;
  }

  /// Returns the path of the local backup file (ZIP preferred, JSON fallback),
  /// or null if neither exists.
  Future<String?> localBackupPath() async {
    final dir = await _localBackupDir();
    final zip = File('${dir.path}/$_autoBackupFilename');
    if (await zip.exists()) return zip.path;
    final json = File('${dir.path}/$_legacyAutoBackupFilename');
    if (await json.exists()) return json.path;
    return null;
  }

  /// Dispatches to ZIP or JSON import based on the file's magic bytes — not
  /// extension, so a renamed file still works.
  Future<BackupResult> _importFromFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      // ZIP files always start with "PK\x03\x04" (or "PK\x05\x06" for empty).
      final isZip = bytes.length >= 2 && bytes[0] == 0x50 && bytes[1] == 0x4B;
      if (isZip) return _importFromZipBytes(bytes);
      // Fall back to legacy JSON.
      return _importFromJsonString(utf8.decode(bytes));
    } catch (_) {
      return BackupResult.error;
    }
  }

  /// v2 import: extracts photos to app documents dir, rewrites photo_path
  /// fields to point there, then performs the normal item/wear-day/wash insert.
  Future<BackupResult> _importFromZipBytes(List<int> bytes) async {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);

      ArchiveFile? jsonEntry;
      final photoEntries = <String, ArchiveFile>{};
      for (final entry in archive.files) {
        if (!entry.isFile) continue;
        if (entry.name == _backupJsonEntry) {
          jsonEntry = entry;
        } else if (entry.name.startsWith(_photosDirEntry)) {
          photoEntries[p.basename(entry.name)] = entry;
        }
      }
      if (jsonEntry == null) return BackupResult.invalidFormat;

      final json = jsonDecode(utf8.decode(jsonEntry.content as List<int>))
          as Map<String, dynamic>;
      final version = json['version'] as int?;
      // Accept both v2 (zipped) and the rare case of a v1 wrapped in a zip.
      if (version != 2 && version != 1) return BackupResult.invalidFormat;

      // Restore photos to the app's documents directory and build a
      // basename -> absolute-path map for rewriting Item entries.
      final docsDir = await getApplicationDocumentsDirectory();
      final restoredPhotoPaths = <String, String>{};
      for (final entry in photoEntries.entries) {
        final dest = File('${docsDir.path}/${entry.key}');
        // Don't overwrite an existing photo — the original is the source of
        // truth on the same device, and on a fresh device the file won't exist.
        if (!await dest.exists()) {
          await dest.writeAsBytes(entry.value.content as List<int>);
        }
        restoredPhotoPaths[entry.key] = dest.path;
      }

      final items = (json['items'] as List).map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        final stored = map['photo_path'] as String?;
        if (stored != null) {
          // v2 stores bare filenames; v1 stored absolute paths. For v1, take
          // basename so we can match it against any photos we did extract.
          final basename = p.basename(stored);
          map['photo_path'] = restoredPhotoPaths[basename];
        }
        return Item.fromJson(map);
      }).toList();

      final wearDays = (json['wearDays'] as List)
          .map((e) => WearDay.fromJson(e as Map<String, dynamic>))
          .toList();
      final washes = (json['washes'] as List)
          .map((e) => Wash.fromJson(e as Map<String, dynamic>))
          .toList();

      for (final item in items) {
        await _itemRepo.insert(item);
      }
      for (final wearDay in wearDays) {
        await _wearDayRepo.insert(wearDay);
      }
      for (final wash in washes) {
        await _washRepo.insert(wash);
      }
      return BackupResult.success;
    } catch (_) {
      return BackupResult.error;
    }
  }

  /// Legacy v1 import: no photos.
  Future<BackupResult> _importFromJsonString(String body) async {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final version = json['version'] as int?;
      if (version != 1) return BackupResult.invalidFormat;

      final items = (json['items'] as List)
          .map((e) => Item.fromJson(e as Map<String, dynamic>))
          .toList();
      final wearDays = (json['wearDays'] as List)
          .map((e) => WearDay.fromJson(e as Map<String, dynamic>))
          .toList();
      final washes = (json['washes'] as List)
          .map((e) => Wash.fromJson(e as Map<String, dynamic>))
          .toList();

      for (final item in items) {
        await _itemRepo.insert(item);
      }
      for (final wearDay in wearDays) {
        await _wearDayRepo.insert(wearDay);
      }
      for (final wash in washes) {
        await _washRepo.insert(wash);
      }
      return BackupResult.success;
    } catch (_) {
      return BackupResult.error;
    }
  }
}

enum BackupResult { success, cancelled, invalidFormat, notFound, error }
