import 'dart:convert';
import 'package:http/http.dart' as http;

class HaService {
  static const _entityId = 'sensor.raw_denim_aktuell';

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
