import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/item_repository.dart';
import '../repositories/wear_day_repository.dart';

class HaService {
  static const _entityId = 'sensor.raw_denim_aktuell';

  /// Pushes [itemId] as the currently worn item with its total wear days. Fire-and-forget: does nothing
  /// when the integration is off or not set up, and swallows failures. Reads the settings straight from
  /// SharedPreferences so it works before the providers have loaded and in the widget's background engine.
  static Future<void> pushItem(String itemId) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('ha_enabled') ?? false)) return;
    final haUrl = prefs.getString('ha_url');
    final haToken = prefs.getString('ha_token');
    if (haUrl == null || haToken == null) return;

    final item = await ItemRepository().getById(itemId);
    if (item == null) return;
    final tracked = await WearDayRepository().countByItemId(itemId);
    await updateCurrentItem(
      haUrl: haUrl,
      token: haToken,
      itemName: '${item.brand} ${item.model}',
      wearDays: item.baseWearCount + tracked,
    ).catchError((_) => false);
  }

  /// Updates the HA sensor with the currently worn item.
  /// Returns true on success (HTTP 200/201).
  static Future<bool> updateCurrentItem({
    required String haUrl,
    required String token,
    required String itemName,
    required int wearDays,
  }) async {
    final uri = Uri.parse('${haUrl.endsWith('/') ? haUrl.substring(0, haUrl.length - 1) : haUrl}/api/states/$_entityId');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'state': itemName,
        'attributes': {
          'friendly_name': 'Raw Denim – Aktuell getragen',
          'wear_days': wearDays,
          'icon': 'mdi:tshirt-crew',
        },
      }),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  /// Sends a test request to verify URL and token are correct.
  static Future<bool> testConnection({
    required String haUrl,
    required String token,
  }) async {
    final uri = Uri.parse('${haUrl.endsWith('/') ? haUrl.substring(0, haUrl.length - 1) : haUrl}/api/');
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }
}
