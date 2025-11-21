import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import 'player_screen.dart';

class MomentosScreen extends StatelessWidget {
  const MomentosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Momentos'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Recientes'),
              Tab(text: 'Populares'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _MomentosList(popular: false),
            _MomentosList(popular: true),
          ],
        ),
      ),
    );
  }
}

class _MomentosList extends StatelessWidget {
  final bool popular;

  const _MomentosList({required this.popular});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final momentos = state.momentos;

        if (momentos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No hay momentos aun'),
                const SizedBox(height: 8),
                Text(
                  'Crea el primero combinando\nuna webcam con audio',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        // Sort based on tab
        final sortedMomentos = List<Momento>.from(momentos);
        if (popular) {
          sortedMomentos.sort((a, b) => b.likes.compareTo(a.likes));
        } else {
          sortedMomentos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedMomentos.length,
          itemBuilder: (context, index) {
            return _MomentoCard(momento: sortedMomentos[index]);
          },
        );
      },
    );
  }
}

class _MomentoCard extends StatelessWidget {
  final Momento momento;

  const _MomentoCard({required this.momento});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          state.playMomento(momento);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PlayerScreen()),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview area
            Container(
              height: 180,
              width: double.infinity,
              color: Colors.grey[900],
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const Center(
                    child: Icon(Icons.play_circle_outline,
                        size: 64, color: Colors.white54),
                  ),
                  if (momento.quoteText != null)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Text(
                        '"${momento.quoteText}"',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    momento.title ?? 'Sin titulo',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.videocam, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        momento.webcamName ?? 'Webcam',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.radio, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        momento.audioName ?? 'Audio',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Por ${momento.creatorName ?? 'Anonimo'}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const Spacer(),
                      Icon(Icons.favorite, size: 16, color: Colors.red[300]),
                      const SizedBox(width: 4),
                      Text('${momento.likes}'),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.share, size: 20),
                        onPressed: () {
                          // TODO: Share momento
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Enlace: ${momento.shareUrl}'),
                            ),
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
