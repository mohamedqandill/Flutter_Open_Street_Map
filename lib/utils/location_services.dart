import 'package:location/location.dart';

class LocationService {
  static Location location = Location();

  Future<bool> checkAndRequestLocationService() async {
    var isServiceEnabled = await location.serviceEnabled();
    if (!isServiceEnabled) {
      isServiceEnabled = await location.requestService();
      if (!isServiceEnabled) {
        return false;
      }
    }
    return true;
  }

  Future<bool> checkAndRequestPermission() async {
    var permissionStatue = await location.hasPermission();
    if (permissionStatue == PermissionStatus.deniedForever) {
      return false;
    }
    if (permissionStatue == PermissionStatus.denied) {
      permissionStatue = await location.requestPermission();
      if (permissionStatue != PermissionStatus.granted) {
        return false;
      }
    }
    return true;
  }

  static void getRealTimeLocationData(void Function(LocationData)? onData) {
    location.changeSettings(distanceFilter: 2);
    location.onLocationChanged.listen(onData);
  }
}
