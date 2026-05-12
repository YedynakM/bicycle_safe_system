// lib/features/bluetooth/bloc/bluetooth_event.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../logic/bluetooth_service.dart';

sealed class BluetoothEvent extends Equatable {
  const BluetoothEvent();

  @override
  List<Object?> get props => [];
}

final class StartScan extends BluetoothEvent {
  const StartScan();
}

final class ConnectToDevice extends BluetoothEvent {
  const ConnectToDevice(this.device);
  final BluetoothDevice device;

  @override
  List<Object?> get props => [device.remoteId];
}

final class Disconnect extends BluetoothEvent {
  const Disconnect();
}

final class ConnectionStateChanged extends BluetoothEvent {
  const ConnectionStateChanged(this.state);
  final BluetoothConnectionState state;

  @override
  List<Object?> get props => [state];
}

/// Internal event fired once [AppBluetoothService] has successfully
/// connected AND completed service discovery.
final class DeviceReady extends BluetoothEvent {
  const DeviceReady(this.readyState);
  final DeviceReadyState readyState;

  @override
  List<Object?> get props => [readyState.device.remoteId];
}
