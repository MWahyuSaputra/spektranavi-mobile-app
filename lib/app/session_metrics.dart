import 'dart:math';

import '../services/esp32_service.dart';
import 'app_config.dart';

/// Mengisi metrik latihan yang sudah ada, hanya saat sumber contoh aktif.
class SessionMetrics {
  final Random _random = Random();
  int _heartTotal = 0;
  int _heartCount = 0;
  double _reactionTotal = 0;
  int _reactionCount = 0;
  int peakHeart = 0;
  double? reactionMs;
  double? bestReactionMs;
  double? laneDeviation;
  int blocks = 0;
  int attempts = 0;

  int get averageHeart => _heartCount == 0 ? 0 : (_heartTotal / _heartCount).round();

  double? get averageReactionMs => _reactionCount == 0 ? null : _reactionTotal / _reactionCount;

  void record(Esp32TelemetryData data) {
    if (!AppConfig.esp32Mock || !data.connected) return;
    final bpm = data.heartRateBpm;
    if (bpm != null) {
      _heartTotal += bpm;
      _heartCount++;
      peakHeart = max(peakHeart, bpm);
    }
    reactionMs = data.reactionMs;
    if (reactionMs != null) {
      _reactionTotal += reactionMs!;
      _reactionCount++;
      bestReactionMs = min(bestReactionMs ?? reactionMs!, reactionMs!);
    }
    laneDeviation = 0.08 + 0.02 * _random.nextDouble();
    if (_heartCount > 0 && _heartCount % 5 == 0) {
      attempts++;
      if (_random.nextDouble() < 0.8) blocks++;
    }
  }
}
