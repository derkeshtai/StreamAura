import 'package:just_audio/just_audio.dart';
import '../models/models.dart';

class StreamAudioService {
  final AudioPlayer _player = AudioPlayer();

  RadioStation? _currentStation;

  // Getters
  RadioStation? get currentStation => _currentStation;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  bool get isPlaying => _player.playing;

  Future<void> playStation(RadioStation station) async {
    try {
      _currentStation = station;
      await _player.setUrl(station.streamUrl);
      await _player.play();
    } catch (e) {
      print('Error playing station: $e');
      rethrow;
    }
  }

  Future<void> playUrl(String url) async {
    try {
      await _player.setUrl(url);
      await _player.play();
    } catch (e) {
      print('Error playing URL: $e');
      rethrow;
    }
  }

  Future<void> play() async {
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> stop() async {
    await _player.stop();
    _currentStation = null;
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// Get current position for momento timestamp
  Duration? get currentPosition => _player.position;

  void dispose() {
    _player.dispose();
  }
}
