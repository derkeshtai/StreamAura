import 'package:cloud_firestore/cloud_firestore.dart';

enum AudioType {
  radio,
  whiteNoise,
  nature,
  ambient,
  music,
}

class RadioStation {
  final String id;
  final String name;
  final String streamUrl;
  final String? imageUrl;
  final String? description;
  final String? genre;
  final String? country;
  final AudioType type;
  final List<String> tags;
  final DateTime? createdAt;

  RadioStation({
    required this.id,
    required this.name,
    required this.streamUrl,
    this.imageUrl,
    this.description,
    this.genre,
    this.country,
    this.type = AudioType.radio,
    this.tags = const [],
    this.createdAt,
  });

  factory RadioStation.fromJson(Map<String, dynamic> json) {
    return RadioStation(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      streamUrl: json['streamUrl'] ?? '',
      imageUrl: json['imageUrl'],
      description: json['description'],
      genre: json['genre'],
      country: json['country'],
      type: AudioType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AudioType.radio,
      ),
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'streamUrl': streamUrl,
      'imageUrl': imageUrl,
      'description': description,
      'genre': genre,
      'country': country,
      'type': type.name,
      'tags': tags,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  String get typeLabel {
    switch (type) {
      case AudioType.radio:
        return 'Radio';
      case AudioType.whiteNoise:
        return 'Ruido Blanco';
      case AudioType.nature:
        return 'Naturaleza';
      case AudioType.ambient:
        return 'Ambiente';
      case AudioType.music:
        return 'Música';
    }
  }
}
