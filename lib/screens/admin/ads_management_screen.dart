import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/ad_service.dart';

class AdsManagementScreen extends StatelessWidget {
  const AdsManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adService = AdService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion de Anuncios'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAdDialog(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<AdConfig>>(
        stream: adService.getAdConfigs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final ads = snapshot.data ?? [];

          if (ads.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.ad_units, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No hay anuncios configurados'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAdDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar Anuncio'),
                  ),
                  const SizedBox(height: 32),
                  _buildInstructions(),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildInstructions(),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Anuncios Configurados',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...ads.map((ad) => _AdCard(ad: ad)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInstructions() {
    return Card(
      color: Colors.blue.withOpacity(0.1),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Configuracion de AdMob',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              '1. Crea una cuenta en Google AdMob\n'
              '2. Registra tu app (Android/iOS)\n'
              '3. Crea Ad Units (Banner, Interstitial, Rewarded)\n'
              '4. Copia los Ad Unit IDs aqui\n\n'
              'Para Web, usa Google AdSense directamente en el HTML.',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdDialog(BuildContext context, [AdConfig? existingAd]) {
    showDialog(
      context: context,
      builder: (context) => _AdFormDialog(ad: existingAd),
    );
  }
}

class _AdCard extends StatelessWidget {
  final AdConfig ad;

  const _AdCard({required this.ad});

  @override
  Widget build(BuildContext context) {
    final adService = AdService();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: ad.isEnabled ? Colors.green : Colors.grey,
          child: Icon(_getTypeIcon(ad.type), color: Colors.white),
        ),
        title: Text(ad.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${ad.typeLabel} - ${ad.placementLabel}'),
            if (!ad.isEnabled)
              const Text(
                'Desactivado',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Text('Editar'),
              onTap: () {
                Future.delayed(const Duration(milliseconds: 100), () {
                  showDialog(
                    context: context,
                    builder: (_) => _AdFormDialog(ad: ad),
                  );
                });
              },
            ),
            PopupMenuItem(
              child: Text(ad.isEnabled ? 'Desactivar' : 'Activar'),
              onTap: () {
                adService.updateAdConfig(ad.copyWith(isEnabled: !ad.isEnabled));
              },
            ),
            PopupMenuItem(
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              onTap: () {
                adService.deleteAdConfig(ad.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(AdType type) {
    switch (type) {
      case AdType.banner:
        return Icons.view_agenda;
      case AdType.interstitial:
        return Icons.fullscreen;
      case AdType.rewarded:
        return Icons.card_giftcard;
      case AdType.native:
        return Icons.article;
    }
  }
}

class _AdFormDialog extends StatefulWidget {
  final AdConfig? ad;

  const _AdFormDialog({this.ad});

  @override
  State<_AdFormDialog> createState() => _AdFormDialogState();
}

class _AdFormDialogState extends State<_AdFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _androidIdController = TextEditingController();
  final _iosIdController = TextEditingController();
  final _webIdController = TextEditingController();
  final _showEveryNController = TextEditingController(text: '5');

  AdType _selectedType = AdType.banner;
  AdPlacement _selectedPlacement = AdPlacement.homeBottom;
  bool _isEnabled = true;

  @override
  void initState() {
    super.initState();
    if (widget.ad != null) {
      _nameController.text = widget.ad!.name;
      _androidIdController.text = widget.ad!.adUnitIdAndroid ?? '';
      _iosIdController.text = widget.ad!.adUnitIdIos ?? '';
      _webIdController.text = widget.ad!.adUnitIdWeb ?? '';
      _showEveryNController.text = (widget.ad!.showEveryNItems ?? 5).toString();
      _selectedType = widget.ad!.type;
      _selectedPlacement = widget.ad!.placement;
      _isEnabled = widget.ad!.isEnabled;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.ad != null ? 'Editar Anuncio' : 'Nuevo Anuncio'),
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
                    hintText: 'Ej: Banner Home Principal',
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<AdType>(
                  value: _selectedType,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: AdType.values.map((type) {
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
                DropdownButtonFormField<AdPlacement>(
                  value: _selectedPlacement,
                  decoration: const InputDecoration(labelText: 'Ubicacion'),
                  items: AdPlacement.values.map((placement) {
                    return DropdownMenuItem(
                      value: placement,
                      child: Text(_getPlacementLabel(placement)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedPlacement = value);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _androidIdController,
                  decoration: const InputDecoration(
                    labelText: 'Ad Unit ID (Android)',
                    hintText: 'ca-app-pub-xxx/xxx',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _iosIdController,
                  decoration: const InputDecoration(
                    labelText: 'Ad Unit ID (iOS)',
                    hintText: 'ca-app-pub-xxx/xxx',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _webIdController,
                  decoration: const InputDecoration(
                    labelText: 'Ad Unit ID (Web/AdSense)',
                    hintText: 'Opcional para web',
                  ),
                ),
                if (_selectedPlacement == AdPlacement.betweenContent) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _showEveryNController,
                    decoration: const InputDecoration(
                      labelText: 'Mostrar cada N items',
                      hintText: 'Ej: 5',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
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
          onPressed: _submit,
          child: Text(widget.ad != null ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }

  String _getTypeLabel(AdType type) {
    switch (type) {
      case AdType.banner:
        return 'Banner';
      case AdType.interstitial:
        return 'Intersticial';
      case AdType.rewarded:
        return 'Recompensado';
      case AdType.native:
        return 'Nativo';
    }
  }

  String _getPlacementLabel(AdPlacement placement) {
    switch (placement) {
      case AdPlacement.homeTop:
        return 'Inicio - Arriba';
      case AdPlacement.homeBottom:
        return 'Inicio - Abajo';
      case AdPlacement.playerBottom:
        return 'Reproductor - Abajo';
      case AdPlacement.momentosList:
        return 'Lista de Momentos';
      case AdPlacement.favoritosList:
        return 'Lista de Favoritos';
      case AdPlacement.betweenContent:
        return 'Entre contenido';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final adService = AdService();

    final adConfig = AdConfig(
      id: widget.ad?.id ?? '',
      name: _nameController.text,
      type: _selectedType,
      placement: _selectedPlacement,
      isEnabled: _isEnabled,
      adUnitIdAndroid: _androidIdController.text.isNotEmpty ? _androidIdController.text : null,
      adUnitIdIos: _iosIdController.text.isNotEmpty ? _iosIdController.text : null,
      adUnitIdWeb: _webIdController.text.isNotEmpty ? _webIdController.text : null,
      showEveryNItems: int.tryParse(_showEveryNController.text),
      createdAt: widget.ad?.createdAt ?? DateTime.now(),
    );

    if (widget.ad != null) {
      await adService.updateAdConfig(adConfig);
    } else {
      await adService.createAdConfig(adConfig);
    }

    if (mounted) Navigator.pop(context);
  }
}
