import 'package:bicycle_safe_system/app/theme/app_colors.dart';
import 'package:bicycle_safe_system/features/dashboard/view/widgets/concentric_speed_gauge.dart';
import 'package:flutter/material.dart';

class DashboardPanel extends StatelessWidget {
  const DashboardPanel({
    required this.panelHeight,
    required this.averageSpeed,
    required this.currentSpeed,
    required this.onSpeedChanged,
    required this.onBluetoothPressed,
    super.key,
  });

  final double panelHeight;
  final double averageSpeed;
  final double currentSpeed;
  final ValueChanged<double> onSpeedChanged;
  final VoidCallback onBluetoothPressed;

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
            colors: [Colors.black.withValues(alpha: 0.95), Colors.transparent],
            stops: const [0.7, 1.0],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Row(
                        //crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildCircleButton(
                                  icon: Icons.bluetooth_searching,
                                  color: Colors.blue,
                                  onTap: onBluetoothPressed,
                                  label: 'SCAN',
                                ),
                              ],
                            ),
                          ),
                          ConcentricSpeedGauge(
                            currentSpeed: currentSpeed,
                            averageSpeed: averageSpeed,
                            //maxSpeed: 60,
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildCircleButton(
                                  icon: Icons.lightbulb_outline,
                                  color: Colors.grey,
                                  onTap: () {},
                                  label: 'LIGHT',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: Container(
                        padding: const 
                        EdgeInsets.symmetric(horizontal: 12, vertical: 4),

                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                              color: Colors.yellow.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('TEST SIMULATION',
                                style:
                                    TextStyle
                                    (color: Colors.yellow, fontSize: 8)),
                            SizedBox(
                              height: 20,
                              child: Slider(
                                value: currentSpeed,
                                max: 60,
                                activeColor: AppColors.primary,
                                onChanged: onSpeedChanged,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 200,
                      height: 35,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.security, size: 16),
                        label: const Text('ARM SYSTEM', 
                        style: TextStyle(fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color, fontSize: 9)),
      ],
    );
  }
}
