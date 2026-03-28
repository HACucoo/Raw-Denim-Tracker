import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
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
const _autoBackupFilename = 'denim_backup.json';

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

  Future<Map<String, dynamic>> _buildBackupData() async {
    final items = await _itemRepo.getAll();
    final wearDays = await _wearDayRepo.getAll();
    final washes = await _washRepo.getAll();
    return {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'items': items.map((i) => i.toJson()).toList(),
      'wearDays': wearDays.map((w) => w.toJson()).toList(),
      'washes': washes.map((w) => w.toJson()).toList(),
    };
  }

  /// Share backup via the system share sheet.
  Future<void> exportBackup() async {
    final json = const JsonEncoder.withIndent('  ').convert(await _buildBackupData());
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
    final file = File('${dir.path}/denim_backup_$timestamp.json');
    await file.writeAsString(json);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'Raw Denim Tracker Backup',
    );
  }

  /// Save backup directly to app-specific external storage.
  /// Returns the file path, or throws on error.
  Future<String> saveLocalBackup() async {
    final json = const JsonEncoder.withIndent('  ').convert(await _buildBackupData());
    final dir = await _localBackupDir();
    final file = File('${dir.path}/$_autoBackupFilename');
    await file.writeAsString(json);
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

  /// Import from any JSON file chosen via the system file picker.
  Future<BackupResult> importBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) {
      return BackupResult.cancelled;
    }

    return _importFromFile(File(result.files.single.path!));
  }

  /// Import directly from the locally saved backup file (same path used by
  /// [saveLocalBackup] / weekly auto-backup). Returns [BackupResult.notFound]
  /// if no local backup exists yet.
  Future<BackupResult> importLocalBackup() async {
    final dir = await _localBackupDir();
    final file = File('${dir.path}/$_autoBackupFilename');
    if (!await file.exists()) return BackupResult.notFound;
    return _importFromFile(file);
  }

  /// Returns the path of the local backup file, or null if it doesn't exist.
  Future<String?> localBackupPath() async {
    final dir = await _localBackupDir();
    final file = File('${dir.path}/$_autoBackupFilename');
    return await file.exists() ? file.path : null;
  }

  Future<BackupResult> _importFromFile(File file) async {
    try {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;

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
    } catch (e) {
      return BackupResult.error;
    }
  }
}

enum BackupResult { success, cancelled, invalidFormat, notFound, error }
