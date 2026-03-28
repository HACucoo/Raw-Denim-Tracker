import 'package:flutter/material.dart';
import 'package:raw_denim_tracker/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/wash.dart';
import '../../providers/wash_providers.dart';
import '../../providers/wear_day_providers.dart';

class WashesTab extends ConsumerStatefulWidget {
  final String itemId;
  const WashesTab({super.key, required this.itemId});

  @override
  ConsumerState<WashesTab> createState() => _WashesTabState();
}

class _WashesTabState extends ConsumerState<WashesTab> {
  Future<void> _addWash() async {
    final result = await showDialog<({DateTime date, int temp, int? wearDays})>(
      context: context,
      useRootNavigator: true,
      builder: (_) => _WashDialog(
        getWearDayCount: () =>
            ref.read(wearDayCountProvider(widget.itemId).future),
      ),
    );
    if (result == null || !mounted) return;
    await ref.read(washActionsProvider).addWash(
          widget.itemId,
          date: result.date,
          tempCelsius: result.temp,
          wearDaysAtWash: result.wearDays,
        );
  }

  @override
  Widget build(BuildContext context) {
    final washesAsync = ref.watch(washesProvider(widget.itemId));
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      children: [
        washesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (washes) {
            if (washes.isEmpty) {
              return Center(
                child: Text(l10n.noWashesYet,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        )),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: washes.length,
              itemBuilder: (context, index) =>
                  _WashTile(wash: washes[index], itemId: widget.itemId),
            );
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            heroTag: 'wash_fab',
            onPressed: _addWash,
            icon: const Icon(Icons.local_laundry_service_outlined),
            label: Text(AppLocalizations.of(context)!.addWash),
          ),
        ),
      ],
    );
  }
}

class _WashTile extends ConsumerStatefulWidget {
  final Wash wash;
  final String itemId;
  const _WashTile({required this.wash, required this.itemId});

  @override
  ConsumerState<_WashTile> createState() => _WashTileState();
}

class _WashTileState extends ConsumerState<_WashTile> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final subtitleParts = ['${widget.wash.tempCelsius}°C'];
    if (widget.wash.wearDaysAtWash != null) {
      subtitleParts.add('${widget.wash.wearDaysAtWash} ${l10n.days}');
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colorScheme.secondaryContainer,
        child: Icon(Icons.local_laundry_service_outlined,
            color: colorScheme.onSecondaryContainer, size: 20),
      ),
      title: Text(DateFormat.yMMMMd(
              Localizations.localeOf(context).languageCode)
          .format(widget.wash.date)),
      subtitle: Text(subtitleParts.join(' · ')),
      trailing: PopupMenuButton<String>(
        onSelected: (value) async {
          if (value == 'edit') {
            final result =
                await showDialog<({DateTime date, int temp, int? wearDays})>(
              context: context,
              useRootNavigator: true,
              builder: (_) => _WashDialog(
                initialDate: widget.wash.date,
                initialTemp: widget.wash.tempCelsius,
                initialWearDays: widget.wash.wearDaysAtWash,
                getWearDayCount: () =>
                    ref.read(wearDayCountProvider(widget.itemId).future),
              ),
            );
            if (result != null && mounted) {
              await ref.read(washActionsProvider).updateWash(
                    widget.itemId,
                    widget.wash.copyWith(
                      date: result.date,
                      tempCelsius: result.temp,
                      wearDaysAtWash: result.wearDays,
                    ),
                  );
            }
          } else if (value == 'delete') {
            await ref
                .read(washActionsProvider)
                .deleteWash(widget.itemId, widget.wash.id);
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
          PopupMenuItem(
            value: 'delete',
            child: Text(l10n.delete,
                style: TextStyle(color: colorScheme.error)),
          ),
        ],
      ),
    );
  }
}

class _WashDialog extends StatefulWidget {
  final DateTime? initialDate;
  final int? initialTemp;
  final int? initialWearDays;
  final Future<int> Function() getWearDayCount;

  const _WashDialog({
    this.initialDate,
    this.initialTemp,
    this.initialWearDays,
    required this.getWearDayCount,
  });

  @override
  State<_WashDialog> createState() => _WashDialogState();
}

class _WashDialogState extends State<_WashDialog> {
  late DateTime _date;
  late TextEditingController _tempController;
  late TextEditingController _wearDaysController;
  bool _loadingWearDays = false;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? DateTime.now();
    _tempController = TextEditingController(
      text: widget.initialTemp?.toString() ?? '30',
    );
    _wearDaysController = TextEditingController(
      text: widget.initialWearDays?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _tempController.dispose();
    _wearDaysController.dispose();
    super.dispose();
  }

  Future<void> _autoFillWearDays() async {
    if (_wearDaysController.text.isNotEmpty) return;
    setState(() => _loadingWearDays = true);
    try {
      final count = await widget.getWearDayCount();
      if (mounted && _wearDaysController.text.isEmpty) {
        _wearDaysController.value = TextEditingValue(
          text: count.toString(),
          selection: TextSelection(
            baseOffset: 0,
            extentOffset: count.toString().length,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingWearDays = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.addWash),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (date != null && mounted) setState(() => _date = date);
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.date,
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.calendar_today_outlined),
              ),
              child: Text(DateFormat.yMMMMd(
                      Localizations.localeOf(context).languageCode)
                  .format(_date)),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _tempController,
            decoration: InputDecoration(
              labelText: l10n.temperature,
              border: const OutlineInputBorder(),
              suffixText: '°C',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _wearDaysController,
            decoration: InputDecoration(
              labelText: l10n.wearDaysAtWash,
              border: const OutlineInputBorder(),
              hintText: l10n.wearDaysAtWashHint,
              suffixIcon: _loadingWearDays
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
            keyboardType: TextInputType.number,
            onTap: _autoFillWearDays,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () {
            final temp = int.tryParse(_tempController.text);
            if (temp == null) return;
            final wearDays = _wearDaysController.text.isEmpty
                ? null
                : int.tryParse(_wearDaysController.text);
            Navigator.pop(
                context, (date: _date, temp: temp, wearDays: wearDays));
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
