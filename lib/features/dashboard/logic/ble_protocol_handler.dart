// lib/features/dashboard/logic/ble_protocol_handler.dart

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

const String kBikeServiceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
const String kCommandCharUuid  = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';
const String kTelemetryCharUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';

enum LightCommand {
  headlight(0x46),  // 'F'
  stop(0x53),       // 'S'
  leftTurn(0x4C),   // 'L'
  rightTurn(0x52),  // 'R'
  off(0x4F);        // 'O'

  const LightCommand(this.byteValue);
  final int byteValue;
}

class BleProtocolHandler {
  /// Pass [services] from [BluetoothConnected] state so we skip a second
  /// discoverServices() GATT transaction (avoids crashes on some Android).
  BleProtocolHandler({
    required BluetoothDevice device,
    required List<BluetoothService> services,
  })  : _device = device,
        _services = services;

  final BluetoothDevice _device;
  final List<BluetoothService> _services;

  BluetoothCharacteristic? _commandChar;
  BluetoothCharacteristic? _telemetryChar;
  StreamSubscription<List<int>>? _notifySub;

  final _speedController = StreamController<double>.broadcast();
  Stream<double> get speedStream => _speedController.stream;
  bool get isReady => _commandChar != null && _telemetryChar != null;

  Future<void> initialize() async {
    // Use pre-discovered services — no second GATT round trip.
    final bikeService = _services.cast<BluetoothService?>().firstWhere(
      (s) => s?.serviceUuid.toString().toLowerCase() == kBikeServiceUuid,
      orElse: () => null,
    );

    if (bikeService == null) {
      throw BleProtocolException(
        'Service $kBikeServiceUuid not found on ${_device.remoteId}.',
      );
    }

    _commandChar  = _findChar(bikeService, kCommandCharUuid);
    _telemetryChar = _findChar(bikeService, kTelemetryCharUuid);

    if (_commandChar == null) {
      throw BleProtocolException('Command char $kCommandCharUuid not found.');
    }
    if (_telemetryChar == null) {
      throw BleProtocolException(
          'Telemetry char $kTelemetryCharUuid not found.');
    }

    await _subscribeToTelemetry();
  }

  Future<void> sendCommand(LightCommand command) async {
    if (_commandChar == null) {
      throw StateError('Call initialize() before sendCommand().');
    }
    try {
      await _commandChar!.write(
        Uint8List.fromList([command.byteValue]),
        withoutResponse: false,
      );
    } on Exception catch (e) {
      throw BleProtocolException('Failed to send ${command.name}: $e');
    }
  }

  Future<void> _subscribeToTelemetry() async {
    await _telemetryChar!.setNotifyValue(true);
    _notifySub = _telemetryChar!.onValueReceived.listen(
      _onTelemetryReceived,
      onError: _speedController.addError,
    );
  }

  void _onTelemetryReceived(List<int> rawBytes) {
    if (rawBytes.length != 4) return; 
    final byteData = ByteData.sublistView(Uint8List.fromList(rawBytes));
    final speed = byteData.getFloat32(0, Endian.little);
    if (speed < 0 || speed > 120) return;
    _speedController.add(speed);
  }

  BluetoothCharacteristic? _findChar(BluetoothService service, String uuid) =>
      service.characteristics.cast<BluetoothCharacteristic?>().firstWhere(
            (c) => c?.characteristicUuid.toString().toLowerCase() == uuid,
            orElse: () => null,
          );

  Future<void> dispose() async {
    await _notifySub?.cancel();
    _notifySub = null;
    try {
      await _telemetryChar?.setNotifyValue(false);
    } on Exception catch (_) {}
    _commandChar  = null;
    _telemetryChar = null;
    await _speedController.close();
  }
}

class BleProtocolException implements Exception {
  const BleProtocolException(this.message);
  final String message;

  @override
  String toString() => 'BleProtocolException: $message';
}
