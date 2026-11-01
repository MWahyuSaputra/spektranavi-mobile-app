import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_colors.dart';
import '../../app/app_styles.dart';
import '../../app/app_config.dart';
import '../../app/broker_settings.dart';
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Gagal terhubung ke ESP32")));
    }
  }

  /// Dialog untuk mengisi atau mengubah host/port broker MQTT.
  /// Nilai disimpan di perangkat, jadi tidak perlu `--dart-define` lagi.
  Future<void> _openBrokerDialog() async {
    final saved = await showDialog<BrokerConfig>(
      context: context,
      builder: (_) =>
          _BrokerDialog(initial: BrokerSettings.instance.config.value),
    );

    if (!mounted || saved == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Broker ${saved.host}:${saved.port} disimpan"),
        backgroundColor: AppColors.green,
      ),
    );

    await DeviceServices.instance.restart();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Esp32TelemetryData>(
      valueListenable: DeviceServices.instance.esp32.data,
      builder: (context, esp32, _) {
        return ValueListenableBuilder<MqttVisionData>(
          valueListenable: DeviceServices.instance.mqtt.data,
          builder: (context, vision, _) {
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
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            "Integrasi Perangkat",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 14),
                        child: Text(
                          "Hubungkan aplikasi ke perangkat keras yang dipakai saat latihan.",
                          style: TextStyle(
                            color: Color(0xFFE7E7EF),
                            fontSize: 11.5,
                          ),
                        ),
                      ),

                      // ---- Broker MQTT (bisa diisi/diubah) ----
                      _brokerCard(),

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
                          _kv(
                            "Latency",
                            vision.latencyMs != null
                                ? "${vision.latencyMs!.toStringAsFixed(1)}ms"
                                : "--",
                          ),
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
                          _kv(
                            "GPS",
                            esp32.gpsValid
                                ? "${esp32.satellites} satelit"
                                : "Tidak Valid",
                          ),
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

  Widget _brokerCard() {
    return ValueListenableBuilder<BrokerConfig>(
      valueListenable: BrokerSettings.instance.config,
      builder: (context, broker, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: DeviceServices.instance.mqtt.connected,
          builder: (context, mqttConnected, _) {
            final connected = mqttConnected && broker.isConfigured;
            final status = AppConfig.visionMock
                ? "Mode simulasi"
                : !broker.isConfigured
                ? "Belum diatur"
                : connected
                ? "Terhubung"
                : "Belum terhubung";

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.white,
                borderRadius: AppStyles.cardRadius,
                child: InkWell(
                  onTap: _openBrokerDialog,
                  borderRadius: AppStyles.cardRadius,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F0F3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.dns_outlined,
                            size: 19,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Broker MQTT",
                                style: AppStyles.cardTitle,
                              ),
                              const SizedBox(height: 2),
                              Text(broker.label, style: AppStyles.cardSubtitle),
                              const SizedBox(height: 3),
                              Text(
                                status,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: connected
                                      ? const Color(0xFF1B8A4F)
                                      : Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          broker.isConfigured ? "Ubah" : "Atur",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
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
          Text(
            v,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Dialog terpisah agar controller teks dimiliki oleh widget dialog dan
/// dibuang saat route benar-benar selesai (bukan saat animasi tutup).
class _BrokerDialog extends StatefulWidget {
  const _BrokerDialog({required this.initial});

  final BrokerConfig initial;

  @override
  State<_BrokerDialog> createState() => _BrokerDialogState();
}

class _BrokerDialogState extends State<_BrokerDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController(text: widget.initial.host);
    _portController = TextEditingController(
      text: widget.initial.port.toString(),
    );
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final parsed = BrokerSettings.parseHost(
      _hostController.text,
      fallbackPort:
          int.tryParse(_portController.text.trim()) ??
          BrokerSettings.defaultPort,
    );

    setState(() => _saving = true);
    try {
      await BrokerSettings.instance.save(host: parsed.host, port: parsed.port);
      if (!mounted) return;
      Navigator.of(context).pop(BrokerSettings.instance.config.value);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal menyimpan broker: $e"),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.initial.isConfigured ? "Ubah Broker MQTT" : "Atur Broker MQTT",
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _hostController,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: _brokerFieldDecoration(
                label: "Host / IP Broker",
                hint: "192.168.1.17 atau broker.local",
              ),
              validator: (value) {
                final parsed = BrokerSettings.parseHost(value ?? '');
                if (parsed.host.isEmpty) {
                  return 'Host broker wajib diisi';
                }
                if (parsed.host.contains(RegExp(r'\s'))) {
                  return 'Host tidak boleh mengandung spasi';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _portController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _brokerFieldDecoration(
                label: "Port",
                hint: BrokerSettings.defaultPort.toString(),
              ),
              validator: (value) {
                final port = int.tryParse(value ?? '');
                if (!BrokerSettings.isValidPort(port)) {
                  return 'Port harus 1-65535';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            const Text(
              "Host dan port dipakai bersama oleh Vision AI "
              "(Raspberry Pi) dan Wearable ESP32. Setelah disimpan, "
              "aplikasi akan menyambung ulang ke broker baru.",
              style: TextStyle(
                fontSize: 11,
                color: Colors.black54,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text("Batal", style: TextStyle(color: Colors.black54)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text("Simpan"),
        ),
      ],
    );
  }
}

InputDecoration _brokerFieldDecoration({
  required String label,
  required String hint,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFF2F2F4),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppStyles.cardRadius,
      ),
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
                  color: online
                      ? const Color(0xFFDBF5E4)
                      : const Color(0xFFF1F1F4),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
