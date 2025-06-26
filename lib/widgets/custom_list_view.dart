import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_maps/utils/maps_services.dart';
import 'package:flutter_maps/utils/models/PlacesAutoCompleteModel.dart';
import 'package:latlong2/latlong.dart';

class CustomListView extends StatefulWidget {
  const CustomListView({
    super.key,
    required this.places,
    required this.mapsApiServices,
    required this.currentLocation,
    required this.textEditingController,
    required this.onRouteUpdate,
  });

  final List<Features> places;
  final MapsApiServices mapsApiServices;
  final LatLng currentLocation;
  final Function(List<LatLng>, LatLng destination, bool listenerState,
      bool loadingState) onRouteUpdate;
  final TextEditingController textEditingController;

  @override
  State<CustomListView> createState() => _CustomListViewState();
}

class _CustomListViewState extends State<CustomListView> {
  bool isLoading = false;
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () async {
              final coords = widget.places[index].geometry!.coordinates!;
              final lon = coords[0];
              final lat = coords[1];
              if (kDebugMode) {
                print("Longitude: $lon, Latitude: $lat");
              }
              bool listenerState = true;
              setState(() {
                widget.textEditingController.clear();
              });
              widget.onRouteUpdate([], LatLng(lat, lon), false, true);

              listenerState = false;

              print("hereee");
              var newRouts = await widget.mapsApiServices
                  .getRoute(widget.currentLocation, LatLng(lat, lon));

              widget.onRouteUpdate(newRouts, LatLng(lat, lon), false, false);
            },
            child: Container(
              width: 150,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.places[index].properties?.name ?? "Error",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.places[index].properties?.country ?? "Error",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w300),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        separatorBuilder: (context, index) {
          return const SizedBox(
            height: 2,
          );
        },
        itemCount: widget.places.length);
  }
}
