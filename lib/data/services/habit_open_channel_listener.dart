import 'package:flutter/services.dart';

import 'widget_sync_service.dart';

/// Receives "open this habit" requests from the widget and forwards them
/// through [onOpenHabit].
class HabitOpenChannelListener {
  static const _channel = MethodChannel(widgetSyncChannelName);

  HabitOpenChannelListener({required void Function(String habitId) onOpenHabit}) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'openHabit') {
        final habitId = call.arguments as String?;
        if (habitId != null) {
          onOpenHabit(habitId);
        }
      }
    });
  }
}
