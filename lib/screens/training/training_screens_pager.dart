import 'package:flutter/material.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:material_themes_widgets/appbars/menu_title_profile_appbar.dart';
import 'package:material_themes_widgets/fundamental/icons.dart';
import 'package:pika_joe/screens/splash/denver_zoo_splash_screen.dart';
import 'package:pika_joe/screens/splash/front_range_pika_project_splash_screen.dart';
import 'package:pika_joe/screens/splash/pika_patrol_splash_screen.dart';
import 'package:pika_joe/screens/splash/rocky_mountain_wild_splash_screen.dart';
import 'package:pika_joe/screens/splash/partnering_with_splash_screen.dart';
import 'package:material_themes_manager/material_themes_manager.dart';

import '../home_with_drawer.dart';
import 'onboarding_screen.dart';

class TrainingScreensPager extends StatefulWidget {
  @override
  _TrainingScreensPagerState createState() => _TrainingScreensPagerState();
}

class _TrainingScreensPagerState extends State<TrainingScreensPager> {

  LiquidController liquidController = LiquidController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*appBar: MenuTitleProfileAppBar(
      //title: 'Pika Patrol',
      //openMenuCallback: (){ _scaffoldKey.currentState.openDrawer(); },
      //openProfileCallback: (){ _scaffoldKey.currentState.openEndDrawer(); },
    ),*/
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
          children: <Widget>[
            LiquidSwipe(
              pages: <Container>[
                OnboardingScreen(title:"This is a Pika!", imageUrl: "assets/pika1.jpg", description: "Cute as a button", backgroundGradientType: BackgroundGradientType.PRIMARY),
                OnboardingScreen(title:"Pika Scat", imageUrl: "assets/pika2.jpg", description: "Cute as a button", backgroundGradientType: BackgroundGradientType.SECONDARY),
                OnboardingScreen(title:"This is a Pika!", imageUrl: "assets/pika3.jpg", description: "Cute as a button", backgroundGradientType: BackgroundGradientType.MAIN_BG),
              ],
              enableLoop: true,
              fullTransitionValue: 300,
              enableSlideIcon: true,
              waveType: WaveType.liquidReveal,
              positionSlideIcon: 0.5,
              liquidController: liquidController,
              ignoreUserGestureWhileAnimating: false,
              disableUserGesture: false,
              //TODO - onPageChangeCallback: pageChangeCallback,
            ),
            SafeArea(
              child: ThemedIconButton(
                Icons.arrow_back,
                emphasis: Emphasis.HIGH,
                type: ThemeGroupType.MOP,
                onPressedCallback: () => {
                  Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (BuildContext context) => HomeWithDrawer())
                  )
                },
              ),
            )
          ],
        ),
    );
  }
}