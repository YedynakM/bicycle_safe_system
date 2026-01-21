import 'package:flutter/material.dart';

class AppGauge extends StatelessWidget {
  const AppGauge({
    required this.value,
    required this.max,
    required this.color,
    required this.label,
    required this.subLabel,
    this.isSmall = false,
    super.key,
  });

  final double value;
  final double max;
  final Color color;
  final String label;
  final String subLabel;
  final bool isSmall;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth < constraints.maxHeight 
              ? constraints.maxWidth 
              : constraints.maxHeight;
          
          if (size < 40) return const SizedBox();

          final fontSize = size * 0.3;
          final strokeWidth = size * 0.08;

          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: size * 0.8,
                height: size * 0.8,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: 1,
                      color: Colors.white.withValues(alpha: 0.12),
                      strokeWidth: strokeWidth,
                    ),
                    CircularProgressIndicator(
                      value: (value / max).clamp(0.0, 1.0),
                      color: color,
                      strokeWidth: strokeWidth,
                      strokeCap: StrokeCap.round,
                    ),
                    Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: const [Shadow(blurRadius: 10, 
                          color: Color.fromARGB(255, 1, 1, 1))],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: size * 0.05),
              Text(
                subLabel,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: (size * 0.12).clamp(8.0, 14.0),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
