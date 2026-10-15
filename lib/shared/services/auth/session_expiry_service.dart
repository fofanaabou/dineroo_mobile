import 'dart:async';

class SessionExpiryService {
  SessionExpiryService._();

  static FutureOr<void> Function()? _onExpired;
  static bool _isHandling = false;
  static bool _hasNotifiedExpired = false;

  static void configure({required FutureOr<void> Function() onExpired}) {
    _onExpired = onExpired;
  }

  static void markActive() {
    _hasNotifiedExpired = false;
  }

  static void reset() {
    _onExpired = null;
    _isHandling = false;
    _hasNotifiedExpired = false;
  }

  static Future<void> notifyExpired() async {
    if (_hasNotifiedExpired) return;
    if (_isHandling) return;

    final handler = _onExpired;
    if (handler == null) return;

    _hasNotifiedExpired = true;
    _isHandling = true;
    try {
      await handler();
    } finally {
      _isHandling = false;
    }
  }
}
