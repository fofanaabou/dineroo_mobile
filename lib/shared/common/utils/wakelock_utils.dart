import 'package:wakelock_plus/wakelock_plus.dart';

class WakeLockUtils {
  static bool _enabled = false;

  static Future<void> enable() async {
    if (_enabled) return;
    _enabled = true;
    await WakelockPlus.enable();
  }

  static Future<void> disable() async {
    if (!_enabled) return;
    _enabled = false;
    await WakelockPlus.disable();
  }

  static Future<void> sync(bool shouldKeepScreenOn) async {
    if (_enabled == shouldKeepScreenOn) return;
    _enabled = shouldKeepScreenOn;
    if (shouldKeepScreenOn) {
      await WakelockPlus.enable();
    } else {
      await WakelockPlus.disable();
    }
  }
}
