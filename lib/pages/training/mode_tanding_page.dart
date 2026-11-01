import '../../app/session_metrics.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../app/app_colors.dart';
import '../../app/app_styles.dart';
import '../../app/athlete_store.dart';
import '../../app/session_store.dart';
import '../../services/device_services.dart';
import '../../services/esp32_service.dart';
import '../../services/mqtt_service.dart';
import '../../widgets/live_stat_box.dart';
import '../../widgets/posture_card.dart';
import '../../widgets/status_chip_row.dart';
import '../../widgets/telemetry_metric_cards.dart';

class ModeTandingPage extends StatefulWidget {
  final Athlete athlete;
  const ModeTandingPage({super.key, required this.athlete});

  @override
  State<ModeTandingPage> createState() => _ModeTandingPageState();
}

class _ModeTandingPageState extends State<ModeTandingPage> {
  final DateTime _startTime = DateTime.now();
  Duration _elapsed = Duration.zero;
  late final Timer _timer;
  final SessionMetrics _metrics = SessionMetrics();


  @override
  void initState() {
    super.initState();
    final esp32 = DeviceServices.instance.esp32;

    // Snapshot awal: metrik dihitung sejak sesi dimulai.
    _metrics.record(esp32.data.value);
    esp32.data.addListener(_onTelemetry);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsed = DateTime.now().difference(_startTime);
      });
    });
  }

  /// Setiap frame telemetry langsung masuk perhitungan supaya AVG BPM
  /// dan AVG RT tampil realtime, bukan menunggu timer 1 detik.
  void _onTelemetry() {
    if (!mounted) return;
    setState(() {
      _metrics.record(DeviceServices.instance.esp32.data.value);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    DeviceServices.instance.esp32.data.removeListener(_onTelemetry);
    super.dispose();
  }

  String get _durasiLabel {
    final m = _elapsed.inMinutes.toString().padLeft(2, '0');
    final s = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  void _stopSesi() {
    _timer.cancel();
    final session = TrainingSession(
      mode: "Mode Tanding",
      athlete: widget.athlete.name,
      date: DateTime.now(),
      duration: _elapsed,
      avgHeart: _metrics.averageHeart,
      peakHeart: _metrics.peakHeart,
      midValue: _metrics.bestReactionMs == null ? "--" : "${_metrics.bestReactionMs!.round()}ms",
      midSub: _metrics.bestReactionMs == null ? "Best reaction time belum tersedia" : "Best RT",
    );
    Navigator.pop(context, session);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Esp32TelemetryData>(
      valueListenable: DeviceServices.instance.esp32.data,
      builder: (context, esp32, _) {
        final postureStatus = esp32.connected && esp32.imuValid ? ([esp32.pitch.abs(), esp32.roll.abs()].reduce(max) > 9 ? "TILTING" : "STABLE")
            : "NO DATA";
        final postureColor = !esp32.connected || !esp32.imuValid ? Colors.black38
            : (postureStatus == "STABLE" ? AppColors.green : const Color(0xFFE8A640));

        return ValueListenableBuilder<MqttVisionData>(
          valueListenable: DeviceServices.instance.mqtt.data,
          builder: (context, vision, __) {
            return Scaffold(
              backgroundColor: AppColors.primary,
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Mode Tanding", style: AppStyles.pageTitle),
                      const SizedBox(height: 10),

                      StatusChipRow(
                        visionOnline: vision.piOnline,
                        esp32Online: esp32.connected,
                      ),
                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _stopSesi,
                          icon: const Icon(Icons.stop_outlined, size: 18),
                          label: const Text(
                            "Stop Sesi",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(color: Colors.white, width: 1),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          const Icon(Icons.circle, size: 7, color: Color(0xFF72D59B)),
                          const SizedBox(width: 6),
                          const Text(
                            "MODE TANDING - LIVE",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            widget.athlete.name.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          LiveStatBox(
                            icon: Icons.timer_outlined,
                            value: _durasiLabel,
                            label: "DURASI",
                          ),
                          LiveStatBox(
                            icon: Icons.favorite_border,
                            value: _metrics.averageHeart > 0 ? _metrics.averageHeart.toString() : "--",
                            label: "AVG BPM",
                          ),
                          LiveStatBox(
                            icon: Icons.bolt_outlined,
                            value: _metrics.averageReactionMs == null
                                ? "--"
                                : "${_metrics.averageReactionMs!.round()}ms",
                            label: "AVG RT",
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: AppStyles.cardRadius,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text("EDGE VISION AI", style: AppStyles.sectionLabelDark),
                                const Spacer(),
                                Icon(
                                  Icons.visibility,
                                  size: 16,
                                  color: vision.ballDetected
                                      ? const Color(0xFF1B8A4F)
                                      : Colors.black38,
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: vision.ballDetected
                                        ? const Color(0xFFDBF5E4)
                                        : const Color(0xFFFBDCDC),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    vision.ballDetected ? "BOLA TERDETEKSI" : "BOLA TIDAK TERDETEKSI",
                                    style: TextStyle(
                                      color: vision.ballDetected
                                          ? const Color(0xFF1B8A4F)
                                          : const Color(0xFFB33A3A),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 6,
                                  color: vision.piOnline ? AppColors.green : Colors.black26,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  vision.piOnline ? "Raspberry Pi online" : "Raspberry Pi offline",
                                  style: AppStyles.cardSubtitle,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: _AiStat(
                                    value: vision.latencyMs != null ? "${vision.latencyMs!.toStringAsFixed(1)}ms" : "--",
                                    label: "Latency",
                                    icon: Icons.timer_outlined,
                                  ),
                                ),
                                Expanded(
                                  child: _AiStat(
                                    value: vision.confidencePercent != null ? "${vision.confidencePercent!.toStringAsFixed(1)}%" : "--",
                                    label: "Confidence",
                                    icon: Icons.adjust_outlined,
                                  ),
                                ),
                                Expanded(
                                  child: _AiStat(
                                    value: vision.fps != null ? vision.fps!.toStringAsFixed(1) : "--",
                                    label: "FPS",
                                    icon: Icons.grid_view_outlined,
                                  ),
                                ),
                                Expanded(
                                  child: _AiStat(
                                    value: vision.trajectory,
                                    label: "Trajectory",
                                    icon: Icons.remove_red_eye_outlined,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      HeartRateTelemetryCard(data: esp32),

                      ReactionTelemetryCard(data: esp32, bestReactionMs: _metrics.bestReactionMs),

                      PostureCard(
                        statusText: postureStatus,
                        statusColor: postureColor,
                        dotColor: Colors.blue,
                        yaw: esp32.connected && esp32.imuValid ? "${esp32.heading.toStringAsFixed(1)}°" : "--",
                        pitch: esp32.connected && esp32.imuValid ? "${esp32.pitch.toStringAsFixed(1)}°" : "--",
                        roll: esp32.connected && esp32.imuValid ? "${esp32.roll.toStringAsFixed(1)}°" : "--",
                        yawDegrees:
                            esp32.connected && esp32.imuValid ? esp32.heading : null,
                        pitchDegrees:
                            esp32.connected && esp32.imuValid ? esp32.pitch : null,
                        rollDegrees:
                            esp32.connected && esp32.imuValid ? esp32.roll : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }


}

class _AiStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _AiStat({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 15, color: Colors.black54),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppStyles.cardSubtitle),
      ],
    );
  }
}
