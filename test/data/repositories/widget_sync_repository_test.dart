import 'package:flutter_test/flutter_test.dart';

import 'package:habitudes/data/repositories/widget_sync_repository.dart';

import '../../../testing/fakes/fake_widget_sync_service.dart';

void main() {
  group('WidgetSyncRepositoryMethodChannel', () {
    test('delegates to the service', () async {
      final service = FakeWidgetSyncService();
      final repository = WidgetSyncRepositoryMethodChannel(service: service);

      await repository.syncAll();

      expect(service.syncAllCalls, 1);
    });

    test('syncAll swallows service failures', () async {
      final service = FakeWidgetSyncService()..error = Exception('boom');
      final repository = WidgetSyncRepositoryMethodChannel(service: service);

      await repository.syncAll();

      expect(service.syncAllCalls, 1);
    });
  });
}
