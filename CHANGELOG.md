# Changelog — Mobile App Spektra Navi

Rentang: kondisi pertama `git clone` → **1 November 2026**

Commit acuan:

| Kondisi | Commit |
|---|---|
| Awal clone | `4f95786` — first commit |
| Sekarang | `a6bfe50` — change by abi |

---

## Ringkasan

Perubahan utama di mobile app sejak clone:

1. Broker MQTT bisa diatur dari aplikasi (host + port), tidak lagi hardcode.
2. App sekarang bisa mengirim arah ke broker lewat topic baru `spektra/v1/device/app/direction`.
3. Mode Simulasi mendapat kontrol suara (TTS) dan panel kontrol yang disederhanakan.
4. Metrik sesi (BPM dan reaction time) dihitung realtime dari telemetry perangkat.
5. Fitur **blokade** dan **lane deviation** dihapus dari aplikasi.
6. Topic vision/Raspberry Pi dan topic ESP32 dipertahankan sama seperti clone.
7. Test baru ditambahkan untuk broker, Mode Simulasi, dan metrik sesi.

---

## 1. Konfigurasi broker MQTT dinamis

### File baru

**`lib/app/broker_settings.dart`**

- Menyimpan `host` dan `port` broker di perangkat dengan `SharedPreferences`.
- Mendukung input:
  - `192.168.1.17`
  - `broker.local`
  - `mqtt://192.168.1.17:1883`
  - `192.168.1.17:1883`
- Validasi port `1–65535`.
- Normalisasi host (membuang skema `mqtt://` dan path).
- Method: `load()`, `save()`, `reset()`, `parseHost()`.

### File yang diubah

- **`lib/app/app_config.dart`**
  - Default IP `192.168.1.17` dihapus.
  - `MQTT_BROKER_IP` tetap tersedia sebagai nilai awal opsional.
  - Default broker sekarang kosong sampai diatur pengguna.
- **`lib/main.dart`**
  - Memuat `BrokerSettings` saat aplikasi start.
- **`lib/services/mqtt_service.dart`**
  - Memakai host/port dari `BrokerSettings`.
  - Tidak mencoba connect jika host broker kosong.
- **`lib/services/esp32_service.dart`**
  - Memakai host/port dari `BrokerSettings`.
  - Tidak mencoba connect jika host broker kosong.
- **`lib/services/device_services.dart`**
  - Tambah `restart()` untuk reconnect Vision + ESP32 setelah broker diubah.
- **`lib/pages/profile/device_integration_page.dart`**
  - Kartu **Broker MQTT** sekarang bisa diketuk.
  - Dialog ubah host/port dengan validasi.
  - Status koneksi broker ditampilkan di kartu.
  - Setelah disimpan, layanan MQTT restart otomatis.
- **`lib/pages/esp32_diagnostic_page.dart`**
  - Menampilkan broker aktif dari `BrokerSettings`.
- **`pubspec.yaml`**
  - Tambah dependency `shared_preferences`.
- **`macos/Flutter/GeneratedPluginRegistrant.swift`**
  - Registrasi plugin `shared_preferences_foundation`.

---

## 2. Mobile app sebagai publisher arah (fitur baru)

### Topic baru

```
spektra/v1/device/app/direction
```

### Payload

```json
{
  "schema": "spektra.v1",
  "type": "direction",
  "mode": "simulasi",
  "direction": "KIRI",
  "source": "app",
  "timestamp_ms": 1793157044185
}
```

Detail:

- QoS `0`, tidak retain.
- `mode`: `simulasi` atau `lari`.
- `direction`:
  - Mode Simulasi: `KIRI`, `TENGAH`, `KANAN`.
  - Mode Lari: `MAJU`, `MUNDUR`, `KIRI`, `KANAN`, `STOP`.
- Jika broker belum terhubung, pengiriman gagal dan hanya dicatat di log debug.
- Jika mode mock aktif, payload tidak dikirim ke broker.

### Catatan penting

Topic ini **tidak ada di versi clone**. Di versi clone:

- App hanya menerima arah dari Raspberry Pi lewat `goalball/instruksi`.
- App hanya mengirim `PING` ke `spektra/v1/device/esp32/command`.

---

## 3. Mode Simulasi

**File:** `lib/pages/training/mode_simulasi_page.dart`

- Menambahkan suara TTS (`flutter_tts`) untuk `KIRI`, `TENGAH`, `KANAN`.
- Tombol arah menyala biru sementara saat suara diputar, lalu kembali normal.
- Menambahkan pengiriman arah ke `spektra/v1/device/app/direction`.
- Panel kontrol disederhanakan:
  - Tetap: pilihan arah bola.
  - Dihapus: kecepatan stimulus, pola, dan tingkat kesulitan.
- Menambahkan penanganan error jika suara gagal diputar.

---

## 4. Metrik sesi realtime

**File:** `lib/app/session_metrics.dart`

- Metrik dihitung dari telemetry perangkat, bukan hanya mode mock.
- Snapshot pertama saat sesi dimulai tidak dihitung.
- Sample yang dikirim ulang tidak dihitung dobel.
- Riwayat sample dibatasi 20 entri agar sample baru tetap terdeteksi.
- Metrik yang dihitung:
  - rata-rata BPM,
  - BPM tertinggi,
  - rata-rata reaction time,
  - best reaction time.

**File:** `lib/pages/training/mode_lari_page.dart` dan `lib/pages/training/mode_tanding_page.dart`

- Telemetry diproses realtime lewat listener, bukan hanya sekali per detik.
- Timer 1 detik sekarang hanya memperbarui durasi sesi.
- AVG RT di Mode Tanding ditampilkan dengan satuan `ms`.
- Memperbaiki overflow teks status ESP32 di Mode Lari (`Expanded` + ellipsis).

---

## 5. Penghapusan fitur blokade dan lane deviation

**Dihapus dari mobile app:**

- Parsing `blocks`, `attempts`, dan `lane_deviation_m` dari telemetry ESP32.
- Perhitungan blokade/lane deviation di `SessionMetrics`.
- Box **BLOKADE** di Mode Tanding.
- Box **LANE DEV** di Mode Lari.
- Kolom metrik ketiga (blokade/lane dev) di kartu Analytics.
- Field `rightValue` dan `rightSub` dari model `TrainingSession`.
- Data contoh yang memakai `Blokade`, `Akurasi`, dan `Lane dev.`.

**Catatan:** di versi clone, field tersebut hanya dipakai untuk data mock. Setelah perubahan, fitur tersebut dihapus sepenuhnya dari aplikasi.

---

## 6. Integrasi ESP32

**Topic tidak berubah dari clone:**

- `spektra/v1/device/esp32/telemetry`
- `spektra/v1/device/esp32/status`
- `spektra/v1/device/esp32/event`
- `spektra/v1/device/esp32/command`

**Perubahan perilaku:**

- Command yang dikirim tetap hanya `PING`.
- Telemetry sekarang juga membaca field opsional:
  - `heart_rate_bpm` / `heartRateBpm`
  - `reaction_ms` / `reactionMs`
  - `speed_mps` / `speedMps` / `speed` / `speed_meters_per_second`
- Menyimpan riwayat sample BPM dan reaction time untuk grafik/metrik realtime.
- Koneksi broker memakai `BrokerSettings`, bukan default IP clone.

---

## 7. Topic vision/Raspberry Pi

Topic tetap sama seperti clone:

- `goalball/status`
- `goalball/instruksi`
- `goalball/koneksi`
- `goalball/fps`
- `goalball/latensi`
- `goalball/latency`
- `goalball/keyakinan`
- `goalball/confidence`

Tidak ada perubahan nama topic pada kondisi akhir.

---

## 8. Test dan tooling

### Test baru

- **`test/broker_settings_test.dart`**
  - Parsing host, skema, dan `host:port`.
  - Simpan host/port.
  - Validasi port.
- **`test/mode_simulasi_test.dart`**
  - Tombol arah hanya biru sesaat lalu kembali.
- **`test/session_metrics_test.dart`**
  - Perhitungan BPM/RT realtime.
  - Sample duplikat tidak dihitung dobel.
  - Riwayat penuh tetap mendeteksi sample baru.

### Lainnya

- **`analysis_options.yaml`**
  - Exclude folder `build`, `android`, `ios`, `web`, `macos`, `linux` dari analyzer.
- **`README.md`**
  - Dokumentasi broker dinamis.
  - Dokumentasi topic `spektra/v1/device/app/direction`.

---

## 9. Perbandingan topic: clone vs sekarang

| Kebutuhan | Clone | Sekarang | Status |
|---|---|---|---|
| Vision / Raspberry Pi | `goalball/...` | `goalball/...` | Sama |
| ESP32 telemetry/status/event | `spektra/v1/device/esp32/...` | `spektra/v1/device/esp32/...` | Sama |
| ESP32 command | `spektra/v1/device/esp32/command` | `spektra/v1/device/esp32/command` | Sama |
| Arah dari app | Tidak ada | `spektra/v1/device/app/direction` | Baru |

---

## 10. Verifikasi

- `flutter test` → semua test lulus.
- `flutter analyze` → tidak ada error; tersisa 14 info/warning lama.
- Perubahan tersimpan dalam commit `a6bfe50` (`change by abi`).
