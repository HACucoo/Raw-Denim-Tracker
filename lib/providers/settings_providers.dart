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

// --- CATEGORIES ---

final categoriesEnabledProvider =
    NotifierProvider<CategoriesEnabledNotifier, bool>(CategoriesEnabledNotifier.new);

class CategoriesEnabledNotifier extends Notifier<bool> {
  static const _key = 'categories_enabled';

  @override
  bool build() {
    Future.microtask(_load);
    return true;
  }

  Future<void> _load() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    state = prefs.getBool(_key) ?? true;
  }

  Future<void> set(bool value) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(_key, value);
    state = value;
  }
}

// --- DEFAULT WASH TEMPERATURE ---

final defaultWashTempProvider =
    NotifierProvider<DefaultWashTempNotifier, int>(DefaultWashTempNotifier.new);

class DefaultWashTempNotifier extends Notifier<int> {
  static const _key = 'default_wash_temp';

  @override
  int build() {
    Future.microtask(_load);
    return 30;
  }

  Future<void> _load() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    state = prefs.getInt(_key) ?? 30;
  }

  Future<void> set(int value) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setInt(_key, value);
    state = value;
  }
}

// --- LOCATION ---

final locationEnabledProvider =
    NotifierProvider<LocationEnabledNotifier, bool>(LocationEnabledNotifier.new);

class LocationEnabledNotifier extends Notifier<bool> {
  static const _key = 'location_enabled';

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

// --- HOME ASSISTANT ---

final haEnabledProvider =
    NotifierProvider<HaEnabledNotifier, bool>(HaEnabledNotifier.new);

class HaEnabledNotifier extends Notifier<bool> {
  static const _key = 'ha_enabled';

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

final haUrlProvider =
    NotifierProvider<HaUrlNotifier, String?>(HaUrlNotifier.new);

class HaUrlNotifier extends Notifier<String?> {
  static const _key = 'ha_url';

  @override
  String? build() {
    Future.microtask(_load);
    return null;
  }

  Future<void> _load() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    state = prefs.getString(_key);
  }

  Future<void> set(String? value) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    if (value == null || value.isEmpty) {
      await prefs.remove(_key);
      state = null;
    } else {
      await prefs.setString(_key, value);
      state = value;
    }
  }
}

final haTokenProvider =
    NotifierProvider<HaTokenNotifier, String?>(HaTokenNotifier.new);

class HaTokenNotifier extends Notifier<String?> {
  static const _key = 'ha_token';

  @override
  String? build() {
    Future.microtask(_load);
    return null;
  }

  Future<void> _load() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    state = prefs.getString(_key);
  }

  Future<void> set(String? value) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    if (value == null || value.isEmpty) {
      await prefs.remove(_key);
      state = null;
    } else {
      await prefs.setString(_key, value);
      state = value;
    }
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
