import 'package:flutter/material.dart';
import 'package:pika_joe/styles/styles.dart';

class FrontRangePikaProjectSplashScreen extends Container {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFF00929F),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Image.asset("assets/images/front_range_pika_project_logo.png"),
        ),
      ),
    );
  }
}