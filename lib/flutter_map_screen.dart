import 'dart:async';
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
  bool isPlacesLoading = false;
  Timer? debounce;
  bool ignoreListener = false;
  bool isFocusedState = false;
  late FocusNode searchFocusState;

  @override
  void initState() {
    locationService = LocationService();
    mapsApiServices = MapsApiServices();
    searchController = SearchController();
    textEditingController = TextEditingController();
    searchFocusState = FocusNode();
    getAutoCompletePlaces();

    mapController = MapController();
    updateMyLocation();
    setState(() {});
    super.initState();
  }

  @override
  void dispose() {
    textEditingController.dispose();
    debounce!.cancel();
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
                  const LatLng(27.892458365561065, 26.725024118954433),
              initialZoom: 5,
              onTap: (tapPosition, point) => addDestinationMarker(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.flutter_map',
              ),
              MarkerLayer(markers: markers),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (trackRoutes.isNotEmpty)
                PolylineLayer(polylines: [
                  Polyline(
                      points: trackRoutes, color: Colors.blue, strokeWidth: 8.0)
                ]),
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
                    isFocused: (isFocused) {
                      isFocusedState = isFocused;
                      setState(() {});
                    },
                    searchFocused: searchFocusState,
                    textEditingController: textEditingController,
                  ),
                  isPlacesLoading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : isFocusedState
                          ? CustomListView(
                              onRouteUpdate: (newRoutes, latLng, listenerState,
                                  loadingState) {
                                setState(() {
                                  trackRoutes = newRoutes;
                                  isLoading = loadingState;
                                  markers = markers
                                      .where((m) => m.point == currentLocation)
                                      .toList();
                                  markers.add(Marker(
                                    point: latLng,
                                    child: const Icon(Icons.location_on,
                                        color: Colors.red, size: 35),
                                  ));
                                  ignoreListener = listenerState;
                                });
                              },
                              places: places,
                              mapsApiServices: mapsApiServices,
                              currentLocation: currentLocation,
                              textEditingController: textEditingController,
                            )
                          : const SizedBox()
                ],
              ))
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          mapController.move(currentLocation, 10);
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }

  void getAutoCompletePlaces() {
    textEditingController.addListener(() {
      if (ignoreListener) return;
      if (debounce?.isActive ?? false) debounce!.cancel();

      debounce = Timer(const Duration(milliseconds: 900), () async {
        if (textEditingController.text.isNotEmpty) {
          setState(() {
            isPlacesLoading = true;
          });
          var result =
              await mapsApiServices.getPlaces(textEditingController.text);
          setState(() {
            places = result;
            isPlacesLoading = false;
          });
        } else {
          setState(() {
            places.clear();
          });
        }
      });
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
            color: Colors.blue,
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

      markers.add(Marker(
          point: point,
          child: const Icon(
            Icons.location_on,
            color: Colors.red,
            size: 35,
          )));

      isLoading = true;
    });
    final newRouts = await mapsApiServices.getRoute(currentLocation, point);
    setState(() {
      trackRoutes = newRouts;
      log("trackroutes=>>${trackRoutes.length}");
      isLoading = false;
    });
  }
}
