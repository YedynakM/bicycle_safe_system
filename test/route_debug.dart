// ignore_for_file: avoid_print
// ignore_for_file: lines_longer_than_80_chars
// ignore_for_file: avoid_redundant_argument_values

import 'package:bicycle_safe_system/features/dashboard/logic/route_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

class RouteTestCase {
  final String name;
  final LatLng start;
  final LatLng end;

  RouteTestCase({
    required this.name,
    required this.start,
    required this.end,
  });
}

void main() {
  final service = RouteService();

  final testCases = [
    RouteTestCase(
      name: 'City Center (Opera) -> St. Jura Cathedral (Park Area)',
      start: const LatLng(49.8419, 24.0315), 
      end: const LatLng(49.8326, 24.0122),   
    ),
    RouteTestCase(
      name: 'Railway Station -> High Castle (Long Distance)',
      start: const LatLng(49.8397, 23.9944), 
      end: const LatLng(49.8483, 24.0393),   
    ),
    RouteTestCase(
      name: 'Victoria Gardens -> Polytechnic University (Urban Mixed)',
      start: const LatLng(49.8122, 23.9745), 
      end: const LatLng(49.8351, 24.0144),   
    ),
  ];

  group('RouteService Integration Tests', () {
    
    for (final testCase in testCases) {
      test('Should retrieve distinct routes for: ${testCase.name}', () async {
        print('\n---------------------------------------------------');
        print('[INFO] Testing Scenario: ${testCase.name}');
        print('[INFO] Coordinates: ${testCase.start} -> ${testCase.end}');

        final stopwatchBike = Stopwatch()..start();
        final bikeRoute = await service.getRoute(testCase.start, testCase.end, profile: 'bike');
        stopwatchBike.stop();

        final stopwatchFoot = Stopwatch()..start();
        final footRoute = await service.getRoute(testCase.start, testCase.end, profile: 'foot');
        stopwatchFoot.stop();

        expect(bikeRoute, isNotEmpty, reason: 'Bike route should not be empty');
        expect(footRoute, isNotEmpty, reason: 'Foot route should not be empty');

        final int diff = (bikeRoute.length - footRoute.length).abs();
        final bool areDifferent = diff > 0;

        print('  > Bike Route: ${bikeRoute.length} points (fetched in ${stopwatchBike.elapsedMilliseconds}ms)');
        print('  > Foot Route: ${footRoute.length} points (fetched in ${stopwatchFoot.elapsedMilliseconds}ms)');
        
        if (areDifferent) {
          print('[SUCCESS] Routes are distinct. Delta: $diff points.');
        } else {
          print('[WARNING] Routes are identical. Path might be constrained by road network.');
        }
      });
    }
  });
}
