import 'package:flutter/material.dart';
import 'package:flutter_maps/utils/maps_services.dart';
import 'package:flutter_maps/utils/models/PlacesAutoCompleteModel.dart';
import 'package:flutter_maps/utils/models/saved_places_model.dart';
import 'package:latlong2/latlong.dart';

import '../utils/db/db.dart';

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
  late SavedPlacesDatabase savedPlacesDatabase;
  List<SavedPlacesModel> savedPlaces = [];
  int placeId = 0;

  @override
  void initState() {
    savedPlacesDatabase = SavedPlacesDatabase();
    getAllSavedPlaces();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 700,
      child: ListView.separated(
          itemBuilder: (context, index) {
            return InkWell(
              onTap: () {
                final coords = widget.textEditingController.text.isEmpty
                    ? [0.0, 0.0]
                    : widget.places[index].geometry!.coordinates!;
                final savedcoords = widget.textEditingController.text.isEmpty
                    ? savedPlaces[index].latLng
                    : const LatLng(0, 0);
                final lon = coords[0];
                final lat = coords[1];
                final latLng = LatLng(lat, lon);
                FocusScope.of(context).unfocus();
                if (widget.textEditingController.text.isNotEmpty) {
                  SavedPlacesModel place = SavedPlacesModel(
                    latLng: latLng,
                    placeName: widget.places[index].properties?.name ?? "",
                    placeCountry: widget.places[index].properties?.label ?? "",
                  );
                  savePlaceToDB(place);
                }

                getRoutes(
                    index,
                    widget.textEditingController.text.isEmpty
                        ? savedcoords
                        : latLng);
                setState(() {
                  Future.delayed(
                    const Duration(milliseconds: 500),
                    () {
                      widget.textEditingController.clear();
                    },
                  );
                  getAllSavedPlaces();
                });
              },
              child: Container(
                width: 150,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 30,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.textEditingController.text.isEmpty
                                  ? savedPlaces[index].placeName
                                  : widget.places[index].properties?.name ??
                                      "Error",
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              widget.textEditingController.text.isEmpty
                                  ? savedPlaces[index].placeCountry
                                  : widget.places[index].properties?.label
                                          ?.substring(0, 12) ??
                                      "Error",
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w300),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_circle_right_outlined,
                        size: 30,
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
          itemCount: widget.textEditingController.text.isEmpty
              ? savedPlaces.length
              : widget.places.length),
    );
  }

  getAllSavedPlaces() async {
    savedPlaces = await savedPlacesDatabase.getPlaces();
    setState(() {});
    print("${savedPlaces.length}");
  }

  getRoutes(int index, LatLng latLng) async {
    widget.onRouteUpdate([], latLng, false, true);
    var newRouts =
        await widget.mapsApiServices.getRoute(widget.currentLocation, latLng);
    widget.onRouteUpdate(newRouts, latLng, false, false);
  }

  savePlaceToDB(SavedPlacesModel place) async {
    await savedPlacesDatabase.savePlace(place);
  }
}
