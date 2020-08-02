import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:pika_joe/screens/splash/page1.dart';
import 'package:pika_joe/screens/splash/page2.dart';
import 'package:pika_joe/screens/splash/page3.dart';
import 'package:pika_joe/screens/splash/pika_patrol_splash.dart';
import 'package:pika_joe/styles/styles.dart';

class LiquidSwipeWrapper extends StatelessWidget {
  static const TextStyle boldStyle = TextStyle(
    fontSize: 50.0,
    color: Colors.black,
    fontFamily: "Product Sans",
    fontWeight: FontWeight.bold,
  );

//widget(child: new PikaPatrolSpash())
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LiquidSwipe(
        pages: <Container>[
          Page1(),
          Page2(),
          Page3(),
        ],
        enableLoop: true,
        fullTransitionValue: 300,
        enableSlideIcon: true,
        waveType: WaveType.liquidReveal,
        positionSlideIcon: 0.5,
      ),
    );
  }
}