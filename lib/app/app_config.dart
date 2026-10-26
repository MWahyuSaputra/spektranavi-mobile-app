import 'build_profile.dart';

/// Konfigurasi koneksi ke MQTT Broker — dipakai bersama oleh
/// Raspberry Pi (Vision AI deteksi bola) dan ESP32 (sensor IMU/GPS/ECG),
/// karena keduanya lapor ke broker MQTT yang sama, cuma beda topic
/// prefix ("goalball/..." untuk Pi, "spektra/v1/device/esp32/..."
/// untuk ESP32).
///
/// Cara ganti IP broker tanpa mengubah kode:
///   flutter run -d <device_id> --dart-define=MQTT_BROKER_IP=192.168.1.17
class AppConfig {
  static const String _defaultMqttBrokerIp = '192.168.1.17';

  static const String mqttBrokerIp = String.fromEnvironment(
    'MQTT_BROKER_IP',
    defaultValue: _defaultMqttBrokerIp,
  );

  static const int mqttBrokerPort = 1883;

  static const bool esp32Diagnostic = String.fromEnvironment(
    'ESP32_DIAGNOSTIC',
    defaultValue: 'false',
  ) == 'true';

  static const bool useSampleData = BuildProfile.sampleData;
  static const bool visionMock = bool.fromEnvironment(
    'MQTT_VISION_MOCK', defaultValue: useSampleData,
  );
  static const bool esp32Mock = bool.fromEnvironment(
    'ESP32_MOCK', defaultValue: useSampleData,
  );

  static const double sampleLatitude = -6.933200;
  static const double sampleLongitude = 110.420300;
}
