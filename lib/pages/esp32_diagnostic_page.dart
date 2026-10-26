import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../app/app_config.dart';
import '../services/esp32_service.dart';

class Esp32DiagnosticPage extends StatefulWidget {
  const Esp32DiagnosticPage({super.key});

  @override
  State<Esp32DiagnosticPage> createState() => _Esp32DiagnosticPageState();
}

class _Esp32DiagnosticPageState extends State<Esp32DiagnosticPage> {
  late final Esp32Service _service;
  bool _connecting = false;

  @override
  void initState() {
    super.initState();
    _service = Esp32Service();
    _connect();
  }

  Future<void> _connect() async {
    if (_connecting) return;
    setState(() => _connecting = true);
    await _service.connect();
    if (mounted) setState(() => _connecting = false);
  }

  @override
  void dispose() {
    _service.disconnect();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('ESP32 Diagnostic'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder<Esp32TelemetryData>(
        valueListenable: _service.data,
        builder: (context, d, _) {
          final last = d.lastTelemetryAt;
          final age = last == null
              ? '--'
              : '${DateTime.now().difference(last).inMilliseconds} ms';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _statusCard(d, age),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _connecting ? null : _connect,
                      icon: const Icon(Icons.wifi),
                      label: Text(_connecting ? 'CONNECTING...' : 'CONNECT'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final ok = _service.ping();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(ok ? 'PING sent' : 'PING failed')),
                        );
                      },
                      icon: const Icon(Icons.sync),
                      label: const Text('PING'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _section('IMU', [
                _row('Valid', d.imuValid.toString()),
                _row('Heading', d.imuValid ? '${d.heading.toStringAsFixed(1)}°' : '--'),
                _row('Roll', d.imuValid ? '${d.roll.toStringAsFixed(1)}°' : '--'),
                _row('Pitch', d.imuValid ? '${d.pitch.toStringAsFixed(1)}°' : '--'),
              ]),
              const SizedBox(height: 12),
              _section('GPS', [
                _row('Valid', d.gpsValid.toString()),
                _row('Latitude', d.gpsValid ? d.latitude.toStringAsFixed(6) : '--'),
                _row('Longitude', d.gpsValid ? d.longitude.toStringAsFixed(6) : '--'),
                _row('Satellites', d.gpsValid ? d.satellites.toString() : '--'),
              ]),
              const SizedBox(height: 12),
              _section('ECG', [
                _row('Lead off', d.leadOff.toString()),
                _row('ECG raw', d.ecgRaw?.toString() ?? '--'),
                _row('BPM', d.connected ? d.heartRateBpm?.toString() ?? '--' : '--'),
              ]),
              const SizedBox(height: 12),
              ValueListenableBuilder<String?>(
                valueListenable: _service.lastEvent,
                builder: (context, event, _) {
                  return _section('MQTT EVENT', [
                    _row('Last event', event ?? '--'),
                  ]);
                },
              ),
              const SizedBox(height: 12),
              _section('CONFIG', [
                _row('Broker', '${AppConfig.mqttBrokerIp}:${AppConfig.mqttBrokerPort}'),
                _row('Mock', AppConfig.esp32Mock.toString()),
                _row('Telemetry timeout', '3 s'),
              ]),
            ],
          );
        },
      ),
    );
  }

  Widget _statusCard(Esp32TelemetryData d, String age) {
    final color = d.connected ? Colors.greenAccent : Colors.redAccent;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.circle, size: 14, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.connected ? 'ESP32 CONNECTED' : 'ESP32 OFFLINE',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text('Last telemetry: $age'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> rows) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label)),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
