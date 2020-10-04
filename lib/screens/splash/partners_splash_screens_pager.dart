import 'package:flutter/material.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:pika_joe/screens/splash/denver_zoo_splash_screen.dart';
import 'package:pika_joe/screens/splash/front_range_pika_project_splash_screen.dart';
import 'package:pika_joe/screens/splash/pika_patrol_splash_screen.dart';
import 'package:pika_joe/screens/splash/rocky_mountain_wild_splash_screen.dart';
import 'package:pika_joe/screens/splash/partnering_with_splash_screen.dart';

import '../home_with_drawer.dart';

class PartnersSplashScreensPager extends StatefulWidget {
  @override
  _PartnersSplashScreensPagerState createState() => _PartnersSplashScreensPagerState();
}

class _PartnersSplashScreensPagerState extends State<PartnersSplashScreensPager> {

  LiquidController liquidController = LiquidController();

  Future<bool> _showNextSplashScreen() async {
    await Future.delayed(Duration(milliseconds: 3000), () {});
    return true;
  }

  @override
  void initState() {
    super.initState();

    _showNextSplashScreen().then((value) {
        liquidController.animateToPage(page: 1);

        _showNextSplashScreen().then((value) {
          liquidController.animateToPage(page: 2);

          _showNextSplashScreen().then((value) {
            liquidController.animateToPage(page: 3);

            _showNextSplashScreen().then((value) {
              liquidController.animateToPage(page: 4);

              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (BuildContext context) => HomeWithDrawer())
              );
            });
          });
        });
      }
    );
  }

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
              disableUserGesture: true,
              //TODO - onPageChangeCallback: pageChangeCallback,
            ),
    );
  }
}