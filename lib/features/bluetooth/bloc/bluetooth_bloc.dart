// lib/features/bluetooth/bloc/bluetooth_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../logic/bluetooth_service.dart';
import 'bluetooth_event.dart';
import 'bluetooth_state.dart';

class BluetoothBloc extends Bloc<BluetoothEvent, BluetoothBlocState> {
  BluetoothBloc({required AppBluetoothService bluetoothService})
      : _service = bluetoothService,
        super(const BluetoothInitial()) {
    on<StartScan>(_onStartScan);
    on<ConnectToDevice>(_onConnectToDevice);
    on<Disconnect>(_onDisconnect);
    on<ConnectionStateChanged>(_onConnectionStateChanged);
    on<DeviceReady>(_onDeviceReady);

    // Raw connection state: used only to detect disconnects.
    _connectionStateSub = _service.connectionStateStream.listen(
      (state) => add(ConnectionStateChanged(state)),
      onError: (_) => add(
        const ConnectionStateChanged(BluetoothConnectionState.disconnected),
      ),
    );

    // Device-ready fires AFTER discoverServices() succeeds.
    // This is the correct moment to emit BluetoothConnected so that
    // DashboardBloc can safely build a BleProtocolHandler.
    _deviceReadySub = _service.deviceReadyStream.listen(
      (readyState) => add(DeviceReady(readyState)),
      onError: (Object e) => emit(BluetoothError(e.toString())),
    );
  }

  final AppBluetoothService _service;
  late final StreamSubscription<BluetoothConnectionState> _connectionStateSub;
  late final StreamSubscription<DeviceReadyState> _deviceReadySub;
  StreamSubscription<List<ScanResult>>? _scanResultsSub;

  // ── handlers ────────────────────────────────────────────────────────────────

  Future<void> _onStartScan(
    StartScan event,
    Emitter<BluetoothBlocState> emit,
  ) async {
    emit(const BluetoothScanning());
    await _scanResultsSub?.cancel();

    _scanResultsSub = _service.scanResultsStream.listen(
      (results) {
        if (state is BluetoothScanning) {
          emit((state as BluetoothScanning).copyWith(results: results));
        }
      },
      onError: (Object e) => emit(BluetoothError(e.toString())),
    );

    try {
      await _service.startScan();
    } on Exception catch (e) {
      emit(BluetoothError('Scan failed: $e'));
    }
  }

  Future<void> _onConnectToDevice(
    ConnectToDevice event,
    Emitter<BluetoothBlocState> emit,
  ) async {
    await _scanResultsSub?.cancel();
    await _service.stopScan();

    // Emit a connecting state so the UI can show a spinner.
    emit(const BluetoothConnecting());

    try {
      // connectToDevice now: connects → negotiates MTU → discoverServices →
      // emits on deviceReadyStream.  The bloc will receive DeviceReady and
      // emit BluetoothConnected from _onDeviceReady.
      await _service.connectToDevice(event.device);
    } on Exception catch (e) {
      emit(BluetoothError('Connection failed: $e'));
    }
  }

  Future<void> _onDisconnect(
    Disconnect event,
    Emitter<BluetoothBlocState> emit,
  ) async {
    await _service.disconnect(intentional: true);
    emit(const BluetoothInitial());
  }

  /// Only used to catch *unexpected* disconnects (device went out of range, etc.)
  void _onConnectionStateChanged(
    ConnectionStateChanged event,
    Emitter<BluetoothBlocState> emit,
  ) {
    if (event.state == BluetoothConnectionState.disconnected) {
      emit(BluetoothDisconnected(isReconnecting: _service.isReconnecting));
    }
    // We intentionally ignore `connected` here: the authoritative "connected"
    // signal now comes from DeviceReady (after service discovery).
  }

  /// Emitted by AppBluetoothService once discoverServices() has succeeded.
  void _onDeviceReady(
    DeviceReady event,
    Emitter<BluetoothBlocState> emit,
  ) {
    emit(BluetoothConnected(
      event.readyState.device,
      services: event.readyState.services,
    ));
  }

  @override
  Future<void> close() async {
    await _connectionStateSub.cancel();
    await _deviceReadySub.cancel();
    await _scanResultsSub?.cancel();
    return super.close();
  }
}
