

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:pika_joe/styles/colors.dart';


final TextStyle adventureSplashStyle = TextStyle(
    color: Colors.white,
    fontSize: 90.0,
    fontFamily: 'Product Sans',
    shadows: <Shadow>[
      Shadow(
          blurRadius: 18.0,
          color: Colors.black87,
          offset: Offset.fromDirection(120, 12)
      )
    ]
);


final TextStyle goldcoinGreyStyle = TextStyle(
    color: Colors.grey,
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
    fontFamily: "Product Sans");

final TextStyle goldCoinWhiteStyle = TextStyle(
    color: Colors.white,
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
    fontFamily: "Product Sans");

final TextStyle greyStyle = TextStyle(
    fontSize: 40.0,
    color: Colors.grey,
    fontFamily: "Product Sans");

final TextStyle whiteStyle = TextStyle(
    fontSize: 40.0,
    color: Colors.white,
    fontFamily: "Product Sans");

final TextStyle boldStyle = TextStyle(
  fontSize: 50.0,
  color: Colors.black,
  fontFamily: "Product Sans",
  fontWeight: FontWeight.bold,
);

final TextStyle descriptionGreyStyle = TextStyle(
  color: Colors.grey,
  fontSize: 20.0,
  fontFamily: "Product Sans",
);

final TextStyle descriptionWhiteStyle = TextStyle(
  color: Colors.white,
  fontSize: 20.0,
  fontFamily: "Product Sans",
);

final TextStyle sidebarItemStyle = TextStyle(
  color: Colors.black45,
    fontSize: 20
);

//------------- Fonts ---------------------------
var heading1FontSize = 25.0;
var heading1Font = "SF-Pro-Text-Regular";

//------------- Buttons -------------------------
var buttonStyle1PaddingHorz = 22.0;
var buttonStyle1PaddingVert = 6.0;
var buttonStyle1BorderRadius = 20.0;
var buttonStyle1FontSize = 10.0;
var buttonStyle1Font = "SF-Pro-Text-Regular";

//-------------- App Bar -------------------------
var appbarIconMargin = 30.0;
var appbarIconSize = 30.0;//TODO - make this a generic size, eg mini, small, med, large

//-------------- Nav Bar -------------------------
var navbarHeight = 50.0;
var navbarIconSize = 30.0;
var navbarAnimationDuration = 500;
var initialPage = 2;

//-------------- Left Sidebar -----------------------
var sidebarPercentWidthWhenOpen = 0.70;
var sidebarAnimationDuration = 1500;
var sidebarPixelsShownWhenClosed = 0.0;
var sidebarArchHeight = 75;

//------------- Cards ----------------------------
var cardAspectRatio = 12.0 / 16.0;
var cardScrollWidgetAspectRatio = cardAspectRatio * 1.2;
var cardScrollWidgetPadding = 20.0;
var cardScrollWidgetVerticalInset = 20.0;
var cardBorderRadius = 16.0;
var cardShadow = BoxShadow(
    color: cardShadowColor,
    offset: Offset(3.0, 6.0),
    blurRadius: 10.0,
);
var cardTitleInsetLeft = 16.0;
var cardTitleInsetBottom = 8.0;
var cardTitleSpacer = SizedBox(height: 10.0);
var cardButtonInsetLeft = 12.0;
var cardButtonInsetBottom = 12.0;

