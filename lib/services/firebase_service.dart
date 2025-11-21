import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  CollectionReference get _webcams => _firestore.collection('webcams');
  CollectionReference get _stations => _firestore.collection('stations');
  CollectionReference get _momentos => _firestore.collection('momentos');
  CollectionReference get _quotes => _firestore.collection('quotes');
  CollectionReference get _favoritos => _firestore.collection('favoritos');

  // Current user
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ============ AUTH ============

  Future<UserCredential?> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      print('Error signing in anonymously: $e');
      return null;
    }
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  Future<UserCredential?> registerWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error registering: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ============ WEBCAMS ============

  Stream<List<Webcam>> getWebcams() {
    return _webcams.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Webcam.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id});
      }).toList();
    });
  }

  Future<List<Webcam>> getWebcamsByCountry(String country) async {
    final snapshot = await _webcams.where('country', isEqualTo: country).get();
    return snapshot.docs.map((doc) {
      return Webcam.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id});
    }).toList();
  }

  // ============ RADIO STATIONS ============

  Stream<List<RadioStation>> getStations() {
    return _stations.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return RadioStation.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id});
      }).toList();
    });
  }

  Stream<List<RadioStation>> getStationsByType(AudioType type) {
    return _stations
        .where('type', isEqualTo: type.name)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return RadioStation.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id});
      }).toList();
    });
  }

  // ============ MOMENTOS ============

  Stream<List<Momento>> getMomentos({int limit = 50}) {
    return _momentos
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Momento.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id});
      }).toList();
    });
  }

  Stream<List<Momento>> getPopularMomentos({int limit = 20}) {
    return _momentos
        .orderBy('likes', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Momento.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id});
      }).toList();
    });
  }

  Future<Momento?> getMomentoById(String id) async {
    final doc = await _momentos.doc(id).get();
    if (doc.exists) {
      return Momento.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id});
    }
    return null;
  }

  Future<String?> createMomento(Momento momento) async {
    try {
      final doc = await _momentos.add(momento.toJson());
      return doc.id;
    } catch (e) {
      print('Error creating momento: $e');
      return null;
    }
  }

  Future<void> likeMomento(String momentoId) async {
    await _momentos.doc(momentoId).update({
      'likes': FieldValue.increment(1),
    });
  }

  // ============ QUOTES ============

  Stream<List<Quote>> getQuotes({QuoteCategory? category}) {
    Query query = _quotes;
    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Quote.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id});
      }).toList();
    });
  }

  Future<Quote?> getRandomQuote({QuoteCategory? category}) async {
    // Simple random: get all and pick one
    // For production, use a better approach with random document IDs
    Query query = _quotes;
    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }
    final snapshot = await query.limit(100).get();
    if (snapshot.docs.isEmpty) return null;

    final randomIndex = DateTime.now().millisecondsSinceEpoch % snapshot.docs.length;
    final doc = snapshot.docs[randomIndex];
    return Quote.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id});
  }

  // ============ FAVORITOS ============

  Stream<List<Favorito>> getUserFavoritos(String userId) {
    return _favoritos
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Favorito.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id});
      }).toList();
    });
  }

  Future<String?> addFavorito(Favorito favorito) async {
    try {
      // Check if already favorited
      final existing = await _favoritos
          .where('userId', isEqualTo: favorito.userId)
          .where('itemId', isEqualTo: favorito.itemId)
          .where('type', isEqualTo: favorito.type.name)
          .get();

      if (existing.docs.isNotEmpty) {
        return existing.docs.first.id;
      }

      final doc = await _favoritos.add(favorito.toJson());
      return doc.id;
    } catch (e) {
      print('Error adding favorito: $e');
      return null;
    }
  }

  Future<void> removeFavorito(String favoritoId) async {
    await _favoritos.doc(favoritoId).delete();
  }

  Future<bool> isFavorito(String userId, String itemId, FavoritoType type) async {
    final snapshot = await _favoritos
        .where('userId', isEqualTo: userId)
        .where('itemId', isEqualTo: itemId)
        .where('type', isEqualTo: type.name)
        .get();
    return snapshot.docs.isNotEmpty;
  }
}
