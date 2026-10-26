import 'package:flutter/material.dart';

/// Baris 3 chip status device: Vision AI (Gawang), Wearable ESP32,
/// Dashboard Pelatih. Warna tiap chip mengikuti status koneksi ASLI
/// yang dilempar dari halaman pemanggil — bukan statis hijau semua.
class StatusChipRow extends StatelessWidget {
  final bool visionOnline;
  final bool esp32Online;

  const StatusChipRow({
    super.key,
    this.visionOnline = false,
    this.esp32Online = false,
  });

  Widget _chip(String text, bool online) {
    final bg = online ? const Color(0xFF72D59B) : const Color(0xFFE3E3E8);
    final dot = online ? const Color(0xFF1C6E46) : const Color(0xFF8A8A93);
    final fg = online ? Colors.black : const Color(0xFF6B6B75);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 3, backgroundColor: dot),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip('Vision AI (Gawang)', visionOnline),
          const SizedBox(width: 8),
          _chip('Wearable ESP32', esp32Online),
          const SizedBox(width: 8),
          // Dashboard Pelatih = aplikasi ini sendiri (HP), selalu online
          // selama aplikasi jalan.
          _chip('Dashboard Pelatih', true),
        ],
      ),
    );
  }
}