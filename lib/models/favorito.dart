import 'package:cloud_firestore/cloud_firestore.dart';

enum FavoritoType {
  webcam,
  radioStation,
  quote,
  momento,
}

class Favorito {
  final String id;
  final String itemId;
  final FavoritoType type;
  final String userId;
  final String? itemName;
  final String? itemUrl;
  final Map<String, dynamic>? itemData; // Full item data for offline
  final DateTime createdAt;

  Favorito({
    required this.id,
    required this.itemId,
    required this.type,
    required this.userId,
    this.itemName,
    this.itemUrl,
    this.itemData,
    required this.createdAt,
  });

  factory Favorito.fromJson(Map<String, dynamic> json) {
    return Favorito(
      id: json['id'] ?? '',
      itemId: json['itemId'] ?? '',
      type: FavoritoType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => FavoritoType.webcam,
      ),
      userId: json['userId'] ?? '',
      itemName: json['itemName'],
      itemUrl: json['itemUrl'],
      itemData: json['itemData'],
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'type': type.name,
      'userId': userId,
      'itemName': itemName,
      'itemUrl': itemUrl,
      'itemData': itemData,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  String get typeLabel {
    switch (type) {
      case FavoritoType.webcam:
        return 'Webcam';
      case FavoritoType.radioStation:
        return 'Estación';
      case FavoritoType.quote:
        return 'Frase';
      case FavoritoType.momento:
        return 'Momento';
    }
  }

  String get typeIcon {
    switch (type) {
      case FavoritoType.webcam:
        return '📹';
      case FavoritoType.radioStation:
        return '🎵';
      case FavoritoType.quote:
        return '💬';
      case FavoritoType.momento:
        return '✨';
    }
  }
}
