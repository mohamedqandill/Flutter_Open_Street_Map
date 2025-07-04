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
  List segments = [];
  late TextEditingController textEditingController;
  bool isLoading = false;
  bool isPlacesLoading = false;
  Timer? debounce;
  bool ignoreListener = false;
  bool isFocusedState = false;
  late FocusNode searchFocusState;
  bool serviceEnabled = false;
  Marker? myLocationMarker;

  @override
  void initState() {
    locationService = LocationService();
    mapsApiServices = MapsApiServices();
    searchController = SearchController();
    textEditingController = TextEditingController();
    searchFocusState = FocusNode();
    getAutoCompletePlaces();
    mapController = MapController();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    requestService().then((enabled) {
      if (enabled == true) {
        updateMyLocation();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("To Use This App,Turn On GPS")),
        );
        didChangeDependencies();
      }
    });
  }

  @override
  void dispose() {
    textEditingController.dispose();
    debounce!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.sizeOf(context).width;
    var height = MediaQuery.sizeOf(context).height;
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
                    points: trackRoutes,
                    color: Colors.blue,
                    strokeWidth: width * 0.02,
                  )
                ]),
              if (segments.isNotEmpty && trackRoutes.length >= 2)
                Transform.translate(
                  offset: const Offset(50, 0),
                  child: MarkerLayer(
                    markers: [
                      Marker(
                        point: getMidPoint(trackRoutes),
                        width: 80,
                        height: 30,
                        child: _buildDurationBubble(segments),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          Positioned(
            top: height * 0.06,
            right: width * 0.05,
            left: width * 0.05,
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
                    ? const Center(child: CircularProgressIndicator())
                    : isFocusedState
                        ? Padding(
                            padding: EdgeInsets.only(top: height * 0.01),
                            child: CustomListView(
                              onRouteUpdate: (newRoutes, latLng, listenerState,
                                  loadingState, placeSegments) {
                                setState(() {
                                  segments = [];
                                  trackRoutes = newRoutes;
                                  isLoading = loadingState;
                                  segments = placeSegments;
                                  markers = markers
                                      .where((m) => m.point == currentLocation)
                                      .toList();
                                  markers.add(Marker(
                                    point: latLng,
                                    child: Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      size: width * 0.08,
                                    ),
                                  ));
                                  ignoreListener = listenerState;
                                });
                              },
                              places: places,
                              mapsApiServices: mapsApiServices,
                              currentLocation: currentLocation,
                              textEditingController: textEditingController,
                            ),
                          )
                        : const SizedBox()
              ],
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          mapController.move(currentLocation, 8);
        },
        child: Icon(Icons.my_location, size: width * 0.07),
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
          try {
            places =
                await mapsApiServices.getPlaces(textEditingController.text);
          } catch (e) {
            setState(() {
              isPlacesLoading = false;
            });
          }
          setState(() {
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

  requestService() async {
    await locationService.checkAndRequestPermission();
    serviceEnabled = await locationService.checkAndRequestLocationService();
    return serviceEnabled;
  }

  Future<void> updateMyLocation() async {
    bool isFirstTime = true;
    bool gotLocation = false;

    if (!gotLocation) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Getting Your Location....."),
      ));
    }
    Timer timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (!gotLocation) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Location request timed out. Trying again..."),
        ));
        updateMyLocation();
      }
    });

    locationService.getRealTimeLocationData((locationData) {
      if (locationData.latitude != null && locationData.longitude != null) {
        gotLocation = true;
        timeoutTimer.cancel();

        final latLng = LatLng(locationData.latitude!, locationData.longitude!);
        currentLocation = latLng;
        setMyLocationMarker(latLng);

        if (isFirstTime) {
          updateMyCamera(latLng);
          isFirstTime = false;
        }
      } else {
        gotLocation = true;
        timeoutTimer.cancel();

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Unable to get location. Trying again..."),
        ));
        Future.delayed(const Duration(seconds: 2), () {
          updateMyLocation();
        });
      }
    });
  }

  setMyLocationMarker(LatLng latLng) {
    var width = MediaQuery.of(context).size.width;

    Marker newMarker = Marker(
      point: latLng,
      child: Icon(
        Icons.my_location,
        size: width * 0.09,
        color: Colors.blue,
      ),
    );

    setState(() {
      if (myLocationMarker != null) {
        markers.remove(myLocationMarker);
      }

      myLocationMarker = newMarker;
      markers.add(myLocationMarker!);
    });
  }

  updateMyCamera(LatLng latLng) {
    mapController.move(latLng, 10);
  }

  addDestinationMarker(LatLng point) async {
    var width = MediaQuery.of(context).size.width;

    setState(() {
      markers =
          markers.where((marker) => marker.point == currentLocation).toList();

      markers.add(Marker(
          point: point,
          child: Icon(
            Icons.location_on,
            color: Colors.red,
            size: width * 0.09,
          )));

      isLoading = true;
    });

    try {
      var result = await mapsApiServices.getRoute(currentLocation, point);
      trackRoutes = result['routePoints'];
      segments = result['segments'];
      setState(() {});
    } catch (e) {
      setState(() {
        isLoading = false;
        trackRoutes = [];
      });
    }
    setState(() {
      log("trackroutes=>>${trackRoutes.length}");
      isLoading = false;
    });
  }

  LatLng getMidPoint(List<LatLng> points) {
    final midIndex = (points.length / 2).floor();
    return points[midIndex];
  }
}

Widget _buildDurationBubble(List segments) {
  if (segments.isEmpty) return const SizedBox();

  final durationSeconds = segments[0]['duration'] as num;
  final duration = Duration(seconds: durationSeconds.round());
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  String minLabel = "min";

  return Container(
    padding: const EdgeInsets.only(left: 10),
    decoration: BoxDecoration(
      color: Colors.blue,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: FittedBox(
      child: Text(
        hours > 0 ? "$hours h $minutes $minLabel" : "$minutes $minLabel",
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    ),
  );
}
