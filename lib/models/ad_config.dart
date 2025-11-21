import 'package:cloud_firestore/cloud_firestore.dart';

enum AdType {
  banner,
  interstitial,
  rewarded,
  native,
}

enum AdPlacement {
  homeTop,
  homeBottom,
  playerBottom,
  momentosList,
  favoritosList,
  betweenContent, // Between list items
}

/// Configuracion de un anuncio administrable
class AdConfig {
  final String id;
  final String name;
  final AdType type;
  final AdPlacement placement;
  final bool isEnabled;
  final String? adUnitIdAndroid;
  final String? adUnitIdIos;
  final String? adUnitIdWeb;
  final int? showEveryNItems; // For betweenContent placement
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AdConfig({
    required this.id,
    required this.name,
    required this.type,
    required this.placement,
    this.isEnabled = true,
    this.adUnitIdAndroid,
    this.adUnitIdIos,
    this.adUnitIdWeb,
    this.showEveryNItems,
    this.createdAt,
    this.updatedAt,
  });

  factory AdConfig.fromJson(Map<String, dynamic> json) {
    return AdConfig(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: AdType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AdType.banner,
      ),
      placement: AdPlacement.values.firstWhere(
        (e) => e.name == json['placement'],
        orElse: () => AdPlacement.homeBottom,
      ),
      isEnabled: json['isEnabled'] ?? true,
      adUnitIdAndroid: json['adUnitIdAndroid'],
      adUnitIdIos: json['adUnitIdIos'],
      adUnitIdWeb: json['adUnitIdWeb'],
      showEveryNItems: json['showEveryNItems'],
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'placement': placement.name,
      'isEnabled': isEnabled,
      'adUnitIdAndroid': adUnitIdAndroid,
      'adUnitIdIos': adUnitIdIos,
      'adUnitIdWeb': adUnitIdWeb,
      'showEveryNItems': showEveryNItems,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  String get typeLabel {
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

  String get placementLabel {
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

  AdConfig copyWith({
    String? id,
    String? name,
    AdType? type,
    AdPlacement? placement,
    bool? isEnabled,
    String? adUnitIdAndroid,
    String? adUnitIdIos,
    String? adUnitIdWeb,
    int? showEveryNItems,
  }) {
    return AdConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      placement: placement ?? this.placement,
      isEnabled: isEnabled ?? this.isEnabled,
      adUnitIdAndroid: adUnitIdAndroid ?? this.adUnitIdAndroid,
      adUnitIdIos: adUnitIdIos ?? this.adUnitIdIos,
      adUnitIdWeb: adUnitIdWeb ?? this.adUnitIdWeb,
      showEveryNItems: showEveryNItems ?? this.showEveryNItems,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
