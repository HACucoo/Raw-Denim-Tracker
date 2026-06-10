import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/item.dart';
import '../repositories/item_repository.dart';
import '../services/widget_service.dart';
import 'settings_providers.dart';

final itemRepositoryProvider = Provider<ItemRepository>((_) => ItemRepository());

final _uuid = Uuid();

final itemsProvider = AsyncNotifierProvider<ItemsNotifier, List<Item>>(ItemsNotifier.new);

class ItemsNotifier extends AsyncNotifier<List<Item>> {
  ItemRepository get _repo => ref.read(itemRepositoryProvider);

  @override
  Future<List<Item>> build() => _repo.getAll();

  Future<Item> addItem({
    required String brand,
    required String model,
    required String size,
    required DateTime firstWearDate,
    String? notes,
    String? photoPath,
    ItemCategory? category,
    bool trackWearDays = true,
  }) async {
    final item = Item(
      id: _uuid.v4(),
      brand: brand,
      model: model,
      size: size,
      firstWearDate: firstWearDate,
      notes: notes,
      photoPath: photoPath,
      createdAt: DateTime.now(),
      category: category,
      trackWearDays: trackWearDays,
    );
    await _repo.insert(item);
    ref.invalidateSelf();
    return item;
  }

  Future<void> updateItem(Item item) async {
    await _repo.update(item);
    ref.invalidateSelf();
    WidgetService.refreshIfWidgetItem(item.id);
  }

  Future<void> deleteItem(String id) async {
    final item = await _repo.getById(id);
    await _repo.delete(id);
    ref.invalidateSelf();

    // The photo copy in the documents dir belongs to this item alone —
    // remove it so deleted items don't leave files behind.
    final photo = item?.photoPath;
    if (photo != null) {
      try {
        await File(photo).delete();
      } catch (_) {/* already gone */}
    }

    // If the widget pointed at this item, clear it instead of letting it
    // show (and insert wear days for) a dead item id.
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('widget_selected_item_id') == id) {
      await prefs.remove('widget_selected_item_id');
      await WidgetService.updateWidget(null);
      ref.invalidate(widgetSelectedItemIdProvider);
    }
  }

  Future<void> linkNfcTag(String itemId, String nfcTagId) async {
    final item = await _repo.getById(itemId);
    if (item == null) return;
    await _repo.update(item.copyWith(nfcTagId: nfcTagId));
    ref.invalidateSelf();
  }

  Future<void> unlinkNfcTag(String itemId) async {
    final item = await _repo.getById(itemId);
    if (item == null) return;
    await _repo.update(item.copyWith(nfcTagId: null));
    ref.invalidateSelf();
  }

  Future<Item?> getByNfcTagId(String nfcTagId) =>
      _repo.getByNfcTagId(nfcTagId);
}

final itemProvider = FutureProvider.family<Item?, String>((ref, id) {
  return ref.read(itemRepositoryProvider).getById(id);
});
