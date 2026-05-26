// lib/features/dashboard/view/widgets/dashboard_panel.dart

import 'package:bicycle_safe_system/app/theme/app_colors.dart';
import 'package:bicycle_safe_system/features/dashboard/bloc/dashboard_bloc.dart';
import 'package:bicycle_safe_system/features/dashboard/bloc/dashboard_event.dart';
import 'package:bicycle_safe_system/features/dashboard/bloc/dashboard_state.dart';
import 'package:bicycle_safe_system/features/dashboard/logic/ble_protocol_handler.dart';
import 'package:bicycle_safe_system/features/dashboard/view/widgets/concentric_speed_gauge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
            colors: [
              Colors.black.withValues(alpha: 0.95),
              Colors.transparent,
            ],
            stops: const [0.7, 1.0],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                BlocBuilder<DashboardBloc, DashboardState>(
                  builder: (context, state) {
                    return _LightControlRow(
                      isConnected: state.isConnected,
                      activeCommand: state.activeCommand,
                    );
                  },
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            BlocBuilder<DashboardBloc, DashboardState>(
                              builder: (context, state) {
                                return _buildCircleButton(
                                  icon: state.isConnected
                                      ? Icons.bluetooth_connected
                                      : Icons.bluetooth_searching,
                                  color: state.isConnected
                                      ? Colors.greenAccent
                                      : Colors.blue,
                                  onTap: onBluetoothPressed,
                                  label: state.isConnected ? 'CONNECTED' : 'SCAN',
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      ConcentricSpeedGauge(
                        currentSpeed: currentSpeed,
                        averageSpeed: averageSpeed,
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            BlocBuilder<DashboardBloc, DashboardState>(
                              builder: (context, state) {
                                return _StatusIndicatorButton(
                                  isConnected: state.isConnected,
                                  activeCommand: state.activeCommand,
                                );
                              },
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
    padding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(
          color: Colors.yellow.withValues(alpha: 0.3)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'TEST SIMULATION',
          style: TextStyle(color: Colors.yellow, fontSize: 8),
        ),
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
const SizedBox(height: 6),
BlocBuilder<DashboardBloc, DashboardState>(
  builder: (context, state) {
    final bool autoOn = state.isAutoNavigationEnabled;
    final Color autoColor =
        autoOn ? Colors.cyanAccent : Colors.white30;
    return GestureDetector(
      onTap: () => context
          .read<DashboardBloc>()
          .add(const ToggleAutoNavigation()),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: autoOn
              ? Colors.cyanAccent.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: autoColor.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 14,
              color: autoColor,
            ),
            const SizedBox(width: 6),
            Text(
              autoOn ? 'AUTO-NAV  ON' : 'AUTO-NAV  OFF',
              style: TextStyle(
                color: autoColor,
                fontSize: 10,
                fontFamily: 'monospace',
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  },
),
const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
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
              color: Colors.grey.withValues(alpha: onTap != null ? 0.15 : 0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: onTap != null ? 0.5 : 0.2),
              ),
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

class _StatusIndicatorButton extends StatelessWidget {
  const _StatusIndicatorButton({
    required this.isConnected,
    required this.activeCommand,
  });

  final bool isConnected;
  final LightCommand? activeCommand;

  Color _resolveColor() {
    if (!isConnected) return Colors.grey;
    switch (activeCommand) {
      case LightCommand.headlight:
        return Colors.greenAccent;
      case LightCommand.stop:
        return Colors.redAccent;
      case LightCommand.leftTurn:
      case LightCommand.rightTurn:
        return Colors.yellowAccent;
      case LightCommand.off:
      case null:
        return Colors.white70;
    }
  }

  String _resolveLabel() {
    switch (activeCommand) {
      case LightCommand.leftTurn:
        return 'L';
      case LightCommand.rightTurn:
        return 'R';
      default:
        return 'OFF';
    }
  }

  IconData _resolveIcon() {
    switch (activeCommand) {
      case LightCommand.leftTurn:
      case LightCommand.rightTurn:
        return Icons.circle;
      case LightCommand.headlight:
        return Icons.lightbulb;
      case LightCommand.stop:
        return Icons.stop_circle;
      case LightCommand.off:
      case null:
        return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _resolveColor();
    final label = _resolveLabel();
    final icon = _resolveIcon();
    final bool showLetter = activeCommand == LightCommand.leftTurn ||
        activeCommand == LightCommand.rightTurn;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: isConnected
              ? () => context
                  .read<DashboardBloc>()
                  .add(const SendLightCommand(LightCommand.off))
              : null,
          borderRadius: BorderRadius.circular(30),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: isConnected ? 0.6 : 0.2),
              ),
            ),
            child: showLetter
                ? Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  )
                : Icon(icon, color: color, size: 22),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'OFF',
          style: TextStyle(color: color, fontSize: 9),
        ),
      ],
    );
  }
}

class _LightControlRow extends StatelessWidget {
  const _LightControlRow({
    required this.isConnected,
    required this.activeCommand,
  });

  final bool isConnected;
  final LightCommand? activeCommand;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _LightButton(
          label: 'LEFT',
          icon: Icons.arrow_back,
          command: LightCommand.leftTurn,
          activeCommand: activeCommand,
          isConnected: isConnected,
        ),
        _LightButton(
          label: 'STOP',
          icon: Icons.stop_circle_outlined,
          command: LightCommand.stop,
          activeCommand: activeCommand,
          isConnected: isConnected,
        ),
        _LightButton(
          label: 'LIGHT',
          icon: Icons.lightbulb_outline,
          command: LightCommand.headlight,
          activeCommand: activeCommand,
          isConnected: isConnected,
        ),
        _LightButton(
          label: 'RIGHT',
          icon: Icons.arrow_forward,
          command: LightCommand.rightTurn,
          activeCommand: activeCommand,
          isConnected: isConnected,
        ),
      ],
    );
  }
}

class _LightButton extends StatelessWidget {
  const _LightButton({
    required this.label,
    required this.icon,
    required this.command,
    required this.activeCommand,
    required this.isConnected,
  });

  final String label;
  final IconData icon;
  final LightCommand command;
  final LightCommand? activeCommand;
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    final isActive = isConnected && activeCommand == command;
    final Color color;
    if (!isConnected) {
      color = Colors.white24;
    } else if (isActive) {
      color = const Color(0xFF39FF14);
    } else {
      color = Colors.white54;
    }

    return GestureDetector(
      onTap: isConnected
          ? () => context.read<DashboardBloc>().add(SendLightCommand(command))
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive
              ? const Color(0xFF39FF14).withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: isConnected ? 0.05 : 0.02),
          border: Border.all(
            color: color,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontFamily: 'monospace',
                letterSpacing: 1,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
