import 'package:flutter/foundation.dart';

/// App-level "please refresh" signal. Carries no data: subscribers re-read
/// their state from the data layer.
class SyncNotifier extends ChangeNotifier {
  void notifyRefresh() => notifyListeners();
}
