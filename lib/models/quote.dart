import 'package:cloud_firestore/cloud_firestore.dart';

enum QuoteCategory {
  motivational,
  inspirational,
  consolation,
  wisdom,
  love,
  humor,
  philosophical,
}

class Quote {
  final String id;
  final String text;
  final String? author;
  final String? source;
  final QuoteCategory category;
  final String? rssFeedUrl;
  final List<String> tags;
  final DateTime? createdAt;

  Quote({
    required this.id,
    required this.text,
    this.author,
    this.source,
    this.category = QuoteCategory.inspirational,
    this.rssFeedUrl,
    this.tags = const [],
    this.createdAt,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      author: json['author'],
      source: json['source'],
      category: QuoteCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => QuoteCategory.inspirational,
      ),
      rssFeedUrl: json['rssFeedUrl'],
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'author': author,
      'source': source,
      'category': category.name,
      'rssFeedUrl': rssFeedUrl,
      'tags': tags,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  String get categoryLabel {
    switch (category) {
      case QuoteCategory.motivational:
        return 'Motivacional';
      case QuoteCategory.inspirational:
        return 'Inspiracional';
      case QuoteCategory.consolation:
        return 'Consolación';
      case QuoteCategory.wisdom:
        return 'Sabiduría';
      case QuoteCategory.love:
        return 'Amor';
      case QuoteCategory.humor:
        return 'Humor';
      case QuoteCategory.philosophical:
        return 'Filosófico';
    }
  }

  String get displayText {
    if (author != null && author!.isNotEmpty) {
      return '"$text"\n— $author';
    }
    return '"$text"';
  }
}
