import 'package:flutter/material.dart';
import 'dart:math';
import '../../app/app_colors.dart';
import '../../app/app_styles.dart';
import '../../app/athlete_store.dart';
import '../../app/session_store.dart';
import '../../services/device_services.dart';
import '../../services/esp32_service.dart';
import '../../widgets/page_shell.dart';
import '../../widgets/heart_rate_chart.dart';
import '../../widgets/posture_card.dart';
import '../../widgets/telemetry_metric_cards.dart';
import '../../widgets/training_mode_card.dart';
import 'mode_lari_page.dart';
import 'mode_simulasi_page.dart';
import 'mode_tanding_page.dart';

enum TrainingMode { tanding, simulasi, lari }

class TrainingPage extends StatefulWidget {
  const TrainingPage({super.key});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage> {
  TrainingMode? _selectedMode;
  Athlete? _selectedAthlete;

  Future<void> _startSession() async {
    if (_selectedMode == null || _selectedAthlete == null) return;

    Widget page;
    switch (_selectedMode!) {
      case TrainingMode.tanding:
        page = ModeTandingPage(athlete: _selectedAthlete!);
        break;
      case TrainingMode.simulasi:
        page = ModeSimulasiPage(athlete: _selectedAthlete!);
        break;
      case TrainingMode.lari:
        page = ModeLariPage(athlete: _selectedAthlete!);
        break;
    }

    final result = await Navigator.push<TrainingSession>(
      context,
      MaterialPageRoute(builder: (_) => page),
    );

    if (!mounted) return;

    if (result != null) {
      SessionStore.instance.addSession(result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Sesi ${result.mode} selesai (${result.durationLabel}) — tersimpan di Analytics",
          ),
          backgroundColor: AppColors.green,
        ),
      );
      setState(() {
        _selectedMode = null;
        _selectedAthlete = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final athletes = AthleteStore.instance.athletes;
    final canStart = _selectedMode != null && _selectedAthlete != null;

    return ValueListenableBuilder<Esp32TelemetryData>(
      valueListenable: DeviceServices.instance.esp32.data,
      builder: (context, esp32, _) {
        return PageShell(
          title: "Training",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "PILIH METODE LATIHAN",
                style: AppStyles.sectionLabelWhite,
              ),
              const SizedBox(height: 8),

              TrainingModeCard(
                icon: Icons.shield_outlined,
                title: "Mode Tanding",
                subtitle: "Deteksi bola asli dari kamera gawang",
                selected: _selectedMode == TrainingMode.tanding,
                onTap: () => setState(() => _selectedMode = TrainingMode.tanding),
              ),

              TrainingModeCard(
                icon: Icons.volume_up_outlined,
                title: "Mode Simulasi",
                subtitle: "Latihan arah menggunakan suara buatan",
                selected: _selectedMode == TrainingMode.simulasi,
                onTap: () =>
                    setState(() => _selectedMode = TrainingMode.simulasi),
              ),

              TrainingModeCard(
                icon: Icons.directions_run,
                title: "Mode Lari",
                subtitle: "Navigasi arah mandiri di lintasan",
                selected: _selectedMode == TrainingMode.lari,
                onTap: () => setState(() => _selectedMode = TrainingMode.lari),
              ),

              const SizedBox(height: 10),
              const Text(
                "PILIH ATLET",
                style: AppStyles.sectionLabelWhite,
              ),
              const SizedBox(height: 8),

              if (athletes.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppStyles.cardRadius,
                  ),
                  child: const Text(
                    "Belum ada atlet terdaftar. Tambahkan lewat Profile → Kelola Atlet.",
                    style: AppStyles.cardSubtitle,
                  ),
                )
              else
                ...athletes.map((a) {
                  final selected = _selectedAthlete?.id == a.id;
                  return InkWell(
                    borderRadius: AppStyles.cardRadius,
                    onTap: () => setState(() => _selectedAthlete = a),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppStyles.cardRadius,
                        border: Border.all(
                          color: selected ? AppColors.green : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 15,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              a.initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(a.name, style: AppStyles.cardTitle),
                          ),
                          Icon(
                            selected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked,
                            size: 20,
                            color: selected ? AppColors.green : Colors.black26,
                          ),
                        ],
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: canStart ? _startSession : null,
                  icon: const Icon(Icons.play_arrow_rounded, size: 22),
                  label: Text(
                    canStart
                        ? "Mulai Sesi"
                        : "Pilih metode dan atlet dulu",
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.green,
                    disabledBackgroundColor: Colors.white24,
                    disabledForegroundColor: Colors.white70,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppStyles.buttonRadius,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              HeartRateTelemetryCard(data: esp32),

              ReactionTelemetryCard(data: esp32),

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
        );
      },
    );
  }


}