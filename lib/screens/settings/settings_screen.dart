import 'package:flutter/material.dart';
import 'package:raw_denim_tracker/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/item.dart';
import '../../providers/item_providers.dart';
import '../../providers/settings_providers.dart';
import '../../providers/wear_day_providers.dart';
import '../../providers/wash_providers.dart';
import '../../repositories/item_repository.dart';
import '../../repositories/wear_day_repository.dart';
import '../../services/widget_service.dart';
import '../../repositories/wash_repository.dart';
import '../../services/backup_service.dart';
import '../../services/ha_service.dart';
import '../../services/sheets_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final sheetsEnabled = ref.watch(sheetsEnabledProvider);
    final spreadsheetId = ref.watch(sheetsSpreadsheetIdProvider);
    final widgetItemId = ref.watch(widgetSelectedItemIdProvider);
    final itemsAsync = ref.watch(itemsProvider);
    final categoriesEnabled = ref.watch(categoriesEnabledProvider);
    final locationEnabled = ref.watch(locationEnabledProvider);
    final defaultWashTemp = ref.watch(defaultWashTempProvider);
    final haEnabled = ref.watch(haEnabledProvider);
    final haUrl = ref.watch(haUrlProvider);
    final haToken = ref.watch(haTokenProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          // --- VOREINSTELLUNGEN ---
          _SectionHeader(l10n.preferences),
          itemsAsync.when(
            loading: () => const ListTile(title: Text('Loading...')),
            error: (_, __) => const SizedBox.shrink(),
            data: (items) => ListTile(
              leading: const Icon(Icons.widgets_outlined),
              title: Text(l10n.widgetItem),
              subtitle: Text(_itemLabel(items, widgetItemId) ?? l10n.none),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _pickWidgetItem(context, ref, items, widgetItemId),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.local_laundry_service_outlined),
            title: Text(l10n.defaultWashTemp),
            trailing: Text(
              '$defaultWashTemp °C',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            onTap: () => _editDefaultWashTemp(context, ref, defaultWashTemp),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.label_outline),
            title: Text(l10n.categoriesEnabled),
            value: categoriesEnabled,
            onChanged: (val) =>
                ref.read(categoriesEnabledProvider.notifier).set(val),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.location_on_outlined),
            title: Text(l10n.locationTrackingEnable),
            value: locationEnabled,
            onChanged: (val) =>
                ref.read(locationEnabledProvider.notifier).set(val),
          ),

          const Divider(),

          // --- BACKUP ---
          _SectionHeader(l10n.backupRestore),
          ListTile(
            leading: const Icon(Icons.upload_outlined),
            title: Text(l10n.exportBackup),
            onTap: () => _exportBackup(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.save_outlined),
            title: Text(l10n.saveBackupLocally),
            onTap: () => _saveBackupLocally(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: Text(l10n.importBackup),
            onTap: () => _importBackup(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.folder_open_outlined),
            title: Text(l10n.importLocalBackup),
            subtitle: Text(l10n.importLocalBackupHint),
            onTap: () => _importLocalBackup(context, ref),
          ),

          const Divider(),

          // --- GOOGLE SHEETS ---
          _SectionHeader(l10n.googleSheets),
          SwitchListTile(
            secondary: const Icon(Icons.table_chart_outlined),
            title: Text(l10n.enableSheetsSync),
            value: sheetsEnabled,
            onChanged: (val) => ref.read(sheetsEnabledProvider.notifier).set(val),
          ),
          if (sheetsEnabled) ...[
            ListTile(
              leading: const Icon(Icons.open_in_new_outlined),
              title: Text(spreadsheetId != null ? l10n.spreadsheetLinked : l10n.createSpreadsheet),
              subtitle: spreadsheetId != null
                  ? Text(spreadsheetId, overflow: TextOverflow.ellipsis)
                  : null,
              onTap: () => _setupSheets(context, ref),
            ),
            if (spreadsheetId != null)
              ListTile(
                leading: const Icon(Icons.sync_outlined),
                title: Text(l10n.syncNow),
                onTap: () => _syncNow(context, ref),
              ),
            if (spreadsheetId != null)
              ListTile(
                leading: Icon(Icons.link_off_outlined,
                    color: Theme.of(context).colorScheme.error),
                title: Text(l10n.unlinkSpreadsheet,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error)),
                onTap: () => _unlinkSpreadsheet(context, ref),
              ),
          ],

          const Divider(),

          // --- HOME ASSISTANT ---
          _SectionHeader(l10n.homeAssistant),
          SwitchListTile(
            secondary: const Icon(Icons.home_outlined),
            title: Text(l10n.haEnable),
            value: haEnabled,
            onChanged: (val) => ref.read(haEnabledProvider.notifier).set(val),
          ),
          if (haEnabled) ...[
            ListTile(
              leading: const Icon(Icons.settings_ethernet_outlined),
              title: Text(l10n.haConfigureConnection),
              subtitle: Text(
                haUrl ?? l10n.haNotConfigured,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: haUrl != null && haToken != null
                  ? Icon(Icons.check_circle_outline,
                      color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () => _configureHa(context, ref, haUrl, haToken),
            ),
            if (haUrl != null && haToken != null)
              ListTile(
                leading: const Icon(Icons.send_outlined),
                title: Text(l10n.haSendNow),
                onTap: () => _sendToHaNow(context, ref, haUrl, haToken),
              ),
          ],
        ],
      ),
    );
  }

  String? _itemLabel(List<Item> items, String? id) {
    if (id == null) return null;
    final item = items.where((i) => i.id == id).firstOrNull;
    return item != null ? '${item.brand} ${item.model}' : null;
  }

  Future<void> _pickWidgetItem(
      BuildContext context, WidgetRef ref, List<Item> items, String? current) async {
    final l10n = AppLocalizations.of(context)!;
    final selected = await showDialog<String?>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.selectWidgetItem),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(l10n.none),
          ),
          ...items.map((item) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, item.id),
                child: Text('${item.brand} ${item.model}'),
              )),
        ],
      ),
    );
    if (context.mounted) {
      await ref.read(widgetSelectedItemIdProvider.notifier).setItemId(selected);
      await WidgetService.updateWidget(selected);
    }
  }

  BackupService _backupService(WidgetRef ref) => BackupService(
        itemRepo: ref.read(itemRepositoryProvider),
        wearDayRepo: ref.read(wearDayRepositoryProvider),
        washRepo: ref.read(washRepositoryProvider),
      );

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    try {
      await _backupService(ref).exportBackup();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _saveBackupLocally(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final path = await _backupService(ref).saveLocalBackup();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.savedTo}: $path'), duration: const Duration(seconds: 6)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    }
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await _backupService(ref).importBackup();
    if (context.mounted) _showImportResult(context, ref, l10n, result);
  }

  Future<void> _importLocalBackup(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final svc = _backupService(ref);
    final path = await svc.localBackupPath();
    if (!context.mounted) return;
    // Show the path and ask for confirmation before overwriting current data.
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.importLocalBackup),
        content: Text(path != null
            ? '${l10n.importLocalBackupConfirm}\n\n$path'
            : l10n.importLocalBackupNotFound),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          if (path != null)
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.importBackup),
            ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result = await svc.importLocalBackup();
    if (context.mounted) _showImportResult(context, ref, l10n, result);
  }

  void _showImportResult(
      BuildContext context, WidgetRef ref, AppLocalizations l10n, BackupResult result) {
    final msg = switch (result) {
      BackupResult.success => l10n.importSuccess,
      BackupResult.cancelled => null,
      BackupResult.invalidFormat => l10n.importInvalidFormat,
      BackupResult.notFound => l10n.importLocalBackupNotFound,
      BackupResult.error => l10n.importError,
    };
    if (msg != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
    if (result == BackupResult.success) {
      ref.invalidate(itemsProvider);
    }
  }

  Future<void> _unlinkSpreadsheet(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.unlinkSpreadsheet),
        content: Text(l10n.unlinkSpreadsheetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.unlinkSpreadsheet),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(sheetsSpreadsheetIdProvider.notifier).set(null);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.spreadsheetUnlinked)),
        );
      }
    }
  }

  Future<void> _setupSheets(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final existingId = ref.read(sheetsSpreadsheetIdProvider);
    try {
      await SheetsService.signIn();
      if (existingId != null) {
        // Already linked — just re-authenticate, keep the existing spreadsheet.
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.spreadsheetLinked)),
          );
        }
        return;
      }
      final id = await SheetsService.createSpreadsheet('Raw Denim Tracker');
      if (context.mounted) {
        await ref.read(sheetsSpreadsheetIdProvider.notifier).set(id);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.spreadsheetCreated)));
      }
    } catch (e, stack) {
      if (context.mounted) {
        await showDialog(
          context: context,
          useRootNavigator: true,
          builder: (ctx) => AlertDialog(
            title: const Text('Google Sheets Fehler'),
            content: SingleChildScrollView(
              child: SelectableText('$e\n\n$stack'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _editDefaultWashTemp(
      BuildContext context, WidgetRef ref, int current) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: current.toString());
    final result = await showDialog<int>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.defaultWashTemp),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            suffixText: '°C',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, int.tryParse(controller.text)),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null && result > 0 && context.mounted) {
      await ref.read(defaultWashTempProvider.notifier).set(result);
    }
  }

  Future<void> _sendToHaNow(
      BuildContext context, WidgetRef ref, String haUrl, String haToken) async {
    final l10n = AppLocalizations.of(context)!;
    // Find the most recently worn item across all items.
    final lastWornDates = await ref.read(wearDayRepositoryProvider).getLastWornDates();
    if (lastWornDates.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.haSendNowFailed)));
      }
      return;
    }
    // Pick the item worn most recently.
    final latestEntry = lastWornDates.entries.reduce(
        (a, b) => a.value.isAfter(b.value) ? a : b);
    final itemId = latestEntry.key;
    final item = await ref.read(itemRepositoryProvider).getById(itemId);
    if (item == null) return;
    final tracked = await ref.read(wearDayRepositoryProvider).countByItemId(itemId);
    final totalDays = item.baseWearCount + tracked;
    final ok = await HaService.updateCurrentItem(
      haUrl: haUrl,
      token: haToken,
      itemName: '${item.brand} ${item.model}',
      wearDays: totalDays,
    ).catchError((_) => false);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? l10n.haSendNowSuccess : l10n.haConnectionFailed),
      ));
    }
  }

  Future<void> _configureHa(
      BuildContext context, WidgetRef ref, String? currentUrl, String? currentToken) async {
    final l10n = AppLocalizations.of(context)!;
    final urlController = TextEditingController(text: currentUrl ?? '');
    final tokenController = TextEditingController(text: currentToken ?? '');
    bool testing = false;

    await showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l10n.homeAssistant),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: urlController,
                decoration: InputDecoration(
                  labelText: l10n.haUrl,
                  hintText: l10n.haUrlHint,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
                autocorrect: false,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tokenController,
                decoration: InputDecoration(
                  labelText: l10n.haToken,
                  hintText: l10n.haTokenHint,
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
                autocorrect: false,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: testing
                      ? null
                      : () async {
                          setState(() => testing = true);
                          final ok = await HaService.testConnection(
                            haUrl: urlController.text.trim(),
                            token: tokenController.text.trim(),
                          ).catchError((_) => false);
                          setState(() => testing = false);
                          if (!ctx.mounted) return;
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                            content: Text(ok
                                ? l10n.haConnectionSuccess
                                : l10n.haConnectionFailed),
                          ));
                        },
                  icon: testing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.wifi_tethering_outlined),
                  label: Text(l10n.haTestConnection),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () async {
                await ref.read(haUrlProvider.notifier).set(urlController.text.trim());
                await ref.read(haTokenProvider.notifier).set(tokenController.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(l10n.haSave),
            ),
          ],
        ),
      ),
    );

    urlController.dispose();
    tokenController.dispose();
  }

  Future<void> _syncNow(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final spreadsheetId = ref.read(sheetsSpreadsheetIdProvider);
    if (spreadsheetId == null) return;

    try {
      final items = await ref.read(itemRepositoryProvider).getAll();
      final wearDays = await ref.read(wearDayRepositoryProvider).getAll();
      final washes = await ref.read(washRepositoryProvider).getAll();
      final trackedCounts = await ref.read(wearDayRepositoryProvider).getAllTrackedCounts();

      await SheetsService.syncAll(
        spreadsheetId: spreadsheetId,
        items: items,
        wearDays: wearDays,
        washes: washes,
        trackedCounts: trackedCounts,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.syncSuccess)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Sync failed: $e')));
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      );
}
