import 'package:flutter/material.dart';
import 'package:raw_denim_tracker/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/item.dart';
import '../../providers/item_providers.dart';
import '../../providers/wear_day_providers.dart';
import '../../services/nfc_service.dart';
import '../../widgets/garment_photo.dart';
import 'wear_days_tab.dart';
import 'washes_tab.dart';

/// ItemDetailScreen uses a stable widget tree so that DefaultTabController
/// (and its InheritedWidget) are NEVER unmounted while children still hold
/// dependencies. The Scaffold+DefaultTabController are always in the tree;
/// only the content inside responds to the async item state.
class ItemDetailScreen extends ConsumerStatefulWidget {
  final String itemId;
  const ItemDetailScreen({super.key, required this.itemId});

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen>
    with SingleTickerProviderStateMixin {
  /// Explicit TabController — owned by the State, not by a widget tree.
  /// Eliminates DefaultTabController (InheritedWidget) entirely, which was
  /// the source of the _dependents.isEmpty assertion crash.
  late TabController _tabController;

  /// Cached item — never goes back to null once set.
  Item? _item;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<bool> _confirmDelete(AppLocalizations l10n) async {
    return await showDialog<bool>(
          context: context,
          useRootNavigator: true,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.deleteItem),
            content: Text(l10n.deleteItemConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.delete,
                    style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _nfcButtonPressed(Item item) {
    if (item.nfcTagId == null) {
      context.push('/item/${widget.itemId}/nfc');
      return;
    }

    // Tag already linked — offer manage options.
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.nfc),
              title: Text(l10n.relinkNfcTag),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/item/${widget.itemId}/nfc');
              },
            ),
            ListTile(
              leading: Icon(Icons.link_off,
                  color: Theme.of(ctx).colorScheme.error),
              title: Text(l10n.unlinkNfcTag,
                  style:
                      TextStyle(color: Theme.of(ctx).colorScheme.error)),
              onTap: () async {
                Navigator.pop(ctx);
                final confirmed = await showDialog<bool>(
                  context: context,
                  useRootNavigator: true,
                  builder: (dctx) => AlertDialog(
                    title: Text(l10n.unlinkNfcTag),
                    content: Text(l10n.unlinkNfcTagConfirm),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dctx, false),
                        child: Text(l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dctx, true),
                        child: Text(l10n.delete,
                            style: TextStyle(
                                color: Theme.of(dctx).colorScheme.error)),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && mounted) {
                  await ref
                      .read(itemsProvider.notifier)
                      .unlinkNfcTag(widget.itemId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.nfcTagUnlinked)),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemAsync = ref.watch(itemProvider(widget.itemId));
    final l10n = AppLocalizations.of(context)!;

    // Update cache whenever fresh data is available.
    // _item NEVER goes back to null, so DefaultTabController stays mounted
    // even while itemProvider is in AsyncLoading (e.g. after invalidation).
    final fresh = itemAsync.asData?.value;
    if (fresh != null) _item = fresh;
    final item = _item;

    // Show bare loading/error screen only on the very first load (no data yet).
    if (item == null) {
      if (itemAsync.hasError) {
        return Scaffold(
          appBar: AppBar(),
          body: Center(child: Text('Fehler: ${itemAsync.error}')),
        );
      }
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: Text(
          '${item.brand} ${item.model}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.nfc),
            tooltip: item.nfcTagId != null
                ? l10n.scanNfcAddWearDay
                : l10n.linkNfcTag,
            onPressed: () => _nfcButtonPressed(item),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                context.push('/item/${widget.itemId}/edit');
              } else if (value == 'delete') {
                final confirmed = await _confirmDelete(l10n);
                if (confirmed && mounted) {
                  await ref
                      .read(itemsProvider.notifier)
                      .deleteItem(widget.itemId);
                  if (mounted) context.pop();
                }
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
              PopupMenuItem(
                value: 'delete',
                child: Text(l10n.delete,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error)),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.wearDays),
            Tab(text: l10n.washes),
          ],
        ),
      ),
      body: Column(
        children: [
          _ItemHeader(itemId: widget.itemId, item: item),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                WearDaysTab(itemId: widget.itemId),
                WashesTab(itemId: widget.itemId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemHeader extends ConsumerWidget {
  final String itemId;
  final Item item;
  const _ItemHeader({required this.itemId, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(wearDayCountProvider(itemId));
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      color: colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          GarmentPhoto(photoPath: item.photoPath, size: 80, borderRadius: 10),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.brand} ${item.model}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (item.size.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(item.size,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.outline,
                          )),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 14, color: colorScheme.primary),
                    const SizedBox(width: 4),
                    countAsync.when(
                      loading: () => const SizedBox(width: 40, height: 14),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (count) => Text(
                        l10n.daysWorn(count),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${l10n.firstWearDate}: ${DateFormat.yMMMMd(Localizations.localeOf(context).languageCode).format(item.firstWearDate)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                ),
                if (item.nfcTagId != null)
                  Row(
                    children: [
                      Icon(Icons.nfc, size: 14, color: colorScheme.secondary),
                      const SizedBox(width: 4),
                      Text(l10n.nfcLinked,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.secondary,
                              )),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
