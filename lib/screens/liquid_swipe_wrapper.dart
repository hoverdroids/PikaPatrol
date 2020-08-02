
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:pika_joe/screens/splash/bla.dart';
import 'package:pika_joe/screens/splash/pika_patrol_splash.dart';
import 'package:pika_joe/styles/styles.dart';

class LiquidSwipeWrapper extends StatelessWidget {

  final pages = <Widget>[

  ];
//widget(child: new PikaPatrolSpash())
  @override
  Widget build(BuildContext context) {
    return LiquidSwipe(
      pages: <Container>[
        Bla()
      ],
      enableLoop: false,
      fullTransitionValue: 300,
      enableSlideIcon: true,
      waveType: WaveType.liquidReveal,
      positionSlideIcon: 0.5,
    );
  }
}