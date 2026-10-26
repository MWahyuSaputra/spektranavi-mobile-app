import 'package:flutter/material.dart';
import '../app/app_styles.dart';

class AnalyticsSessionCard extends StatelessWidget {
  final IconData icon;
  final String mode;
  final String athlete;
  final String date;
  final String duration;
  final String leftValue;
  final String leftSub;
  final String midValue;
  final String midSub;
  final String rightValue;
  final String rightSub;

  const AnalyticsSessionCard({
    super.key,
    required this.icon,
    required this.mode,
    required this.athlete,
    required this.date,
    required this.duration,
    required this.leftValue,
    required this.leftSub,
    required this.midValue,
    required this.midSub,
    required this.rightValue,
    required this.rightSub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppStyles.cardRadius,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F3),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black26, width: 0.7),
                ),
                child: Icon(icon, size: 20),
              ),
              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mode, style: AppStyles.cardTitle),
                    const SizedBox(height: 2),
                    Text(
                      "$athlete · $date",
                      style: AppStyles.cardSubtitle,
                    ),
                  ],
                ),
              ),

              Text(
                duration,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF8B8B96),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(child: _stat(icon: Icons.favorite_border, value: leftValue, sub: leftSub)),
              Expanded(child: _stat(icon: Icons.bolt_outlined, value: midValue, sub: midSub)),
              Expanded(child: _stat(icon: Icons.shield_outlined, value: rightValue, sub: rightSub)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat({
    required IconData icon,
    required String value,
    required String sub,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          sub,
          textAlign: TextAlign.center,
          style: AppStyles.cardSubtitle,
        ),
      ],
    );
  }
}