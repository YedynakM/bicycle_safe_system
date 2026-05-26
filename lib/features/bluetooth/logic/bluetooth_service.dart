// lib/features/bluetooth/logic/bluetooth_service.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

const int _kTargetMtu = 512;
const int _kMaxReconnectAttempts = 8;
const int _kInitialBackoffSeconds = 1;
const int _kMaxBackoffSeconds = 60;
const Duration _kScanDuration = Duration(seconds: 6);

/// Emitted once services have been discovered and the device is truly usable.
final class DeviceReadyState {
  const DeviceReadyState({
    required this.device,
    required this.services,
  });

  final BluetoothDevice device;

  /// All services discovered on the device.
  final List<BluetoothService> services;
}

class BluetoothConnectionException implements Exception {
  const BluetoothConnectionException(this.message);
  final String message;

  @override
  String toString() => 'BluetoothConnectionException: $message';
}

class AppBluetoothService {
  // ── public getters ──────────────────────────────────────────────────────────

  BluetoothDevice? get connectedDevice => _connectedDevice;
  BluetoothDevice? _connectedDevice;

  bool get isReconnecting => _isReconnecting;
  bool _isReconnecting = false;
  bool _intentionalDisconnect = false;

  // ── streams ─────────────────────────────────────────────────────────────────

  /// Raw BLE connection-state changes (connecting / connected / disconnecting /
  /// disconnected).  UI should prefer [deviceReadyStream] to know when the
  /// device is actually usable.
  final _connectionStateController =
      StreamController<BluetoothConnectionState>.broadcast();
  Stream<BluetoothConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  /// Emitted after a successful connection AND service-discovery pass.
  /// Listeners receive a [DeviceReadyState] that carries the discovered
  /// services so that BleProtocolHandler can be built without a second
  /// discoverServices() call.
  final _deviceReadyController =
      StreamController<DeviceReadyState>.broadcast();
  Stream<DeviceReadyState> get deviceReadyStream =>
      _deviceReadyController.stream;

  /// Scan results (merged, de-duplicated).
  final _scanResultsController =
      StreamController<List<ScanResult>>.broadcast();
  Stream<List<ScanResult>> get scanResultsStream =>
      _scanResultsController.stream;
  // Alias kept for ScanPage compatibility.
  Stream<List<ScanResult>> get scanResults => _scanResultsController.stream;

  // ── private ─────────────────────────────────────────────────────────────────

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _deviceConnectionSub;

  final List<ScanResult> _scanResults = [];

  // ── scanning ────────────────────────────────────────────────────────────────

Future<void> startScan({Duration timeout = _kScanDuration}) async {
  if (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
    try {
      await FlutterBluePlus.turnOn();
      await FlutterBluePlus.adapterState
          .where((s) => s == BluetoothAdapterState.on)
          .first
          .timeout(const Duration(seconds: 8));
    } on Exception catch (_) {}

    if (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
      throw BluetoothConnectionException(
        'Please turn on Bluetooth in your phone settings.',
      );
    }
  }

  _scanResults.clear();
  await _scanSub?.cancel();
  _scanSub = null;

  try {
    await FlutterBluePlus.stopScan();
  } on Exception catch (_) {}

  _scanSub = FlutterBluePlus.scanResults.listen(
    (results) {
      for (final r in results) {
        final idx = _scanResults
            .indexWhere((e) => e.device.remoteId == r.device.remoteId);
        if (idx == -1) {
          _scanResults.add(r);
        } else {
          _scanResults[idx] = r;
        }
      }
      _scanResultsController.add(List.unmodifiable(_scanResults));
    },
    onError: _scanResultsController.addError,
  );

  try {
    await FlutterBluePlus.startScan(
      timeout: timeout,
      androidUsesFineLocation: true,
    );
  } on Exception catch (e) {
    await _scanSub?.cancel();
    _scanSub = null;
    throw BluetoothConnectionException(
      'Scan failed: ${e.toString()}',
    );
  }
}

Future<void> stopScan() async {
  try {
    await FlutterBluePlus.stopScan();
  } on Exception catch (_) {}
  await _scanSub?.cancel();
  _scanSub = null;
}
  // ── connection ──────────────────────────────────────────────────────────────

  /// Connect to [device], discover services, then emit on [deviceReadyStream].
  ///
  /// Throws a [BluetoothConnectionException] on any failure so callers can
  /// surface a proper error to the UI instead of swallowing it.
  Future<void> connectToDevice(BluetoothDevice device) async {
    _intentionalDisconnect = false;
    _connectedDevice = device;

    await _deviceConnectionSub?.cancel();

    // Listen for future disconnects so we can trigger auto-reconnect.
    _deviceConnectionSub = device.connectionState.listen(
      _handleConnectionStateChange,
      onError: _connectionStateController.addError,
    );

    // ── Step 1: physical connection ──────────────────────────────────────────
    try {
      await device.connect(license: License.free, autoConnect: false, mtu: null);
    } on Exception catch (e) {
      _connectedDevice = null;
      await _deviceConnectionSub?.cancel();
      _deviceConnectionSub = null;
      throw BluetoothConnectionException('connect() failed: $e');
    }

    // ── Step 2: MTU negotiation (best-effort, non-fatal) ────────────────────
    await _negotiateMtu(device);

    // ── Step 3: service discovery ────────────────────────────────────────────
    // This MUST happen here (in the service layer) and not later in the BLoC,
    // because on Android the connectionState stream fires `connected` before
    // the GATT service table is ready. Doing discovery here lets us emit a
    // single "device is fully ready" event that the BLoC can act on safely.
    List<BluetoothService> services;
    try {
      services = await device.discoverServices();
    } on Exception catch (e) {
      // Discovery failed – disconnect cleanly so the state machine stays sane.
      await disconnect();
      throw BluetoothConnectionException('discoverServices() failed: $e');
    }

    // ── Step 4: broadcast readiness ──────────────────────────────────────────
    _deviceReadyController.add(DeviceReadyState(
      device: device,
      services: services,
    ));
  }

  Future<void> _negotiateMtu(BluetoothDevice device) async {
    try {
      await device.requestMtu(_kTargetMtu);
    } on Exception catch (_) {
      // Non-fatal: proceed with the default MTU.
    }
  }

  Future<void> disconnect({bool intentional = false}) async {
    _intentionalDisconnect = intentional;
    _isReconnecting = false;

    await _deviceConnectionSub?.cancel();
    _deviceConnectionSub = null;

    try {
      await _connectedDevice?.disconnect();
    } on Exception catch (_) {}
  }

  // ── connection-state handling & auto-reconnect ───────────────────────────

  void _handleConnectionStateChange(BluetoothConnectionState state) {
    _connectionStateController.add(state);

    if (state == BluetoothConnectionState.disconnected &&
        !_intentionalDisconnect) {
      _scheduleReconnect();
    }
  }

  Future<void> _scheduleReconnect() async {
    if (_isReconnecting || _connectedDevice == null) return;

    _isReconnecting = true;
    int attempts = 0;
    int delaySeconds = _kInitialBackoffSeconds;

    while (attempts < _kMaxReconnectAttempts) {
      _connectionStateController.add(BluetoothConnectionState.disconnected);
      await Future<void>.delayed(Duration(seconds: delaySeconds));

      if (_intentionalDisconnect || _connectedDevice == null) {
        _isReconnecting = false;
        return;
      }

      final found = await _probeForDevice(_connectedDevice!.remoteId);

      if (found) {
        try {
          // connectToDevice will re-discover services and re-emit on
          // deviceReadyStream, so the BLoC will rebuild BleProtocolHandler.
          await connectToDevice(_connectedDevice!);
          _isReconnecting = false;
          return;
        } on Exception catch (_) {}
      }

      attempts++;
      delaySeconds = min(delaySeconds * 2, _kMaxBackoffSeconds);
    }

    _isReconnecting = false;
    _connectionStateController.addError(
      BluetoothConnectionException(
        'Auto-reconnect failed after $_kMaxReconnectAttempts attempts.',
      ),
    );
  }

  Future<bool> _probeForDevice(DeviceIdentifier targetId) async {
    final completer = Completer<bool>();
    StreamSubscription<List<ScanResult>>? probeSub;

    probeSub = FlutterBluePlus.scanResults.listen((results) {
      if (results.any((r) => r.device.remoteId == targetId)) {
        if (!completer.isCompleted) completer.complete(true);
      }
    });

    await FlutterBluePlus.startScan(timeout: _kScanDuration);

    await Future.any<void>([
      completer.future,
      Future<void>.delayed(_kScanDuration + const Duration(seconds: 1)),
    ]);

    await FlutterBluePlus.stopScan();
    await probeSub.cancel();

    return completer.isCompleted ? await completer.future : false;
  }

  // ── lifecycle ────────────────────────────────────────────────────────────────

  Future<void> dispose() async {
    _intentionalDisconnect = true;
    _isReconnecting = false;

    await _scanSub?.cancel();
    await _deviceConnectionSub?.cancel();
    await _connectionStateController.close();
    await _deviceReadyController.close();
    await _scanResultsController.close();

    try {
      await _connectedDevice?.disconnect();
    } on Exception catch (_) {}

    _connectedDevice = null;
  }
}

