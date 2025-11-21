import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _rssFeeds => _firestore.collection('rssFeeds');
  CollectionReference get _admins => _firestore.collection('admins');

  // ============ AUTH ============

  /// Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _admins.doc(user.uid).get();
    return doc.exists;
  }

  /// Sign in admin
  Future<bool> signInAdmin(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return await isCurrentUserAdmin();
    } catch (e) {
      return false;
    }
  }

  // ============ RSS FEEDS MANAGEMENT ============

  Stream<List<RssFeed>> getRssFeeds() {
    return _rssFeeds.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return RssFeed.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id});
      }).toList();
    });
  }

  Stream<List<RssFeed>> getRssFeedsByType(RssFeedType type) {
    return _rssFeeds
        .where('type', isEqualTo: type.name)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return RssFeed.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id});
      }).toList();
    });
  }

  Future<String?> createRssFeed(RssFeed feed) async {
    try {
      final doc = await _rssFeeds.add(feed.toJson());
      return doc.id;
    } catch (e) {
      print('Error creating RSS feed: $e');
      return null;
    }
  }

  Future<void> updateRssFeed(RssFeed feed) async {
    await _rssFeeds.doc(feed.id).update(feed.toJson());
  }

  Future<void> deleteRssFeed(String id) async {
    await _rssFeeds.doc(id).delete();
  }

  Future<void> toggleRssFeed(String id, bool isEnabled) async {
    await _rssFeeds.doc(id).update({
      'isEnabled': isEnabled,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> updateFeedLastFetched(String id, int itemCount) async {
    await _rssFeeds.doc(id).update({
      'lastFetched': Timestamp.fromDate(DateTime.now()),
      'itemCount': itemCount,
    });
  }

  // ============ STATS ============

  Future<Map<String, dynamic>> getStats() async {
    final webcamsCount = await _firestore.collection('webcams').count().get();
    final stationsCount = await _firestore.collection('stations').count().get();
    final momentosCount = await _firestore.collection('momentos').count().get();
    final usersCount = await _firestore.collection('users').count().get();
    final rssFeedsCount = await _rssFeeds.count().get();

    return {
      'webcams': webcamsCount.count,
      'stations': stationsCount.count,
      'momentos': momentosCount.count,
      'users': usersCount.count,
      'rssFeeds': rssFeedsCount.count,
    };
  }

  // ============ CONTENT MODERATION ============

  Future<void> deleteWebcam(String id) async {
    await _firestore.collection('webcams').doc(id).delete();
  }

  Future<void> deleteStation(String id) async {
    await _firestore.collection('stations').doc(id).delete();
  }

  Future<void> deleteMomento(String id) async {
    await _firestore.collection('momentos').doc(id).delete();
  }

  Future<void> deleteQuote(String id) async {
    await _firestore.collection('quotes').doc(id).delete();
  }

  // ============ BULK OPERATIONS ============

  Future<int> importFromRssFeed(RssFeed feed, List<Map<String, dynamic>> items) async {
    final batch = _firestore.batch();
    String collectionName;

    switch (feed.type) {
      case RssFeedType.webcams:
        collectionName = 'webcams';
        break;
      case RssFeedType.radioStations:
        collectionName = 'stations';
        break;
      case RssFeedType.quotes:
        collectionName = 'quotes';
        break;
      case RssFeedType.images:
        collectionName = 'images';
        break;
    }

    for (var item in items) {
      final docRef = _firestore.collection(collectionName).doc();
      item['rssFeedId'] = feed.id;
      item['createdAt'] = Timestamp.fromDate(DateTime.now());
      batch.set(docRef, item);
    }

    await batch.commit();
    await updateFeedLastFetched(feed.id, items.length);

    return items.length;
  }
}
