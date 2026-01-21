import 'dart:async';
import 'package:bicycle_safe_system/app/theme/app_colors.dart';
import 'package:bicycle_safe_system/features/dashboard/logic/test_simulation_service.dart';
import 'package:bicycle_safe_system/features/dashboard/view/widgets/status_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final MapController _mapController = MapController();
  final TestSimulationService _simulationService = TestSimulationService();
  
  Timer? _avgSpeedTimer;

  double _currentSpeed = 0.0;
  double _averageSpeed = 0.0;
  final List<double> _speedHistory = [];

  LatLng _currentLocation = const LatLng(49.8419, 24.0315);
  LatLng? _destination;
  List<LatLng> _routePoints = [];

  @override
  void dispose() {
    _simulationService.stop();
    _avgSpeedTimer?.cancel();
    super.dispose();
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _destination = point;
      _routePoints = [_currentLocation, point];
    });
    if (_currentSpeed > 0) _startSimulation();
  }

  void _updateSpeed(double value) {
    final double roundedValue = double.parse(value.toStringAsFixed(1));
    setState(() => _currentSpeed = roundedValue);
    _startSimulation();
  }

  void _startAverageSpeedCalculation() {
    if (_avgSpeedTimer != null && _avgSpeedTimer!.isActive) return;
    
    _avgSpeedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _speedHistory.add(_currentSpeed);
        if (_speedHistory.isNotEmpty) {
           double total = _speedHistory.reduce((a, b) => a + b);
           _averageSpeed = total / _speedHistory.length;
        }
      });
    });
  }

  void _startSimulation() {
    _startAverageSpeedCalculation();
    
    _simulationService.startSimulation(
      speedKmH: _currentSpeed,
      startPos: _currentLocation,
      destination: _destination,
      onPositionChanged: (newPos) {
        setState(() {
          _currentLocation = newPos;
          if (_destination != null) _routePoints = [newPos, _destination!];
        });
        _mapController.move(newPos, _mapController.camera.zoom);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double panelHeight = (screenSize.height * 0.45).clamp(260.0, 380.0);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Bike Monitor', style: TextStyle(shadows: [Shadow(blurRadius: 5)])),
        actions: const [
           StatusIndicator(isConnected: false),
           SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 17,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.bicycle_safe_system',
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(points: _routePoints, strokeWidth: 4.0, color: Colors.blueAccent),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.navigation, color: AppColors.primary, size: 40),
                  ),
                  if (_destination != null)
                     Marker(
                      point: _destination!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                    ),
                ],
              ),
            ],
          ),
          
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: panelHeight, 
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.85), 
                    Colors.transparent
                  ], 
                  stops: const [0.6, 1.0],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final availableHeight = constraints.maxHeight;
                      final double reservedHeight = 110.0; 
                      final double availableForGauges = (availableHeight - reservedHeight).clamp(0.0, 200.0);

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            height: availableForGauges,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildGauge(
                                  value: _averageSpeed, 
                                  max: 60.0, 
                                  color: Colors.orangeAccent, 
                                  label: _averageSpeed.toStringAsFixed(1), 
                                  subLabel: "AVG KM/H",
                                  isSmall: true,
                                ),
                                _buildGauge(
                                  value: _currentSpeed, 
                                  max: 60.0, 
                                  color: AppColors.primary, 
                                  label: _currentSpeed.toStringAsFixed(0), 
                                  subLabel: "KM/H",
                                ),
                              ],
                            ),
                          ),
                          
                          const Spacer(),

                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 350),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.yellow.withValues(alpha: 0.7), width: 1),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text("TEST SIMULATION SPEED", 
                                      style: TextStyle(color: Colors.yellow, fontSize: 9)),
                                  ),
                                  SizedBox(
                                    height: 30, 
                                    child: Slider(
                                      value: _currentSpeed,
                                      min: 0,
                                      max: 60,
                                      activeColor: AppColors.primary,
                                      onChanged: _updateSpeed,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 10),

                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 300, maxHeight: 45),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.security),
                                label: const Text('ARM SYSTEM'),
                                style: ElevatedButton.styleFrom(
                                   backgroundColor: Colors.redAccent,
                                   foregroundColor: Colors.white,
                                   elevation: 5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGauge({
    required double value, 
    required double max, 
    required Color color, 
    required String label, 
    required String subLabel,
    bool isSmall = false,
  }) {
    return AspectRatio(
      aspectRatio: 1, 
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth < constraints.maxHeight 
              ? constraints.maxWidth 
              : constraints.maxHeight;
              
          if (size < 40) return const SizedBox(); 

          final fontSize = size * 0.3; 
          final strokeWidth = size * 0.08; 

          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: size * 0.8,
                height: size * 0.8,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: 1.0,
                      color: Colors.white.withValues(alpha: 0.12),
                      strokeWidth: strokeWidth,
                    ),
                    CircularProgressIndicator(
                      value: (value / max).clamp(0.0, 1.0),
                      color: color,
                      strokeWidth: strokeWidth,
                      strokeCap: StrokeCap.round,
                    ),
                    Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: const [Shadow(blurRadius: 10, color: Colors.black)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: size * 0.05),
              Text(subLabel, 
                style: TextStyle(
                  color: Colors.grey, 
                  fontSize: (size * 0.12).clamp(8.0, 14.0),
                  fontWeight: FontWeight.bold
                )
              ),
            ],
          );
        }
      ),
    );
  }
}
