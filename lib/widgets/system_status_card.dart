import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../app/app_styles.dart';

/// Kartu status satu device di Home. `online` menentukan warna &
/// teks status — TIDAK ada lagi status hijau/"Terhubung" statis
/// untuk device yang belum benar-benar terhubung.
class SystemStatusCard extends StatelessWidget {
  final String title;
  final bool online;
  final String latency;
  final String battery;

  const SystemStatusCard({
    super.key,
    required this.title,
    required this.online,
    this.latency = "--",
    this.battery = "-",
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = online ? const Color(0xFF1E8C73) : const Color(0xFFB0B0B8);
    final statusColor = online ? const Color(0xFF2D9A78) : const Color(0xFF8A8A93);
    final statusText = online ? "Terhubung" : "Tidak terhubung";

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F3),
        borderRadius: AppStyles.cardRadius,
        border: Border.all(color: AppColors.border, width: 0.7),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 5, backgroundColor: dotColor),
          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppStyles.cardTitle),
                const SizedBox(height: 2),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          Icon(
            online ? Icons.check_circle_outline : Icons.error_outline,
            size: 15,
            color: online ? Colors.black : Colors.black38,
          ),
          const SizedBox(width: 4),
          const Icon(Icons.timer_outlined, size: 15),
          const SizedBox(width: 3),
          Text(online ? latency : "--", style: AppStyles.cardSubtitle),

          if (battery != "-") ...[
            const SizedBox(width: 6),
            const Icon(Icons.battery_std, size: 15),
            const SizedBox(width: 3),
            Text(online ? battery : "--", style: AppStyles.cardSubtitle),
          ],
        ],
      ),
    );
  }
}