import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class AppBluetoothService {
  Stream<List<ScanResult>> get scanResults =>
   FlutterBluePlus.scanResults;
  Stream<BluetoothAdapterState> get adapterState =>
   FlutterBluePlus.adapterState;
  Stream<bool> get isScanning =>
   FlutterBluePlus.isScanning;

  Future<void> startScan() async {
    if (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
      try {
        await FlutterBluePlus.turnOn();
      } catch (e) {
        throw Exception('Bluetooth is off');
      }
    }

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
      androidUsesFineLocation: true,
    );
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    await device.connect(license: License.free, autoConnect: true, mtu: null);
  }

  Future<void> disconnectFromDevice(BluetoothDevice device) async {
    await device.disconnect();
  }
}
