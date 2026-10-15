import 'package:dineroo_mobile/shared/common/observability/telemetry.dart';
import 'package:flutter/widgets.dart';

/// Exports the buffered spans when the app leaves the foreground.
///
/// The batch processor exports on a timer, so without this the spans of the user's last actions
/// are lost if the OS suspends or kills the app before the next tick. `inactive` and `hidden` are
/// transient (system dialogs, app-switch animation) and are ignored.
class TelemetryLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      AppTelemetry.forceFlush();
    }
  }
}
