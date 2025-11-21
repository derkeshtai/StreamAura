import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

class AppState extends ChangeNotifier {
  final FirebaseService firebaseService = FirebaseService();
  final StreamAudioService audioService = StreamAudioService();
  final RssService rssService = RssService();
  late final MomentoService momentoService;

  // Current playback state
  Webcam? _currentWebcam;
  RadioStation? _currentStation;
  Quote? _currentQuote;
  bool _isBuffering = false;

  // Display settings for quotes
  String _fontFamily = 'Roboto';
  double _fontSize = 24;
  int _fontColor = 0xFFFFFFFF;
  bool _showQuotes = true;

  // Lists
  List<Webcam> _webcams = [];
  List<RadioStation> _stations = [];
  List<Momento> _momentos = [];
  List<Favorito> _favoritos = [];

  AppState() {
    momentoService = MomentoService(firebaseService);
    _init();
  }

  // Getters
  Webcam? get currentWebcam => _currentWebcam;
  RadioStation? get currentStation => _currentStation;
  Quote? get currentQuote => _currentQuote;
  bool get isBuffering => _isBuffering;

  String get fontFamily => _fontFamily;
  double get fontSize => _fontSize;
  int get fontColor => _fontColor;
  bool get showQuotes => _showQuotes;

  List<Webcam> get webcams => _webcams;
  List<RadioStation> get stations => _stations;
  List<Momento> get momentos => _momentos;
  List<Favorito> get favoritos => _favoritos;

  bool get isPlaying => audioService.isPlaying;

  Future<void> _init() async {
    // Sign in anonymously for basic access
    await firebaseService.signInAnonymously();

    // Listen to data streams
    firebaseService.getWebcams().listen((data) {
      _webcams = data;
      notifyListeners();
    });

    firebaseService.getStations().listen((data) {
      _stations = data;
      notifyListeners();
    });

    firebaseService.getMomentos().listen((data) {
      _momentos = data;
      notifyListeners();
    });

    // Load favoritos if logged in
    final user = firebaseService.currentUser;
    if (user != null) {
      firebaseService.getUserFavoritos(user.uid).listen((data) {
        _favoritos = data;
        notifyListeners();
      });
    }
  }

  // ============ PLAYBACK CONTROL ============

  Future<void> selectWebcam(Webcam webcam) async {
    _currentWebcam = webcam;
    _updateBuffering();
    notifyListeners();
  }

  Future<void> selectStation(RadioStation station) async {
    _currentStation = station;
    await audioService.playStation(station);
    _updateBuffering();
    notifyListeners();
  }

  Future<void> playAudio() async {
    await audioService.play();
    notifyListeners();
  }

  Future<void> pauseAudio() async {
    await audioService.pause();
    notifyListeners();
  }

  Future<void> setVolume(double volume) async {
    await audioService.setVolume(volume);
  }

  // ============ QUOTES ============

  Future<void> loadRandomQuote({QuoteCategory? category}) async {
    _currentQuote = await firebaseService.getRandomQuote(category: category);
    notifyListeners();
  }

  void setQuote(Quote? quote) {
    _currentQuote = quote;
    notifyListeners();
  }

  void updateDisplaySettings({
    String? fontFamily,
    double? fontSize,
    int? fontColor,
    bool? showQuotes,
  }) {
    if (fontFamily != null) _fontFamily = fontFamily;
    if (fontSize != null) _fontSize = fontSize;
    if (fontColor != null) _fontColor = fontColor;
    if (showQuotes != null) _showQuotes = showQuotes;
    notifyListeners();
  }

  // ============ BUFFERING ============

  void _updateBuffering() {
    if (_currentWebcam != null && _currentStation != null) {
      if (!_isBuffering) {
        _isBuffering = true;
        momentoService.startBuffering(
          webcamUrl: _currentWebcam!.url,
          audioUrl: _currentStation!.streamUrl,
        );
      } else {
        momentoService.updateWebcam(_currentWebcam!.url);
        momentoService.updateAudio(_currentStation!.streamUrl);
      }
    }
  }

  // ============ MOMENTOS ============

  Future<Momento?> createMomento({
    required String title,
    String? description,
    int secondsAgo = 0,
    List<String> tags = const [],
  }) async {
    if (_currentWebcam == null || _currentStation == null) return null;

    return momentoService.createMomento(
      title: title,
      description: description,
      webcamId: _currentWebcam!.id,
      webcamName: _currentWebcam!.name,
      audioId: _currentStation!.id,
      audioName: _currentStation!.name,
      secondsAgo: secondsAgo,
      quoteText: _showQuotes ? _currentQuote?.text : null,
      quoteSource: _currentQuote?.author,
      displaySettings: {
        'fontFamily': _fontFamily,
        'fontSize': _fontSize,
        'fontColor': _fontColor,
      },
      tags: tags,
    );
  }

  Future<void> playMomento(Momento momento) async {
    final playback = momentoService.prepareMomentoPlayback(momento);

    // Load webcam
    _currentWebcam = Webcam(
      id: momento.webcamId,
      name: momento.webcamName ?? 'Momento',
      url: playback.webcamUrl,
    );

    // Load audio
    _currentStation = RadioStation(
      id: momento.audioId,
      name: momento.audioName ?? 'Audio',
      streamUrl: playback.audioUrl,
    );

    // Load quote
    if (playback.quoteText != null) {
      _currentQuote = Quote(
        id: 'momento',
        text: playback.quoteText!,
        author: momento.quoteSource,
      );
    }

    // Apply display settings
    if (playback.displaySettings != null) {
      _fontFamily = playback.displaySettings!['fontFamily'] ?? _fontFamily;
      _fontSize = (playback.displaySettings!['fontSize'] ?? _fontSize).toDouble();
      _fontColor = playback.displaySettings!['fontColor'] ?? _fontColor;
    }

    await audioService.playStation(_currentStation!);
    notifyListeners();
  }

  // ============ FAVORITOS ============

  Future<void> toggleFavorito(dynamic item, FavoritoType type) async {
    final user = firebaseService.currentUser;
    if (user == null) return;

    String itemId;
    String? itemName;
    String? itemUrl;

    if (item is Webcam) {
      itemId = item.id;
      itemName = item.name;
      itemUrl = item.url;
    } else if (item is RadioStation) {
      itemId = item.id;
      itemName = item.name;
      itemUrl = item.streamUrl;
    } else if (item is Momento) {
      itemId = item.id;
      itemName = item.title;
    } else {
      return;
    }

    final isFav = await firebaseService.isFavorito(user.uid, itemId, type);

    if (isFav) {
      // Remove from favoritos
      final fav = _favoritos.firstWhere(
        (f) => f.itemId == itemId && f.type == type,
        orElse: () => Favorito(
          id: '',
          itemId: itemId,
          type: type,
          userId: user.uid,
          createdAt: DateTime.now(),
        ),
      );
      if (fav.id.isNotEmpty) {
        await firebaseService.removeFavorito(fav.id);
      }
    } else {
      // Add to favoritos
      await firebaseService.addFavorito(Favorito(
        id: '',
        itemId: itemId,
        type: type,
        userId: user.uid,
        itemName: itemName,
        itemUrl: itemUrl,
        createdAt: DateTime.now(),
      ));
    }
  }

  bool isFavorito(String itemId, FavoritoType type) {
    return _favoritos.any((f) => f.itemId == itemId && f.type == type);
  }

  @override
  void dispose() {
    audioService.dispose();
    momentoService.dispose();
    super.dispose();
  }
}
