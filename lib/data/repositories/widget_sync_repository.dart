import '../services/widget_sync_service.dart';

abstract class WidgetSyncRepository {
  /// Requests a refresh of all home screen widgets. Never throws.
  Future<void> syncAll();
}

class WidgetSyncRepositoryMethodChannel implements WidgetSyncRepository {
  final WidgetSyncService _service;

  WidgetSyncRepositoryMethodChannel({required WidgetSyncService service}) : _service = service;

  @override
  Future<void> syncAll() async {
    try {
      await _service.syncAll();
    } catch (_) {
      // Widget refresh is best-effort and must never break the check-in flow.
    }
  }
}
