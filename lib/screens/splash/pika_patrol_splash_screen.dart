import 'package:flutter/material.dart';
import 'package:pika_joe/styles/styles.dart';

class PikaPatrolSplashScreen extends Container {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.teal,
      width: double.infinity,
      height: double.infinity,
      child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: Image.asset("assets/images/pika_patrol_logo.png"),
          ),
      ),
    );
  }
}