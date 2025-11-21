import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa un "momento" compartido - una combinación perfecta
/// de video y audio que crea una experiencia emocional
class Momento {
  final String id;
  final String? title;
  final String? description;

  // Video/Webcam info
  final String webcamId;
  final String webcamUrl;
  final String? webcamName;
  final String? videoTimestamp; // YouTube timestamp or HLS position

  // Audio info
  final String audioId;
  final String audioUrl;
  final String? audioName;
  final int? audioOffsetSeconds; // Offset to sync with video

  // Quote overlay (optional)
  final String? quoteText;
  final String? quoteSource;

  // Metadata
  final String creatorId;
  final String? creatorName;
  final DateTime createdAt;
  final int likes;
  final int shares;
  final List<String> tags;

  // Display settings
  final Map<String, dynamic>? displaySettings; // font, color, size for quotes

  Momento({
    required this.id,
    this.title,
    this.description,
    required this.webcamId,
    required this.webcamUrl,
    this.webcamName,
    this.videoTimestamp,
    required this.audioId,
    required this.audioUrl,
    this.audioName,
    this.audioOffsetSeconds,
    this.quoteText,
    this.quoteSource,
    required this.creatorId,
    this.creatorName,
    required this.createdAt,
    this.likes = 0,
    this.shares = 0,
    this.tags = const [],
    this.displaySettings,
  });

  factory Momento.fromJson(Map<String, dynamic> json) {
    return Momento(
      id: json['id'] ?? '',
      title: json['title'],
      description: json['description'],
      webcamId: json['webcamId'] ?? '',
      webcamUrl: json['webcamUrl'] ?? '',
      webcamName: json['webcamName'],
      videoTimestamp: json['videoTimestamp'],
      audioId: json['audioId'] ?? '',
      audioUrl: json['audioUrl'] ?? '',
      audioName: json['audioName'],
      audioOffsetSeconds: json['audioOffsetSeconds'],
      quoteText: json['quoteText'],
      quoteSource: json['quoteSource'],
      creatorId: json['creatorId'] ?? '',
      creatorName: json['creatorName'],
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      likes: json['likes'] ?? 0,
      shares: json['shares'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      displaySettings: json['displaySettings'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'webcamId': webcamId,
      'webcamUrl': webcamUrl,
      'webcamName': webcamName,
      'videoTimestamp': videoTimestamp,
      'audioId': audioId,
      'audioUrl': audioUrl,
      'audioName': audioName,
      'audioOffsetSeconds': audioOffsetSeconds,
      'quoteText': quoteText,
      'quoteSource': quoteSource,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'likes': likes,
      'shares': shares,
      'tags': tags,
      'displaySettings': displaySettings,
    };
  }

  /// Genera un deep link para compartir el momento
  String get shareUrl => 'https://streamaura.app/momento/$id';

  Momento copyWith({
    String? id,
    String? title,
    String? description,
    String? webcamId,
    String? webcamUrl,
    String? webcamName,
    String? videoTimestamp,
    String? audioId,
    String? audioUrl,
    String? audioName,
    int? audioOffsetSeconds,
    String? quoteText,
    String? quoteSource,
    String? creatorId,
    String? creatorName,
    DateTime? createdAt,
    int? likes,
    int? shares,
    List<String>? tags,
    Map<String, dynamic>? displaySettings,
  }) {
    return Momento(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      webcamId: webcamId ?? this.webcamId,
      webcamUrl: webcamUrl ?? this.webcamUrl,
      webcamName: webcamName ?? this.webcamName,
      videoTimestamp: videoTimestamp ?? this.videoTimestamp,
      audioId: audioId ?? this.audioId,
      audioUrl: audioUrl ?? this.audioUrl,
      audioName: audioName ?? this.audioName,
      audioOffsetSeconds: audioOffsetSeconds ?? this.audioOffsetSeconds,
      quoteText: quoteText ?? this.quoteText,
      quoteSource: quoteSource ?? this.quoteSource,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      shares: shares ?? this.shares,
      tags: tags ?? this.tags,
      displaySettings: displaySettings ?? this.displaySettings,
    );
  }
}
