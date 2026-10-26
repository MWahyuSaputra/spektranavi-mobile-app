import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../app/app_styles.dart';
import '../app/field_position.dart';

class FieldMapCard extends StatelessWidget {
  final FieldPosition? position;
  final String athleteName;

  const FieldMapCard({
    super.key,
    required this.position,
    required this.athleteName,
  });

  @override
  Widget build(BuildContext context) {
    final visiblePosition = position?.isInside == true ? position : null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppStyles.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MAP LAPANGAN', style: AppStyles.sectionLabelDark),
          const SizedBox(height: 12),
          Center(
            child: SizedBox(
              height: 280,
              child: AspectRatio(
                aspectRatio: FieldProjection.widthMeters / FieldProjection.lengthMeters,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const CustomPaint(painter: _FieldPainter()),
                    if (visiblePosition != null)
                      LayoutBuilder(
                        builder: (context, constraints) => Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: visiblePosition.x * constraints.maxWidth - 8,
                              top: visiblePosition.y * constraints.maxHeight - 8,
                              child: Semantics(
                                label: 'Posisi atlet $athleteName',
                                child: Container(
                                  key: const ValueKey('athlete-map-marker'),
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary,
                                    border: Border.all(color: Colors.white, width: 3),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black26, blurRadius: 5),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            position == null
                ? 'Menunggu posisi atlet'
                : visiblePosition == null
                    ? 'Posisi atlet di luar area lapangan'
                    : 'Posisi atlet · $athleteName',
            style: AppStyles.cardSubtitle,
          ),
        ],
      ),
    );
  }
}

class _FieldPainter extends CustomPainter {
  const _FieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final field = Offset.zero & size;
    canvas.drawRect(field, Paint()..color = const Color(0xFFE7F3EA));
    final lines = Paint()
      ..color = const Color(0xFF91B59B)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRect(field.deflate(0.75), lines);
    for (final fraction in [1 / 6, 1 / 3, 1 / 2, 2 / 3, 5 / 6]) {
      final y = size.height * fraction;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), lines);
    }
    for (final y in [size.height / 12, size.height * 11 / 12]) {
      canvas.drawLine(Offset(size.width / 2 - 8, y), Offset(size.width / 2 + 8, y), lines);
    }
  }

  @override
  bool shouldRepaint(covariant _FieldPainter oldDelegate) => false;
}
