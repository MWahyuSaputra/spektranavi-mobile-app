import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../app/app_styles.dart';

class SessionCard extends StatelessWidget {
  final String icon;
  final String name;
  final String mode;
  final String date;
  final String duration;

  const SessionCard({
    super.key,
    required this.icon,
    required this.name,
    required this.mode,
    required this.date,
    required this.duration,
  });

  IconData _iconFromMode(String mode) {
    if (mode.toLowerCase().contains('tanding')) return Icons.shield_outlined;
    if (mode.toLowerCase().contains('simulasi')) return Icons.volume_up_outlined;
    return Icons.directions_run;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppStyles.cardRadius,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_iconFromMode(mode), size: 20),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppStyles.cardTitle),
                const SizedBox(height: 2),
                Text(
                  "$date · $mode",
                  style: AppStyles.cardSubtitle,
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(duration, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined, size: 11, color: AppColors.textSoft),
                  SizedBox(width: 2),
                  Text("durasi", style: TextStyle(fontSize: 9.5, color: AppColors.textSoft)),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }
}