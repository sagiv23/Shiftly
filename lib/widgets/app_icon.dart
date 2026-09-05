import 'package:flutter/material.dart';

class EssentialWorkIcon extends StatelessWidget {
  final double size;

  const EssentialWorkIcon({super.key, this.size = 180.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // כחול נייבי נקי וכהה
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: CustomPaint(painter: _EssentialWorkIconPainter()),
    );
  }
}

class _EssentialWorkIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.28;

    // 1. מעגל השעון (Clock Face Outline)
    final clockOutline = Paint()
      ..color =
          const Color(0xFF38BDF8) // כחול בהיר נקי
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.045
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, clockOutline);

    // 2. מחוגי השעון (מצביעים על שעות עבודה)
    final handsPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.045
      ..strokeCap = StrokeCap.round;

    // מחוג שעות (מצביע למעלה/ימינה)
    canvas.drawLine(
      center,
      Offset(center.dx, center.dy - radius * 0.55),
      handsPaint,
    );
    // מחוג דקות (מצביע ימינה)
    canvas.drawLine(
      center,
      Offset(center.dx + radius * 0.45, center.dy),
      handsPaint,
    );

    // 3. תגית שכר (Currency Symbol Overlay - ₪)
    final textPainter = TextPainter(
      text: TextSpan(
        text: '₪',
        style: TextStyle(
          color: const Color(0xFFFACC15), // זהב-שכר
          fontSize: size.width * 0.28,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.rtl,
    );

    textPainter.layout();
    // מיקום הסמל בפינה הימנית התחתונה מעל השעון
    final textOffset = Offset(
      center.dx + radius * 0.1,
      center.dy + radius * 0.05,
    );

    // הוספת רקע כהה קטן מאחורי הסמל לקריאות
    final bgCircle = Paint()..color = const Color(0xFF1E293B);
    canvas.drawCircle(
      Offset(
        textOffset.dx + textPainter.width / 2,
        textOffset.dy + textPainter.height / 2,
      ),
      textPainter.width * 0.55,
      bgCircle,
    );

    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
