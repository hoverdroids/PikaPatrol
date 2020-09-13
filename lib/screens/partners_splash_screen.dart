import 'package:flutter/material.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:pika_joe/screens/splash/denver_zoo_splash_screen.dart';
import 'package:pika_joe/screens/splash/front_range_pika_project_splash_screen.dart';
import 'package:pika_joe/screens/splash/pika_patrol_splash_screen.dart';
import 'package:pika_joe/screens/splash/rocky_mountain_wild_splash_screen.dart';
import 'package:pika_joe/screens/splash/partnering_with_splash_screen.dart';

class PartnersSplashScreen extends StatefulWidget {
  @override
  _PartnersSplashScreenState createState() => _PartnersSplashScreenState();
}

class _PartnersSplashScreenState extends State<PartnersSplashScreen> {

  LiquidController liquidController = LiquidController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LiquidSwipe(
              pages: <Container>[
                PikaPatrolSplashScreen(),
                PartneringWithSplashScreen(),
                RockyMountainWildSplashScreen(),
                FrontRangePikaProjectSplashScreen(),
                DenverZooSplashScreen()
              ],
              enableLoop: false,
              fullTransitionValue: 300,
              enableSlideIcon: false,
              waveType: WaveType.liquidReveal,
              positionSlideIcon: 0.5,
              liquidController: liquidController,
              ignoreUserGestureWhileAnimating: true,
              //disableUserGesture: true,
              //TODO - onPageChangeCallback: pageChangeCallback,
            ),
    );
  }
}