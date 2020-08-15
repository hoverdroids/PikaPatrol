import 'package:flutter/material.dart';
import 'package:pika_joe/styles/styles.dart';
import 'package:pika_joe/widget/drawer/elastic_drawer.dart';

class MainDrawer extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    Size mediaQuery = MediaQuery.of(context).size;

    return Container(
      width: mediaQuery.width * sidebarPercentWidthWhenOpen,
      child:Drawer(
        child:ElasticDrawer(
          percentOfWidth: sidebarPercentWidthWhenOpen,
          animationDuration: sidebarAnimationDuration,
          pixelsShownWhenClosed: sidebarPixelsShownWhenClosed,
          archHeight: sidebarArchHeight,
        ),
      ),
    );
  }
}