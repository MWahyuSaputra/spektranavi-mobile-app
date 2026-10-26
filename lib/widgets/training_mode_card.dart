import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../app/app_styles.dart';

class TrainingModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool selected;

  const TrainingModeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppStyles.cardRadius,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppStyles.cardRadius,
          border: Border.all(
            color: selected ? AppColors.green : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.greenSoft
                    : const Color(0xFFF0F0F3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 21,
                color: selected ? AppColors.green : AppColors.textDark,
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppStyles.cardTitle),
                  const SizedBox(height: 3),
                  Text(subtitle, style: AppStyles.cardSubtitle),
                ],
              ),
            ),

            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              size: 22,
              color: selected ? AppColors.green : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }
}