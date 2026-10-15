import 'package:flutter/foundation.dart';
import 'package:dineroo_mobile/shared/services/app_update/app_update_service.dart';

class AppUpdateViewModel extends ChangeNotifier {
  AppUpdateViewModel(this._service);

  final AppUpdateService _service;

  AppUpdateResult? _result;
  AppUpdateResult? get result => _result;

  bool get shouldShowDialog => _result?.shouldShow == true;

  Future<void> check() async {
    _result = await _service.checkForUpdate();
    notifyListeners();
  }

  Future<void> performUpdate() async {
    final currentResult = _result;
    if (currentResult == null) return;
    await _service.performUpdate(currentResult);
  }

  void clear() {
    _result = null;
    notifyListeners();
  }
}
