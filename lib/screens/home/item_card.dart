import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../models/item.dart';
import '../../providers/wear_day_providers.dart';
import '../../widgets/garment_photo.dart';

String _fmtDate(DateTime date, BuildContext context) =>
    DateFormat.yMMMMd(Localizations.localeOf(context).languageCode).format(date);

class ItemCard extends ConsumerWidget {
  final Item item;
  const ItemCard({super.key, required this.item});

  Future<void> _addToday(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final name = '${item.brand} ${item.model}';
    final added = await ref.read(wearDayActionsProvider).addWearDay(item.id, DateTime.now());
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(added ? l10n.nfcWearDayAdded(name) : l10n.nfcAlreadyWornToday(name)),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(wearDayCountProvider(item.id));
    final lastDateAsync = ref.watch(lastWearDateProvider(item.id));
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/item/${item.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              GarmentPhoto(photoPath: item.photoPath, size: 72),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.brand} ${item.model}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (item.size.isNotEmpty) ...[
                          Text(
                            item.size,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colorScheme.outline,
                                ),
                          ),
                          Text(
                            ' · ',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colorScheme.outline,
                                ),
                          ),
                        ],
                        Text(
                          _fmtDate(item.firstWearDate, context),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                    if (item.trackWearDays) const SizedBox(height: 6),
                    if (item.trackWearDays) countAsync.when(
                      loading: () => const SizedBox(height: 20),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (count) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 14, color: colorScheme.primary),
                              const SizedBox(width: 4),
                              Text(
                                l10n.daysWorn(count),
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              lastDateAsync.whenOrNull(
                                data: (date) => date != null
                                    ? Text(
                                        '  (${_fmtDate(date, context)})',
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                              color: colorScheme.outline,
                                            ),
                                      )
                                    : null,
                              ) ?? const SizedBox.shrink(),
                              if (item.nfcTagId != null) ...[
                                const SizedBox(width: 10),
                                Icon(Icons.nfc, size: 14, color: colorScheme.secondary),
                              ],
                            ],
                          ),
                          lastDateAsync.when(
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                            data: (date) {
                              final today = DateTime.now();
                              final alreadyToday = date != null &&
                                  date.year == today.year &&
                                  date.month == today.month &&
                                  date.day == today.day;
                              if (alreadyToday) return const SizedBox.shrink();
                              return GestureDetector(
                                onTap: () => _addToday(context, ref),
                                child: Text(
                                  l10n.addWearDay,
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: colorScheme.primary,
                                        decoration: TextDecoration.underline,
                                        decorationColor: colorScheme.primary,
                                      ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
