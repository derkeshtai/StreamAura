import 'dart:async';
import '../models/models.dart';
import 'firebase_service.dart';

/// Service to handle momento creation and playback
class MomentoService {
  final FirebaseService _firebaseService;

  // Buffer info - stores recent playback info
  final List<BufferEntry> _buffer = [];
  static const int _bufferMaxEntries = 50; // ~4 minutes of entries at 5sec intervals
  static const Duration _bufferInterval = Duration(seconds: 5);

  Timer? _bufferTimer;
  String? _currentWebcamUrl;
  String? _currentAudioUrl;
  DateTime? _webcamStartTime;
  DateTime? _audioStartTime;

  MomentoService(this._firebaseService);

  /// Start recording buffer for current playback
  void startBuffering({
    required String webcamUrl,
    required String audioUrl,
  }) {
    _currentWebcamUrl = webcamUrl;
    _currentAudioUrl = audioUrl;
    _webcamStartTime = DateTime.now();
    _audioStartTime = DateTime.now();
    _buffer.clear();

    _bufferTimer?.cancel();
    _bufferTimer = Timer.periodic(_bufferInterval, (_) => _recordBufferEntry());
  }

  void _recordBufferEntry() {
    if (_currentWebcamUrl == null || _currentAudioUrl == null) return;

    _buffer.add(BufferEntry(
      timestamp: DateTime.now(),
      webcamUrl: _currentWebcamUrl!,
      audioUrl: _currentAudioUrl!,
      webcamOffset: DateTime.now().difference(_webcamStartTime!),
      audioOffset: DateTime.now().difference(_audioStartTime!),
    ));

    // Keep buffer size limited
    while (_buffer.length > _bufferMaxEntries) {
      _buffer.removeAt(0);
    }
  }

  /// Stop buffering
  void stopBuffering() {
    _bufferTimer?.cancel();
    _bufferTimer = null;
  }

  /// Update webcam (resets webcam timing)
  void updateWebcam(String webcamUrl) {
    _currentWebcamUrl = webcamUrl;
    _webcamStartTime = DateTime.now();
  }

  /// Update audio (resets audio timing)
  void updateAudio(String audioUrl) {
    _currentAudioUrl = audioUrl;
    _audioStartTime = DateTime.now();
  }

  /// Get buffer entries from last N minutes
  List<BufferEntry> getRecentBuffer({Duration lookback = const Duration(minutes: 3)}) {
    final cutoff = DateTime.now().subtract(lookback);
    return _buffer.where((e) => e.timestamp.isAfter(cutoff)).toList();
  }

  /// Create a momento from current playback state
  /// [secondsAgo] - how many seconds ago the "perfect moment" started
  Future<Momento?> createMomento({
    required String title,
    String? description,
    required String webcamId,
    required String webcamName,
    required String audioId,
    required String audioName,
    int secondsAgo = 0,
    String? quoteText,
    String? quoteSource,
    Map<String, dynamic>? displaySettings,
    List<String> tags = const [],
  }) async {
    final userId = _firebaseService.currentUser?.uid;
    if (userId == null) return null;

    // Find the buffer entry closest to the specified time
    BufferEntry? targetEntry;
    if (secondsAgo > 0 && _buffer.isNotEmpty) {
      final targetTime = DateTime.now().subtract(Duration(seconds: secondsAgo));
      targetEntry = _buffer.reduce((a, b) {
        return (a.timestamp.difference(targetTime).abs() <
                b.timestamp.difference(targetTime).abs())
            ? a
            : b;
      });
    }

    final momento = Momento(
      id: '', // Will be set by Firestore
      title: title,
      description: description,
      webcamId: webcamId,
      webcamUrl: targetEntry?.webcamUrl ?? _currentWebcamUrl ?? '',
      webcamName: webcamName,
      videoTimestamp: targetEntry?.webcamOffset.inSeconds.toString(),
      audioId: audioId,
      audioUrl: targetEntry?.audioUrl ?? _currentAudioUrl ?? '',
      audioName: audioName,
      audioOffsetSeconds: targetEntry?.audioOffset.inSeconds,
      quoteText: quoteText,
      quoteSource: quoteSource,
      creatorId: userId,
      creatorName: _firebaseService.currentUser?.displayName,
      createdAt: DateTime.now(),
      tags: tags,
      displaySettings: displaySettings,
    );

    final docId = await _firebaseService.createMomento(momento);
    if (docId != null) {
      return momento.copyWith(id: docId);
    }
    return null;
  }

  /// Play a shared momento
  MomentoPlaybackInfo prepareMomentoPlayback(Momento momento) {
    return MomentoPlaybackInfo(
      webcamUrl: momento.webcamUrl,
      audioUrl: momento.audioUrl,
      videoTimestamp: momento.videoTimestamp,
      audioOffsetSeconds: momento.audioOffsetSeconds ?? 0,
      quoteText: momento.quoteText,
      displaySettings: momento.displaySettings,
    );
  }

  void dispose() {
    _bufferTimer?.cancel();
  }
}

/// Entry in the playback buffer
class BufferEntry {
  final DateTime timestamp;
  final String webcamUrl;
  final String audioUrl;
  final Duration webcamOffset;
  final Duration audioOffset;

  BufferEntry({
    required this.timestamp,
    required this.webcamUrl,
    required this.audioUrl,
    required this.webcamOffset,
    required this.audioOffset,
  });
}

/// Info needed to play back a momento
class MomentoPlaybackInfo {
  final String webcamUrl;
  final String audioUrl;
  final String? videoTimestamp;
  final int audioOffsetSeconds;
  final String? quoteText;
  final Map<String, dynamic>? displaySettings;

  MomentoPlaybackInfo({
    required this.webcamUrl,
    required this.audioUrl,
    this.videoTimestamp,
    this.audioOffsetSeconds = 0,
    this.quoteText,
    this.displaySettings,
  });
}
