import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _adConfigs => _firestore.collection('adConfigs');

  final Map<AdPlacement, BannerAd?> _bannerAds = {};
  final Map<AdPlacement, AdConfig> _configs = {};
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool _isInitialized = false;

  // Test Ad Unit IDs (replace with real ones in production)
  static const _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const _testBannerIos = 'ca-app-pub-3940256099942544/2934735716';
  static const _testInterstitialAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const _testInterstitialIos = 'ca-app-pub-3940256099942544/4411468910';
  static const _testRewardedAndroid = 'ca-app-pub-3940256099942544/5224354917';
  static const _testRewardedIos = 'ca-app-pub-3940256099942544/1712485313';

  Future<void> initialize() async {
    if (_isInitialized) return;

    if (!kIsWeb) {
      await MobileAds.instance.initialize();
    }

    // Load ad configs from Firebase
    await _loadAdConfigs();
    _isInitialized = true;
  }

  Future<void> _loadAdConfigs() async {
    try {
      final snapshot = await _adConfigs.where('isEnabled', isEqualTo: true).get();
      for (var doc in snapshot.docs) {
        final config = AdConfig.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id});
        _configs[config.placement] = config;
      }
    } catch (e) {
      debugPrint('Error loading ad configs: $e');
    }
  }

  // ============ ADMIN FUNCTIONS ============

  Stream<List<AdConfig>> getAdConfigs() {
    return _adConfigs.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return AdConfig.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id});
      }).toList();
    });
  }

  Future<String?> createAdConfig(AdConfig config) async {
    try {
      final doc = await _adConfigs.add(config.toJson());
      return doc.id;
    } catch (e) {
      debugPrint('Error creating ad config: $e');
      return null;
    }
  }

  Future<void> updateAdConfig(AdConfig config) async {
    await _adConfigs.doc(config.id).update(config.toJson());
  }

  Future<void> deleteAdConfig(String id) async {
    await _adConfigs.doc(id).delete();
  }

  // ============ AD LOADING ============

  String _getBannerAdUnitId(AdConfig? config) {
    if (kIsWeb) return ''; // Web uses AdSense, not AdMob

    if (config != null) {
      if (Platform.isAndroid && config.adUnitIdAndroid != null) {
        return config.adUnitIdAndroid!;
      }
      if (Platform.isIOS && config.adUnitIdIos != null) {
        return config.adUnitIdIos!;
      }
    }

    // Return test IDs
    return Platform.isAndroid ? _testBannerAndroid : _testBannerIos;
  }

  Future<BannerAd?> loadBannerAd(AdPlacement placement) async {
    if (kIsWeb) return null;

    final config = _configs[placement];
    if (config != null && !config.isEnabled) return null;

    final adUnitId = _getBannerAdUnitId(config);

    final bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('Banner ad loaded for $placement');
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: $error');
          ad.dispose();
        },
      ),
    );

    await bannerAd.load();
    _bannerAds[placement] = bannerAd;
    return bannerAd;
  }

  BannerAd? getBannerAd(AdPlacement placement) => _bannerAds[placement];

  Future<void> loadInterstitialAd() async {
    if (kIsWeb) return;

    final config = _configs.values.firstWhere(
      (c) => c.type == AdType.interstitial && c.isEnabled,
      orElse: () => AdConfig(
        id: '',
        name: 'Default Interstitial',
        type: AdType.interstitial,
        placement: AdPlacement.betweenContent,
      ),
    );

    final adUnitId = Platform.isAndroid
        ? (config.adUnitIdAndroid ?? _testInterstitialAndroid)
        : (config.adUnitIdIos ?? _testInterstitialIos);

    await InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          debugPrint('Interstitial ad loaded');
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad failed to load: $error');
        },
      ),
    );
  }

  Future<void> showInterstitialAd() async {
    if (_interstitialAd != null) {
      await _interstitialAd!.show();
      _interstitialAd = null;
      // Preload next one
      loadInterstitialAd();
    }
  }

  Future<void> loadRewardedAd() async {
    if (kIsWeb) return;

    final adUnitId = Platform.isAndroid ? _testRewardedAndroid : _testRewardedIos;

    await RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          debugPrint('Rewarded ad loaded');
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
        },
      ),
    );
  }

  Future<bool> showRewardedAd({required Function(RewardItem) onRewarded}) async {
    if (_rewardedAd == null) return false;

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        onRewarded(reward);
      },
    );
    _rewardedAd = null;
    loadRewardedAd();
    return true;
  }

  // ============ CONFIG HELPERS ============

  bool isAdEnabled(AdPlacement placement) {
    return _configs[placement]?.isEnabled ?? true;
  }

  int? getShowEveryNItems(AdPlacement placement) {
    return _configs[placement]?.showEveryNItems;
  }

  void dispose() {
    for (var ad in _bannerAds.values) {
      ad?.dispose();
    }
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}
