import 'package:habitudes/data/services/widget_sync_service.dart';

class FakeWidgetSyncService implements WidgetSyncService {
  int syncAllCalls = 0;
  Exception? error;

  @override
  Future<void> syncAll() async {
    syncAllCalls++;
    final failure = error;
    if (failure != null) {
      throw failure;
    }
  }
}
