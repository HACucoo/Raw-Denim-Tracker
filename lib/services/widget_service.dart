import 'package:home_widget/home_widget.dart';
import '../repositories/item_repository.dart';
import '../repositories/wear_day_repository.dart';

class WidgetService {
  static const _widgetName = 'WearDayWidget';

  /// Call whenever the widget item changes or wear days are updated.
  static Future<void> updateWidget(String? itemId) async {
    if (itemId == null) {
      await HomeWidget.saveWidgetData<String>('widget_item_name', 'No item selected');
      await HomeWidget.saveWidgetData<int>('widget_wear_count', 0);
      await HomeWidget.saveWidgetData<String>('widget_item_id', '');
      await HomeWidget.saveWidgetData<String>('widget_photo_path', '');
    } else {
      final item = await ItemRepository().getById(itemId);
      final tracked = await WearDayRepository().countByItemId(itemId);
      final total = (item?.baseWearCount ?? 0) + tracked;

      await HomeWidget.saveWidgetData<String>(
        'widget_item_name',
        item != null ? '${item.brand} ${item.model}' : 'Unknown',
      );
      await HomeWidget.saveWidgetData<int>('widget_wear_count', total);
      await HomeWidget.saveWidgetData<String>('widget_item_id', itemId);
      await HomeWidget.saveWidgetData<String>(
        'widget_photo_path',
        item?.photoPath ?? '',
      );
    }
    await HomeWidget.updateWidget(androidName: _widgetName);
  }

  /// Refreshes the widget only if it is currently showing [itemId].
  static Future<void> refreshIfWidgetItem(String itemId) async {
    final widgetItemId = await HomeWidget.getWidgetData<String>('widget_item_id');
    if (widgetItemId == itemId) await updateWidget(itemId);
  }
}
