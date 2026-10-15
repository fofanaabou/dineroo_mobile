import 'package:flutter/widgets.dart';
import 'package:dineroo_mobile/shared/realtime/stomp_realtime_service.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';

class RealtimeLifecycleObserver extends WidgetsBindingObserver {
  @visibleForTesting
  static StompRealtimeService? stompServiceOverride;

  StompRealtimeService get _service =>
      stompServiceOverride ?? StompRealtimeService();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App returns to the foreground
        logger.i('[RT] App resumed — checking WebSocket connection...');
        _service.reconnectIfNeeded();
        break;

      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // Transient states (brief focus loss, system dialogs, app-switch
        // animations): keep the WebSocket alive, disconnecting here caused
        // constant reconnect churn and made drivers invisible to dispatch.
        break;

      case AppLifecycleState.paused:
        // WS connection is released when the app actually goes into background.
        logger.w('[RT] App paused — disconnecting WebSocket...');
        _service.disconnect(clearSession: false, clearSubscriptions: false);
        break;

      case AppLifecycleState.detached:
        // App is completely finished.
        logger.w('[RT] App detached — cleaning up WebSocket...');
        _service.disconnect();
        break;
    }
  }
}
