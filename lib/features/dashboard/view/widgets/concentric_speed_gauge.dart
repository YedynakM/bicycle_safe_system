import 'dart:math';
import 'package:bicycle_safe_system/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

class ConcentricSpeedGauge extends StatelessWidget {
  final double currentSpeed;
  final double averageSpeed;
  final double maxSpeed;

  const ConcentricSpeedGauge({
    required this.currentSpeed,
    required this.averageSpeed,
    super.key,
    this.maxSpeed = 60.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(200, 200),
            painter: _GaugePainter(
              currentSpeed: currentSpeed,
              averageSpeed: averageSpeed,
              maxSpeed: maxSpeed,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                currentSpeed.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const Text(
                'KM/H',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'AVG: ${averageSpeed.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double currentSpeed;
  final double averageSpeed;
  final double maxSpeed;

  _GaugePainter({
    required this.currentSpeed,
    required this.averageSpeed,
    required this.maxSpeed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    const startAngle = 135 * pi / 180;
    const sweepAngle = 270 * pi / 180;

    final outerPaintBg = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 12;

    final outerPaintActive = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 12;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 10), 
        startAngle, sweepAngle, false, outerPaintBg);

    final currentSweep = (currentSpeed / maxSpeed).clamp(0.0, 1.0) * sweepAngle;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 10), 
        startAngle, currentSweep, false, outerPaintActive);

    final innerPaintBg = Paint()
      ..color = Colors.grey.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8;

    final innerPaintActive = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 28), 
        startAngle, sweepAngle, false, innerPaintBg);

    final avgSweep = (averageSpeed / maxSpeed).clamp(0.0, 1.0) * sweepAngle;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 28), 
        startAngle, avgSweep, false, innerPaintActive);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
