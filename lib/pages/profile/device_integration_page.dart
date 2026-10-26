import 'package:flutter/material.dart';
import '../../app/app_colors.dart';
import '../../app/app_styles.dart';
import '../../app/app_config.dart';
import '../../services/device_services.dart';
import '../../services/esp32_service.dart';
import '../../services/mqtt_service.dart';

/// Status perangkat dibaca dari layanan koneksi bersama.
class DeviceIntegrationPage extends StatefulWidget {
  const DeviceIntegrationPage({super.key});

  @override
  State<DeviceIntegrationPage> createState() => _DeviceIntegrationPageState();
}

class _DeviceIntegrationPageState extends State<DeviceIntegrationPage> {
  bool _visionTesting = false;
  bool _esp32Testing = false;

  Future<void> _testVision() async {
    setState(() => _visionTesting = true);
    // Check if Pi is online via mqtt service
    final online = DeviceServices.instance.mqtt.data.value.piOnline;
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _visionTesting = false);
  }

  Future<void> _testEsp32() async {
    setState(() => _esp32Testing = true);
    final success = DeviceServices.instance.esp32.ping();
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _esp32Testing = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal terhubung ke ESP32")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Esp32TelemetryData>(
      valueListenable: DeviceServices.instance.esp32.data,
      builder: (context, esp32, _) {
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
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            "Integrasi Perangkat",
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 14),
                        child: Text(
                          "Hubungkan aplikasi ke perangkat keras yang dipakai saat latihan.",
                          style: TextStyle(color: Color(0xFFE7E7EF), fontSize: 11.5),
                        ),
                      ),

                      // ---- Broker MQTT (info) ----
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: AppStyles.cardRadius),
                        child: Row(
                          children: [
                            const Icon(Icons.dns_outlined, size: 18, color: Colors.black54),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Broker MQTT", style: AppStyles.cardTitle),
                                  const SizedBox(height: 2),
                                  Text(
                                    "${AppConfig.mqttBrokerIp}:${AppConfig.mqttBrokerPort}",
                                    style: AppStyles.cardSubtitle,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ---- Kartu Raspberry Pi (Vision AI) ----
                      _DeviceCard(
                        icon: Icons.videocam_outlined,
                        title: "Vision AI (Gawang)",
                        subtitle: "Raspberry Pi — deteksi bola",
                        online: vision.piOnline,
                        testing: _visionTesting,
                        onTest: _testVision,
                        extraRows: [
                          _kv("FPS", vision.fps?.toStringAsFixed(1) ?? "--"),
                          _kv("Latency", vision.latencyMs != null ? "${vision.latencyMs!.toStringAsFixed(1)}ms" : "--"),
                        ],
                      ),

                      // ---- Kartu ESP32 (Wearable) ----
                      _DeviceCard(
                        icon: Icons.watch_outlined,
                        title: "Wearable ESP32",
                        subtitle: "IMU, GPS, sensor ECG",
                        online: esp32.connected,
                        testing: _esp32Testing,
                        onTest: _testEsp32,
                        extraRows: [
                          _kv("IMU", esp32.imuValid ? "Aktif" : "Tidak Aktif"),
                          _kv("GPS", esp32.gpsValid ? "${esp32.satellites} satelit" : "Tidak Valid"),
                        ],
                      ),

                      // ---- Dashboard Pelatih ----
                      const _DeviceCard(
                        icon: Icons.dashboard_outlined,
                        title: "Dashboard Pelatih",
                        subtitle: "Aplikasi ini sendiri",
                        online: true,
                        testing: false,
                        onTest: null,
                        extraRows: [],
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

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text(k, style: AppStyles.cardSubtitle),
          const Spacer(),
          Text(v, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool online;
  final bool testing;
  final VoidCallback? onTest;
  final List<Widget> extraRows;

  const _DeviceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.online,
    required this.testing,
    required this.onTest,
    required this.extraRows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: AppStyles.cardRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 19, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppStyles.cardTitle),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppStyles.cardSubtitle),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: online ? const Color(0xFFDBF5E4) : const Color(0xFFF1F1F4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  online ? "Terhubung" : "Belum terhubung",
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: online ? const Color(0xFF1B8A4F) : Colors.black45,
                  ),
                ),
              ),
            ],
          ),
          if (extraRows.isNotEmpty) ...[
            const Divider(height: 20),
            ...extraRows,
          ],
          if (onTest != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: testing ? null : onTest,
                icon: testing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync, size: 16),
                label: Text(testing ? "Menghubungkan..." : "Tes Koneksi"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}