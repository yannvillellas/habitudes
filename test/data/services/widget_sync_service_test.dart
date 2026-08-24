import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:habitudes/data/services/widget_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('app.yann.habitudes/widget');

  group('MethodChannelWidgetSyncService', () {
    test('invokes updateAll on the channel', () async {
      final calls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        return null;
      });

      await MethodChannelWidgetSyncService().syncAll();

      expect(calls, ['updateAll']);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    });

    test('propagates channel failures to the caller', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'boom');
      });

      await expectLater(MethodChannelWidgetSyncService().syncAll(), throwsA(isA<PlatformException>()));

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    });
  });
}
