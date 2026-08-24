import 'package:flutter/services.dart';

const widgetSyncChannelName = 'app.yann.habitudes/widget';

abstract class WidgetSyncService {
  Future<void> syncAll();
}

class MethodChannelWidgetSyncService implements WidgetSyncService {
  static const _channel = MethodChannel(widgetSyncChannelName);

  @override
  Future<void> syncAll() => _channel.invokeMethod<void>('updateAll');
}
