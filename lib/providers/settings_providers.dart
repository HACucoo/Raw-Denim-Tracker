import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (_) => SharedPreferences.getInstance(),
);

// ---------------------------------------------------------------------------
// Persistence base classes
// ---------------------------------------------------------------------------

/// A setting backed by SharedPreferences: starts on [defaultValue], loads the
/// stored value asynchronously, and persists every [set].
abstract class PersistedNotifier<T> extends Notifier<T> {
  String get prefsKey;
  T get defaultValue;

  T readFrom(SharedPreferences prefs);
  Future<void> writeTo(SharedPreferences prefs, T value);

  @override
  T build() {
    Future.microtask(() async {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      state = readFrom(prefs);
    });
    return defaultValue;
  }

  Future<void> set(T value) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await writeTo(prefs, value);
    state = value;
  }
}

abstract class BoolPrefNotifier extends PersistedNotifier<bool> {
  @override
  bool readFrom(SharedPreferences prefs) => prefs.getBool(prefsKey) ?? defaultValue;
  @override
  Future<void> writeTo(SharedPreferences prefs, bool value) =>
      prefs.setBool(prefsKey, value);
}

abstract class IntPrefNotifier extends PersistedNotifier<int> {
  @override
  int readFrom(SharedPreferences prefs) => prefs.getInt(prefsKey) ?? defaultValue;
  @override
  Future<void> writeTo(SharedPreferences prefs, int value) =>
      prefs.setInt(prefsKey, value);
}

/// Nullable string setting; null and '' both clear the stored key.
abstract class StringPrefNotifier extends PersistedNotifier<String?> {
  @override
  String? get defaultValue => null;
  @override
  String? readFrom(SharedPreferences prefs) => prefs.getString(prefsKey);
  @override
  Future<void> writeTo(SharedPreferences prefs, String? value) =>
      value == null ? prefs.remove(prefsKey) : prefs.setString(prefsKey, value);
  @override
  Future<void> set(String? value) =>
      super.set(value == null || value.isEmpty ? null : value);
}

/// Enum setting stored by name; unknown stored values fall back to the default.
abstract class EnumPrefNotifier<T extends Enum> extends PersistedNotifier<T> {
  List<T> get values;
  @override
  T readFrom(SharedPreferences prefs) =>
      values.asNameMap()[prefs.getString(prefsKey)] ?? defaultValue;
  @override
  Future<void> writeTo(SharedPreferences prefs, T value) =>
      prefs.setString(prefsKey, value.name);
}

// ---------------------------------------------------------------------------
// Settings
// ---------------------------------------------------------------------------

// ID of item selected for widget
final widgetSelectedItemIdProvider =
    NotifierProvider<WidgetItemNotifier, String?>(WidgetItemNotifier.new);

class WidgetItemNotifier extends StringPrefNotifier {
  @override
  String get prefsKey => 'widget_selected_item_id';
}

final sheetsEnabledProvider =
    NotifierProvider<SheetsEnabledNotifier, bool>(SheetsEnabledNotifier.new);

class SheetsEnabledNotifier extends BoolPrefNotifier {
  @override
  String get prefsKey => 'sheets_enabled';
  @override
  bool get defaultValue => false;
}

final categoriesEnabledProvider =
    NotifierProvider<CategoriesEnabledNotifier, bool>(CategoriesEnabledNotifier.new);

class CategoriesEnabledNotifier extends BoolPrefNotifier {
  @override
  String get prefsKey => 'categories_enabled';
  @override
  bool get defaultValue => true;
}

final defaultWashTempProvider =
    NotifierProvider<DefaultWashTempNotifier, int>(DefaultWashTempNotifier.new);

class DefaultWashTempNotifier extends IntPrefNotifier {
  @override
  String get prefsKey => 'default_wash_temp';
  @override
  int get defaultValue => 30;
}

final widgetMonochromeProvider =
    NotifierProvider<WidgetMonochromeNotifier, bool>(WidgetMonochromeNotifier.new);

class WidgetMonochromeNotifier extends BoolPrefNotifier {
  @override
  String get prefsKey => 'widget_monochrome';
  @override
  bool get defaultValue => false;
}

final locationEnabledProvider =
    NotifierProvider<LocationEnabledNotifier, bool>(LocationEnabledNotifier.new);

class LocationEnabledNotifier extends BoolPrefNotifier {
  @override
  String get prefsKey => 'location_enabled';
  @override
  bool get defaultValue => false;
}

final haEnabledProvider =
    NotifierProvider<HaEnabledNotifier, bool>(HaEnabledNotifier.new);

class HaEnabledNotifier extends BoolPrefNotifier {
  @override
  String get prefsKey => 'ha_enabled';
  @override
  bool get defaultValue => false;
}

final haUrlProvider =
    NotifierProvider<HaUrlNotifier, String?>(HaUrlNotifier.new);

class HaUrlNotifier extends StringPrefNotifier {
  @override
  String get prefsKey => 'ha_url';
}

final haTokenProvider =
    NotifierProvider<HaTokenNotifier, String?>(HaTokenNotifier.new);

class HaTokenNotifier extends StringPrefNotifier {
  @override
  String get prefsKey => 'ha_token';
}

final sheetsSpreadsheetIdProvider =
    NotifierProvider<SpreadsheetIdNotifier, String?>(SpreadsheetIdNotifier.new);

class SpreadsheetIdNotifier extends StringPrefNotifier {
  @override
  String get prefsKey => 'sheets_spreadsheet_id';
}
