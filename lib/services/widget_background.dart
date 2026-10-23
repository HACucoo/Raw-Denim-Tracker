import 'package:home_widget/home_widget.dart';
import 'ha_archive_service.dart';
import 'ha_service.dart';

/// Runs in home_widget's background Flutter engine — no activity, no Riverpod — after the Kotlin
/// `WearDayReceiver` has written today's wear day for a widget tap. It does what the in-app path does
/// after a wear day: send the whole state to the Home Assistant archive and update the "currently worn"
/// sensor. If this engine cannot start, nothing is lost: the next app start sends everything anyway.
///
/// Registered in `main()` with [HomeWidget.registerInteractivityCallback]; the Kotlin side raises it by
/// broadcasting `rawdenim://widget/wear-day-added?item=<id>` to `HomeWidgetBackgroundReceiver`.
@pragma('vm:entry-point')
Future<void> widgetBackgroundCallback(Uri? uri) async {
  if (uri == null || uri.host != 'widget' || uri.path != '/wear-day-added') return;
  await HaArchiveService.send().catchError((_) => false);
  final itemId = uri.queryParameters['item'];
  if (itemId != null) await HaService.pushItem(itemId);
}
