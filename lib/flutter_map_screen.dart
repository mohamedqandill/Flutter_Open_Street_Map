import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_maps/utils/location_services.dart';
import 'package:flutter_maps/utils/maps_services.dart';
import 'package:flutter_maps/utils/models/PlacesAutoCompleteModel.dart';
import 'package:flutter_maps/widgets/custom_list_view.dart';
import 'package:flutter_maps/widgets/custom_text_field.dart';
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
  late SearchController searchController;
  List<LatLng> trackRoutes = [];
  List<Features> places = [];
  late TextEditingController textEditingController;
  bool isLoading = false;

  @override
  void initState() {
    locationService = LocationService();
    mapsApiServices = MapsApiServices();
    searchController = SearchController();
    textEditingController = TextEditingController();
    getAutoCompletePlaces();
    mapController = MapController();
    updateMyLocation();
    setState(() {});
    super.initState();
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter:
                  const LatLng(30.552435364641454, 31.006551321191935),
              initialZoom: 15,
              onTap: (tapPosition, point) => addDestinationMarker(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.flutter_map',
              ),
              MarkerLayer(markers: markers),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (trackRoutes.isNotEmpty)
                PolylineLayer(polylines: [
                  Polyline(
                      points: trackRoutes, color: Colors.red, strokeWidth: 5.0)
                ])
            ],
          ),
          Positioned(
              top: 50,
              right: 20,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomTextField(
                    textEditingController: textEditingController,
                  ),
                  CustomListView(
                    places: places,
                  )
                ],
              ))
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

  getAutoCompletePlaces() {
    textEditingController.addListener(() async {
      if (textEditingController.text.isNotEmpty) {
        var result =
            await mapsApiServices.getPlaces(textEditingController.text);
        places.clear();
        setState(() {
          places.addAll(result);
        });
      }
    });
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
      markers.add(Marker(
          point: latLng,
          child: const Icon(
            Icons.my_location,
            size: 35,
          )));
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
            color: Colors.red,
            size: 35,
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
