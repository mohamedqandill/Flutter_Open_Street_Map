import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_maps/providers/map_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CachedTileProvider extends TileProvider {
  CachedTileProvider();
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return CachedNetworkImageProvider(
      getTileUrl(coordinates, options),
    );
  }
}

class FlutterMapScreen extends StatefulWidget {
  const FlutterMapScreen({super.key});

  @override
  State<FlutterMapScreen> createState() => _FlutterMapScreenState();
}

class _FlutterMapScreenState extends State<FlutterMapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MapProvider>().requestServiceAndLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.sizeOf(context).width;
    var height = MediaQuery.sizeOf(context).height;

    return Consumer<MapProvider>(
      builder: (context, mapProv, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          body: Stack(
            children: [
              FlutterMap(
                mapController: mapProv.mapController,
                options: MapOptions(
                  initialCenter: mapProv.currentLocation,
                  initialZoom: 12,
                  onTap: (tapPosition, point) {
                    if (!mapProv.isRoutingMode) {
                      mapProv.selectPointOnMap(point, isOrigin: false);
                    } else if (mapProv.destinationFocus.hasFocus) {
                      mapProv.selectPointOnMap(point, isOrigin: false);
                    } else if (mapProv.originFocus.hasFocus) {
                      mapProv.selectPointOnMap(point, isOrigin: true);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'com.example.flutter_map',
                    tileProvider: CachedTileProvider(),
                  ),
                  MarkerLayer(markers: mapProv.markers),
                  if (mapProv.trackRoutes.isNotEmpty)
                    PolylineLayer(polylines: [
                      Polyline(
                        points: mapProv.trackRoutes,
                        color: const Color(0xFF4285F4).withOpacity(0.8),
                        strokeWidth: 6,
                        borderColor: const Color(0xFF1967D2),
                        borderStrokeWidth: 1,
                      )
                    ]),
                ],
              ),
              _buildHeader(context, mapProv, width, height),
              if (mapProv.showBottomDetails &&
                  mapProv.segments.isNotEmpty &&
                  mapProv.trackRoutes.length >= 2)
                _buildBottomDetailsCard(context, mapProv, width),
              if ((mapProv.isSearchingOrigin ||
                      mapProv.isSearchingDestination) &&
                  mapProv.places.isNotEmpty)
                _buildSearchResults(context, mapProv, width, height),
              if (mapProv.isLoading || mapProv.isPlacesLoading)
                const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4285F4))),
            ],
          ),
          floatingActionButton:
              _buildFloatingActionButtons(context, mapProv, width),
        );
      },
    );
  }

  Widget _buildHeader(
      BuildContext context, MapProvider mapProv, double width, double height) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
            top: height * 0.05, left: 16, right: 16, bottom: 16),
        decoration: BoxDecoration(
          color: mapProv.isRoutingMode ? Colors.white : Colors.transparent,
          boxShadow: mapProv.isRoutingMode
              ? [
                  const BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4))
                ]
              : [],
        ),
        child: mapProv.isRoutingMode
            ? _buildRoutingModeUI(context, mapProv, width)
            : _buildSearchBar(context, mapProv, width),
      ),
    );
  }

  Widget _buildSearchBar(
      BuildContext context, MapProvider mapProv, double width) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.location_on, color: Color(0xFFEA4335)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: mapProv.destinationController,
              focusNode: mapProv.destinationFocus,
              onTap: () => mapProv.setSearchingDestination(true),
              style: GoogleFonts.outfit(fontSize: width * 0.04),
              decoration: InputDecoration(
                hintText: "Search here",
                border: InputBorder.none,
                hintStyle: GoogleFonts.outfit(
                    color: Colors.grey, fontSize: width * 0.04),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.directions, color: Color(0xFF4285F4)),
            onPressed: () => mapProv.setRoutingMode(true),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildRoutingModeUI(
      BuildContext context, MapProvider mapProv, double width) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => mapProv.setRoutingMode(false),
            ),
            Text("Your Route",
                style: GoogleFonts.outfit(
                    fontSize: width * 0.05, fontWeight: FontWeight.bold)),
          ],
        ),
        _buildRoutingField(mapProv, width, mapProv.originController,
            mapProv.originFocus, "Pick origin", true),
        const SizedBox(height: 8),
        _buildRoutingField(mapProv, width, mapProv.destinationController,
            mapProv.destinationFocus, "Search destination", false),
      ],
    );
  }

  Widget _buildRoutingField(MapProvider mapProv, double width,
      TextEditingController ctrl, FocusNode fn, String hint, bool isOrigin) {
    return Container(
      decoration: BoxDecoration(
          color: const Color(0xFFF1F3F4),
          borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: ctrl,
        focusNode: fn,
        onTap: () => isOrigin
            ? mapProv.setSearchingOrigin(true)
            : mapProv.setSearchingDestination(true),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(isOrigin ? Icons.my_location : Icons.location_on,
              color:
                  isOrigin ? const Color(0xFF4285F4) : const Color(0xFFEA4335)),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildSearchResults(
      BuildContext context, MapProvider mapProv, double width, double height) {
    return Positioned(
      top: mapProv.isRoutingMode ? 220 : 110,
      left: 16,
      right: 16,
      child: Container(
        constraints: BoxConstraints(maxHeight: height * 0.4),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 10)
            ]),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: mapProv.places.length,
          separatorBuilder: (c, i) => const Divider(height: 1),
          itemBuilder: (c, i) {
            final place = mapProv.places[i];
            return ListTile(
              title: Text(place.properties?.name ?? ""),
              subtitle: Text(place.properties?.label ?? ""),
              onTap: () => mapProv.onPlaceSelected(place),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomDetailsCard(
      BuildContext context, MapProvider mapProv, double width) {
    final durationSecs = mapProv.segments[0]['duration'] as num;
    final distanceMeters = mapProv.segments[0]['distance'] as num;
    final minutes = (durationSecs / 60).round();
    final distanceKm = (distanceMeters / 1000).toStringAsFixed(1);

    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8))
            ]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text("$minutes min",
                    style: GoogleFonts.outfit(
                        fontSize: width * 0.06,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E8E3E))),
                const SizedBox(width: 8),
                Text("($distanceKm km)",
                    style: GoogleFonts.outfit(
                        fontSize: width * 0.045, color: Colors.grey)),
                const Spacer(),
                IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => setState(() {
                          mapProv.showBottomDetails = false;
                        })),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Fastest route now based on traffic",
                  style: GoogleFonts.outfit(
                      color: Colors.grey, fontSize: width * 0.035)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => setState(() {
                mapProv.showBottomDetails = false;
              }),
              icon: const Icon(Icons.navigation_outlined, color: Colors.white),
              label: const Text("Start",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4285F4),
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons(
      BuildContext context, MapProvider mapProv, double width) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          onPressed: () => mapProv.clearAll(),
          backgroundColor: Colors.white,
          child: const Icon(Icons.layers_clear, color: Colors.red),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          onPressed: () => mapProv.updateMyLocation(),
          backgroundColor: Colors.white,
          child: const Icon(Icons.my_location, color: Color(0xFF4285F4)),
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}
