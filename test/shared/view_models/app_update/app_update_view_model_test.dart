import 'package:dineroo_mobile/shared/services/app_update/app_update_service.dart';
import 'package:dineroo_mobile/shared/view_models/app_update/app_update_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppUpdateViewModel', () {
    test('check stores result and notifies listeners', () async {
      final service = _FakeAppUpdateService(result: _result());
      final viewModel = AppUpdateViewModel(service);
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      await viewModel.check();

      expect(viewModel.result, service.result);
      expect(viewModel.shouldShowDialog, isTrue);
      expect(notifications, 1);
    });

    test('performUpdate delegates to service when result exists', () async {
      final service = _FakeAppUpdateService(result: _result());
      final viewModel = AppUpdateViewModel(service);

      await viewModel.check();
      await viewModel.performUpdate();

      expect(service.performedUpdate, same(service.result));
    });

    test('performUpdate does nothing before check', () async {
      final service = _FakeAppUpdateService(result: _result());
      final viewModel = AppUpdateViewModel(service);

      await viewModel.performUpdate();

      expect(service.performedUpdate, isNull);
    });

    test('clear removes result and notifies listeners', () async {
      final service = _FakeAppUpdateService(result: _result());
      final viewModel = AppUpdateViewModel(service);
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      await viewModel.check();
      viewModel.clear();

      expect(viewModel.result, isNull);
      expect(viewModel.shouldShowDialog, isFalse);
      expect(notifications, 2);
    });
  });
}

AppUpdateResult _result() {
  return AppUpdateResult(
    shouldShow: true,
    storeLink: 'https://store.test/app',
    localVersion: '1.2.3+40',
    storeVersion: '60',
    message: 'Update available',
    platform: AppPlatform.android,
  );
}

class _FakeAppUpdateService extends AppUpdateService {
  _FakeAppUpdateService({required this.result});

  final AppUpdateResult result;
  AppUpdateResult? performedUpdate;

  @override
  Future<AppUpdateResult> checkForUpdate() async => result;

  @override
  Future<void> performUpdate(AppUpdateResult result) async {
    performedUpdate = result;
  }
}
