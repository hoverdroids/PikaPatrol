// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:pika_patrol/screens/splash/denver_zoo_splash_screen.dart';
import 'package:pika_patrol/screens/splash/front_range_pika_project_splash_screen.dart';
import 'package:pika_patrol/screens/splash/pika_patrol_splash_screen.dart';
import 'package:pika_patrol/screens/splash/rocky_mountain_wild_splash_screen.dart';
import 'package:pika_patrol/screens/splash/partnering_with_splash_screen.dart';
import 'package:pika_patrol/screens/splash/if_then_splash_screen.dart';
import 'package:provider/provider.dart';
import '../../l10n/translations.dart';
import '../home_with_drawer.dart';

class PartnersSplashScreensPager extends StatefulWidget {

  const PartnersSplashScreensPager({super.key});

  @override
  PartnersSplashScreensPagerState createState() => PartnersSplashScreensPagerState();
}

class PartnersSplashScreensPagerState extends State<PartnersSplashScreensPager> {

  LiquidController liquidController = LiquidController();

  Future<bool> _showNextSplashScreen() async {
    await Future.delayed(const Duration(milliseconds: 3000), () {});
    return true;
  }

  @override
  void initState() {
    super.initState();
    _showNextSplashScreen().then((value) {
      liquidController.animateToPage(page: 1);
    });
  }

  @override
  Widget build(BuildContext context) {

    var translations = Provider.of<Translations>(context);
    translations.update(context);

    return Scaffold(
      body: LiquidSwipe(
        pages: <Container>[
          PikaPatrolSplashScreen(),
          PartneringWithSplashScreen(),
          RockyMountainWildSplashScreen(),
          FrontRangePikaProjectSplashScreen(),
          IfThenSplashScreen(),
          DenverZooSplashScreen()
        ],
        enableLoop: false,
        fullTransitionValue: 300,
        waveType: WaveType.liquidReveal,
        positionSlideIcon: 0.5,
        liquidController: liquidController,
        ignoreUserGestureWhileAnimating: true,
        disableUserGesture: true,
        onPageChangeCallback: (page) => {
          _showNextSplashScreen().then((value){
            if (page < 5) {
              liquidController.animateToPage(page: page + 1);
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (BuildContext context) => const HomeWithDrawer())
              );
            }
          })
        },
      ),
    );
  }
}