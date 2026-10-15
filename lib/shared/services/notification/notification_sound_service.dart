import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class NotificationSoundService {
  static final NotificationSoundService _instance =
      NotificationSoundService._internal();

  factory NotificationSoundService() => _instance;

  @visibleForTesting
  static AudioPlayer Function() playerFactory = () => AudioPlayer();

  late final AudioPlayer _player = playerFactory();
  bool _isPlaying = false;

  NotificationSoundService._internal();

  bool get isPlaying => _isPlaying;

  Future<void> playLoop() async {
    if (_isPlaying) return;
    _isPlaying = true;
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(AssetSource('sounds/notification.mp3'));
  }

  Future<void> playOnce() async {
    final player = playerFactory();
    await player.setReleaseMode(ReleaseMode.release);
    await player.play(AssetSource('sounds/notification.mp3'));
    player.onPlayerComplete.first.then((_) => player.dispose());
  }

  Future<void> stop() async {
    if (!_isPlaying) return;
    _isPlaying = false;
    await _player.stop();
  }

  Future<void> disposeForLogout() async {
    _isPlaying = false;
    await _player.stop();
    await _player.release();
  }
}
