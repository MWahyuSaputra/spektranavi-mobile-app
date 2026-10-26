import 'package:flutter/material.dart';
import '../app/app_styles.dart';

class ProfileActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? textColor;
  final Color? iconColor;
  final VoidCallback? onTap;

  const ProfileActionTile({
    super.key,
    required this.icon,
    required this.title,
    this.textColor,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppStyles.cardRadius,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppStyles.cardRadius,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? Colors.black54),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textColor ?? Colors.black,
              ),
            ),
            if (onTap != null) ...[
              const Spacer(),
              const Icon(Icons.chevron_right, size: 18, color: Colors.black38),
            ],
          ],
        ),
      ),
    );
  }
}