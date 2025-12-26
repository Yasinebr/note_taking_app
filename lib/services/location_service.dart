import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static Future<Position?> getCurrentLocation() async {
    try {
      // Check and request location permission
      var permission = await Permission.location.status;
      if (permission.isDenied) {
        permission = await Permission.location.request();
      }

      if (permission.isPermanentlyDenied) {
        await openAppSettings();
        return null;
      }

      if (permission.isGranted) {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          return null;
        }

        LocationPermission geoPermission = await Geolocator.checkPermission();
        if (geoPermission == LocationPermission.denied) {
          geoPermission = await Geolocator.requestPermission();
        }

        if (geoPermission == LocationPermission.deniedForever ||
            geoPermission == LocationPermission.denied) {
          return null;
        }

        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      }
    } catch (e) {
      print('Error getting location: $e');
    }
    return null;
  }

  static String formatLocation(Position position) {
    return '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
  }
}