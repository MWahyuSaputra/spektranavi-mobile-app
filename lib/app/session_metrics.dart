import 'dart:math';

import '../services/esp32_service.dart';

/// Menghitung metrik latihan (rata-rata BPM, rata-rata waktu reaksi,
/// puncak BPM, dan best RT) dari telemetry ESP32 selama sesi berjalan.
class SessionMetrics {
  int _heartTotal = 0;
  int _heartCount = 0;
  double _reactionTotal = 0;
  int _reactionCount = 0;
  int peakHeart = 0;
  double? reactionMs;
  double? bestReactionMs;

  /// Sample terakhir yang sudah dihitung. Dipakai untuk mendeteksi
  /// sample baru, karena telemetry mempertahankan nilai terakhir saat
  /// field-nya tidak dikirim ulang (tidak boleh dihitung dobel).
  List<int> _heartSamples = const [];
  List<int> _reactionSamples = const [];

  bool _started = false;

  int get averageHeart =>
      _heartCount == 0 ? 0 : (_heartTotal / _heartCount).round();

  double? get averageReactionMs =>
      _reactionCount == 0 ? null : _reactionTotal / _reactionCount;

  void record(Esp32TelemetryData data) {
    if (!data.connected) return;

    // Snapshot pertama = kondisi sebelum sesi dimulai, jangan dihitung.
    if (!_started) {
      _started = true;
      _heartSamples = data.heartSamples;
      _reactionSamples = data.reactionSamples;
      return;
    }

    _recordHeartSamples(data.heartSamples);
    _recordReactionSamples(data.reactionSamples);

    reactionMs = data.reactionMs;
  }

  void _recordHeartSamples(List<int> samples) {
    for (final bpm in _newSamples(_heartSamples, samples)) {
      if (bpm <= 0) continue;
      _heartTotal += bpm;
      _heartCount++;
      peakHeart = max(peakHeart, bpm);
    }
    _heartSamples = samples;
  }

  void _recordReactionSamples(List<int> samples) {
    for (final ms in _newSamples(_reactionSamples, samples)) {
      if (ms <= 0) continue;
      _reactionTotal += ms;
      _reactionCount++;
      bestReactionMs = min(bestReactionMs ?? ms.toDouble(), ms.toDouble());
    }
    _reactionSamples = samples;
  }

  /// Sample baru pada list riwayat. Riwayat dibatasi 20 entri, jadi saat
  /// sudah penuh jumlahnya tidak bertambah — cukup ambil entri terakhir.
  List<int> _newSamples(List<int> previous, List<int> current) {
    if (current.isEmpty) return const [];

    if (previous.isEmpty) return current;

    if (current.length > previous.length) {
      final added = current.length - previous.length;
      return current.sublist(current.length - added);
    }

    return current.last == previous.last ? const [] : [current.last];
  }
}
