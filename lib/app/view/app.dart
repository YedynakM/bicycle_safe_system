// lib/app/view/app.dart
import 'package:bicycle_safe_system/app/theme/app_theme.dart'; 
import 'package:bicycle_safe_system/features/dashboard/view/dashboard_page.dart';
import 'package:flutter/material.dart';

class BikeApp extends StatelessWidget {
  const BikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bicycle Safe System',
      debugShowCheckedModeBanner: false, 
      theme: AppTheme.darkTheme, 
      home: const DashboardPage(),
    );
  }
}
