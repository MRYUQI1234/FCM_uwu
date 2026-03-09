import 'dart:math';
import 'package:flutter/material.dart';

class LineChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;

  LineChartPainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final path = Path();
    final double stepX = size.width / (values.length - 1);
    final double maxValue = values.reduce(max).clamp(1.0, double.infinity);

    for (int i = 0; i < values.length; i++) {
      final double x = i * stepX;
      final double y = size.height - (values[i] / maxValue) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // Smooth Bezier implementation
        final prevX = (i - 1) * stepX;
        final prevY = size.height - (values[i - 1] / maxValue) * size.height;
        path.cubicTo(
          prevX + stepX / 2, prevY,
          x - stepX / 2, y,
          x, y
        );
      }
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
    
    // Fill under path
    final fillPath = Path.combine(
      PathOperation.intersect, 
      Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
      Path()..moveTo(0, size.height)
            ..lineTo(0, size.height - (values[0] / maxValue) * size.height)
    );
     // Re-implementing fill correctly for curves
    final actualFillPath = Path();
    actualFillPath.moveTo(0, size.height);
    for (int i = 0; i < values.length; i++) {
      final double x = i * stepX;
      final double y = size.height - (values[i] / maxValue) * size.height;
      if (i == 0) {
        actualFillPath.lineTo(x, y);
      } else {
        final prevX = (i - 1) * stepX;
        final prevY = size.height - (values[i - 1] / maxValue) * size.height;
        actualFillPath.cubicTo(prevX + stepX / 2, prevY, x - stepX / 2, y, x, y);
      }
    }
    actualFillPath.lineTo(size.width, size.height);
    actualFillPath.close();
      
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.3), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      
    canvas.drawPath(actualFillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class RadarChartPainter extends CustomPainter {
  final Map<String, double> stats;
  final Color color;
  final Color? labelColor;
  final Color? gridColor;

  RadarChartPainter({
    required this.stats, 
    required this.color,
    this.labelColor,
    this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = min(centerX, centerY) * 0.8;

    final axisPaint = Paint()
      ..color = gridColor ?? Colors.white.withOpacity(0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final List<Offset> points = [];
    final keys = stats.keys.toList();
    final int axisCount = keys.length;
    if (axisCount == 0) return; // Prevent division by zero crash

    final angleStep = (2 * pi) / axisCount;

    // Draw background grid
    for (var i = 1; i <= 4; i++) {
      final polyPath = Path();
      final currentRadius = radius * (i / 4);
      for (var j = 0; j < axisCount; j++) {
        final angle = j * angleStep - pi / 2;
        final x = centerX + currentRadius * cos(angle);
        final y = centerY + currentRadius * sin(angle);
        if (j == 0) polyPath.moveTo(x, y);
        else polyPath.lineTo(x, y);
      }
      polyPath.close();
      canvas.drawPath(polyPath, axisPaint);
    }

    // Draw axes
    for (var j = 0; j < axisCount; j++) {
      final angle = j * angleStep - pi / 2;
      canvas.drawLine(Offset(centerX, centerY), Offset(centerX + radius * cos(angle), centerY + radius * sin(angle)), axisPaint);
    }

    // Draw stat polygon
    final statPath = Path();
    for (var j = 0; j < axisCount; j++) {
      final angle = j * angleStep - pi / 2;
      final val = stats[keys[j]] ?? 0.5;
      final x = centerX + radius * val * cos(angle);
      final y = centerY + radius * val * sin(angle);
      points.add(Offset(x, y));
      if (j == 0) statPath.moveTo(x, y);
      else statPath.lineTo(x, y);
    }
    statPath.close();

    canvas.drawPath(statPath, fillPaint);
    canvas.drawPath(statPath, borderPaint);

    // Draw points
    for (var point in points) {
      canvas.drawCircle(point, 3, Paint()..color = color);
      canvas.drawCircle(point, 6, Paint()..color = color.withOpacity(0.2));
    }

    // Draw Labels
    for (var j = 0; j < axisCount; j++) {
      final angle = j * angleStep - pi / 2;
      final labelRadius = radius + 20;
      final x = centerX + labelRadius * cos(angle);
      final y = centerY + labelRadius * sin(angle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: keys[j].toUpperCase(),
          style: TextStyle(
            color: labelColor ?? Colors.white38,
            fontSize: 8,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Center the text based on its size
      canvas.save();
      canvas.translate(x - textPainter.width / 2, y - textPainter.height / 2);
      textPainter.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant RadarChartPainter oldDelegate) {
    return oldDelegate.stats != stats || 
           oldDelegate.color != color || 
           oldDelegate.labelColor != labelColor ||
           oldDelegate.gridColor != gridColor;
  }
}
