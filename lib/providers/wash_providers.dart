import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/wash.dart';
import '../repositories/wash_repository.dart';

final washRepositoryProvider = Provider<WashRepository>((_) => WashRepository());

final _uuid = Uuid();

final washesProvider = FutureProvider.autoDispose.family<List<Wash>, String>(
  (ref, itemId) => ref.read(washRepositoryProvider).getByItemId(itemId),
);

final washActionsProvider = Provider<WashActions>((ref) => WashActions(ref));

class WashActions {
  final Ref _ref;
  WashActions(this._ref);

  WashRepository get _repo => _ref.read(washRepositoryProvider);

  Future<void> addWash(String itemId, {required DateTime date, required int tempCelsius, int? wearDaysAtWash}) async {
    await _repo.insert(Wash(id: _uuid.v4(), itemId: itemId, date: date, tempCelsius: tempCelsius, wearDaysAtWash: wearDaysAtWash));
    _ref.invalidate(washesProvider(itemId));
  }

  Future<void> updateWash(String itemId, Wash wash) async {
    await _repo.update(wash);
    _ref.invalidate(washesProvider(itemId));
  }

  Future<void> deleteWash(String itemId, String id) async {
    await _repo.delete(id);
    _ref.invalidate(washesProvider(itemId));
  }
}
