import 'app_config.dart';
import 'package:flutter/foundation.dart';
import '../services/firestore_service.dart';

class TrainingSession {
  final String mode;
  final String athlete;
  final DateTime date;
  final Duration duration;
  final int avgHeart;
  final int peakHeart;
  final String midValue;
  final String midSub;
  final String rightValue;
  final String rightSub;

  const TrainingSession({
    required this.mode,
    required this.athlete,
    required this.date,
    required this.duration,
    required this.avgHeart,
    required this.peakHeart,
    required this.midValue,
    required this.midSub,
    required this.rightValue,
    required this.rightSub,
  });

  String get durationLabel {
    final m = duration.inMinutes;
    final s = duration.inSeconds % 60;
    if (m <= 0) return "$s detik";
    return "$m menit";
  }

  String get dateLabel {
    const bulan = [
      "Jan", "Feb", "Mar", "Apr", "Mei", "Jun",
      "Jul", "Agu", "Sep", "Okt", "Nov", "Des",
    ];
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return "${date.day} ${bulan[date.month - 1]} ${date.year} · $hh:$mm";
  }

  Map<String, dynamic> toMap() {
    return {
      'mode': mode,
      'athlete': athlete,
      'date': date.toIso8601String(),
      'durationSeconds': duration.inSeconds,
      'avgHeart': avgHeart,
      'peakHeart': peakHeart,
      'midValue': midValue,
      'midSub': midSub,
      'rightValue': rightValue,
      'rightSub': rightSub,
    };
  }

  factory TrainingSession.fromMap(Map<String, dynamic> map) {
    return TrainingSession(
      mode: map['mode'] ?? '',
      athlete: map['athlete'] ?? '',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      duration: Duration(seconds: (map['durationSeconds'] ?? 0) as int),
      avgHeart: (map['avgHeart'] ?? 0) as int,
      peakHeart: (map['peakHeart'] ?? 0) as int,
      midValue: map['midValue'] ?? '',
      midSub: map['midSub'] ?? '',
      rightValue: map['rightValue'] ?? '',
      rightSub: map['rightSub'] ?? '',
    );
  }
}

/// Menyimpan histori sesi latihan, disinkronkan ke Firestore per akun
/// pelatih. Panggil `load()` sekali setelah pengguna login.
class SessionStore extends ChangeNotifier {
  SessionStore._internal();
  static final SessionStore instance = SessionStore._internal();

  final List<TrainingSession> _sessions = [];
  bool _loaded = false;

  List<TrainingSession> get sessions => List.unmodifiable(_sessions);
  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    if (AppConfig.useSampleData) {
      final now = DateTime.now();
      _sessions
        ..clear()
        ..addAll([
          TrainingSession(
            mode: 'Mode Tanding',
            athlete: 'Ahmad Rizki',
            date: now.subtract(const Duration(days: 1)),
            duration: const Duration(minutes: 30),
            avgHeart: 128,
            peakHeart: 151,
            midValue: '92%',
            midSub: 'Akurasi',
            rightValue: '17',
            rightSub: 'Blokade',
          ),
          TrainingSession(
            mode: 'Mode Simulasi',
            athlete: 'Siti Nurhaliza',
            date: now.subtract(const Duration(days: 2)),
            duration: const Duration(minutes: 20),
            avgHeart: 118,
            peakHeart: 137,
            midValue: '494ms',
            midSub: 'Best RT',
            rightValue: '73%',
            rightSub: 'Akurasi',
          ),
          TrainingSession(
            mode: 'Mode Lari',
            athlete: 'Budi Santoso',
            date: now.subtract(const Duration(days: 3)),
            duration: const Duration(minutes: 40),
            avgHeart: 122,
            peakHeart: 143,
            midValue: '520ms',
            midSub: 'Best RT',
            rightValue: '0.08m',
            rightSub: 'Lane dev.',
          ),
        ]);
      _loaded = true;
      notifyListeners();
      return;
    }
    try {
      final data = await FirestoreService.instance.fetchSessions();
      _sessions
        ..clear()
        ..addAll(data.map((d) => TrainingSession.fromMap(d)));
      _loaded = true;
      notifyListeners();
    } catch (_) {
      _loaded = true;
    }
  }

  void reset() {
    _sessions.clear();
    _loaded = false;
    notifyListeners();
  }

  Future<void> addSession(TrainingSession session) async {
    _sessions.insert(0, session);
    notifyListeners();

    try {
      if (!AppConfig.useSampleData) {
        await FirestoreService.instance.addSession(session.toMap());
      }
    } catch (_) {
      // Tersimpan sementara di memori walau gagal sinkron ke server.
    }
  }
}