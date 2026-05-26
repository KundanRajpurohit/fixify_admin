import 'package:flutter/material.dart';

class SegmentedRingPainter extends CustomPainter {
  final int totalSegments;
  final int currentSegment;
  final Color activeColor;
  final Color inactiveColor;

  SegmentedRingPainter({
    required this.totalSegments,
    required this.currentSegment,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 4.0;
    const gapAngle = 10 * (3.14159 / 180); // 10 degrees gap between segments
    final segmentAngle =
        (2 * 3.14159 - (gapAngle * totalSegments)) / totalSegments;

    for (int i = 0; i < totalSegments; i++) {
      final paint =
          Paint()
            ..color = i < currentSegment ? activeColor : inactiveColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round;

      final startAngle = -3.14159 / 2 + (i * (segmentAngle + gapAngle));

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        segmentAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(SegmentedRingPainter oldDelegate) {
    return oldDelegate.currentSegment != currentSegment;
  }
}
