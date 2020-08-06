import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:pika_joe/screens/splash/page1.dart';
import 'package:pika_joe/screens/splash/page2.dart';
import 'package:pika_joe/screens/splash/page3.dart';

class LiquidSwipeWrapper extends StatelessWidget {

  //TODO - https://github.com/iamSahdeep/liquid_swipe_flutter/blob/master/example/lib/main.dart
  LiquidController liquidController = LiquidController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Pika Patrol'),//TODO - apply a style
      ),
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
        liquidController: liquidController,
        ignoreUserGestureWhileAnimating: true,
        //TODO - onPageChangeCallback: pageChangeCallback,
      ),
      bottomNavigationBar: CurvedNavigationBar(
        color: Colors.blueAccent,
        backgroundColor: Colors.white,
        buttonBackgroundColor: Colors.blueAccent,
        height: 50,
        items: <Widget>[
          Icon(Icons.add, size: 30),
          Icon(Icons.list, size: 30),
          Icon(Icons.compare_arrows, size: 30),
        ],
        onTap: (index) {
          //TODO - liquidController.animateToPage(page: 2);//liquidController.currentPage + 1, duration: 500);
        },
        animationDuration: Duration(
          milliseconds: 200
        ),
        animationCurve: Curves.bounceInOut,
        index: 1,
      ),
    );
  }
}