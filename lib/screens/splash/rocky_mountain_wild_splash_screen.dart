// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/fundamental/icons.dart';
import 'package:pika_patrol/screens/home_with_drawer.dart';

class RockyMountainWildSplashScreen extends Container {

  RockyMountainWildSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      height: double.infinity,
      child: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                  child: Image.asset("assets/images/rocky_mountain_wild_logo.png"),
                )
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
          ],
        )
      ),
    );
  }
}