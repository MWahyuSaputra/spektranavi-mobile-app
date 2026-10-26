import '../../app/app_config.dart';
import '../../app/field_position.dart';
import '../../widgets/field_map_card.dart';
import '../../app/session_metrics.dart';
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

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

class ModeLariPage extends StatefulWidget {
  final Athlete athlete;

  const ModeLariPage({
    super.key,
    required this.athlete,
  });

  @override
  State<ModeLariPage> createState() => _ModeLariPageState();
}

class _ModeLariPageState extends State<ModeLariPage> {
  final DateTime _startTime = DateTime.now();
  Duration _elapsed = Duration.zero;
  late final Timer _timer;
  final SessionMetrics _metrics = SessionMetrics();

  // Panduan suara untuk kontrol manual.
  final FlutterTts _tts = FlutterTts();
  String? _selectedDirection;
  bool _showMap = false;
  FieldProjection? _mapOrigin;

  void _captureMapOrigin() {
    final data = DeviceServices.instance.esp32.data.value;
    if (_mapOrigin != null || !data.connected || !data.gpsValid ||
        !FieldProjection.validCoordinates(data.latitude, data.longitude)) return;
    _mapOrigin = AppConfig.esp32Mock
        ? const FieldProjection(AppConfig.sampleLatitude, AppConfig.sampleLongitude)
        : FieldProjection(data.latitude, data.longitude);
  }

  FieldPosition? _mapPosition(Esp32TelemetryData data) {
    if (!data.connected || !data.gpsValid) return null;
    return _mapOrigin?.project(data.latitude, data.longitude);
  }

  @override
  void initState() {
    super.initState();
    _metrics.record(DeviceServices.instance.esp32.data.value);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsed = DateTime.now().difference(_startTime);
        _metrics.record(DeviceServices.instance.esp32.data.value);
      });
    });

    DeviceServices.instance.esp32.data.addListener(_captureMapOrigin);
    _captureMapOrigin();
    _setupVoice();
  }

  Future<void> _setupVoice() async {
    try {
      await _tts.setLanguage('id-ID');
      await _tts.setSpeechRate(0.42);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
    } catch (e) {
      debugPrint('[VOICE] Gagal menyiapkan TTS: $e');
    }
  }

  Future<void> _speakDirection(String direction) async {
    final phrases = <String, String>{
      'MAJU': 'Maju',
      'MUNDUR': 'Mundur',
      'KIRI': 'Ke kiri',
      'KANAN': 'Ke kanan',
    };

    final phrase = phrases[direction];
    if (phrase == null) return;

    if (!mounted) return;

    setState(() {
      _selectedDirection = direction;
    });

    try {
      await _tts.stop();
      await _tts.speak(phrase);
    } catch (e) {
      debugPrint('[VOICE] Gagal memutar "$phrase": $e');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Suara "$phrase" tidak dapat diputar.'),
        ),
      );
    }
  }

  Future<void> _stopVoice() async {
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint('[VOICE] Gagal menghentikan suara: $e');
    }

    if (!mounted) return;
    setState(() {
      _selectedDirection = null;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    DeviceServices.instance.esp32.data.removeListener(_captureMapOrigin);

    _tts.stop();

    super.dispose();
  }

  String get _durasiLabel {
    final m = _elapsed.inMinutes.toString().padLeft(2, '0');
    final s = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  String _postureStatus(Esp32TelemetryData d) {
    if (!d.connected || !d.imuValid) return "NO DATA";

    final maxTilt = [d.pitch.abs(), d.roll.abs()].reduce(max);
    return maxTilt > 9 ? "TILTING" : "STABLE";
  }

  Color _postureColor(Esp32TelemetryData d) {
    final status = _postureStatus(d);
    if (status == "NO DATA") return Colors.black38;

    return status == "STABLE"
        ? AppColors.green
        : const Color(0xFFE8A640);
  }

  String _correction(MqttVisionData vision) {
    if (!vision.piOnline || !vision.ballDetected) return "--";

    switch (vision.trajectory) {
      case 'KIRI':
        return 'GESER KIRI';
      case 'KANAN':
        return 'GESER KANAN';
      case 'TENGAH':
        return 'LURUS';
      default:
        return '--';
    }
  }

  void _stopSesi() {
    _timer.cancel();

    final session = TrainingSession(
      mode: "Mode Lari",
      athlete: widget.athlete.name,
      date: DateTime.now(),
      duration: _elapsed,
      avgHeart: _metrics.averageHeart,
      peakHeart: _metrics.peakHeart,
      midValue: _metrics.bestReactionMs == null ? "--" : "${_metrics.bestReactionMs!.round()}ms",
      midSub: _metrics.bestReactionMs == null ? "Best reaction time belum tersedia" : "Best RT",
      rightValue: _metrics.laneDeviation == null ? "--" : "${_metrics.laneDeviation!.toStringAsFixed(2)}m",
      rightSub: _metrics.laneDeviation == null ? "Lane deviation belum tersedia" : "Lane dev.",
    );

    Navigator.pop(context, session);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Esp32TelemetryData>(
      valueListenable: DeviceServices.instance.esp32.data,
      builder: (context, esp32, _) {
        return ValueListenableBuilder<MqttVisionData>(
          valueListenable: DeviceServices.instance.mqtt.data,
          builder: (context, vision, __) {
            final postureStatus = _postureStatus(esp32);
            final postureColor = _postureColor(esp32);

            return Scaffold(
              backgroundColor: AppColors.primary,
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Mode Lari",
                        style: AppStyles.pageTitle,
                      ),
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
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(color: Colors.white),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                      _manualControlCard(),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 7,
                            color: esp32.connected
                                ? AppColors.green
                                : Colors.redAccent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            esp32.connected
                                ? "Wearable ESP32 terhubung"
                                : "Wearable ESP32 tidak terhubung",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
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
                            value: _metrics.bestReactionMs?.round().toString() ?? "--",
                            label: "BEST RT",
                          ),
                          Expanded(
                            child: _LastLiveStatBox(
                              icon: Icons.directions_run,
                              value: esp32.connected && esp32.speedMetersPerSecond != null
                                  ? "${esp32.speedMetersPerSecond!.toStringAsFixed(2)} m/s" : "--",
                              label: "SPEED",
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      HeartRateTelemetryCard(data: esp32),

                      PostureCard(
                        statusText: postureStatus,
                        statusColor: postureColor,
                        dotColor: Colors.blue,
                        yaw: esp32.connected && esp32.imuValid ? "${esp32.heading.toStringAsFixed(1)}°"
                            : "--",
                        pitch: esp32.connected && esp32.imuValid ? "${esp32.pitch.toStringAsFixed(1)}°"
                            : "--",
                        roll: esp32.connected && esp32.imuValid ? "${esp32.roll.toStringAsFixed(1)}°"
                            : "--",
                        yawDegrees:
                            esp32.connected && esp32.imuValid ? esp32.heading : null,
                        pitchDegrees:
                            esp32.connected && esp32.imuValid ? esp32.pitch : null,
                        rollDegrees:
                            esp32.connected && esp32.imuValid ? esp32.roll : null,
                      ),

                      _gpsCard(esp32),
                      if (_showMap)
                        FieldMapCard(
                          key: const ValueKey('running-field-map'),
                          position: _mapPosition(esp32),
                          athleteName: widget.athlete.name,
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

  Widget _manualControlCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppStyles.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "KONTROL MANUAL",
            style: AppStyles.sectionLabelDark,
          ),
          const SizedBox(height: 4),
          const Text(
            "Tekan arah untuk panduan suara",
            style: AppStyles.cardSubtitle,
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _directionButton(
                label: "MAJU",
                icon: Icons.arrow_upward,
                direction: "MAJU",
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _directionButton(
                label: "KIRI",
                icon: Icons.arrow_back,
                direction: "KIRI",
              ),
              const SizedBox(width: 8),
              _directionButton(
                label: "STOP",
                icon: Icons.stop,
                direction: null,
                isStop: true,
              ),
              const SizedBox(width: 8),
              _directionButton(
                label: "KANAN",
                icon: Icons.arrow_forward,
                direction: "KANAN",
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _directionButton(
                label: "MUNDUR",
                icon: Icons.arrow_downward,
                direction: "MUNDUR",
              ),
            ],
          ),

          if (_selectedDirection != null) ...[
            const SizedBox(height: 10),
            Center(
              child: Text(
                "ARAH: $_selectedDirection",
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _directionButton({
    required String label,
    required IconData icon,
    required String? direction,
    bool isStop = false,
  }) {
    final selected =
        direction != null && _selectedDirection == direction;

    return SizedBox(
      width: 88,
      height: 58,
      child: ElevatedButton(
        onPressed: () async {
          if (isStop) {
            await _stopVoice();
            return;
          }

          await _speakDirection(direction!);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: selected
              ? AppColors.primary
              : const Color(0xFFF2F2F4),
          foregroundColor:
              selected ? Colors.white : AppColors.textDark,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: selected
                  ? AppColors.primary
                  : Colors.black12,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 21),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gpsCard(Esp32TelemetryData d) {
    final valid = d.connected && d.gpsValid &&
        FieldProjection.validCoordinates(d.latitude, d.longitude);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppStyles.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "GNSS / NAVIGASI LINTASAN",
                  style: AppStyles.sectionLabelDark,
                ),
              ),
              Semantics(
                button: true,
                toggled: _showMap,
                child: IconButton(
                  key: const ValueKey('gnss-map-toggle'),
                  tooltip: _showMap ? 'Sembunyikan map' : 'Tampilkan map',
                  onPressed: () => setState(() => _showMap = !_showMap),
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  icon: const Icon(Icons.my_location_outlined, size: 16, color: Colors.black54),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    valid ? d.satellites.toString() : "--",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    "satellites",
                    style: AppStyles.cardSubtitle,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    "GPS",
                    style: AppStyles.cardSubtitle,
                  ),
                ],
              ),
              const SizedBox(width: 18),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black26),
                ),
                child: const Center(
                  child: Icon(
                    Icons.navigation_outlined,
                    size: 28,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Koordinat",
                      style: AppStyles.cardSubtitle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      valid
                          ? "${d.latitude.toStringAsFixed(6)}, "
                            "${d.longitude.toStringAsFixed(6)}"
                          : "GPS belum valid",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            "Speed",
            style: AppStyles.cardSubtitle,
          ),
          const SizedBox(height: 8),
          if (d.connected && d.speedMetersPerSecond != null)
            Text('${d.speedMetersPerSecond!.toStringAsFixed(2)} m/s',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))
          else
            _emptyLine("Kecepatan belum dikirim firmware ESP32"),
        ],
      ),
    );
  }

  Widget _visionCard(
    MqttVisionData vision,
    String correction,
  ) {
    return Container(
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
              const Text(
                "EDGE VISION AI",
                style: AppStyles.sectionLabelDark,
              ),
              const Spacer(),
              Icon(
                Icons.visibility,
                size: 16,
                color: vision.ballDetected
                    ? const Color(0xFF1B8A4F)
                    : Colors.black38,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.circle,
                size: 6,
                color: vision.piOnline
                    ? AppColors.green
                    : Colors.black26,
              ),
              const SizedBox(width: 4),
              Text(
                vision.piOnline
                    ? "Raspberry Pi online"
                    : "Raspberry Pi offline",
                style: AppStyles.cardSubtitle,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AiStat(
                  value: vision.latencyMs != null
                      ? "${vision.latencyMs!.toStringAsFixed(1)}ms"
                      : "--",
                  label: "Latency",
                ),
              ),
              Expanded(
                child: _AiStat(
                  value: vision.confidencePercent != null
                      ? "${vision.confidencePercent!.toStringAsFixed(1)}%"
                      : "--",
                  label: "Confidence",
                ),
              ),
              Expanded(
                child: _AiStat(
                  value: vision.fps != null
                      ? vision.fps!.toStringAsFixed(1)
                      : "--",
                  label: "FPS",
                ),
              ),
              Expanded(
                child: _AiStat(
                  value: vision.trajectory,
                  label: "Trajectory",
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Arah koreksi: $correction",
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }



  Widget _emptyLine(String text) {
    return SizedBox(
      width: double.infinity,
      height: 10,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black45,
          ),
        ),
      ),
    );
  }
}

class _AiStat extends StatelessWidget {
  final String value;
  final String label;

  const _AiStat({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: AppStyles.cardSubtitle,
        ),
      ],
    );
  }
}

class _LastLiveStatBox extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _LastLiveStatBox({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppStyles.statLabel,
          ),
        ],
      ),
    );
  }
}