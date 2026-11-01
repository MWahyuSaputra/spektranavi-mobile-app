import 'build_profile.dart';

/// Konfigurasi koneksi ke MQTT Broker — dipakai bersama oleh
/// Raspberry Pi (Vision AI deteksi bola) dan ESP32 (sensor IMU/GPS/ECG),
/// karena keduanya lapor ke broker MQTT yang sama, cuma beda topic
/// prefix ("goalball/..." untuk Pi,
/// "spektra/v1/device/esp32/..." untuk ESP32).
///
/// Host/port broker sekarang diisi dari aplikasi melalui
/// Profile > Integrasi Perangkat dan disimpan di perangkat, jadi tidak perlu
/// lagi `--dart-define` setiap kali `flutter run`.
///
/// `MQTT_BROKER_IP` masih bisa dipakai sebagai nilai awal opsional untuk
/// build yang memang ingin langsung terisi.
class AppConfig {
  static const String mqttBrokerIp = String.fromEnvironment(
    'MQTT_BROKER_IP',
    defaultValue: '',
  );

  static const int mqttBrokerPort = 1883;

  static const bool esp32Diagnostic =
      String.fromEnvironment('ESP32_DIAGNOSTIC', defaultValue: 'false') ==
      'true';

  static const bool useSampleData = BuildProfile.sampleData;
  static const bool visionMock = bool.fromEnvironment(
    'MQTT_VISION_MOCK',
    defaultValue: useSampleData,
  );
  static const bool esp32Mock = bool.fromEnvironment(
    'ESP32_MOCK',
    defaultValue: useSampleData,
  );

  static const double sampleLatitude = -6.933200;
  static const double sampleLongitude = 110.420300;
}
