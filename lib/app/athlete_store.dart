import 'app_config.dart';
import 'sample_data.dart';
import 'package:flutter/foundation.dart';
import '../services/firestore_service.dart';

class Athlete {
  final String id;
  final String name;
  final String initial;

  Athlete({required this.id, required this.name})
      : initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : "?";
}

/// Menyimpan daftar atlet, disinkronkan ke Firestore per akun pelatih.
/// Panggil `load()` sekali setelah pengguna login (mis. di halaman
/// utama) untuk mengambil data dari Firestore.
class AthleteStore extends ChangeNotifier {
  AthleteStore._internal();
  static final AthleteStore instance = AthleteStore._internal();

  final List<Athlete> _athletes = [];
  bool _loaded = false;
  int _nextNumber = 1;

  List<Athlete> get athletes => List.unmodifiable(_athletes);
  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    if (AppConfig.useSampleData) {
      _athletes
        ..clear()
        ..addAll(SampleData.athletes.map((d) => Athlete(id: d['id']!, name: d['name']!)));
      _nextNumber = _athletes.length + 1;
      _loaded = true;
      notifyListeners();
      return;
    }
    try {
      final data = await FirestoreService.instance.fetchAthletes();
      _athletes
        ..clear()
        ..addAll(data.map((d) => Athlete(id: d['id'], name: d['name'] ?? '')));
      _nextNumber = _athletes.length + 1;
      _loaded = true;
      notifyListeners();
    } catch (_) {
      // Kalau gagal ambil dari Firestore (mis. offline), biarkan daftar
      // kosong dulu — pengguna tetap bisa menambah atlet secara manual.
      _loaded = true;
    }
  }

  /// Reset state saat logout, supaya data akun sebelumnya tidak
  /// tertinggal/bocor ke sesi login berikutnya.
  void reset() {
    _athletes.clear();
    _loaded = false;
    _nextNumber = 1;
    notifyListeners();
  }

  Future<void> addAthlete(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final id = "Atlet-${_nextNumber.toString().padLeft(2, '0')}";
    _nextNumber++;
    _athletes.add(Athlete(id: id, name: trimmed));
    notifyListeners();

    try {
      if (!AppConfig.useSampleData) {
        await FirestoreService.instance.addAthlete(id: id, name: trimmed);
      }
    } catch (_) {
      // Tersimpan sementara di memori walau gagal sinkron ke server.
    }
  }

  Future<void> removeAthlete(String id) async {
    _athletes.removeWhere((a) => a.id == id);
    notifyListeners();

    try {
      if (!AppConfig.useSampleData) {
        await FirestoreService.instance.removeAthlete(id);
      }
    } catch (_) {}
  }
}