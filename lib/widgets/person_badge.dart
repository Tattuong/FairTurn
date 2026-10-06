import 'package:flutter/material.dart';

const personColors = <Color>[
  Color(0xFFD4F562),
  Color(0xFFC4B5FD),
  Color(0xFFE4D4FF),
  Color(0xFFE5E7EB),
  Color(0xFFFBCFE8),
  Color(0xFFBFDBFE),
  Color(0xFFFDE68A),
];

class PersonBadge extends StatelessWidget {
  final String initial;
  final int color;
  final double size;
  final bool dashed;
  final bool checked;
  final bool crossed;
  final bool ring;

  const PersonBadge({
    super.key,
    required this.initial,
    required this.color,
    this.size = 36,
    this.dashed = false,
    this.checked = false,
    this.crossed = false,
    this.ring = false,
  });

  @override
  Widget build(BuildContext context) {
    final fill = personColors[color.abs() % personColors.length];
    final mark = (size * 0.34).clamp(16.0, 22.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            painter: dashed ? const _DashedRingPainter() : null,
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: dashed ? Colors.transparent : fill,
                shape: BoxShape.circle,
                border: dashed || !ring
                    ? null
                    : Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                initial,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: size * 0.38,
                  color: const Color(0xFF17191C),
                  height: 1,
                ),
              ),
            ),
          ),
          if (checked || crossed)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: mark,
                height: mark,
                decoration: const BoxDecoration(
                  color: Color(0xFF17191C),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  crossed ? Icons.close : Icons.check,
                  size: mark * 0.68,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  const _DashedRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB7BDC7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final path = Path()
      ..addOval(Rect.fromCircle(
          center: size.center(Offset.zero), radius: size.width / 2 - 1));
    final dashed = Path();
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        dashed.addPath(
            metric.extractPath(distance, distance + 4.5), Offset.zero);
        distance += 8;
      }
    }
    canvas.drawPath(dashed, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
