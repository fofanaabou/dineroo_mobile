import 'package:dineroo_mobile/shared/services/app_update/app_update_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_update/in_app_update.dart' as in_app_update;
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://api.test');
  });

  group('AppUpdateService', () {
    test(
      'returns mandatory update when current build is below minimum',
      () async {
        final service = _service(
          currentBuildNumber: '40',
          policy: {
            'minimumBuildNumber': 50,
            'latestBuildNumber': 60,
            'storeUrl': 'https://store.test/app',
            'forceUpdate': false,
            'message': 'Update required',
          },
        );

        final result = await service.checkForUpdate();

        expect(result.shouldShow, isTrue);
        expect(result.forceUpdate, isTrue);
        expect(result.storeLink, 'https://store.test/app');
        expect(result.localVersion, '1.2.3+40');
        expect(result.storeVersion, '60');
        expect(result.message, 'Update required');
        expect(result.platform, AppPlatform.android);
      },
    );

    test('returns optional update when only latest build is newer', () async {
      final service = _service(
        currentBuildNumber: '55',
        policy: {
          'minimumBuildNumber': 50,
          'latestBuildNumber': 60,
          'storeUrl': 'https://store.test/app',
          'forceUpdate': false,
          'message': 'Update available',
        },
      );

      final result = await service.checkForUpdate();

      expect(result.shouldShow, isTrue);
      expect(result.forceUpdate, isFalse);
    });

    test('returns forced update when backend force flag is enabled', () async {
      final service = _service(
        currentBuildNumber: '60',
        policy: {
          'minimumBuildNumber': 1,
          'latestBuildNumber': 60,
          'storeUrl': 'https://store.test/app',
          'forceUpdate': true,
          'message': 'Force update',
        },
      );

      final result = await service.checkForUpdate();

      expect(result.shouldShow, isTrue);
      expect(result.forceUpdate, isTrue);
    });

    test('returns none when current build is up to date', () async {
      final service = _service(
        currentBuildNumber: '60',
        policy: {
          'minimumBuildNumber': 50,
          'latestBuildNumber': 60,
          'storeUrl': 'https://store.test/app',
          'forceUpdate': false,
          'message': 'Update available',
        },
      );

      final result = await service.checkForUpdate();

      expect(result.shouldShow, isFalse);
    });

    test('returns none on unsupported platform or backend error', () async {
      final unsupportedPlatformService = _service(
        currentBuildNumber: '40',
        policy: {},
        platformResolver: () => null,
      );

      final unsupportedResult = await unsupportedPlatformService
          .checkForUpdate();
      expect(unsupportedResult.shouldShow, isFalse);

      final failingService = AppUpdateService(
        dio: _dio((options) => throw DioException(requestOptions: options)),
        packageInfoLoader: () => Future.value(_packageInfo('40')),
        platformResolver: () => AppPlatform.android,
      );

      final failingResult = await failingService.checkForUpdate();
      expect(failingResult.shouldShow, isFalse);
    });

    test('checks at most once per service instance', () async {
      var requests = 0;
      final service = AppUpdateService(
        dio: _dio((options) {
          requests++;
          return _response(options, {
            'minimumBuildNumber': 1,
            'latestBuildNumber': 60,
            'storeUrl': 'https://store.test/app',
            'forceUpdate': false,
            'message': 'Update available',
          });
        }),
        packageInfoLoader: () => Future.value(_packageInfo('40')),
        platformResolver: () => AppPlatform.android,
      );

      expect((await service.checkForUpdate()).shouldShow, isTrue);
      expect((await service.checkForUpdate()).shouldShow, isFalse);
      expect(requests, 1);
    });

    test('returns none when backend response has no data', () async {
      final service = AppUpdateService(
        dio: _dio((options) => _response(options, null)),
        packageInfoLoader: () => Future.value(_packageInfo('40')),
        platformResolver: () => AppPlatform.android,
      );

      final result = await service.checkForUpdate();

      expect(result.shouldShow, isFalse);
    });

    test('parses string build numbers and default policy values', () async {
      final service = _service(
        currentBuildNumber: '40',
        policy: {
          'minimumBuildNumber': '30',
          'latestBuildNumber': '45',
        },
      );

      final result = await service.checkForUpdate();

      expect(result.shouldShow, isTrue);
      expect(result.forceUpdate, isFalse);
      expect(result.storeLink, '');
      expect(result.storeVersion, '45');
      expect(result.message, 'Une nouvelle version de Dineroo est disponible.');
    });

    test('performs immediate Android update when forced and allowed', () async {
      var immediateUpdates = 0;
      var storeLaunches = 0;
      final service = AppUpdateService(
        androidUpdateInfoLoader: () async => _FakeAppUpdateInfo(
          updateAvailability: in_app_update.UpdateAvailability.updateAvailable,
          immediateUpdateAllowed: true,
        ),
        immediateUpdateRunner: () async => immediateUpdates++,
        storeLauncher: (_) async {
          storeLaunches++;
          return true;
        },
      );

      await service.performUpdate(_updateResult(forceUpdate: true));

      expect(immediateUpdates, 1);
      expect(storeLaunches, 0);
    });

    test('performs flexible Android update when optional and allowed', () async {
      var flexibleUpdates = 0;
      var completedFlexibleUpdates = 0;
      var storeLaunches = 0;
      final service = AppUpdateService(
        androidUpdateInfoLoader: () async => _FakeAppUpdateInfo(
          updateAvailability: in_app_update.UpdateAvailability.updateAvailable,
          flexibleUpdateAllowed: true,
        ),
        flexibleUpdateRunner: () async => flexibleUpdates++,
        completeFlexibleUpdateRunner: () async => completedFlexibleUpdates++,
        storeLauncher: (_) async {
          storeLaunches++;
          return true;
        },
      );

      await service.performUpdate(_updateResult());

      expect(flexibleUpdates, 1);
      expect(completedFlexibleUpdates, 1);
      expect(storeLaunches, 0);
    });

    test('opens store when Android Play Core is unavailable', () async {
      Uri? launchedUri;
      final service = AppUpdateService(
        androidUpdateInfoLoader: () async => throw StateError('Unavailable'),
        storeLauncher: (uri) async {
          launchedUri = uri;
          return true;
        },
      );

      await service.performUpdate(_updateResult());

      expect(launchedUri, Uri.parse('https://store.test/app'));
    });

    test('opens store directly on iOS', () async {
      Uri? launchedUri;
      final service = AppUpdateService(
        storeLauncher: (uri) async {
          launchedUri = uri;
          return true;
        },
      );

      await service.performUpdate(_updateResult(platform: AppPlatform.ios));

      expect(launchedUri, Uri.parse('https://store.test/app'));
    });

    test('does not open store when store URL is invalid', () async {
      var storeLaunches = 0;
      final service = AppUpdateService(
        storeLauncher: (_) async {
          storeLaunches++;
          return true;
        },
      );

      await service.performUpdate(_updateResult(storeLink: '://invalid-url'));

      expect(storeLaunches, 0);
    });
  });
}

AppUpdateService _service({
  required String currentBuildNumber,
  required Map<String, dynamic> policy,
  AppPlatform? Function()? platformResolver,
}) {
  return AppUpdateService(
    dio: _dio((options) {
      expect(options.method, 'GET');
      expect(options.uri.path, '/v1/app/version-policy');
      expect(options.uri.queryParameters['platform'], 'android');
      return _response(options, policy);
    }),
    packageInfoLoader: () => Future.value(_packageInfo(currentBuildNumber)),
    platformResolver: platformResolver ?? () => AppPlatform.android,
  );
}

Dio _dio(Response<dynamic> Function(RequestOptions options) responder) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.resolve(responder(options)),
    ),
  );
  return dio;
}

Response<dynamic> _response(RequestOptions options, Object? data) {
  return Response<dynamic>(
    requestOptions: options,
    statusCode: 200,
    data: data,
  );
}

PackageInfo _packageInfo(String buildNumber) {
  return PackageInfo(
    appName: 'Dineroo',
    packageName: 'com.dineroo.app',
    version: '1.2.3',
    buildNumber: buildNumber,
  );
}

AppUpdateResult _updateResult({
  bool forceUpdate = false,
  AppPlatform platform = AppPlatform.android,
  String storeLink = 'https://store.test/app',
}) {
  return AppUpdateResult(
    shouldShow: true,
    forceUpdate: forceUpdate,
    storeLink: storeLink,
    localVersion: '1.2.3+40',
    storeVersion: '60',
    message: 'Update available',
    platform: platform,
  );
}

class _FakeAppUpdateInfo {
  _FakeAppUpdateInfo({
    required this.updateAvailability,
    this.immediateUpdateAllowed = false,
    this.flexibleUpdateAllowed = false,
  });

  final in_app_update.UpdateAvailability updateAvailability;
  final bool immediateUpdateAllowed;
  final bool flexibleUpdateAllowed;
}
