import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/wear_day.dart';
import '../repositories/item_repository.dart';
import '../repositories/wear_day_repository.dart';
import '../services/ha_service.dart';
import 'item_providers.dart';

final wearDayRepositoryProvider = Provider<WearDayRepository>((_) => WearDayRepository());

final _uuid = Uuid();

final wearDaysProvider = FutureProvider.family<List<WearDay>, String>(
  (ref, itemId) => ref.read(wearDayRepositoryProvider).getByItemId(itemId),
);

/// Total wear days = baseWearCount (item offset) + tracked wear days in DB
final wearDayCountProvider = FutureProvider.family<int, String>((ref, itemId) async {
  final item = await ref.read(itemRepositoryProvider).getById(itemId);
  final tracked = await ref.read(wearDayRepositoryProvider).countByItemId(itemId);
  return (item?.baseWearCount ?? 0) + tracked;
});

/// Last wear date for an item (null if never worn).
final lastWearDateProvider = FutureProvider.family<DateTime?, String>(
  (ref, itemId) => ref.read(wearDayRepositoryProvider).getLastWornDate(itemId),
);

final wearDayActionsProvider = Provider<WearDayActions>((ref) => WearDayActions(ref));

class WearDayActions {
  final Ref _ref;
  WearDayActions(this._ref);

  WearDayRepository get _repo => _ref.read(wearDayRepositoryProvider);
  ItemRepository get _itemRepo => _ref.read(itemRepositoryProvider);

  /// Returns true if the wear day was inserted, false if it already existed.
  Future<bool> addWearDay(String itemId, DateTime date) async {
    if (await _repo.existsForDate(itemId, date)) return false;
    final (lat, lng) = await _currentLocation();
    await _repo.insert(WearDay(
      id: _uuid.v4(),
      itemId: itemId,
      date: date,
      latitude: lat,
      longitude: lng,
    ));
    _ref.invalidate(wearDaysProvider(itemId));
    _ref.invalidate(wearDayCountProvider(itemId));
    _ref.invalidate(lastWearDateProvider(itemId));
    _pushToHa(itemId);
    return true;
  }

  /// Best-effort location capture with 5-second timeout. Returns (null, null) on failure.
  Future<(double?, double?)> _currentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return (null, null);
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );
      return (pos.latitude, pos.longitude);
    } catch (_) {
      return (null, null);
    }
  }

  /// Fire-and-forget HA update — failures are silently ignored.
  /// Reads directly from SharedPreferences to avoid race conditions with
  /// provider initialisation (providers load asynchronously via microtask).
  Future<void> _pushToHa(String itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final haEnabled = prefs.getBool('ha_enabled') ?? false;
    if (!haEnabled) return;
    final haUrl = prefs.getString('ha_url');
    final haToken = prefs.getString('ha_token');
    if (haUrl == null || haToken == null) return;

    final item = await _itemRepo.getById(itemId);
    if (item == null) return;
    final tracked = await _repo.countByItemId(itemId);
    final totalDays = item.baseWearCount + tracked;

    await HaService.updateCurrentItem(
      haUrl: haUrl,
      token: haToken,
      itemName: '${item.brand} ${item.model}',
      wearDays: totalDays,
    ).catchError((_) => false);
  }

  Future<void> updateWearDay(String itemId, WearDay wearDay) async {
    await _repo.update(wearDay);
    _ref.invalidate(wearDaysProvider(itemId));
    _ref.invalidate(lastWearDateProvider(itemId));
  }

  Future<void> deleteWearDay(String itemId, String id) async {
    await _repo.delete(id);
    _ref.invalidate(wearDaysProvider(itemId));
    _ref.invalidate(wearDayCountProvider(itemId));
    _ref.invalidate(lastWearDateProvider(itemId));
  }

  /// Sets the base wear count (historical offset) for an item.
  Future<void> setBaseWearCount(String itemId, int count) async {
    final item = await _itemRepo.getById(itemId);
    if (item == null) return;
    await _itemRepo.update(item.copyWith(baseWearCount: count));
    _ref.invalidate(wearDayCountProvider(itemId));
  }
}
