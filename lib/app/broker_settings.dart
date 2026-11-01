import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_config.dart';

/// Alamat broker MQTT yang sedang dipakai aplikasi.
class BrokerConfig {
  final String host;
  final int port;

  const BrokerConfig({required this.host, required this.port});

  bool get isConfigured => host.isNotEmpty;

  /// Teks yang ditampilkan di UI, mis. `192.168.1.17:1883`.
  String get label => isConfigured ? '$host:$port' : 'Belum diatur';

  BrokerConfig copyWith({String? host, int? port}) {
    return BrokerConfig(host: host ?? this.host, port: port ?? this.port);
  }

  @override
  bool operator ==(Object other) =>
      other is BrokerConfig && other.host == host && other.port == port;

  @override
  int get hashCode => Object.hash(host, port);
}

/// Menyimpan host/port broker MQTT di perangkat (SharedPreferences).
///
/// Nilai ini dipakai bersama oleh `MqttService` (Raspberry Pi / Vision AI)
/// dan `Esp32Service` (wearable), karena keduanya terhubung ke broker yang
/// sama. Pengguna mengubahnya lewat Profile > Integrasi Perangkat.
class BrokerSettings {
  BrokerSettings._();

  static final BrokerSettings instance = BrokerSettings._();

  static const String _hostKey = 'mqtt_broker_host';
  static const String _portKey = 'mqtt_broker_port';

  /// Dipertahankan sebagai fallback kalau port tersimpan tidak valid.
  static const int defaultPort = AppConfig.mqttBrokerPort;

  final ValueNotifier<BrokerConfig> config = ValueNotifier(
    BrokerConfig(host: AppConfig.mqttBrokerIp, port: defaultPort),
  );

  bool _loaded = false;
  Future<void>? _loading;

  bool get isLoaded => _loaded;

  /// Muat pengaturan tersimpan. Aman dipanggil berkali-kali.
  Future<void> load() {
    if (_loaded) return Future<void>.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedHost = prefs.getString(_hostKey);
      final storedPort = prefs.getInt(_portKey);

      config.value = BrokerConfig(
        host: storedHost == null
            ? AppConfig.mqttBrokerIp
            : normalizeHost(storedHost),
        port: isValidPort(storedPort) ? storedPort! : defaultPort,
      );
    } finally {
      _loaded = true;
      _loading = null;
    }
  }

  /// Simpan host/port baru lalu beri tahu pendengar (UI dan layanan MQTT).
  Future<void> save({required String host, required int port}) async {
    final normalizedHost = normalizeHost(host);

    if (normalizedHost.isEmpty) {
      throw ArgumentError('Host broker wajib diisi');
    }
    if (!isValidPort(port)) {
      throw ArgumentError('Port broker tidak valid');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_hostKey, normalizedHost);
    await prefs.setInt(_portKey, port);

    config.value = BrokerConfig(host: normalizedHost, port: port);
    _loaded = true;
  }

  /// Kembalikan ke nilai awal build (biasanya kosong).
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hostKey);
    await prefs.remove(_portKey);

    config.value = BrokerConfig(
      host: AppConfig.mqttBrokerIp,
      port: defaultPort,
    );
    _loaded = true;
  }

  static bool isValidPort(int? port) =>
      port != null && port >= 1 && port <= 65535;

  /// Rapikan input pengguna: buang spasi, skema (`mqtt://`), dan path.
  static String normalizeHost(String raw) {
    var value = raw.trim();

    value = value.replaceFirst(RegExp(r'^[a-zA-Z][a-zA-Z0-9+.\-]*://'), '');
    value = value.split('/').first.trim();

    return value;
  }

  /// Ambil host dan port dari input host.
  ///
  /// Mendukung `192.168.1.17`, `broker.local`, `mqtt://192.168.1.17:1883`,
  /// maupun `192.168.1.17:1883`. Kalau host tidak memuat port, [fallbackPort]
  /// yang dipakai.
  static BrokerConfig parseHost(String raw, {int fallbackPort = defaultPort}) {
    var value = raw.trim();

    value = value.replaceFirst(RegExp(r'^[a-zA-Z][a-zA-Z0-9+.\-]*://'), '');
    value = value.split('/').first.trim();

    var port = fallbackPort;
    final hostPort = RegExp(r'^([^:]+):(\d+)$').firstMatch(value);

    if (hostPort != null) {
      value = hostPort.group(1)!.trim();
      port = int.tryParse(hostPort.group(2)!) ?? fallbackPort;
    }

    return BrokerConfig(
      host: value,
      port: isValidPort(port) ? port : fallbackPort,
    );
  }
}
