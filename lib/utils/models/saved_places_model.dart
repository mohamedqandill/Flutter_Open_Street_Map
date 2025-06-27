import 'package:latlong2/latlong.dart';

class SavedPlacesModel {
  final LatLng latLng;
  final String placeName;
  final String placeCountry;

  SavedPlacesModel({
    required this.latLng,
    required this.placeName,
    required this.placeCountry,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latLng.latitude,
      'longitude': latLng.longitude,
      'placeName': placeName,
      'placeCountry': placeCountry,
    };
  }

  factory SavedPlacesModel.fromJson(Map<dynamic, dynamic> json) {
    return SavedPlacesModel(
      latLng: LatLng(json['latitude'], json['longitude']),
      placeName: json['placeName'],
      placeCountry: json['placeCountry'],
    );
  }
}
