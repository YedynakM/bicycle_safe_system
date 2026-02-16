import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DashboardMap extends StatelessWidget {
  const DashboardMap({
    required this.mapController,
    required this.currentLocation,
    required this.routePoints,
    required this.onTap,
    required this.onMapPositionChanged,
    required this.onInteractionStart,
    this.destination,
    super.key,
  });

  final MapController mapController;
  final LatLng currentLocation;
  final LatLng? destination;
  final List<LatLng> routePoints;
  final void Function(MapCamera, bool) onMapPositionChanged;
  final void Function(TapPosition, LatLng) onTap;
  final VoidCallback onInteractionStart;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => onInteractionStart(),
      child: FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: currentLocation,
        initialZoom: 15,
        onTap: onTap,
        onPositionChanged: (position, hasGesture) {

        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.bicycle_safe_system',
        ),
        if (routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints,
                strokeWidth: 4,
                color: Colors.blueAccent,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            Marker(
              point: currentLocation,
              width: 40,
              height: 40,
              child: const Icon(
                Icons.navigation,
                color: Colors.blue,
                size: 30,
                shadows: [Shadow(color: Colors.black54, blurRadius: 5)],
              ),
            ),
            if (destination != null)
              Marker(
                point: destination!,
                width: 40,
                height: 40,
                child: const Icon(Icons.location_on, 
                color: Colors.red, size: 40),
              ),
          ],
        ),
      ],
    )
    );
  }
}
