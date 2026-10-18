import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/item_repository.dart';
import '../repositories/wash_repository.dart';
import '../repositories/wear_day_repository.dart';

/// Sends the complete current state — garments, wear days with their location, washes — to the Home Assistant
/// script `script.raw_denim_speichern`, which writes it as one JSON object per line into HA's media folder
/// (served to logged-in callers only), where the HA archive picks it up. Every send replaces the whole file, so a
/// send missed while HA was out of reach is made good by the next one; the archive keeps what it has seen.
class HaArchiveService {
  static const _script = 'raw_denim_speichern';
  static Timer? _timer;

  /// Coalesces a burst of changes (a wear day plus its location, a restore …) into one send.
  static void schedule() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 3), () {
      send().catchError((_) => false);
    });
  }

  /// Returns true when HA took the data. False when the integration is off, not set up, the script does not
  /// exist (yet) or HA is out of reach.
  static Future<bool> send() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('ha_enabled') ?? false)) return false;
    final haUrl = prefs.getString('ha_url');
    final token = prefs.getString('ha_token');
    if (haUrl == null || token == null) return false;
    final base = haUrl.endsWith('/') ? haUrl.substring(0, haUrl.length - 1) : haUrl;
    final response = await http
        .post(
          Uri.parse('$base/api/services/script/$_script'),
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
          body: jsonEncode({'zeilen': await lines()}),
        )
        .timeout(const Duration(seconds: 30));
    return response.statusCode == 200;
  }

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// One map per garment, wear day and wash; field names in German like the archive's other tables.
  static Future<List<Map<String, dynamic>>> lines() async {
    final items = await ItemRepository().getAll();
    final wearDays = await WearDayRepository().getAll();
    final washes = await WashRepository().getAll();
    return [
      for (final i in items)
        {
          'typ': 'stueck',
          'id': i.id,
          'marke': i.brand,
          'modell': i.model,
          'groesse': i.size,
          'kategorie': i.category?.name,
          'erster_tragetag': _day(i.firstWearDate),
          'basis_tragetage': i.baseWearCount,
          'tragetage_zaehlen': i.trackWearDays,
          'angelegt': i.createdAt.toIso8601String(),
        },
      for (final w in wearDays)
        {
          'typ': 'tragetag',
          'id': w.id,
          'stueck': w.itemId,
          'tag': _day(w.date),
          'breite': w.latitude,
          'laenge': w.longitude,
        },
      for (final w in washes)
        {
          'typ': 'waesche',
          'id': w.id,
          'stueck': w.itemId,
          'tag': _day(w.date),
          'temperatur': w.tempCelsius,
          'tragetage_bei_waesche': w.wearDaysAtWash,
        },
    ];
  }
}
