import 'dart:math';

/// Utilitas "random walk" — nilai berubah sedikit demi sedikit tiap
/// tick, dipakai untuk mensimulasikan detak jantung (BPM) selama
/// firmware ESP32 belum menghitung BPM asli dari sinyal ECG.
double stepValue(
  double current, {
  required double min,
  required double max,
  required double maxStep,
  required Random random,
}) {
  final delta = (random.nextDouble() * 2 - 1) * maxStep;
  final next = current + delta;
  return next.clamp(min, max).toDouble();
}

int stepInt(
  int current, {
  required int min,
  required int max,
  required int maxStep,
  required Random random,
}) {
  final delta = random.nextInt(maxStep * 2 + 1) - maxStep;
  final next = current + delta;
  return next.clamp(min, max).toInt();
}

List<int> shiftBars(
  List<int> bars, {
  required int min,
  required int max,
  required int maxStep,
  required Random random,
}) {
  final last = bars.isNotEmpty ? bars.last : (min + max) ~/ 2;
  final next = stepInt(last, min: min, max: max, maxStep: maxStep, random: random);
  return [...bars.sublist(1), next];
}