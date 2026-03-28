import 'package:flutter/material.dart';
import 'package:raw_denim_tracker/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/wear_day.dart';
import '../../providers/item_providers.dart';
import '../../providers/wear_day_providers.dart';

class WearDaysTab extends ConsumerStatefulWidget {
  final String itemId;
  const WearDaysTab({super.key, required this.itemId});

  @override
  ConsumerState<WearDaysTab> createState() => _WearDaysTabState();
}

class _WearDaysTabState extends ConsumerState<WearDaysTab> {
  Future<void> _addWearDay() async {
    final date = await showDatePicker(
      context: context,
      useRootNavigator: true,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    await ref.read(wearDayActionsProvider).addWearDay(widget.itemId, date);
  }

  Future<void> _editBaseCount(int current) async {
    final result = await showDialog<int>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => _EditBaseCountDialog(initial: current),
    );
    if (result != null && mounted) {
      await ref
          .read(wearDayActionsProvider)
          .setBaseWearCount(widget.itemId, result);
    }
  }

  Future<void> _showBulkDialog() async {
    final result = await showDialog<int>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => const _BulkCountDialog(),
    );
    if (result != null && result > 0 && mounted) {
      final current =
          ref.read(itemProvider(widget.itemId)).asData?.value?.baseWearCount ??
              0;
      await ref
          .read(wearDayActionsProvider)
          .setBaseWearCount(widget.itemId, current + result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wearDaysAsync = ref.watch(wearDaysProvider(widget.itemId));
    final itemAsync = ref.watch(itemProvider(widget.itemId));
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      children: [
        wearDaysAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (wearDays) {
            final baseCount = itemAsync.value?.baseWearCount ?? 0;
            return ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                if (baseCount > 0)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.tertiaryContainer,
                      child: Icon(Icons.history_outlined,
                          color: Theme.of(context)
                              .colorScheme
                              .onTertiaryContainer,
                          size: 20),
                    ),
                    title: Text(l10n.historicalDays),
                    subtitle: Text(l10n.historicalDaysSubtitle),
                    trailing: Text(
                      '+$baseCount',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.tertiary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    onTap: () => _editBaseCount(baseCount),
                  ),
                if (baseCount > 0 && wearDays.isNotEmpty) const Divider(),
                if (wearDays.isEmpty && baseCount == 0)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(l10n.noWearDaysYet,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              )),
                    ),
                  ),
                ...wearDays.map(
                    (w) => _WearDayTile(wearDay: w, itemId: widget.itemId)),
              ],
            );
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton.small(
                heroTag: 'bulk_fab',
                onPressed: _showBulkDialog,
                tooltip: l10n.addHistoricalDays,
                child: const Icon(Icons.more_time_outlined),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.extended(
                heroTag: 'wear_day_fab',
                onPressed: _addWearDay,
                icon: const Icon(Icons.add),
                label: Text(l10n.addWearDay),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WearDayTile extends ConsumerStatefulWidget {
  final WearDay wearDay;
  final String itemId;
  const _WearDayTile({required this.wearDay, required this.itemId});

  @override
  ConsumerState<_WearDayTile> createState() => _WearDayTileState();
}

class _WearDayTileState extends ConsumerState<_WearDayTile> {
  Future<void> _editDate() async {
    final date = await showDatePicker(
      context: context,
      useRootNavigator: true,
      initialDate: widget.wearDay.date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    await ref
        .read(wearDayActionsProvider)
        .updateWearDay(widget.itemId, widget.wearDay.copyWith(date: date));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(Icons.today_outlined,
            color: Theme.of(context).colorScheme.onPrimaryContainer, size: 20),
      ),
      title: Text(DateFormat.yMMMMd(Localizations.localeOf(context).languageCode).format(widget.wearDay.date)),
      trailing: PopupMenuButton<String>(
        onSelected: (value) async {
          if (value == 'edit') {
            await _editDate();
          } else if (value == 'delete') {
            await ref
                .read(wearDayActionsProvider)
                .deleteWearDay(widget.itemId, widget.wearDay.id);
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
          PopupMenuItem(
            value: 'delete',
            child: Text(l10n.delete,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dialog widgets — own their TextEditingController via initState/dispose so
// the controller is never disposed while the TextField is still alive.
// ---------------------------------------------------------------------------

class _EditBaseCountDialog extends StatefulWidget {
  final int initial;
  const _EditBaseCountDialog({required this.initial});
  @override
  State<_EditBaseCountDialog> createState() => _EditBaseCountDialogState();
}

class _EditBaseCountDialogState extends State<_EditBaseCountDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.historicalDays),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: l10n.historicalDaysLabel,
          border: const OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(context, int.tryParse(_controller.text)),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

class _BulkCountDialog extends StatefulWidget {
  const _BulkCountDialog();
  @override
  State<_BulkCountDialog> createState() => _BulkCountDialogState();
}

class _BulkCountDialogState extends State<_BulkCountDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.addHistoricalDays),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.addHistoricalDaysHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.addHistoricalDaysLabel,
              border: const OutlineInputBorder(),
              suffixText: l10n.days,
            ),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, int.tryParse(_controller.text)),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
