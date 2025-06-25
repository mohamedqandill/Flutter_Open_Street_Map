import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

import 'constants.dart';

class MapsApiServices {
  Dio dio = Dio();

  Future<List<LatLng>> getRoute(
      LatLng currentLocation, LatLng destination) async {
    try {
      List<LatLng> trackRoutes = [];

      final startCoord =
          "${currentLocation.longitude},${currentLocation.latitude}";
      final endCoord = "${destination.longitude},${destination.latitude}";
      print(currentLocation.latitude);
      var response = await dio.get(
          "https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey&start=$startCoord&end=$endCoord");
      if (response.statusCode == 200) {
        trackRoutes = _parseRoute(response.data);
      } else {
        log("Unexpected status: ${response.statusCode}");
      }
      return trackRoutes;
    } catch (e) {
      log("Error==>${e.toString()}");
      rethrow;
    }
  }

  List<LatLng> _parseRoute(Map<String, dynamic> json) {
    List<LatLng> routePoints = [];

    final features = json['features'] as List;
    if (features.isEmpty) return routePoints;

    final geometry = features[0]['geometry'];
    final coordinates = geometry['coordinates'] as List;

    for (var point in coordinates) {
      final lon = point[0];
      final lat = point[1];
      routePoints.add(LatLng(lat, lon));
    }

    return routePoints;
  }
}
