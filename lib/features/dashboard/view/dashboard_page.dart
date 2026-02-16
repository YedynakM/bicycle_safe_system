import 'dart:async';
import 'package:bicycle_safe_system/features/bluetooth/view/scan_page.dart';
import 'package:bicycle_safe_system/features/dashboard/logic/geometry_helper.dart';
import 'package:bicycle_safe_system/features/dashboard/logic/route_service.dart';
import 'package:bicycle_safe_system/features/dashboard/logic/test_simulation_service.dart';
import 'package:bicycle_safe_system/features/dashboard/view/widgets/dashboard_map.dart';
import 'package:bicycle_safe_system/features/dashboard/view/widgets/dashboard_panel.dart';
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
  final RouteService _routeService = RouteService();

  Timer? _avgSpeedTimer;
  Timer? _autoCenterTimer;

  bool _isAutoCenterEnabled = true;
  double _currentRotation = 0;
  LatLng? _prevLocation;

  double _currentSpeed = 0;
  double _averageSpeed = 0;
  final List<double> _speedHistory = [];

  LatLng _currentLocation = const LatLng(49.8419, 24.0315);
  LatLng? _destination;
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;
  String _routingProfile = 'foot';

  @override
  void dispose() {
    _simulationService.stop();
    _avgSpeedTimer?.cancel();
    _autoCenterTimer?.cancel();
    super.dispose();
  }

  void _resetAutoCenterTimer(Duration duration) {
    _autoCenterTimer?.cancel();
    _autoCenterTimer = Timer(duration, () {
      if (mounted) {
        setState(() {
          _isAutoCenterEnabled = true;
          _mapController.move(
            _currentLocation,
            _mapController.camera.zoom,
          );
          _mapController.rotate(_currentRotation);
        });
      }
    });
  }

  void _onInteractionStart() {
    if (_isAutoCenterEnabled) {
      setState(() => _isAutoCenterEnabled = false);
    }
    _autoCenterTimer?.cancel();
  }

  void _onMapPositionChanged(MapCamera position, bool hasGesture) {
    if (hasGesture) {
      _resetAutoCenterTimer(const Duration(seconds: 10));
    }
  }

  Future<void> _onMapTap(TapPosition tapPosition, LatLng point) async {
    setState(() {
      _destination = point;
      _isAutoCenterEnabled = false;
    });
    await _fetchRoute(point);
  }

  Future<void> _fetchRoute(LatLng dest) async {
    setState(() => _isLoadingRoute = true);
  
    _simulationService.stop();

    final realRoute = await _routeService.getRoute(
      _currentLocation,
      dest,
      profile: _routingProfile,
    );

    if (!mounted) return;

    setState(() {
      _routePoints = realRoute.isNotEmpty 
          ? realRoute 
          : [_currentLocation, dest];
      _isLoadingRoute = false;
      
      _isAutoCenterEnabled = true;
      _prevLocation = null;
    });

    if (_routePoints.length > 1) {
      final initialBearing = GeometryHelper.calculateBearing(
        _routePoints[0], 
        _routePoints[1],
      );
      _currentRotation = -initialBearing;
      
      _mapController.move(
        _currentLocation, 
        _mapController.camera.zoom,
      );
      _mapController.rotate(_currentRotation);
    }

    if (_currentSpeed > 0 && _routePoints.isNotEmpty) {
      _startSimulation();
    }
  }

  void _toggleRoutingMode() {
    setState(() {
      _routingProfile = _routingProfile == 'bike' ? 'foot' : 'bike';
    });
    if (_destination != null) {
      _fetchRoute(_destination!);
    }
  }

  void _updateSpeed(double value) {
    setState(() => _currentSpeed = double.parse(value.toStringAsFixed(1)));
    if (_routePoints.isNotEmpty) _startSimulation();
  }

  void _startAverageSpeedCalculation() {
    if (_avgSpeedTimer != null && _avgSpeedTimer!.isActive) return;
    _avgSpeedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _speedHistory.add(_currentSpeed);
        if (_speedHistory.isNotEmpty) {
          _averageSpeed =
              _speedHistory.reduce((a, b) => a + b) / _speedHistory.length;
        }
      });
    });
  }

  void _startSimulation() {
    _startAverageSpeedCalculation();

    _simulationService.startSimulation(
      speedKmH: _currentSpeed,
      route: _routePoints,
      onPositionChanged: (newPos) {
        double newRotation = _currentRotation;

        if (_prevLocation != null) {
          final double bearing = GeometryHelper.calculateBearing(
            _prevLocation!,
            newPos,
          );
          newRotation = -bearing;
        }

        setState(() {
          _prevLocation = _currentLocation;
          _currentLocation = newPos;
          _currentRotation = newRotation;
        });

        if (_isAutoCenterEnabled) {
          _mapController.move(newPos, _mapController.camera.zoom);
          _mapController.rotate(newRotation);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final panelHeight =
        (MediaQuery.of(context).size.height * 0.45).clamp(260.0, 380.0);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'Bike Monitor',
              style: TextStyle(shadows: [Shadow(blurRadius: 5)]),
            ),
            if (_isLoadingRoute) ...[
              const SizedBox(width: 10),
              const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            ]
          ],
        ),
        actions: [
          if (!_isAutoCenterEnabled)
            IconButton(
              icon: const Icon(Icons.gps_fixed, color: Colors.redAccent),
              onPressed: () {
                setState(() => _isAutoCenterEnabled = true);
                _mapController.move(
                  _currentLocation,
                  _mapController.camera.zoom,
                );
                _mapController.rotate(_currentRotation);
                _autoCenterTimer?.cancel();
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          DashboardMap(
            mapController: _mapController,
            currentLocation: _currentLocation,
            destination: _destination,
            routePoints: _routePoints,
            onTap: _onMapTap,
            onMapPositionChanged: _onMapPositionChanged,
            onInteractionStart: _onInteractionStart,
          ),
          Positioned(
            top: 100,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'mode_toggle',
              onPressed: _toggleRoutingMode,
              backgroundColor: Colors.black87,
              child: Icon(
                _routingProfile == 'bike'
                    ? Icons.directions_bike
                    : Icons.directions_walk,
                color: _routingProfile == 'bike'
                    ? Colors.blueAccent
                    : Colors.orangeAccent,
              ),
            ),
          ),
          DashboardPanel(
            panelHeight: panelHeight,
            averageSpeed: _averageSpeed,
            currentSpeed: _currentSpeed,
            onSpeedChanged: _updateSpeed,
            onBluetoothPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (context) => const ScanPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
