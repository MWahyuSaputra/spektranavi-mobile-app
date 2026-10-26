import '../../app/app_config.dart';
import '../../services/mqtt_service.dart';
import 'package:flutter/material.dart';
import '../../app/app_colors.dart';
import '../../app/app_styles.dart';
import '../../app/athlete_store.dart';
import '../../app/session_store.dart';
import '../../services/device_services.dart';
import '../../services/esp32_service.dart';
import '../../widgets/athlete_list_tile_simple.dart';
import '../../widgets/page_shell.dart';
import '../../widgets/session_card.dart';
import '../../widgets/system_status_card.dart';
import '../training/training_page.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? onStartTraining;
  const HomePage({super.key, this.onStartTraining});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    AthleteStore.instance.addListener(_onChanged);
    SessionStore.instance.addListener(_onChanged);
  }

  @override
  void dispose() {
    AthleteStore.instance.removeListener(_onChanged);
    SessionStore.instance.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final athletes = AthleteStore.instance.athletes;

    return PageShell(
      title: "Welcome",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppStyles.bigRadius,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("STATUS SISTEM", style: AppStyles.sectionLabelDark),
                const SizedBox(height: 8),
                ValueListenableBuilder<Esp32TelemetryData>(
                  valueListenable: DeviceServices.instance.esp32.data,
                  builder: (context, data, _) {
                    return Column(
                      children: [
                        ValueListenableBuilder<MqttVisionData>(
                          valueListenable: DeviceServices.instance.mqtt.data,
                          builder: (context, vision, _) => SystemStatusCard(
                            title: "Vision AI (Gawang)",
                            online: vision.piOnline,
                            latency: vision.piOnline && vision.latencyMs != null
                                ? "${vision.latencyMs!.toStringAsFixed(1)} ms" : "--",
                            battery: "--",
                          ),
                        ),
                        SystemStatusCard(
                          title: "Wearable ESP32",
                          online: data.connected,
                          latency: AppConfig.esp32Mock && data.connected ? "8 ms" : "--",
                          battery: AppConfig.esp32Mock && data.connected ? "75%" : "--",
                        ),
                        const SystemStatusCard(
                          title: "Dashboard Pelatih",
                          online: true,
                          latency: "3 ms",
                          battery: "-",
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          const Text("DAFTAR ATLET", style: AppStyles.sectionLabelWhite),
          const SizedBox(height: 8),

          if (athletes.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 4),
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
            ...athletes.map(
              (a) => AthleteListTileSimple(
                initial: a.initial,
                name: a.name,
                id: a.id,
              ),
            ),

          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.green,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: AppStyles.buttonRadius,
                ),
              ),
              onPressed: () {
                if (widget.onStartTraining != null) {
                  widget.onStartTraining!();
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TrainingPage()),
                  );
                }
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: const Text(
                "Mulai Latihan",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),

          const SizedBox(height: 12),
          const Text("Sesi Terakhir", style: AppStyles.sectionLabelWhite),
          const SizedBox(height: 8),

          if (SessionStore.instance.sessions.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppStyles.cardRadius,
              ),
              child: const Text(
                "Belum ada data sesi latihan.",
                style: AppStyles.cardSubtitle,
                textAlign: TextAlign.center,
              ),
            )
          else
            ...SessionStore.instance.sessions.map(
              (s) => SessionCard(
                icon: s.athlete[0],
                name: s.athlete,
                mode: s.mode,
                date: s.dateLabel,
                duration: s.durationLabel,
              ),
            ),
        ],
      ),
    );
  }
}