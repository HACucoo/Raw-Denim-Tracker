import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item.dart';
import '../repositories/item_repository.dart';
import '../repositories/wash_repository.dart';
import '../repositories/wear_day_repository.dart';

/// Sends the complete current state — garments, wear days with their location, washes — to the Home Assistant
/// script `script.raw_denim_speichern`, which writes it as one JSON object per line into HA's media folder
/// (served to logged-in callers only), where the HA archive picks it up. Every send replaces the whole file, so a
/// send missed while HA was out of reach is made good by the next one; the archive keeps what it has seen.
///
/// Photos are too big to go along every time: a garment line only names its photo (`bild`, a key that changes
/// with the photo), and the photo itself — shrunk to a small JPEG — goes to `script.raw_denim_bild_speichern`
/// once, when it is new or changed. That script appends it to a file of its own.
class HaArchiveService {
  static const _script = 'raw_denim_speichern';
  static const _photoScript = 'raw_denim_bild_speichern';
  static const _sentPhotoPrefix = 'ha_archive_photo_';
  static const _thumbWidth = 400;
  static Timer? _timer;

  /// Coalesces a burst of changes (a wear day plus its location, a restore …) into one send.
  static void schedule() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 3), () {
      send().catchError((_) => false);
    });
  }

  /// Returns true when HA took the data. False when the integration is off, not set up, the script does not
  /// exist (yet) or HA is out of reach. [allPhotos] sends every photo again, not only new or changed ones.
  static Future<bool> send({bool allPhotos = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('ha_enabled') ?? false)) return false;
    final haUrl = prefs.getString('ha_url');
    final token = prefs.getString('ha_token');
    if (haUrl == null || token == null) return false;
    final base = haUrl.endsWith('/') ? haUrl.substring(0, haUrl.length - 1) : haUrl;
    final headers = {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
    final items = await ItemRepository().getAll();
    final response = await http
        .post(Uri.parse('$base/api/services/script/$_script'),
            headers: headers, body: jsonEncode({'zeilen': await lines(items)}))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) return false;
    await _sendPhotos(items, base, headers, prefs, allPhotos);
    return true;
  }

  /// A key that changes whenever the photo does: file name, size and modification time.
  static String? photoKey(Item item) {
    final path = item.photoPath;
    if (path == null) return null;
    final file = File(path);
    if (!file.existsSync()) return null;
    final stat = file.statSync();
    return '${p.basename(path)}-${stat.size}-${stat.modified.millisecondsSinceEpoch}';
  }

  /// Each photo HA does not have yet. A photo HA refused or that could not be read is tried again next time;
  /// a missing photo script (older HA setup) stops the rest.
  static Future<void> _sendPhotos(List<Item> items, String base, Map<String, String> headers,
      SharedPreferences prefs, bool all) async {
    for (final item in items) {
      final key = photoKey(item);
      if (key == null) continue;
      if (!all && prefs.getString('$_sentPhotoPrefix${item.id}') == key) continue;
      final Uint8List? jpeg;
      try {
        jpeg = await compute(_thumbnail, item.photoPath!);
      } catch (_) {
        continue;
      }
      if (jpeg == null) continue;
      final response = await http
          .post(Uri.parse('$base/api/services/script/$_photoScript'),
              headers: headers,
              body: jsonEncode({'stueck': item.id, 'bild': key, 'daten': base64Encode(jpeg)}))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) return;
      await prefs.setString('$_sentPhotoPrefix${item.id}', key);
    }
  }

  /// The photo shrunk to [_thumbWidth] pixels wide as a JPEG (runs in a background isolate).
  static Uint8List? _thumbnail(String path) {
    final decoded = img.decodeImage(File(path).readAsBytesSync());
    if (decoded == null) return null;
    final upright = img.bakeOrientation(decoded);
    final small = upright.width > _thumbWidth ? img.copyResize(upright, width: _thumbWidth) : upright;
    return img.encodeJpg(small, quality: 75);
  }

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// One map per garment, wear day and wash; field names in German like the archive's other tables.
  static Future<List<Map<String, dynamic>>> lines([List<Item>? items]) async {
    items ??= await ItemRepository().getAll();
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
          'bild': photoKey(i),
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
