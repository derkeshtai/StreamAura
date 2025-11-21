import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/models.dart';
import '../services/ad_service.dart';

/// Widget para mostrar banner ads
class AdBannerWidget extends StatefulWidget {
  final AdPlacement placement;

  const AdBannerWidget({
    super.key,
    required this.placement,
  });

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    if (kIsWeb) {
      // For web, we'll show a placeholder for AdSense
      setState(() => _isLoaded = true);
      return;
    }

    final adService = AdService();
    final ad = await adService.loadBannerAd(widget.placement);
    if (mounted && ad != null) {
      setState(() {
        _bannerAd = ad;
        _isLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return const SizedBox(height: 50); // Reserve space
    }

    // Web: Show AdSense placeholder (you'll add the actual AdSense code in HTML)
    if (kIsWeb) {
      return Container(
        height: 90,
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'Ad Space',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Mobile: Show AdMob banner
    if (_bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: AdWidget(ad: _bannerAd!),
      );
    }

    return const SizedBox.shrink();
  }
}

/// Widget para insertar ads entre items de una lista
class AdListItem extends StatelessWidget {
  final int index;
  final int showEveryN;
  final AdPlacement placement;

  const AdListItem({
    super.key,
    required this.index,
    this.showEveryN = 5,
    this.placement = AdPlacement.betweenContent,
  });

  @override
  Widget build(BuildContext context) {
    // Show ad every N items (after item 4, 9, 14, etc.)
    if ((index + 1) % showEveryN == 0) {
      return AdBannerWidget(placement: placement);
    }
    return const SizedBox.shrink();
  }
}

/// Mixin para listas con ads intercalados
mixin AdListMixin {
  /// Calcula el indice real del item considerando los ads
  int getRealIndex(int index, int showEveryN) {
    final adsBeforeThis = index ~/ (showEveryN + 1);
    return index - adsBeforeThis;
  }

  /// Verifica si el indice corresponde a un ad
  bool isAdIndex(int index, int showEveryN) {
    return (index + 1) % (showEveryN + 1) == 0;
  }

  /// Calcula el total de items incluyendo ads
  int getTotalCount(int itemCount, int showEveryN) {
    final adCount = itemCount ~/ showEveryN;
    return itemCount + adCount;
  }
}
