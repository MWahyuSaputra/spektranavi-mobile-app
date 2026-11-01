import '../../services/mqtt_service.dart';
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
import '../../widgets/posture_card.dart';
import '../../widgets/status_chip_row.dart';
import '../../widgets/telemetry_metric_cards.dart';

class ModeSimulasiPage extends StatefulWidget {
  final Athlete athlete;
  const ModeSimulasiPage({super.key, required this.athlete});

  @override
  State<ModeSimulasiPage> createState() => _ModeSimulasiPageState();
}

class _ModeSimulasiPageState extends State<ModeSimulasiPage> {
  final DateTime _startTime = DateTime.now();
  Duration _elapsed = Duration.zero;
  late final Timer _timer;
  final SessionMetrics _metrics = SessionMetrics();

  // Panel kontrol simulasi — pelatih memilih arah bola.
  static const _arahOptions = ["KIRI", "TENGAH", "KANAN"];

  static const _phrases = <String, String>{
    'KIRI': 'Ke kiri',
    'TENGAH': 'Tengah',
    'KANAN': 'Ke kanan',
  };

  /// Tombol hanya biru sesaat: selama suara diputar, dengan batas aman
  /// beberapa detik kalau TTS tidak selesai.
  static const Duration _minHighlight = Duration(milliseconds: 450);
  static const Duration _highlightTimeout = Duration(seconds: 3);

  final FlutterTts _tts = FlutterTts();
  late final Future<void> _voiceReady;

  Timer? _highlightTimer;
  int? _activeArahIndex;
  int _speechId = 0;

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

  Future<void> _selectArah(int index) async {
    final direction = _arahOptions[index];
    final phrase = _phrases[direction];
    final speechId = ++_speechId;

    _highlightTimer?.cancel();

    setState(() {
      _activeArahIndex = index;
    });

    // Kirim arah ke broker supaya perangkat/penerima lain bisa membacanya.
    DeviceServices.instance.mqtt.publishDirection(
      mode: 'simulasi',
      direction: direction,
    );

    // Batas aman: warna kembali walau suara gagal/tidak selesai.
    _highlightTimer = Timer(_highlightTimeout, () {
      if (!mounted || speechId != _speechId) return;
      setState(() => _activeArahIndex = null);
    });

    if (phrase == null) return;

    final startedAt = DateTime.now();

    try {
      await _voiceReady;
      await _tts.stop();

      if (!mounted || speechId != _speechId) return;

      await _tts.speak(phrase);
    } catch (e) {
      debugPrint('[VOICE] Gagal memutar "$phrase": $e');

      if (!mounted || speechId != _speechId) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Suara "$phrase" tidak dapat diputar.'),
        ),
      );
    }

    if (!mounted || speechId != _speechId) return;

    // Pastikan tombol tetap terlihat biru sebentar, tidak sekadar berkedip.
    final elapsed = DateTime.now().difference(startedAt);
    if (elapsed < _minHighlight) {
      await Future.delayed(_minHighlight - elapsed);
    }

    if (!mounted || speechId != _speechId) return;

    _highlightTimer?.cancel();
    setState(() => _activeArahIndex = null);
  }

  @override
  void initState() {
    super.initState();
    _voiceReady = _setupVoice();
    _metrics.record(DeviceServices.instance.esp32.data.value);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsed = DateTime.now().difference(_startTime);
        _metrics.record(DeviceServices.instance.esp32.data.value);
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _highlightTimer?.cancel();
    _tts.stop();
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
      mode: "Mode Simulasi",
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
        return Scaffold(
          backgroundColor: AppColors.primary,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Mode Simulasi", style: AppStyles.pageTitle),
                  const SizedBox(height: 10),

                  ValueListenableBuilder<MqttVisionData>(
                    valueListenable: DeviceServices.instance.mqtt.data,
                    builder: (context, vision, _) => StatusChipRow(
                      visionOnline: vision.piOnline,
                      esp32Online: esp32.connected,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          _durasiLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          "DURASI SESI",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          height: 36,
                          child: ElevatedButton.icon(
                            onPressed: _stopSesi,
                            icon: const Icon(Icons.stop_outlined, size: 16),
                            label: const Text(
                              "Stop Sesi",
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

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
                          children: const [
                            Text("PANEL KONTROL SIMULASI", style: AppStyles.sectionLabelDark),
                            Spacer(),
                            Icon(Icons.volume_up_outlined, size: 18),
                          ],
                        ),
                        const SizedBox(height: 12),

                        _simLabel("ARAH BOLA"),
                        const SizedBox(height: 6),
                        _selectableRow(
                          labels: _arahOptions,
                          selectedIndex: _activeArahIndex,
                          onSelect: _selectArah,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  HeartRateTelemetryCard(data: esp32),

                  ReactionTelemetryCard(data: esp32, bestReactionMs: _metrics.bestReactionMs),

                  PostureCard(
                    statusText: esp32.connected && esp32.imuValid
                        ? ( [esp32.pitch.abs(), esp32.roll.abs()].reduce(max) > 9 ? "TILTING" : "STABLE")
                        : "NO DATA",
                    statusColor: esp32.connected && esp32.imuValid
                        ? ( [esp32.pitch.abs(), esp32.roll.abs()].reduce(max) > 9 ? const Color(0xFFE8A640) : AppColors.green)
                        : Colors.black38,
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _simLabel(String text) {
    return Text(text, style: AppStyles.sectionLabelDark);
  }

  Widget _selectableRow({
    required List<String> labels,
    required int? selectedIndex,
    required ValueChanged<int> onSelect,
  }) {
    return Row(
      children: List.generate(labels.length, (i) {
        final isSelected = i == selectedIndex;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(i),
            child: Container(
              height: 34,
              margin: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : const Color(0xFFF2F2F4),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                ),
              ),
              child: Center(
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }


}