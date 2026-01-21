import 'package:bicycle_safe_system/features/bluetooth/logic/bluetooth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  
  final AppBluetoothService _bleService = AppBluetoothService();

  Future<void> _checkPermissionsAndScan() async {
    final Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses.values.any((status) => status.isGranted)) {
      try {
        await _bleService.startScan();
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar
           (SnackBar(content: Text(e.toString())));
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissions required!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Device Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _checkPermissionsAndScan,
                  icon: const Icon(Icons.search),
                  label: const Text('Scan'),
                ),
                ElevatedButton.icon(
                  onPressed: _bleService.stopScan,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                  style: ElevatedButton.styleFrom
                  (backgroundColor: Colors.red.shade100),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ScanResult>>(
              stream: _bleService.scanResults,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No devices found'));
                }

                final results = snapshot.data!;
                
                return ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final result = results[index];
                    final device = result.device;
                    
                    if (device.platformName.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Card(
                      margin: const EdgeInsets.
                      symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.bluetooth),
                        title: Text(device.platformName),
                        subtitle: Text(device.remoteId.toString()),
                        trailing: Text('${result.rssi} dBm'),
                        onTap: () => _bleService.connectToDevice(device),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
