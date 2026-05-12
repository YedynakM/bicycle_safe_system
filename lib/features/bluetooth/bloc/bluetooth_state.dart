// lib/features/bluetooth/bloc/bluetooth_state.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

sealed class BluetoothBlocState extends Equatable {
  const BluetoothBlocState();

  @override
  List<Object?> get props => [];
}

final class BluetoothInitial extends BluetoothBlocState {
  const BluetoothInitial();
}

final class BluetoothScanning extends BluetoothBlocState {
  const BluetoothScanning({this.results = const []});

  final List<ScanResult> results;

  BluetoothScanning copyWith({List<ScanResult>? results}) =>
      BluetoothScanning(results: results ?? this.results);

  @override
  List<Object?> get props => [results];
}

/// Emitted while [AppBluetoothService.connectToDevice] is running (between
/// connect() and discoverServices() completing).  Use this to show a spinner.
final class BluetoothConnecting extends BluetoothBlocState {
  const BluetoothConnecting();
}

/// Emitted only after service discovery succeeds.
/// [services] is passed straight from [DeviceReadyState] so that
/// [DashboardBloc] can hand them to [BleProtocolHandler] without a second
/// discoverServices() call.
final class BluetoothConnected extends BluetoothBlocState {
  const BluetoothConnected(this.device, {this.services = const []});

  final BluetoothDevice device;

  /// Already-discovered services — ready to use immediately.
  final List<BluetoothService> services;

  @override
  List<Object?> get props => [device.remoteId, services];
}

final class BluetoothDisconnected extends BluetoothBlocState {
  const BluetoothDisconnected({this.isReconnecting = false});

  final bool isReconnecting;

  @override
  List<Object?> get props => [isReconnecting];
}

final class BluetoothError extends BluetoothBlocState {
  const BluetoothError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
