import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/item.dart';
import '../repositories/item_repository.dart';
import '../services/widget_service.dart';

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
    await _repo.delete(id);
    ref.invalidateSelf();
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
