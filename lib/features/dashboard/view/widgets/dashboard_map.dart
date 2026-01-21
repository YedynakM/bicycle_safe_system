import 'package:bicycle_safe_system/app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DashboardMap extends StatelessWidget {
  const DashboardMap({
    required this.mapController,
    required this.currentLocation,
    required this.onTap,
    this.destination,
    this.routePoints = const [],
    super.key,
  });

  final MapController mapController;
  final LatLng currentLocation;
  final LatLng? destination;
  final List<LatLng> routePoints;
  final void Function(TapPosition, LatLng) onTap;

@override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: currentLocation,
        initialZoom: 17,
        onTap: onTap,
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
                strokeWidth: 5,
                color: Colors.blueAccent.withValues(alpha: 0.7),
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            Marker(
              point: currentLocation,
              width: 40,
              height: 40,
              child: const Icon(Icons.navigation, 
              color: AppColors.primary, size: 40),
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
    );
  }
}
