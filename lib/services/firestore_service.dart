import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Layanan penyimpanan data atlet & sesi latihan ke Firestore,
/// terpisah per akun pelatih (coach) lewat uid Firebase Auth.
///
/// Struktur data:
///   coaches/{uid}/athletes/{athleteId}
///   coaches/{uid}/sessions/{sessionId}
class FirestoreService {
  FirestoreService._internal();
  static final FirestoreService instance = FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _athletesRef {
    if (_uid == null) throw StateError('Belum login');
    return _db.collection('coaches').doc(_uid).collection('athletes');
  }

  CollectionReference<Map<String, dynamic>> get _sessionsRef {
    if (_uid == null) throw StateError('Belum login');
    return _db.collection('coaches').doc(_uid).collection('sessions');
  }

  // ---------- Atlet ----------

  Future<void> addAthlete({required String id, required String name}) {
    return _athletesRef.doc(id).set({
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeAthlete(String id) {
    return _athletesRef.doc(id).delete();
  }

  /// Ambil semua atlet sekali (dipakai saat load awal).
  Future<List<Map<String, dynamic>>> fetchAthletes() async {
    final snap = await _athletesRef.orderBy('createdAt').get();
    return snap.docs
        .map((d) => {'id': d.id, ...d.data()})
        .toList();
  }

  // ---------- Sesi Latihan ----------

  Future<void> addSession(Map<String, dynamic> sessionData) {
    return _sessionsRef.add({
      ...sessionData,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> fetchSessions() async {
    final snap = await _sessionsRef.orderBy('createdAt', descending: true).get();
    return snap.docs
        .map((d) => {'id': d.id, ...d.data()})
        .toList();
  }
}