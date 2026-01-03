import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';


class RouteService {
 final String _baseUrl = 'http://router.project-osrm.org/route/v1/bike';
  //TODO: Make an option to change from bike to car or foot, 
  //but i don't think it is needed, because program is for
  //bicycles or E-scooters.

  Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    final String url = '$_baseUrl/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        if (data['routes'] == null || (data['routes'] as List).isEmpty) {
          return [];
        }
        

        final routes = data['routes'] as List;
        final geometry = routes[0]['geometry'] as Map<String, dynamic>;
        final coordinates = geometry['coordinates'] as List;

        return coordinates.map((coord) {
          final point = coord as List;
          return LatLng(
            (point[1] as num).toDouble(), 
            (point[0] as num).toDouble(),
          );
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
