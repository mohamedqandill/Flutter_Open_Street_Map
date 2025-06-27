import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_maps/utils/models/PlacesAutoCompleteModel.dart';
import 'package:latlong2/latlong.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'constants.dart';

class MapsApiServices {
  Dio dio = Dio();
  MapsApiServices() {
    dio.options = BaseOptions(
      connectTimeout: const Duration(minutes: 1),
      receiveTimeout: const Duration(minutes: 1),
      sendTimeout: const Duration(minutes: 1),
    );
    dio.interceptors.add(PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90,
        enabled: kDebugMode,
        filter: (options, args) {
          // don't print requests with uris containing '/posts'
          if (options.path.contains('/posts')) {
            return false;
          }
          // don't print responses with unit8 list data
          return !args.isResponse || !args.hasUint8ListData;
        }));
  }

  Future<Map<String, dynamic>> getRoute(
      LatLng currentLocation, LatLng destination) async {
    try {
      List<LatLng> trackRoutes = [];
      List<dynamic> segments = [];

      final startCoord =
          "${currentLocation.longitude},${currentLocation.latitude}";
      final endCoord = "${destination.longitude},${destination.latitude}";
      var response = await dio.get(
          "https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey&start=$startCoord&end=$endCoord");

      if (response.statusCode == 200) {
        final data = response.data;
        trackRoutes = _parseRoute(data);
        segments = _parseSegments(data);
      } else {
        log("Unexpected status: ${response.statusCode}");
      }

      return {
        'routePoints': trackRoutes,
        'segments': segments,
      };
    } catch (e) {
      log("Error==>${e.toString()}");
      rethrow;
    }
  }

  List<dynamic> _parseSegments(Map<String, dynamic> json) {
    final features = json['features'] as List;
    if (features.isEmpty) return [];

    final segments = features[0]['properties']['segments'];
    return segments ?? [];
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

  getPlaces(String query) async {
    try {
      // var encodedQuery = Uri.encodeComponent(query);
      var response = await dio.get(
          "https://api.openrouteservice.org/geocode/autocomplete?api_key=$apiKey&text=$query");
      if (response.statusCode == 200) {
        var data = PlacesAutoCompleteModel.fromJson(response.data);
        List<Features>? places = data.features;
        print("places=>>${data.features!.length}");
        return places;
      }
    } catch (e) {
      print("Error=>${e.toString()}");
      rethrow;
    }
  }
}
