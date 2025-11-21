import 'package:http/http.dart' as http;
import 'package:webfeed_plus/webfeed_plus.dart';
import '../models/models.dart';

class RssService {
  final Map<String, dynamic> _cache = {};
  final Duration _cacheExpiry = const Duration(minutes: 15);

  /// Fetch and parse RSS feed for quotes
  Future<List<Quote>> fetchQuotesFromFeed(String feedUrl) async {
    try {
      final response = await http.get(Uri.parse(feedUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch RSS feed');
      }

      final feed = RssFeed.parse(response.body);
      final quotes = <Quote>[];

      for (var item in feed.items ?? []) {
        quotes.add(Quote(
          id: item.guid ?? item.link ?? DateTime.now().toString(),
          text: _cleanHtml(item.title ?? item.description ?? ''),
          author: item.author,
          source: feed.title,
          rssFeedUrl: feedUrl,
          createdAt: item.pubDate,
        ));
      }

      return quotes;
    } catch (e) {
      print('Error fetching quotes RSS: $e');
      return [];
    }
  }

  /// Fetch webcams from RSS feed
  Future<List<Webcam>> fetchWebcamsFromFeed(String feedUrl) async {
    try {
      final response = await http.get(Uri.parse(feedUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch RSS feed');
      }

      final feed = RssFeed.parse(response.body);
      final webcams = <Webcam>[];

      for (var item in feed.items ?? []) {
        // Try to extract video URL from enclosure or media content
        String? videoUrl = item.enclosure?.url;

        if (videoUrl != null) {
          webcams.add(Webcam(
            id: item.guid ?? DateTime.now().toString(),
            name: item.title ?? 'Unknown',
            url: videoUrl,
            description: _cleanHtml(item.description ?? ''),
            thumbnailUrl: _extractThumbnail(item),
            createdAt: item.pubDate,
          ));
        }
      }

      return webcams;
    } catch (e) {
      print('Error fetching webcams RSS: $e');
      return [];
    }
  }

  /// Fetch radio stations from RSS feed
  Future<List<RadioStation>> fetchStationsFromFeed(String feedUrl) async {
    try {
      final response = await http.get(Uri.parse(feedUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch RSS feed');
      }

      final feed = RssFeed.parse(response.body);
      final stations = <RadioStation>[];

      for (var item in feed.items ?? []) {
        String? audioUrl = item.enclosure?.url;

        if (audioUrl != null) {
          stations.add(RadioStation(
            id: item.guid ?? DateTime.now().toString(),
            name: item.title ?? 'Unknown',
            streamUrl: audioUrl,
            description: _cleanHtml(item.description ?? ''),
            imageUrl: _extractThumbnail(item),
            createdAt: item.pubDate,
          ));
        }
      }

      return stations;
    } catch (e) {
      print('Error fetching stations RSS: $e');
      return [];
    }
  }

  /// Generic RSS fetch with caching
  Future<RssFeed?> fetchFeed(String url, {bool useCache = true}) async {
    final cacheKey = url;

    if (useCache && _cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey];
      if (DateTime.now().difference(cached['timestamp']) < _cacheExpiry) {
        return cached['data'] as RssFeed;
      }
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final feed = RssFeed.parse(response.body);
        _cache[cacheKey] = {
          'data': feed,
          'timestamp': DateTime.now(),
        };
        return feed;
      }
    } catch (e) {
      print('Error fetching feed: $e');
    }
    return null;
  }

  String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }

  String? _extractThumbnail(RssItem item) {
    // Try media:thumbnail first
    if (item.media?.thumbnails?.isNotEmpty ?? false) {
      return item.media!.thumbnails!.first.url;
    }
    // Try to extract from description
    final imgRegex = RegExp(r'<img[^>]+src="([^">]+)"');
    final match = imgRegex.firstMatch(item.description ?? '');
    return match?.group(1);
  }

  void clearCache() {
    _cache.clear();
  }
}
