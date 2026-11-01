import 'package:flutter_test/flutter_test.dart';
import 'package:spektranavi/app/session_metrics.dart';
import 'package:spektranavi/services/esp32_service.dart';

Esp32TelemetryData _frame({
  List<int> heartSamples = const [],
  List<int> reactionSamples = const [],
  int? bpm,
  double? reactionMs,
}) {
  return Esp32TelemetryData(
    connected: true,
    heartRateBpm: bpm,
    reactionMs: reactionMs,
    heartSamples: heartSamples,
    reactionSamples: reactionSamples,
  );
}

void main() {
  test('Avg BPM dan avg RT dihitung realtime dari telemetry perangkat', () {
    final metrics = SessionMetrics();

    // Frame pertama = snapshot sebelum sesi, tidak dihitung.
    metrics.record(
      _frame(
        heartSamples: const [60, 62],
        reactionSamples: const [700],
        bpm: 62,
        reactionMs: 700,
      ),
    );
    expect(metrics.averageHeart, 0);
    expect(metrics.averageReactionMs, isNull);

    metrics.record(
      _frame(
        heartSamples: const [60, 62, 70, 72],
        reactionSamples: const [700, 520],
        bpm: 72,
        reactionMs: 520,
      ),
    );
    expect(metrics.averageHeart, 71);
    expect(metrics.averageReactionMs, 520);
    expect(metrics.peakHeart, 72);
    expect(metrics.bestReactionMs, 520);
  });

  test('Sample lama yang dikirim ulang tidak dihitung dobel', () {
    final metrics = SessionMetrics();
    metrics.record(
      _frame(heartSamples: const [80], reactionSamples: const [600]),
    );

    final data = _frame(
      heartSamples: const [80, 90],
      reactionSamples: const [600, 500],
      bpm: 90,
      reactionMs: 500,
    );
    metrics.record(data);
    metrics.record(data);
    metrics.record(data);

    expect(metrics.averageHeart, 90);
    expect(metrics.averageReactionMs, 500);
  });

  test('Riwayat penuh (20 sample) tetap mendeteksi sample baru', () {
    final metrics = SessionMetrics();
    final before = List<int>.generate(20, (i) => 60 + i);
    metrics.record(_frame(heartSamples: before));

    final after = [...before.sublist(1), 120];
    metrics.record(_frame(heartSamples: after));

    expect(metrics.averageHeart, 120);
    expect(metrics.peakHeart, 120);
  });

}
