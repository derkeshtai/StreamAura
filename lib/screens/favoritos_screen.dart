import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/models.dart';

class FavoritosScreen extends StatelessWidget {
  const FavoritosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoritos'),
      ),
      body: Consumer<AppState>(
        builder: (context, state, _) {
          if (state.favoritos.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No tienes favoritos'),
                  SizedBox(height: 8),
                  Text(
                    'Agrega webcams, estaciones o\nmomentos a tus favoritos',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Group by type
          final grouped = <FavoritoType, List<Favorito>>{};
          for (var fav in state.favoritos) {
            grouped.putIfAbsent(fav.type, () => []).add(fav);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (var type in FavoritoType.values)
                if (grouped.containsKey(type)) ...[
                  _SectionHeader(type: type, count: grouped[type]!.length),
                  ...grouped[type]!.map((fav) => _FavoritoTile(favorito: fav)),
                  const SizedBox(height: 16),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final FavoritoType type;
  final int count;

  const _SectionHeader({required this.type, required this.count});

  @override
  Widget build(BuildContext context) {
    String title;
    IconData icon;

    switch (type) {
      case FavoritoType.webcam:
        title = 'Webcams';
        icon = Icons.videocam;
        break;
      case FavoritoType.radioStation:
        title = 'Estaciones';
        icon = Icons.radio;
        break;
      case FavoritoType.quote:
        title = 'Frases';
        icon = Icons.format_quote;
        break;
      case FavoritoType.momento:
        title = 'Momentos';
        icon = Icons.auto_awesome;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoritoTile extends StatelessWidget {
  final Favorito favorito;

  const _FavoritoTile({required this.favorito});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(favorito.typeIcon),
        ),
        title: Text(favorito.itemName ?? 'Sin nombre'),
        subtitle: Text(favorito.typeLabel),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () {
            final state = context.read<AppState>();
            state.firebaseService.removeFavorito(favorito.id);
          },
        ),
        onTap: () {
          // TODO: Navigate to item
        },
      ),
    );
  }
}
