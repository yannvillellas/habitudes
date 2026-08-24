import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:habitudes/data/services/habit_open_channel_listener.dart';
import 'package:habitudes/data/services/widget_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HabitOpenChannelListener', () {
    test('invokes the callback with the habit id when openHabit is received', () async {
      String? opened;
      HabitOpenChannelListener(onOpenHabit: (habitId) => opened = habitId);

      final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final message = const StandardMethodCodec().encodeMethodCall(const MethodCall('openHabit', 'h1'));
      await messenger.handlePlatformMessage(widgetSyncChannelName, message, (ByteData? reply) {});

      expect(opened, 'h1');
    });

    test('ignores other channel methods', () async {
      String? opened;
      HabitOpenChannelListener(onOpenHabit: (habitId) => opened = habitId);

      final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final message = const StandardMethodCodec().encodeMethodCall(const MethodCall('somethingElse'));
      await messenger.handlePlatformMessage(widgetSyncChannelName, message, (ByteData? reply) {});

      expect(opened, isNull);
    });

    test('ignores openHabit without a habit id', () async {
      String? opened;
      HabitOpenChannelListener(onOpenHabit: (habitId) => opened = habitId);

      final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final message = const StandardMethodCodec().encodeMethodCall(const MethodCall('openHabit'));
      await messenger.handlePlatformMessage(widgetSyncChannelName, message, (ByteData? reply) {});

      expect(opened, isNull);
    });
  });
}
