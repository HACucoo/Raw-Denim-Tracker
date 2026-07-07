import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item.dart';
import '../repositories/wear_day_repository.dart';
import 'item_providers.dart';
import 'settings_providers.dart';

final categoryFilterProvider =
    NotifierProvider<CategoryFilterNotifier, ItemCategory?>(CategoryFilterNotifier.new);

class CategoryFilterNotifier extends Notifier<ItemCategory?> {
  @override
  ItemCategory? build() => null;
  void set(ItemCategory? value) => state = value;
}

enum SortOrder { firstWearDate, wearCount, brand, lastWorn }

enum SortDirection { ascending, descending }

final sortOrderProvider =
    NotifierProvider<SortOrderNotifier, SortOrder>(SortOrderNotifier.new);

class SortOrderNotifier extends Notifier<SortOrder> {
  static const _key = 'sort_order';

  @override
  SortOrder build() {
    Future.microtask(_load);
    return SortOrder.firstWearDate;
  }

  Future<void> _load() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final stored = prefs.getString(_key);
    state = SortOrder.values.asNameMap()[stored] ?? SortOrder.firstWearDate;
  }

  Future<void> set(SortOrder value) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_key, value.name);
    state = value;
  }
}

final sortDirectionProvider =
    NotifierProvider<SortDirectionNotifier, SortDirection>(SortDirectionNotifier.new);

class SortDirectionNotifier extends Notifier<SortDirection> {
  static const _key = 'sort_direction';

  @override
  SortDirection build() {
    Future.microtask(_load);
    return SortDirection.descending;
  }

  Future<void> _load() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final stored = prefs.getString(_key);
    state = SortDirection.values.asNameMap()[stored] ?? SortDirection.descending;
  }

  Future<void> toggle() => _set(state == SortDirection.ascending
      ? SortDirection.descending
      : SortDirection.ascending);

  Future<void> setDescending() => _set(SortDirection.descending);

  Future<void> _set(SortDirection value) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_key, value.name);
    state = value;
  }
}

/// When true, the most recently worn item is always pinned at the top,
/// regardless of the active sort order.
final latestOnTopProvider =
    NotifierProvider<LatestOnTopNotifier, bool>(LatestOnTopNotifier.new);

class LatestOnTopNotifier extends Notifier<bool> {
  static const _key = 'sort_latest_on_top';

  @override
  bool build() {
    Future.microtask(_load);
    return false;
  }

  Future<void> _load() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> toggle() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final value = !state;
    await prefs.setBool(_key, value);
    state = value;
  }
}

/// Items sorted according to [sortOrderProvider] and [sortDirectionProvider],
/// with optional [latestOnTopProvider] pin and [categoryFilterProvider] filter.
final sortedItemsProvider = FutureProvider<List<Item>>((ref) async {
  final itemsAsync = await ref.watch(itemsProvider.future);
  final sortOrder = ref.watch(sortOrderProvider);
  final sortDirection = ref.watch(sortDirectionProvider);
  final latestOnTop = ref.watch(latestOnTopProvider);
  final categoryFilter = ref.watch(categoryFilterProvider);
  var items = List<Item>.from(itemsAsync);
  if (categoryFilter != null) {
    items = items.where((i) => i.category == categoryFilter).toList();
  }

  final repo = WearDayRepository();

  Map<String, int> trackedCounts = {};
  Map<String, DateTime> lastWornDates = {};

  if (sortOrder == SortOrder.wearCount) {
    trackedCounts = await repo.getAllTrackedCounts();
  }
  if (sortOrder == SortOrder.lastWorn || latestOnTop) {
    lastWornDates = await repo.getLastWornDates();
  }

  final asc = sortDirection == SortDirection.ascending;

  switch (sortOrder) {
    case SortOrder.firstWearDate:
      items.sort((a, b) => asc
          ? a.firstWearDate.compareTo(b.firstWearDate)
          : b.firstWearDate.compareTo(a.firstWearDate));

    case SortOrder.brand:
      items.sort((a, b) {
        final cmp = a.brand.toLowerCase().compareTo(b.brand.toLowerCase());
        final result = cmp != 0 ? cmp : a.model.toLowerCase().compareTo(b.model.toLowerCase());
        return asc ? result : -result;
      });

    case SortOrder.wearCount:
      items.sort((a, b) {
        final countA = a.baseWearCount + (trackedCounts[a.id] ?? 0);
        final countB = b.baseWearCount + (trackedCounts[b.id] ?? 0);
        return asc ? countA.compareTo(countB) : countB.compareTo(countA);
      });

    case SortOrder.lastWorn:
      items.sort((a, b) {
        final dateA = lastWornDates[a.id];
        final dateB = lastWornDates[b.id];
        // Items never worn always go to the end regardless of direction.
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return asc ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
      });
  }

  // Pin the most recently worn item at position 0 if the toggle is on.
  if (latestOnTop && items.isNotEmpty && lastWornDates.isNotEmpty) {
    int latestIndex = 0;
    DateTime? latestDate;
    for (int i = 0; i < items.length; i++) {
      final d = lastWornDates[items[i].id];
      if (d != null && (latestDate == null || d.isAfter(latestDate))) {
        latestDate = d;
        latestIndex = i;
      }
    }
    if (latestIndex != 0) {
      final pinned = items.removeAt(latestIndex);
      items.insert(0, pinned);
    }
  }

  return items;
});
