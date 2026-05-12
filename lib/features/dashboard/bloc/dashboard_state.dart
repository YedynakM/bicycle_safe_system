// lib/features/dashboard/bloc/dashboard_state.dart

import 'package:equatable/equatable.dart';
import 'package:bicycle_safe_system/features/dashboard/logic/ble_protocol_handler.dart';

final class DashboardState extends Equatable {
  const DashboardState({
    this.isConnected = false,
    this.isReconnecting = false,
    this.currentSpeedKmh = 0.0,
    this.activeCommand,
    this.errorMessage,
  });

  final bool isConnected;
  final bool isReconnecting;
  final double currentSpeedKmh;
  final LightCommand? activeCommand;
  final String? errorMessage;

  DashboardState copyWith({
    bool? isConnected,
    bool? isReconnecting,
    double? currentSpeedKmh,
    LightCommand? activeCommand,
    String? errorMessage,
    bool clearError = false,
    bool clearActiveCommand = false,
  }) {
    return DashboardState(
      isConnected: isConnected ?? this.isConnected,
      isReconnecting: isReconnecting ?? this.isReconnecting,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      activeCommand: clearActiveCommand ? null : activeCommand ?? this.activeCommand,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isConnected,
        isReconnecting,
        currentSpeedKmh,
        activeCommand,
        errorMessage,
      ];
}
