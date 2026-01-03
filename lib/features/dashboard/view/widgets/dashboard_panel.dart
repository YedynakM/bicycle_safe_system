import 'package:bicycle_safe_system/app/theme/app_colors.dart';
import 'package:bicycle_safe_system/features/dashboard/view/widgets/app_gauge.dart';
import 'package:flutter/material.dart';

class DashboardPanel extends StatelessWidget {
  const DashboardPanel({
    required this.panelHeight,
    required this.averageSpeed,
    required this.currentSpeed,
    required this.onSpeedChanged,
    super.key,
  });

  final double panelHeight;
  final double averageSpeed;
  final double currentSpeed;
  final ValueChanged<double> onSpeedChanged;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: panelHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.85), Colors.transparent],
            stops: const [0.6, 1.0],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double availableForGauges = (
                  constraints.maxHeight - 110.0).clamp(0.0, 200.0);

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: availableForGauges,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AppGauge(
                            value: averageSpeed,
                            max: 60,
                            color: Colors.orangeAccent,
                            label: averageSpeed.toStringAsFixed(1),
                            subLabel: 'AVG KM/H',
                            isSmall: true,
                          ),
                          AppGauge(
                            value: currentSpeed,
                            max: 60,
                            color: AppColors.primary,
                            label: currentSpeed.toStringAsFixed(0),
                            subLabel: 'KM/H',
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 350),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                          color: Colors.yellow.withValues(alpha: 0.7)),
                        ),
                        child: Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text('TEST SIMULATION', style: TextStyle(
                                color: Colors.yellow, fontSize: 9)),
                            ),
                            SizedBox(
                              height: 30,
                              child: Slider(
                                value: currentSpeed,
                                //min: 0,
                                max: 60,
                                activeColor: AppColors.primary,
                                onChanged: onSpeedChanged,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints
                      (maxWidth: 300, maxHeight: 45),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.security),
                          label: const Text('ARM SYSTEM'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
