import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../services/esp32_service.dart';
import 'heart_rate_chart.dart';
import 'training_metric_card.dart';

class HeartRateTelemetryCard extends StatelessWidget {
  final Esp32TelemetryData data;
  const HeartRateTelemetryCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final bpm = data.connected ? data.heartRateBpm : null;
    return TrainingMetricCard(
      title: 'Detak Jantung',
      value: bpm?.toString() ?? '--',
      unit: 'BPM',
      subtitle: bpm != null
          ? 'Detak jantung atlet'
          : data.connected && data.ecgRaw != null
              ? 'ECG raw tersedia, BPM belum dihitung'
              : 'Belum tersedia dari telemetry ESP32',
      valueColor: bpm != null ? Colors.black : Colors.black45,
      topRightIcon: Icons.favorite,
      topRightColor: AppColors.red,
      chart: bpm != null
          ? HeartRateSpikeChart(samples: data.heartSamples, height: 46)
          : _NoMetricChart(data.connected && data.ecgRaw != null
              ? 'ECG raw tersedia, BPM belum dihitung'
              : 'Tidak ada data ECG'),
    );
  }
}

class ReactionTelemetryCard extends StatelessWidget {
  final Esp32TelemetryData data;
  final double? bestReactionMs;
  const ReactionTelemetryCard({super.key, required this.data, this.bestReactionMs});

  @override
  Widget build(BuildContext context) {
    final reaction = data.connected ? data.reactionMs : null;
    return TrainingMetricCard(
      title: 'Waktu Reaksi',
      value: reaction?.round().toString() ?? '--',
      unit: 'ms',
      subtitle: reaction == null
          ? 'Data reaksi belum tersedia'
          : 'Terbaik : ${(bestReactionMs ?? reaction).round()}ms',
      valueColor: reaction != null ? Colors.black : Colors.black45,
      topRightIcon: Icons.bolt,
      topRightColor: AppColors.green,
      chart: reaction == null
          ? const _NoMetricChart('Menunggu data reaksi...')
          : SizedBox(
              height: 46,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.reactionSamples.map((sample) => Expanded(
                  child: Container(
                    height: (sample / 800 * 42).clamp(2.0, 44.0).toDouble(),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )).toList(),
              ),
            ),
    );
  }
}

class _NoMetricChart extends StatelessWidget {
  final String text;
  const _NoMetricChart(this.text);

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 46,
    child: Center(child: Text(text,
      style: const TextStyle(fontSize: 10, color: Colors.black45))),
  );
}
