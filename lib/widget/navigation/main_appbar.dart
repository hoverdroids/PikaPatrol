
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pika_joe/styles/colors.dart';
import 'package:pika_joe/styles/styles.dart';

class MainAppBar extends AppBar {

  Function openMenuCallback;

  MainAppBar({this.openMenuCallback}) : super(
    backgroundColor: Colors.transparent,
    title: Text('Pika Patrol'),//TODO - apply a style
    centerTitle: true,
    elevation: 0.0,
    leading: IconButton(
      padding: EdgeInsets.only(left: appbarIconMargin),
      onPressed: openMenuCallback,
      icon: Icon(Icons.menu),
      iconSize: appbarIconSize,
      color: iconDarkBgColor,
    ),
    actions: <Widget>[
      IconButton(
        padding: EdgeInsets.only(right: appbarIconMargin),
        onPressed: () => print('Search'),//todo - connect this to a relevant action via a callback
        icon: Icon(Icons.search),
        iconSize: appbarIconSize,
        color: iconDarkBgColor,
      ),
    ],
  );
}