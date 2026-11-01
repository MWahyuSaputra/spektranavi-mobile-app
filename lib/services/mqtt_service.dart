import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../app/app_config.dart';
import '../app/broker_settings.dart';

/// Telemetry Vision AI dari Raspberry Pi.
class MqttVisionData {
  final bool piOnline;
  final bool ballDetected;
  final String trajectory;
  final double? latencyMs;
  final double? confidencePercent;
  final double? fps;

  const MqttVisionData({
    this.piOnline = false,
    this.ballDetected = false,
    this.trajectory = '--',
    this.latencyMs,
    this.confidencePercent,
    this.fps,
  });

  MqttVisionData copyWith({
    bool? piOnline,
    bool? ballDetected,
    String? trajectory,
    double? latencyMs,
    double? confidencePercent,
    double? fps,
  }) {
    return MqttVisionData(
      piOnline: piOnline ?? this.piOnline,
      ballDetected: ballDetected ?? this.ballDetected,
      trajectory: trajectory ?? this.trajectory,
      latencyMs: latencyMs ?? this.latencyMs,
      confidencePercent: confidencePercent ?? this.confidencePercent,
      fps: fps ?? this.fps,
    );
  }
}

class MqttService {
  MqttServerClient? _client;
  Timer? _mockTimer;
  bool _disposed = false;

  final ValueNotifier<MqttVisionData> data = ValueNotifier(
    const MqttVisionData(),
  );

  /// Status koneksi ke broker, dipakai halaman Integrasi Perangkat.
  final ValueNotifier<bool> connected = ValueNotifier(false);

  static const List<String> _topics = [
    'goalball/status',
    'goalball/instruksi',
    'goalball/koneksi',
    'goalball/fps',
    'goalball/latensi',
    'goalball/latency',
    'goalball/keyakinan',
    'goalball/confidence',
  ];

  /// Topik arah/aba-aba yang dikirim aplikasi (Mode Simulasi & Mode Lari).
  static const String directionTopic = 'spektra/v1/device/app/direction';

  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  /// Kirim arah bola/aba-aba pelatih ke broker.
  ///
  /// Payload JSON:
  /// {
  ///   "schema": "spektra.v1",
  ///   "type": "direction",
  ///   "mode": "simulasi" | "lari",
  ///   "direction": "KIRI" | "TENGAH" | "KANAN" | "MAJU" | "MUNDUR" | "STOP",
  ///   "source": "app",
  ///   "timestamp_ms": 123456789
  /// }
  bool publishDirection({required String mode, required String direction}) {
    if (_disposed) return false;

    final payload = jsonEncode({
      'schema': 'spektra.v1',
      'type': 'direction',
      'mode': mode,
      'direction': direction,
      'source': 'app',
      'timestamp_ms': DateTime.now().millisecondsSinceEpoch,
    });

    // Mode mock tidak memakai broker; cukup catat di log.
    if (AppConfig.visionMock) {
      debugPrint('[MOCK/MQTT] ARAH $mode -> $direction');
      return true;
    }

    final client = _client;

    if (client == null ||
        client.connectionStatus?.state != MqttConnectionState.connected) {
      debugPrint('[MQTT/App] Gagal kirim arah: broker belum terhubung');
      return false;
    }

    final builder = MqttClientPayloadBuilder()..addString(payload);

    client.publishMessage(directionTopic, MqttQos.atMostOnce, builder.payload!);

    debugPrint('[MQTT/App] ARAH $mode -> $direction');
    return true;
  }

  Future<void> connect() async {
    if (_disposed) return;

    _mockTimer?.cancel();

    if (AppConfig.visionMock) {
      _startMockMode();
      return;
    }

    final broker = BrokerSettings.instance.config.value;
    final host = broker.host;

    if (host.isEmpty) {
      debugPrint('[MQTT/Vision] Broker belum diatur');
      connected.value = false;
      data.value = const MqttVisionData();
      return;
    }

    final clientId =
        'spektranavi_vision_${DateTime.now().millisecondsSinceEpoch}';
    final client = MqttServerClient(host, clientId);
    client.port = broker.port;
    client.keepAlivePeriod = 20;
    client.autoReconnect = true;
    client.logging(on: false);

    client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean();

    _client = client;
    client.onConnected = _onConnected;
    client.onDisconnected = _onDisconnected;

    try {
      await client.connect();
    } catch (e) {
      debugPrint('[MQTT/Vision] Gagal connect ke $host:${broker.port}: $e');
      client.disconnect();
      connected.value = false;
      data.value = const MqttVisionData();
      return;
    }

    if (client.connectionStatus?.state != MqttConnectionState.connected) {
      client.disconnect();
      connected.value = false;
      data.value = const MqttVisionData();
      return;
    }

    connected.value = true;
    _subscribe(client);
    client.updates?.listen(_onMessage);

    debugPrint('[MQTT/Vision] Terhubung ke $host:${broker.port}');
  }

  void _onConnected() {
    final client = _client;
    if (_disposed || client == null) return;
    connected.value = true;
    _subscribe(client);
  }

  void _subscribe(MqttServerClient client) {
    for (final topic in _topics) {
      client.subscribe(topic, MqttQos.atMostOnce);
    }
  }

  void _onDisconnected() {
    if (_disposed) return;
    connected.value = false;
    data.value = const MqttVisionData();
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> events) {
    if (_disposed || events.isEmpty) return;

    final message = events.first.payload as MqttPublishMessage;
    final topic = events.first.topic;
    final payload = MqttPublishPayload.bytesToStringAsString(
      message.payload.message,
    ).trim();

    switch (topic) {
      case 'goalball/status':
        data.value = data.value.copyWith(ballDetected: payload == 'TERDETEKSI');
        break;
      case 'goalball/instruksi':
        data.value = data.value.copyWith(
          trajectory: payload == 'TIDAK_TERDETEKSI' ? '--' : payload,
        );
        break;
      case 'goalball/koneksi':
        data.value = data.value.copyWith(piOnline: payload == 'online');
        break;
      case 'goalball/fps':
        data.value = data.value.copyWith(fps: double.tryParse(payload));
        break;
      case 'goalball/latensi':
      case 'goalball/latency':
        data.value = data.value.copyWith(latencyMs: double.tryParse(payload));
        break;
      case 'goalball/keyakinan':
      case 'goalball/confidence':
        final raw = double.tryParse(payload);
        data.value = data.value.copyWith(
          confidencePercent: raw == null ? null : raw * 100,
        );
        break;
    }
  }

  void _startMockMode() {
    const directions = ['KIRI', 'TENGAH', 'KANAN'];
    final random = Random();
    var tick = 0;

    data.value = const MqttVisionData(
      piOnline: true,
      ballDetected: true,
      trajectory: 'TENGAH',
      latencyMs: 41.3,
      confidencePercent: 92.5,
      fps: 24.7,
    );

    _mockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }

      tick++;
      final detected = tick % 5 != 0;

      data.value = MqttVisionData(
        piOnline: true,
        ballDetected: detected,
        trajectory: detected ? directions[tick % directions.length] : '--',
        latencyMs: 35 + random.nextDouble() * 20,
        confidencePercent: detected ? 84 + random.nextDouble() * 14 : 0,
        fps: 20 + random.nextDouble() * 7,
      );
    });
  }

  void disconnect() {
    _mockTimer?.cancel();
    _mockTimer = null;
    _client?.disconnect();
    _client = null;

    if (!_disposed) {
      connected.value = false;
      data.value = const MqttVisionData();
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _mockTimer?.cancel();
    _client?.disconnect();
    _client = null;
    data.dispose();
    connected.dispose();
  }
}
