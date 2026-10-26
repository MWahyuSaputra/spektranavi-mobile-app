import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppStyles {
  // Page spacing
  static const double pageHorizontal = 14;
  static const double pageTop = 10;
  static const double pageBottom = 96;

  // Radius
  static BorderRadius cardRadius = BorderRadius.circular(12);
  static BorderRadius bigRadius = BorderRadius.circular(14);
  static BorderRadius buttonRadius = BorderRadius.circular(14);

  // Titles
  static const pageTitle = TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
  );

  static const sectionLabelWhite = TextStyle(
    color: Colors.white,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
  );

  static const sectionLabelDark = TextStyle(
    color: AppColors.textSoft,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );

  static const cardTitle = TextStyle(
    color: AppColors.textDark,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    height: 1.1,
  );

  static const cardSubtitle = TextStyle(
    color: AppColors.textSoft,
    fontSize: 10.5,
    fontWeight: FontWeight.w500,
    height: 1.15,
  );

  static const statValue = TextStyle(
    color: AppColors.textDark,
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );

  static const statLabel = TextStyle(
    color: AppColors.textSoft,
    fontSize: 9.5,
    fontWeight: FontWeight.w600,
  );

  static const bigMetricGreen = TextStyle(
    color: Color(0xFF67C892),
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  static const bigMetricOrange = TextStyle(
    color: Color(0xFFF8663A),
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );
}