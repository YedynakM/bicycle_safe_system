// lib/app/view/app.dart
import 'package:bicycle_safe_system/app/theme/app_theme.dart';
import 'package:bicycle_safe_system/features/bluetooth/bloc/bluetooth_bloc.dart';
import 'package:bicycle_safe_system/features/bluetooth/logic/bluetooth_service.dart';
import 'package:bicycle_safe_system/features/dashboard/bloc/dashboard_bloc.dart';
import 'package:bicycle_safe_system/features/dashboard/view/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BikeApp extends StatelessWidget {
  const BikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppBluetoothService>(
          create: (_) => AppBluetoothService(),
        ),
      ],
      child: Builder(
        builder: (context) {
          final bluetoothBloc = BluetoothBloc(
            bluetoothService: context.read<AppBluetoothService>(),
          );

          return MultiBlocProvider(
            providers: [
              BlocProvider<BluetoothBloc>(
                create: (_) => bluetoothBloc,
              ),
              BlocProvider<DashboardBloc>(
                create: (_) => DashboardBloc(bluetoothBloc: bluetoothBloc),
              ),
            ],
            child: MaterialApp(
              title: 'Bicycle Safe System',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.darkTheme,
              home: const DashboardPage(),
            ),
          );
        },
      ),
    );
  }
}
