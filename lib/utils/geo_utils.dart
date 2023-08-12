import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';

Future<Position> checkPermissionsAndGetCurrentPosition() async {
  bool isServiceEnabled;
  LocationPermission permission;

  isServiceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!isServiceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the
    // App to enable the location services.
    Fluttertoast.showToast(
        msg: "Could not retrieve location.\nEnable GPS and try to save again.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,//TODO - need to use Toast with context to link to the primary color
        textColor: Colors.white,
        fontSize: 16.0
    );
    await Geolocator.openLocationSettings();
    return Future.error("Location services are disabled.");
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

      Fluttertoast.showToast(
          msg: "You must grant location permissions.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,//TODO - need to use Toast with context to link to the primary color
          textColor: Colors.white,
          fontSize: 16.0
      );
      await Geolocator.openAppSettings();
      return Future.error("Location permissions are denied");
    }
  } else if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately.

    Fluttertoast.showToast(
        msg: "You must grant location permissions.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,//TODO - need to use Toast with context to link to the primary color
        textColor: Colors.white,
        fontSize: 16.0
    );
    await Geolocator.openAppSettings();
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  // When we reach here, permissions are granted and we can continue accessing the device position
  Position position = await Geolocator.getCurrentPosition();

  if (position == null) {
    Fluttertoast.showToast(
        msg: "Could not retrieve location from GPS.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,//TODO - need to use Toast with context to link to the primary color
        textColor: Colors.white,
        fontSize: 16.0
    );
  }

  return position;
}

String? isValidGeo(String value, String name) {
  bool isDouble = double.tryParse(value) != null;
  return isDouble ? null : 'Invalid';
}