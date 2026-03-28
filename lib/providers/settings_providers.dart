import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (_) => SharedPreferences.getInstance(),
);

// ID of item selected for widget
final widgetSelectedItemIdProvider =
    NotifierProvider<WidgetItemNotifier, String?>(WidgetItemNotifier.new);

class WidgetItemNotifier extends Notifier<String?> {
  static const _key = 'widget_selected_item_id';

  @override
  String? build() {
    Future.microtask(_load);
    return null;
  }

  Future<void> _load() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    state = prefs.getString(_key);
  }

  Future<void> setItemId(String? id) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    if (id == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, id);
    }
    state = id;
  }
}

final sheetsEnabledProvider =
    NotifierProvider<SheetsEnabledNotifier, bool>(SheetsEnabledNotifier.new);

class SheetsEnabledNotifier extends Notifier<bool> {
  static const _key = 'sheets_enabled';

  @override
  bool build() {
    Future.microtask(_load);
    return false;
  }

  Future<void> _load() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> set(bool value) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(_key, value);
    state = value;
  }
}

final sheetsSpreadsheetIdProvider =
    NotifierProvider<SpreadsheetIdNotifier, String?>(SpreadsheetIdNotifier.new);

class SpreadsheetIdNotifier extends Notifier<String?> {
  static const _key = 'sheets_spreadsheet_id';

  @override
  String? build() {
    Future.microtask(_load);
    return null;
  }

  Future<void> _load() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    state = prefs.getString(_key);
  }

  Future<void> set(String? id) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    if (id == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, id);
    }
    state = id;
  }
}
