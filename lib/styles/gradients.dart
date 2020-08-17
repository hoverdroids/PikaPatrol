import 'package:flutter/material.dart';
import 'package:pika_joe/styles/styles.dart';

import 'colors.dart';

Widget getBackgroundGradient(ScreenStyles screenStyle) {
  if(screenStyle == ScreenStyles.PRIMARY_ON_LIGHT || screenStyle == ScreenStyles.LIGHT_ON_LIGHT || screenStyle == ScreenStyles.DARK_ON_LIGHT) {
    return lightBackgroundGradient;
  } else if(screenStyle == ScreenStyles.PRIMARY_ON_DARK || screenStyle == ScreenStyles.LIGHT_ON_DARK || screenStyle == ScreenStyles.DARK_ON_DARK) {
    return darkBackgroundGradient;
  } else {
    return primaryGradient;
  }
}


var primaryGradient = Container(
  height: double.infinity,
  width: double.infinity,
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        primaryStartColor,
        primaryEndColor,
      ],
    ),
  ),
);

var darkBackgroundGradient = Container(
  height: double.infinity,
  width: double.infinity,
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        darkBackgroundStartColor,
        darkBackgroundEndColor,
      ],
    ),
  ),
);

var darkSurfaceGradient = Container(
  height: double.infinity,
  width: double.infinity,
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        darkSurfaceStartColor,
        darkSurfaceEndColor,
      ],
    ),
  ),
);

var lightBackgroundGradient = Container(
  height: double.infinity,
  width: double.infinity,
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        lightBackgroundStartColor,
        lightBackgroundEndColor,
      ],
    ),
  ),
);

var lightSurfaceGradient = Container(
  height: double.infinity,
  width: double.infinity,
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        lightSurfaceStartColor,
        lightSurfaceEndColor,
      ],
    ),
  ),
);