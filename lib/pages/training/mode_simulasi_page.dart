import '../../services/mqtt_service.dart';
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

  // State panel kontrol simulasi — sekarang bisa dipilih-pilih pengguna.
  static const _arahOptions = ["KIRI", "TENGAH", "KANAN"];
  static const _polaOptions = ["KIRI", "TENGAH", "KANAN"];

  int _arahBolaIndex = 1; // default: TENGAH
  int _kecepatanIndex = 2; // default: level 3 dari 5
  int _polaIndex = 1; // default: TENGAH
  int _kesulitanIndex = 1; // default: level 2 dari 5

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
  }

  @override
  void dispose() {
    _timer.cancel();
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
      rightValue: _metrics.attempts == 0 ? "--" : "${_metrics.blocks}/${_metrics.attempts}",
      rightSub: _metrics.attempts == 0 ? "--" : "${(_metrics.blocks / _metrics.attempts * 100).round()}%",
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
                          selectedIndex: _arahBolaIndex,
                          onSelect: (i) => setState(() => _arahBolaIndex = i),
                        ),

                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.speed_outlined, size: 14, color: Colors.black54),
                            const SizedBox(width: 4),
                            const Text("KECEPATAN STIMULUS", style: AppStyles.sectionLabelDark),
                            const Spacer(),
                            Text("${_kecepatanIndex + 1}/5", style: AppStyles.cardSubtitle),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _selectableLevels(
                          count: 5,
                          selectedIndex: _kecepatanIndex,
                          onSelect: (i) => setState(() => _kecepatanIndex = i),
                        ),

                        const SizedBox(height: 12),
                        Row(
                          children: const [
                            Icon(Icons.rotate_right_outlined, size: 14, color: Colors.black54),
                            SizedBox(width: 4),
                            Text("POLA", style: AppStyles.sectionLabelDark),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _selectableRow(
                          labels: _polaOptions,
                          selectedIndex: _polaIndex,
                          onSelect: (i) => setState(() => _polaIndex = i),
                        ),

                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.layers_outlined, size: 14, color: Colors.black54),
                            const SizedBox(width: 4),
                            const Text("TINGKAT KESULITAN", style: AppStyles.sectionLabelDark),
                            const Spacer(),
                            Text("Lv. ${_kesulitanIndex + 1}", style: AppStyles.cardSubtitle),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _selectableLevels(
                          count: 5,
                          selectedIndex: _kesulitanIndex,
                          onSelect: (i) => setState(() => _kesulitanIndex = i),
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
    required int selectedIndex,
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

  Widget _selectableLevels({
    required int count,
    required int selectedIndex,
    required ValueChanged<int> onSelect,
  }) {
    return Row(
      children: List.generate(count, (i) {
        final isSelected = i == selectedIndex;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(i),
            child: Container(
              height: 34,
              margin: EdgeInsets.only(right: i == count - 1 ? 0 : 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : const Color(0xFFF2F2F4),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                ),
              ),
              child: Center(
                child: Text(
                  "${i + 1}",
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