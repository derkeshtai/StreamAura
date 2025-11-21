import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/admin_service.dart';
import '../../services/rss_service.dart';

class RssFeedsScreen extends StatelessWidget {
  const RssFeedsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminService = AdminService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feeds RSS'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFeedDialog(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<RssFeed>>(
        stream: adminService.getRssFeeds(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final feeds = snapshot.data ?? [];

          if (feeds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.rss_feed, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No hay feeds configurados'),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showFeedDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar Feed'),
                  ),
                ],
              ),
            );
          }

          // Group by type
          final grouped = <RssFeedType, List<RssFeed>>{};
          for (var feed in feeds) {
            grouped.putIfAbsent(feed.type, () => []).add(feed);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (var type in RssFeedType.values)
                if (grouped.containsKey(type)) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _getTypeTitle(type),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...grouped[type]!.map((feed) => _FeedCard(feed: feed)),
                  const SizedBox(height: 16),
                ],
            ],
          );
        },
      ),
    );
  }

  String _getTypeTitle(RssFeedType type) {
    switch (type) {
      case RssFeedType.webcams:
        return 'Webcams';
      case RssFeedType.radioStations:
        return 'Estaciones de Radio';
      case RssFeedType.quotes:
        return 'Frases';
      case RssFeedType.images:
        return 'Imagenes';
    }
  }

  void _showFeedDialog(BuildContext context, [RssFeed? existingFeed]) {
    showDialog(
      context: context,
      builder: (context) => _FeedFormDialog(feed: existingFeed),
    );
  }
}

class _FeedCard extends StatelessWidget {
  final RssFeed feed;

  const _FeedCard({required this.feed});

  @override
  Widget build(BuildContext context) {
    final adminService = AdminService();
    final rssService = RssService();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Text(feed.typeIcon, style: const TextStyle(fontSize: 24)),
        title: Text(feed.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (feed.description.isNotEmpty)
              Text(
                feed.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            Row(
              children: [
                Icon(
                  feed.isEnabled ? Icons.check_circle : Icons.cancel,
                  size: 14,
                  color: feed.isEnabled ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  feed.isEnabled ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                    fontSize: 12,
                    color: feed.isEnabled ? Colors.green : Colors.red,
                  ),
                ),
                if (feed.itemCount > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${feed.itemCount} items',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // URL
                Row(
                  children: [
                    const Icon(Icons.link, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feed.url,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Refresh interval
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 16),
                    const SizedBox(width: 8),
                    Text('Actualizar cada ${feed.refreshIntervalMinutes} min'),
                  ],
                ),
                const SizedBox(height: 8),

                // Last fetched
                if (feed.lastFetched != null)
                  Row(
                    children: [
                      const Icon(Icons.update, size: 16),
                      const SizedBox(width: 8),
                      Text('Ultima actualizacion: ${_formatDate(feed.lastFetched!)}'),
                    ],
                  ),

                const SizedBox(height: 16),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        // Test fetch
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Probando feed...')),
                        );
                        try {
                          final result = await rssService.fetchFeed(feed.url);
                          final itemCount = result?.items?.length ?? 0;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Feed OK: $itemCount items encontrados')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Probar'),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => _FeedFormDialog(feed: feed),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar'),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        adminService.toggleRssFeed(feed.id, !feed.isEnabled);
                      },
                      icon: Icon(feed.isEnabled ? Icons.pause : Icons.play_arrow),
                      label: Text(feed.isEnabled ? 'Desactivar' : 'Activar'),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Eliminar feed'),
                            content: Text('Eliminar "${feed.name}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Eliminar'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          adminService.deleteRssFeed(feed.id);
                        }
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _FeedFormDialog extends StatefulWidget {
  final RssFeed? feed;

  const _FeedFormDialog({this.feed});

  @override
  State<_FeedFormDialog> createState() => _FeedFormDialogState();
}

class _FeedFormDialogState extends State<_FeedFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _urlController = TextEditingController();
  final _intervalController = TextEditingController(text: '60');

  RssFeedType _selectedType = RssFeedType.webcams;
  bool _isEnabled = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.feed != null) {
      _nameController.text = widget.feed!.name;
      _descController.text = widget.feed!.description;
      _urlController.text = widget.feed!.url;
      _intervalController.text = widget.feed!.refreshIntervalMinutes.toString();
      _selectedType = widget.feed!.type;
      _isEnabled = widget.feed!.isEnabled;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _urlController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.feed != null;

    return AlertDialog(
      title: Text(isEditing ? 'Editar Feed' : 'Nuevo Feed RSS'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Ej: Webcams de naturaleza',
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Descripcion',
                    hintText: 'Descripcion opcional',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'URL del Feed',
                    hintText: 'https://example.com/feed.xml',
                  ),
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Requerido';
                    if (!Uri.tryParse(v!)!.hasAbsolutePath) {
                      return 'URL invalida';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<RssFeedType>(
                  value: _selectedType,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: RssFeedType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getTypeLabel(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedType = value);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _intervalController,
                  decoration: const InputDecoration(
                    labelText: 'Intervalo de actualizacion (minutos)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Activo'),
                  value: _isEnabled,
                  onChanged: (v) => setState(() => _isEnabled = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }

  String _getTypeLabel(RssFeedType type) {
    switch (type) {
      case RssFeedType.webcams:
        return 'Webcams';
      case RssFeedType.radioStations:
        return 'Estaciones de Radio';
      case RssFeedType.quotes:
        return 'Frases';
      case RssFeedType.images:
        return 'Imagenes';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final adminService = AdminService();

    final feed = RssFeed(
      id: widget.feed?.id ?? '',
      name: _nameController.text,
      description: _descController.text,
      url: _urlController.text,
      type: _selectedType,
      isEnabled: _isEnabled,
      refreshIntervalMinutes: int.tryParse(_intervalController.text) ?? 60,
      createdAt: widget.feed?.createdAt ?? DateTime.now(),
    );

    if (widget.feed != null) {
      await adminService.updateRssFeed(feed);
    } else {
      await adminService.createRssFeed(feed);
    }

    if (mounted) Navigator.pop(context);
  }
}
