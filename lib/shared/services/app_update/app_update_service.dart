import 'dart:io';

import 'package:dineroo_mobile/shared/common/constants/constants.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_uri_builder.dart';
import 'package:dineroo_mobile/shared/common/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateService {
  AppUpdateService({
    Dio? dio,
    Future<PackageInfo> Function()? packageInfoLoader,
    AppPlatform? Function()? platformResolver,
    Future<dynamic> Function()? androidUpdateInfoLoader,
    Future<void> Function()? immediateUpdateRunner,
    Future<void> Function()? flexibleUpdateRunner,
    Future<void> Function()? completeFlexibleUpdateRunner,
    Future<bool> Function(Uri uri)? storeLauncher,
  }) : _dio = dio ?? createPublicDioClient(),
       _packageInfoLoader = packageInfoLoader ?? PackageInfo.fromPlatform,
       _platformResolver = platformResolver,
       _androidUpdateInfoLoader =
           androidUpdateInfoLoader ?? InAppUpdate.checkForUpdate,
       _immediateUpdateRunner =
           immediateUpdateRunner ??
           (() async {
             await InAppUpdate.performImmediateUpdate();
           }),
       _flexibleUpdateRunner =
           flexibleUpdateRunner ??
           (() async {
             await InAppUpdate.startFlexibleUpdate();
           }),
       _completeFlexibleUpdateRunner =
           completeFlexibleUpdateRunner ??
           (() async {
             await InAppUpdate.completeFlexibleUpdate();
           }),
       _storeLauncher =
           storeLauncher ??
           ((uri) => launchUrl(uri, mode: LaunchMode.externalApplication));

  final Dio _dio;
  final Future<PackageInfo> Function() _packageInfoLoader;
  final AppPlatform? Function()? _platformResolver;
  final Future<dynamic> Function() _androidUpdateInfoLoader;
  final Future<void> Function() _immediateUpdateRunner;
  final Future<void> Function() _flexibleUpdateRunner;
  final Future<void> Function() _completeFlexibleUpdateRunner;
  final Future<bool> Function(Uri uri) _storeLauncher;
  bool _checkedThisSession = false;

  Future<AppUpdateResult> checkForUpdate() async {
    if (_checkedThisSession) return AppUpdateResult.none();
    _checkedThisSession = true;

    final platform = _currentPlatform;
    if (platform == null) return AppUpdateResult.none();

    try {
      final packageInfo = await _packageInfoLoader();
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;
      final policy = await _fetchPolicy(platform);
      final updateRequired =
          policy.forceUpdate || currentBuildNumber < policy.minimumBuildNumber;
      final updateAvailable = currentBuildNumber < policy.latestBuildNumber;

      if (!updateRequired && !updateAvailable) return AppUpdateResult.none();

      return AppUpdateResult(
        shouldShow: true,
        forceUpdate: updateRequired,
        storeLink: policy.storeUrl,
        localVersion: '${packageInfo.version}+$currentBuildNumber',
        storeVersion: '${policy.latestBuildNumber}',
        message: policy.message,
        platform: platform,
      );
    } catch (_) {
      return AppUpdateResult.none();
    }
  }

  Future<void> performUpdate(AppUpdateResult result) async {
    if (result.platform == AppPlatform.android) {
      try {
        final info = await _androidUpdateInfoLoader();
        final updateAvailable =
            info.updateAvailability == UpdateAvailability.updateAvailable;

        if (updateAvailable &&
            result.forceUpdate &&
            info.immediateUpdateAllowed) {
          await _immediateUpdateRunner();
          return;
        }

        if (updateAvailable &&
            !result.forceUpdate &&
            info.flexibleUpdateAllowed) {
          await _flexibleUpdateRunner();
          await _completeFlexibleUpdateRunner();
          return;
        }
      } catch (_) {
        // Fall back to the store URL when Play Core is unavailable.
      }
    }

    final uri = Uri.tryParse(result.storeLink);
    if (uri != null) {
      await _storeLauncher(uri);
    }
  }

  Future<AppVersionPolicy> _fetchPolicy(AppPlatform platform) async {
    final response = await _dio.getUri<Map<String, dynamic>>(
      ApiUriBuilder.build(
        ApiConstants.appVersionPolicy,
        queryParameters: {'platform': platform.name},
      ),
    );

    final data = response.data;
    if (data == null) throw StateError('Missing app version policy');
    return AppVersionPolicy.fromJson(data);
  }

  AppPlatform? get _currentPlatform {
    final resolvedPlatform = _platformResolver?.call();
    if (resolvedPlatform != null) return resolvedPlatform;
    if (kIsWeb) return null;
    if (Platform.isAndroid) return AppPlatform.android;
    if (Platform.isIOS) return AppPlatform.ios;
    return null;
  }
}

class AppVersionPolicy {
  AppVersionPolicy({
    required this.minimumBuildNumber,
    required this.latestBuildNumber,
    required this.storeUrl,
    required this.forceUpdate,
    required this.message,
  });

  final int minimumBuildNumber;
  final int latestBuildNumber;
  final String storeUrl;
  final bool forceUpdate;
  final String message;

  factory AppVersionPolicy.fromJson(Map<String, dynamic> json) {
    return AppVersionPolicy(
      minimumBuildNumber: _readInt(json['minimumBuildNumber']),
      latestBuildNumber: _readInt(json['latestBuildNumber']),
      storeUrl: json['storeUrl'] as String? ?? '',
      forceUpdate: json['forceUpdate'] as bool? ?? false,
      message:
          json['message'] as String? ??
          'Une nouvelle version de Dineroo est disponible.',
    );
  }

  static int _readInt(Object? value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class AppUpdateResult {
  AppUpdateResult({
    required this.shouldShow,
    required this.storeLink,
    required this.localVersion,
    required this.storeVersion,
    required this.message,
    this.forceUpdate = false,
    this.platform,
  });

  final bool shouldShow;
  final bool forceUpdate;
  final String storeLink;
  final String localVersion;
  final String storeVersion;
  final String message;
  final AppPlatform? platform;

  static AppUpdateResult none() => AppUpdateResult(
    shouldShow: false,
    storeLink: '',
    localVersion: '',
    storeVersion: '',
    message: '',
  );
}

enum AppPlatform { android, ios }
