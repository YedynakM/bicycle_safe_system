import 'dart:async';
import 'package:latlong2/latlong.dart';

class TestSimulationService {
  Timer? _timer;
  LatLng? _currentPosition;
  
  void startSimulation({
    required double speedKmH,
    required LatLng startPos,
    LatLng? destination, 
    required Function(LatLng) onPositionChanged
  }) {
    _timer?.cancel();
    _currentPosition = startPos;
    
    if (speedKmH <= 0) return;

    int milliseconds = (1000 / speedKmH * 20).round(); 
    if (milliseconds < 50) milliseconds = 50;

    _timer = Timer.periodic(Duration(milliseconds: milliseconds), (timer) {
      if (destination != null && _currentPosition != null) {
        final double latDiff = destination.latitude - _currentPosition!.latitude;
        final double lngDiff = destination.longitude - _currentPosition!.longitude;
        
        const double step = 0.0001;
        
        final double newLat = _currentPosition!.latitude + (latDiff > 0 ? step : -step);
        final double newLng = _currentPosition!.longitude + (lngDiff > 0 ? step : -step);

        if ((newLat - destination.latitude).abs() < step && (newLng - destination.longitude).abs() < step) {
           _timer?.cancel();
        } else {
           _currentPosition = LatLng(newLat, newLng);
           onPositionChanged(_currentPosition!);
        }
      } else {
        final double newLat = _currentPosition!.latitude + 0.0001;
        final double newLng = _currentPosition!.longitude + 0.0001;
        _currentPosition = LatLng(newLat, newLng);
        onPositionChanged(_currentPosition!);
      }
    });
  }

  void stop() {
    _timer?.cancel();
  }
}
