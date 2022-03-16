import 'package:flutter/material.dart';

class IfThenSplashScreen extends Container {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFFF3F3F3),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Image.asset("assets/images/if_then_logo.jpg"),
        ),
      ),
    );
  }
}