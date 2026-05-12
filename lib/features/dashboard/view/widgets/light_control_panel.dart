// lib/features/dashboard/view/widgets/light_control_panel.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bicycle_safe_system/features/dashboard/bloc/dashboard_bloc.dart';
import 'package:bicycle_safe_system/features/dashboard/bloc/dashboard_event.dart';
import 'package:bicycle_safe_system/features/dashboard/bloc/dashboard_state.dart';
import 'package:bicycle_safe_system/features/dashboard/logic/ble_protocol_handler.dart';

class LightControlPanel extends StatelessWidget {
  const LightControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _CommandButton(
              label: 'LEFT',
              icon: Icons.arrow_back,
              command: LightCommand.leftTurn,
              activeCommand: state.activeCommand,
              isConnected: state.isConnected,
            ),
            _CommandButton(
              label: 'STOP',
              icon: Icons.stop_circle_outlined,
              command: LightCommand.stop,
              activeCommand: state.activeCommand,
              isConnected: state.isConnected,
            ),
            _CommandButton(
              label: 'LIGHT',
              icon: Icons.lightbulb_outline,
              command: LightCommand.headlight,
              activeCommand: state.activeCommand,
              isConnected: state.isConnected,
            ),
            _CommandButton(
              label: 'RIGHT',
              icon: Icons.arrow_forward,
              command: LightCommand.rightTurn,
              activeCommand: state.activeCommand,
              isConnected: state.isConnected,
            ),
          ],
        );
      },
    );
  }
}

class _CommandButton extends StatelessWidget {
  const _CommandButton({
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
    final isActive = activeCommand == command;
    final color = isActive ? const Color(0xFF39FF14) : Colors.white54;

    return GestureDetector(
      onTap: isConnected
          ? () => context
              .read<DashboardBloc>()
              .add(SendLightCommand(command))
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive
              ? const Color(0xFF39FF14).withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
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
