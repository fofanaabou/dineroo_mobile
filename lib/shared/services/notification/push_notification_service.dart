import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:dineroo_mobile/customer/models/domain/user.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/enums/push_notification_type.dart';
import 'package:dineroo_mobile/shared/models/domain/push_notification_payload.dart';
import 'package:dineroo_mobile/shared/services/notification/notification_sound_service.dart';
import 'package:dineroo_mobile/shared/services/user/user_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

const FirebaseOptions _iosFirebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyC2I2fX0BZbasAkT4g_lhVtHmgdxYstglY',
  appId: '1:304362969930:ios:8564ab3284f28865d83fb3',
  messagingSenderId: '304362969930',
  projectId: 'dineroo-b329f',
  storageBucket: 'dineroo-b329f.firebasestorage.app',
  iosBundleId: 'com.dineroo.app',
);

Future<FirebaseApp> _initializeFirebaseApp() async {
  if (Firebase.apps.isNotEmpty) {
    return Firebase.app();
  }
  if (Platform.isIOS) {
    return Firebase.initializeApp(options: _iosFirebaseOptions);
  }
  return Firebase.initializeApp();
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  final _ = message;
  await _initializeFirebaseApp();
}

class PushNotificationService {
  static const Duration _silentPushSyncInterval = Duration(hours: 24);
  static const Duration _silentPushSyncCheckInterval = Duration(hours: 6);
  static const Duration _initialMessageTimeout = Duration(seconds: 5);
  static const String _pushSyncBoxName = 'push_sync';
  static const String _lastPushSyncAtKey = 'lastPushSyncAt';
  static const String _foregroundChannelId = 'dineroo_foreground_notifications';
  static const String _foregroundChannelName = 'Foreground notifications';
  static const String _foregroundChannelDescription =
      'Notifications shown while the app is open';
  static const List<Duration> _pushRegistrationRetryDelays = [
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 15),
    Duration(seconds: 30),
  ];

  static final PushNotificationService _instance =
      PushNotificationService._internal();

  factory PushNotificationService() => _instance;

  PushNotificationService._internal();

  late FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final UserService _userService = UserService();
  final StreamController<Map<String, dynamic>> _openedMessagesController =
      StreamController<Map<String, dynamic>>.broadcast();
  final Set<String> _pendingRegistrationRetries = <String>{};
  final Set<String> _pendingSyncRetries = <String>{};
  Map<String, dynamic>? _pendingOpenedMessage;
  Map<String, dynamic>? _pendingNavigationPayload;
  Timer? _silentPushSyncTimer;
  bool _initialized = false;
  Future<void>? _initializationFuture;

  Stream<Map<String, dynamic>> get openedMessages =>
      _openedMessagesController.stream;

  Map<String, dynamic>? takePendingOpenedMessage() {
    final message = _pendingOpenedMessage;
    _pendingOpenedMessage = null;
    return message;
  }

  void savePendingNavigationPayload(Map<String, dynamic> data) {
    _pendingNavigationPayload = Map<String, dynamic>.from(data);
  }

  Map<String, dynamic>? takePendingNavigationPayload() {
    final payload = _pendingNavigationPayload;
    _pendingNavigationPayload = null;
    return payload;
  }

  @visibleForTesting
  String debugTokenPreview(String token) => _tokenPreview(token);

  @visibleForTesting
  bool debugShouldTriggerRealtimeFallbackFromPush(Map<String, dynamic> data) =>
      _shouldTriggerRealtimeFallbackFromPush(data);

  @visibleForTesting
  void debugQueueOpenedMessage(Map<String, dynamic> data) {
    _queueOpenedMessage(data);
  }

  @visibleForTesting
  void debugHandleLocalNotificationResponse(NotificationResponse response) {
    _handleLocalNotificationResponse(response);
  }

  @visibleForTesting
  Future<bool> debugShouldSilentlySyncDeviceToken() =>
      _shouldSilentlySyncDeviceToken();

  @visibleForTesting
  Future<void> debugMarkSilentPushSyncNow() => _markSilentPushSyncNow();

  @visibleForTesting
  void debugResetForTesting() {
    _pendingRegistrationRetries.clear();
    _pendingSyncRetries.clear();
    _pendingOpenedMessage = null;
    _pendingNavigationPayload = null;
    _silentPushSyncTimer?.cancel();
    _silentPushSyncTimer = null;
    _initialized = false;
    _initializationFuture = null;
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final existingInitialization = _initializationFuture;
    if (existingInitialization != null) {
      await existingInitialization;
      return;
    }

    _initializationFuture = _initialize();
    try {
      await _initializationFuture;
    } catch (_) {
      _initializationFuture = null;
      rethrow;
    }
  }

  Future<void> _initialize() async {
    final firebaseApp = await _initializeFirebaseApp();
    logger.i(
      '[Push] Firebase initialized: '
      'name=${firebaseApp.name}, projectId=${firebaseApp.options.projectId}',
    );

    _messaging = FirebaseMessaging.instance;
    await _initializeLocalNotifications();

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _messaging.setAutoInitEnabled(true);
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);
    _messaging.onTokenRefresh.listen(_handleTokenRefresh);

    final initialMessage = await _messaging.getInitialMessage().timeout(
      _initialMessageTimeout,
      onTimeout: () {
        logger.w(
          '[Push] Initial notification message check timed out; continuing',
        );
        return null;
      },
    );
    if (initialMessage != null) {
      _queueOpenedMessage(initialMessage.data);
    }

    _startSilentPushSyncTimer();

    _initialized = true;
  }

  Future<void> syncUserDeviceToken(String userId) async {
    try {
      await initialize();
      await _requestPermissionIfNeeded();

      final settings = await _messaging.getNotificationSettings();
      final isAuthorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (!isAuthorized) {
        logger.w(
          '[Push] Permission not granted '
          '(${settings.authorizationStatus}), skipping device token sync',
        );
        return;
      }

      final token = await _getFcmTokenOrNull();
      if (token == null || token.isEmpty) {
        logger.w('[Push] No FCM token available yet');
        _scheduleDeviceTokenSyncRetry(userId);
        return;
      }

      logger.i(
        '[Push] Syncing token for userId=$userId token=${_tokenPreview(token)}',
      );

      await _registerDeviceToken(userId: userId, token: token);
      await _markSilentPushSyncNow();
    } catch (e, stack) {
      logger.e(
        '[Push] Failed to sync device token for userId=$userId',
        error: e,
        stackTrace: stack,
      );

      if (_initialized) {
        final token = await _getFcmTokenOrNull();
        if (token != null && token.isNotEmpty) {
          _scheduleDeviceTokenRegistrationRetry(userId: userId, token: token);
        }
      } else {
        logger.w('[Push] Token retry skipped because push is not initialized');
      }
    }
  }

  Future<void> syncPersistedUserDeviceToken() async {
    final user = await _loadUserFromPersistedToken();
    if (user == null) {
      logger.w('[Push] No authenticated user found for device token sync');
      return;
    }

    await syncUserDeviceToken(user.id);
  }

  Future<void> silentlySyncPersistedUserDeviceTokenIfNeeded() async {
    final shouldSync = await _shouldSilentlySyncDeviceToken();
    if (!shouldSync) {
      return;
    }

    logger.i('[Push] Running silent periodic device token sync');
    await syncPersistedUserDeviceToken();
  }

  Future<void> unregisterUserDeviceToken(String userId) async {
    await initialize();
    final token = await _getFcmTokenOrNull();
    if (token == null || token.isEmpty) {
      logger.w('[Push] No FCM token available to unregister');
      return;
    }

    try {
      await _userService.deleteDeviceToken(
        userId: userId,
        token: token,
        platform: _platformName,
      );
    } catch (e, stack) {
      logger.e(
        '[Push] Failed to unregister token for userId=$userId.',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<void> _requestPermissionIfNeeded() async {
    final settings = await _messaging.getNotificationSettings();
    final shouldRequestPermission =
        settings.authorizationStatus == AuthorizationStatus.notDetermined ||
        (Platform.isAndroid &&
            settings.authorizationStatus == AuthorizationStatus.denied);

    if (!shouldRequestPermission) {
      logger.i(
        '[Push] Skipping permission request, current status: '
        '${settings.authorizationStatus}',
      );
      return;
    }

    final result = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    logger.i(
      '[Push] Notification permission status: ${result.authorizationStatus}',
    );
  }

  Future<void> _handleTokenRefresh(String token) async {
    final user = await _loadUserFromPersistedToken();
    if (user == null) {
      logger.w('[Push] Token refreshed but no authenticated user was found');
      return;
    }

    try {
      logger.i(
        '[Push] Refreshing token for userId=${user.id} token=${_tokenPreview(token)}',
      );
      await _registerDeviceToken(userId: user.id, token: token);
      await _markSilentPushSyncNow();
    } catch (e, stack) {
      logger.e(
        '[Push] Failed to refresh token registration',
        error: e,
        stackTrace: stack,
      );
      _scheduleDeviceTokenRegistrationRetry(userId: user.id, token: token);
    }
  }

  Future<void> _registerDeviceToken({
    required String userId,
    required String token,
  }) {
    return _userService.registerDeviceToken(
      userId: userId,
      token: token,
      platform: _platformName,
    );
  }

  Future<String?> _getFcmTokenOrNull() async {
    try {
      final hasApnsToken = await _hasApnsTokenIfNeeded();
      if (!hasApnsToken) {
        return null;
      }
      return await _messaging.getToken();
    } on FirebaseException catch (e, stack) {
      if (e.code == 'apns-token-not-set') {
        logger.w(
          '[Push] APNS token not available yet; skipping FCM token sync',
        );
        return null;
      }
      logger.e('[Push] Failed to get FCM token', error: e, stackTrace: stack);
      return null;
    } catch (e, stack) {
      logger.e('[Push] Failed to get FCM token', error: e, stackTrace: stack);
      return null;
    }
  }

  Future<bool> _hasApnsTokenIfNeeded() async {
    if (!Platform.isIOS) {
      return true;
    }
    final apnsToken = await _messaging.getAPNSToken();
    if (apnsToken != null && apnsToken.isNotEmpty) {
      logger.i('[Push] APNS token available');
      return true;
    }
    logger.w('[Push] APNS token not available yet; FCM token sync deferred');
    return false;
  }

  String _tokenPreview(String token) {
    if (token.length <= 16) {
      return token;
    }

    return '${token.substring(0, 8)}...${token.substring(token.length - 8)}';
  }

  void _scheduleDeviceTokenRegistrationRetry({
    required String userId,
    required String token,
  }) {
    final retryKey = '$userId:$token';
    if (!_pendingRegistrationRetries.add(retryKey)) {
      logger.i('[Push] Token registration retry already scheduled for $userId');
      return;
    }

    unawaited(
      Future<void>(() async {
        try {
          for (final delay in _pushRegistrationRetryDelays) {
            await Future.delayed(delay);

            try {
              await _registerDeviceToken(userId: userId, token: token);
              await _markSilentPushSyncNow();
              logger.i('[Push] Token registration retry succeeded for $userId');
              return;
            } catch (e, stack) {
              logger.e(
                '[Push] Token registration retry failed for $userId after '
                '${delay.inSeconds}s',
                error: e,
                stackTrace: stack,
              );
            }
          }

          logger.e(
            '[Push] Token registration exhausted all retries for $userId',
          );
        } finally {
          _pendingRegistrationRetries.remove(retryKey);
        }
      }),
    );
  }

  void _scheduleDeviceTokenSyncRetry(String userId) {
    if (!_pendingSyncRetries.add(userId)) {
      logger.i('[Push] Device token sync retry already scheduled for $userId');
      return;
    }
    unawaited(
      Future<void>(() async {
        try {
          for (final delay in _pushRegistrationRetryDelays) {
            await Future.delayed(delay);

            final token = await _getFcmTokenOrNull();
            if (token == null || token.isEmpty) {
              logger.w(
                '[Push] Device token sync retry found no FCM token for '
                '$userId after ${delay.inSeconds}s',
              );
              continue;
            }

            try {
              await _registerDeviceToken(userId: userId, token: token);
              await _markSilentPushSyncNow();
              logger.i('[Push] Device token sync retry succeeded for $userId');
              return;
            } catch (e, stack) {
              logger.e(
                '[Push] Device token sync retry failed for $userId after '
                '${delay.inSeconds}s',
                error: e,
                stackTrace: stack,
              );
            }
          }
          logger.e(
            '[Push] Device token sync exhausted all retries for $userId',
          );
        } finally {
          _pendingSyncRetries.remove(userId);
        }
      }),
    );
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final title = notification?.title ?? 'Dineroo';
    final body = notification?.body ?? 'Vous avez une nouvelle notification.';
    final data = Map<String, dynamic>.from(message.data);

    logger.i('[Push] Foreground notification received: $title');
    NotificationSoundService().playOnce();

    if (_shouldTriggerRealtimeFallbackFromPush(data)) {
      logger.i(
        '[Push] Triggering foreground navigation fallback for driver assignment',
      );
      _queueOpenedMessage(data);
    }

    unawaited(
      _showForegroundLocalNotification(title: title, body: body, data: data),
    );
  }

  bool _shouldTriggerRealtimeFallbackFromPush(Map<String, dynamic> data) {
    final payload = PushNotificationPayload.fromData(data);
    return payload.type == PushNotificationType.driverDeliveryAssigned ||
        payload.type == PushNotificationType.deliveryAssigned;
  }

  void _handleMessageOpened(RemoteMessage message) {
    _queueOpenedMessage(message.data);
  }

  void _queueOpenedMessage(Map<String, dynamic> data) {
    logger.i('[Push] Notification opened with data: $data');
    _pendingOpenedMessage = data;
    _openedMessagesController.add(data);
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();

    await _localNotificationsPlugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _handleLocalNotificationResponse,
    );

    if (Platform.isIOS) {
      logger.i(
        '[Push] Skipping local notification permission request during startup',
      );
    }

    const androidChannel = AndroidNotificationChannel(
      _foregroundChannelId,
      _foregroundChannelName,
      description: _foregroundChannelDescription,
      importance: Importance.max,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  Future<void> _showForegroundLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    await _localNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _foregroundChannelId,
          _foregroundChannelName,
          channelDescription: _foregroundChannelDescription,
          icon: 'ic_launcher_foreground',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(data),
    );
  }

  void _handleLocalNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        _queueOpenedMessage(decoded);
        return;
      }

      if (decoded is Map) {
        _queueOpenedMessage(Map<String, dynamic>.from(decoded));
      }
    } catch (e, stack) {
      logger.e(
        '[Push] Failed to decode local notification payload',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<User?> _loadUserFromPersistedToken() async {
    final authBox = await Hive.openBox('auth');
    final accessToken = authBox.get('accessToken');

    if (accessToken is! String || accessToken.isEmpty) {
      return null;
    }

    final decodedToken = JwtDecoder.decode(accessToken);
    return User.fromToken(decodedToken);
  }

  void _startSilentPushSyncTimer() {
    _silentPushSyncTimer?.cancel();
    _silentPushSyncTimer = Timer.periodic(_silentPushSyncCheckInterval, (_) {
      unawaited(silentlySyncPersistedUserDeviceTokenIfNeeded());
    });
  }

  Future<bool> _shouldSilentlySyncDeviceToken() async {
    final syncBox = await Hive.openBox(_pushSyncBoxName);
    final lastSyncAtRaw = syncBox.get(_lastPushSyncAtKey);
    if (lastSyncAtRaw is! String || lastSyncAtRaw.isEmpty) {
      return true;
    }

    final lastSyncAt = DateTime.tryParse(lastSyncAtRaw);
    if (lastSyncAt == null) {
      return true;
    }

    return DateTime.now().difference(lastSyncAt) >= _silentPushSyncInterval;
  }

  Future<void> _markSilentPushSyncNow() async {
    final syncBox = await Hive.openBox(_pushSyncBoxName);
    await syncBox.put(_lastPushSyncAtKey, DateTime.now().toIso8601String());
  }

  String get _platformName => Platform.isIOS ? 'IOS' : 'ANDROID';
}
