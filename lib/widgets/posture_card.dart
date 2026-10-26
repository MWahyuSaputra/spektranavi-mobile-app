import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../app/app_styles.dart';

class PostureCard extends StatelessWidget {
  final String statusText;
  final Color statusColor;
  final Color dotColor;
  final String yaw;
  final String pitch;
  final String roll;

  // Nilai numerik asli (opsional) — dipakai supaya titik biru & panah
  // arah beneran bergerak mengikuti data IMU asli, bukan diam di
  // tengah. Kalau null (data belum tersedia), indikator tetap di
  // tengah dalam warna abu-abu netral.
  final double? pitchValue;
  final double? rollValue;
  final double? yawValue;

  // Alias nama parameter (kompatibilitas dengan versi lain yang
  // memanggil pakai nama ini) — isinya sama persis, cuma nama beda.
  final double? pitchDegrees;
  final double? rollDegrees;
  final double? yawDegrees;

  const PostureCard({
    super.key,
    required this.statusText,
    required this.statusColor,
    required this.dotColor,
    required this.yaw,
    required this.pitch,
    required this.roll,
    this.pitchValue,
    this.rollValue,
    this.yawValue,
    this.pitchDegrees,
    this.rollDegrees,
    this.yawDegrees,
  });

  double? get _effectivePitch => pitchDegrees ?? pitchValue;
  double? get _effectiveRoll => rollDegrees ?? rollValue;
  double? get _effectiveYaw => yawDegrees ?? yawValue;

  @override
  Widget build(BuildContext context) {
    final hasData = _effectivePitch != null && _effectiveRoll != null;

    // Batas visual kemiringan yang dipetakan ke tepi lingkaran dalam.
    // Di luar ±20°, titik akan menempel di tepi (clamp), bukan keluar.
    const maxTiltDeg = 20.0;
    const maxOffsetPx = 30.0;

    final dx = hasData
        ? (_effectiveRoll!.clamp(-maxTiltDeg, maxTiltDeg) / maxTiltDeg) * maxOffsetPx
        : 0.0;
    // Pitch positif (mendongak) digambar titik bergerak ke atas.
    final dy = hasData
        ? -(_effectivePitch!.clamp(-maxTiltDeg, maxTiltDeg) / maxTiltDeg) * maxOffsetPx
        : 0.0;

    final activeDotColor = hasData ? dotColor : Colors.black26;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppStyles.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("POSTURE (IMU)", style: AppStyles.sectionLabelDark),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            height: 110,
            child: Center(
              child: SizedBox(
                width: 92,
                height: 92,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black26, width: 1),
                      ),
                    ),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black26, width: 1),
                      ),
                    ),

                    // Penanda arah (yaw) — garis kecil di tepi lingkaran
                    // luar yang berputar mengikuti orientasi wearable.
                    if (_effectiveYaw != null)
                      Transform.rotate(
                        angle: (_effectiveYaw! * math.pi / 180),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 3,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),

                    // Titik biru — bergerak sesuai pitch (naik/turun)
                    // dan roll (kiri/kanan) asli dari IMU.
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      transform: Matrix4.translationValues(dx, dy, 0),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: activeDotColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Row(
            children: [
              Expanded(child: _axis("YAW", yaw)),
              Expanded(child: _axis("PITCH", pitch)),
              Expanded(child: _axis("ROLL", roll)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _axis(String label, String value) {
    return Column(
      children: [
        Text(label, style: AppStyles.cardSubtitle),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}