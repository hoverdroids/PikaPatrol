

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