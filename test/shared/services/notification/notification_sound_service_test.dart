import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:dineroo_mobile/shared/services/notification/notification_sound_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAudioPlayer extends AudioPlayer {
  ReleaseMode? setReleaseModeParam;
  Source? playSourceParam;
  bool stopCalled = false;
  bool releaseCalled = false;
  bool disposeCalled = false;

  final StreamController<void> _completerController =
      StreamController<void>.broadcast();

  @override
  Future<void> setReleaseMode(ReleaseMode releaseMode) async {
    setReleaseModeParam = releaseMode;
  }

  @override
  Future<void> play(
    Source source, {
    double? volume,
    double? balance,
    AudioContext? ctx,
    Duration? position,
    PlayerMode? mode,
  }) async {
    playSourceParam = source;
  }

  @override
  Stream<void> get onPlayerComplete => _completerController.stream;

  @override
  Future<void> stop() async {
    stopCalled = true;
  }

  @override
  Future<void> release() async {
    releaseCalled = true;
  }

  void emitComplete() {
    _completerController.add(null);
  }

  @override
  Future<void> dispose() async {
    disposeCalled = true;
    await _completerController.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('xyz.luan/audioplayers');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (message) async {
          if (message.method == 'create') return 'player-1';
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('NotificationSoundService', () {
    setUp(() {
      NotificationSoundService.playerFactory = () => FakeAudioPlayer();
    });

    tearDown(() async {
      NotificationSoundService.playerFactory = () => AudioPlayer();
      await NotificationSoundService().stop();
    });

    test('playLoop sets loop mode and plays', () async {
      final service = NotificationSoundService();

      await service.playLoop();

      expect(service.isPlaying, true);
    });

    test('playLoop does nothing when already playing', () async {
      final service = NotificationSoundService();

      await service.playLoop();
      await service.playLoop();

      expect(service.isPlaying, true);
    });

    test('playOnce creates player and leaves isPlaying false', () async {
      final service = NotificationSoundService();

      await service.playOnce();

      expect(service.isPlaying, false);
    });

    test('stop stops the player', () async {
      final service = NotificationSoundService();

      await service.playLoop();
      await service.stop();

      expect(service.isPlaying, false);
    });

    test('stop does nothing when not playing', () async {
      final service = NotificationSoundService();

      await service.stop();

      expect(service.isPlaying, false);
    });

    test('disposeForLogout stops and releases', () async {
      final service = NotificationSoundService();

      await service.playLoop();
      await service.disposeForLogout();

      expect(service.isPlaying, false);
    });

    test('isPlaying returns false initially', () {
      final service = NotificationSoundService();

      expect(service.isPlaying, false);
    });
  });
}
