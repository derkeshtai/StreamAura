import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import 'rss_feeds_screen.dart';
import 'ads_management_screen.dart';
import 'content_management_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AdminService _adminService = AdminService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _adminService.getStats();
    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administracion'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Stats cards
                  _buildStatsSection(),
                  const SizedBox(height: 24),

                  // Quick actions
                  const Text(
                    'Administracion',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildAdminMenu(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estadisticas',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _StatCard(
              title: 'Webcams',
              value: '${_stats?['webcams'] ?? 0}',
              icon: Icons.videocam,
              color: Colors.blue,
            ),
            _StatCard(
              title: 'Estaciones',
              value: '${_stats?['stations'] ?? 0}',
              icon: Icons.radio,
              color: Colors.green,
            ),
            _StatCard(
              title: 'Momentos',
              value: '${_stats?['momentos'] ?? 0}',
              icon: Icons.auto_awesome,
              color: Colors.purple,
            ),
            _StatCard(
              title: 'Feeds RSS',
              value: '${_stats?['rssFeeds'] ?? 0}',
              icon: Icons.rss_feed,
              color: Colors.orange,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdminMenu() {
    return Column(
      children: [
        _AdminMenuItem(
          title: 'Feeds RSS',
          subtitle: 'Administra los feeds de contenido',
          icon: Icons.rss_feed,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RssFeedsScreen()),
          ),
        ),
        _AdminMenuItem(
          title: 'Anuncios',
          subtitle: 'Configura AdMob y espacios publicitarios',
          icon: Icons.ad_units,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdsManagementScreen()),
          ),
        ),
        _AdminMenuItem(
          title: 'Contenido',
          subtitle: 'Administra webcams, estaciones y frases',
          icon: Icons.folder,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ContentManagementScreen()),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _AdminMenuItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _AdminMenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
