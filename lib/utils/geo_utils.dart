// ignore_for_file: non_constant_identifier_names
import 'package:geolocator/geolocator.dart';
import 'package:material_themes_widgets/utils/ui_utils.dart';

import '../l10n/translations.dart';

Future<Position> checkPermissionsAndGetCurrentPosition(Translations translations) async {
  bool isServiceEnabled;
  LocationPermission permission;

  isServiceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!isServiceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the
    // App to enable the location services.
    showToast(translations.couldNotRetrieveLocationEnableGps);
    await Geolocator.openLocationSettings();
    return Future.error(translations.locationServicesAreDisabled);
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      showToast(translations.youMustGrantLocationPermissions);
      await Geolocator.openAppSettings();
      return Future.error(translations.locationPermissionsAreDenied);
    }
  } else if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately.
    showToast(translations.youMustGrantLocationPermissions);
    await Geolocator.openAppSettings();
    return Future.error(translations.locationPermissionsArePermanentlyDenied);
  }

  // When we reach here, permissions are granted and we can continue accessing the device position
  Position position = await Geolocator.getCurrentPosition();

  if (position == null) {
    showToast(translations.couldNotRetrieveLocationFromGps);
  }

  return position;
}

String? isValidGeo(String? value, String name) {
  bool isDouble = value == null ? false : double.tryParse(value) != null;
  return isDouble ? null : 'Invalid';
}

double FEET_PER_METER = 3.28084;

double feetToMeters(double feet) => feet / FEET_PER_METER;

double metersToFeet(double meter) => meter * FEET_PER_METER;