import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:pika_joe/screens/observations_page.dart';
import 'package:pika_joe/screens/splash/page2.dart';
import 'package:pika_joe/screens/splash/page3.dart';
import 'package:pika_joe/styles/colors.dart';
import 'package:pika_joe/styles/styles.dart';
import 'package:pika_joe/widget/elastic_sidebar.dart';
import 'package:pika_joe/widget/standard_app_bar.dart';

//Derived from https://github.com/iamSahdeep/liquid_swipe_flutter/blob/master/example/lib/main.dart
class LiquidSwipeWrapper extends StatefulWidget {
  @override
  _LiquidSwipeWrapperState createState() => _LiquidSwipeWrapperState();
}

class _LiquidSwipeWrapperState extends State<LiquidSwipeWrapper> {

  LiquidController liquidController = LiquidController();

  @override
  Widget build(BuildContext context) {

    Size mediaQuery = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: mainAppBar,
      body: Container(
        width: mediaQuery.width,
        child: Stack(
          children: <Widget>[
            LiquidSwipe(
              pages: <Container>[
                ObservationsPage(),
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
            ElasticSidebar(
              percentOfWidth: sidebarPercentWidthWhenOpen,
              animationDuration: sidebarAnimationDuration,
              pixelsShownWhenClosed: sidebarPixelsShownWhenClosed,
              archHeight: sidebarArchHeight,
            ),
          ],
        ),
      ),
      bottomNavigationBar: CurvedNavigationBar(
        color: navbarColor,
        backgroundColor: navbarBgColor,
        buttonBackgroundColor: navbarButtonColor,
        height: navbarHeight,
        items: <Widget>[
          Icon(Icons.add, size: navbarIconSize, color: navbarIconColor),
          Icon(Icons.list, size: navbarIconSize, color: navbarIconColor),
          Icon(Icons.compare_arrows, size: navbarIconSize, color: navbarIconColor),
        ],
        onTap: (index) {
          //TODO - liquidController.animateToPage(page: 2);//liquidController.currentPage + 1, duration: 500);
        },
        animationDuration: Duration(
          milliseconds: navbarAnimationDuration
        ),
        animationCurve: Curves.bounceInOut,
        index: 1,
      ),
      drawer: Container(
        width: mediaQuery.width * 0.70,
        child:Drawer(

          //child: Center(
          // child: Column(
          //mainAxisAlignment: MainAxisAlignment.center,
          //children: <Widget>[
          child:ElasticSidebar(
            percentOfWidth: sidebarPercentWidthWhenOpen,
                   animationDuration: sidebarAnimationDuration,
                   pixelsShownWhenClosed: sidebarPixelsShownWhenClosed,
                   archHeight: sidebarArchHeight,
                 ),
               //],
             //),
           //),
      ),
    )
    );
  }
}