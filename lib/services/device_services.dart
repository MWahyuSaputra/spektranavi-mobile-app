import '../services/esp32_service.dart';
import '../services/mqtt_service.dart';

/// Satu sumber koneksi bersama ke Raspberry Pi (Vision AI) dan ESP32
/// (Wearable), dipakai oleh Home, Training, tiap Mode, dan halaman
/// Integrasi Perangkat — supaya semua bagian app baca status koneksi
/// yang SAMA, bukan bikin koneksi terpisah-pisah di tiap halaman.
///
/// Panggil `DeviceServices.instance.start()` sekali (di
/// MainNavigationPage, setelah login) — aman dipanggil berkali-kali,
/// tidak akan connect dobel.
class DeviceServices {
  DeviceServices._internal();
  static final DeviceServices instance = DeviceServices._internal();

  final MqttService mqtt = MqttService();
  final Esp32Service esp32 = Esp32Service();

  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    // Jalankan paralel supaya satu koneksi lambat tidak menahan yang lain.
    await Future.wait([
      mqtt.connect(),
      esp32.connect(),
    ]);
  }

  void dispose() {
    mqtt.disconnect();
    esp32.disconnect();
    _started = false;
  }
}