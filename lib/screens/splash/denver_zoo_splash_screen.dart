import 'package:flutter/material.dart';

class DenverZooSplashScreen extends Container {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xff39156A),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Image.asset("assets/images/denver_zoo_logo.png"),
        ),
      ),
    );
  }
}