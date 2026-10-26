import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../app/app_styles.dart';

class ProfileAthleteTile extends StatelessWidget {
  final String initial;
  final String name;
  final String id;

  const ProfileAthleteTile({
    super.key,
    required this.initial,
    required this.name,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppStyles.cardTitle),
              const SizedBox(height: 2),
              Text(id, style: AppStyles.cardSubtitle),
            ],
          ),
        ],
      ),
    );
  }
}