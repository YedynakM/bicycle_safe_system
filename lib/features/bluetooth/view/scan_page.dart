// lib/features/bluetooth/view/scan_page.dart
import 'package:bicycle_safe_system/features/bluetooth/bloc/bluetooth_bloc.dart';
import 'package:bicycle_safe_system/features/bluetooth/bloc/bluetooth_event.dart';
import 'package:bicycle_safe_system/features/bluetooth/bloc/bluetooth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

  Future<bool> _requestPermissions(BuildContext context) async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    final granted = statuses.values.any((s) => s.isGranted);

    if (!granted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bluetooth permissions required.')),
      );
    }
    return granted;
  }

  @override
  Widget build(BuildContext context) {
    // Uses the BluetoothBloc provided higher in the tree (e.g. from app.dart).
    // This is the ONLY correct way to share state with DashboardPage.
    return BlocConsumer<BluetoothBloc, BluetoothBlocState>(
      listener: (context, state) {
        if (state is BluetoothConnected) {
          // Pop back to the dashboard automatically once connected.
          if (Navigator.of(context).canPop()) Navigator.of(context).pop();
        } else if (state is BluetoothError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      },
      builder: (context, state) {
        final bloc = context.read<BluetoothBloc>();
        final isScanning = state is BluetoothScanning;
        final isConnecting = state is BluetoothConnecting;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Device Search'),
            actions: [
              if (state is BluetoothConnected)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Chip(
                    avatar: const Icon(Icons.bluetooth_connected,
                        size: 16, color: Colors.white),
                    label: Text(
                      state.device.platformName.isNotEmpty
                          ? state.device.platformName
                          : state.device.remoteId.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    backgroundColor: Colors.green.shade700,
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: isScanning || isConnecting
                          ? null
                          : () async {
                              final ok =
                                  await _requestPermissions(context);
                              if (ok && context.mounted) {
                                bloc.add(const StartScan());
                              }
                            },
                      icon: const Icon(Icons.search),
                      label: const Text('Scan'),
                    ),
                    ElevatedButton.icon(
                      onPressed: isScanning
                          ? () => bloc.add(const Disconnect())
                          : null,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade100,
                      ),
                    ),
                  ],
                ),
              ),

              // Status banner while connecting
              if (isConnecting)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text('Connecting & discovering services…'),
                    ],
                  ),
                ),

              Expanded(
                child: Builder(builder: (context) {
                  if (state is! BluetoothScanning ||
                      state.results.isEmpty) {
                    return Center(
                      child: Text(
                        isScanning ? 'Scanning…' : 'No devices found.',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  final results = state.results
                      .where((r) => r.device.platformName.isNotEmpty)
                      .toList();

                  if (results.isEmpty) {
                    return const Center(
                      child: Text(
                        'No named devices found.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final result = results[index];
                      final device = result.device;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: const Icon(Icons.bluetooth),
                          title: Text(device.platformName),
                          subtitle: Text(device.remoteId.toString()),
                          trailing: Text('${result.rssi} dBm'),
                          onTap: () => bloc.add(ConnectToDevice(device)),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}
