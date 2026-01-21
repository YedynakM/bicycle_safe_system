import 'dart:async';
import 'package:latlong2/latlong.dart';

class TestSimulationService {
  Timer? _timer;
  List<LatLng> _currentRoute = [];
  int _targetNodeIndex = 0;
  LatLng? _currentPosition;
  final Distance _distanceCalculator = const Distance();

  void startSimulation({
    required double speedKmH,
    required List<LatLng> route, 
    required void Function(LatLng) onPositionChanged,
  }) {
    if (_currentRoute != route) {
      _currentRoute = route;
      _targetNodeIndex = 1;
      _currentPosition = route.isNotEmpty ? route[0] : null;
    }
    
    _timer?.cancel();
    
    if (speedKmH <= 0 || _currentRoute.isEmpty || _currentRoute.length < 2)
    {
      return;
    }

    const int updateIntervalMs = 20; 

    _timer = Timer.periodic(const Duration(milliseconds: updateIntervalMs), 
    (timer) {
      if (_currentPosition == null) return;

      final double speedMetersPerSecond = speedKmH / 3.6;
      double distanceToTravel = 
      speedMetersPerSecond * (updateIntervalMs / 1000);

      while (distanceToTravel > 0 && _targetNodeIndex < _currentRoute.length) {
        final LatLng targetPoint = _currentRoute[_targetNodeIndex];
        final double distToNextPoint = 
        _distanceCalculator.as
        (LengthUnit.Meter, _currentPosition!, targetPoint);

        if (distToNextPoint > distanceToTravel) {
          final double fraction = distanceToTravel / distToNextPoint;
          
          final double newLat = _currentPosition!.latitude + 
          (targetPoint.latitude - _currentPosition!.latitude) * fraction;
          final double newLng = _currentPosition!.longitude + 
          (targetPoint.longitude - _currentPosition!.longitude) * fraction;
          
          _currentPosition = LatLng(newLat, newLng);
          distanceToTravel = 0;
        } else {
          _currentPosition = targetPoint;
          distanceToTravel -= distToNextPoint;
          _targetNodeIndex++;
        }
      }

      onPositionChanged(_currentPosition!);

      if (_targetNodeIndex >= _currentRoute.length) {
        stop();
      }
    });
  }

  void stop() {
    _timer?.cancel();
  }
}
