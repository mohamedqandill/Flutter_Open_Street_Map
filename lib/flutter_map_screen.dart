import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_maps/utils/location_services.dart';
import 'package:flutter_maps/utils/maps_services.dart';
import 'package:latlong2/latlong.dart';

class FlutterMapScreen extends StatefulWidget {
  const FlutterMapScreen({super.key});

  @override
  State<FlutterMapScreen> createState() => _FlutterMapScreenState();
}

class _FlutterMapScreenState extends State<FlutterMapScreen> {
  late LocationService locationService;
  late MapController mapController;
  late MapsApiServices mapsApiServices;
  List<Marker> markers = [];
  late LatLng currentLocation;
  List<LatLng> trackRoutes = [];
  bool isLoading = false;

  @override
  void initState() {
    locationService = LocationService();
    mapsApiServices = MapsApiServices();
    mapController = MapController();
    updateMyLocation();
    setState(() {});
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          initialCenter: const LatLng(30.552435364641454, 31.006551321191935),
          initialZoom: 15,
          onTap: (tapPosition, point) => addDestinationMarker(point),
        ),
        children: [
          TileLayer(
            // Bring your own tiles
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            // For demonstration only
            userAgentPackageName:
                'com.example.flutter_map', // Add your app identifier
            // And many more recommended properties!
          ),
          MarkerLayer(markers: markers),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (trackRoutes.isNotEmpty)
            PolylineLayer(polylines: [
              Polyline(points: trackRoutes, color: Colors.red, strokeWidth: 5.0)
            ])
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          mapController.move(currentLocation, 15);
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }

  updateMyLocation() async {
    await locationService.checkAndRequestLocationService();
    var permissionGranted = await locationService.checkAndRequestPermission();
    if (permissionGranted) {
      LocationService.getRealTimeLocationData(
        (locationData) {
          var latLng = LatLng(locationData.latitude!, locationData.longitude!);

          currentLocation = latLng;
          setMyLocationMarker(latLng);
          updateMyCamera(latLng);
        },
      );
    } else {
      //TODO
    }
  }

  setMyLocationMarker(LatLng latLng) {
    setState(() {
      markers.add(Marker(point: latLng, child: const Icon(Icons.my_location)));
    });
  }

  updateMyCamera(LatLng latLng) {
    mapController.move(latLng, 15);
  }

  addDestinationMarker(LatLng point) async {
    setState(() {
      markers =
          markers.where((marker) => marker.point == currentLocation).toList();
    });
    setState(() {
      markers.add(Marker(
          point: point,
          child: const Icon(
            Icons.location_on,
            color: Colors.orange,
          )));
    });
    setState(() {
      isLoading = true;
    });
    final newRoutes = await mapsApiServices.getRoute(currentLocation, point);
    setState(() {
      trackRoutes = newRoutes;
      log("trackroutes=>>${trackRoutes.length}");
      isLoading = false;
    });
  }
}
