import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../providers/app_state.dart';
import '../models/models.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _videoController;
  YoutubePlayerController? _youtubeController;
  bool _showControls = true;
  double _volume = 0.8;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  void _initVideo() {
    final state = context.read<AppState>();
    final webcam = state.currentWebcam;

    if (webcam == null) return;

    if (webcam.isYoutube) {
      final videoId = YoutubePlayer.convertUrlToId(webcam.url);
      if (videoId != null) {
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: true,
            mute: true, // Video muted, audio from radio
            loop: true,
          ),
        );
      }
    } else {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(webcam.url))
        ..initialize().then((_) {
          setState(() {});
          _videoController!.setVolume(0); // Video muted
          _videoController!.play();
          _videoController!.setLooping(true);
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video Layer
            _buildVideoLayer(),

            // Quote Overlay
            _buildQuoteOverlay(),

            // Controls Overlay
            if (_showControls) _buildControlsOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoLayer() {
    final state = context.watch<AppState>();
    final webcam = state.currentWebcam;

    if (webcam == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off, size: 64, color: Colors.white54),
            SizedBox(height: 16),
            Text(
              'Selecciona una webcam',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    if (webcam.isYoutube && _youtubeController != null) {
      return Center(
        child: YoutubePlayer(
          controller: _youtubeController!,
          showVideoProgressIndicator: false,
        ),
      );
    }

    if (_videoController != null && _videoController!.value.isInitialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
      );
    }

    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildQuoteOverlay() {
    final state = context.watch<AppState>();

    if (!state.showQuotes || state.currentQuote == null) {
      return const SizedBox.shrink();
    }

    final quote = state.currentQuote!;

    return Positioned(
      bottom: 120,
      left: 32,
      right: 32,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          quote.displayText,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: state.fontFamily,
            fontSize: state.fontSize,
            color: Color(state.fontColor),
            shadows: const [
              Shadow(
                offset: Offset(1, 1),
                blurRadius: 4,
                color: Colors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    final state = context.watch<AppState>();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
          stops: const [0, 0.2, 0.8, 1],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.currentWebcam?.name ?? 'Sin webcam',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (state.currentStation != null)
                          Text(
                            state.currentStation!.name,
                            style: const TextStyle(color: Colors.white70),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      state.isFavorito(
                              state.currentWebcam?.id ?? '', FavoritoType.webcam)
                          ? Icons.favorite
                          : Icons.favorite_outline,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      if (state.currentWebcam != null) {
                        state.toggleFavorito(
                            state.currentWebcam!, FavoritoType.webcam);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () => _showSettingsSheet(context),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Bottom controls
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Audio controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          state.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 48,
                        ),
                        onPressed: () {
                          if (state.isPlaying) {
                            state.pauseAudio();
                          } else {
                            state.playAudio();
                          }
                        },
                      ),
                    ],
                  ),

                  // Volume slider
                  Row(
                    children: [
                      const Icon(Icons.volume_down, color: Colors.white),
                      Expanded(
                        child: Slider(
                          value: _volume,
                          onChanged: (value) {
                            setState(() => _volume = value);
                            state.setVolume(value);
                          },
                        ),
                      ),
                      const Icon(Icons.volume_up, color: Colors.white),
                    ],
                  ),

                  // Create momento button
                  ElevatedButton.icon(
                    onPressed: () => _showCreateMomentoDialog(context),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Crear Momento'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    final state = context.read<AppState>();

    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuracion',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Mostrar frases'),
              value: state.showQuotes,
              onChanged: (value) {
                state.updateDisplaySettings(showQuotes: value);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Cambiar frase'),
              trailing: const Icon(Icons.refresh),
              onTap: () {
                state.loadRandomQuote();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Tamano de fuente'),
              subtitle: Slider(
                value: state.fontSize,
                min: 14,
                max: 36,
                divisions: 11,
                label: state.fontSize.round().toString(),
                onChanged: (value) {
                  state.updateDisplaySettings(fontSize: value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateMomentoDialog(BuildContext context) {
    final state = context.read<AppState>();
    final titleController = TextEditingController();
    int secondsAgo = 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Momento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Titulo del momento',
                hintText: 'Ej: Jazz en Tokyo de noche',
              ),
            ),
            const SizedBox(height: 16),
            const Text('Cuando empezo el momento?'),
            StatefulBuilder(
              builder: (context, setSliderState) => Column(
                children: [
                  Slider(
                    value: secondsAgo.toDouble(),
                    min: 0,
                    max: 180,
                    divisions: 36,
                    label: secondsAgo == 0 ? 'Ahora' : 'Hace $secondsAgo seg',
                    onChanged: (value) {
                      setSliderState(() => secondsAgo = value.round());
                    },
                  ),
                  Text(
                    secondsAgo == 0 ? 'Ahora mismo' : 'Hace $secondsAgo segundos',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (titleController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ingresa un titulo')),
                );
                return;
              }

              final momento = await state.createMomento(
                title: titleController.text,
                secondsAgo: secondsAgo,
              );

              Navigator.pop(context);

              if (momento != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Momento creado!'),
                    action: SnackBarAction(
                      label: 'Compartir',
                      onPressed: () {
                        // TODO: Share momento
                      },
                    ),
                  ),
                );
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }
}
