import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  Future<void> playAlarm() async {
    if (_isPlaying) return;

    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(1.0);
    await _player.setSource(AssetSource('alarm.mp3'));
    await _player.resume();
    _isPlaying = true;
  }

  Future<void> stopAlarm() async {
    await _player.stop();
    _isPlaying = false;
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  void dispose() {
    _player.dispose();
  }
}
