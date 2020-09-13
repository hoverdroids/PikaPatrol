import 'package:flutter/material.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:shimmer/shimmer.dart';

class PartneringWithSplashScreen extends Container {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.brown,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Shimmer.fromColors(
              period: Duration(milliseconds: 1500),
              baseColor: Colors.white,
              highlightColor: Colors.brown,
              child: ThemedH3(
                "In\nPartnership\nWith",
                type: ThemeGroupType.MOP,
                emphasis: Emphasis.HIGH,
                textAlign: TextAlign.center,
              ),
            )
        ),
      ),
    );
  }
}