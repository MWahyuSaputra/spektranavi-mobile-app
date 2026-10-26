import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../app/app_styles.dart';

class AthleteListTileSimple extends StatelessWidget {
  final String initial;
  final String name;
  final String id;
  final VoidCallback? onTap;

  const AthleteListTileSimple({
    super.key,
    required this.initial,
    required this.name,
    required this.id,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppStyles.cardRadius,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppStyles.cardRadius,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppStyles.cardTitle),
                  const SizedBox(height: 2),
                  Text(id, style: AppStyles.cardSubtitle),
                ],
              ),
            ),

            const Icon(Icons.chevron_right, size: 20, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}