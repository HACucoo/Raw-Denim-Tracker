import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'providers/item_providers.dart';
import 'repositories/item_repository.dart';
import 'repositories/wear_day_repository.dart';
import 'repositories/wash_repository.dart';
import 'services/backup_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: RawDenimApp()));
  _scheduleAutoBackup();
}

/// Runs the weekly auto-backup check in the background after the app starts.
void _scheduleAutoBackup() {
  Future.microtask(() async {
    try {
      final svc = BackupService(
        itemRepo: ItemRepository(),
        wearDayRepo: WearDayRepository(),
        washRepo: WashRepository(),
      );
      await svc.autoBackupIfNeeded();
    } catch (_) {
      // Auto-backup is best-effort; never crash the app over it.
    }
  });
}
