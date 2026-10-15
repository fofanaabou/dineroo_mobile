import 'dart:async';
import 'dart:typed_data';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class FakeStompClient implements StompClient {
  @override
  final StompConfig config;

  bool _connected = false;
  bool _isActive = false;
  final Map<String, StompFrameCallback> subscriptions = {};
  final List<Map<String, dynamic>> sentMessages = [];

  FakeStompClient({required this.config});

  @override
  bool get connected => _connected;

  @override
  bool get isActive => _isActive;

  @override
  void activate() {
    _isActive = true;
    Future.microtask(() {
      if (!_isActive) return;
      _connected = true;
      config.onConnect(StompFrame(command: 'CONNECTED'));
    });
  }

  @override
  void deactivate() {
    _isActive = false;
    _connected = false;
    subscriptions.clear();
  }

  @override
  StompUnsubscribe subscribe({
    required String destination,
    required StompFrameCallback callback,
    Map<String, String>? headers,
  }) {
    subscriptions[destination] = callback;
    return ({Map<String, String>? unsubscribeHeaders}) {
      subscriptions.remove(destination);
    };
  }

  @override
  void send({
    required String destination,
    Map<String, String>? headers,
    String? body,
    Uint8List? binaryBody,
  }) {
    sentMessages.add({
      'destination': destination,
      'headers': headers,
      'body': body,
    });
  }

  @override
  void ack({required String id, Map<String, String>? headers}) {}

  @override
  void nack({required String id, Map<String, String>? headers}) {}
}
