

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pika_joe/styles/styles.dart';
import 'package:pika_joe/widget/elastic_sidebar.dart';

import 'liquid_swipe_wrapper.dart';

class HomeWithSidebar extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    Size mediaQuery = MediaQuery.of(context).size;

    return Container(
        width: mediaQuery.width,
        child: Stack(
          children: <Widget>[
            ElasticSidebar(
              percentOfWidth: sidebarPercentWidthWhenOpen,
              animationDuration: sidebarAnimationDuration,
              pixelsShownWhenClosed: sidebarPixelsShownWhenClosed,
              archHeight: sidebarArchHeight,
            ),
            LiquidSwipeWrapper(),
          ],
        ),
    );
  }
}