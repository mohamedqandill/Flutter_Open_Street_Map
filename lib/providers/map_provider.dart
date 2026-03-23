import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../utils/location_services.dart';
import '../utils/maps_services.dart';
import '../utils/models/PlacesAutoCompleteModel.dart';

class MapProvider with ChangeNotifier, WidgetsBindingObserver {
  final LocationService locationService = LocationService();
  final MapsApiServices mapsApiServices = MapsApiServices();
  final MapController mapController = MapController();

  List<Marker> markers = [];
  LatLng currentLocation = const LatLng(30.0444, 31.2357);
  List<LatLng> trackRoutes = [];
  List<Features> places = [];
  List segments = [];

  final TextEditingController originController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  final FocusNode originFocus = FocusNode();
  final FocusNode destinationFocus = FocusNode();

  bool isLoading = false;
  bool isPlacesLoading = false;
  bool ignoreListener = false;
  bool isSearchingOrigin = false;
  bool isSearchingDestination = false;
  bool isRoutingMode = false;
  bool showBottomDetails = false;
  bool isFollowingUser = true;

  Marker? myLocationMarker;
  LatLng? originLocation;
  LatLng? destinationLocation;
  StreamSubscription? locationSubscription;
  Timer? debounce;
  bool _isInitial = true;

  MapProvider() {
    WidgetsBinding.instance.addObserver(this);
    _initListeners();
  }

  void _initListeners() {
    void listener() {
      final text = isSearchingOrigin ? originController.text : destinationController.text;
      if (ignoreListener || text.isEmpty) {
        places = [];
        notifyListeners();
        return;
      }
      if (debounce?.isActive ?? false) debounce!.cancel();
      debounce = Timer(const Duration(milliseconds: 600), () async {
        isPlacesLoading = true;
        notifyListeners();
        try {
          places = await mapsApiServices.getPlaces(text);
        } catch (_) {}
        isPlacesLoading = false;
        notifyListeners();
      });
    }

    originController.addListener(listener);
    destinationController.addListener(listener);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      requestServiceAndLocation();
    }
  }

  Future<void> requestServiceAndLocation() async {
    await locationService.checkAndRequestPermission();
    bool enabled = await locationService.checkAndRequestLocationService();
    if (enabled) {
      updateMyLocation();
    }
  }

  Future<void> updateMyLocation() async {
    bool isFirstTime = true;
    locationSubscription?.cancel();
    locationSubscription = LocationService.onLocationChanged.listen((position) async {
      final latLng = LatLng(position.latitude, position.longitude);

      bool isOriginTrackingUser = originLocation == null ||
          (originLocation != null &&
              originLocation!.latitude == currentLocation.latitude &&
              originLocation!.longitude == currentLocation.longitude);

      currentLocation = latLng;
      _setMyLocationMarker(latLng);

      if (isFollowingUser || _isInitial) {
        mapController.move(latLng, 14);
        _isInitial = false;
      }

      if (isFirstTime) {
        isFirstTime = false;
        final name = await mapsApiServices.getPlaceName(latLng);
        if (originController.text.isEmpty || originController.text == "My Location") {
          ignoreListener = true;
          originController.text = name;
          ignoreListener = false;
        }
      }

      if (isOriginTrackingUser) {
        originLocation = latLng;
        updateMarkersAndRoute(showSheet: false);
      }
      notifyListeners();
    }, onError: (e) {
      debugPrint("Location error: $e");
      Future.delayed(const Duration(seconds: 2), () => requestServiceAndLocation());
    });
  }

  void _setMyLocationMarker(LatLng latLng) {
    myLocationMarker = Marker(
      point: latLng,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(height: 20, width: 20, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          Container(
            height: 14, width: 14,
            decoration: BoxDecoration(
              color: const Color(0xFF4285F4),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ],
      ),
    );
    updateMarkersAndRoute(showSheet: false);
  }

  Future<void> onPlaceSelected(Features place) async {
    final coords = place.geometry!.coordinates!;
    final latLng = LatLng(coords[1], coords[0]);

    if (isSearchingOrigin) {
      originLocation = latLng;
      originController.text = place.properties?.name ?? "";
      isSearchingOrigin = false;
    } else {
      destinationLocation = latLng;
      destinationController.text = place.properties?.name ?? "";
      isSearchingDestination = false;
    }
    places = [];
    updateMarkersAndRoute();
    notifyListeners();
  }

  Future<void> selectPointOnMap(LatLng point, {required bool isOrigin}) async {
    isLoading = true;
    notifyListeners();
    final name = await mapsApiServices.getPlaceName(point);
    ignoreListener = true;
    if (isOrigin) {
      originLocation = point;
      originController.text = name;
    } else {
      destinationLocation = point;
      destinationController.text = name;
    }
    ignoreListener = false;
    isLoading = false;
    updateMarkersAndRoute();
    notifyListeners();
  }

  void updateMarkersAndRoute({bool showSheet = true}) async {
    markers = [];
    if (myLocationMarker != null) markers.add(myLocationMarker!);

    if (originLocation != null && (originLocation!.latitude != currentLocation.latitude || originLocation!.longitude != currentLocation.longitude)) {
      markers.add(Marker(point: originLocation!, child: const Icon(Icons.radio_button_checked, color: Color(0xFF4285F4))));
    }

    if (destinationLocation != null) {
      markers.add(Marker(point: destinationLocation!, child: const Icon(Icons.location_on, color: Color(0xFFEA4335), size: 36)));
    }

    if (originLocation != null && destinationLocation != null) {
      if (showSheet) {
        isLoading = true;
        showBottomDetails = false;
        notifyListeners();
      }
      try {
        final result = await mapsApiServices.getRoute(originLocation!, destinationLocation!);
        trackRoutes = result['routePoints'];
        segments = result['segments'];
        if (showSheet) showBottomDetails = true;

        if (trackRoutes.isNotEmpty && segments.isNotEmpty) {
          final middlePoint = trackRoutes[trackRoutes.length ~/ 2];
          final durationSecs = segments[0]['duration'] as num;
          final durationMins = (durationSecs / 60).round();
          markers.add(Marker(
            point: middlePoint, width: 80, height: 40, alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(color: const Color.fromARGB(255, 30, 125, 142), borderRadius: BorderRadius.circular(20)),
              alignment: Alignment.center,
              child: Text("$durationMins min", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ));
        }

        if (showSheet && trackRoutes.isNotEmpty) {
          mapController.fitCamera(CameraFit.bounds(bounds: LatLngBounds.fromPoints(trackRoutes), padding: const EdgeInsets.only(top: 150, bottom: 350, left: 50, right: 50)));
        }
      } catch (e) {
        debugPrint("Routing error: $e");
      }
      isLoading = false;
      notifyListeners();
    }
  }

  void clearAll() {
    isRoutingMode = false;
    trackRoutes = [];
    segments = [];
    destinationLocation = null;
    destinationController.clear();
    showBottomDetails = false;
    updateMarkersAndRoute(showSheet: false);
    mapController.move(currentLocation, 14);
    notifyListeners();
  }

  void setRoutingMode(bool value) {
    isRoutingMode = value;
    notifyListeners();
  }

  void setSearchingOrigin(bool value) {
    isSearchingOrigin = value;
    if (value) isSearchingDestination = false;
    notifyListeners();
  }

  void setSearchingDestination(bool value) {
    isSearchingDestination = value;
    if (value) isSearchingOrigin = false;
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    originController.dispose();
    destinationController.dispose();
    originFocus.dispose();
    destinationFocus.dispose();
    debounce?.cancel();
    locationSubscription?.cancel();
    super.dispose();
  }
}
