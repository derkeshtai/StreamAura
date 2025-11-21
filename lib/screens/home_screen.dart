import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../widgets/ad_banner_widget.dart';
import 'player_screen.dart';
import 'momentos_screen.dart';
import 'favoritos_screen.dart';
import 'admin/admin_login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _ExploreTab(),
    const MomentosScreen(),
    const FavoritosScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explorar',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Momentos',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favoritos',
          ),
        ],
      ),
    );
  }
}

class _ExploreTab extends StatelessWidget {
  const _ExploreTab();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('StreamAura'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.videocam), text: 'Webcams'),
              Tab(icon: Icon(Icons.radio), text: 'Audio'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.play_circle_filled),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PlayerScreen()),
                );
              },
              tooltip: 'Abrir reproductor',
            ),
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                );
              },
              tooltip: 'Admin',
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            _WebcamsTab(),
            _AudioTab(),
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
    return Consumer<AppState>(
      builder: (context, state, _) {
        if (state.webcams.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.videocam_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No hay webcams disponibles'),
                Text(
                  'Agrega webcams desde Firebase',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Ad banner at top
            const AdBannerWidget(placement: AdPlacement.homeTop),

            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 16 / 10,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: state.webcams.length,
                itemBuilder: (context, index) {
                  final webcam = state.webcams[index];
                  return _WebcamCard(webcam: webcam);
                },
              ),
            ),

            // Ad banner at bottom
            const AdBannerWidget(placement: AdPlacement.homeBottom),
          ],
        );
      },
    );
  }
}

class _WebcamCard extends StatelessWidget {
  final Webcam webcam;

  const _WebcamCard({required this.webcam});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final isSelected = state.currentWebcam?.id == webcam.id;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: () {
          state.selectWebcam(webcam);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PlayerScreen()),
          );
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (webcam.thumbnailUrl != null)
              Image.network(
                webcam.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[800],
                  child: const Icon(Icons.videocam, size: 48),
                ),
              )
            else
              Container(
                color: Colors.grey[800],
                child: const Icon(Icons.videocam, size: 48),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  webcam.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (webcam.isYoutube)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(Icons.play_circle_fill, color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}

class _AudioTab extends StatelessWidget {
  const _AudioTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        if (state.stations.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.radio, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No hay estaciones disponibles'),
                Text(
                  'Agrega estaciones desde Firebase',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            const AdBannerWidget(placement: AdPlacement.homeTop),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.stations.length,
                itemBuilder: (context, index) {
                  final station = state.stations[index];
                  // Show ad every 5 items
                  return Column(
                    children: [
                      _StationTile(station: station),
                      if ((index + 1) % 5 == 0)
                        const AdBannerWidget(placement: AdPlacement.betweenContent),
                    ],
                  );
                },
              ),
            ),
            const AdBannerWidget(placement: AdPlacement.homeBottom),
          ],
        );
      },
    );
  }
}

class _StationTile extends StatelessWidget {
  final RadioStation station;

  const _StationTile({required this.station});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isPlaying = state.currentStation?.id == station.id && state.isPlaying;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage:
              station.imageUrl != null ? NetworkImage(station.imageUrl!) : null,
          child: station.imageUrl == null ? const Icon(Icons.radio) : null,
        ),
        title: Text(station.name),
        subtitle: Text(station.typeLabel),
        trailing: IconButton(
          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: () {
            if (isPlaying) {
              state.pauseAudio();
            } else {
              state.selectStation(station);
            }
          },
        ),
        onTap: () {
          state.selectStation(station);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PlayerScreen()),
          );
        },
      ),
    );
  }
}
