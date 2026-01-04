import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';


class RouteService {
  //Implemented option to change between bike or foot(TODO).
  //Changed server to openstreetmap.de which supports both profiles properly.
  final String _bikeUrl = 'https://routing.openstreetmap.de/routed-bike/route/v1/driving';
  final String _footUrl = 'https://routing.openstreetmap.de/routed-foot/route/v1/driving';

  Future<List<LatLng>> getRoute(LatLng start, 
  LatLng end, {String profile = 'bike'}) 
  async {
    final String baseUrl = profile == 'foot' ? _footUrl : _bikeUrl;
    final String url = '$baseUrl/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';

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
