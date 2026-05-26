// lib/features/dashboard/bloc/dashboard_bloc.dart

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bicycle_safe_system/features/bluetooth/bloc/bluetooth_bloc.dart';
import 'package:bicycle_safe_system/features/bluetooth/bloc/bluetooth_state.dart';
import 'package:bicycle_safe_system/features/dashboard/logic/ble_protocol_handler.dart';
import 'package:bicycle_safe_system/features/dashboard/bloc/dashboard_event.dart';
import 'package:bicycle_safe_system/features/dashboard/bloc/dashboard_state.dart';

Duration _overrideDurationFor(LightCommand command) {
  switch (command) {
    case LightCommand.leftTurn:
    case LightCommand.rightTurn:
      return const Duration(seconds: 10);
    default:
      return const Duration(seconds: 5);
  }
}

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({required BluetoothBloc bluetoothBloc})
      : _bluetoothBloc = bluetoothBloc,
        super(const DashboardState()) {
    on<BtStateChanged>(_onBtStateChanged);
    on<SpeedUpdated>(_onSpeedUpdated);
    on<SendLightCommand>(_onSendLightCommand);
    on<AutoTurnDetected>(_onAutoTurnDetected);
    on<AutoTurnReleased>(_onAutoTurnReleased);
    on<ToggleAutoNavigation>(_onToggleAutoNavigation);
    on<ClearError>((_, emit) => emit(state.copyWith(clearError: true)));

    _btSub = bluetoothBloc.stream.listen(
      (btState) => add(BtStateChanged(btState)),
    );
    add(BtStateChanged(bluetoothBloc.state));
  }

  final BluetoothBloc _bluetoothBloc;
  BleProtocolHandler? _protocolHandler;
  late final StreamSubscription<Object> _btSub;
  StreamSubscription<double>? _speedSub;

  DateTime? _userOverrideUntil;

  bool get _userOverrideActive =>
      _userOverrideUntil != null &&
      DateTime.now().isBefore(_userOverrideUntil!);

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

        Future.delayed(const Duration(milliseconds: 300), () {
          if (!isClosed) add(const SendLightCommand(LightCommand.headlight));
        });
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
        clearAutoOverride: true,
        clearUserPreference: true,
      ));
    } else if (btState is BluetoothConnecting) {
      emit(state.copyWith(
        isConnected: false,
        isReconnecting: false,
        clearError: true,
      ));
    }
  }

Future<void> _onSpeedUpdated(
    SpeedUpdated event,
    Emitter<DashboardState> emit,
  ) async {
    final double previousSpeed = state.currentSpeedKmh;
    emit(state.copyWith(currentSpeedKmh: event.speedKmh));

    if (!state.isConnected || _protocolHandler == null) return;

    if (event.speedKmh <= 0.5 && previousSpeed > 0.5) {
      final LightCommand? pref = state.activeCommand;
      try {
        await _protocolHandler!.sendCommand(LightCommand.stop);
        emit(state.copyWith(
          activeCommand: LightCommand.stop,
          autoOverrideCommand: LightCommand.stop,
          userPreferenceCommand: pref,
        ));
      } on BleProtocolException catch (e) {
        emit(state.copyWith(errorMessage: e.message));
      }
    } else if (event.speedKmh > 0.5 && previousSpeed <= 0.5) {
      final LightCommand restore =
          state.userPreferenceCommand ?? LightCommand.headlight;
      try {
        await _protocolHandler!.sendCommand(restore);
        emit(state.copyWith(
          activeCommand: restore,
          clearAutoOverride: true,
          clearUserPreference: true,
        ));
      } on BleProtocolException catch (e) {
        emit(state.copyWith(errorMessage: e.message));
      }
    }
  }

  Future<void> _onSendLightCommand(
    SendLightCommand event,
    Emitter<DashboardState> emit,
  ) async {
    if (_protocolHandler == null || !state.isConnected) {
      emit(state.copyWith(errorMessage: 'Not connected to ESP32.'));
      return;
    }

    if (event.command == LightCommand.leftTurn ||
        event.command == LightCommand.rightTurn) {
      _userOverrideUntil = DateTime.now().add(const Duration(seconds: 5));
    }

    try {
      await _protocolHandler!.sendCommand(event.command);
      emit(state.copyWith(
        activeCommand: event.command,
        userPreferenceCommand: event.command,
        clearAutoOverride: true,
        clearError: true,
      ));
    } on BleProtocolException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

 Future<void> _onAutoTurnDetected(
    AutoTurnDetected event,
    Emitter<DashboardState> emit,
  ) async {
    if (!state.isAutoNavigationEnabled) return;
    if (_userOverrideActive) return;
    if (state.activeCommand == event.command) return;
    if (_protocolHandler == null || !state.isConnected) return;
    //if (state.currentSpeedKmh <= 0.5) return;

    try {
      await _protocolHandler!.sendCommand(event.command);
      emit(state.copyWith(
        activeCommand: event.command,
        autoOverrideCommand: event.command,
      ));
    } on BleProtocolException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  Future<void> _onAutoTurnReleased(
    AutoTurnReleased event,
    Emitter<DashboardState> emit,
  ) async {
    if (!state.isAutoNavigationEnabled) return;
    if (_userOverrideActive) return;
    if (state.autoOverrideCommand == null) return;
    if (_protocolHandler == null || !state.isConnected) return;

    final LightCommand restore =
        state.userPreferenceCommand ?? LightCommand.headlight;
    try {
      await _protocolHandler!.sendCommand(restore);
      emit(state.copyWith(
        activeCommand: restore,
        clearAutoOverride: true,
      ));
    } on BleProtocolException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

Future<void> _onToggleAutoNavigation(
    ToggleAutoNavigation event,
    Emitter<DashboardState> emit,
  ) async {
    final bool turningOff = state.isAutoNavigationEnabled;
    final bool hasAutoTurnActive = turningOff &&
        state.autoOverrideCommand != null &&
        (state.activeCommand == LightCommand.leftTurn ||
            state.activeCommand == LightCommand.rightTurn);

    emit(state.copyWith(
      isAutoNavigationEnabled: !state.isAutoNavigationEnabled,
      clearAutoOverride: true,
    ));

    if (hasAutoTurnActive &&
        _protocolHandler != null &&
        state.isConnected) {
      final LightCommand restore =
          state.userPreferenceCommand ?? LightCommand.headlight;
      try {
        await _protocolHandler!.sendCommand(restore);
        emit(state.copyWith(
          activeCommand: restore,
          clearAutoOverride: true,
        ));
      } on BleProtocolException catch (e) {
        emit(state.copyWith(errorMessage: e.message));
      }
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
