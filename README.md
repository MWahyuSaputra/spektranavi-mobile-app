# Spektra Navi

Aplikasi pelatih goalball berbasis Flutter. Kedua paket menggunakan halaman,
komponen, kontrol manual dan dependensi dari aplikasi real yang dilampirkan.

## Menjalankan

Gunakan Flutter yang memenuhi `pubspec.lock` (Flutter 3.38.4 atau lebih baru,
Dart 3.10.3 atau lebih baru). Dari folder `spektranavi`:

```sh
flutter pub get
flutter run
```

Untuk membuat APK:

```sh
flutter build apk --release
```

Login dan pengaturan akun mengikuti Firebase pada aplikasi asal. Konfigurasi
Firebase, identitas aplikasi, aset, dan panduan suara tetap mengikuti proyek asal.
Tidak ada perubahan package ID; pemasangan kedua paket pada perangkat yang sama
menggantikan aplikasi dengan package ID yang sama.

## Sumber data

`lib/app/build_profile.dart` adalah satu-satunya berkas yang berbeda antarpaket:

- `sampleData = false`: data contoh tidak aktif. Telemetri berasal dari perangkat;
  metrik yang belum tersedia menampilkan `--`. Atlet dan riwayat memakai Firestore.
- `sampleData = true`: telemetri bergerak otomatis tanpa ESP32/Raspberry Pi fisik.
  Atlet dan riwayat contoh disimpan di memori dan tidak ditulis ke Firestore.

Sumber Vision AI dan ESP32 menggunakan layanan bersama agar status konsisten
antarlaman. Nilai BPM tidak dihitung secara fiktif dari ECG mentah pada sumber
perangkat. Data contoh aktif hanya melalui pengaturan sumber di atas. Tidak ada
kartu satelit, panel peringatan, atau halaman tambahan di luar basis aplikasi asal.
Indikator satelit pada GNSS yang sudah ada dipertahankan.

Konfigurasi broker mengikuti aplikasi asal:

```sh
flutter run --dart-define=MQTT_BROKER_IP=192.168.1.17
```

Pengaturan `ESP32_MOCK` dan `MQTT_VISION_MOCK` yang sudah ada tetap tersedia sebagai
override saat build. Jalankan tanpa override untuk memakai profil bawaan paket.

## Map pada Mode Lari

Tekan ikon target abu-abu di kanan kartu GNSS untuk menampilkan atau menyembunyikan
kartu MAP LAPANGAN tepat di bawahnya. Denah menampilkan titik posisi atlet tanpa
teks ukuran lapangan. Map tidak muncul pada Mode Tanding atau Mode Simulasi.

Map adalah denah posisi relatif, bukan peta jalan atau citra satelit. Pada sumber
perangkat, koordinat GPS valid pertama dalam sesi menjadi titik tengah acuan yang
tetap; bagian atas denah mengarah ke utara. Mulai sesi di tengah lapangan untuk
menyelaraskan acuan. Batas lapangan belum dikalibrasi berdasarkan koordinat sudut
lapangan. Pada sumber contoh, lintasan dan acuan menggunakan koordinat yang sama.

Saat GPS tidak valid atau perangkat terputus, titik disembunyikan dan kartu
menampilkan status menunggu. Posisi di luar batas tidak dipaksa masuk ke lapangan.

## Pemeriksaan

- Seluruh file Dart lolos pemeriksaan sintaks dengan parser Dart.
- Referensi import lokal, konsistensi dua paket, isi dan nama seluruh file ZIP
  diperiksa; istilah yang diminta untuk dihapus tidak ditemukan.
- Cache build, konfigurasi path komputer asal, dan hasil kompilasi lama tidak
  disertakan. Semua artefak build harus dibuat ulang dari sumber yang diperbarui.
- Pengujian Flutter disertakan untuk tombol map, perpindahan titik, GPS tidak
  valid/terputus, pemisahan sumber data, dan penyimpanan contoh tanpa Firebase.

```sh
flutter analyze
flutter test
```

Build APK, analisis tipe Flutter, pengujian widget, dan pemeriksaan visual pada
perangkat belum dijalankan di lingkungan pengerjaan ini. Flutter SDK tidak
tersedia; percobaan menjalankan compiler Dart gagal pada inisialisasi thread
runtime. Pemeriksaan sintaks tidak menggantikan build dan pengujian tersebut.
