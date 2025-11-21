import 'package:cloud_firestore/cloud_firestore.dart';

class Webcam {
  final String id;
  final String name;
  final String url;
  final String? thumbnailUrl;
  final String? description;
  final String? location;
  final String? country;
  final List<String> tags;
  final bool isYoutube;
  final bool supportsTimestamp; // For DVR/archive support
  final DateTime? createdAt;

  Webcam({
    required this.id,
    required this.name,
    required this.url,
    this.thumbnailUrl,
    this.description,
    this.location,
    this.country,
    this.tags = const [],
    this.isYoutube = false,
    this.supportsTimestamp = false,
    this.createdAt,
  });

  factory Webcam.fromJson(Map<String, dynamic> json) {
    return Webcam(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      url: json['url'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
      description: json['description'],
      location: json['location'],
      country: json['country'],
      tags: List<String>.from(json['tags'] ?? []),
      isYoutube: json['isYoutube'] ?? false,
      supportsTimestamp: json['supportsTimestamp'] ?? false,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'description': description,
      'location': location,
      'country': country,
      'tags': tags,
      'isYoutube': isYoutube,
      'supportsTimestamp': supportsTimestamp,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  Webcam copyWith({
    String? id,
    String? name,
    String? url,
    String? thumbnailUrl,
    String? description,
    String? location,
    String? country,
    List<String>? tags,
    bool? isYoutube,
    bool? supportsTimestamp,
    DateTime? createdAt,
  }) {
    return Webcam(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      description: description ?? this.description,
      location: location ?? this.location,
      country: country ?? this.country,
      tags: tags ?? this.tags,
      isYoutube: isYoutube ?? this.isYoutube,
      supportsTimestamp: supportsTimestamp ?? this.supportsTimestamp,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
