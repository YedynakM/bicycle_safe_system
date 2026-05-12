// lib/features/dashboard/logic/geometry_helper.dart

import 'dart:math';

import 'package:latlong2/latlong.dart';

class GeometryHelper {
  static double calculateBearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * pi / 180.0;
    final lat2 = end.latitude * pi / 180.0;
    final dLon = (end.longitude - start.longitude) * pi / 180.0;

    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

    final bearing = atan2(y, x) * 180.0 / pi;
    return (bearing + 360.0) % 360.0;
  }

  static double shortestRotationDelta(double fromDeg, double toDeg) {
    double delta = (toDeg - fromDeg) % 360.0;
    if (delta > 180.0) delta -= 360.0;
    if (delta < -180.0) delta += 360.0;
    return delta;
  }
}
