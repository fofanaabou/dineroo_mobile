import 'dart:async';
import 'dart:convert';
import 'package:dineroo_mobile/shared/common/constants/constants.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/common/helpers/url_helper.dart';
import 'package:dineroo_mobile/shared/realtime/stomp_subscription_manager.dart';
import 'package:flutter/foundation.dart';

class StompRealtimeService {
  static final StompRealtimeService _instance =
      StompRealtimeService._internal();

  factory StompRealtimeService() => _instance;

  StompRealtimeService._internal() {
    _subscriptionManager = StompSubscriptionManager(this);
  }

  @visibleForTesting
  static StompClient Function(StompConfig config)? clientFactory;

  StompClient? _client;
  bool _isConnected = false;
  bool _isConnecting = false;
  int _connectAttempts = 0;
  String? _token;
  String? _userRole;
  String? _restaurantId;
  String? _userId;

  late final StompSubscriptionManager _subscriptionManager;

  StompClient _createClient(StompConfig config) {
    if (clientFactory != null) {
      return clientFactory!(config);
    }
    return StompClient(config: config);
  }

  final Map<String, void Function(String body)> _subscriptions = {};
  final Map<String, StompUnsubscribe> _activeSubscriptions = {};
  static const int _maxConnectAttempts = 8;

  bool get isConnected => _isConnected;

  Future<void> connect({
    required String token,
    required String userRole,
    String? restaurantId,
    String? userId,
  }) async {
    if (_isConnected) {
      logger.i('[RT] Already connected');
      return;
    }

    if (_isConnecting) {
      logger.i('[RT] Connection already in progress');
      return;
    }

    if (_connectAttempts >= _maxConnectAttempts) {
      logger.e(
        '[RT] Max STOMP attempts reached ($_connectAttempts/$_maxConnectAttempts). '
        'Call disconnect() then connect() to retry manually.',
      );
      return;
    }

    _token = token;
    _userRole = userRole;
    _restaurantId = restaurantId;
    _userId = userId;

    final baseUrl = getApiBaseUrl();
    final supportedApiVersions = <String>[ApiConstants.apiVersion, '/v2'];
    final versionsPattern = supportedApiVersions
        .map(RegExp.escape)
        .map((version) => '$version\$')
        .join('|');
    final wsUrl = baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://')
        .replaceFirst(RegExp(versionsPattern), '');

    final url = '$wsUrl/realtime';
    logger.i('[RT] Connecting to STOMP at $url...');

    _client = _createClient(StompConfig(
        url: url,
        onConnect: _onConnect,
        beforeConnect: () async {
          if (_connectAttempts >= _maxConnectAttempts) {
            _isConnecting = false;
            throw Exception('[RT] STOMP retries exhausted before connect');
          }
          _isConnecting = true;
          _connectAttempts += 1;
          logger.i(
            '[RT] STOMP attempt $_connectAttempts/$_maxConnectAttempts to $url',
          );
          await Future.delayed(const Duration(milliseconds: 300));
        },
        onWebSocketError: (e) {
          _isConnecting = false;
          logger.e(
            '[RT] WS Error (attempt $_connectAttempts/$_maxConnectAttempts): $e',
          );
          if (!_isConnected && _connectAttempts >= _maxConnectAttempts) {
            logger.e('[RT] Auto-reconnect exhausted, stopping STOMP client');
            try {
              _client?.deactivate();
            } catch (_) {}
            _client = null;
          }
        },
        onStompError: (frame) {
          logger.e(
            '[RT] STOMP Error (attempt $_connectAttempts/$_maxConnectAttempts): '
            'command=${frame.command} headers=${frame.headers} body=${frame.body}',
          );
        },
        onDisconnect: (_) {
          _isConnecting = false;
          _isConnected = false;
          _activeSubscriptions.clear();
          logger.w(
            '[RT] Disconnected from STOMP '
            '(attempts=$_connectAttempts/$_maxConnectAttempts)',
          );
        },
        onWebSocketDone: () {
          _isConnecting = false;
          _isConnected = false;
          _activeSubscriptions.clear();
          logger.w(
            '[RT] WebSocket closed (attempts=$_connectAttempts/$_maxConnectAttempts)',
          );
          Future.microtask(() => reconnectIfNeeded());
        },
        reconnectDelay: const Duration(seconds: 5),
        heartbeatIncoming: Duration.zero,
        stompConnectHeaders: {'Authorization': 'Bearer $_token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $_token'},
      ),
    );

    _client!.activate();
  }

  void _onConnect(StompFrame frame) {
    _isConnected = true;
    _isConnecting = false;
    _connectAttempts = 0;
    logger.i('[RT] Connected to STOMP');

    _subscriptionManager.autoSubscribeForRole(
      _userRole ?? '',
      _restaurantId,
      _userId,
    );

    if (_subscriptions.isNotEmpty) {
      logger.i(
        '[RT] Re-subscribing to ${_subscriptions.length} destinations...',
      );
      _activeSubscriptions.clear();

      _subscriptions.forEach((destination, callback) {
        _subscribeInternal(destination, callback);
      });
    }
  }

  void _subscribeInternal(
    String destination,
    void Function(String body) onMessage,
  ) {
    if (_client == null) return;

    final previousUnsubscribe = _activeSubscriptions.remove(destination);
    previousUnsubscribe?.call();

    final unsubscribe = _client!.subscribe(
      destination: destination,
      callback: (frame) {
        if (frame.body != null) {
          onMessage(frame.body!);
        }
      },
    );

    _activeSubscriptions[destination] = unsubscribe;
  }

  Future<void> reconnectIfNeeded() async {
    if (_isConnected || _client?.connected == true) return;

    if (_token == null || _token!.isEmpty) {
      logger.w('[RT] Cannot reconnect — missing token');
      return;
    }

    if (_isConnecting) {
      logger.i('[RT] Reconnect skipped — a connection attempt is in progress');
      return;
    }

    logger.i('[RT] Attempting reconnection...');

    try {
      _client?.deactivate();
    } catch (_) {}

    await connect(
      token: _token!,
      userRole: _userRole ?? '',
      restaurantId: _restaurantId,
      userId: _userId,
    );
  }

  Future<void> disconnect({
    bool clearSession = true,
    bool clearSubscriptions = true,
  }) async {
    if (_client == null) return;

    logger.i('[RT] Disconnecting from STOMP...');

    for (final unsubscribe in _activeSubscriptions.values) {
      unsubscribe();
    }

    _activeSubscriptions.clear();
    if (clearSubscriptions) {
      _subscriptions.clear();
    }

    try {
      _client!.deactivate();
    } catch (_) {}

    _isConnected = false;
    _isConnecting = false;
    _connectAttempts = 0;
    _client = null;
    if (clearSession) {
      _token = null;
      _userRole = null;
      _restaurantId = null;
      _userId = null;
    }
  }

  Future<void> subscribe({
    required String destination,
    required Function(String body) onMessage,
  }) async {
    _subscriptions[destination] = onMessage;

    if (!_isConnected || _client == null) {
      logger.w(
        '[RT] Not connected yet, subscription deferred for $destination',
      );
      return;
    }

    logger.i('[RT] Subscribing to $destination...');
    _subscribeInternal(destination, onMessage);
  }

  void unsubscribe(String destination) {
    logger.i('[RT] Unsubscribing from $destination');
    _subscriptions.remove(destination);
    final unsubscribe = _activeSubscriptions.remove(destination);
    unsubscribe?.call();
  }

  void sendDriverLocation({
    required String driverId,
    required double longitude,
    required double latitude,
  }) {
    if (!_isConnected || _client == null) {
      logger.w('[RT] Driver location skipped: socket not connected');
      return;
    }

    final payload = jsonEncode({
      'driverId': driverId,
      'longitude': longitude,
      'latitude': latitude,
    });

    try {
      _client!.send(destination: '/app/driver-location', body: payload);
    } catch (e, stack) {
      _isConnected = false;
      logger.e(
        '[RT] Failed to send driver location: socket is not writable',
        error: e,
        stackTrace: stack,
      );
      unawaited(reconnectIfNeeded());
    }
  }
}
