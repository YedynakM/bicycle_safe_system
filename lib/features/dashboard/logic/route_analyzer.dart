// lib/features/dashboard/logic/route_analyzer.dart

import 'dart:math';

import 'package:bicycle_safe_system/features/dashboard/logic/ble_protocol_handler.dart';
import 'package:bicycle_safe_system/features/dashboard/logic/geometry_helper.dart';
import 'package:latlong2/latlong.dart';

enum ManeuverRecommendation { none, turnLeft, turnRight }

class RouteAnalyzer {
  static const double _turnThresholdDeg = 30.0;
  static const double _releaseThresholdDeg = 12.0;
  static const Distance _dist = Distance();

  ManeuverRecommendation analyzeUpcomingManeuver(
    LatLng currentPos,
    List<LatLng> route,
    double speedKmh,
  ) {
    if (route.length < 2 || speedKmh <= 0) return ManeuverRecommendation.none;

    final int nearestIdx = _nearestRouteIndex(currentPos, route);
    if (nearestIdx < 0 || nearestIdx >= route.length - 1) {
      return ManeuverRecommendation.none;
    }

    final double speedMs = speedKmh / 3.6;
    final double dynamicLookAhead = max(12.0, speedMs * 4.0);

    final LatLng lookAheadPoint =
        _pointAheadOnRoute(nearestIdx, route, dynamicLookAhead);

    final double currentBearing =
        GeometryHelper.calculateBearing(currentPos, route[nearestIdx + 1]);
    final double futureBearing =
        GeometryHelper.calculateBearing(currentPos, lookAheadPoint);

    final double delta = _bearingDelta(currentBearing, futureBearing);

    if (delta > _turnThresholdDeg) return ManeuverRecommendation.turnRight;
    if (delta < -_turnThresholdDeg) return ManeuverRecommendation.turnLeft;
    return ManeuverRecommendation.none;
  }

  bool isTurnCompleted(
    LatLng currentPos,
    List<LatLng> route,
  ) {
    if (route.length < 2) return true;
    final int nearestIdx = _nearestRouteIndex(currentPos, route);
    if (nearestIdx < 0 || nearestIdx >= route.length - 1) return true;

    const double releaseLookAhead = 4.0;

    final LatLng releasePoint =
        _pointAheadOnRoute(nearestIdx, route, releaseLookAhead);

    final double currentBearing =
        GeometryHelper.calculateBearing(currentPos, route[nearestIdx + 1]);
    final double nearFutureBearing =
        GeometryHelper.calculateBearing(currentPos, releasePoint);

    final double delta =
        _bearingDelta(currentBearing, nearFutureBearing).abs();
    return delta < _releaseThresholdDeg;
  }

  static LightCommand? recommendationToCommand(ManeuverRecommendation rec) {
    switch (rec) {
      case ManeuverRecommendation.turnLeft:
        return LightCommand.leftTurn;
      case ManeuverRecommendation.turnRight:
        return LightCommand.rightTurn;
      case ManeuverRecommendation.none:
        return null;
    }
  }

  int _nearestRouteIndex(LatLng pos, List<LatLng> route) {
    double minDist = double.infinity;
    int idx = 0;
    for (int i = 0; i < route.length - 1; i++) {
      final double d = _dist.as(LengthUnit.Meter, pos, route[i]);
      if (d < minDist) {
        minDist = d;
        idx = i;
      }
    }
    return idx;
  }

  LatLng _pointAheadOnRoute(
      int startIdx, List<LatLng> route, double metersAhead) {
    double remaining = metersAhead;
    for (int i = startIdx; i < route.length - 1; i++) {
      final double segLen =
          _dist.as(LengthUnit.Meter, route[i], route[i + 1]);
      if (segLen >= remaining) {
        final double fraction = remaining / segLen;
        final double lat = route[i].latitude +
            (route[i + 1].latitude - route[i].latitude) * fraction;
        final double lng = route[i].longitude +
            (route[i + 1].longitude - route[i].longitude) * fraction;
        return LatLng(lat, lng);
      }
      remaining -= segLen;
    }
    return route.last;
  }

  double _bearingDelta(double from, double to) {
    double delta = (to - from) % 360.0;
    if (delta > 180.0) delta -= 360.0;
    if (delta < -180.0) delta += 360.0;
    return delta;
  }
}
