// lib/features/dashboard/bloc/dashboard_event.dart

import 'package:equatable/equatable.dart';
import 'package:bicycle_safe_system/features/dashboard/logic/ble_protocol_handler.dart';

sealed class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

final class SendLightCommand extends DashboardEvent {
  const SendLightCommand(this.command);
  final LightCommand command;

  @override
  List<Object?> get props => [command];
}

final class SpeedUpdated extends DashboardEvent {
  const SpeedUpdated(this.speedKmh);
  final double speedKmh;

  @override
  List<Object?> get props => [speedKmh];
}
class ClearError extends DashboardEvent {
  const ClearError();
}
final class BtStateChanged extends DashboardEvent {
  const BtStateChanged(this.btState);
  final Object btState;

  @override
  List<Object?> get props => [btState];
}
