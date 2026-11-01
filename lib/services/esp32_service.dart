import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import '../app/field_position.dart';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../app/app_config.dart';
import '../app/broker_settings.dart';

/// Data telemetry dari ESP32.
///
/// Sesuai firmware:
/// - heading / roll / pitch = IMU BNO055
/// - latitude / longitude / satellites = GPS
/// - ecgRaw = data mentah ECG, BUKAN BPM
class Esp32TelemetryData {
  final bool connected;

  final bool imuValid;
  final double heading;
  final double roll;
  final double pitch;

  final bool gpsValid;
  final double latitude;
  final double longitude;
  final int satellites;

  final bool leadOff;
  final int? ecgRaw;

  // Nilai opsional: tidak diturunkan dari ECG mentah atau diisi pada mode perangkat.
  final int? heartRateBpm;
  final double? speedMetersPerSecond;
  final double? reactionMs;
  final List<int> heartSamples;
  final List<int> reactionSamples;

  /// Waktu terakhir Flutter menerima telemetry ESP32.
  final DateTime? lastTelemetryAt;

  const Esp32TelemetryData({
    this.connected = false,
    this.imuValid = false,
    this.heading = 0,
    this.roll = 0,
    this.pitch = 0,
    this.gpsValid = false,
    this.latitude = 0,
    this.longitude = 0,
    this.satellites = 0,
    this.leadOff = true,
    this.ecgRaw,
    this.heartRateBpm,
    this.speedMetersPerSecond,
    this.reactionMs,
    this.heartSamples = const [],
    this.reactionSamples = const [],
    this.lastTelemetryAt,
  });

  Esp32TelemetryData copyWith({
    bool? connected,
    bool? imuValid,
    double? heading,
    double? roll,
    double? pitch,
    bool? gpsValid,
    double? latitude,
    double? longitude,
    int? satellites,
    bool? leadOff,
    int? ecgRaw,
    int? heartRateBpm,
    double? speedMetersPerSecond,
    double? reactionMs,
    List<int>? heartSamples,
    List<int>? reactionSamples,
    DateTime? lastTelemetryAt,
  }) {
    return Esp32TelemetryData(
      connected: connected ?? this.connected,
      imuValid: imuValid ?? this.imuValid,
      heading: heading ?? this.heading,
      roll: roll ?? this.roll,
      pitch: pitch ?? this.pitch,
      gpsValid: gpsValid ?? this.gpsValid,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      satellites: satellites ?? this.satellites,
      leadOff: leadOff ?? this.leadOff,
      ecgRaw: ecgRaw ?? this.ecgRaw,
      heartRateBpm: heartRateBpm ?? this.heartRateBpm,
      speedMetersPerSecond: speedMetersPerSecond ?? this.speedMetersPerSecond,
      reactionMs: reactionMs ?? this.reactionMs,
      heartSamples: heartSamples ?? this.heartSamples,
      reactionSamples: reactionSamples ?? this.reactionSamples,
      lastTelemetryAt: lastTelemetryAt ?? this.lastTelemetryAt,
    );
  }
}

class Esp32Service {
  MqttServerClient? _client;

  Timer? _connectionWatchdog;
  Timer? _mockTimer;

  bool _disposed = false;

  final ValueNotifier<Esp32TelemetryData> data = ValueNotifier(
    const Esp32TelemetryData(),
  );

  /// Event MQTT terakhir, misalnya PONG.
  final ValueNotifier<String?> _lastEvent = ValueNotifier<String?>(null);

  /// Bisa dipakai oleh ValueListenableBuilder.
  ValueListenable<String?> get lastEvent => _lastEvent;

  /// Nilai event terakhir secara langsung.
  String? get lastEventValue => _lastEvent.value;

  static const String _topicTelemetry = 'spektra/v1/device/esp32/telemetry';

  static const String _topicStatus = 'spektra/v1/device/esp32/status';

  static const String _topicCommand = 'spektra/v1/device/esp32/command';

  static const String _topicEvent = 'spektra/v1/device/esp32/event';

  static const Duration _telemetryTimeout = Duration(seconds: 3);

  Future<void> connect() async {
    if (_disposed) return;

    _connectionWatchdog?.cancel();
    _mockTimer?.cancel();

    // MODE MOCK
    if (AppConfig.esp32Mock) {
      _startMockMode();
      return;
    }

    final broker = BrokerSettings.instance.config.value;

    if (broker.host.isEmpty) {
      debugPrint('[MQTT/ESP32] Broker belum diatur');
      data.value = const Esp32TelemetryData();
      return;
    }

    final clientId =
        'spektranavi_esp32_${DateTime.now().millisecondsSinceEpoch}';

    final client = MqttServerClient(broker.host, clientId);

    client.port = broker.port;
    client.keepAlivePeriod = 20;
    client.autoReconnect = true;
    client.logging(on: false);

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean();

    client.connectionMessage = connMessage;

    _client = client;

    client.onConnected = _onConnected;
    client.onDisconnected = _onDisconnected;

    try {
      await client.connect();
    } catch (e) {
      debugPrint('[MQTT/ESP32] Gagal connect: $e');

      client.disconnect();

      if (!_disposed) {
        data.value = const Esp32TelemetryData();
      }

      return;
    }

    if (client.connectionStatus?.state != MqttConnectionState.connected) {
      client.disconnect();

      data.value = const Esp32TelemetryData();

      return;
    }

    debugPrint(
      '[MQTT/ESP32] Terhubung ke '
      '${broker.host}:${broker.port}',
    );

    _subscribeTopics(client);

    client.updates?.listen(_onMessage);

    _startConnectionWatchdog();
  }

  void _onConnected() {
    if (_disposed || _client == null) return;

    debugPrint('[MQTT/ESP32] MQTT connected/reconnected');

    _subscribeTopics(_client!);

    _startConnectionWatchdog();
  }

  void _subscribeTopics(MqttServerClient client) {
    client.subscribe(_topicTelemetry, MqttQos.atMostOnce);

    client.subscribe(_topicStatus, MqttQos.atMostOnce);

    client.subscribe(_topicEvent, MqttQos.atMostOnce);
  }

  void _onDisconnected() {
    if (_disposed) return;

    debugPrint('[MQTT/ESP32] MQTT disconnected');

    data.value = const Esp32TelemetryData();
  }

  void _startConnectionWatchdog() {
    _connectionWatchdog?.cancel();

    _connectionWatchdog = Timer.periodic(const Duration(milliseconds: 500), (
      _,
    ) {
      if (_disposed) return;

      final last = data.value.lastTelemetryAt;

      if (last == null) {
        data.value = const Esp32TelemetryData();
        return;
      }

      final age = DateTime.now().difference(last);

      if (age > _telemetryTimeout && data.value.connected) {
        data.value = const Esp32TelemetryData();

        debugPrint(
          '[MQTT/ESP32] Telemetry timeout '
          '(${age.inMilliseconds} ms)',
        );
      }
    });
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> events) {
    if (_disposed || events.isEmpty) return;

    final received = events.first;

    final topic = received.topic;

    final message = received.payload as MqttPublishMessage;

    final payload = MqttPublishPayload.bytesToStringAsString(
      message.payload.message,
    );

    debugPrint(
      '[MQTT/ESP32] '
      '$topic -> $payload',
    );

    if (topic == _topicTelemetry) {
      _handleTelemetry(payload);
      return;
    }

    if (topic == _topicStatus) {
      _handleStatus(payload);
      return;
    }

    if (topic == _topicEvent) {
      _handleEvent(payload);
      return;
    }
  }

  void _handleStatus(String payload) {
    try {
      final decoded = jsonDecode(payload);

      if (decoded is! Map<String, dynamic>) {
        return;
      }

      if (decoded['schema'] != 'spektra.v1') {
        return;
      }

      if (decoded['type'] != 'status') {
        return;
      }

      final status = decoded['status']?.toString().toLowerCase();

      if (status == 'online') {
        data.value = data.value.copyWith(connected: true);
      } else if (status == 'offline') {
        data.value = const Esp32TelemetryData();
      }
    } catch (e) {
      debugPrint('[MQTT/ESP32] Status parse error: $e');
    }
  }

  void _handleTelemetry(String payload) {
    try {
      final decoded = jsonDecode(payload);

      if (decoded is! Map<String, dynamic>) {
        return;
      }

      if (decoded['schema'] != 'spektra.v1') {
        return;
      }

      if (decoded['type'] != 'telemetry') {
        return;
      }

      final dynamic rawData = decoded['data'];

      if (rawData is! Map<String, dynamic>) {
        return;
      }

      final d = rawData;

      // Opsional: firmware yang sudah memproses ECG dapat mengirim BPM
      // dan waktu reaksi lewat telemetry. Kalau tidak ada, nilai terakhir
      // dipertahankan (atau tetap null).
      final heartRateBpm = _asInt(d['heart_rate_bpm'] ?? d['heartRateBpm']);

      final reactionMs = _asDouble(d['reaction_ms'] ?? d['reactionMs']);

      // Kecepatan lari (m/s): dikirim firmware/dummy sebagai speed_mps.
      final speedRaw = _asDouble(
        d['speed_mps'] ??
            d['speedMps'] ??
            d['speed'] ??
            d['speed_meters_per_second'],
      );

      final speedMps = speedRaw != null && speedRaw.isFinite && speedRaw >= 0
          ? speedRaw
          : null;

      final headingRaw = d['heading'];
      final rollRaw = d['roll'];
      final pitchRaw = d['pitch'];

      final imuValid = headingRaw is num && rollRaw is num && pitchRaw is num;

      final gpsValid = d['gps_valid'] == true;

      final latitudeRaw = d['latitude'];
      final longitudeRaw = d['longitude'];

      final latitudeValid =
          latitudeRaw is num && latitudeRaw.isFinite && latitudeRaw.abs() <= 90;

      final longitudeValid =
          longitudeRaw is num &&
          longitudeRaw.isFinite &&
          longitudeRaw.abs() <= 180;

      final now = DateTime.now();

      data.value = Esp32TelemetryData(
        connected: true,

        imuValid: imuValid,

        heading: imuValid ? headingRaw.toDouble() : data.value.heading,

        roll: imuValid ? rollRaw.toDouble() : data.value.roll,

        pitch: imuValid ? pitchRaw.toDouble() : data.value.pitch,

        gpsValid: gpsValid && latitudeValid && longitudeValid,

        latitude: latitudeValid ? latitudeRaw.toDouble() : data.value.latitude,

        longitude: longitudeValid
            ? longitudeRaw.toDouble()
            : data.value.longitude,

        satellites: d['satellites'] is num
            ? (d['satellites'] as num).toInt()
            : 0,

        leadOff: d['lead_off'] == true,

        ecgRaw: d['ecg_raw'] is num ? (d['ecg_raw'] as num).toInt() : null,

        heartRateBpm: heartRateBpm ?? data.value.heartRateBpm,

        reactionMs: reactionMs ?? data.value.reactionMs,

        speedMetersPerSecond: speedMps ?? data.value.speedMetersPerSecond,

        heartSamples: _appendSamples(data.value.heartSamples, heartRateBpm),

        reactionSamples: _appendSamples(
          data.value.reactionSamples,
          reactionMs?.round(),
        ),

        lastTelemetryAt: now,
      );
    } catch (e) {
      debugPrint('[MQTT/ESP32] Telemetry parse error: $e');
    }
  }

  void _handleEvent(String payload) {
    try {
      final decoded = jsonDecode(payload);

      if (decoded is! Map<String, dynamic>) {
        return;
      }

      if (decoded['schema'] != 'spektra.v1') {
        return;
      }

      if (decoded['type'] != 'event') {
        return;
      }

      final event = decoded['event']?.toString();

      if (event == null || event.isEmpty) {
        return;
      }

      _lastEvent.value = event;

      debugPrint('[MQTT/ESP32] Event: $event');
    } catch (e) {
      debugPrint('[MQTT/ESP32] Event parse error: $e');
    }
  }

  /// Jumlah sample riwayat untuk grafik BPM / waktu reaksi.
  static const int _maxMetricSamples = 20;

  static int? _asInt(dynamic value) => value is num ? value.toInt() : null;

  static double? _asDouble(dynamic value) =>
      value is num ? value.toDouble() : null;

  static List<int> _appendSamples(List<int> samples, int? value) {
    if (value == null) return samples;

    final next = <int>[...samples, value];

    if (next.length > _maxMetricSamples) {
      next.removeRange(0, next.length - _maxMetricSamples);
    }

    return List<int>.unmodifiable(next);
  }

  /// Kirim command PING ke ESP32.
  ///
  /// Firmware ESP32 mengharapkan:
  /// {
  ///   "schema": "spektra.v1",
  ///   "type": "command",
  ///   "command": "PING",
  ///   "timestamp_ms": 123456789
  /// }
  bool sendPing() {
    if (_disposed) return false;

    // Untuk mode mock, langsung simulasikan balasan PONG.
    if (AppConfig.esp32Mock) {
      _lastEvent.value = 'PONG';

      debugPrint('[MOCK/ESP32] PING -> PONG');

      return true;
    }

    final client = _client;

    if (client == null) {
      return false;
    }

    if (client.connectionStatus?.state != MqttConnectionState.connected) {
      return false;
    }

    final builder = MqttClientPayloadBuilder();

    final command = {
      'schema': 'spektra.v1',
      'type': 'command',
      'command': 'PING',
      'timestamp_ms': DateTime.now().millisecondsSinceEpoch,
    };

    builder.addString(jsonEncode(command));

    client.publishMessage(_topicCommand, MqttQos.atMostOnce, builder.payload!);

    debugPrint('[MQTT/ESP32] PING sent');

    return true;
  }

  /// Alias sederhana agar diagnostic page bisa memanggil ping().
  bool ping() {
    return sendPing();
  }

  void disconnect() {
    _connectionWatchdog?.cancel();
    _connectionWatchdog = null;

    _mockTimer?.cancel();
    _mockTimer = null;

    _client?.disconnect();
    _client = null;

    if (!_disposed) {
      data.value = const Esp32TelemetryData();
    }
  }

  void _startMockMode() {
    var frame = 0;
    final heartHistory = <int>[];
    final reactionHistory = <int>[];

    void publishFrame() {
      final now = DateTime.now();
      final seconds = frame++ * 0.5;
      final east = 3 * math.sin(seconds * 0.6);
      final north = 6 * math.sin(seconds * 0.3);
      final eastSpeed = 1.8 * math.cos(seconds * 0.6);
      final northSpeed = 1.8 * math.cos(seconds * 0.3);
      final bpm = (110 + 12 * math.sin(seconds * 0.18)).round();
      final reaction = 620 + 90 * math.sin(seconds * 0.25);
      heartHistory.add(bpm);
      reactionHistory.add(reaction.round());
      if (heartHistory.length > 20) heartHistory.removeAt(0);
      if (reactionHistory.length > 20) reactionHistory.removeAt(0);

      data.value = Esp32TelemetryData(
        connected: true,
        imuValid: true,
        heading:
            (math.atan2(eastSpeed, northSpeed) * 180 / math.pi + 360) % 360,
        roll: 5 * math.sin(seconds),
        pitch: 8 * math.sin(seconds * 0.7),
        gpsValid: true,
        latitude:
            AppConfig.sampleLatitude +
            north / FieldProjection.earthRadiusMeters * 180 / math.pi,
        longitude:
            AppConfig.sampleLongitude +
            east /
                (FieldProjection.earthRadiusMeters *
                    math.cos(AppConfig.sampleLatitude * math.pi / 180)) *
                180 /
                math.pi,
        satellites: 7,
        leadOff: false,
        ecgRaw: 2048 + (200 * math.sin(seconds * 4)).round(),
        heartRateBpm: bpm,
        speedMetersPerSecond: math.sqrt(
          eastSpeed * eastSpeed + northSpeed * northSpeed,
        ),
        reactionMs: reaction,
        heartSamples: List.unmodifiable(heartHistory),
        reactionSamples: List.unmodifiable(reactionHistory),
        lastTelemetryAt: now,
      );
    }

    publishFrame();
    _mockTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }
      publishFrame();
    });
    _startConnectionWatchdog();
  }

  void dispose() {
    if (_disposed) return;

    _disposed = true;

    _connectionWatchdog?.cancel();
    _mockTimer?.cancel();

    _connectionWatchdog = null;
    _mockTimer = null;

    _client?.disconnect();
    _client = null;

    data.dispose();
    _lastEvent.dispose();
  }
}
