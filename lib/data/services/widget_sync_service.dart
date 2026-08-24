import 'package:flutter/services.dart';

abstract class WidgetSyncService {
  Future<void> syncAll();
}

class MethodChannelWidgetSyncService implements WidgetSyncService {
  static const _channel = MethodChannel('app.yann.habitudes/widget');

  @override
  Future<void> syncAll() => _channel.invokeMethod<void>('updateAll');
}
