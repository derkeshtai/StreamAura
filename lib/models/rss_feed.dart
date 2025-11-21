import 'package:cloud_firestore/cloud_firestore.dart';

enum RssFeedType {
  webcams,
  radioStations,
  quotes,
  images,
}

/// Feed RSS administrable
class RssFeed {
  final String id;
  final String name;
  final String description;
  final String url;
  final RssFeedType type;
  final bool isEnabled;
  final bool isDefault; // Feeds predeterminados
  final int refreshIntervalMinutes;
  final DateTime? lastFetched;
  final int itemCount;
  final String? iconUrl;
  final Map<String, String>? fieldMapping; // Map RSS fields to model fields
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RssFeed({
    required this.id,
    required this.name,
    this.description = '',
    required this.url,
    required this.type,
    this.isEnabled = true,
    this.isDefault = false,
    this.refreshIntervalMinutes = 60,
    this.lastFetched,
    this.itemCount = 0,
    this.iconUrl,
    this.fieldMapping,
    this.createdAt,
    this.updatedAt,
  });

  factory RssFeed.fromJson(Map<String, dynamic> json) {
    return RssFeed(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      type: RssFeedType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => RssFeedType.webcams,
      ),
      isEnabled: json['isEnabled'] ?? true,
      isDefault: json['isDefault'] ?? false,
      refreshIntervalMinutes: json['refreshIntervalMinutes'] ?? 60,
      lastFetched: json['lastFetched'] != null
          ? (json['lastFetched'] as Timestamp).toDate()
          : null,
      itemCount: json['itemCount'] ?? 0,
      iconUrl: json['iconUrl'],
      fieldMapping: json['fieldMapping'] != null
          ? Map<String, String>.from(json['fieldMapping'])
          : null,
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
      'description': description,
      'url': url,
      'type': type.name,
      'isEnabled': isEnabled,
      'isDefault': isDefault,
      'refreshIntervalMinutes': refreshIntervalMinutes,
      'lastFetched': lastFetched != null ? Timestamp.fromDate(lastFetched!) : null,
      'itemCount': itemCount,
      'iconUrl': iconUrl,
      'fieldMapping': fieldMapping,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  String get typeLabel {
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

  String get typeIcon {
    switch (type) {
      case RssFeedType.webcams:
        return '📹';
      case RssFeedType.radioStations:
        return '🎵';
      case RssFeedType.quotes:
        return '💬';
      case RssFeedType.images:
        return '🖼️';
    }
  }

  bool get needsRefresh {
    if (lastFetched == null) return true;
    return DateTime.now().difference(lastFetched!).inMinutes >= refreshIntervalMinutes;
  }

  RssFeed copyWith({
    String? id,
    String? name,
    String? description,
    String? url,
    RssFeedType? type,
    bool? isEnabled,
    bool? isDefault,
    int? refreshIntervalMinutes,
    DateTime? lastFetched,
    int? itemCount,
    String? iconUrl,
    Map<String, String>? fieldMapping,
  }) {
    return RssFeed(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      url: url ?? this.url,
      type: type ?? this.type,
      isEnabled: isEnabled ?? this.isEnabled,
      isDefault: isDefault ?? this.isDefault,
      refreshIntervalMinutes: refreshIntervalMinutes ?? this.refreshIntervalMinutes,
      lastFetched: lastFetched ?? this.lastFetched,
      itemCount: itemCount ?? this.itemCount,
      iconUrl: iconUrl ?? this.iconUrl,
      fieldMapping: fieldMapping ?? this.fieldMapping,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
