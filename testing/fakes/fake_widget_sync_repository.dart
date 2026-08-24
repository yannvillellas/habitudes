import 'package:habitudes/data/repositories/widget_sync_repository.dart';

class FakeWidgetSyncRepository implements WidgetSyncRepository {
  int syncAllCalls = 0;

  @override
  Future<void> syncAll() async {
    syncAllCalls++;
  }
}
