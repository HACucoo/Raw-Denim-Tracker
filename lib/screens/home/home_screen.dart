import 'dart:io';
import 'package:flutter/material.dart';
import 'package:raw_denim_tracker/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/item.dart';
import '../../providers/sort_providers.dart';
import 'item_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final Set<String> _precached = {};

  void _precachePhotos(BuildContext context, List<Item> items) {
    for (final item in items) {
      final path = item.photoPath;
      if (path == null || _precached.contains(path)) continue;
      _precached.add(path);
      // Decode at thumbnail size (same cacheWidth as GarmentPhoto uses for 72 px).
      precacheImage(
        ResizeImage(FileImage(File(path)), width: 216, height: 216),
        context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(sortedItemsProvider);
    final sortOrder = ref.watch(sortOrderProvider);
    final sortDirection = ref.watch(sortDirectionProvider);
    final latestOnTop = ref.watch(latestOnTopProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          PopupMenuButton<Object>(
            icon: const Icon(Icons.sort),
            tooltip: l10n.sortBy,
            onSelected: (value) {
              if (value is _ToggleLatestOnTop) {
                ref.read(latestOnTopProvider.notifier).toggle();
              } else if (value is SortOrder) {
                if (value == sortOrder) {
                  ref.read(sortDirectionProvider.notifier).toggle();
                } else {
                  ref.read(sortOrderProvider.notifier).set(value);
                  ref.read(sortDirectionProvider.notifier).setDescending();
                }
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: SortOrder.firstWearDate,
                child: _SortItem(
                  icon: Icons.calendar_today_outlined,
                  label: l10n.sortByDate,
                  selected: sortOrder == SortOrder.firstWearDate,
                  direction: sortDirection,
                ),
              ),
              PopupMenuItem(
                value: SortOrder.wearCount,
                child: _SortItem(
                  icon: Icons.format_list_numbered,
                  label: l10n.sortByWearCount,
                  selected: sortOrder == SortOrder.wearCount,
                  direction: sortDirection,
                ),
              ),
              PopupMenuItem(
                value: SortOrder.brand,
                child: _SortItem(
                  icon: Icons.sort_by_alpha,
                  label: l10n.sortByBrand,
                  selected: sortOrder == SortOrder.brand,
                  direction: sortDirection,
                ),
              ),
              PopupMenuItem(
                value: SortOrder.lastWorn,
                child: _SortItem(
                  icon: Icons.access_time_outlined,
                  label: l10n.sortByLastWorn,
                  selected: sortOrder == SortOrder.lastWorn,
                  direction: sortDirection,
                ),
              ),
              const PopupMenuDivider(),
              CheckedPopupMenuItem<Object>(
                value: const _ToggleLatestOnTop(),
                checked: latestOnTop,
                child: Text(l10n.latestOnTop),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.checkroom_outlined,
                      size: 64, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(l10n.noItemsYet,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(l10n.addFirstItem,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          )),
                ],
              ),
            );
          }
          _precachePhotos(context, items);
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, index) => ItemCard(item: items[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/item/new'),
        tooltip: l10n.addItem,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Immutable sentinel — const-safe.
class _ToggleLatestOnTop {
  const _ToggleLatestOnTop();
  @override
  bool operator ==(Object other) => other is _ToggleLatestOnTop;
  @override
  int get hashCode => runtimeType.hashCode;
}

class _SortItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final SortDirection direction;
  const _SortItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.direction,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon,
              size: 18,
              color: selected ? Theme.of(context).colorScheme.primary : null),
          const SizedBox(width: 10),
          Text(label,
              style: selected
                  ? TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600)
                  : null),
          if (selected) ...[
            const Spacer(),
            Icon(
              direction == SortDirection.ascending
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ],
      );
}
