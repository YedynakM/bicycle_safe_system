// lib/features/dashboard/bloc/dashboard_bloc.dart
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bicycle_safe_system/features/bluetooth/bloc/bluetooth_bloc.dart';
import 'package:bicycle_safe_system/features/bluetooth/bloc/bluetooth_state.dart';
import 'package:bicycle_safe_system/features/dashboard/logic/ble_protocol_handler.dart';
import 'package:bicycle_safe_system/features/dashboard/bloc/dashboard_event.dart';
import 'package:bicycle_safe_system/features/dashboard/bloc/dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({required BluetoothBloc bluetoothBloc})
      : _bluetoothBloc = bluetoothBloc,
        super(const DashboardState()) {
    on<BtStateChanged>(_onBtStateChanged);
    on<SpeedUpdated>(_onSpeedUpdated);
    on<SendLightCommand>(_onSendLightCommand);
    on<ClearError>((_, emit) => emit(state.copyWith(clearError: true)));
    _btSub = bluetoothBloc.stream.listen(
      (btState) => add(BtStateChanged(btState)),
    );
    // Replay the current BT state in case BluetoothConnected was already
    // emitted before DashboardBloc was created.
    add(BtStateChanged(bluetoothBloc.state));
  }

  final BluetoothBloc _bluetoothBloc;
  BleProtocolHandler? _protocolHandler;
  late final StreamSubscription<Object> _btSub;
  StreamSubscription<double>? _speedSub;

  // ── handlers ────────────────────────────────────────────────────────────────

  Future<void> _onBtStateChanged(
    BtStateChanged event,
    Emitter<DashboardState> emit,
  ) async {
    final btState = event.btState;

    if (btState is BluetoothConnected) {
      await _tearDown();
      emit(state.copyWith(
        isConnected: true,
        isReconnecting: false,
        clearError: true,
      ));

      try {
        // Pass the already-discovered services so BleProtocolHandler does NOT
        // call discoverServices() again — that would cause a second GATT
        // transaction and potentially crash on some Android versions.
        _protocolHandler = BleProtocolHandler(
          device: btState.device,
          services: btState.services,
        );
        await _protocolHandler!.initialize();

        _speedSub = _protocolHandler!.speedStream.listen(
          (speed) => add(SpeedUpdated(speed)),
          onError: (Object error) =>
              emit(state.copyWith(errorMessage: 'Telemetry error: $error')),
        );
      } on BleProtocolException catch (e) {
        emit(state.copyWith(isConnected: false, errorMessage: e.message));
      }
    } else if (btState is BluetoothDisconnected) {
      await _tearDown();
      emit(state.copyWith(
        isConnected: false,
        isReconnecting: btState.isReconnecting,
        currentSpeedKmh: 0.0,
        clearActiveCommand: true,
      ));
    } else if (btState is BluetoothConnecting) {
      // Show a "connecting" state in the dashboard while discovery is ongoing.
      emit(state.copyWith(
        isConnected: false,
        isReconnecting: false,
        clearError: true,
      ));
    }
  }

  void _onSpeedUpdated(SpeedUpdated event, Emitter<DashboardState> emit) {
    emit(state.copyWith(currentSpeedKmh: event.speedKmh));
  }

  Future<void> _onSendLightCommand(
    SendLightCommand event,
    Emitter<DashboardState> emit,
  ) async {
    if (_protocolHandler == null || !state.isConnected) {
      emit(state.copyWith(errorMessage: 'Not connected to ESP32.'));
      return;
    }
    try {
      await _protocolHandler!.sendCommand(event.command);
      emit(state.copyWith(activeCommand: event.command, clearError: true));
    } on BleProtocolException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  Future<void> _tearDown() async {
    await _speedSub?.cancel();
    _speedSub = null;
    await _protocolHandler?.dispose();
    _protocolHandler = null;
  }

  @override
  Future<void> close() async {
    await _btSub.cancel();
    await _tearDown();
    return super.close();
  }
}
