import 'package:flutter/material.dart';

class RockyMountainWildSplashScreen extends Container {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Image.asset("assets/images/rocky_mountain_wild_logo.png"),
        ),
      ),
    );
  }
}