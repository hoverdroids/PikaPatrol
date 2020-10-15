import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:pika_joe/styles/colors.dart';
import 'package:pika_joe/styles/styles.dart';
import 'package:pika_joe/widget/netflix/movie_model.dart';
import 'package:pika_joe/widget/netflix/movie_screen.dart';

//TODO - this whole class needs to be migrated to ThemedWidgets
class StatsObservationsMapNavigationBar extends CurvedNavigationBar {

  StatsObservationsMapNavigationBar(PageController pageController) : super(
    color: navbarColor,
    backgroundColor: navbarBgColor,
    buttonBackgroundColor: navbarButtonColor,
    height: navbarHeight,
    items: <Widget>[
      //Icon(Icons.show_chart, size: navbarIconSize, color: navbarIconColor),
      Icon(Icons.loupe, size: navbarIconSize, color: navbarIconColor),
      //Icon(Icons.map, size: navbarIconSize, color: navbarIconColor),
    ],
    onTap: (index) {
      pageController.animateToPage(
          index,
          duration: Duration(milliseconds: navbarAnimationDuration),
          curve: Curves.easeInOut);
    },
    animationDuration: Duration(milliseconds: navbarAnimationDuration),
    animationCurve: Curves.easeInOut,
    //index: pageController.initialPage,
  );
}