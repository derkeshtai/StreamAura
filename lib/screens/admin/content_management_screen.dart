import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../services/admin_service.dart';
import '../../models/models.dart';

class ContentManagementScreen extends StatelessWidget {
  const ContentManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestion de Contenido'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.videocam), text: 'Webcams'),
              Tab(icon: Icon(Icons.radio), text: 'Estaciones'),
              Tab(icon: Icon(Icons.format_quote), text: 'Frases'),
              Tab(icon: Icon(Icons.auto_awesome), text: 'Momentos'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _WebcamsTab(),
            _StationsTab(),
            _QuotesTab(),
            _MomentosTab(),
          ],
        ),
      ),
    );
  }
}

class _WebcamsTab extends StatelessWidget {
  const _WebcamsTab();

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();
    final adminService = AdminService();

    return StreamBuilder<List<Webcam>>(
      stream: firebaseService.getWebcams(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];

        return _ContentList<Webcam>(
          items: items,
          emptyIcon: Icons.videocam_off,
          emptyText: 'No hay webcams',
          itemBuilder: (item) => ListTile(
            leading: item.thumbnailUrl != null
                ? Image.network(item.thumbnailUrl!, width: 60, fit: BoxFit.cover)
                : const CircleAvatar(child: Icon(Icons.videocam)),
            title: Text(item.name),
            subtitle: Text(item.url, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(
                context,
                'Eliminar webcam "${item.name}"?',
                () => adminService.deleteWebcam(item.id),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StationsTab extends StatelessWidget {
  const _StationsTab();

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();
    final adminService = AdminService();

    return StreamBuilder<List<RadioStation>>(
      stream: firebaseService.getStations(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];

        return _ContentList<RadioStation>(
          items: items,
          emptyIcon: Icons.radio,
          emptyText: 'No hay estaciones',
          itemBuilder: (item) => ListTile(
            leading: item.imageUrl != null
                ? Image.network(item.imageUrl!, width: 50, fit: BoxFit.cover)
                : const CircleAvatar(child: Icon(Icons.radio)),
            title: Text(item.name),
            subtitle: Text(item.typeLabel),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(
                context,
                'Eliminar estacion "${item.name}"?',
                () => adminService.deleteStation(item.id),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuotesTab extends StatelessWidget {
  const _QuotesTab();

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();
    final adminService = AdminService();

    return StreamBuilder<List<Quote>>(
      stream: firebaseService.getQuotes(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];

        return _ContentList<Quote>(
          items: items,
          emptyIcon: Icons.format_quote,
          emptyText: 'No hay frases',
          itemBuilder: (item) => ListTile(
            leading: const CircleAvatar(child: Icon(Icons.format_quote)),
            title: Text(
              item.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(item.author ?? 'Anonimo'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(
                context,
                'Eliminar esta frase?',
                () => adminService.deleteQuote(item.id),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MomentosTab extends StatelessWidget {
  const _MomentosTab();

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();
    final adminService = AdminService();

    return StreamBuilder<List<Momento>>(
      stream: firebaseService.getMomentos(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];

        return _ContentList<Momento>(
          items: items,
          emptyIcon: Icons.auto_awesome,
          emptyText: 'No hay momentos',
          itemBuilder: (item) => ListTile(
            leading: const CircleAvatar(child: Icon(Icons.auto_awesome)),
            title: Text(item.title ?? 'Sin titulo'),
            subtitle: Text(
              '${item.webcamName ?? "Webcam"} + ${item.audioName ?? "Audio"}\n'
              'Likes: ${item.likes} | Por: ${item.creatorName ?? "Anonimo"}',
            ),
            isThreeLine: true,
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(
                context,
                'Eliminar momento "${item.title}"?',
                () => adminService.deleteMomento(item.id),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ContentList<T> extends StatelessWidget {
  final List<T> items;
  final IconData emptyIcon;
  final String emptyText;
  final Widget Function(T item) itemBuilder;

  const _ContentList({
    required this.items,
    required this.emptyIcon,
    required this.emptyText,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(emptyText),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) => itemBuilder(items[index]),
    );
  }
}

Future<void> _confirmDelete(
  BuildContext context,
  String message,
  VoidCallback onConfirm,
) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirmar'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  if (confirm == true) {
    onConfirm();
  }
}
