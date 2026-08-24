import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'sync_notifier.dart';

/// Triggers a data refresh when the app becomes visible again, so that
/// widget-side writes are reflected before the first visible frame.
class AppRefreshLifecycleListener extends StatefulWidget {
  const AppRefreshLifecycleListener({super.key, required this.child});

  final Widget child;

  @override
  State<AppRefreshLifecycleListener> createState() => _AppRefreshLifecycleListenerState();
}

class _AppRefreshLifecycleListenerState extends State<AppRefreshLifecycleListener> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(onShow: () => context.read<SyncNotifier>().notifyRefresh());
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
