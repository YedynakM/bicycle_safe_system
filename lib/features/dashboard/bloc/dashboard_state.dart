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
    this.autoOverrideCommand,
    this.userPreferenceCommand,
    this.isAutoNavigationEnabled = false,
  });

  final bool isConnected;
  final bool isReconnecting;
  final double currentSpeedKmh;
  final LightCommand? activeCommand;
  final String? errorMessage;
  final LightCommand? autoOverrideCommand;
  final LightCommand? userPreferenceCommand;
  final bool isAutoNavigationEnabled;

  DashboardState copyWith({
    bool? isConnected,
    bool? isReconnecting,
    double? currentSpeedKmh,
    LightCommand? activeCommand,
    String? errorMessage,
    LightCommand? autoOverrideCommand,
    LightCommand? userPreferenceCommand,
    bool? isAutoNavigationEnabled,
    bool clearError = false,
    bool clearActiveCommand = false,
    bool clearAutoOverride = false,
    bool clearUserPreference = false,
  }) {
    return DashboardState(
      isConnected: isConnected ?? this.isConnected,
      isReconnecting: isReconnecting ?? this.isReconnecting,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      activeCommand:
          clearActiveCommand ? null : activeCommand ?? this.activeCommand,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      autoOverrideCommand: clearAutoOverride
          ? null
          : autoOverrideCommand ?? this.autoOverrideCommand,
      userPreferenceCommand: clearUserPreference
          ? null
          : userPreferenceCommand ?? this.userPreferenceCommand,
      isAutoNavigationEnabled:
          isAutoNavigationEnabled ?? this.isAutoNavigationEnabled,
    );
  }

  @override
  List<Object?> get props => [
        isConnected,
        isReconnecting,
        currentSpeedKmh,
        activeCommand,
        errorMessage,
        autoOverrideCommand,
        userPreferenceCommand,
        isAutoNavigationEnabled,
      ];
}
