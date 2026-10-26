import 'package:flutter/material.dart';
import '../app/app_styles.dart';

class CatalogDocCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String tag;
  final bool external;
  final VoidCallback? onTap;

  const CatalogDocCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.tag,
    this.external = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppStyles.cardRadius,
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppStyles.cardRadius,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppStyles.cardTitle,
                      ),
                    ),
                    if (external)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(Icons.open_in_new, size: 14),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(description, style: AppStyles.cardSubtitle),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F1F4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF70707A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}