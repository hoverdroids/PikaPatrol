import 'package:flutter/material.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:shimmer/shimmer.dart';
import 'package:material_themes_widgets/fundamental/icons.dart';
import 'package:pika_patrol/screens/home_with_drawer.dart';

class PartneringWithSplashScreen extends Container {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.brown,
      width: double.infinity,
      height: double.infinity,
      child: SafeArea(
        child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                    child: Shimmer.fromColors(
                      period: const Duration(milliseconds: 1500),
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
              Align(
                alignment: Alignment.topRight,
                child: ThemedIconButton(
                    Icons.highlight_off,
                    iconSize: IconSize.MEDIUM,
                    onPressedCallback: () => {
                      Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (BuildContext context) => HomeWithDrawer())
                      )
                    }
                )
              ),
            ]
        )
      ),
    );
  }
}