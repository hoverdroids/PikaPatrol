import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:pika_joe/styles/colors.dart';
import 'package:pika_joe/styles/styles.dart';

class MainNavbar extends CurvedNavigationBar {
  MainNavbar() : super(
    color: navbarColor,
    backgroundColor: navbarBgColor,
    buttonBackgroundColor: navbarButtonColor,
    height: navbarHeight,
    items: <Widget>[
      Icon(Icons.show_chart, size: navbarIconSize, color: navbarIconColor),
      Icon(Icons.loupe, size: navbarIconSize, color: navbarIconColor),
      Icon(Icons.map, size: navbarIconSize, color: navbarIconColor),
    ],
    onTap: (index) {
    //TODO - liquidController.animateToPage(page: 2);//liquidController.currentPage + 1, duration: 500);
    },
    animationDuration: Duration(
      milliseconds: navbarAnimationDuration
    ),
    animationCurve: Curves.bounceInOut,
    index: 1,
  );
}