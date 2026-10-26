import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../app/app_styles.dart';

/// Grafik detak jantung bergaya garis "spike" kecil (mirip monitor BPM
/// asli) — menggantikan blok warna solid yang sebelumnya dipakai.
///
/// Skala vertikal DIBUAT LONGGAR (data + padding), bukan mentok dari nilai
/// minimum ke maksimum sampel. Ini yang membuat garisnya "naik turun tajam
/// dikit" seperti diminta — bukan grafik ekstrem yang penuh dari bawah ke
/// atas card walau datanya cuma berubah beberapa BPM.
class HeartRateSpikeChart extends StatelessWidget {
  final List<int> samples;
  final double height;

  const HeartRateSpikeChart({
    super.key,
    required this.samples,
    this.height = 78,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.greenSoft,
        borderRadius: AppStyles.cardRadius,
      ),
      child: CustomPaint(
        painter: _SpikePainter(
          samples: samples,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _SpikePainter extends CustomPainter {
  final List<int> samples;
  _SpikePainter({required this.samples});

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.length < 2) return;
    // Cuma tampilkan N titik terakhir biar grafik tidak makin rapat waktu
    // sesi berjalan lama (samples terus bertambah tiap detik saat live).
    final visible =
        samples.length > 20 ? samples.sublist(samples.length - 20) : samples;

    final minVal = visible.reduce((a, b) => a < b ? a : b).toDouble();
    final maxVal = visible.reduce((a, b) => a > b ? a : b).toDouble();

    // Bantalan di atas & bawah rentang data supaya lonjakan terlihat halus
    // ("tajam dikit"), bukan grafik yang mentok penuh tinggi card.
    final spread = (maxVal - minVal).clamp(4.0, 999.0);
    final padding = spread * 1.6;
    final rangeMin = minVal - padding;
    final rangeMax = maxVal + padding;
    final range = (rangeMax - rangeMin).clamp(1.0, double.infinity);

    final stepX =
        visible.length > 1 ? size.width / (visible.length - 1) : size.width;

    final points = <Offset>[
      for (var i = 0; i < visible.length; i++)
        Offset(
          i * stepX,
          size.height -
              (((visible[i] - rangeMin) / range).clamp(0.0, 1.0) *
                  size.height),
        ),
    ];

    // Area fill tipis di bawah garis.
    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..color = const Color(0xFF77D3A0).withOpacity(0.45)
        ..style = PaintingStyle.fill,
    );

    // Garis spike di atasnya.
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }

    canvas.drawPath(
      linePath,
      Paint()
        ..color = const Color(0xFF1B8A4F)
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SpikePainter oldDelegate) =>
      oldDelegate.samples != samples;
}